#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw/weaken/;
use Data::Dumper;

use_ok('KorAP::XML::Krill');

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

my $path = catdir(dirname(__FILE__), 'corpus', 'doc', '0001');

ok(my $doc = KorAP::XML::Krill->new(
  path => $path . '/'
), 'Load Korap::Document');

like($doc->path, qr!\Q$path\E/$!, 'Path');
ok($doc->parse, 'Parse document');

ok($doc->primary->data, 'Primary data in existence');
is($doc->primary->data_length, 129, 'Data length');

use_ok('KorAP::XML::Tokenizer');

ok(my $tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => 'OpenNLP',
  layer => 'Tokens',
  name => 'tokens'
), 'New Tokenizer');

ok($tokens->parse, 'Parse');

ok($tokens->add('Connexor', 'Sentences'), 'Add Structure');

my $data = $tokens->to_data->{data};

like($data->{foundries}, qr!connexor/sentences!, 'data');
is($data->{stream}->[0]->[0], '-:cnx/sentences$<i>1', 'Number of paragraphs');
is($data->{stream}->[0]->[1], '-:tokens$<i>18', 'Number of tokens');
is($data->{stream}->[0]->[2], '<>:base/s:t$<b>64<i>0<i>129<i>17<b>0', 'Text boundary');
is($data->{stream}->[0]->[3], '<>:cnx/s:s$<b>64<i>0<i>129<i>17<b>0', 'Sentence');
is($data->{stream}->[0]->[4], '_0$<i>0<i>3', 'Position');

done_testing;

__END__
