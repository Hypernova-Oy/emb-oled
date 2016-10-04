package OLED::Client;

use Modern::Perl;
use Carp qw(confess);

use IO::Socket::UNIX;

use base qw(OLED);

sub new {
    my ($class, $params) = @_;

    my $self = __PACKAGE__->_loadConfig($params->{configFile});
    $self = bless($self, $class);

    return $self;
}

sub _connect {
    my ($self) = @_;

    $self->{socket} = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Peer => $self->getSocketPath(),
    ) unless $self->{socket};
    $self->socketConnectedSuccesfully();
    #$self->{socket}->autoflush(1);
    return $self->{socket};
}

=head2 _send

Sends a text message to the server

@PARAM1 String, the message. A newline is automatically appended for you so you can't forget it.

=cut

sub _send {
    my ($self, $msg) = @_;
    my $socket = $self->_connect();

    $msg =~ s/\n/\\n/g; #Escape newlines. Newlines inside the message will crash the server?
    $socket->send($msg."\n"); #Make sure there is a newline at the end of the message so the connection wont hang while waiting for the terminator character

    my $reply = $socket->getline();
    chomp($reply);

    #$socket->close();
    return $reply;
}

sub DESTROY {
    my ($self) = @_;

    if ($self->{socket}) {
        $self->{socket}->shutdown(2);
        $self->{socket}->close();
    }
}

1;
