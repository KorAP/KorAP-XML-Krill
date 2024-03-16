#/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use File::Temp qw/:POSIX/;
use Mojo::File;
use Mojo::JSON qw/decode_json/;
use IO::Uncompress::Gunzip;
use Test::More;
use Test::Output;
use Data::Dumper;
use utf8;

if ($ENV{SKIP_SCRIPT}) {
  plan skip_all => 'Skip script tests';
};

my $f = dirname(__FILE__);
my $script = catfile($f, '..', '..', 'script', 'korapxml2krill');

my $input = catdir($f, '..', 'annotation', 'corpus', 'doc', '0001');
ok(-d $input, 'Input directory found');

my $output = tmpnam();
my $cache = tmpnam();


ok(!-f $output, 'Output does not exist');

my $call = join(
  ' ',
  'perl', $script,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache,
  '-k' => 0.03,
  '-t' => 'OpenNLP#Tokens',
  '-l' => 'INFO'
);

# Test without compression
stderr_like(
  sub {
    system($call);
  },
  qr!The code took!,
  $call
);

ok(-f $output, 'Output does exist');
ok((my $file = Mojo::File->new($output)->slurp), 'Slurp data');
ok((my $json = decode_json $file), 'decode json');
is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');
is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'Title');
is($json->{data}->{foundries}, 'base base/paragraphs base/sentences connexor connexor/morpho connexor/phrase connexor/sentences connexor/syntax corenlp corenlp/constituency corenlp/morpho corenlp/sentences dereko dereko/structure glemm glemm/morpho mate mate/dependency mate/morpho opennlp opennlp/morpho opennlp/sentences spacy spacy/morpho treetagger treetagger/morpho treetagger/sentences xip xip/constituency xip/morpho xip/sentences', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:base/paragraphs$<i>1', 'Paragraphs');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'TokenSource');

# Delete output
unlink $output;
ok(!-f $output, 'Output does not exist');

$call .= ' -z';

# Test with compression
stderr_like(
  sub { system($call); },
  qr!The code took!,
  $call
);

ok(-f $output, 'Output does exist');

# Uncompress the data using a buffer
my $gz = IO::Uncompress::Gunzip->new($output, Transparent => 0);
($file, my $buffer) = '';
while ($gz->read($buffer)) {
  $file .= $buffer;
};
$gz->close;

ok($json = decode_json($file), 'decode json');

is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');
is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'TokenSource');
is($json->{data}->{foundries}, 'base base/paragraphs base/sentences connexor connexor/morpho connexor/phrase connexor/sentences connexor/syntax corenlp corenlp/constituency corenlp/morpho corenlp/sentences dereko dereko/structure glemm glemm/morpho mate mate/dependency mate/morpho opennlp opennlp/morpho opennlp/sentences spacy spacy/morpho treetagger treetagger/morpho treetagger/sentences xip xip/constituency xip/morpho xip/sentences', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:base/paragraphs$<i>1', 'Paragraphs');

# Delete output
is(unlink($output), 1, 'Unlink successful');
ok(!-e $output, 'Output does not exist');

# Use a different token source and skip all annotations,
# except for DeReKo#Structure and Mate#Dependency
$call = join(
  ' ',
  'perl', $script,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache,
  '-t' => 'CoreNLP#Tokens',
  '-s' => '#all',
  '-a' => 'DeReKo#Structure',
  '-a' => 'Mate#Dependency',
  '-l' => 'INFO'
);

stderr_like(
  sub {
    system($call);
  },
  qr!The code took!,
  $call
);

ok(-f $output, 'Output does exist');
ok(($file = Mojo::File->new($output)->slurp), 'Slurp data');
ok(($json = decode_json $file), 'decode json');

is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');

is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'corenlp#tokens', 'TokenSource');
is($json->{data}->{foundries}, 'dereko dereko/structure mate mate/dependency', 'Foundries');

like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:tokens$<i>20', 'Tokens');


# Check overwrite
$call = join(
  ' ',
  'perl', $script,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache,
  '-t' => 'CoreNLP#Tokens',
  '-s' => '#all',
  '-a' => 'DeReKo#Structure',
  '-a' => 'Mate#Dependency',
  '-l' => 'DEBUG'
);

ok(-f $output, 'Output does exist');
stderr_like(
  sub {
    system($call);
  },
  qr!already exists!,
  $call
);

$call .= ' -w ';

stderr_unlike(
  sub {
    system($call);
  },
  qr!already exists!,
  $call
);

# Check meta data switch

# Delete output
unlink $output;
ok(!-f $output, 'Output does not exist');

# Koral version
$input = catdir($f, '..', 'annotation', 'corpus', 'doc', '0001');
$call = join(
  ' ',
  'perl', $script,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache,
  '-t' => 'OpenNLP#Tokens',
  '-k' => 0.4,
  '-l' => 'INFO'
);

$call .= ' -w ';

stderr_like(
  sub {
    system($call);
  },
  qr!The code took!,
  $call
);

