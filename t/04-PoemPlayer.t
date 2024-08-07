use Modern::Perl;
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
use utf8;
use Test::More;

use OLED;
use OLED::PoemPlayer;

ok(OLED->setConfig({configFile => 't/server.conf'}), "Given test config");

subtest "List poems", \&listPoems;
sub listPoems {
  my $poemNames = OLED::PoemPlayer::listPoems();
  is($poemNames->[0], "Aholla itkijä");
}
subtest "Parse poem display style 'Discreet'", \&parsePoemDiscreet;
sub parsePoemDiscreet {
  my $lines;

  subtest "\$config->{Heartbeat_DisplayStyle} = 'Discreet'", sub {
    ok(OLED->config->{Heartbeat_DisplayStyle} = 'D');
  };

  subtest "Aholla itkijä", sub {
    OLED::PoemPlayer::selectPoem("Aholla itkijä");

    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Aholla itkijä|      ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, [undef, '  Immikkö aholla    ','itki,               ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, [undef, undef, 'Heinätiellä         ','hellehteli,         ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Kirjavaisella       ','kivellä,            ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, [undef, 'Paistavalla         ','paaterella.         ']);

    while (scalar(@$lines) > 0) {
      $lines = OLED::PoemPlayer::feedRowsToDisplay();
    }
    is_deeply($lines, []);
  };

  subtest "Random poems do not crash. Automatically load a new poem after existing is consumed.", \&randomPoemNotCrash;
}

subtest "Parse poem display style 'Fullview'", \&parsePoemFullview;
sub parsePoemFullview {
  my $lines;

  subtest "\$config->{Heartbeat_DisplayStyle} = 'Fullview'", sub {
    ok(OLED->config->{Heartbeat_DisplayStyle} = 'F');
  };

  subtest "Aholla itkijä", sub {
    OLED::PoemPlayer::selectPoem("Aholla itkijä");

    $lines = OLED::PoemPlayer::feedRowsToDisplay(); # Poems start with 3 empty rows, just like the Star Wars intro
    is_deeply($lines, ['                    ','                    ','                    ','Aholla itkijä|      ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    $lines = OLED::PoemPlayer::feedRowsToDisplay();

    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Aholla itkijä|      ','--------------------','                    ','  Immikkö aholla    ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['--------------------','                    ','  Immikkö aholla    ','itki,               ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['                    ','  Immikkö aholla    ','itki,               ','Heinätiellä         ']);

    while (scalar(@$lines) == 4) {
      $lines = OLED::PoemPlayer::feedRowsToDisplay();
    }

    is_deeply($lines, ['majana,             ','Musta multa         ','kattehena.”         ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Musta multa         ','kattehena.”         ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['kattehena.”         ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, []);
  };

  subtest "Äiä on ääntäni kulunut", sub {
    OLED::PoemPlayer::selectPoem("Äiä on ääntäni kulunut");

    $lines = OLED::PoemPlayer::feedRowsToDisplay(); # Poems start with 3 empty rows, just like the Star Wars intro
    is_deeply($lines, ['                    ','                    ','                    ','Äiä on ääntäni      ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    $lines = OLED::PoemPlayer::feedRowsToDisplay();

    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Äiä on ääntäni      ','kulunut|            ','--------------------','                    ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['kulunut|            ','--------------------','                    ','  Lauloin ennen     ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['--------------------','                    ','  Lauloin ennen     ','lapsempana,         ']);

    while (scalar(@$lines) == 4) {
      $lines = OLED::PoemPlayer::feedRowsToDisplay();
    }

    is_deeply($lines, ['kivillä,            ','Reki rannan         ','hiekkasilla.        ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['Reki rannan         ','hiekkasilla.        ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, ['hiekkasilla.        ']);
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    is_deeply($lines, []);

  };

  subtest "Random poems do not crash. Automatically load a new poem after existing is consumed.", \&randomPoemNotCrash;
}

#subtest "Random poems do not crash. Automatically load a new poem after existing is consumed.", sub {
sub randomPoemNotCrash {
  my $lines;

  OLED::PoemPlayer::selectRandomPoem();
  $lines = OLED::PoemPlayer::feedRowsToDisplay();
  ok($lines, "Random poem 1");
  while (scalar(@$lines) > 0) {
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    like($lines->[0], qr/.{20}/) if $lines->[0];
    like($lines->[1], qr/.{20}/) if $lines->[1];
    like($lines->[2], qr/.{20}/) if $lines->[2];
    like($lines->[3], qr/.{20}/) if $lines->[3];
  }
  $lines = OLED::PoemPlayer::feedRowsToDisplay();
  ok($lines, "Random poem 2");
  while (scalar(@$lines) > 0) {
    $lines = OLED::PoemPlayer::feedRowsToDisplay();
    like($lines->[0], qr/.{20}/) if $lines->[0];
    like($lines->[1], qr/.{20}/) if $lines->[1];
    like($lines->[2], qr/.{20}/) if $lines->[2];
    like($lines->[3], qr/.{20}/) if $lines->[3];
  }
};

done_testing;
