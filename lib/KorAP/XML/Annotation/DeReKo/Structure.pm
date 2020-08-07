package KorAP::XML::Annotation::DeReKo::Structure;
use KorAP::XML::Annotation::Base;
use List::Util qw/first/;
use Scalar::Util qw/looks_like_number/;

sub parse {
  my $self = shift;
  my $as_base = shift // 0;
  my ($sentences, $paragraphs) = (0,0);

  $$self->add_spandata(
    foundry => 'struct',
    layer => 'structure',
    cb => sub {
      my ($stream, $span) = @_;
      my $tui = 0;

      # Get starting position
      my $p_start = $span->get_p_start;

      # Read feature
      my $feature = $span->get_hash->{fs}->{f};
      my $attrs;

      # Get attributes
      if (ref $feature eq 'ARRAY') {
        $attrs = $feature->[1]->{fs}->{f};
        $attrs = ref $attrs eq 'ARRAY' ? $attrs : [$attrs];
        $feature = $feature->[0];
        $tui = $stream->tui($p_start);
      };

      # Get term label
      my $name = $feature->{'#text'};

      # Get the mtt
      my $mtt = $stream->pos($p_start);

      unless ($mtt) {

        # This is a special case were a milestone is at the
        # end of a text and can't be indexed at the moment!
        $$self->log->warn(
          'Span ' . $span->to_string . ' can\'t be indexed'
        );
        return;
      };

      # Add structure
      my $mt = $mtt->add_span('<>:dereko/s:' . $name, $span);
      # $mt->set_p_start($p_start);
      $mt->set_pti($span->get_milestone ? 65 : 64);

      my $level = $span->get_hash->{'-l'};
      if ($level || $tui) {
        my $pl;
        $pl .= '<b>' . ($level ? $level - 1 : 0);
        $pl .= '<s>' . $tui if $tui;
        $mt->set_payload($pl);
      };

      # Use sentence and paragraph elements for base
      if ($as_base && ($name eq 's' || $name eq 'p' || $name eq 'pb')) {

        if ($name eq 's' && index($as_base, 'sentences') >= 0) {
          # Clone Multiterm
          $mt = $mt->clone;
          $mt->set_term('<>:base/s:' . $name);
          $mt->set_payload('<b>2');
          $sentences++;

          # Add to stream
          $mtt->add_blessed($mt);
        }
        elsif ($name eq 'p' && index($as_base, 'paragraphs') >= 0) {
          # Clone Multiterm
          $mt = $mt->clone;
          $mt->set_term('<>:base/s:' . $name);
          $mt->set_payload('<b>1');
          $paragraphs++;

          # Add to stream
          $mtt->add_blessed($mt);
        }

        # Add pagebreaks
        elsif ($name eq 'pb' && index($as_base, 'pagebreaks') >= 0) {
          if (my $nr = first { $_->{-name} eq 'n' } @$attrs) {
            if (($nr = $nr->{'#text'}) && looks_like_number($nr)) {
              $mt = $mtt->add_by_term('~:base/s:pb');
              $mt->set_payload('<i>' . $nr . '<i>' . $span->get_o_start);
              $mt->set_stored_offsets(0);
            };
          };
        };
      };

      # Add attributes
      if ($attrs) {

        my $pl = '<s>' . $tui .($span->get_milestone ? '' : '<i>' . $span->get_p_end);

        # Set a tui if attributes are set
        foreach (@$attrs) {

          # Add attributes
          $mt = $mtt->add_by_term('@:dereko/s:' . $_->{'-name'} . ($_->{'#text'} ? ':' . $_->{'#text'} : ''));
          $mt->set_p_start($p_start);
          $mt->set_pti(17);
          $mt->set_payload($pl);
        };
      };
    }
  ) or return;

  if ($as_base) {
    if (index($as_base, 'sentences') >= 0) {
      $$self->stream->add_meta('base/sentences', '<i>' . $sentences);
    };
    if (index($as_base, 'paragraphs') >= 0) {
      $$self->stream->add_meta('base/paragraphs', '<i>' . $paragraphs);
    };
  };

  return 1;
};

sub layer_info {
  ['dereko/s=spans'];
};

1;
