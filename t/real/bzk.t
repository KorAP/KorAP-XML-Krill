use strict;
use warnings;
use Test::More;
use Data::Dumper;
use JSON::XS;
use Log::Log4perl;

use Benchmark qw/:hireswallclock/;

my $t = Benchmark->new;

use utf8;
use lib 'lib', '../lib';

#Log::Log4perl->init({
#  'log4perl.rootLogger' => 'DEBUG, STDERR',
#  'log4perl.appender.STDERR' => 'Log::Log4perl::Appender::ScreenColoredLevels',
#  'log4perl.appender.STDERR.layout' => 'PatternLayout',
#  'log4perl.appender.STDERR.layout.ConversionPattern' => '[%r] %F %L %c - %m%n'
#});

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

my $path = catdir(dirname(__FILE__), '..', 'corpus', 'BZK', 'D59', '00001');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'BZK/D59/00001', 'Correct text sigle');
is($doc->doc_sigle, 'BZK/D59', 'Correct document sigle');
is($doc->corpus_sigle, 'BZK', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{title}, 'Unser gemeinsames Werk wird siegreich sein', 'Title');
ok(!$meta->{sub_title}, 'No SubTitle');
ok(!$meta->{author}, 'Author');
ok(!$meta->{editor}, 'Editor');
is($meta->{pub_place}, 'Berlin', 'PubPlace');
ok(!$meta->{publisher}, 'Publisher');

is($meta->{text_type}, 'Zeitung: Tageszeitung', 'Correct Text Type');

ok(!$meta->{text_type_art}, 'Correct Text Type Art');
is($meta->{text_type_ref}, 'Tageszeitung', 'Correct Text Type Ref');
is($meta->{text_domain}, 'Politik', 'Correct Text Domain');
is($meta->{text_column}, 'POLITIK', 'Correct Text Column');
is($meta->{text_class}->[0], 'politik', 'Correct Text Class');
is($meta->{text_class}->[1], 'ausland', 'Correct Text Class');
ok(!$meta->{text_class}->[2], 'Correct Text Class');

is($meta->{pub_date}, '19590101', 'Creation date');
is($meta->{creation_date}, '19590101', 'Creation date');
is($meta->{availability}, 'ACA-NC-LC', 'License');
ok(!$meta->{pages}, 'Pages');

ok(!$meta->{file_edition_statement}, 'File Statement');
ok(!$meta->{bibl_edition_statement}, 'Bibl Statement');

is($meta->{reference} . "\n", <<'REF', 'Reference');
Neues Deutschland, [Tageszeitung], 01.01.1959, Jg. 14, Berliner Ausgabe, S. 1. - Sachgebiet: Politik, Originalressort: POLITIK; Unser gemeinsames Werk wird siegreich sein
REF
is($meta->{language}, 'de', 'Language');

is($meta->{corpus_title}, 'Bonner Zeitungskorpus', 'Correct Corpus title');
ok(!$meta->{corpus_sub_title}, 'Correct Corpus sub title');
ok(!$meta->{corpus_author}, 'Correct Corpus author');
ok(!$meta->{corpus_editor}, 'Correct Corpus editor');

is($meta->{doc_title}, 'Neues Deutschland', 'Correct Doc title');
is($meta->{doc_sub_title}, 'Organ des Zentralkomitees der Sozialistischen Einheitspartei Deutschlands', 'Correct Doc sub title');
ok(!$meta->{doc_author}, 'Correct Doc author');
ok(!$meta->{doc_editor}, 'Correct doc editor');

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

is(substr($output->{data}->{text}, 0, 100), 'unser gemeinsames Werk wird siegreich sein Neujahrsbotschaft des Präsidenten der DeutschenDemokratis', 'Primary Data');
is($output->{data}->{name}, 'tokens', 'tokenName');
is($output->{data}->{tokenSource}, 'opennlp#tokens', 'tokenSource');
is($output->{version}, '0.03', 'version');
is($output->{data}->{foundries}, '', 'Foundries');
is($output->{data}->{layerInfos}, '', 'layerInfos');
is($output->{data}->{stream}->[0]->[4], 's:unser', 'data');

is($output->{textSigle}, 'BZK/D59/00001', 'Correct text sigle');
is($output->{docSigle}, 'BZK/D59', 'Correct document sigle');
is($output->{corpusSigle}, 'BZK', 'Correct corpus sigle');

is($output->{title}, 'Unser gemeinsames Werk wird siegreich sein', 'Title');
ok(!exists $output->{subTitle}, 'No SubTitle');
ok(!exists $output->{author}, 'Author');
ok(!exists $output->{editor}, 'Publisher');

is($output->{pubPlace}, 'Berlin', 'PubPlace');
ok(!exists $output->{publisher}, 'Publisher');

is($output->{textType}, 'Zeitung: Tageszeitung', 'Correct Text Type');
ok(!exists $output->{textTypeArt}, 'Correct Text Type Art');
is($output->{textTypeRef}, 'Tageszeitung', 'Correct Text Type Ref');
is($output->{textDomain}, 'Politik', 'Correct Text Domain');

is($output->{creationDate}, '19590101', 'Creation date');
is($output->{availability}, 'ACA-NC-LC', 'License');
ok(!exists $output->{pages}, 'Pages');
ok(!exists $output->{fileEditionStatement}, 'File Statement');
ok(!exists $output->{biblEditionStatement}, 'Bibl Statement');

is($output->{reference} . "\n", <<'REF', 'Reference');
Neues Deutschland, [Tageszeitung], 01.01.1959, Jg. 14, Berliner Ausgabe, S. 1. - Sachgebiet: Politik, Originalressort: POLITIK; Unser gemeinsames Werk wird siegreich sein
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
like($first_token, qr/s:unser/, 'data');
like($first_token, qr/_0\$<i>0<i>5/, 'data');

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

## Mate - not in existence
{
  local $SIG{__WARN__} = sub {};
  $tokens->add('Mate', 'Morpho');
  $output = decode_json( $tokens->to_json );
  unlike($output->{data}->{foundries}, qr!mate/morpho!, 'Foundries');
  unlike($output->{data}->{layerInfos}, qr!mate/p=tokens!, 'layerInfos');
  unlike($output->{data}->{layerInfos}, qr!mate/l=tokens!, 'layerInfos');
  unlike($output->{data}->{layerInfos}, qr!mate/m=tokens!, 'layerInfos');
};

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
