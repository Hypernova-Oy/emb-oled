package OLED::Server;

use Modern::Perl;
use Carp qw(cluck confess);

use base qw(Net::Server::Single OLED);

use Time::HiRes qw(ITIMER_VIRTUAL ITIMER_REAL ITIMER_PROF);
use Sys::SigAction;
use OLED::us2066;

use OLED::Server::Display;

my $display;
my $config;

sub process_request {
  my $self = shift;

  Time::HiRes::setitimer(ITIMER_REAL, 0); #reset ClearTimeout

  while (<STDIN>) {
    s/\r?\n$//;
    eval {
      if (Sys::SigAction::timeout_call(
        $config->{ServerTimeout},
        sub {
          my $reply = $self->_handler($_);
          print STDOUT $reply."\n";
        })
      ) {
        # On timeout
        print STDOUT "Timed out in '".$config->{ServerTimeout}."'!\n";
      }
    };
    if ($@) {
      print STDOUT ($@);
    }
  }
  Time::HiRes::setitimer(ITIMER_REAL, $config->getClearTimeout());
}

sub _handler {
  my ($self, $payload) = @_;
  print STDERR "Server got: $payload\n" if $config->{Verbose};
  my $reply = $display->handleMessage($payload);
  print STDERR "Server send: $reply\n" if $config->{Verbose};
  return $reply;
}

sub _clearDisplay {
  OLED::us2066::clearDisplay();
  print STDERR "Display cleared\n" if $config->{Verbose};
}

sub start_daemon {
  my ($params) = @_;
  $config = __PACKAGE__->_loadConfig($params);
  $display = OLED::Server::Display->new($config);

  $SIG{ALRM} = sub { _clearDisplay() };

  my $server = OLED::Server->new(
    pid_file => $config->getPidPath,
    port => $config->getSocketPath . '|unix',
    user => $config->{User},
    group => $config->{Group},
  );
  $server->run();
}

1;
