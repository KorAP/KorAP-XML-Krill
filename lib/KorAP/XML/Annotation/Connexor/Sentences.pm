package KorAP::XML::Annotation::Connexor::Sentences;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;
  my $i = 0;

  $$self->add_spandata(
    foundry => 'connexor',
    layer => 'sentences',
    cb => sub {
      my ($stream, $span) = @_;
      my $mtt = $stream->pos($span->p_start);
      $mtt->add(
	term => '<>:cnx/s:s',
	o_start => $span->o_start,
	o_end => $span->o_end,
	p_end => $span->p_end,
	pti => 64,
	payload => '<b>0'
      );
      $i++;
    }
  ) or return;

  $$self->stream->add_meta('cnx/sentences', '<i>' . $i);

  return 1;
};


sub layer_info {
  ['cnx/s=spans'];
};

1;