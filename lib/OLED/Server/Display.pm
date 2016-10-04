package OLED::Server::Display;

use Modern::Perl;
use Carp qw(cluck confess);

use OLED::us2066;

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

sub handleMessage {
    my ($self, $msg) = @_;

    if ($msg eq "Hello server!") {
        return "Hello client!";
    }

    my ($subroutine, $params) = _splitMessage($msg);

    if ($msg =~ /^printRow\((.*)\);$/) {
        my @params = split(/\t/, $1);
        OLED::us2066::printRow(@params);
        return "200 OK";
    }
    elsif ($msg =~ /^doubleLineText\((.*)\);$/) {
        my @params = split(/\t/, $1);
        OLED::us2066::doubleLineText(@params);
        return "200 OK";
    }
    elsif ($msg =~ /^displayOnOff\((.*)\);$/) {
        my @params = split(/\t/, $1);
        OLED::us2066::displayOnOff(@params);
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
    return (undef, undef);
}

1;
