use strict;
use warnings;
use utf8;
use Test::More;
use Mojo::Cache;
use lib 'lib', '../lib';
use Data::Dumper;

use File::Temp qw/tmpnam/;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

my $file = tmpnam();

my $cache = Cache::FastMmap->new(
  share_file => $file,
  cache_size => '10m'
);

my $path = catdir(dirname(__FILE__), qw/corpus REI BNG 00128/);
ok(my $doc = KorAP::XML::Krill->new(
  path => $path,
  meta_type => 'I5',
  cache => $cache
), 'Get doc');

like($doc->path, qr!\Q$path\E/!, 'Path');

ok(!$cache->get('REI'), 'No REI set');
ok(!$cache->get('REI/BNG'), 'No REI/BNG set');
ok($doc->parse);
ok($cache->get('REI'), 'REI set');
ok($cache->get('REI/BNG'), 'REI/BNG set');


# REI
my $rei = $cache->get('REI');
is($rei->{availability}, 'CC-BY-SA');
is($rei->{language}, 'de');
is($rei->{corpus_title}, 'Reden und Interviews');

# REI/BNG
my $rei_bng = $cache->get('REI/BNG');

is($rei_bng->{availability}, 'CC-BY-SA');
is($rei_bng->{language}, 'de');
is($rei_bng->{corpus_title}, 'Reden und Interviews');
is($rei_bng->{doc_title}, 'Reden der Bundestagsfraktion Bündnis 90/DIE GRÜNEN, (2002-2006)');

done_testing;
__END__
