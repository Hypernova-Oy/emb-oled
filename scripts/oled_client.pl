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
my $confFile;
my ($printRow, $helloWorld);


GetOptions(
    'h|help'                      => \$help,
    'v|verbose:i'                 => \$verbose,
    'c:s'                         => \$confFile,
    'p:s'                         => \$printRow,
    'H'                           => \$helloWorld,
);

my $usage = <<USAGE;

An OLED display server cli client

 -c        Config file. Defaults to /etc/emb-oled/server.conf

 -h        Hello world check to the server

 -p        print a row to the OLED display

EXAMPLES

  oled_client.pl -p "0:PRINT TO FIRST ROW"

USAGE

if ($help) {
  print $usage;
  exit 0;
}


my $client = OLED::Client->new({configFile => $confFile});

if ($helloWorld) {
    print $client->_send("Hello server!")."\n";
}
if ($printRow) {
    my ($index, $msg) = split(':',$printRow);
    print $client->printRow($index, $msg);
}