ok(-f $output, 'Output does exist');
ok(($file = Mojo::File->new($output)->slurp), 'Slurp data');
ok(($json = decode_json $file), 'decode json');
ok(!$json->{textType}, 'text type');
ok(!$json->{title}, 'Title');

is($json->{fields}->[0]->{key}, 'corpusSigle');
is($json->{fields}->[0]->{type}, 'type:string');
is($json->{fields}->[0]->{value}, 'Corpus');
is($json->{fields}->[0]->{'@type'}, 'koral:field');

is($json->{fields}->[4]->{key}, 'distributor');
is($json->{fields}->[4]->{value}, 'data:,Institut für Deutsche Sprache');
is($json->{fields}->[4]->{type}, 'type:attachement');
is($json->{fields}->[4]->{'@type'}, 'koral:field');

is($json->{fields}->[9]->{key}, 'textClass');
is($json->{fields}->[9]->{value}->[0], 'freizeit-unterhaltung');
is($json->{fields}->[9]->{value}->[1], 'vereine-veranstaltungen');
is($json->{fields}->[9]->{type}, 'type:keywords');
is($json->{fields}->[9]->{'@type'}, 'koral:field');

is($json->{fields}->[14]->{key}, 'textType');
is($json->{fields}->[14]->{value}, 'Zeitung: Tageszeitung');
is($json->{fields}->[14]->{type}, 'type:string');
is($json->{fields}->[14]->{'@type'}, 'koral:field');

is($json->{fields}->[22]->{key}, 'title');
is($json->{fields}->[22]->{value}, 'Beispiel Text');
is($json->{fields}->[22]->{type}, 'type:text');
is($json->{fields}->[22]->{'@type'}, 'koral:field');

is($json->{data}->{tokenSource}, 'opennlp#tokens', 'Title');
is($json->{data}->{foundries}, 'base base/paragraphs base/sentences connexor connexor/morpho connexor/phrase connexor/sentences connexor/syntax corenlp corenlp/constituency corenlp/morpho corenlp/sentences dereko dereko/structure glemm glemm/morpho mate mate/dependency mate/morpho opennlp opennlp/morpho opennlp/sentences spacy spacy/morpho treetagger treetagger/morpho treetagger/sentences xip xip/constituency xip/morpho xip/sentences', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:base/paragraphs$<i>1', 'Paragraphs');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'TokenSource');

my $token = join(',',@{$json->{data}->{stream}->[1]});

like($token, qr!<>:xip\/c:AP\$<b>64<i>4<i>11<i>2<b>5!);
like($token, qr!<>:xip\/c:ADJ\$<b>64<i>4<i>11<i>2<b>6!);
like($token, qr!<>:cnx\/c:np\$<b>64<i>4<i>30<i>4<b>0!);
like($token, qr!<>:xip\/c:NP\$<b>64<i>4<i>30<i>4<b>3!);
like($token, qr!<>:xip\/c:NPA\$<b>64<i>4<i>30<i>4<b>4!);
like($token, qr!>:mate\/d:NK\$<b>32<i>3!);
like($token, qr!_1\$<i>4<i>11!);
like($token, qr!cnx\/l:letzt!);
like($token, qr!cnx\/p:A!);
like($token, qr!cnx\/syn:\@PREMOD!);
like($token, qr!corenlp\/p:ADJ!);
like($token, qr!glemm\/l:__letzt-!);
like($token, qr!i:letzten!);
like($token, qr!mate\/l:letzter!);
like($token, qr!mate\/m:case:dat!);
like($token, qr!mate\/m:degree:pos!);
like($token, qr!mate\/m:gender:neut!);
like($token, qr!mate\/m:number:sg!);
like($token, qr!mate\/p:ADJA!);
like($token, qr!opennlp\/p:ADJA!);
like($token, qr!s:letzten!);
like($token, qr!spacy\/l:letzter!);
like($token, qr!spacy\/p:ADJ!);
like($token, qr!tt\/l:letzt!);
like($token, qr!tt\/p:ADJA!);
like($token, qr!xip\/l:letzt!);
like($token, qr!xip\/p:ADJ!);

# Delete output
unlink $output;
ok(!-f $output, 'Output does not exist');


# Koral version
$input = catdir($f, '..', 'real', 'corpus', 'NKJP', 'NKJP', 'KOT');
$call = join(
  ' ',
  'perl', $script,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache,
  '-t' => 'NKJP#Morpho',
  '-l' => 'INFO',
  '--lang' => 'en'
);

$call .= ' -w ';

stderr_like(
  sub {
    system($call);
  },
  qr!The code took!,
  $call
);

ok(-f $output, 'Output does exist');
ok(($file = Mojo::File->new($output)->slurp), 'Slurp data');
ok(($json = decode_json $file), 'decode json');
is($json->{corpusTitle}, 'National Corpus of Polish -- the 1 million word subcorpus', 'Title');





done_testing;
__END__

