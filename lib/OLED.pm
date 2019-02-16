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

my $isDigit = qr/^\d+$/;

sub _loadConfig {
    my ($class, $configFile) = @_;
    my $c = new Config::Simple($configFile || "/etc/emb-oled/server.conf")
	|| exitWithError(Config::Simple->error());
    $c = $c->vars();

    foreach my $cp (qw(SPI_SerialClockSignal      SPI_SerialDataInputSignal
                       SPI_SerialDataOutputSignal SPI_ChipSelectSignal
                       SPI_ResetSignal)) {
        unless (defined($c->{$cp})) {
            confess("Configuration parameter '$cp' is not defined!");
        }
        unless ($c->{$cp} =~ $isDigit) {
            confess("Configuration parameter '$cp' is not a digit!");
        }
    }

    unless ($c->{SocketPath}) {
        confess("Configuration parameter 'SocketPath' is undefined.");
    }

    unless ($c->{ClearTimeout}) {
        confess("Configuration parameter 'ClearTimeout' is undefined.");
    }

    return $c;
}

sub getSocketPath {
    return shift->{SocketPath};
}
sub getTimeout {
    return shift->{Timeout};
}

sub SCLK { return shift->{SPI_SerialClockSignal} }
sub SDIN { return shift->{SPI_SerialDataInputSignal} }
sub SDOUT { return shift->{SPI_SerialDataOutputSignal} }
sub CS   { return shift->{SPI_ChipSelectSignal} }
sub RES  { return shift->{SPI_ResetSignal} }

1;
