use strict;
use warnings;
use Test::More;
use Data::Dumper;
use JSON::XS;

if ($ENV{SKIP_REAL}) {
  plan skip_all => 'Skip real tests';
};

use utf8;
use lib 'lib', '../lib';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

my $path = catdir(dirname(__FILE__), 'corpus','NEUJ','CEXXXX','000006');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'corpus/CEXXXX/000006', 'Correct text sigle');
is($doc->doc_sigle, 'corpus/CEXXXX', 'Correct document sigle');
is($doc->corpus_sigle, 'corpus', 'Correct corpus sigle');

my $meta = $doc->meta;
ok(!$meta->{T_title}, 'Title'); # fg-baden-wurttemberg-2022-03-24-3-k-279420
ok(!$meta->{T_sub_title}, 'SubTitle');
is($meta->{T_author}, 'p_0', 'Author');
ok(!$meta->{A_editor}, 'Editor');
ok(!$meta->{S_pub_place}, 'PubPlace');
ok(!$meta->{A_publisher}, 'Publisher');

ok(!$meta->{S_text_type}, 'No Text Type');
ok(!$meta->{S_text_type_art}, 'No Text Type Art');
ok(!$meta->{S_text_type_ref}, 'No Text Type Ref');
ok(!$meta->{S_text_domain}, 'No Text Domain');
ok(!$meta->{S_text_column}, 'No Text Column');

ok(!$meta->{K_text_class}, 'Correct Text Class');

is($meta->{D_pub_date}, '20010101', 'Creation date');
# is($meta->{D_creation_date}, '20010101', 'Creation date');

# is($meta->{D_creation_date}, '20020614', 'Creation date');
# is($meta->{S_availability}, 'CC-BY-SA', 'License');
# ok(!$meta->{A_pages}, 'Pages');

ok(!$meta->{A_file_edition_statement}, 'File Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Statement');

is($meta->{A_reference} . "\n", <<'REF', 'Reference');
, 1.1.1 00:00:00 +01:00 Uhr
REF
is($meta->{S_language}, 'de', 'Language');

ok(!$meta->{T_corpus_title}, 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus sub title');
ok(!$meta->{T_corpus_author}, 'Correct Corpus author');
ok(!$meta->{A_corpus_editor}, 'Correct Corpus editor');

ok(!$meta->{T_doc_title}, 'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct doc editor');

is($meta->{I_Jahr},'2003', 'XenoData');
is($meta->{T_Person},'Johannes Rau', 'XenoData');
is($meta->{T_GUID},'5d6a6c99-23b5-47eb-902f-f646ef7e24f5', 'XenoData');

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

is(substr($output->{data}->{text}, 0, 100), 'Liebe Mitbürgerinnen und Mitbürger , herzlich grüße ich sie alle , die Sie hier in Deutschland leben');

is($output->{data}->{name}, 'tokens', 'tokenName');
is($output->{data}->{tokenSource}, 'base#tokens', 'tokenSource');
is($output->{version}, '0.03', 'version');

is($output->{data}->{foundries}, '', 'Foundries');
is($output->{data}->{layerInfos}, '', 'layerInfos');
is($output->{data}->{stream}->[0]->[4], 's:Liebe', 'data');

is($output->{textSigle}, 'corpus/CEXXXX/000006', 'Correct text sigle');
is($output->{docSigle}, 'corpus/CEXXXX', 'Correct document sigle');
is($output->{corpusSigle}, 'corpus', 'Correct corpus sigle');

## Annotations
ok($tokens->add('DeReKo', 'Structure', 'base_sentences_paragraphs'), 'Structure');
ok($tokens->add('CorpusExplorer', 'Morpho'), 'CorpusExplorer Morpho');

$output = decode_json( $tokens->to_json );

is($output->{data}->{foundries}, 'corpusexplorer corpusexplorer/morpho dereko dereko/structure dereko/structure/base_sentences_paragraphs', 'Foundries');
is($output->{data}->{layerInfos}, 'cex/l=tokens cex/p=tokens cex/phrase=tokens dereko/s=spans', 'layerInfos');
my $first_token = join('||', @{$output->{data}->{stream}->[0]});
like($first_token, qr!cex/l:lieb!, 'data');
like($first_token, qr!cex/p:ADJA!, 'data');
# like($first_token, qr!cex/phrase:NC!, 'data');
like($first_token, qr!i:liebe!, 'data');
like($first_token, qr!s:Liebe!, 'data');
like($first_token, qr!<>:dereko/s:body\$<b>64<i>0<i>5176<i>770<b>1!, 'data');

my $middle_token = join('||', @{$output->{data}->{stream}->[119]});
like($middle_token, qr!cex/l:auch!, 'data');
like($middle_token, qr!cex/p:ADV!, 'data');
# like($middle_token, qr!cex/phrase:NC!, 'data');
like($middle_token, qr!i:auch!, 'data');
like($middle_token, qr!s:auch!, 'data');

done_testing;
__END__

