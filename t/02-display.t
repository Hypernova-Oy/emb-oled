#!/usr/bin/perl

use Modern::Perl;

use Test::More;

use Time::HiRes;

use OLED::Server::Display;

my @rows = (
    "  LED TO THE RIVER  ",
    "  MIDSUMMER I WAVE  ",
    "A 'V' OF BLACK SWANS",
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

    $display = OLED::Server::Display->new({CSPin => 24});

    $reply = $display->handleMessage("printRow(0\t$rows[0]);");
    is($reply, "200 OK", "Print row 1");
    $reply = $display->handleMessage("printRow(1\t$rows[1]);");
    is($reply, "200 OK", "Print row 2");
    $reply = $display->handleMessage("printRow(2\t$rows[2]);");
    is($reply, "200 OK", "Print row 3");
    $reply = $display->handleMessage("printRow(3\t$rows[3]);");
    is($reply, "200 OK", "Print row 4");

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
