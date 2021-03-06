#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use KorAP::XML::Annotation::Connexor::Phrase;
use Test::More;
use lib 't/annotation';
use TestInit;
use Scalar::Util qw/weaken/;
use Data::Dumper;

ok(my $tokens = TestInit::tokens('0001'), 'Parse tokens');

ok($tokens->add('Connexor', 'Phrase'), 'Add Structure');

my $data = $tokens->to_data->{data};

like($data->{foundries}, qr!connexor/phrase!, 'data');
is($data->{stream}->[0]->[1], '<>:base/s:t$<b>64<i>0<i>129<i>18<b>0', 'Text boundary');
is($data->{stream}->[1]->[0], '<>:cnx/c:np$<b>64<i>4<i>30<i>4<b>0', 'Noun phrase');

done_testing;

__END__
