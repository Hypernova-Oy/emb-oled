package OLED::Server::Display;

use Modern::Perl;
use threads;
use threads::shared;

use Text::Levenshtein::XS;
use Time::HiRes;

use OLED;
use OLED::us2066;

use OLog;
my $l = bless({}, 'OLog');

=head1 OLED::Server::Display

Handles the socket API requests and operates the given OLED displays

=cut

our $handlingMessage :shared = Time::HiRes::time();
our $lastResetTime :shared = Time::HiRes::time();
our %statistics :shared = (
    printRow => 0,
    readRow => 0,
    doubleLineText => 0,
    displayOnOff => 0,
    clearDisplay => 0,
    reset => 0,
    validPrintRow => 0,
    invalidPrintRow => 0,
);
our $latestPrintRow :shared = "                    "; # Testing uses this to introspect correct behaviour during daemon runtime

sub new {
    my ($class, $p) = @_;

    my $self = bless({}, $class);

    OLED::us2066::setSpiPinSCLK(     $p->{SPI_SerialClockSignal}      );
    OLED::us2066::setSpiPinSDIN(     $p->{SPI_SerialDataInputSignal}  );
    OLED::us2066::setSpiPinSDOUT(    $p->{SPI_SerialDataOutputSignal} );
    OLED::us2066::setSpiPinCS(       $p->{SPI_ChipSelectSignal}       );
    OLED::us2066::setSpiPinRES(      $p->{SPI_ResetSignal}            );
    OLED::us2066::setSpiReceiveDelay($p->{SPI_ReceiveDelayMs}         );
    OLED::us2066::setSpiSendDelay(   $p->{SPI_SendDelayMs}            );
    OLED::us2066::init();
    OLED::us2066::displayOnOff(1,0,0);

    return $self;
}

=head2 handleMessage

@PARAM1 String, the received message

=cut

our %dispatchTable = (
    printRow       => sub { $latestPrintRow = $_[1]; OLED::us2066::printRow(@_); },
    readRow        => sub { my $buffer = "                    ";
                            OLED::us2066::readRow($_[0], $buffer);
                            return $buffer;
                      },
    doubleLineText => sub { OLED::us2066::doubleLineText(@_) },
    displayOnOff   => sub { OLED::us2066::displayOnOff(@_) },
    clearDisplay   => sub { OLED::us2066::clearDisplay() },
    reset          => sub { if (Time::HiRes::time() - $lastResetTime >= $OLED::config->Heartbeat_ReResetDelay()) {
                              OLED::us2066::init();
                              $lastResetTime = Time::HiRes::time();
                            }
                            else {
                              $l->info("reset prevented by Heartbeat_ReResetDelay");
                              return "reset prevented by Heartbeat_ReResetDelay\n";
                            }
                          }, # init internally flips the RESet-pin.
);

sub handleMessage {
    my ($self, $msg) = @_;

    if ($msg eq "Hello server!") {
        return "Hello client!";
    }

    my ($subroutineName, $params) = _splitMessage($msg);
    return "404 command not found" unless ($dispatchTable{$subroutineName});

    $statistics{$subroutineName} = $statistics{$subroutineName} ? $statistics{$subroutineName}+1 : 1;

    my $rv = $self->_dispatchCall($subroutineName, $params);
    return "200 OK $rv" if $rv;
    return "200 OK";
}

sub _splitMessage {
    my ($msg) = @_;

    if ($msg =~ /^(.+?)\((.*)\);$/) {
        my $subroutine = $1;
        my @params = split(/\t/, $2);
        return ($subroutine, \@params);
    } else {
        $l->warn("Unable to parse message '$msg'");
        return ('', []);
    }
}

sub _dispatchCall {
    my ($self, $subroutineName, $params) = @_;
    lock($handlingMessage);
    $handlingMessage = Time::HiRes::time();

    $l->trace("$subroutineName(".join(",",@$params).")") if $l->is_trace;

    return $dispatchTable{$subroutineName}->(@$params);
}

=head validateDisplayContent

@RETURN the levenshtein distance between what was written and what was read. 0 is without errors.

=cut

sub validateDisplayContent {
    my ($self, $lineNumber, $writtenLine) = @_;

    my $readLine = $self->_dispatchCall('readRow', [$lineNumber]);

    my $levenshtein = Text::Levenshtein::XS::distance($writtenLine, $readLine);
    if ($levenshtein > $OLED::config->Heartbeat_LevenshteinDistanceTolerance()) {
        $statistics{invalidPrintRow}++;
        $l->error("Display write-read cycle failed: Written='$writtenLine', Read='$readLine', Levenshtein='$levenshtein', Invalid='".$statistics{invalidPrintRow}."/".$statistics{validPrintRow}."'. Reseting display.");
        $self->_dispatchCall('reset', []);
        return $levenshtein;
    }
    $statistics{validPrintRow}++;
    return $levenshtein;
}

sub DESTROY {
    my ($self) = @_;
 
    OLED::us2066::displayOnOff(0,0,0);

    my $statistics = "Statistics:\n";
    while (my ($k, $v) = each(%statistics)) {
        $statistics .= "$k.=.$v\n";
    }
    $l->info($statistics);
}

1;
