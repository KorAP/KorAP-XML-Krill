#!/usr/bin/env perl
# source ~/perl5/perlbrew/etc/bashrc
# perlbrew switch perl-blead@korap
use strict;
use warnings;
use utf8;
use Test::More;
use JSON::XS;
use Benchmark ':hireswallclock';
use lib 'lib', '../lib';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

sub _t2h {
  my $string = shift;
  $string =~ s/^\[\(\d+?-\d+?\)(.+?)\]$/$1/;
  my %hash = ();
  foreach (split(qr!\|!, $string)) {
    $hash{$_} = 1;
  };
  return \%hash;
};

my @layers;
# push(@layers, ['Base', 'Sentences']);
push(@layers, ['Base', 'Paragraphs']);

# OpenNLP
push(@layers, ['OpenNLP', 'Morpho']);
push(@layers, ['OpenNLP', 'Sentences']);

# CoreNLP
push(@layers, ['CoreNLP', 'NamedEntities', 'ne_dewac_175m_600']);
push(@layers, ['CoreNLP', 'NamedEntities', 'ne_hgc_175m_600']);
push(@layers, ['CoreNLP', 'Sentences']);

# Connexor
push(@layers, ['Connexor', 'Morpho']);
push(@layers, ['Connexor', 'Syntax']);
push(@layers, ['Connexor', 'Phrase']);
push(@layers, ['Connexor', 'Sentences']);

# TreeTagger
push(@layers, ['TreeTagger', 'Morpho']);
push(@layers, ['TreeTagger', 'Sentences']);

# Mate
# push(@layers, ['Mate', 'Morpho']);
# push(@layers, ['Mate', 'Dependency']);
diag 'Check for mate/d';

# XIP
push(@layers, ['XIP', 'Morpho']);
push(@layers, ['XIP', 'Constituency']);
push(@layers, ['XIP', 'Dependency']);
push(@layers, ['XIP', 'Sentences']);


my $path = catdir(dirname(__FILE__), 'corpus/WPD/00001');
ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
like($doc->path, qr!$path/$!, 'Path');

ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
like($doc->path, qr!$path/$!, 'Path');

ok($doc->parse, 'Parse document');

# Metdata
is($doc->title, 'A', 'title');
ok(!$doc->sub_title, 'subTitle');

is($doc->text_sigle, 'WPD_AAA.00001', 'ID');
is($doc->corpus_sigle, 'WPD', 'corpusID');
is($doc->pub_date, '20050328', 'pubDate');
is($doc->pub_place, 'URL:http://de.wikipedia.org', 'pubPlace');
is($doc->text_class->[0], 'freizeit-unterhaltung', 'TextClass');
is($doc->text_class->[1], 'reisen', 'TextClass');
is($doc->text_class->[2], 'wissenschaft', 'TextClass');
is($doc->text_class->[3], 'populaerwissenschaft', 'TextClass');
ok(!$doc->text_class->[4], 'TextClass');
is($doc->author, 'Ruru; Jens.Ol; Aglarech; u.a.', 'author');

# Get tokens
use_ok('KorAP::XML::Tokenizer');
# Get tokenization
ok(my $tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => 'OpenNLP',
  layer => 'Tokens',
  name => 'tokens'
), 'New Tokenizer');
ok($tokens->parse, 'Parse');

like($tokens->path, qr!$path/$!, 'Path');
is($tokens->foundry, 'OpenNLP', 'Foundry');
is($tokens->doc->text_sigle, 'WPD_AAA.00001', 'Doc id');
is($tokens->should, 1068, 'Should');
is($tokens->have, 923, 'Have');
is($tokens->name, 'tokens', 'Name');
is($tokens->layer, 'Tokens', 'Layer');


is_deeply(_t2h($tokens->stream->pos(118)->to_string),
   _t2h('[(763-768)s:Linie|i:linie|_118$<i>763<i>768]'),
   'Token is correct');

# Add Mate
ok($tokens->add('Mate', 'Morpho'), 'Add Mate');


is_deeply(
  _t2h($tokens->stream->pos(118)->to_string),
  _t2h('[(763-768)s:Linie|i:linie|_118$<i>763<i>768|mate/l:linie|mate/p:NN|mate/m:case:acc|mate/m:number:sg|mate/m:gender:fem]'),
  'with Mate');

# Add sentences
ok($tokens->add('Base', 'Sentences'), 'Add Sentences');

