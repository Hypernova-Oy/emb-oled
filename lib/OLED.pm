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
    my ($class, $params) = @_;
    my $c = new Config::Simple($params->{configFile} || "/etc/emb-oled/server.conf")
	|| die(Config::Simple->error());
    $c = $c->vars();
    while (my ($k, $v) = each(%$params)) {
      $c->{$k} = $v if defined $params->{$k}; #This way undef $params dont clobber defined config.
    }

    foreach my $cp (qw(SPI_SerialClockSignal      SPI_SerialDataInputSignal
                       SPI_SerialDataOutputSignal SPI_ChipSelectSignal
                       SPI_ResetSignal            SPI_SendDelayMs
                       SPI_ReceiveDelayMs
                       ClearTimeout               ServerTimeout)) {
        unless (defined($c->{$cp})) {
            confess("Configuration parameter '$cp' is not defined!");
        }
        unless ($c->{$cp} =~ $isDigit) {
            confess("Configuration parameter '$cp' is not a digit!");
        }
    }

    unless ($c->{User}) {
        confess("Configuration parameter 'User' is undefined.");
    }
    unless ($c->{Group}) {
        confess("Configuration parameter 'Group' is undefined.");
    }
    unless ($c->{RunDir}) {
        confess("Configuration parameter 'RunDir' is undefined.");
    }

    return bless($c, $class);
}

sub getRunDir {
    return shift->{RunDir};
}
sub getSocketPath {
    return shift->{RunDir}.'/sock';
}
sub getPidPath {
    return shift->{RunDir}.'/pid';
}
sub getClearTimeout {
    return shift->{ClearTimeout};
}
sub getServerTimeout {
    return shift->{ServerTimeout};
}
sub SPI_SendDelayMs {
    return shift->{SPI_SendDelayMs};
}
sub SPI_ReceiveDelayMs {
    return shift->{SPI_ReceiveDelayMs};
}

1;
