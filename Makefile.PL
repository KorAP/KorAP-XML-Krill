#!/usr/bin/env perl
use v5.32;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'KorAP::XML::Krill',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Merge KorAP-XML data and create Krill documents',
  VERSION_FROM => 'lib/KorAP/XML/Krill.pm',
  LICENSE      => 'freebsd',
  PREREQ_PM => {
    'Mojolicious'     => 9.22,
    'Packed::Array'   => 0.01,
    'Test::Output'    => 0,
    'Log::Any'        => 1.710,
    'JSON::XS'        => 4.03,
    'Set::Scalar'     => 1.29,
    'XML::Fast'       => 0.17,
    'Try::Tiny'       => 0.31,
    'Array::IntSpan'  => 2.004,
    'List::MoreUtils' => 0.430,
    'List::MoreUtils::XS' => 0.430,
    'Parallel::ForkManager' => 2.02,
    'IO::Compress::Gzip' => 2.102,
    'IO::Uncompress::Gunzip' => 2.102,
    'IO::Dir::Recursive' => 0.03,
    'File::Temp'      => 0.2311,
    'Module::Install' => 1.19,
    'Dumbbench'       => 0.501,
    'Benchmark'       => 0,
    'Unicode::Normalize' => 1.26,
    'Carp'            => 0,
    'strict'          => 0,
    'warnings'        => 0,
    'utf8'            => 0,
    'bytes'           => 0,
    'Pod::Usage'      => 2.01,
    'Cache::FastMmap' => 1.57,
    'Config::Simple'  => 4.58,
    'String::Random'  => 0.32,
    'File::Path'      => 2.18,
    'Path::Iterator::Rule' => 1.015,
    'Archive::Tar'    => 2.40,
    'Archive::Tar::Stream' => 0.02,
    'Clone'           => 0.45,
    'List::Util'      => 1.60,
    'Scalar::Util'    => 1.60,
  },
  MIN_PERL_VERSION => '5.032',
  test => {
    TESTS =>
      't/*.t '.
      't/annotation/*.t ' .
      't/sgbr/*.t ' .
      't/real/*.t ' .
      't/script/*.t '
	  },
  EXE_FILES => ['script/korapxml2krill'],
  META_MERGE   => {
    'meta-spec' => { version => 2 },
    requires  => { perl => '5.032' },
    resources => {
      license     => 'https://opensource.org/licenses/BSD-2-Clause',
      repository  => {
        type => 'git',
        url => 'https://github.com/KorAP/KorAP-XML-Krill.git',
        web => 'https://github.com/KorAP/KorAP-XML-Krill',
      },
      bugtracker => {
        web => 'https://github.com/KorAP/KorAP-XML-Krill/issues'
      }
    }
  }
);
