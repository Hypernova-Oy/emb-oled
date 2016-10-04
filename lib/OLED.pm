package OLED;

use Modern::Perl;
use Carp qw(confess);

use Config::Simple;

sub socketConnectedSuccesfully {
    my ($self) = @_;

    unless ($self->{socket}) { #Why cant we connect?
        confess("Couldn't connect to socket '".$self->getSocketPath()."', because '$!', even if it exists?") if (-e $self->getSocketPath());
        confess("Couldn't connect to socket '".$self->getSocketPath()."', because '$!'");
    }
    return $self;
}

=head2 _loadConfig

=cut

sub _loadConfig {
    my ($class, $configFile) = @_;
    my $c = new Config::Simple($configFile)
	|| exitWithError(Config::Simple->error());
    $c = $c->vars();

    unless ($c->{SPICSGPIOPins}) {
        confess("Configuration parameter 'SPICSGPIOPins' is undefined");
    }
    $c->{SPICSGPIOPins} = [split(/[ ,.]/, $c->{SPICSGPIOPins})];
    unless (ref($c->{SPICSGPIOPins}) eq 'ARRAY' && scalar(@{$c->{SPICSGPIOPins}}) > 0) {
        confess("Configuration parameter 'SPICSGPIOPins' is unknown. It must be a list of GPIO wiringPi pins connected as SPI CS-channels.");
    }

    unless ($c->{SocketPath}) {
        confess("Configuration parameter 'SocketPath' is undefined.");
    }

    return $c;
}

sub getSocketPath {
    return shift->{SocketPath};
}
sub getTimeout {
    return shift->{Timeout};
}

1;
