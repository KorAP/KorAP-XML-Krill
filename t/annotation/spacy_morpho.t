#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use KorAP::XML::Annotation::Spacy::Morpho;
use Scalar::Util qw/weaken/;
use Data::Dumper;
use lib 't/annotation';
use TestInit;

ok(my $tokens = TestInit::tokens('0001'), 'Parse tokens');

ok($tokens->add('Spacy', 'Morpho'), 'Add Structure');

my $data = $tokens->to_data->{data};

like($data->{foundries}, qr!spacy/morpho!, 'data');
like($data->{layerInfos}, qr!spacy/p=tokens!, 'data');
like($data->{layerInfos}, qr!spacy/l=tokens!, 'data');

is($data->{stream}->[0]->[5], 'spacy/l:zu', 'POS');
is($data->{stream}->[0]->[6], 'spacy/p:ADP', 'POS');

is($data->{stream}->[3]->[3], 'spacy/l:Anlass', 'POS');
is($data->{stream}->[3]->[4], 'spacy/p:NOUN', 'POS');

is($data->{stream}->[10]->[3], 'spacy/l:ein', 'POS');
is($data->{stream}->[10]->[4], 'spacy/p:ADV', 'POS');

is($data->{stream}->[13]->[3], 'spacy/l:Betrieb', 'POS');

is($data->{stream}->[-1]->[3], 'spacy/l:werden', 'POS');
is($data->{stream}->[-1]->[4], 'spacy/p:AUX', 'POS');

is($data->{stream}->[11]->[3], 'spacy/l:bevor',
   'Lemma');
is($data->{stream}->[11]->[4], 'spacy/p:SCONJ',
   'POS');

is($data->{stream}->[12]->[1], 'i:der','Surface');
is($data->{stream}->[13]->[1], 'i:betrieb','Surface');
is($data->{stream}->[14]->[1], 'i:ende','Surface');
is($data->{stream}->[15]->[1], 'i:schuljahr','Surface');
is($data->{stream}->[16]->[1], 'i:eingestellt','Surface');
is($data->{stream}->[17]->[1], 'i:wird','Surface');

ok(!$data->{stream}->[18],'Nothing');

is(scalar(@{$data->{stream}}), 18, 'Length');

done_testing;

__END__

