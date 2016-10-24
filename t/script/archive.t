#/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use File::Temp qw/tempdir/;
use Mojo::Util qw/slurp/;
use Mojo::JSON qw/decode_json/;
use IO::Uncompress::Gunzip;
use Test::More;
use Test::Output qw/:stdout :stderr :functions/;
use Data::Dumper;
use KorAP::XML::Archive;
use utf8;

my $f = dirname(__FILE__);
my $script = catfile($f, '..', '..', 'script', 'korapxml2krill');

my $call = join(
  ' ',
  'perl', $script,
  'archive'
);

unless (KorAP::XML::Archive::test_unzip) {
  plan skip_all => 'unzip not found';
};

# Test without parameters
stdout_like(
  sub {
    system($call);
  },
  qr!archive.+?Process an!s,
  $call
);

my $input = catfile($f, '..', 'corpus', 'archive.zip');
ok(-f $input, 'Input archive found');

my $output = File::Temp->newdir(CLEANUP => 0);
$output->unlink_on_destroy(0);

ok(-d $output, 'Output directory exists');

$call = join(
  ' ',
  'perl', $script,
  'archive',
  '--input' => $input,
  '--output' => $output,
  '-t' => 'Base#tokens_aggr',
  '-m' => 'Sgbr'
);

# Test without compression
my $json;
{
  local $SIG{__WARN__} = sub {};
  my $out = stdout_from(sub { system($call); });

  like($out, qr!TEST-BSP-1\.json!s, $call);

  $out =~ m!Processed (.+?\.json)!;
  $json = $1;
};

ok(-f $json, 'Json file exists');
ok((my $file = slurp $json), 'Slurp data');
ok(($json = decode_json $file), 'decode json');

is($json->{data}->{tokenSource}, 'base#tokens_aggr', 'Title');
is($json->{data}->{foundries}, 'base base/paragraphs base/sentences dereko dereko/structure sgbr sgbr/lemma sgbr/morpho', 'Foundries');
is($json->{sgbrKodex}, 'M', 'Kodex meta data');


# Use directory
$input = catdir($f, '..', 'annotation', 'corpus');

$call = join(
  ' ',
  'perl', $script,
  'archive',
  '--input' => $input,
  '--output' => $output,
  '-t' => 'Tree_Tagger#Tokens',
  '-j' => 4 # 4 jobs!
);

my ($json_1, $json_2);

{
  local $SIG{__WARN__} = sub {};

  # That's not really stable on slow machines!
  my $out = stdout_from(sub { system($call); });

  ok($out =~ m!\[\$(\d+?):1\/2\]!s, $call . ' pid 1');
  my $pid1 = $1;
  ok($out =~ m!\[\$(\d+?):2\/2\]!s, $call . ' pid 2');
  my $pid2 = $1;

  isnt($pid1, $pid2, 'No PID match');

  ok($out =~ m!Processed .+?\/corpus-doc-0001\.json!s, $call);
  ok($out =~ m!Processed .+?\/corpus-doc-0002\.json!s, $call);

  ok(-d $output, 'Temporary directory still exists');
  my $json_1 = catfile($output, 'corpus-doc-0001.json');
  ok(-f $json_1, 'Json file exists 1');
  my $json_2 = catfile($output, 'corpus-doc-0002.json');
  ok(-f $json_2, 'Json file exists 2');

  ok(($file = slurp $json_1), 'Slurp data');
  ok(($json_1 = decode_json $file), 'decode json');

  is($json_1->{data}->{tokenSource}, 'tree_tagger#tokens', 'TokenSource');
  is($json_1->{data}->{foundries}, 'base base/paragraphs base/sentences connexor connexor/morpho connexor/phrase connexor/sentences connexor/syntax corenlp corenlp/constituency corenlp/morpho corenlp/sentences dereko dereko/structure glemm glemm/morpho mate mate/dependency mate/morpho opennlp opennlp/morpho opennlp/sentences treetagger treetagger/morpho treetagger/sentences xip xip/constituency xip/morpho xip/sentences', 'Foundries');
  is($json_1->{textSigle}, 'Corpus/Doc/0001', 'Sigle');

  ok(-f $json_2, 'Json file exists');
  ok(($file = slurp $json_2), 'Slurp data');
  ok(($json_2 = decode_json $file), 'decode json');

  is($json_2->{data}->{tokenSource}, 'tree_tagger#tokens', 'TokenSource');
  is($json_2->{data}->{foundries}, 'base base/paragraphs base/sentences dereko dereko/structure malt malt/dependency treetagger treetagger/morpho treetagger/sentences', 'Foundries');
  is($json_2->{textSigle}, 'Corpus/Doc/0002', 'Sigle');
};

ok(-d $output, 'Ouput directory exists');
unlink($output);

done_testing;
__END__
