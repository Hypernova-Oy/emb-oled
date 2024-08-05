#!/usr/bin/perl

use Modern::Perl;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use utf8;

use Test::More;
use Time::HiRes;

use OLED::Client;

use t::IPC;

subtest "Start the OLED-server and receive a connection", \&oledServer;
sub oledServer {
    my ($oledClient, $oledPid, $reply);
    eval {

    $oledPid = threads->create(\&OLED::Server::start_daemon, {configFile => 't/server.conf'}); sleep 1;

    $oledClient = OLED::Client->new({configFile => 't/server.conf'});

    $reply = $oledClient->printRow(0, "lol");
    $reply = $oledClient->readRow(0);
    is($reply, "200 OK lol", "printRow op + readRow op");

    $oledClient->endTransaction(); #Tell the server it can start clearing the screen.
    Time::HiRes::sleep $oledClient->{ClearTimeout}+0.1; #Wait for the server to clear screen after a time of inactivity
    $reply = $oledClient->readRow(0);
    is($reply, "200 OK                     ", "Screen cleared after 'ClearTimeout'-delay");

    $reply = $oledClient->printRow(0, "lol");
    $oledClient->clearDisplay();
    $reply = $oledClient->readRow(0);
    is($reply, "200 OK                     ", "Screen manually cleared");


    };
    if ($@) {
        ok(0, $@);
    }

    kill 'TERM', $oledPid; #Trigger the child process cleanup signal handler
}

done_testing();
