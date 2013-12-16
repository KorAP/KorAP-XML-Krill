package KorAP::Tokenizer::Spans;
use Mojo::Base 'KorAP::Tokenizer::Units';
use KorAP::Tokenizer::Span;
# use Mojo::DOM;
use Mojo::ByteStream 'b';
use XML::Fast;
use Try::Tiny;

has 'range';

has 'log' => sub {
  Log::Log4perl->get_logger(__PACKAGE__)
};

sub parse {
  my $self = shift;
  my $path = $self->path . $self->foundry . '/' . $self->layer . '.xml';

  return unless -e $path;

  my $file = b($path)->slurp;

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
  my ($from, $to, $h);

  my @spans;
  my $p = $self->primary;

  foreach my $s (@$spans) {

    $should++;

    my $span = $self->span(
      $s->{-from},
      $s->{-to},
      $s
    ) or next;

    $have++;

    push(@spans, $span);
  };

  $self->should($should);
  $self->have($have);

  return \@spans;
};

1;
