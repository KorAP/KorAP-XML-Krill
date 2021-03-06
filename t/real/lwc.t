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

# This will Check LWC annotations

# New

my $path = catdir(dirname(__FILE__), 'corpus','WPD17','000','22053');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'WPD17/000/22053', 'Correct text sigle');
is($doc->doc_sigle, 'WPD17/000', 'Correct document sigle');
is($doc->corpus_sigle, 'WPD17', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, '0er', 'Title');
is($meta->{S_pub_place}, 'URL:http://de.wikipedia.org', 'PubPlace');
is($meta->{D_pub_date}, '20170701', 'Creation Date');
ok(!$meta->{T_sub_title}, 'SubTitle');
is($meta->{T_author}, 'Rogi.Official, u.a.', 'Author');

is($meta->{A_publisher}, 'Wikipedia', 'Publisher');
is($meta->{A_editor},'wikipedia.org', 'Editor');
ok(!$meta->{translator}, 'Translator');
is($meta->{S_text_type}, 'Enzyklopädie', 'Correct Text Type');
is($meta->{S_text_type_art}, 'Enzyklopädie-Artikel', 'Correct Text Type Art');
ok(!$meta->{S_text_type_ref}, 'Correct Text Type Ref');
ok(!$meta->{S_text_column}, 'Correct Text Column');
ok(!$meta->{S_text_domain}, 'Correct Text Domain');
is($meta->{D_creation_date},'20150511', 'Creation Date');

ok(!$meta->{pages}, 'Pages');
ok(!$meta->{A_file_edition_statement}, 'File Ed Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Ed Statement');
is($meta->{A_reference}, '0er, In: Wikipedia - URL:http://de.wikipedia.org/wiki/0er: Wikipedia, 2017', 'Reference');
is($meta->{S_language}, 'de', 'Language');

is($meta->{T_corpus_title}, 'Wikipedia', 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus Sub title');
ok(!$meta->{T_corpus_author}, 'Correct Corpus author');
is($meta->{A_corpus_editor}, 'wikipedia.org', 'Correct Corpus editor');

is($meta->{T_doc_title}, 'Wikipedia, Artikel mit Anfangszahl 0, Teil 00', 'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc Sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct Doc editor');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

my ($token_base_foundry, $token_base_layer) = (qw/Base Tokens/);

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

# LWC
ok($tokens->add('LWC', 'Dependency'), 'Add LWC dependency annotations');

$output = $tokens->to_data;

is($output->{data}->{foundries},
   'dereko dereko/structure dereko/structure/base_sentences_paragraphs lwc lwc/dependency',
   'Foundries');

is($output->{data}->{layerInfos}, 'dereko/s=spans lwc/d=rels', 'layerInfos');

my $token = join('||', @{$output->{data}->{stream}->[7]});

like($token, qr!>:lwc/d:SVP\$<b>32<i>4!, 'data');
like($token, qr!i:statt!, 'data');

$token = join('||', @{$output->{data}->{stream}->[9]});

like($token, qr!>:lwc/d:--\$<b>33<i>64<i>76<i>8<i>11!, 'data');
like($token, qr!s:Januar!, 'data');


$path = catdir(dirname(__FILE__), 'corpus','WPD17','060','18486');

ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

$meta = $doc->meta;

is($meta->{T_doc_title}, 'Wikipedia, Artikel mit Anfangszahl 0, Teil 60', 'No doc title');
ok(!exists $meta->{translator}, 'No translator');

is($meta->{K_text_class}->[0], 'staat-gesellschaft', 'text class');
is($meta->{K_text_class}->[1], 'verbrechen', 'text class');




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

## Base
$tokens->add('DeReKo', 'Structure', 'base_sentences_paragraphs');

# LWC
ok($tokens->add('LWC', 'Dependency'), 'Add LWC dependency annotations');

$output = decode_json( $tokens->to_json );

$token = join('||', @{$output->{data}->{stream}->[2]});

like($token, qr!>:lwc/d:SVP\$<b>32<i>1!, 'data');
like($token, qr!s:für!, 'data');


done_testing;
__END__
