#/usr/bin/env perl
use strict;
use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use File::Temp qw/:POSIX tempfile/;
use Mojo::File;
use Test::More;
use Test::Output qw/combined_from/;
use Data::Dumper;
use KorAP::XML::Archive;

if ($ENV{SKIP_SCRIPT}) {
  plan skip_all => 'Skip script tests';
};

unless (KorAP::XML::Archive::test_unzip) {
  plan skip_all => 'unzip not found';
};

my $f = dirname(__FILE__);

my ($fh, $cfg_file) = tempfile();

my $input_base = catdir($f, '..', 'corpus', 'archives');

# Temporary extract
my $temp_out = File::Temp->newdir(CLEANUP => 0);

print $fh <<"CFG";
overwrite       0
token           OpenNLP#tokens
base-sentences  DeReKo#Structure
base-paragraphs DeReKo#Structure
base-pagebreaks DeReKo#Structure
jobs            -1
meta            I5
gzip            1
log             DEBUG
temporary-extract $temp_out
sequential-extraction 1
input-base      $input_base
CFG

close($fh);

# Path for script
my $script = catfile($f, '..', '..', 'script', 'korapxml2krill');

# Path for input
my $input = "'".catfile('wpd15*.zip') . "'";

# Temporary output
my $output = File::Temp->newdir(CLEANUP => 0);

my $cache = tmpnam();

my $call = join(
  ' ',
  'perl', $script,
  'archive',
  '--config' => $cfg_file,
  '--input' => $input,
  '--output' => $output,
  '--cache' => $cache
);

like($call, qr!config!, 'Call string');

my $stdout = combined_from(sub { system($call) });

like($stdout, qr!Reading config from!, 'Config');

# Processed using gzip
like($stdout, qr!Processed .+?WPD15-A00-00081\.json\.gz!, 'Gzip');

like($stdout, qr!Extract sequentially to!);

# Check log level
like($stdout, qr!Unable to parse KorAP::XML::Annotation::Glemm::Morpho!, 'Check log level');

# Check wildcard input
like($stdout, qr!Input is .+?wpd15-single\.zip,.+?wpd15-single\.malt\.zip,.+?wpd15-single\.corenlp\.zip,.+?wpd15-single\.opennlp\.zip,.+?wpd15-single\.mdparser\.zip,.+?wpd15-single\.tree_tagger\.zip!is, 'Wildcards');

like($stdout, qr!Run using \d+ jobs on \d+ cores!, 'Jobs');

done_testing;
__END__
