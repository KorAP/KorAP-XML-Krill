#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use KorAP::XML::Annotation::Spacy::Morpho;
use KorAP::XML::Annotation::Spacy::Dependency;
use Scalar::Util qw/weaken/;
use Data::Dumper;
use lib 't/annotation';
use TestInit;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use File::Temp qw/tempdir/;
use KorAP::XML::Archive;
use KorAP::XML::Krill;
use KorAP::XML::Tokenizer;

# Test 1: Old format tests (backward compatibility)
subtest 'Old format backward compatibility (0001 corpus)' => sub {
  ok(my $tokens = TestInit::tokens('0001'), 'Parse tokens');

  ok($tokens->add('Spacy', 'Morpho'), 'Add Structure');

  my $data = $tokens->to_data->{data};

  like($data->{foundries}, qr!spacy/morpho!, 'data');
  like($data->{layerInfos}, qr!spacy/p=tokens!, 'data');
  like($data->{layerInfos}, qr!spacy/l=tokens!, 'data');

  is($data->{stream}->[0]->[5], 'spacy/l:zu', 'POS');
  is($data->{stream}->[0]->[6], 'spacy/p:ADP', 'POS');

  is($data->{stream}->[3]->[3], 'spacy/l:Anlass', 'POS');
  is($data->{stream}->[3]->[4], 'spacy/p:NOUN', 'POS');

  is($data->{stream}->[10]->[3], 'spacy/l:ein', 'POS');
  is($data->{stream}->[10]->[4], 'spacy/p:ADV', 'POS');

  is($data->{stream}->[13]->[3], 'spacy/l:Betrieb', 'POS');

  is($data->{stream}->[-1]->[3], 'spacy/l:werden', 'POS');
  is($data->{stream}->[-1]->[4], 'spacy/p:AUX', 'POS');

  is($data->{stream}->[11]->[3], 'spacy/l:bevor',
     'Lemma');
  is($data->{stream}->[11]->[4], 'spacy/p:SCONJ',
     'POS');

  is($data->{stream}->[12]->[1], 'i:der','Surface');
  is($data->{stream}->[13]->[1], 'i:betrieb','Surface');
  is($data->{stream}->[14]->[1], 'i:ende','Surface');
  is($data->{stream}->[15]->[1], 'i:schuljahr','Surface');
  is($data->{stream}->[16]->[1], 'i:eingestellt','Surface');
  is($data->{stream}->[17]->[1], 'i:wird','Surface');

  ok(!$data->{stream}->[18],'Nothing');

  is(scalar(@{$data->{stream}}), 18, 'Length');
};

