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

# This will Check DRuKoLa-Files

# New
# BBU/BLOG/83709_a_82384
my $path = catdir(dirname(__FILE__), 'corpus','CoRoLa','BBU','BLOG','83709_a_82384');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'BBU/BLOG/83709_a_82384', 'Correct text sigle');
is($doc->doc_sigle, 'BBU/BLOG', 'Correct document sigle');
is($doc->corpus_sigle, 'BBU', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, 'Schimbă vorba', 'Title');
is($meta->{S_pub_place}, 'URL:http://www.bucurenci.ro', 'PubPlace');
is($meta->{D_pub_date}, '20131005', 'Creation Date');
ok(!$meta->{T_sub_title}, 'SubTitle');
is($meta->{T_author}, 'Dragoș Bucurenci', 'Author');

ok(!$meta->{A_publisher}, 'Publisher');
ok(!$meta->{A_editor}, 'Editor');
is($meta->{A_translator}, '[TRANSLATOR]', 'Translator');
ok(!$meta->{T_translator}, 'Translator');
#is($meta->{S_text_type}, 'Autobiographie', 'Correct Text Type');
ok(!$meta->{S_text_type_art}, 'Correct Text Type Art');
# is($meta->{S_text_type_ref}, '', 'Correct Text Type Ref');
ok(!$meta->{S_text_column}, 'Correct Text Column');
ok(!$meta->{S_text_domain}, 'Correct Text Domain');
ok(!$meta->{D_creation_date}, 'Creation Date');

ok(!$meta->{pages}, 'Pages');
ok(!$meta->{A_file_edition_statement}, 'File Ed Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Ed Statement');
ok(!$meta->{A_reference}, 'Reference');
is($meta->{S_language}, 'ro', 'Language');

#is($meta->{T_corpus_title}, 'Goethes Werke', 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus Sub title');
#is($meta->{T_corpus_author}, 'Goethe, Johann Wolfgang von', 'Correct Corpus author');
#is($meta->{A_corpus_editor}, 'Trunz, Erich', 'Correct Corpus editor');

#is($meta->{T_doc_title}, 'Goethe: Autobiographische Schriften II, (1817-1825, 1832)',
#   'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc Sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct Doc editor');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

my ($token_base_foundry, $token_base_layer) = (qw/Base Tokens_conservative/);

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

my $output = decode_json( $tokens->to_json );

## Base
$tokens->add('DeReKo', 'Structure', 'base_sentences_paragraphs');
ok($tokens->add('DRuKoLa', 'Morpho'), 'Add Drukola');

$output = $tokens->to_data;

is($output->{data}->{foundries}, 'dereko dereko/structure dereko/structure/base_sentences_paragraphs drukola drukola/morpho', 'Foundries');

is($output->{data}->{layerInfos}, 'dereko/s=spans drukola/l=tokens drukola/m=tokens drukola/p=tokens', 'layerInfos');

my $token = join('||', @{$output->{data}->{stream}->[7]});

like($token, qr!drukola/l:la!, 'data');
like($token, qr!drukola/m:msd:Sp!, 'data');
like($token, qr!drukola/p:ADPOSITION!, 'data');

$token = join('||', @{$output->{data}->{stream}->[9]});

like($token, qr!i:vorba!, 'data');
like($token, qr!drukola/l:vorbă!, 'data');
like($token, qr!drukola/m:case:Ncfsry!, 'data');
like($token, qr!drukola/m:definiteness:yes!, 'data');
like($token, qr!drukola/m:gender:feminine!, 'data');
like($token, qr!drukola/p:NOUN!, 'data');


# New
# BBU2/BLOG/83709_a_82384
$path = catdir(dirname(__FILE__), 'corpus','CoRoLa','BBU2','Blog','83701_a_82376');

ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

$meta = $doc->meta;

ok(!exists $meta->{T_doc_title}, 'No doc title');
ok(!exists $meta->{translator}, 'No translator');

ok(!exists $meta->{K_text_class}, 'No translator');



$path = catdir(dirname(__FILE__), 'corpus','CoRoLa','Corola-Journal','-','247_a_537');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

$meta = $doc->meta;
is($meta->text_sigle, 'Corola-Journal/-/247_a_537', 'Text Sigle');
is($meta->doc_sigle, 'Corola-Journal/-', 'Doc Sigle');
is($meta->corpus_sigle, 'Corola-Journal', 'Corpus Sigle');
is($meta->{K_text_class}->[0], 'Sport', 'Text class');


$path = catdir(dirname(__FILE__), 'corpus','CoRoLa','Corola-Journal','COLEGIUL NATIONAL „OCTAV BANCILA“ - IASI','326_a_562');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

$meta = $doc->meta;
is($meta->text_sigle, 'Corola-Journal/COLEGIUL NATIONAL „OCTAV BANCILA“ - IASI/326_a_562', 'Text Sigle');
is($meta->doc_sigle, 'Corola-Journal/COLEGIUL NATIONAL „OCTAV BANCILA“ - IASI', 'Doc Sigle');
is($meta->corpus_sigle, 'Corola-Journal', 'Corpus Sigle');
is($meta->{T_title}, 'APOGEUL ARHITECTURĂ ȘI DESIGN', 'Title');



# Old translator behaviour:
our %ENV;
$ENV{K2K_TRANSLATOR_TEXT} = 1;
$path = catdir(dirname(__FILE__), 'corpus','CoRoLa','BBU','BLOG','83709_a_82384');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'BBU/BLOG/83709_a_82384', 'Correct text sigle');
$meta = $doc->meta;
is($meta->{T_translator}, '[TRANSLATOR]', 'Translator');
ok(!$meta->{A_translator}, 'Translator');
$ENV{K2K_TRANSLATOR_TEXT} = 0;


done_testing;
__END__
