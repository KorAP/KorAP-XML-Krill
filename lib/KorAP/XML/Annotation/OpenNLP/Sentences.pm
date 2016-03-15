package KorAP::XML::Annotation::OpenNLP::Sentences;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;
  my $i = 0;

  $$self->add_spandata(
    foundry => 'opennlp',
    layer => 'sentences',
    cb => sub {
      my ($stream, $span) = @_;
      my $mtt = $stream->pos($span->p_start);
      $mtt->add(
	term => '<>:opennlp/s:s',
	o_start => $span->o_start,
	o_end => $span->o_end,
	p_end => $span->p_end,
	pti => 64,
	payload => '<b>0'
      );
      $i++;
    }
  ) or return;

  $$self->stream->add_meta('opennlp/sentences', '<i>' . $i);

  return 1;
};

sub layer_info {
    ['opennlp/s=spans'];
};

1;