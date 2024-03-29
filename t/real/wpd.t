use strict;
use warnings;
use Test::More;
use Data::Dumper;
use JSON::XS;

if ($ENV{SKIP_REAL}) {
  plan skip_all => 'Skip real tests';
};

use Benchmark qw/:hireswallclock/;

my $t = Benchmark->new;

use utf8;
use lib 'lib', '../lib';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

my $path = catdir(dirname(__FILE__), 'corpus','WPD','00001');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'WPD/AAA/00001', 'Correct text sigle');
is($doc->doc_sigle, 'WPD/AAA', 'Correct document sigle');
is($doc->corpus_sigle, 'WPD', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, 'A', 'Title');
is($meta->{S_pub_place}, 'URL:http://de.wikipedia.org', 'PubPlace');
is($meta->{D_pub_date}, '20050328', 'Creation Date');
SKIP: {
  skip 'Failure because corpus is no longer supported', 1;
  ok(!$meta->{T_sub_title}, 'SubTitle');
};
is($meta->{T_author}, 'Ruru; Jens.Ol; Aglarech; u.a.', 'Author');

ok(!$meta->{T_doc_title}, 'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc Sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct Doc editor');

ok(!$meta->{T_corpus_title}, 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus Sub title');

# This link is broken, but that's due to the data
is($meta->{A_externalLink}, 'data:application/x.korap-link;title=Wikipedia,http%3A%2F%2Fde.wikipedia.org', 'No link');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

my ($token_base_foundry, $token_base_layer) = (qw/OpenNLP Tokens/);

# Get tokenization
my $tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => $token_base_foundry,
  layer => $token_base_layer,
  name => 'tokens'
);
ok($tokens, 'Token Object is fine');
ok($tokens->parse, 'Token parsing is fine');

my $output = $tokens->to_data;

is(substr($output->{data}->{text}, 0, 100), 'A bzw. a ist der erste Buchstabe des lateinischen Alphabets und ein Vokal. Der Buchstabe A hat in de', 'Primary Data');
is($output->{data}->{name}, 'tokens', 'tokenName');
is($output->{data}->{tokenSource}, 'opennlp#tokens', 'tokenSource');

is($output->{version}, '0.03', 'version');
is($output->{data}->{foundries}, '', 'Foundries');
is($output->{data}->{layerInfos}, '', 'layerInfos');
is($output->{data}->{stream}->[0]->[4], 's:A', 'data');

$tokens->add('Mate', 'Dependency');

my $stream = $tokens->to_data->{data}->{stream};

# This is not a goot relation example
 is($stream->[79]->[0],
    '>:mate/d:CJ$<b>32<i>68',
    'term to term');
 is($stream->[79]->[1], '<:mate/d:PD$<b>32<i>81', 'term to term');


# These are no longer aligned
# is($stream->[77]->[0],
#    '<:mate/d:--$<b>34<i>498<i>499<i>78<i>78',
#    'element to term');
# is($stream->[78]->[0], '>:mate/d:--$<b>33<i>498<i>499<i>77<i>78', 'term to element');

$tokens->add('Base', 'Sentences');

$stream = $tokens->to_data->{data}->{stream};

is($stream->[0]->[2], '<>:base/s:s$<b>64<i>0<i>74<i>13<b>2', 'Text starts with sentence');


# Problematic document
$path = catdir(dirname(__FILE__), 'corpus','WPD15','W28','65631');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'WPD15/W28/65631', 'Correct text sigle');
is($doc->doc_sigle, 'WPD15/W28', 'Correct document sigle');
is($doc->corpus_sigle, 'WPD15', 'Correct corpus sigle');

$meta = $doc->meta;
is($meta->{A_externalLink}, 'data:application/x.korap-link;title=Wikipedia,http%3A%2F%2Fde.wikipedia.org%2Fwiki%2FWolfgang_Krebs_%28Schauspieler%29', 'link');

# Get tokenization
$tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => 'Base',
  layer => 'tokens_aggr',
  name => 'tokens'
);
ok($tokens, 'Token Object is fine');
ok($tokens->parse, 'Token parsing is fine');

is($tokens->foundry, 'Base', 'Foundry');
is($tokens->layer, 'tokens_aggr', 'Layer');

ok($tokens->add('CoreNLP', 'Constituency'), 'Add Structure');

$output = $tokens->to_data;

is($output->{data}->{foundries}, 'corenlp corenlp/constituency', 'Foundries');
is($output->{data}->{layerInfos}, 'corenlp/c=spans', 'layerInfos');
is($doc->meta->{A_editor}, 'wikipedia.org', 'Editor');


# Check offset problem
$path = catdir(dirname(__FILE__), 'corpus','WPD15','U43','34816');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'WPD15/U43/34816', 'Correct text sigle');

$meta = $doc->meta;
is($meta->{A_externalLink}, 'data:application/x.korap-link;title=Wikipedia,http%3A%2F%2Fde.wikipedia.org%2Fwiki%2FUniversit%E4tsbibliothek_Augsburg');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

$token_base_foundry = 'Base';

# Get tokenization
$tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => $token_base_foundry,
  layer => $token_base_layer,
  name => 'tokens'
);
ok($tokens, 'Token Object is fine');
ok($tokens->parse, 'Token parsing is fine');

$output = $tokens->to_data;
$stream = $tokens->to_data->{data}->{stream};

is($stream->[420]->[-1], 's:online', 'online');
is($stream->[421]->[-1], 's:verfügbar', 'verfügbar');

done_testing;
__END__




