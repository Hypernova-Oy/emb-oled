package OLED::Server::Display;

use Modern::Perl;
use Carp qw(cluck confess);

use OLED::us2066;

=head1 OLED::Server::Display

Handles the socket API requests and operates the given OLED displays

=cut

sub new {
    my ($class, $params) = @_;

    my $self = $class->_validateParams($params);
    $self = bless($self, $class);

    OLED::us2066::init();
    OLED::us2066::displayOnOff(1,0,0);

    return $self;
}

sub _validateParams {
    my ($class, $params) = @_;

    return $params;
}

=head2 handleMessage

@PARAM1 String, the received message

=cut

my %dispatchTable = (
    printRow       => sub { OLED::us2066::printRow(@_) },
    readRow        => sub { return OLED::us2066::readRow(@_) },
    doubleLineText => sub { OLED::us2066::doubleLineText(@_) },
    displayOnOff   => sub { OLED::us2066::displayOnOff(@_) },
    clearDisplay   => sub { OLED::us2066::clearDisplay() },
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

1;
