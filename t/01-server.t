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

    $reply = $oledClient->_send("Hello server!");
    is($reply, "Hello client!", "Server-client handshake 1 ok");

    ##Sending multiple newlines many times can crash the server if newlines are not escaped
    $reply = $oledClient->_send("crash\nthe\nserver\n");
    is($reply, "404 command not found", "Multiple newline crash prevention 1 ok");
    $reply = $oledClient->_send("fight\nthe\npower");
    is($reply, "404 command not found", "Multiple newline crash prevention 2 ok");
    $reply = $oledClient->_send("yankee\ngo\nhome");
    is($reply, "404 command not found", "Multiple newline crash prevention 3 ok");
    $reply = $oledClient->_send("this\nshould\ndo\nit");
    is($reply, "404 command not found", "Multiple newline crash prevention 4 ok");

    $reply = $oledClient->_send("Hello server!");
    is($reply, "Hello client!", "Server-client handshake 2 ok");

    $reply = $oledClient->_send("Hello server!");
    is($reply, "Hello client!", "Server-client handshake 3 ok");

    $reply = $oledClient->_send("");
    is($reply, "404 command not found", "Server-client empty message ok");

    };
    if ($@) {
        ok(0, $@);
    }

    kill 'TERM', $oledPid; #Trigger the child process cleanup signal handler
}

done_testing();
