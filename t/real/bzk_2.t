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

my $path = catdir(dirname(__FILE__), 'corpus','BZK','D59','00089');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::XML::Krill');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'BZK/D59/00089', 'Correct text sigle');
is($doc->doc_sigle, 'BZK/D59', 'Correct document sigle');
is($doc->corpus_sigle, 'BZK', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, 'Saragat-Partei zerfällt', 'Title');
ok(!$meta->{T_sub_title}, 'No SubTitle');
ok(!$meta->{T_author}, 'Author');
ok(!$meta->{A_editor}, 'Editor');
is($meta->{S_pub_place}, 'Berlin', 'PubPlace');
is($meta->{D_pub_date}, '19590219', 'PubDate');
ok(!$meta->{A_publisher}, 'Publisher');

is($meta->{K_award}->[0], 'Deutscher Buchpreis 2023', 'Award');
is($meta->{K_award}->[1], 'Booker price 2024', 'Award');

is($meta->{S_text_type}, 'Zeitung: Tageszeitung', 'Correct Text Type');

ok(!$meta->{S_text_type_art}, 'Correct Text Type Art');
is($meta->{S_text_type_ref}, 'Tageszeitung', 'Correct Text Type Ref');
is($meta->{S_text_domain}, 'Politik', 'Correct Text Domain');
is($meta->{S_text_column}, 'POLITIK', 'Correct Text Column');
is($meta->{K_text_class}->[0], 'politik', 'Correct Text Class');
is($meta->{K_text_class}->[1], 'ausland', 'Correct Text Class');
ok(!$meta->{K_text_class}->[2], 'Correct Text Class');

is($meta->{D_creation_date}, '19590219', 'Creation date');
is($meta->{S_availability}, 'ACA-NC-LC', 'License');
ok(!$meta->{pages}, 'Pages');

ok(!$meta->{A_file_edition_statement}, 'File Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Statement');

is($meta->{A_reference} . "\n", <<'REF', 'Reference');
Neues Deutschland, [Tageszeitung], 19.02.1959, Jg. 14, Berliner Ausgabe, S. 7. - Sachgebiet: Politik, Originalressort: POLITIK; Saragat-Partei zerfällt
REF
is($meta->{S_language}, 'de', 'Language');

is($meta->{T_corpus_title}, 'Bonner Zeitungskorpus', 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus sub title');
ok(!$meta->{T_corpus_author}, 'Correct Corpus author');
ok(!$meta->{A_corpus_editor}, 'Correct Corpus editor');

is($meta->{T_doc_title}, 'Neues Deutschland', 'Correct Doc title');
is($meta->{T_doc_sub_title}, 'Organ des Zentralkomitees der Sozialistischen Einheitspartei Deutschlands', 'Correct Doc sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct doc editor');

is($meta->{A_URN},'data:application/x.korap-link;title=urn%3Anbn%3Ade%3A101%3A1-2019012904515398173807,http%3A%2F%2Fnbn-resolving.de%2Furn%3Anbn%3Ade%3A101%3A1-2019012904515398173807');
is($meta->{S_ISBN},'978-3-7325-6705-8');

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

my $output = decode_json( $tokens->to_json );

is(substr($output->{data}->{text}, 0, 100), 'Saragat-Partei zerfällt Rom (ADN) die von dem Rechtssozialisten Saragat geführte Sozialdemokratische', 'Primary Data');
is($output->{data}->{name}, 'tokens', 'tokenName');
is($output->{data}->{tokenSource}, 'opennlp#tokens', 'tokenSource');
is($output->{version}, '0.03', 'version');
is($output->{data}->{foundries}, '', 'Foundries');
is($output->{data}->{layerInfos}, '', 'layerInfos');
is($output->{data}->{stream}->[0]->[4], 's:Saragat-Partei', 'data');

is($output->{textSigle}, 'BZK/D59/00089', 'Correct text sigle');
is($output->{docSigle}, 'BZK/D59', 'Correct document sigle');
is($output->{corpusSigle}, 'BZK', 'Correct corpus sigle');

is($output->{title}, 'Saragat-Partei zerfällt', 'Title');
ok(!exists $output->{subTitle}, 'No SubTitle');
ok(!exists $output->{author}, 'Author');
ok(!exists $output->{editor}, 'Publisher');

is($output->{pubPlace}, 'Berlin', 'PubPlace');
ok(!exists $output->{publisher}, 'Publisher');

is($output->{textType}, 'Zeitung: Tageszeitung', 'Correct Text Type');
ok(!exists $output->{textTypeArt}, 'Correct Text Type Art');
is($output->{textTypeRef}, 'Tageszeitung', 'Correct Text Type Ref');
is($output->{textDomain}, 'Politik', 'Correct Text Domain');
is($output->{textClass}, 'politik ausland', 'Correct Text Domain');

is($output->{creationDate}, '19590219', 'Creation date');
is($output->{availability}, 'ACA-NC-LC', 'License');
ok(!exists $output->{pages}, 'Pages');
ok(!exists $output->{fileEditionStatement}, 'File Statement');
ok(!exists $output->{biblEditionStatement}, 'Bibl Statement');

is($output->{reference} . "\n", <<'REF', 'Reference');
Neues Deutschland, [Tageszeitung], 19.02.1959, Jg. 14, Berliner Ausgabe, S. 7. - Sachgebiet: Politik, Originalressort: POLITIK; Saragat-Partei zerfällt
REF
is($output->{language}, 'de', 'Language');

is($output->{corpusTitle}, 'Bonner Zeitungskorpus', 'Correct Corpus title');
ok(!exists $output->{corpusSubTitle}, 'Correct Corpus sub title');
ok(!exists $output->{corpusAuthor}, 'Correct Corpus author');
ok(!exists $output->{corpusEditor}, 'Correct Corpus editor');

is($output->{docTitle}, 'Neues Deutschland', 'Correct Doc title');
is($output->{docSubTitle}, 'Organ des Zentralkomitees der Sozialistischen Einheitspartei Deutschlands', 'Correct Doc sub title');
ok(!exists $output->{docAuthor}, 'Correct Doc author');
ok(!exists $output->{docEditor}, 'Correct doc editor');

## Base
$tokens->add('Base', 'Sentences');
$tokens->add('Base', 'Paragraphs');

$output = decode_json( $tokens->to_json );

is($output->{data}->{foundries}, 'base base/paragraphs base/sentences', 'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans', 'layerInfos');
my $first_token = join('||', @{$output->{data}->{stream}->[0]});
like($first_token, qr/s:Saragat-Partei/, 'data');
like($first_token, qr/_0\$<i>0<i>14/, 'data');

## OpenNLP
$tokens->add('OpenNLP', 'Sentences');

$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences opennlp opennlp/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans opennlp/s=spans', 'layerInfos');

$tokens->add('OpenNLP', 'Morpho');
$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences opennlp opennlp/morpho opennlp/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans opennlp/p=tokens opennlp/s=spans', 'layerInfos');

## Treetagger
$tokens->add('TreeTagger', 'Sentences');
$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences opennlp opennlp/morpho opennlp/sentences treetagger treetagger/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans opennlp/p=tokens opennlp/s=spans tt/s=spans', 'layerInfos');

$tokens->add('TreeTagger', 'Morpho');
$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences opennlp opennlp/morpho opennlp/sentences treetagger treetagger/morpho treetagger/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans opennlp/p=tokens opennlp/s=spans tt/l=tokens tt/p=tokens tt/s=spans', 'layerInfos');

## CoreNLP
$tokens->add('CoreNLP', 'NamedEntities');
$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences corenlp corenlp/namedentities opennlp opennlp/morpho opennlp/sentences treetagger treetagger/morpho treetagger/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans corenlp/ne=tokens opennlp/p=tokens opennlp/s=spans tt/l=tokens tt/p=tokens tt/s=spans', 'layerInfos');

$tokens->add('CoreNLP', 'Sentences');
$output = decode_json( $tokens->to_json );
is($output->{data}->{foundries},
   'base base/paragraphs base/sentences corenlp corenlp/namedentities corenlp/sentences opennlp opennlp/morpho opennlp/sentences treetagger treetagger/morpho treetagger/sentences',
   'Foundries');
is($output->{data}->{layerInfos}, 'base/s=spans corenlp/ne=tokens corenlp/s=spans opennlp/p=tokens opennlp/s=spans tt/l=tokens tt/p=tokens tt/s=spans', 'layerInfos');

$tokens->add('CoreNLP', 'Morpho');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!corenlp/morpho!, 'Foundries');
like($output->{data}->{layerInfos}, qr!corenlp/p=tokens!, 'layerInfos');

