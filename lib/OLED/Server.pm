package OLED::Server;

use Modern::Perl;
use Carp qw(cluck confess);

use IO::Socket::UNIX;
use OLED::Server::Display;

use base qw(OLED);

sub new {
    my ($class, $params) = @_;

    my $self = __PACKAGE__->_loadConfig($params->{configFile});
    $self = bless($self, $class);

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

    while (1) {
        my $buffer;
        eval {
            print "Server ready\n" if $self->{verbose};
            if (my $conn = $self->{socket}->accept()) {
                print "Server accepted $conn\n" if $self->{verbose};
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

sub DESTROY {
    my ($self) = @_;

    if ($self->{socket}) {
        $self->{socket}->shutdown(2);
        $self->{socket}->close();
        unlink $self->getSocketPath(); #For some reason the socket is not automatically removed
    }
}

1;