is_deeply(
  _t2h($tokens->stream->pos(0)->to_string),
  _t2h('[(0-1)s:A|i:a|_0$<i>0<i>1|-:tokens$<i>923|mate/p:XY|<>:base/s:s$<b>64<i>0<i>74<i>13<b>2|<>:base/s:t$<b>64<i>0<i>6083<i>923<b>0|-:base/sentences$<i>96]'),
  'Startinfo'
);

foreach (@layers) {
  ok($tokens->add(@$_), 'Add '. join(', ', @$_));
};

my $s =
  '[(0-1)s:A|i:a|_0$<i>0<i>1|'.
  '-:tokens$<i>923|'.
  'mate/p:XY|'.
  '<>:base/s:s$<b>64<i>0<i>74<i>13<b>2|'.
  '<>:base/s:t$<b>64<i>0<i>6083<i>923<b>0|'.
  '-:base/sentences$<i>96|'.
  '<>:base/s:p$<b>64<i>0<i>224<i>34<b>1|'.
  '-:base/paragraphs$<i>76|'.
  'opennlp/p:NE|' .
  '<>:opennlp/s:s$<b>64<i>0<i>74<i>13<b>0|'.
  '-:opennlp/sentences$<i>50|'.
  '<>:corenlp/s:s$<b>64<i>0<i>6<i>2<b>0|'.
  '-:corenlp/sentences$<i>68|'.
  'cnx/l:A|'.
  'cnx/p:N|'.
  'cnx/syn:@NH|'.
  '<>:cnx/c:np$<b>64<i>0<i>1<i>1<b>0|'.
  '<>:cnx/s:s$<b>64<i>0<i>74<i>13<b>0|'.
  '-:cnx/sentences$<i>63|'.
  'tt/l:A$<b>129<b>199|'.
  'tt/p:NN$<b>129<b>199|'.
  'tt/l:A$<b>129<b>54|'.
  'tt/p:FM$<b>129<b>54|'.
  '<>:tt/s:s$<b>64<i>0<i>6083<i>923<b>0|'.
  '-:tt/sentences$<i>1|'.
#  '>:mate/d:PNC$<i>2|'.
  'xip/p:SYMBOL|'.
  'xip/l:A|'.
  '<>:xip/c:TOP$<b>64<i>0<i>74<i>13<b>0|'.
  '<>:xip/c:MC$<b>64<i>0<i>73<i>13<b>1|'.
  '<>:xip/c:NP$<b>64<i>0<i>1<i>1<b>2|'.
  '<>:xip/c:NPA$<b>64<i>0<i>1<i>1<b>3|'.
  '<>:xip/c:NOUN$<b>64<i>0<i>1<i>1<b>4|'.
  '<>:xip/c:SYMBOL$<b>64<i>0<i>1<i>1<b>5|'.
  '>:xip/d:SUBJ$<i>3|'.
  '<:xip/d:COORD$<i>1|'.
  '<>:xip/s:s$<b>64<i>0<i>74<i>13<b>0|'.
  '-:xip/sentences$<i>65]';

{
  local $SIG{__WARN__} = sub {};
  is_deeply(
    _t2h($tokens->stream->pos(0)->to_string),
    _t2h($s),
    'Startinfo');
};

is($tokens->layer_info,
   'base/s=spans cnx/c=spans cnx/l=tokens cnx/m=tokens cnx/p=tokens cnx/s=spans cnx/syn=tokens corenlp/ne=tokens corenlp/s=spans mate/l=tokens mate/m=tokens mate/p=tokens opennlp/p=tokens opennlp/s=spans tt/l=tokens tt/p=tokens tt/s=spans xip/c=spans xip/d=rels xip/l=tokens xip/p=tokens xip/s=spans', 'Layer info'); # mate/d=rels

is($tokens->support, 'base base/paragraphs base/sentences connexor connexor/morpho connexor/phrase connexor/sentences connexor/syntax corenlp corenlp/namedentities corenlp/namedentities corenlp/namedentities/ne_dewac_175m_600 corenlp/namedentities/ne_hgc_175m_600 corenlp/sentences mate mate/morpho opennlp opennlp/morpho opennlp/sentences treetagger treetagger/morpho treetagger/sentences xip xip/constituency xip/dependency xip/morpho xip/sentences', 'Support'); # mate/dependency

done_testing;
__END__
