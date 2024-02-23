package OLED::Server;

use Modern::Perl;
use threads;
use threads::shared;

use base qw(Net::Server::Single);

use Time::HiRes qw(ITIMER_VIRTUAL ITIMER_REAL ITIMER_PROF);
use Try::Tiny;
use Sys::SigAction;
use OLED::us2066;

use OLED::PoemPlayer;
use OLED::Server::Display;

use OLog;
my $l = bless({}, 'OLog');

my $display;

our $timeOfLastCall :shared = Time::HiRes::time();
our $timeOfLastClearDisplay :shared = Time::HiRes::time;

sub display {
  return $display if $display;
  $display = OLED::Server::Display->new(OLED->config);
}

sub process_request {
  my $self = shift;

  while (<STDIN>) {
    s/\r?\n$//;
    try {
      if (Sys::SigAction::timeout_call(
        OLED->config->{ServerTimeout},
        sub {
          my $reply = $self->_handler($_);
          print STDOUT "$reply\n";
        })
      ) {
        # On timeout
        print STDOUT "Timed out in '".OLED->config->{ServerTimeout}."'!\n";
      }
    } catch {
      $l->error($_);
      print STDOUT $_."\n";
    };
  }
}

sub _handler {
  my ($self, $payload) = @_;
  $l->info("Server got: $payload");
  $timeOfLastCall = Time::HiRes::time();
  my $reply = display->handleMessage($payload);
  $l->info("Server send: $reply");
  return $reply;
}

=head2 oledDisplayConnectionManagementThread

Checks for the health of the connection/display and tries to restart it if it is not working properly.

=cut

sub oledDisplayConnectionManagementThread {
  threads->detach();

  while (1) {
    try {
      _oledDisplayConnectionManagementLoop();
    } catch {
      $l->error($_);
      Time::HiRes::sleep($OLED::config->Heartbeat_IdleBeforeHeartbeating());
    };
  }
}

sub _oledDisplayConnectionManagementLoop {
  if (Time::HiRes::time() - $timeOfLastCall >= $OLED::config->Heartbeat_IdleBeforeHeartbeating()) {
    my $lines = OLED::PoemPlayer::feedRowsToDisplay();
    if (OLED->config->Heartbeat_DisplayStyle eq 'D' &&
        OLED->config->ClearTimeout > OLED->config->Heartbeat_ScrollSpeedForNewLine) {
      display->_dispatchCall('clearDisplay', []);
    }
    for (my $i=0 ; $i<@$lines ; $i++) { my $writeLine = $lines->[$i];
      next unless $writeLine;
      display->_dispatchCall('printRow', [$i, $writeLine]);
      display->validateDisplayContent($i, $writeLine);
    }
    $l->debug("Heartbeat ".OLED::PoemPlayer::getPoemStatus());
    Time::HiRes::sleep($OLED::config->Heartbeat_ScrollSpeedForNewLine());
    Time::HiRes::sleep($OLED::config->Heartbeat_IdleBeforeHeartbeating()) unless (@$lines);
  }
  else {
    Time::HiRes::sleep($OLED::config->Heartbeat_IdleBeforeHeartbeating());
  }
}

=head displayClearThread

Using Time::HiRes::setitimer(ITIMER_REAL) somehow interferes with Net::Server and triggers this warning:

  Accept failed with 29 tries left: Interrupted system call

Tried AnyEvent->timer and other timer classes from Time::HiRes but cannot get the timers firing on Raspberry Pi 4.

So since we have threading enabled, implement a simple poller to clear the display after a timeout.

=cut

my $displayClearThreadPollingIntervalS = 1;
sub displayClearThread {
  threads->detach();
  while (1) {
    try {
      Time::HiRes::sleep($displayClearThreadPollingIntervalS);
      _displayClearThread();
    }
    catch {
      $l->error($_);
      Time::HiRes::sleep($displayClearThreadPollingIntervalS);
    }
  }
}

sub _displayClearThread {
  if ($timeOfLastClearDisplay < $timeOfLastCall &&
      Time::HiRes::time() - $timeOfLastCall > OLED->config->ClearTimeout()) {
    display->_dispatchCall('clearDisplay', []);
    $l->debug("Display cleared");
    $timeOfLastClearDisplay = Time::HiRes::time();
  }
}

sub start_daemon {
  my ($params) = @_;
  OLED->setConfig($params);
  OLog::get_logger(); # This implicitly inits Log::Log4perl
  display(); # Set up display hardware before multithreading. Otherwise threads will try to make their own GPIO devices, and big problems...

  my $oledDisplayConnectionManagementThread = threads->create(\&oledDisplayConnectionManagementThread);
  my $displayClearThread = threads->create(\&displayClearThread);

  my $server = OLED::Server->new(
    pid_file => OLED->config->getPidPath,
    port => OLED->config->getSocketPath . '|unix',
    user => OLED->config->{User},
    group => OLED->config->{Group},
    log_file => 'Log::Log4perl',
    log4perl_conf => OLog::get_log_file(),
  );
  $server->run();
}

1;
