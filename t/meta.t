use strict;
use warnings;
use utf8;
use Test::More;
use Benchmark ':hireswallclock';
use Mojo::DOM;
use Mojo::ByteStream 'b';
use Data::Dumper;
use lib 'lib', '../lib';

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use_ok('KorAP::XML::Krill');

# WPD/00001
my $path = catdir(dirname(__FILE__), 'corpus/WPD/00001');
ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
like($doc->path, qr!\Q$path\E/!, 'Path');

ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
like($doc->path, qr!\Q$path\E/$!, 'Path');

ok($doc->parse, 'Parse document');

# Metdata
is($doc->text_sigle, 'WPD/AAA/00001', 'ID');

my $meta = $doc->meta;
is($meta->{title}, 'A', 'title');

ok(!$meta->{sub_title}, 'subTitle');
is($doc->corpus_sigle, 'WPD', 'corpusID');
is($meta->{pub_date}, '20050328', 'pubDate');
is($meta->{pub_place}, 'URL:http://de.wikipedia.org', 'pubPlace');
is($meta->{text_class}->[0], 'freizeit-unterhaltung', 'TextClass');
is($meta->{text_class}->[1], 'reisen', 'TextClass');
is($meta->{text_class}->[2], 'wissenschaft', 'TextClass');
is($meta->{text_class}->[3], 'populaerwissenschaft', 'TextClass');
ok(!$meta->{text_class}->[4], 'TextClass');
is($meta->{author}, 'Ruru; Jens.Ol; Aglarech; u.a.', 'author');


#is($doc->author->[0], 'Ruru', 'author');
#is($doc->author->[1], 'Jens.Ol', 'author');
#is($doc->author->[2], 'Aglarech', 'author');
#ok(!$doc->author->[3], 'author');

# Additional information
ok(!$meta->{editor}, 'Editor');
is($meta->{publisher}, 'Wikipedia', 'Publisher');
is($meta->{creation_date}, '20050000', 'Creation date');
ok(!$meta->{text_type}, 'No text_type');
ok(!$meta->{text_type_art}, 'no text_type art');
ok(!$meta->{text_type_ref}, 'no text_type ref');
ok(!$meta->{text_domain}, 'no text_domain');
ok(!$meta->{text_column}, 'no text_column');
ok(!$meta->keywords('keywords'), 'no keywords');
is($meta->keywords('text_class'), 'freizeit-unterhaltung reisen wissenschaft populaerwissenschaft', 'no text classes');

#is($doc->coll_title, 'Wikipedia', 'Collection title');
#is($doc->coll_sub_title, 'Die freie Enzyklopädie', 'Collection subtitle');
#is($doc->coll_editor, 'wikipedia.org', 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');

# A01/13047
$path = catdir(dirname(__FILE__), 'corpus/A01/13047');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');

