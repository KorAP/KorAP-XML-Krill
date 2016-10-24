package KorAP::XML::Tokenizer::Tokens;
use Mojo::Base 'KorAP::XML::Tokenizer::Units';
use Mojo::ByteStream 'b';
use KorAP::XML::Tokenizer::Token;
use Carp qw/croak carp/;
use File::Spec::Functions qw/catdir catfile/;
use XML::Fast;
use Try::Tiny;

has 'log' => sub {
  Log::Log4perl->get_logger(__PACKAGE__)
};

sub parse {
  my $self = shift;

  # my $path = $self->path . $self->foundry . '/' . $self->layer . '.xml';
  my $path = catfile($self->path, $self->foundry, $self->layer . '.xml');

  # Legacy data support
  unless (-e $path) {
    if ($self->layer eq 'namedentities') {
      $path = $self->path . $self->foundry . '/ne_combined.xml';
      return unless -e $path;
    }
    elsif ($self->layer eq 'morpho' && $self->foundry eq 'glemm') {
      $path = catfile($self->path, $self->foundry, 'glemm.xml');
      return unless -e $path;
    }
    else {
      return;
    };
  };

  my $file = b($path)->slurp;

  # Bug workaround
  if ($self->foundry eq 'glemm') {
    if (index($file, "</span\n") > 0 || index($file, "</span\r") > 0) {
	$file =~ s!</span[\n\r]!</span>\n!g;
    };
  };

#  my $spans = Mojo::DOM->new($file);
#  $spans->xml(1);

  my ($spans, $error);
  try {
      local $SIG{__WARN__} = sub {
	  $error = 1;
      };
      $spans = xml2hash($file, text => '#text', attr => '-')->{layer}->{spanList};
  }
  catch  {
      $self->log->warn('Span error in ' . $path . ($_ ? ': ' . $_ : ''));
      $error = 1;
  };

  return if $error;

  if (ref $spans && $spans->{span}) {
      $spans = $spans->{span};
  }
  else {
      return [];
  };

  $spans = [$spans] if ref $spans ne 'ARRAY';

  my ($should, $have) = (0,0);

  my @tokens;

  foreach my $s (@$spans) {

    $should++;

    my $token = $self->token(
      $s->{-from},
      $s->{-to},
      $s
    ) or next;

    $have++;

    push(@tokens, $token);
  };

  $self->should($should);
  $self->have($have);

  return \@tokens;
};


1;
