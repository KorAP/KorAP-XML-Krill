package KorAP::XML::Annotation::RWK::Structure;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;
  my (@sentences, @paragraphs);

  my ($last_p, $last_o) = (0,0);

  $$self->add_spandata(
    foundry => 'struct',
    layer => 'structure',
    cb => sub {
      my ($stream, $span) = @_;

      # Read feature
      my $feature = $span->get_hash->{fs}->{f};
      my $attrs;

      # Get attributes
      if (ref $feature eq 'ARRAY') {
        $attrs = $feature->[1]->{fs}->{f};
        $attrs = ref $attrs eq 'ARRAY' ? $attrs : [$attrs];
        $feature = $feature->[0];
      };

      # Get term label
      my $name = $feature->{'#text'};

      # Check only for anchors
      if ($name eq 's-milestone') {
        push @sentences, [ $span->get_p_start, $span->get_o_start ];
      }
      elsif ($name eq 'p-milestone') {
        push @paragraphs, [ $span->get_p_start, $span->get_o_start ];
      }
      else {
        $last_p = $span->get_p_start;
        $last_o = $span->get_o_end;
      }
    }
  ) or return;

  my ($sentences, $paragraphs) = (0, 0);

  # Add final position
  push @sentences, [$last_p, $last_o];
  push @paragraphs, [$last_p, $last_o];

  my $stream = $$self->stream;
  my %hash = (
    s => \@sentences,
    p => \@paragraphs
  );
  while (my ($type, $list) = each %hash) {
    my ($p_start, $o_start) = (0,0);

    # Sort and unique milestones
    @$list = sort {
      $a->[0] <=> $b->[0]
    } @$list;

    # Iterate overs milestones
    foreach (@$list) {

      if (($_->[0] == $p_start) || ($_->[1] == $o_start)) {
        next;
      };

      my $mtt = $stream->pos($p_start);

      if (!$mtt) {
        $p_start--;

        if (($_->[0] == $p_start) || ($_->[1] == $o_start)) {
          next;
        };

        $mtt = $stream->pos($p_start);
      };

      # Add the base sentence
      my $mt = $mtt->add_by_term('<>:base/s:' . $type);
      $mt->set_o_start($o_start);
      $mt->set_o_end($_->[1]);
      $mt->set_p_start($p_start);
      $mt->set_p_end($_->[0]);
      $mt->set_pti(64);
      $mt->set_payload('<b>1');

      if ($type eq 's') {
        $sentences++;
      } else {
        $paragraphs++;
      };

      $p_start = $_->[0];
      $o_start = $_->[1];
    };

    # Set meta information about sentence count
    if ($type eq 's') {
      $stream->add_meta('base/sentences', '<i>' . $sentences);
    }
    else {
      $stream->add_meta('base/paragraphs', '<i>' . $paragraphs);
    };
  };

  # Set meta information about sentence count
  return 1;
};

sub layer_info {
  [];
};


1;
__END__
