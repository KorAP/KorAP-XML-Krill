#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use JSON::XS;
use Test::More;
use Scalar::Util qw/weaken/;
use Data::Dumper;
use lib 't/annotation';
use TestInit;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';


my $path = catdir(dirname(__FILE__), 'corpus', 'doc', '0001');

ok(my $doc = KorAP::XML::Krill->new( path => $path . '/' ), 'Load Korap::Document');
ok($doc->parse, 'Parse document');
like($doc->path, qr!\Q$path\E/!, 'Path');

# Metdata
is($doc->text_sigle, 'Corpus/Doc/0001', 'ID-text');
is($doc->doc_sigle, 'Corpus/Doc', 'ID-doc');
is($doc->corpus_sigle, 'Corpus', 'ID-corpus');

my $meta = $doc->meta;

is($meta->{title}, 'Beispiel Text', 'title');
is($meta->{sub_title}, 'Beispiel Text Untertitel', 'title');
is($meta->{pub_date}, '20010402', 'Publication date');
is($meta->{pub_place}, 'Mannheim', 'Publication place');
is($meta->{author}, 'Mustermann, Max', 'Author');

is($meta->{publisher}, 'Artificial articles Inc.', 'Publisher');
is($meta->{editor}, 'Monika Mustermann', 'Editor');
is($meta->{text_type}, 'Zeitung: Tageszeitung', 'Text Type');
is($meta->{text_type_art}, 'Bericht', 'Text Type Art');
is($meta->{text_type_ref}, 'Aphorismen', 'Text Type Ref');
ok(!$meta->{text_column}, 'Text Column');
ok(!$meta->{text_domain}, 'Text Domain');
is($meta->{creation_date}, '19990601', 'Creation Date');
ok(!$meta->{license}, 'License');
ok(!$meta->{pages}, 'Pages');
ok(!$meta->{file_edition_statement}, 'File Edition Statement');
ok(!$meta->{bibl_edition_statement}, 'Bibl Edition Statement');
ok(!$meta->{reference}, 'Reference');
is($meta->{language}, 'de', 'Language');

is($meta->{doc_title}, 'Beispiel Dokument', 'Doc: title');
ok(!$meta->{doc_sub_title}, 'Doc: subtitle');
ok(!$meta->{doc_editor}, 'Doc: editor');
ok(!$meta->{doc_author}, 'Doc: author');

is($meta->{corpus_title}, 'Werke von Beispiel', 'Corpus: title');
ok(!$meta->{corpus_sub_title}, 'Corpus: subtitle');
is($meta->{corpus_editor}, 'Mustermann, Monika', 'Corpus: editor');
is($meta->{corpus_author}, 'Mustermann, Max', 'Corpus: author');


done_testing;

__END__
