#!/usr/bin/perl

# Copyright 2016 Koha-Suomi
#

use Modern::Perl;
use Carp;
use Getopt::Long qw(:config no_ignore_case);
use POSIX();
use Data::Dumper;

use OLED::Client;

my $help;
my $verbose = 0;
my $confFile = "/etc/emb-oled/server.conf";


GetOptions(
    'h|help'                      => \$help,
    'v|verbose:i'                 => \$verbose,
    'c:s'                         => \$confFile,
);

my $usage = <<USAGE;

An OLED display server cli client

 -c        Config file. Defaults to /etc/emb-oled/server.conf

USAGE

if ($help) {
  print $usage;
  exit 0;
}


my $client = OLED::Client->new({configFile => $confFile});

print "Client: ".$client->_send("Hello server!\n\nder")."\n";
print "Client: ".$client->_send("Hello server!")."\n";
print "Client: ".$client->_send("Hello server!")."\n";
print "Client: ".$client->_send("Hello server!")."\n";
