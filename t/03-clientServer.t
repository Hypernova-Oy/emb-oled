#!/usr/bin/perl

use Modern::Perl;

use Test::More;

use OLED::Client;

use t::IPC;

subtest "Start the OLED-server and receive a connection", \&oledServer;
sub oledServer {
    my ($oledClient, $oledPid, $reply);
    eval {

    $oledPid = t::IPC::forkOLEDServer('t/server.conf');

    $oledClient = OLED::Client->new({configFile => 't/server.conf'});

    $reply = $oledClient->printRow(0, "lol");
    $reply = $oledClient->readRow(0);
    is($reply, "200 OK lol", "printRow op + readRow op");

    sleep $oledClient->{ClearTimeout}+1; #Wait for the server to clear screen
    $reply = $oledClient->readRow(0);
    is($reply, "200 OK                     ", "Screen cleared after 'ClearTimeout'-delay");


    };
    if ($@) {
        ok(0, $@);
    }

    kill 'TERM', $oledPid; #Trigger the child process cleanup signal handler
}

done_testing();
