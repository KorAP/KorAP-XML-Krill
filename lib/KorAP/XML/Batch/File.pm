package KorAP::XML::Batch::File;
use KorAP::XML::Krill;
use Mojo::Log;
use IO::Compress::Gzip;
use IO::File;
use strict;
use warnings;

# Constructor
sub new {
  my $class = shift;
  my %param = @_;

  bless {
    cache     => $param{cache}     // undef,
    meta_type => $param{meta_type} || 'I5',
    overwrite => $param{overwrite},
    foundry   => $param{foundry}   || 'Base',
    layer     => $param{layer}     || 'Tokens',
    anno      => $param{anno}      || [[]],
    log       => $param{log}       || Mojo::Log->new(level => 'fatal'),
    primary   => $param{primary},
    pretty    => $param{pretty},
    gzip      => $param{gzip}      // 0
  }, $class;
};

# Process a file
sub process {
  my ($self, $input, $output) = @_;

  if (!$self->{overwrite} && $output && -e $output) {
    $self->{log}->debug($output . ' already exists');
    return;
  };

  # Create and parse new document
  $input =~ s{([^/])$}{$1/};
  my $doc = KorAP::XML::Krill->new(
    path      => $input,
    meta_type => $self->{meta_type},
    cache     => $self->{cache}
  );

  # Parse document
  unless ($doc->parse) {
    $self->{log}->warn(($output // $input) . " can't be processed - no document data");
    return;
  };

  # Get tokenization
  my $tokens = KorAP::XML::Tokenizer->new(
    path => $doc->path,
    doc => $doc,
    foundry => $self->{foundry},
    layer => $self->{layer},
    name => 'tokens'
  );

  # Unable to process base tokenization
  unless ($tokens->parse) {
    $self->{log}->error(($output // $input) . " can't be processed - no base tokenization");
    return;
  };

  foreach (@{$self->{anno}}) {
    $tokens->add(@$_);
  };

  my $file;
  my $print_text = ($self->{pretty} ? $tokens->to_pretty_json($self->{primary}) : $tokens->to_json($self->{primary}));

  # There is an output file given
  if ($output) {

    if ($self->{gzip}) {
      $file = IO::Compress::Gzip->new($output, TextFlag => 1, Minimal => 1);
    }
    else {
      $file = IO::File->new($output, "w"); # '>:encoding(UTF-8)'); # "w");
    };

    # Write to output
    unless ($file->print($print_text)) {
      $self->{log}->error('Unable to write to ' . $file);
    };

    # Flush pending data
    # $file->flush if $self->{gzip};

    $file->close;
  }

  # Direct output to STDOUT
  else {
    print $print_text . "\n";
  };

  return 1;
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

KorAP::XML::Batch::File - Process multiple files with identical setup


=head1 SYNOPSIS


  # Create Converter Object
  my $converter = KorAP::XML::Batch::File->new(
    overwrite => 1,
    gzip => 1
  );

  $converter->process('/my/data' => 'my-output.gz');

=head1 DESCRIPTION

Set up the configuration for a corpus and process
multiple texts with the same configuration.

=head1 METHODS

Construct a new converter object.

  my $converter = KorAP::XML::Batch::File->new(
    overwrite => 1,
    gzip => 1
  );


=head2 new

=over 2

=item cache

A L<Cache::FastMmap> compatible cache object.

=item meta_type

Meta data type to be parsed. Defaults to C<I5>,
also supports all classes in the C<KorAP::XML::Meta> namespace.

=item overwrite

Overwrite existing files!
Defaults to C<false>.

=item foundry

The foundry to use for tokenization,
defaults to C<Base>.

=item layer

The layer to use for tokenization,
defaults to C<Tokens>.

=item anno

  my $converter = KorAP::XML::Batch::File->new(
    anno => [
      ['CoreNLP', 'Morpho'],
      ['OpenNLP', 'Morpho']
    ]
  );

An array reference of array references,
containing annotation layers as foundry-layer
pairs to parse.
The list is empty by default.

=item log

A L<Mojo::Log> compatible log object.

=item primary

Export primary text associated with the document.
Defaults to C<true>.

=item pretty

Pretty print the output JSON.
Defaults to C<false>.

=item gzip

Compress the output using Gzip.
This will be ignored, if the output is undefined
(i.e. C<STDOUT>).
Defaults to C<false>.

=back

=head2 process

  $converter->process('/mydoc/');
  $converter->process('/mydoc/', '/myoutput.gzip');

Process a file and pass to a chosen output.
The first argument is mandatory and
represents the path to the KorapXML text files.
The second argument is optional and
represents a file path to write.
If the second argument is not given,
the process will write to C<STDOUT>
(in that case, the C<gzip> parameter is ignored).

=head1 AVAILABILITY

  https://github.com/KorAP/KorAP-XML-Krill


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2016, L<IDS Mannheim|http://www.ids-mannheim.de/>
Author: L<Nils Diewald|http://nils-diewald.de/>

KorAP::XML::Krill is developed as part of the
L<KorAP|http://korap.ids-mannheim.de/>
Corpus Analysis Platform at the
L<Institute for the German Language (IDS)|http://ids-mannheim.de/>,
member of the
L<Leibniz-Gemeinschaft|http://www.leibniz-gemeinschaft.de/en/about-us/leibniz-competition/projekte-2011/2011-funding-line-2/>
and supported by the L<KobRA|http://www.kobra.tu-dortmund.de> project,
funded by the
L<Federal Ministry of Education and Research (BMBF)|http://www.bmbf.de/en/>.

KorAP::XML::Krill is free software published under the
L<BSD-2 License|https://raw.githubusercontent.com/KorAP/KorAP-XML-Krill/master/LICENSE>.

=cut
