use strict;
use warnings;
use utf8;
use Test::More;
use Benchmark ':hireswallclock';
use Mojo::DOM;
use Mojo::File;
use Mojo::ByteStream 'b';
use Data::Dumper;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use lib 'lib', '../lib';

use_ok('KorAP::XML::Krill');

# ART
my $path = catdir(dirname(__FILE__), 'corpus','artificial');
ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
#is($doc->path, $path . '/', 'Path');

ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
#is($doc->path, $path . '/', 'Path');

ok($doc->parse, 'Parse document');

my $meta = $doc->meta;

# Metdata
is($meta->{T_title}, 'Artificial Title', 'title');
is($meta->{T_sub_title}, 'Artificial Subtitle', 'subTitle');
is($doc->text_sigle, 'A_RT/ABC/00001', 'ID');
is($doc->corpus_sigle, 'A_RT', 'corpusID');
is($meta->{D_pub_date}, '20010402', 'pubDate');
is($meta->{S_pub_place}, 'Mannheim', 'pubPlace');
is($meta->{S_pub_place_key}, 'DE', 'pubPlace key');
is($meta->{K_text_class}->[0], 'freizeit-unterhaltung', 'TextClass');
is($meta->{K_text_class}->[1], 'vereine-veranstaltungen', 'TextClass');
ok(!$meta->{K_text_class}->[2], 'TextClass');
#is($doc->author->[0], 'Ruru', 'author');
#is($doc->author->[1], 'Jens.Ol', 'author');
#is($doc->author->[2], 'Aglarech', 'author');
is($meta->{T_author}, 'Ruru; Jens.Ol; Aglarech; u.a.', 'author');

# Additional information
is($meta->{A_editor}, 'Nils Diewald', 'Editor');
is($meta->{A_publisher}, 'Artificial articles Inc.', 'Publisher');
is($meta->{D_creation_date}, '19990601', 'Creation date');
#is($doc->coll_title, 'Artificial articles', 'Collection title');
#is($doc->coll_sub_title, 'Best of!', 'Collection subtitle');
#is($doc->coll_editor, 'Nils Diewald', 'Collection editor');
#is($doc->coll_author, 'Nils Diewald', 'Collection author');
is($meta->{S_text_type}, 'Zeitung: Tageszeitung', 'No text_type');
is($meta->{S_text_type_art}, 'Bericht', 'text_type art');

use_ok('KorAP::XML::Meta::I5');

$meta = new KorAP::XML::Meta::I5();

is('data:application/x.korap-link;example=%20Das%20war%20einfach;title=Hallo%21,https%3A%2F%2Fwww.test.de',
   $meta->korap_data_uri('https://www.test.de', title => 'Hallo!', example => ' Das war einfach'));

our %ENV;
$ENV{K2K_PUBLISHER_STRING} = 1;

# ART
$path = catdir(dirname(__FILE__), 'corpus','artificial');
ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');
$meta = $doc->meta;
ok(!$meta->{A_publisher}, 'Publisher');
is($meta->{S_publisher}, 'Artificial articles Inc.', 'Publisher');

$ENV{K2K_PUBLISHER_STRING} = 0;


done_testing;
__END__