$tokens->add('CoreNLP', 'Constituency');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!corenlp/constituency!, 'Foundries');
like($output->{data}->{layerInfos}, qr!corenlp/c=spans!, 'layerInfos');

## Glemm
$tokens->add('Glemm', 'Morpho');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!glemm/morpho!, 'Foundries');
like($output->{data}->{layerInfos}, qr!glemm/l=tokens!, 'layerInfos');

## Connexor
$tokens->add('Connexor', 'Sentences');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!connexor/sentences!, 'Foundries');
like($output->{data}->{layerInfos}, qr!cnx/s=spans!, 'layerInfos');

$tokens->add('Connexor', 'Morpho');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!connexor/morpho!, 'Foundries');
like($output->{data}->{layerInfos}, qr!cnx/p=tokens!, 'layerInfos');
like($output->{data}->{layerInfos}, qr!cnx/l=tokens!, 'layerInfos');
like($output->{data}->{layerInfos}, qr!cnx/m=tokens!, 'layerInfos');

$tokens->add('Connexor', 'Phrase');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!connexor/phrase!, 'Foundries');
like($output->{data}->{layerInfos}, qr!cnx/c=spans!, 'layerInfos');

$tokens->add('Connexor', 'Syntax');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!connexor/syntax!, 'Foundries');
like($output->{data}->{layerInfos}, qr!cnx/syn=tokens!, 'layerInfos');

## Mate
$tokens->add('Mate', 'Morpho');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!mate/morpho!, 'Foundries');
like($output->{data}->{layerInfos}, qr!mate/p=tokens!, 'layerInfos');
like($output->{data}->{layerInfos}, qr!mate/l=tokens!, 'layerInfos');
like($output->{data}->{layerInfos}, qr!mate/m=tokens!, 'layerInfos');

# diag "No test for mate dependency";

## XIP
$tokens->add('XIP', 'Sentences');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!xip/sentences!, 'Foundries');
like($output->{data}->{layerInfos}, qr!xip/s=spans!, 'layerInfos');

$tokens->add('XIP', 'Morpho');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!xip/morpho!, 'Foundries');
like($output->{data}->{layerInfos}, qr!xip/l=tokens!, 'layerInfos');
like($output->{data}->{layerInfos}, qr!xip/p=tokens!, 'layerInfos');

$tokens->add('XIP', 'Constituency');
$output = decode_json( $tokens->to_json );
like($output->{data}->{foundries}, qr!xip/constituency!, 'Foundries');
like($output->{data}->{layerInfos}, qr!xip/c=spans!, 'layerInfos');

# diag "No test for xip dependency";

done_testing;
__END__
