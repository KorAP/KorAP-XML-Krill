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

# This will Check KoKoKom-Files

my $path = catdir(dirname(__FILE__), 'corpus','KTC','001','000001');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'KTC/001/000001', 'Correct text sigle');
is($doc->doc_sigle, 'KTC/001', 'Correct document sigle');
is($doc->corpus_sigle, 'KTC', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, 'ohne Titel', 'Title');
is($meta->{S_pub_place}, 'San Bruno, California / Berlin', 'PubPlace');
is($meta->{D_pub_date}, '20221127', 'Creation Date');
ok(!$meta->{T_sub_title}, 'SubTitle');
is($meta->{T_author}, 'maiLab', 'Author');

is($meta->{A_publisher}, 'Youtube / ARD', 'Publisher');
ok(!$meta->{A_editor}, 'Editor');
ok(!$meta->{A_translator}, 'Translator');
ok(!$meta->{S_text_type}, 'Correct Text Type');
ok(!$meta->{S_text_type_art}, 'Correct Text Type Art');
ok(!$meta->{S_text_type_ref}, 'Correct Text Type Ref');
ok(!$meta->{S_text_column}, 'Correct Text Column');
ok(!$meta->{S_text_domain}, 'Correct Text Domain');
ok(!$meta->{D_creation_date}, 'Creation Date');

ok(!$meta->{pages}, 'Pages');
ok(!$meta->{A_file_edition_statement}, 'File Ed Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Ed Statement');
is($meta->{A_reference}, 'KTC/001.000001, Transkript, 27.11.2022. maiLab: in: KTC/001., - Youtube / ARD', 'Reference');
# is($meta->{S_language}, 'de', 'Language');

is($meta->{T_corpus_title}, 'KoKoKom Transkriptkorpus', 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus Sub title');
ok(!$meta->{T_corpus_author}, 'Correct Corpus author');
ok(!$meta->{A_corpus_editor}, 'Correct Corpus editor');

is($meta->{T_doc_title}, 'ohne Titel', 'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc Sub title');
is($meta->{T_doc_author},'maiLab', 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct Doc editor');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

my ($token_base_foundry, $token_base_layer) = (qw/Base tokens/);

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

$output = $tokens->to_data;

is($output->{data}->{foundries}, 'dereko dereko/structure dereko/structure/base_sentences_paragraphs', 'Foundries');

is($output->{data}->{layerInfos}, 'dereko/s=spans', 'layerInfos');

my $token = join('||', @{$output->{data}->{stream}->[7]});

like($token, qr!i:man!, 'data');

$token = join('||', @{$output->{data}->{stream}->[9]});

like($token, qr!i:öffentliche!, 'data');

$token = join('||', @{$output->{data}->{stream}->[0]});

like($token, qr!\<\>:dereko/s:u\$<b>64<i>0<i>125<i>17<b>3<s>2!, 'data');
like($token, qr!\@:dereko\/s:who:Mai Thi Nguyen-Kim\$<b>17<s>2<i>17!, 'data');
like($token, qr!\@:dereko\/s:start:0:00\$<b>17<s>2<i>17!, 'data');
like($token, qr!\@:dereko\/s:end:01:20\$<b>17<s>2<i>17!, 'data');

like($token, qr!\~:base\/s:marker\$<i>0<i>0<x>who:Mai Thi Nguyen-Kim!, 'data');
like($token, qr!\~:base\/s:marker\$<i>0<i>0<x>start:0:00!, 'data');
like($token, qr!\~:base\/s:marker\$<i>0<i>0<x>end:01:20!, 'data');

diag $tokens->to_json;

done_testing;
__END__

