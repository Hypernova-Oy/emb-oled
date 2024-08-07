#!/usr/bin/perl

# Copyright 2016 Koha-Suomi
#

use Modern::Perl;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use utf8;
use Carp;
use Getopt::Long qw(:config no_ignore_case);
use POSIX();
use Data::Dumper;

use OLED::Client;

my $help;
my $verbose = 0;
my $confFile;
my ($poem, $printRow, $readRow, $reset, $helloWorld);


GetOptions(
    'h|help'                      => \$help,
    'v|verbose:i'                 => \$verbose,
    'c:s'                         => \$confFile,
    'p:s'                         => \$printRow,
    'r:i'                         => \$readRow,
    'R'                           => \$reset,
    'poem:s'                      => \$poem,
    'H'                           => \$helloWorld,
);

my $usage = <<USAGE;

An OLED display server cli client

 -c        Config file. Defaults to /etc/emb-oled/server.conf

 -H        Hello world check to the server

 -p        print a row to the OLED display

 -r        Number, Index of the row from 0-3. Read a row from the display.

 -R        Flag, reset the display

 --poem    Show a poem. 'r' or 'random' for a random poem, or a named poem.

EXAMPLES

  oled_client.pl -p "0:PRINT TO FIRST ROW"
  oled_client.pl -r 3

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
if ($readRow) {
  my $readRowIndex = $readRow;
  print $client->readRow($readRowIndex);
}
if ($reset) {
  print $client->reset();
}
if ($poem) {
  require OLED::PoemPlayer;
  @OLED::PoemPlayer::poemBuffer = ();
  if ($poem eq 'r' || $poem eq 'random') {
    OLED::PoemPlayer::selectRandomPoem();
  }
  else {
    OLED::PoemPlayer::selectPoem($poem);
  }
  OLED::PoemPlayer::feedRowsToDisplay();
  if (ref($OLED::PoemPlayer::poemBuffer[0]) eq 'ARRAY') {
    for my $lineRows (@OLED::PoemPlayer::poemBuffer) {
      for my $row (@$lineRows) {
        print "$row";
        print ord($_).' ' for split(//, $row);
        print "\n";
      }
    }
  }
  else {
    print join("\n", @OLED::PoemPlayer::poemBuffer)."\n";
  }
}
