#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw/weaken/;
use Data::Dumper;
use lib 't/annotation';
use KorAP::XML::Krill;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';


my $path = catdir(dirname(__FILE__), 'corpus', 'doc', '0001');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::XML::Krill');
ok($doc->parse, 'Parse document');
like($doc->path, qr!\Q$path\E/!, 'Path');

is($doc->primary->data,
   'Zum letzten kulturellen Anlass lädt die Leitung des Schulheimes Hofbergli ein, '.
     'bevor der Betrieb Ende Schuljahr eingestellt wird.', 'Primary data');

is($doc->primary->data_length, 129, 'Primary data length');

is($doc->primary->data(0,3), 'Zum', 'Get primary data');


done_testing;

__END__
