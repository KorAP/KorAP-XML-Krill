#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use File::Temp qw/ :POSIX /;
use Mojo::Util qw/slurp/;
use Mojo::JSON qw/decode_json/;
use IO::Uncompress::Gunzip;
use Data::Dumper;

use_ok('KorAP::XML::Batch::File');

ok(my $bf = KorAP::XML::Batch::File->new(
  overwrite => 1,
  foundry => 'OpenNLP',
  layer => 'Tokens'
), 'Construct new batch file object');

my $path = catdir(dirname(__FILE__), 'annotation', 'corpus', 'doc', '0001');

my $output = tmpnam();
ok($bf->process($path => $output), 'Process file');

ok(-f $output, 'File exists');

ok(my $file = slurp $output, 'Slurp data');

ok(my $json = decode_json $file, 'decode json');

is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');
is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'Title');
is($json->{data}->{foundries}, '', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:tokens$<i>18', 'Tokens');
is($json->{data}->{stream}->[0]->[1], '<>:base/s:t$<b>64<i>0<i>129<i>17<b>0', 'Data');

# Generate with Gzip
$bf->{gzip} = 1;

$path = catdir(dirname(__FILE__), 'annotation', 'corpus', 'doc', '0001');
$output = tmpnam();
ok($bf->process($path => $output), 'Process file');

my $out;
my $gz = IO::Uncompress::Gunzip->new($output);
ok($gz->read($out), 'Uncompress');

ok($json = decode_json $out, 'decode json');

is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');
is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'Title');
is($json->{data}->{foundries}, '', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:tokens$<i>18', 'Tokens');
is($json->{data}->{stream}->[0]->[1], '<>:base/s:t$<b>64<i>0<i>129<i>17<b>0', 'Data');

# Generate with annotations
$bf->{gzip} = 0;
$bf->{anno} = [
  ['CoreNLP', 'Morpho'],
  ['OpenNLP', 'Morpho']
];
$output = tmpnam();
ok($bf->process($path => $output), 'Process file');
ok($file = slurp $output, 'Slurp data');
ok($json = decode_json $file, 'decode json');

is($json->{textType}, 'Zeitung: Tageszeitung', 'text type');
is($json->{title}, 'Beispiel Text', 'Title');
is($json->{data}->{tokenSource}, 'opennlp#tokens', 'Title');
is($json->{data}->{foundries}, 'corenlp corenlp/morpho opennlp opennlp/morpho', 'Foundries');
like($json->{data}->{text}, qr/^Zum letzten kulturellen/, 'Foundries');
is($json->{data}->{stream}->[0]->[0], '-:tokens$<i>18', 'Tokens');

my $token = $json->{data}->{stream}->[0];

like($json->{data}->{text}, qr/Ende Schuljahr eingestellt wird\.$/, 'Primary text');

is($token->[1], '<>:base/s:t$<b>64<i>0<i>129<i>17<b>0', 'base/s');
is($token->[2], '_0$<i>0<i>3', 'position');
is($token->[3], 'corenlp/p:APPRART', 'corenlp');
is($token->[5], 'opennlp/p:APPRART', 'opennlp');

$token = $json->{data}->{stream}->[-1];

is($token->[1], 'corenlp/p:VAFIN', 'corenlp');
is($token->[3], 'opennlp/p:VAFIN', 'opennlp');

# Check layer and foundry for base tokenization
# No primary data
$bf->{anno} = [[]];
$bf->{primary} = 0;
$bf->{foundry} = 'CoreNLP';
$bf->{layer} = 'Tokens';

ok($bf->process($path => $output), 'Process file');
ok(-f $output, 'File exists');
ok($file = slurp $output, 'Slurp data');
ok($json = decode_json $file, 'decode json');

ok(!$json->{data}->{text}, 'No Primary text');
is($json->{data}->{tokenSource}, 'corenlp#tokens', 'Title');

like($file, qr/^\{"/, 'No pretty printing');

# Check pretty printing
$bf->{pretty} = 1;
ok($bf->process($path => $output), 'Process file');
ok(-f $output, 'File exists');
ok($file = slurp $output, 'Slurp data');
like($file, qr/^\{[\n\s]+"/, 'No pretty printing');

# Check overwriting
$bf->{overwrite} = 0;

ok(!$bf->process($path => $output), 'Process file');

done_testing;
__END__




