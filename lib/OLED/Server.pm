package OLED::Server;

use Modern::Perl;
use Carp qw(cluck confess);


use Sys::SigAction;
use IO::Socket::UNIX;
use OLED::us2066;

use OLED::Server::Display;

use base qw(OLED);

sub new {
    my ($class, $params) = @_;

    my $self = $class->_loadConfig($params->{configFile});
    $self = bless($self, $class);
    $self->{verbose} = $params->{verbose} if $params->{verbose};

    $self->{socket} = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Local => $self->getSocketPath(),
        Listen => 1,
    );
    $self->socketConnectedSuccesfully();
    $self->{socket}->timeout( $self->getTimeout() );

    $self->{display} = OLED::Server::Display->new({CSPin => $self->getSPICSGPIOPin(0)});

    return $self;
}

sub start {
    my ($self) = @_;

    my $viewModified;

    print "Server ready\n" if $self->{verbose};
    while (1) {
        my $buffer;
        eval {

            my $conn;
            my $skipLoop; #Prevent getting en Exiting eval via next -warning
            if (Sys::SigAction::timeout_call(
                $self->{ClearTimeout},
                sub {$conn = $self->{socket}->accept()})
            ) {
                $self->_loopTimeout($viewModified);
                $skipLoop = 1;
            }
            unless($skipLoop) {
                print "Server accepted $conn\n" if $self->{verbose};

                $viewModified = 1; #Toggle display clear

                $conn->autoflush(1);
                while($buffer = <$conn>) {
                    chomp($buffer);
                    print "Server got: $buffer\n" if $self->{verbose};
                    my $reply = $self->{display}->handleMessage($buffer);
                    print "Server send: $reply\n" if $self->{verbose};
                    $conn->send($reply."\n"); #Make sure there is a newline at the end of the message so the connection wont hang while waiting for the terminator character
                }
                print "Server closes $conn\n" if $self->{verbose};
                $conn->close();
            }
        };
        if ($@) {
            cluck($@);
        }
    }
}

sub _loopTimeout {
    my ($self, $viewModified) = @_;

    if ($viewModified) {
        OLED::us2066::clearDisplay();
        print "Display cleared\n" if $self->{verbose};
    }
}

sub DESTROY {
    my ($self) = @_;

    OLED::us2066::displayOnOff(0,0,0);

    if ($self->{socket}) {
        $self->{socket}->shutdown(2);
        $self->{socket}->close();
        unlink $self->getSocketPath(); #For some reason the socket is not automatically removed
    }
}

1;
