use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Data::Dumper;
use KorAP::XML::Tokenizer;
use KorAP::XML::Krill;
use utf8;

my $path = catdir(dirname(__FILE__), 'CMC-TSK', '2014-09', '2843');

ok(my $doc = KorAP::XML::Krill->new(
  path => $path . '/',
  meta_type => 'Sgbr'
), 'Create Document');

ok($doc->parse, 'Parse document');

like($doc->path, qr!\Q$path\E/!, 'Path');

# Metdata
is($doc->text_sigle, 'CMC-TSK/2014-09/2843', 'ID-text');

is($doc->doc_sigle, 'CMC-TSK/2014-09', 'ID-doc');
is($doc->corpus_sigle, 'CMC-TSK', 'ID-corpus');

my $meta = $doc->meta;

is($meta->{title}, '@ Koelle_am_Rhing 10:18', 'title');

ok(!$meta->{sub_title}, 'no subtitle');

is($meta->{publisher}, 'tagesschau.de', 'Publisher');

is($meta->{pub_date}, '20140930');

ok(!$meta->{pub_place}, 'No pub place');

is($meta->{doc_title}, 'Korpus zur Beobachtung des Schreibgebrauchs im Deutschen', 'Doc title');
is($meta->{doc_sub_title}, 'Subkorpus Internettexte, Subkorpus Leserkommentare Tagesschau, Subkorpus September 2014, Subkorpus Beispielauszug', 'Doc Sub title');

is($meta->{'funder'}, 'Bundesministerium für Bildung und Forschung', 'Funder');

is($meta->{author}, 'privat23', 'Author');
ok(!$meta->{'sgbr_author_sex'}, 'No Sex');
ok(!$meta->{'sgbr_kodex'}, 'No kodex');
is($meta->{reference}, 'http://meta.tagesschau.de/node/090285#comment-1732187', 'Publace ref');

is($meta->keywords('keywords'), '');

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

ok(!$meta->{doc_editor}, 'Doc: editor');
ok(!$meta->{doc_author}, 'Doc: author');

ok(!$meta->{corpus_title}, 'Corpus: title');
ok(!$meta->{corpus_sub_title}, 'Corpus: subtitle');
ok(!$meta->{corpus_editor}, 'Corpus: editor');
ok(!$meta->{corpus_author}, 'Corpus: author');

my $hash = $doc->to_hash;
is($hash->{title}, '@ Koelle_am_Rhing 10:18', 'Corpus title');

# Second document
$path = catdir(dirname(__FILE__), 'CMC-TSK', '2014-09', '3401');

ok($doc = KorAP::XML::Krill->new(
  path => $path . '/',
  meta_type => 'Sgbr'
), 'Create Document');

ok($doc->parse, 'Parse document');

like($doc->path, qr!\Q$path\E/!, 'Path');

# Metdata
is($doc->text_sigle, 'CMC-TSK/2014-09/3401', 'ID-text');

is($doc->doc_sigle, 'CMC-TSK/2014-09', 'ID-doc');
is($doc->corpus_sigle, 'CMC-TSK', 'ID-corpus');


$meta = $doc->meta;
is($meta->{title}, '@fitnessfrosch', 'title');

ok(!$meta->{sub_title}, 'no subtitle');

is($meta->{publisher}, 'tagesschau.de', 'Publisher');

is($meta->{pub_date}, '20141001');
is($meta->{'sgbr_date'}, '2014-10-01 00:50:00');

ok(!$meta->{pub_place}, 'No pub place');

is($meta->{doc_title}, 'Korpus zur Beobachtung des Schreibgebrauchs im Deutschen', 'Doc title');
is($meta->{doc_sub_title}, 'Subkorpus Internettexte, Subkorpus Leserkommentare Tagesschau, Subkorpus September 2014, Subkorpus Beispielauszug', 'Doc Sub title');

is($meta->{'funder'}, 'Bundesministerium für Bildung und Forschung', 'Funder');

is($meta->{author}, 'weltoffen', 'Author');
ok(!$meta->{'sgbr_author_sex'}, 'No Sex');
ok(!$meta->{'sgbr_kodex'}, 'No kodex');
is($meta->{reference}, 'http://meta.tagesschau.de/node/090308#comment-1732754', 'Publace ref');

is($meta->keywords('keywords'), '');

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

ok(!$meta->{doc_editor}, 'Doc: editor');
ok(!$meta->{doc_author}, 'Doc: author');

ok(!$meta->{corpus_title}, 'Corpus: title');
ok(!$meta->{corpus_sub_title}, 'Corpus: subtitle');
ok(!$meta->{corpus_editor}, 'Corpus: editor');
ok(!$meta->{corpus_author}, 'Corpus: author');

$hash = $doc->to_hash;
is($hash->{title}, '@fitnessfrosch', 'Corpus title');

done_testing;
__END__

