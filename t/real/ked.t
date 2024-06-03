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

# This will Check KED-Files - especially regarding Xenodata

my $path = catdir(dirname(__FILE__), 'corpus','KED','KLX','03212');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

is($doc->text_sigle, 'KED/KLX/03212', 'Correct text sigle');
is($doc->doc_sigle, 'KED/KLX', 'Correct document sigle');
is($doc->corpus_sigle, 'KED', 'Correct corpus sigle');

my $meta = $doc->meta;
is($meta->{T_title}, 'Flöhe', 'Title');
is($meta->{S_pub_place}, 'klexikon.zum.de', 'PubPlace');
is($meta->{D_pub_date}, '20230309', 'Creation Date');
ok(!$meta->{T_sub_title}, 'SubTitle');
ok(!$meta->{T_author}, 'No author');

is($meta->{A_publisher}, 'klexikon.zum.de', 'Publisher');
ok(!$meta->{A_editor}, 'Editor');
ok(!$meta->{A_translator}, 'Translator');
is($meta->{S_text_type}, 'Webtext:Lexikonartikel', 'Correct Text Type');
is($meta->{S_text_type_art}, 'Lexikonartikel', 'Correct Text Type Art');
is($meta->{S_text_type_ref}, 'Webtext', 'Correct Text Type Ref');
ok(!$meta->{S_text_column}, 'Correct Text Column');
ok(!$meta->{S_text_domain}, 'Correct Text Domain');
is($meta->{D_creation_date}, '20230309', 'Creation Date');

ok(!$meta->{pages}, 'Pages');
ok(!$meta->{A_file_edition_statement}, 'File Ed Statement');
ok(!$meta->{A_bibl_edition_statement}, 'Bibl Ed Statement');
is($meta->{A_reference}, 'Flöhe, In: Klexikon (Online) - URL:https://web.archive.org/web/20230309105908/https://klexikon.zum.de/wiki/Fl%C3%B6he, 2023', 'Reference');
# is($meta->{S_language}, 'de', 'Language');

is($meta->{T_corpus_title}, 'Korpus Einfaches Deutsch', 'Correct Corpus title');
ok(!$meta->{T_corpus_sub_title}, 'Correct Corpus Sub title');
ok(!$meta->{T_corpus_author}, 'Correct Corpus author');
is($meta->{A_corpus_editor},'Daniel Jach, Shanghai Normal University, China', 'Correct Corpus editor');

is($meta->{T_doc_title}, 'Korpus Einfaches Deutsch: Klexikon (Online)', 'Correct Doc title');
ok(!$meta->{T_doc_sub_title}, 'Correct Doc Sub title');
ok(!$meta->{T_doc_author}, 'Correct Doc author');
ok(!$meta->{A_doc_editor}, 'Correct Doc editor');

is($meta->{'A_text_external_link'}, 'data:application/x.korap-link;title=link%20to%20source,https%3A%2F%2Fweb.archive.org%2Fweb%2F20230309105908%2Fhttps%3A%2F%2Fklexikon.zum.de%2Fwiki%2FFl%25C3%25B6he','External link');

is($meta->{'A_corpus_external_link'}, 'data:application/x.korap-link;title=link%20to%20KED%20website,https%3A%2F%2Fdaniel-jach.github.io%2Fsimple-german%2Fsimple-german.html','external link');

is($meta->{'A_KED.topicLabel'}, 'Gesundheit und Krankheit', 'Xenodata');
is($meta->{'A_KED.nToksSentMd'}, '11.0', 'Xenodata');
is($meta->{'A_KED.nToks'}, '308', 'Xenodata');
is($meta->{'A_KED.nPunct1kTks'}, '129.87', 'Xenodata');
is($meta->{'A_KED.strtgyLabel'}, "Erkl\x{e4}ren", 'Xenodata');
is($meta->{'A_KED.rcpntLabel'}, 'Kinder', 'Xenodata');
is($meta->{'A_KED.nSent'}, '28', 'Xenodata');
is($meta->{'A_KED.nTyps'}, '188', 'Xenodata');
is($meta->{'A_KED.txttypLabel'}, 'Lexikonartikel', 'Xenodata');
is($meta->{'S_KED.cover4Herder'}, '0.65', 'Xenodata');
is($meta->{'S_KED.cover2Herder'}, '0.61', 'Xenodata');
is($meta->{'S_KED.cover1Herder'}, '0.58', 'Xenodata');
is($meta->{'S_KED.nPara'}, '5', 'Xenodata');
is($meta->{'S_KED.cover3Herder'}, '0.62', 'Xenodata');
is($meta->{'S_KED.cover5Herder'}, '0.67', 'Xenodata');
is_deeply($meta->{'K_KED.strtgy'}, ['erklaeren','beschreiben'], 'Xenodata');
is_deeply($meta->{'K_KED.topic'}, ['gesundheit_krankheit'], 'Xenodata');
is_deeply($meta->{'K_KED.txttyp'}, ['lexikonartikel'], 'Xenodata');
is_deeply($meta->{'K_KED.rcpnt'}, ['kinder'], 'Xenodata');

is_deeply($meta->{'K_KED.corpusRcpnt'}, ['kinder'], 'Xenodata');
is($meta->{'A_KED.corpusRcpntLabel'}, 'Kinder', 'Xenodata');

is_deeply($meta->{'K_KED.docRcpnt'}, ['kinder'], 'Xenodata');
is($meta->{'A_KED.docRcpntLabel'}, 'Kinder', 'Xenodata');

# Tokenization
use_ok('KorAP::XML::Tokenizer');

my ($token_base_foundry, $token_base_layer) = (qw/tokens morpho/);

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

like($token, qr!i:mitteleuropa!, 'data');

done_testing;
__END__

