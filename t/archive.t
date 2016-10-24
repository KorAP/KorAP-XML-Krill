#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Basename 'dirname';
use File::Spec::Functions qw/catfile catdir/;
use File::Temp qw/tempdir/;

use KorAP::XML::Archive;

my $file = catfile(dirname(__FILE__), 'corpus','archive.zip');
my $archive = KorAP::XML::Archive->new($file);

unless ($archive->test_unzip) {
  plan skip_all => 'unzip not found';
};

ok($archive->test, 'Test archive');
like($archive->path(0), qr/archive\.zip$/, 'Archive path');

my @list = $archive->list_texts;
is(scalar @list, 10, 'Found all tests');
is($list[0], './TEST/BSP/1', 'First document');
is($list[-1], './TEST/BSP/10', 'First document');

my @path = $archive->split_path('./TEST/BSP/9');
is($path[0],'.', 'Prefix');
is($path[1],'TEST', 'Prefix');
is($path[2],'BSP', 'Prefix');
is($path[3],'9', 'Prefix');

my $dir = tempdir(CLEANUP => 1);

{
  local $SIG{__WARN__} = sub {};
  ok($archive->extract('./TEST/BSP/8', $dir), 'Wrong path');
};

ok(-d catdir($dir, 'TEST'), 'Test corpus directory exists');
ok(-f catdir($dir, 'TEST', 'header.xml'), 'Test corpus header exists');
ok(-d catdir($dir, 'TEST', 'BSP'), 'Test doc directory exists');
ok(-f catdir($dir, 'TEST', 'BSP', 'header.xml'), 'Test doc header exists');


# TODO: Test attaching!

done_testing;

__END__
