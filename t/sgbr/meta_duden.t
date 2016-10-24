use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Data::Dumper;
use KorAP::XML::Tokenizer;
use KorAP::XML::Krill;
use utf8;

my $path = catdir(dirname(__FILE__), 'PRO-DUD', 'BSP-2013-01', 32);

ok(my $doc = KorAP::XML::Krill->new(
  path => $path . '/',
  meta_type => 'Sgbr'
), 'Create Document');

ok($doc->parse, 'Parse document');

like($doc->path, qr!\Q$path\E/!, 'Path');

# Metdata
is($doc->text_sigle, 'PRO-DUD/BSP-2013-01/32', 'ID-text');
is($doc->doc_sigle, 'PRO-DUD/BSP-2013-01', 'ID-doc');
is($doc->corpus_sigle, 'PRO-DUD', 'ID-corpus');

my $meta = $doc->meta;
is($meta->{title}, 'Nur Platt, kein Deutsch', 'title');
ok(!$meta->{sub_title}, 'no subtitle');

is($meta->{publisher}, 'Dorfblatt GmbH', 'Publisher');
is($meta->{pub_date}, '20130126');
is($meta->{sgbr_date}, '2013-01-26');
is($meta->{pub_place}, 'Stadtingen');

is($meta->{doc_title}, 'Korpus zur Beobachtung des Schreibgebrauchs im Deutschen', 'Doc title');
is($meta->{doc_sub_title}, 'Subkorpus Ortsblatt, Jahrgang 2013, Monat Januar', 'Doc Sub title');

is($meta->{'funder'}, 'Bundesministerium für Bildung und Forschung', 'Funder');

is($meta->{author}, 'unbekannt', 'Author');
ok(!$meta->{'sgbr_author_sex'}, 'No Sex');
is($meta->{'sgbr_kodex'}, 'T', '');

is($meta->keywords('keywords'), 'sgbrKodex:T');

is($meta->{language}, 'de', 'Language');

ok(!$meta->{editor}, 'Editor');

ok(!$meta->{text_type}, 'Text Type');
ok(!$meta->{text_type_art}, 'Text Type Art');
ok(!$meta->{text_type_ref}, 'Text Type Ref');
ok(!$meta->{text_column}, 'Text Column');
ok(!$meta->{text_domain}, 'Text Domain');
ok(!$meta->{creation_date}, 'Creation Date');
ok(!$meta->{license}, 'License');
ok(!$meta->{pages}, 'Pages');
ok(!$meta->{file_edition_statement}, 'File Edition Statement');
ok(!$meta->{bibl_edition_statement}, 'Bibl Edition Statement');
ok(!$meta->{reference}, 'Reference');


ok(!$meta->{doc_editor}, 'Doc: editor');
ok(!$meta->{doc_author}, 'Doc: author');

ok(!$meta->{corpus_title}, 'Corpus: title');
ok(!$meta->{corpus_sub_title}, 'Corpus: subtitle');
ok(!$meta->{corpus_editor}, 'Corpus: editor');
ok(!$meta->{corpus_author}, 'Corpus: author');

my $hash = $doc->to_hash;
is($hash->{title}, 'Nur Platt, kein Deutsch', 'Corpus title');
is($hash->{sgbrKodex}, 'T', 'store');


done_testing;


__END__