# Test 2: New format tests with full features (WPD15 corpus)
subtest 'New format with UPOS, MSD, and dependencies (WPD15 corpus)' => sub {
  my $name = 'wpd15-single';
  my @path = (dirname(__FILE__), '..', 'corpus','archives');

  my $file = catfile(@path, $name . '.zip');
  my $archive = KorAP::XML::Archive->new($file);

  unless ($archive->test_unzip) {
    plan skip_all => 'unzip not found';
  };

  ok($archive->attach('#' . catfile(@path, $name . '.spacy.zip')), 'Attach spacy archive');

  my $dir = tempdir(CLEANUP => 1);

  my $f_path = 'WPD15/A00/00081';
  $archive->extract_sigle(0, [$f_path], $dir);

  ok(my $doc = KorAP::XML::Krill->new( path => $dir . '/' . $f_path));

  ok($doc->parse, 'Krill parser works');

  my $tokens = KorAP::XML::Tokenizer->new(
    path => $doc->path,
    doc => $doc,
    foundry => 'Base',
    layer => 'Tokens',
    name => 'tokens'
  ) or return;

  $tokens->parse or return;

  ok($tokens->add('Spacy', 'Morpho'), 'Add Morpho');
  ok($tokens->add('Spacy', 'Dependency'), 'Add Dependency');

  my $data = $tokens->to_data->{data};

  is($data->{tokenSource}, 'base#tokens', 'TokenSource');
  like($data->{foundries}, qr!spacy/morpho!, 'foundries');
  like($data->{foundries}, qr!spacy/dependency!, 'foundries');
  like($data->{layerInfos}, qr!spacy/l=tokens!, 'layerInfos - lemma');
  like($data->{layerInfos}, qr!spacy/p=tokens!, 'layerInfos - XPOS');
  like($data->{layerInfos}, qr!spacy/u=tokens!, 'layerInfos - UPOS');
  like($data->{layerInfos}, qr!spacy/m=tokens!, 'layerInfos - MSD');
  like($data->{layerInfos}, qr!spacy/d=rels!, 'layerInfos - dependency');

  my $stream = $data->{stream};

  is($stream->[0]->[0], '-:tokens$<i>3555', 'Token count');

  # Check morphological features for first token "Anime"
  my $token_0 = $stream->[0];
  ok((grep { $_ eq 'spacy/l:Anime' } @$token_0), 'First token - lemma');
  ok((grep { $_ eq 'spacy/p:NN' } @$token_0), 'First token - XPOS (pos)');
  ok((grep { $_ eq 'spacy/u:NOUN' } @$token_0), 'First token - UPOS');
  ok((grep { $_ eq 'spacy/m:case:nom' } @$token_0), 'First token - MSD Case');
  ok((grep { $_ eq 'spacy/m:gender:masc' } @$token_0), 'First token - MSD Gender');
  ok((grep { $_ eq 'spacy/m:number:sing' } @$token_0), 'First token - MSD Number');

  # Check a punctuation token
  my $token_1 = $stream->[1];
  ok((grep { $_ =~ /^spacy\/l:/ } @$token_1), 'Second token - has lemma');
  ok((grep { $_ =~ /^spacy\/p:/ } @$token_1), 'Second token - has XPOS');
  ok((grep { $_ =~ /^spacy\/u:/ } @$token_1), 'Second token - has UPOS');

  # Check UPOS vs XPOS distinction
  ok((grep { $_ eq 'spacy/p:NN' } @$token_0), 'First token XPOS is NN');
  ok((grep { $_ eq 'spacy/u:NOUN' } @$token_0), 'First token UPOS is NOUN');

  # Token 2: "im" - XPOS=APPRART, UPOS=ADP (preposition with article)
  my $token_2 = $stream->[2];
  ok((grep { $_ eq 'spacy/p:APPRART' } @$token_2), 'Token 2 XPOS is APPRART');
  ok((grep { $_ eq 'spacy/u:ADP' } @$token_2), 'Token 2 UPOS is ADP');

  # Verify MSD is only present on tokens that have morphological features
  my $has_msd_token = 0;
  my $no_msd_token = 0;
  for my $tok (@$stream) {
    next unless ref $tok eq 'ARRAY';
    my $has_msd = 0;
    for my $item (@$tok) {
      if ($item =~ /^spacy\/m:/) {
        $has_msd = 1;
        last;
      }
    }
    $has_msd_token = 1 if $has_msd;
    $no_msd_token = 1 if !$has_msd;
  }
  ok($has_msd_token, 'Some tokens have MSD features');
  ok($no_msd_token, 'Some tokens have no MSD features (e.g., punctuation)');

  # Check dependency relations
  ok((grep { $_ =~ /^>:spacy\/d:sb/ } @$token_0), 'First token has outgoing dependency');

  # Check specific dependency types
  my %dep_types;
  for my $tok (@$stream) {
    next unless ref $tok eq 'ARRAY';
    for my $item (@$tok) {
      if ($item =~ /^[<>]:spacy\/d:(\w+)/) {
        $dep_types{$1} = 1;
      }
    }
  }

  # spaCy German model should have common dependency labels
  ok($dep_types{sb}, 'Found "sb" (subject) dependency');
  ok($dep_types{ROOT}, 'Found "ROOT" dependency');
  ok($dep_types{punct}, 'Found "punct" (punctuation) dependency');
  ok($dep_types{nk}, 'Found "nk" (noun kernel) dependency');

  # Check that dependencies are bidirectional
  my $has_incoming_dep = 0;
  my $has_outgoing_dep = 0;
  my %incoming_targets;
  my %outgoing_targets;

  for my $i (0 .. $#{$stream}) {
    my $tok = $stream->[$i];
    next unless ref $tok eq 'ARRAY';
    for my $item (@$tok) {
      if ($item =~ /^<:spacy\/d:(\w+)(?:\$<b>\d+)?<i>(\d+)/) {
        $has_incoming_dep = 1;
        $incoming_targets{$i} = $2;
      }
      elsif ($item =~ /^>:spacy\/d:(\w+)(?:\$<b>\d+)?<i>(\d+)/) {
        $has_outgoing_dep = 1;
        $outgoing_targets{$i} = $2;
      }
    }
  }

  ok($has_incoming_dep, 'Stream contains incoming dependencies');
  ok($has_outgoing_dep, 'Stream contains outgoing dependencies');

  # Verify bidirectionality
  my $bidirectional_found = 0;
  for my $src (keys %outgoing_targets) {
    my $tgt = $outgoing_targets{$src};
    if (exists $incoming_targets{$tgt} && $incoming_targets{$tgt} == $src) {
      $bidirectional_found = 1;
      last;
    }
  }
  ok($bidirectional_found, 'Dependencies are bidirectional');

  # Count total annotations
  my $upos_count = 0;
  my $xpos_count = 0;
  my $lemma_count = 0;
  my $msd_count = 0;
  my $dep_count = 0;

  for my $tok (@$stream) {
    next unless ref $tok eq 'ARRAY';
    for my $item (@$tok) {
      $upos_count++ if $item =~ /^spacy\/u:/;
      $xpos_count++ if $item =~ /^spacy\/p:/;
      $lemma_count++ if $item =~ /^spacy\/l:/;
      $msd_count++ if $item =~ /^spacy\/m:/;
      $dep_count++ if $item =~ /^[<>]:spacy\/d:/;
    }
  }

  ok($upos_count > 0, "Found $upos_count UPOS annotations");
  ok($xpos_count > 0, "Found $xpos_count XPOS annotations");
  ok($lemma_count > 0, "Found $lemma_count lemma annotations");
  ok($msd_count > 0, "Found $msd_count MSD annotations");
  ok($dep_count > 0, "Found $dep_count dependency annotations");

  # Verify UPOS and XPOS counts match
  is($upos_count, $xpos_count, 'Every token has both UPOS and XPOS');
};

done_testing;

__END__