ok($doc->parse, 'Parse document');
$meta = $doc->meta;
is($meta->{title}, 'Fischer und Kolp im Sonnenhügel', 'title');

ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'A01/APR/13047', 'ID');
is($doc->corpus_sigle, 'A01', 'corpusID');
is($meta->{pub_date}, '20010402', 'pubDate');
ok(!$meta->{pub_place}, 'pubPlace');
is($meta->{text_class}->[0], 'freizeit-unterhaltung', 'TextClass');
is($meta->{text_class}->[1], 'vereine-veranstaltungen', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');

# Additional information
ok(!$meta->{editor}, 'Editor');
ok(!$meta->{publisher}, 'Publisher');
is($meta->{creation_date}, '20010402', 'Creation date');
#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
ok(!$meta->{text_type}, 'text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');

# ERL/0001
$path = catdir(dirname(__FILE__), 'corpus/ERL/00001');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');

ok($doc->parse, 'Parse document');

$meta = $doc->meta;
is($meta->{title}, 'Amtsblatt des Landesbezirks Baden [diverse Erlasse]', 'title'); # Amtsblatt des Landesbezirks Baden [diverse Erlasse]
# MK2/ERL.00001

ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'MK2/ERL/00001', 'ID');
is($doc->corpus_sigle, 'MK2', 'corpusID');
is($meta->{pub_date}, '00000000', 'pubDate');
is($meta->{pub_place}, 'Karlsruhe', 'pubPlace');
is($meta->{text_class}->[0], 'politik', 'TextClass');
is($meta->{text_class}->[1], 'kommunalpolitik', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');

# Additional information
ok(!$meta->{editor}, 'Editor');
is($meta->{publisher}, 'Badenia Verlag und Druckerei', 'Publisher');
is($meta->{creation_date}, '19600000', 'Creation date');

# !!!
# diag 'Non-acceptance of creation date ranges may be temporary';


#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
is($meta->{text_type}, 'Erlass', 'text_type');
ok(!$meta->{text_type_art}, 'text_type art');


# A01/02035-substring
$path = catdir(dirname(__FILE__), 'corpus/A00/02035-substring');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');

$meta = $doc->meta;

is($meta->{title}, 'St. Galler Tagblatt, 11.01.2000, Ressort: TB-RSP (Abk.)', 'title'); # A00/JAN.02035
ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'A00/JAN/02035', 'ID');
is($doc->corpus_sigle, 'A00', 'corpusID');
is($meta->{pub_date}, '20000111', 'pubDate');
ok(!$meta->{pub_place}, 'pubPlace');
is($meta->{text_class}->[0], 'sport', 'TextClass');
is($meta->{text_class}->[1], 'ballsport', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');

# Additional information
ok(!$meta->{editor}, 'Editor');
ok(!$meta->{publisher}, 'Publisher');
is($meta->{creation_date}, "20000111", 'Creation date');
#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
ok(!$meta->{text_type}, 'text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');

# A01/02873-meta
$path = catdir(dirname(__FILE__), 'corpus/A00/02873-meta');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');
$meta = $doc->meta;

is($meta->{title}, 'Tradition und Moderne', 'title');
ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'A00/JAN/02873', 'ID');
is($doc->corpus_sigle, 'A00', 'corpusID');
is($meta->{pub_date}, '20000113', 'pubDate');
ok(!$meta->{pub_place}, 'pubPlace');
is($meta->{text_class}->[0], 'kultur', 'TextClass');
is($meta->{text_class}->[1], 'film', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');


# Additional information
ok(!$meta->{editor}, 'Editor');
ok(!$meta->{publisher}, 'Publisher');
is($meta->{creation_date}, "20000113", 'Creation date');
#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
ok(!$meta->{text_type}, 'text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');


# A01/05663-unbalanced
$path = catdir(dirname(__FILE__), 'corpus/A00/05663-unbalanced');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');
$meta = $doc->meta;

is($meta->{title}, 'Mehr Arbeitslose im Dezember', 'title');
ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'A00/JAN/05663', 'ID');
is($doc->corpus_sigle, 'A00', 'corpusID');
is($meta->{pub_date}, '20000124', 'pubDate');
ok(!$meta->{pub_place}, 'pubPlace');
is($meta->{text_class}->[0], 'gesundheit-ernaehrung', 'TextClass');
is($meta->{text_class}->[1], 'gesundheit', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');


# Additional information
ok(!$meta->{editor}, 'Editor');
ok(!$meta->{publisher}, 'Publisher');
is($meta->{creation_date}, "20000124", 'Creation date');
#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
ok(!$meta->{text_type}, 'text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');

# A01/07452-deep
$path = catdir(dirname(__FILE__), 'corpus/A00/07452-deep');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');
$meta = $doc->meta;

is($meta->{title}, 'Wil im Dezember 1999', 'title');
ok(!$meta->{sub_title}, 'subTitle');
is($doc->text_sigle, 'A00/JAN/07452', 'ID');
is($doc->corpus_sigle, 'A00', 'corpusID');
is($meta->{pub_date}, '20000129', 'pubDate');
ok(!$meta->{pub_place}, 'pubPlace');
is($meta->{text_class}->[0], 'politik', 'TextClass');
is($meta->{text_class}->[1], 'kommunalpolitik', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
ok(!$meta->{author}, 'author');


# Additional information
ok(!$meta->{editor}, 'Editor');
ok(!$meta->{publisher}, 'Publisher');
is($meta->{creation_date}, "20000129", 'Creation date');
#ok(!$doc->coll_title, 'Collection title');
#ok(!$doc->coll_sub_title, 'Collection subtitle');
#ok(!$doc->coll_editor, 'Collection editor');
#ok(!$doc->coll_author, 'Collection author');
ok(!$meta->{text_type}, 'text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');

# ART
$path = catdir(dirname(__FILE__), 'corpus/artificial');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
#is($doc->path, $path . '/', 'Path');

ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
#is($doc->path, $path . '/', 'Path');

ok($doc->parse, 'Parse document');
$meta = $doc->meta;

# Metdata
is($meta->{title}, 'Artificial Title', 'title');
is($meta->{sub_title}, 'Artificial Subtitle', 'subTitle');
is($doc->text_sigle, 'ART/ABC/00001', 'ID');
is($doc->corpus_sigle, 'ART', 'corpusID');
is($meta->{pub_date}, '20010402', 'pubDate');
is($meta->{pub_place}, 'Mannheim', 'pubPlace');
is($meta->{pub_place_key}, 'DE', 'pubPlace key');
is($meta->{text_class}->[0], 'freizeit-unterhaltung', 'TextClass');
is($meta->{text_class}->[1], 'vereine-veranstaltungen', 'TextClass');
ok(!$meta->{text_class}->[2], 'TextClass');
#is($doc->author->[0], 'Ruru', 'author');
#is($doc->author->[1], 'Jens.Ol', 'author');
#is($doc->author->[2], 'Aglarech', 'author');
is($meta->{author}, 'Ruru; Jens.Ol; Aglarech; u.a.', 'author');

# Additional information
is($meta->{editor}, 'Nils Diewald', 'Editor');
is($meta->{publisher}, 'Artificial articles Inc.', 'Publisher');
is($meta->{creation_date}, '19990601', 'Creation date');
#is($doc->coll_title, 'Artificial articles', 'Collection title');
#is($doc->coll_sub_title, 'Best of!', 'Collection subtitle');
#is($doc->coll_editor, 'Nils Diewald', 'Collection editor');
#is($doc->coll_author, 'Nils Diewald', 'Collection author');
is($meta->{text_type}, 'Zeitung: Tageszeitung', 'No text_type');
is($meta->{text_type_art}, 'Bericht', 'text_type art');


# Multipath headers
$path = catdir(dirname(__FILE__), 'corpus/VDI/JAN/00001');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
like($doc->path, qr!\Q$path\E/!, 'Path');

ok($doc = KorAP::XML::Krill->new( path => $path ), 'Load Korap::Document');
like($doc->path, qr!\Q$path\E/$!, 'Path');

ok($doc->parse, 'Parse document');
$meta = $doc->meta;

is($doc->text_sigle, 'VDI14/JAN/00001', 'text sigle');
is($doc->doc_sigle, 'VDI14/JAN', 'doc sigle');
is($meta->corpus_sigle, 'VDI14', 'corpus sigle');

is($meta->{title}, '10- Zz mit Zahl', 'title');

ok(!$meta->{sub_title}, 'subtitle');
is($meta->{pub_date}, '20140117', 'pubdate');
is($meta->{pub_place}, 'Düsseldorf', 'pubplace');
is($meta->{author}, 'Windhövel, Kerstin', 'author');
is($meta->{publisher}, 'VDI Verlag GmbH', 'publisher');
ok(!$meta->{editor}, 'editor');

ok(!$meta->{text_type}, 'text type');
ok(!$meta->{text_type_art}, 'text type art');
ok(!$meta->{text_type_ref}, 'text type ref');
ok(!$meta->{text_column}, 'text column');
ok(!$meta->{text_domain}, 'text domain');
ok(!$meta->{creation_date}, 'creation date');
ok(!$meta->{availability}, 'License');
ok(!$meta->{pages}, 'Pages');
ok(!$meta->{file_edition_statement}, 'file edition statement');
ok(!$meta->{bibl_edition_statement}, 'bibl edition statement');
is($meta->{reference}, 'VDI nachrichten, 17.01.2014, S. 10; 10- Zz mit Zahl [Ausführliche Zitierung nicht verfügbar]', 'Reference');

ok(!$doc->{language}, 'Language');
# !!!
# diag 'This may be "de" in the future';

is($meta->{doc_title}, 'VDI nachrichten, Januar 2014', 'Doc title');
ok(!$meta->{doc_sub_title}, 'Doc Sub title');
ok(!$meta->{doc_editor}, 'Doc editor');
ok(!$meta->{doc_author}, 'Doc author');

is($meta->{corpus_title}, 'VDI nachrichten', 'Corpus title');
ok(!$meta->{corpus_sub_title}, 'Corpus Sub title');
is($meta->{corpus_editor}, 'Verein Deutscher Ingenieure', 'Corpus editor');
ok(!$meta->{corpus_author}, 'Corpus author');

is($meta->keywords('keywords'), '', 'Keywords');
is($meta->keywords('text_class'), 'Freizeit-Unterhaltung Reisen Politik Ausland', 'Text class');

# WDD
$path = catdir(dirname(__FILE__), 'corpus/WDD/G27/38989');
ok($doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
like($doc->path, qr!\Q$path\E/!, 'Path');
ok($doc->parse, 'Parse document');
$meta = $doc->meta;

is($doc->text_sigle, 'WDD11/G27/38989', 'text sigle');
is($doc->doc_sigle, 'WDD11/G27', 'doc sigle');
is($doc->corpus_sigle, 'WDD11', 'corpus sigle');

is($meta->{title}, 'Diskussion:Gunter A. Pilz', 'title');
ok(!$meta->{sub_title}, 'subtitle');
is($meta->{pub_date}, '20111029', 'pubdate');
is($meta->{pub_place}, 'URL:http://de.wikipedia.org', 'pubplace');

is($meta->{author}, '€pa, u.a.', 'author');
is($meta->{publisher}, 'Wikipedia', 'publisher');
ok(!$meta->{editor}, 'editor');

is($meta->{text_type}, 'Diskussionen zu Enzyklopädie-Artikeln', 'text type');
ok(!$meta->{text_type_art}, 'text type art');
ok(!$meta->{text_type_ref}, 'text type ref');
ok(!$meta->{text_column}, 'text column');
ok(!$meta->{text_domain}, 'text domain');

is($meta->{creation_date}, '20070707', 'creation date');
is($meta->{availability}, 'CC-BY-SA', 'License');
ok(!$meta->{pages}, 'Pages');
ok(!$meta->{file_edition_statement}, 'file edition statement');
ok(!$meta->{bibl_edition_statement}, 'bibl edition statement');
is($meta->{reference}, 'Diskussion:Gunter A. Pilz, In: Wikipedia - URL:http://de.wikipedia.org/wiki/Diskussion:Gunter_A._Pilz: Wikipedia, 2007', 'Reference');

is($meta->{language}, 'de', 'Language');

is($meta->{doc_title}, 'Wikipedia, Diskussionen zu Artikeln mit Anfangsbuchstabe G, Teil 27', 'Doc title');
ok(!$meta->{doc_sub_title}, 'Doc Sub title');
ok(!$meta->{doc_editor}, 'Doc editor');
ok(!$meta->{doc_author}, 'Doc author');

is($meta->{corpus_title}, 'Wikipedia', 'Corpus title');
ok(!$meta->{corpus_sub_title}, 'Corpus Sub title');
is($meta->{corpus_editor}, 'wikipedia.org', 'Corpus editor');
ok(!$meta->{corpus_author}, 'Corpus author');

is($meta->keywords('keywords'), '', 'Keywords');
is($meta->keywords('text_class'), '', 'Text class');

is($meta->{availability}, 'CC-BY-SA', 'Availability');

use_ok('KorAP::XML::Meta::I5');

$path = catdir(dirname(__FILE__), 'corpus', 'I5', 'rei-example.i5');
ok($meta = KorAP::XML::Meta::I5->new, 'Construct meta object');
my $dom = Mojo::DOM->new->parse(b($path)->slurp);
ok($meta->parse($dom->at('idsHeader'), 'corpus'), 'Parse corpus header');

my $hash = $meta->to_hash;
is($hash->{availability}, 'CC-BY-SA', 'Availability');
is($hash->{language}, 'de', 'Language');
is($hash->{corpus_title}, 'Reden und Interviews', 'Corpus title');
is($hash->{corpus_sigle}, 'REI', 'Corpus Sigle');

ok($meta->parse($dom->find('idsHeader')->[1], 'doc'), 'Parse corpus header');

$hash = $meta->to_hash;
is($hash->{availability}, 'CC-BY-SA', 'Availability');
is($hash->{language}, 'de', 'Language');
is($hash->{corpus_title}, 'Reden und Interviews', 'Corpus title');
is($hash->{corpus_sigle}, 'REI', 'Corpus Sigle');
is($hash->{doc_sigle}, 'REI/BNG', 'Document Sigle');
is($hash->{doc_title}, 'Reden der Bundestagsfraktion Bündnis 90/DIE GRÜNEN, (2002-2006)', 'Document Sigle');

ok($meta->parse($dom->find('idsHeader')->[2], 'text'), 'Parse corpus header');

$hash = $meta->to_hash;
is($hash->{availability}, 'CC-BY-SA', 'Availability');
is($hash->{language}, 'de', 'Language');
is($hash->{corpus_title}, 'Reden und Interviews', 'Corpus title');
is($hash->{corpus_sigle}, 'REI', 'Corpus Sigle');
is($hash->{doc_sigle}, 'REI/BNG', 'Document Sigle');
is($hash->{doc_title}, 'Reden der Bundestagsfraktion Bündnis 90/DIE GRÜNEN, (2002-2006)', 'Document Sigle');

is($hash->{text_sigle}, 'REI/BNG/00001');
is($hash->{title}, 'Energiewirtschaft');
is($hash->{sub_title}, 'Rede im Deutschen Bundestag am 19.01.2002');
is($hash->{creation_date}, '20020119');
is($hash->{pub_date}, '20020119');
is($hash->{pub_place_key}, 'DE');
is($hash->{reference}, 'Hustedt, Michaele: Energiewirtschaft. Rede im Deutschen Bundestag am 19.01.2002, Hrsg: Bundestagsfraktion Bündnis 90/DIE GRÜNEN [Ausführliche Zitierung nicht verfügbar]');
is($hash->{text_class}->[0], 'politik');
is($hash->{text_class}->[1], 'inland');
is($hash->{author}, 'Hustedt, Michaele');
is($hash->{pub_place}, 'Berlin');

done_testing;
__END__



