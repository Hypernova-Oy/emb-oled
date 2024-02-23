package OLED;

use Modern::Perl;
use Carp qw(confess);

use Config::Simple;

our $config;

sub socketConnectedSuccesfully {
    my ($self) = @_;

    unless ($self->{socket}) { #Why cant we connect?
        confess("Couldn't connect to socket '".$self->getSocketPath()."', because '$!', even if it exists?") if (-e $self->getSocketPath());
        confess("Couldn't connect to socket '".$self->getSocketPath()."', because '$!'");
    }
    return $self;
}

sub config {
    return $config if $config;
    return _loadConfig(@_);
}
sub setConfig {
    return _loadConfig(@_);
}

=head2 _loadConfig

=cut

my $isDigit = qr/^\d+$/;

sub _loadConfig {
    my ($class, $params) = @_;
    $config = new Config::Simple($params->{configFile} || "/etc/emb-oled/server.conf")
	|| die(Config::Simple->error());
    $config = $config->vars();
    while (my ($k, $v) = each(%$params)) {
      $config->{$k} = $v if defined $params->{$k}; #This way undef $params dont clobber defined config.
    }

    foreach my $cp (qw(SPI_SerialClockSignal      SPI_SerialDataInputSignal
                       SPI_SerialDataOutputSignal SPI_ChipSelectSignal
                       SPI_ResetSignal            SPI_SendDelayMs
                       SPI_ReceiveDelayMs
                    )) {
        unless (defined($config->{$cp})) {
            confess("Configuration parameter '$cp' is not defined!");
        }
        unless ($config->{$cp} =~ $isDigit) {
            confess("Configuration parameter '$cp' is not a digit!");
        }
    }

    unless ($config->{User}) {
        confess("Configuration parameter 'User' is undefined.");
    }
    unless ($config->{Group}) {
        confess("Configuration parameter 'Group' is undefined.");
    }
    unless ($config->{RunDir}) {
        confess("Configuration parameter 'RunDir' is undefined.");
    }
    if ($config->{Heartbeat_DisplayStyle} =~ /^([DF])/i) {
        $config->{Heartbeat_DisplayStyle} = ucfirst($1);
    }
    else {
        warn("configuration parameter 'Heartbeat_DisplayStyle'='".$config->{Heartbeat_DisplayStyle}."' doesnt match regexp /^[DF]/");
    }

    return bless($config, $class);
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
sub ClearTimeout {
    return shift->{ClearTimeout} // 4;
}
sub getServerTimeout {
    return shift->{ServerTimeout} // 5;
}
sub Heartbeat_IdleBeforeHeartbeating {
    return shift->{Heartbeat_IdleBeforeHeartbeating} // 60;
}
sub Heartbeat_LevenshteinDistanceTolerance {
    return shift->{Heartbeat_LevenshteinDistanceTolerance} // 3;
}
sub Heartbeat_ScrollSpeedForNewLine {
    return shift->{Heartbeat_ScrollSpeedForNewLine} // 10;
}
sub Heartbeat_ReResetDelay {
    return shift->{Heartbeat_ReResetDelay} // 3600;
}
sub Heartbeat_DisplayStyle {
    return shift->{Heartbeat_DisplayStyle} || 'D'
}
sub SPI_SendDelayMs {
    return shift->{SPI_SendDelayMs};
}
sub SPI_ReceiveDelayMs {
    return shift->{SPI_ReceiveDelayMs};
}

1;
