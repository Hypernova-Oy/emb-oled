package OLED::Server::Display;

use Modern::Perl;
use Carp qw(cluck confess);

use OLED::us2066;

=head1 OLED::Server::Display

Handles the socket API requests and operates the given OLED displays

=cut

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

my %dispatchTable = (
    printRow       => sub { OLED::us2066::printRow(@_) },
    readRow        => sub { my $buffer = "                    ";
                            OLED::us2066::readRow($_[0], $buffer);
                            return $buffer;
                      },
    doubleLineText => sub { OLED::us2066::doubleLineText(@_) },
    displayOnOff   => sub { OLED::us2066::displayOnOff(@_) },
    clearDisplay   => sub { OLED::us2066::clearDisplay() },
    reset          => sub { OLED::us2066::init() }, # init internally flips the RESet-pin.
);

sub handleMessage {
    my ($self, $msg) = @_;

    if ($msg eq "Hello server!") {
        return "Hello client!";
    }

    my ($subroutine, $params) = _splitMessage($msg);

    if ($dispatchTable{$subroutine}) {
        my $rv = $dispatchTable{$subroutine}(@$params);
        return "200 OK $rv" if $rv;
        return "200 OK";
    }

    return "404 command not found";
}

sub _splitMessage {
    my ($msg) = @_;

    if ($msg =~ /^(.+?)\((.*)\);$/) {
        my $subroutine = $1;
        my @params = split(/\t/, $2);
        return ($subroutine, \@params);
    }
    return ('', '');
}

sub DESTROY {
    my ($self) = @_;
 
    OLED::us2066::displayOnOff(0,0,0);
}

1;
