#!/usr/bin/perl
#
# Copyright (C) 2016 Koha-Suomi
#
# This file is part of emb-oled.
#

package t::IPC;

use Carp qw(confess cluck);
use Modern::Perl;

use OLED::Server;

sub forkExec {
    my ($cmd) = @_;
    my $pid = fork();
    if ($pid == 0) { #I am a child
        exec $cmd;
        exit 0;
    }
    else {
        sleep 1; #Sleep a bit to give time for the forked process to execute
    }
    return $pid; #Return the forked pid to the caller.
}

sub forkSub {
    my ($sub, @params) = @_;
    my $pid = fork();
    if ($pid == 0) { #I am a child
        eval {
            &$sub(@params);
        } or cluck($@);
        exit 0;
    }
    else {
        sleep 1; #Sleep a bit to give time for the forked process to execute
    }
    return $pid; #Return the forked pid to the caller.
}

sub forkOLEDServer {
    my ($configFile) = @_;

    return forkExec("perl -Ilib scripts/oled_server -c $configFile");
}

1;
