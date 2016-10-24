package KorAP::XML::Krill;
use Mojo::Base -base;
use Mojo::ByteStream 'b';
use Mojo::Util qw/encode/;
use Scalar::Util qw/weaken/;
use XML::Fast;
use Try::Tiny;
use Carp qw/croak carp/;
use KorAP::XML::Document::Primary;
use KorAP::XML::Tokenizer;
use Log::Log4perl;
use KorAP::XML::Log;
use Cache::FastMmap;
use Mojo::DOM;
use Data::Dumper;
use File::Spec::Functions qw/catdir catfile catpath splitdir splitpath rel2abs rootdir/;

our $VERSION = '0.21';

has 'path';
has [qw/text_sigle doc_sigle corpus_sigle/];
has 'meta_type' => 'I5';
has 'cache';

has log => sub {
  if(Log::Log4perl->initialized()) {
    state $log = Log::Log4perl->get_logger(__PACKAGE__);
  };
  state $log = KorAP::XML::Log->new;
  return $log;
};

# Constructor
sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;

  # Path is defined
  if (exists $self->{path}) {
    $self->{path} = rel2abs($self->{path});
    if ($self->{path} !~ m!\/$!) {
      $self->{path} .= '/';
    };
  };
  return $self;
};


# Parse document (primary data and metadata)
sub parse {
  my $self = shift;
  my $meta_data_type = $self->meta_type;

  state $ENC_RE = qr/^[^>]+encoding\s*=\s*(["'])([^\1]+?)\1/o;

  # Path to primary
  my $data_xml = $self->path . 'data.xml';
  my ($rt, $error, $file);

  my $unable = 'Unable to parse document ' . $self->path;

  # No primary data found
  unless (-e $data_xml) {
    $self->log->warn($unable . ' - no data.xml found');
    $error = 1;
  }

  else {
    # Load file
    $file = b($data_xml)->slurp;
    try {
      local $SIG{__WARN__} = sub {
        $error = 1;
      };

      $rt = xml2hash($file, text => '#text', attr => '-')->{raw_text};
    } catch  {
      $self->log->warn($unable);
      $error = 1;
    };
  };

  return if $error;

  $self->log->debug('Parse document ' . $self->path);

  # Get document id and corpus id
  if ($rt && $rt->{'-docid'}) {
    if ($rt->{'-docid'} =~ /^([^_]+)_([^\._]+?)\.(.+?)$/) {
      $self->text_sigle(join('/', $1, $2, $3));
      $self->doc_sigle(join('/', $1, $2));
      $self->corpus_sigle($1);
    }
    else {
      $self->log->warn($unable . ': ID not parseable');
      return;
    };
  }
  else {
    $self->log->warn($unable . ': No raw_text found or no ID');
    return;
  };

  # Get primary data
  my $pd = $rt->{text};

  unless ($pd) {
    $self->log->warn($unable . ': No primary data found');
    return;
  };

  # Associate primary data
  $self->{pd} = KorAP::XML::Document::Primary->new($pd);

  my @path = grep { $_ } splitdir($self->path);
  my @header;

  # Parse the corpus file, the doc file,
  # and the text file for meta information
  foreach (0..2) {
    # Removed starting '/'

    unshift @header, catfile(rootdir(), @path, 'header.xml');
    pop @path;
  };

  # Get metadata class and create an object
  my $meta_class = 'KorAP::XML::Meta::' . $meta_data_type;
  my $meta;

  if ($meta_class->can('new') || eval("require $meta_class; 1;")) {
    $meta = $meta_class->new(
      log          => $self->log,
      corpus_sigle => $self->corpus_sigle,
      doc_sigle    => $self->doc_sigle,
      text_sigle   => $self->text_sigle,
      cache        => $self->cache
    );

    # Associate meta object
    $self->{meta} = $meta;
  };

  unless ($meta) {
    $self->log->warn(
      "Metadata object for $meta_data_type not initializable"
    );
  };

  my @type = qw/corpus doc text/;
  foreach (@header) {
    # Get corpus, doc and text meta data
    my $type = shift(@type);

    # Check for cache
    next if $meta->is_cached($type);

    next unless -e $_;

    # Slurp data and probably decode
    my $slurp = b($_)->slurp;
    $slurp =~ $ENC_RE;
    my $file = $slurp->decode($2 // 'UTF-8');

    # Get DOM
    my $dom = Mojo::DOM->new($file);

    # Parse object based on DOM
    $meta->parse($dom, $type);
    $meta->do_cache($type);
  };

  return $self;
};


sub tokenize {
  my $self = shift;
  my ($token_foundry, $token_layer) = @_;

  $token_foundry //= 'OpenNLP';
  $token_layer   //= 'Tokens';

  # Create tokenizer
  my $tokens = KorAP::XML::Tokenizer->new(
    path => $self->path,
    doc => $self,
    foundry => $token_foundry,
    layer => $token_layer,
    name => 'tokens'
  );

  # Parse tokens
  unless ($tokens->parse) {
    $self->log->warn(
      'Unable to tokenize ' . $self->path .
	' with ' . $token_foundry . '#'
	  . $token_layer
    );
  }
  else {
    weaken $self;
    $self->{tokenizer} = $tokens;
  };

  return $self;
};


# Add annotation
sub annotate {
  my $self = shift;
  unless ($self->{tokenizer}) {
    $self->log->warn('No tokenizer defined')
  }
  else {
    $self->{tokenizer}->add(@_);
  };

  $self;
};


# Store arbitrary data
sub store {
  my $self = shift;
  return $self->{store} unless @_;
  return $self->{store}->{$_[0]} if @_ == 1;
  $self->{store}->{$_[0]} = $_[1];
};


# Primary data
sub primary {
  $_[0]->{pd};
};

sub meta {
  return $_[0]->{meta};
};

sub to_hash {
  my $self = shift;

  $self->parse unless $self->text_sigle;

  my %hash;

  # Get meta object
  my $meta = $self->meta;
  foreach ($meta->keys) {

    my $v = $meta->{$_};
    if (ref $v) {
      $hash{_k($_)} = $meta->keywords($_);
    }
    else {
      $v =~ s/\n/ /g;
      $v =~ s/\s\s+/ /g;
      $hash{_k($_)} = $v;
    };
  };

  foreach (qw/corpus doc text/) {
    $hash{$_ . 'Sigle'} = $self->{$_ . '_sigle'};
  };

  return \%hash;
};


sub _k {
  my $x = $_[0];
  $x =~ s/_(\w)/\U$1\E/g;
  $x =~ s/id$/ID/gi;
  return $x;
};


sub to_json {
  my $self = shift;
  unless ($self->{tokenizer}) {
    $self->log->warn('No tokenizer defined');
    return;
  };

  return $self->{tokenizer}->to_json;
};


1;


__END__

sub to_string {
  my $self = shift;

  my $string;

  foreach (@ATTR) {
    if (my $att = $self->$_) {
      $att =~ s/\n/ /g;
      $att =~ s/\s\s+/ /g;
      $string .= $_ . ' = ' . $att . "\n";
    };
  };

  $string .= 'text_class = ' . $self->text_class_string . "\n";
  $string .= 'keywords = ' . $self->keywords_string . "\n";

  return $string;
};

# Todo: Make this a KoralQuery serializer
sub to_koral_query {
  my $self = shift;
  my $hash = {};
  $hash->{'@context'} = 'http://korap.ids-mannheim.de/ns/koral/0.4/context.jsonld';
  $hash->{'@type'} = 'koral:corpus';
#  $hash->{'text'} = $self->primary->data;
#  my $hash = $self->to_hash;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

KorAP::XML::Krill - Preprocess KorAP XML documents for Krill


=head1 SYNOPSIS

  # Create Converter Object
  my $doc = KorAP::XML::Krill->new(
    path => 'mydoc-1/'
  );

  # Convert to krill json
  print $doc->parse->tokenize->annotate('Mate', 'Morpho')->to_json;


=head1 DESCRIPTION

Parse the primary and meta data of a KorAP-XML document.


=head1 ATTRIBUTES

=head2 log

L<Log::Log4perl> object for logging.

=head2 path

  $doc->path("example-004/");
  print $doc->path;

The path of the document.


=head2 primary

  print $doc->primary->data(0,20);

The L<KorAP::XML::Document::Primary> object containing the primary data.


=head1 METHODS

=head2 annotate

  $doc->annotate('Mate', 'Morpho');

Add annotation layer to conversion process.


=head2 parse

  $doc = $doc->parse;

Run the meta parsing process of the document.


=head2 tokenize

  $doc = $doc->tokenize('OpenNLP', 'Tokens');

Accept the tokenization based on a given foundry and a given layer.


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
