package OLED::Client;

use Modern::Perl;
use Carp qw(confess);

use IO::Socket::UNIX;

use base qw(OLED);

sub new {
    my ($class, $params) = @_;

    my $self = $class->_loadConfig($params->{configFile});
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

=head2 endTransaction

Call this after you have finished with your user transcation with the oled-server so it can clear the screen.

=cut

sub endTransaction {
    my ($self) = @_;

    $self->{socket}->close();
    $self->{socket} = undef;
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

    #$self->endTransaction(); #Call this to end the transaction after you have sent whatever messages need sending.
    return $reply;
}





=head1 OLED::Client display interface functions

Contains the subroutines to generate the proper socket interface messages to perform the given actions.

=cut

sub printRow {
    my ($self, $index, $text) = @_;
    return $self->_send("printRow($index\t$text);");
}

sub readRow {
    my ($self, $index) = @_;
    return $self->_send("readRow($index\t                    );");
}

=head2 doubleLineText

See OLED::us2066 for the constants to use

=cut

sub doubleLineText {
    my ($self, $constant) = @_;
    return $self->_send("doubleLineText($constant);");
}

sub displayOnOff {
    my ($self, $on, $cursor, $blink) = @_;
    return $self->_send("displayOnOff($on\t$cursor\t$blink);");
}

sub clearDisplay {
    my ($self, $index) = @_;
    return $self->_send("clearDisplay();");
}




sub DESTROY {
    my ($self) = @_;

    if ($self->{socket}) {
        $self->{socket}->shutdown(2);
        $self->{socket}->close();
    }
}

1;
