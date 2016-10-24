#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Log::Log4perl;
use Data::Dumper;

Log::Log4perl->init({
  'log4perl.rootLogger' => 'ERROR, STDERR',
  'log4perl.appender.STDERR' => 'Log::Log4perl::Appender::ScreenColoredLevels',
  'log4perl.appender.STDERR.layout' => 'PatternLayout',
  'log4perl.appender.STDERR.layout.ConversionPattern' => '[%r] %F %L %c - %m%n'
});

use File::Basename 'dirname';
use File::Spec::Functions qw/catdir catfile/;
use Test::More;
use Scalar::Util qw/weaken/;
use Data::Dumper;
use lib 't/annotation';
use File::Temp qw/tempdir/;

use KorAP::XML::Archive;

my $name = 'wpd15-single';
my @path = (dirname(__FILE__), '..', 'corpus','archives');

my $file = catfile(@path, $name . '.zip');
my $archive = KorAP::XML::Archive->new($file);

unless ($archive->test_unzip) {
  plan skip_all => 'unzip not found';
};

use_ok('KorAP::XML::Annotation::MDParser::Dependency');
use_ok('KorAP::XML::Krill');
use_ok('KorAP::XML::Tokenizer');


ok($archive->attach('#' . catfile(@path, $name . '.mdparser.zip')), 'Attach mdparser archive');

my $dir = tempdir();

my $f_path = 'WPD15/A00/00081';
$archive->extract($f_path, $dir);

ok(my $doc = KorAP::XML::Krill->new( path => $dir . '/' . $f_path));

ok($doc->parse, 'Krill parser works');

my $tokens = KorAP::XML::Tokenizer->new(
  path => $doc->path,
  doc => $doc,
  foundry => 'Base',
  layer => 'Tokens',
  name => 'tokens'
) or return;

$tokens->parse or return;

ok($tokens->add('MDParser', 'Dependency'), 'Add Dependency');

my $data = $tokens->to_data->{data};


is($data->{tokenSource}, 'base#tokens', 'TokenSource');
like($data->{foundries}, qr!mdparser/dependency!, 'foundries');
like($data->{layerInfos}, qr!mdp/d=rels!, 'foundries');

my $stream = $data->{stream};

is($stream->[0]->[0], '-:tokens$<i>3555', 'Token count');

# Term-to-term
is($stream->[0]->[1], '<:mdp/d:NMOD$<b>32<i>5', 'Term-to-Term');
is($stream->[5]->[0], '>:mdp/d:NMOD$<b>32<i>0', 'Term-to-Term');

# Element-to-term
is($stream->[0]->[8], '<:mdp/d:ROOT$<b>34<i>0<i>317<i>40<i>0', 'Element-to-Term');
is($stream->[0]->[10], '>:mdp/d:ROOT$<b>33<i>0<i>317<i>0<i>40', 'Term-to-Element');


is($stream->[-1]->[0], '>:mdp/d:ROOT$<b>33<i>26130<i>26153<i>3553<i>3554', 'Term-to-Element');
is($stream->[3553]->[1], '<:mdp/d:ROOT$<b>34<i>26130<i>26153<i>3554<i>3553', 'Element-to-Term');

done_testing;
__END__
