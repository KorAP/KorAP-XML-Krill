use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Data::Dumper;
use KorAP::XML::Tokenizer;
use KorAP::XML::Krill;
use utf8;

my $path = catdir(dirname(__FILE__), 'TEST', 'BSP', 1);

ok(my $doc = KorAP::XML::Krill->new(
  path => $path . '/',
  meta_type => 'Sgbr'
), 'Create Document');

ok($doc->parse, 'Parse document');

like($doc->path, qr!\Q$path\E/!, 'Path');

# Metdata
is($doc->text_sigle, 'TEST/BSP/1', 'ID-text');
is($doc->doc_sigle, 'TEST/BSP', 'ID-doc');
is($doc->corpus_sigle, 'TEST', 'ID-corpus');

my $meta = $doc->meta;

is($meta->{title}, 'Sommerüberraschung', 'title');
is($meta->{author}, 'TEST.BSP.Autoren.1', 'Author');
is($meta->{'sgbr_author_age_class'}, 'X', 'AgeClass');

is($meta->{'sgbr_author_sex'}, 'M', 'Sex');
is($meta->{'sgbr_kodex'}, 'M', 'Kodex');

is($meta->{doc_title}, 'Beispielkorpus', 'Doc: title');
is($meta->{doc_sub_title}, 'Subkorpus Beispieltext', 'Doc: subtitle');

is($meta->{language}, 'de', 'Language');

ok(!$meta->{publisher}, 'Publisher');
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
is($hash->{title}, 'Sommerüberraschung', 'Corpus title');
is($hash->{sgbrAuthorSex}, 'M', 'additional');

# Sgbr specific keywords
is($meta->keywords('keywords'), 'sgbrAuthorAgeClass:X sgbrAuthorSex:M sgbrKodex:M');


done_testing;


__END__
