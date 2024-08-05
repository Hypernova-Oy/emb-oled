#!/usr/bin/perl

use Modern::Perl;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use utf8;

use Test::More;

use Time::HiRes;

use OLED;
use OLED::Server::Display;

my @rows = (
    "  LED TÖ THE RIVER  ",
    "  MIDSUMMER I WÄVE  ",
    "A 'V' OF BLÄCK SWÄNS",
    " WITH HOPE TO GRAVE ",
    "                    ",
    "                    ",
    "  COLD WAS MY SOUL  ",
    " UNTOLD WAS THE PAIN",
    "I FACED, WHEN YOU LEFT ME",
    " A ROSE IN THE RAIN ",
);

subtest "Handle client messages with the Display", \&oledDisplay;
sub oledDisplay {
    my ($display, $reply);
    eval {

    my $c = OLED->_loadConfig({configFile => 't/server.conf'});
    $display = OLED::Server::Display->new($c);

    for (my $i=0 ; $i<4 ; $i++) {
        $reply = $display->handleMessage("printRow($i\t$rows[$i]);");
        is($reply, "200 OK", "Print row $i");
        $reply = $display->handleMessage("readRow($i);");
        is($reply, "200 OK $rows[$i]", "Read row $i");
    }

    Time::HiRes::usleep(500000);

    $reply = $display->handleMessage("doubleLineText(3);");
    is($reply, "200 OK", "Double line 2+2");
    foreach my $i (0..4) { my $j=$i+1;
        $reply = $display->handleMessage("printRow(0\t$rows[$i]);");
        is($reply, "200 OK", "Print double line $i");
        $reply = $display->handleMessage("printRow(1\t$rows[$j]);");
        is($reply, "200 OK", "Print double line $j");
        Time::HiRes::usleep(250000);
    }

    Time::HiRes::usleep(250000);

    $reply = $display->handleMessage("doubleLineText(0);");
    is($reply, "200 OK", "Double line removed");

    $reply = $display->handleMessage("printRow(0\t$rows[6]);");
    is($reply, "200 OK", "Print row 7");
    $reply = $display->handleMessage("printRow(1\t$rows[7]);");
    is($reply, "200 OK", "Print row 8");
    $reply = $display->handleMessage("printRow(2\t$rows[8]);");
    is($reply, "200 OK", "Print row 9");
    $reply = $display->handleMessage("printRow(3\t$rows[9]);");
    is($reply, "200 OK", "Print row 10");

    Time::HiRes::usleep(500000);

    $reply = $display->handleMessage("displayOnOff(0\t0\t0);");

    };
    if ($@) {
        ok(0, $@);
    }
}

done_testing();
