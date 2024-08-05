#!/usr/bin/perl

use Modern::Perl;
use threads;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use utf8;

use Test::More;
use Time::HiRes;

use OLED;
use OLED::Client;
use OLED::Server;
use OLED::Server::Display;

ok(OLED->setConfig({configFile => 't/server.conf'}), "Given test config");

subtest "Validate heartbeat", sub {
  my $validationsDone = $OLED::Server::Display::statistics{invalidPrintRow} + $OLED::Server::Display::statistics{validPrintRow};
  my $display = OLED::Server::Display->new(OLED->config());
  $display->handleMessage("printRow(0\tOver the hills and f);");
  my $levenshtein = $display->validateDisplayContent(0, 'Over the hills and f');
  cmp_ok($validationsDone, '<', $OLED::Server::Display::statistics{invalidPrintRow} + $OLED::Server::Display::statistics{validPrintRow},
    'Validation done');
  cmp_ok($levenshtein, '>=', 0, 'Received levenshtein');
};

subtest "Management loop validates connection", sub {
  OLED->setConfig({configFile => 't/server.conf'});
  my $validationsDone = $OLED::Server::Display::statistics{invalidPrintRow} + $OLED::Server::Display::statistics{validPrintRow};
  my $display = OLED::Server::Display->new(OLED->config());

  $OLED::Server::timeOfLastCall = time();
  OLED::Server::_oledDisplayConnectionManagementLoop();
  cmp_ok($validationsDone, '==', $OLED::Server::Display::statistics{invalidPrintRow} + $OLED::Server::Display::statistics{validPrintRow},
    'Validations not done');

  Time::HiRes::sleep(OLED->config->Heartbeat_IdleBeforeHeartbeating());

  OLED::Server::_oledDisplayConnectionManagementLoop();
  cmp_ok($validationsDone, '<', $OLED::Server::Display::statistics{invalidPrintRow} + $OLED::Server::Display::statistics{validPrintRow},
    'Validations done');
};

SKIP: { skip "threading breaks tests", 1;
subtest "Scenario: Management thread starts doing heartbeat tests between display calls.", \&mgntThreadTest;
sub mgntThreadTest {
  my ($serverThread, $oledClient, $reply, $tries, $maxTries);
  eval {  
    print "JAJAJAJAAJ\n";
  $serverThread = threads->create(\&OLED::Server::start_daemon, {configFile => 't/server.conf'});
  $serverThread->detach();
  Time::HiRes::sleep(50000000); # Wait for server to start

print "JAJAJAJAA22222222222222J\n";
  $oledClient = OLED::Client->new({configFile => 't/server.conf'});
print "JAJAJAJAAJ\n";

    print "JAJAJAJAAJ\n";
    $reply = $oledClient->printRow(0, "lol");
    print "JAJAJAJAAJ\n";
    is($reply, "200 OK lol", "printRow lol");
    print "JAJAJAJAAJ\n";
    is($OLED::Server::Display::latestPrintRow, "lol", "Display print introspection check");
    print "JAJAJAJAAJ\n";
    $oledClient->endTransaction(); #Tell the server it can start clearing the screen.
    print "JAJAJAJAAJ\n";


  subtest "Wait for the screen to be cleared", sub {
    Time::HiRes::sleep $OLED::config->ClearTimeout()+0.01; #Wait for the server to clear screen after a time of inactivity
    is($OLED::Server::Display::statistics{clearDisplay}, 1, "statistics clearDisplay +1");
  };

  subtest "Wait for the heartbeat tests to start", sub {
    $tries = 0;
    # We try in 100ms slices, up to 2 times as long as the configured idling time.
    # Because the management thread idles in increments of the Heartbeat_IdleBeforeHeartbeating.
    $maxTries = $OLED::config->Heartbeat_IdleBeforeHeartbeating()/0.1*2;
    while ($OLED::Server::Display::latestPrintRow ne "lol" && ++$tries < $maxTries) {
      Time::HiRes::sleep 0.1;
    }
    isnt($OLED::Server::Display::latestPrintRow, "lol", "Heartbeat has written something");
    ok($tries < $maxTries, "Heartbeat started in the expected time");
  };

  };
  if ($@) {
      ok(0, $@);
  }

  kill 'TERM', $serverThread; #Trigger the child process cleanup signal handler
}
};

done_testing();
