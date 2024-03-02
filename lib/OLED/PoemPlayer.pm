# Copyright 2024 Hypernova Oy
#
# This file is part of OLED.

=head OLED::PoemPlayer

Poems consist of a title and stanzas containing variable-length lines of text.
Try to present the poems on the small 4x20 screen spectacularly.

- Show a title with underscore
- Separate stanzas with a newline
- Cut long lines of text to smaller space-padded rows respecting word-boundaries.
- Keep scrolling the poem-feed line-by-line

Display styles:

- Fullview - Keep moving the text viewport forward/downward, always printing the full 4 rows.
- Discreet - Print only one line at a time, clearing the previous line and printing a new one on the next rows. This is more discreet.

Poem terminology:

- Stanza - Like a paragraph
- Line - A full line of poetry, typically ends in some punctuation
- Row - A row of text on the character display. One line of poetry often takes many rows to show.

=cut

package OLED::PoemPlayer;

use Modern::Perl;
use utf8;
use POSIX;

use Text::Unidecode;

use OLED;
use OLED::Poems;

use OLog;
my $l = bless({}, 'OLog');

my $poem;
my $poemBufferIndex = 0;
my $nextDisplayRowUsed = 0;
our @poemBuffer = ();

my $maxRowLengthOnDisplay = 20;
my $maxRowsOnDisplay = 4;

sub getPoemTitle {
  return ($poem) ? $poem->{title} : '';
}

sub getPoemStatus {
  return getPoemTitle()." $poemBufferIndex/".scalar(@poemBuffer);
}

sub listPoems {
  return \@OLED::Poems::poemTitles;
}

sub selectPoem {
  my ($poemName) = @_;
  unless ($OLED::Poems::poems{$poemName}) {
    $l->warn("Unknown poem '$poemName'!");
    return undef;
  }
  $poem = _parsePoem($OLED::Poems::poems{$poemName});
  @poemBuffer = ();
  return $poem;
}

sub selectRandomPoem {
  my $i = POSIX::floor(rand(@OLED::Poems::poemTitles));
  $poem = _parsePoem($OLED::Poems::poems{$OLED::Poems::poemTitles[$i]});
  @poemBuffer = ();
  return $poem;
}

sub _parsePoem {
  my ($poemObj) = @_;
  my @stanzas = split("\n\n", $poemObj->{content});
  for (my $i=0 ; $i<@stanzas ; $i++) {
    my @p = split("\n", $stanzas[$i]);
    $stanzas[$i] = \@p;
  }
  $poemObj->{stanzas} = \@stanzas;
  return $poemObj;
}

sub _parsePoemLine {
  my ($textLine, $isStanzaStart) = @_;
  my @words = split(/ /, $textLine);
  my @stringBuilder;
  my $row = ($isStanzaStart) ? "  " : "";
  my $rowWordCount = 0;

  for my $word (@words) {
    my $spaceForNewWord = $maxRowLengthOnDisplay - length($row) - length($word) - length(' ');
    if ($spaceForNewWord >= 0) { # Room for a new word
      $row .= ' ' if $rowWordCount > 0;
      $row .= $word;
      $rowWordCount++;
    }
    elsif ($rowWordCount == 0) { # Split the word to two rows separated by -
      $row .= ' ' if $rowWordCount > 1;
      $row .= substr($word, 0, $spaceForNewWord-1).'-';
      push(@stringBuilder, _padRow($row));
      $rowWordCount = 0;
      $row = substr($word, $spaceForNewWord-1);
    }
    elsif ($row) { # Line already has some words, so we can change rows.
      push(@stringBuilder, _padRow($row));
      $row = $word;
      $rowWordCount = 1;
    }
  }
  if (length($row) < 20 && substr($row, -1) !~ /\p{XPosixPunct}/) {
    $row .= '|';
  }
  push(@stringBuilder, _padRow($row));
  return @stringBuilder;
}

sub _padRow {
  my ($row, $padding) = @_;
  $padding = ' ' unless $padding;
  my $paddingNeeded = $maxRowLengthOnDisplay - length($row);
  if ($paddingNeeded > 0) {
    $row .= $padding x $paddingNeeded;
  }
  return $row;
}

sub _formatPoemToRowBuffer {
  my ($poemObj) = @_;
  $poemBufferIndex = 0;

  my @titleRows = _parsePoemLine($poemObj->{title});
  if (@titleRows == $maxRowsOnDisplay) {
    $titleRows[-1] =~ s/ {2,}//;
    $titleRows[-1] = _padRow($titleRows[-1],'-');
  }
  else {
    push(@titleRows, _padRow('-' x $maxRowLengthOnDisplay));
  }
  push(@poemBuffer, _padRow(''));
  push(@poemBuffer, _padRow(''));
  push(@poemBuffer, _padRow(''));
  push(@poemBuffer, @titleRows);
  for my $p (@{$poemObj->{stanzas}}) {
    push(@poemBuffer, _padRow(''));
    for (my $j=0 ; $j<@$p ; $j++) { my $r = $p->[$j];
      push(@poemBuffer, _parsePoemLine($r,($j==0)?1:0));
    }
  }
}

sub _formatPoemToLineBuffer {
  my ($poemObj) = @_;
  $poemBufferIndex = 0;

  push(@poemBuffer, [_parsePoemLine($poemObj->{title})]);
  for my $p (@{$poemObj->{stanzas}}) {
    for (my $j=0 ; $j<@$p ; $j++) { my $r = $p->[$j];
      push(@poemBuffer, [_parsePoemLine($r,($j==0)?1:0)]);
    }
  }
}

sub feedRowsToDisplay {
  $poem = _parsePoem(selectRandomPoem()) unless $poem;

  if (OLED->config->Heartbeat_DisplayStyle eq 'F') { #Fullview
    _formatPoemToRowBuffer($poem) unless @poemBuffer;
    my @view = ();
    my $indexesAvailable = scalar(@poemBuffer) - $poemBufferIndex;
    push(@view, $poemBuffer[$poemBufferIndex+0]) if $indexesAvailable > 0;
    push(@view, $poemBuffer[$poemBufferIndex+1]) if $indexesAvailable > 1;
    push(@view, $poemBuffer[$poemBufferIndex+2]) if $indexesAvailable > 2;
    push(@view, $poemBuffer[$poemBufferIndex+3]) if $indexesAvailable > 3;

    if ($indexesAvailable == 0) {
      $poem = undef;
      @poemBuffer = ();
    }

    $poemBufferIndex++;
    return \@view;
  }
  elsif (OLED->config->Heartbeat_DisplayStyle eq 'D') { #Discreet
    _formatPoemToLineBuffer($poem) unless @poemBuffer;
    my @view = ();
    my $lineRows = $poemBuffer[$poemBufferIndex];

    unless ($lineRows) {
      $poem = undef;
      @poemBuffer = ();
      return [];
    }

    if ($nextDisplayRowUsed + scalar(@$lineRows) > $maxRowsOnDisplay) { # start writing from top if no room for the poem's line.
      $nextDisplayRowUsed = 0;
    }
    while (scalar(@view) < $nextDisplayRowUsed) { # prepend the view with empty lines for already used rows
      push(@view, undef);
    }
    push(@view, @$lineRows);

    $nextDisplayRowUsed++;
    $poemBufferIndex++;
    return \@view;
  }
  else {
    $l->logdie("Unknown Heartbeat_DisplayStyle='".OLED->config->Heartbeat_DisplayStyle."'");
  }
}

1;