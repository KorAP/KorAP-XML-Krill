#/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use File::Temp qw/:POSIX tempdir/;
use Mojo::File;
use Mojo::Util qw/quote/;
use Mojo::JSON qw/decode_json/;
use IO::Uncompress::Gunzip;
use Test::More;
use Test::Output qw/:stdout :stderr :functions/;
use Data::Dumper;
use KorAP::XML::Archive;
use utf8;
use Archive::Tar;

if ($ENV{SKIP_SCRIPT}) {
  plan skip_all => 'Skip script tests';
};

my $f = dirname(__FILE__);
my $script = catfile($f, '..', '..', 'script', 'korapxml2krill');

my $call = join(
  ' ',
  'perl', $script,
  'archive'
);

unless (KorAP::XML::Archive::test_unzip) {
  plan skip_all => 'unzip not found';
};

# Test without parameters
stdout_like(
  sub {
    system($call);
  },
  qr!archive.+?\$ korapxml2krill!s,
  $call
);

my $input = catfile($f, '..', 'corpus', 'archive.zip');
ok(-f $input, 'Input archive found');

my $output = File::Temp->new;

ok(-f $output, 'Output directory exists');

my $input_quotes = "'".catfile($f, '..', 'corpus', 'archives', 'wpd15*.zip') . "'";

my $cache = tmpnam();

$call = join(
  ' ',
  'perl', $script,
  'archive',
  '--input' => $input_quotes,
  '--output' => $output . '.tar',
  '--cache' => $cache,
  '-t' => 'Base#tokens_aggr',
  '--to-tar'
);

# Test without parameters
my $combined = combined_from( sub { system($call) });

like($combined, qr!Input is .+?wpd15-single\.zip,.+?wpd15-single\.malt\.zip,.+?wpd15-single\.corenlp\.zip,.+?wpd15-single\.opennlp\.zip,.+?wpd15-single\.mdparser\.zip,.+?wpd15-single\.tree_tagger\.zip!is, 'Input is fine');

like($combined, qr!Writing to file .+?\.tar!, 'Write out');
like($combined, qr!Wrote to tar archive!, 'Write out');

# Now test with multiple jobs
$call = join(
  ' ',
  'perl', $script,
  'archive',
  '--input' => $input,  # Use the same input as the first test
  '--output' => $output . '_multi.tar',
  '--cache' => $cache,
  '-t' => 'Base#tokens_aggr',
  '-m' => 'Sgbr',  # Add meta type parameter
  '--to-tar',
  '--gzip',  # Add gzip parameter
  '--jobs' => 3  # Use 3 jobs to test multiple tar files
);

# Test with multiple jobs
$combined = combined_from( sub { system($call) });

like($combined, qr!Writing to file .+?\.tar!, 'Write out');
like($combined, qr!Merging 3 temporary tar files!, 'Merging correct number of temp files');
like($combined, qr!Wrote to tar archive!, 'Write out');

# Read the merged tar with --ignore-zeros
my $tar_file = $output . '_multi.tar';
ok(-f $tar_file, 'Multi-job tar file exists');

# Use Archive::Tar to read the merged tar
my $merged_tar = Archive::Tar->new;
ok($merged_tar->read($tar_file, 1, {ignore_zeros => 1}), 'Can read merged tar with ignore_zeros');

# Verify expected files are present
ok($merged_tar->contains_file('TEST-BSP-1.json.gz'), 'Expected file found in merged tar');

# Check the content is valid
my $content = $merged_tar->get_content('TEST-BSP-1.json.gz');
ok(length($content) > 0, 'File content is not empty');
is(scalar($merged_tar->list_files()), 1, 'One file in tar');

# Test with multiple jobs and multiple input files
$call = join(
  ' ',
  'perl', $script,
  'archive',
  '--input' => 't/corpus/artificial',  # Use artificial test corpus
  '--output' => $output . '_multi_files.tar',
  '--cache' => $cache,
  '-t' => 'Base#sentences',  # Use sentences.xml
  '-m' => 'Sgbr',
  '--to-tar',
  '--gzip',
  '--jobs' => 3
);

# Run multi-file test
$combined = combined_from( sub { system($call) });

like($combined, qr!Writing to file .+?\.tar!, 'Write out for multi-file');
like($combined, qr!Merging 3 temporary tar files!, 'Merging correct number of temp files');
like($combined, qr!Wrote to tar archive!, 'Write out');

# Read the merged tar with --ignore-zeros
my $multi_tar_file = $output . '_multi_files.tar';
ok(-f $multi_tar_file, 'Multi-file tar exists');

# Use Archive::Tar to read the merged tar
my $multi_merged_tar = Archive::Tar->new;
ok($multi_merged_tar->read($multi_tar_file, 1, {ignore_zeros => 1}), 'Can read multi-file tar with ignore_zeros');

# Check that the file is in the tar
my @files = $multi_merged_tar->list_files();
my $found_files = join("\n", @files);

like($found_files, qr/artificial\.json\.gz/, 'Contains artificial document');

done_testing;
__END__
