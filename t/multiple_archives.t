#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile catdir/;
use File::Temp qw/tempdir/;

use KorAP::XML::Archive;

my $name = 'wpd15-single';
my @path = (dirname(__FILE__), 'corpus','archives');

my $file = catfile(@path, $name . '.zip');
my $archive = KorAP::XML::Archive->new($file);

unless ($archive->test_unzip) {
    plan skip_all => 'unzip not found';
};

ok($archive->test, 'Test archive');

like($archive->path(0), qr/wpd15-single\.zip$/, 'Archive path');

ok($archive->attach(catfile(@path, 'fake.zip')), 'Attach fake archive');

# Fake archive is no valid zip file
ok(!$archive->test, 'Test archive');

# Recreate archive object
$archive = KorAP::XML::Archive->new($file);

# Test again
ok($archive->test, 'Test archive');

my @list = $archive->list_texts;
is(scalar @list, 1, 'Found all tests');

# Attach further archives
ok($archive->attach(catfile(@path, $name . '.corenlp.zip')), 'Add corenlp');
ok($archive->attach(catfile(@path, $name . '.malt.zip')), 'Add malt');
ok($archive->attach(catfile(@path, $name . '.mdparser.zip')), 'Add mdparser');
ok($archive->attach(catfile(@path, $name . '.opennlp.zip')), 'Add opennlp');
ok($archive->attach(catfile(@path, $name . '.tree_tagger.zip')), 'Add tree tagger');

@list = $archive->list_texts;
is(scalar @list, 1, 'Found all tests');
is($list[0], 'WPD15/A00/00081', 'First document');

ok($archive->test, 'Test all archives');

# Split path
@path = $archive->split_path($list[0]);
is($path[0],'', 'Prefix');
is($path[1],'WPD15', 'Prefix');
is($path[2],'A00', 'Prefix');
is($path[3],'00081', 'Prefix');

# Extract everything to temporary directory
my $dir = tempdir(CLEANUP => 1);
{
  local $SIG{__WARN__} = sub {};
  ok($archive->extract($list[0], $dir), 'Wrong path');
};

ok(-d catdir($dir, 'WPD15'), 'Test corpus directory exists');
ok(-f catdir($dir, 'WPD15', 'header.xml'), 'Test corpus header exists');
ok(-d catdir($dir, 'WPD15', 'A00'), 'Test doc directory exists');
ok(-f catdir($dir, 'WPD15', 'A00', 'header.xml'), 'Test doc header exists');
ok(-d catdir($dir, 'WPD15', 'A00', '00081'), 'Test text directory exists');
ok(-f catdir($dir, 'WPD15', 'A00', '00081', 'header.xml'), 'Test text header exists');

ok(-f catdir($dir, 'WPD15', 'A00', '00081', 'data.xml'), 'Test primary data exists');

my @file = ('WPD15', 'A00', '00081');
ok(-f catdir($dir, @file, 'base', 'paragraph.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'base', 'sentences.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'base', 'tokens.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'base', 'tokens_aggr.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'base', 'tokens_conservative.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'struct', 'structure.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'corenlp', 'constituency.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'corenlp', 'metadata.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'corenlp', 'morpho.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'corenlp', 'sentences.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'corenlp', 'tokens.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'malt', 'dependency.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'malt', 'metadata.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'mdparser', 'dependency.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'mdparser', 'metadata.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'opennlp', 'metadata.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'opennlp', 'morpho.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'opennlp', 'sentences.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'opennlp', 'tokens.xml'), 'Annotation data exists');

ok(-f catdir($dir, @file, 'tree_tagger', 'metadata.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'tree_tagger', 'morpho.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'tree_tagger', 'sentences.xml'), 'Annotation data exists');
ok(-f catdir($dir, @file, 'tree_tagger', 'tokens.xml'), 'Annotation data exists');


done_testing;
__END__


