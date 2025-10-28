package KorAP::XML::Annotation::Spacy::Dependency;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;

  # Relation data
  # Supports term-to-term and term-to-element only
  $$self->add_tokendata(
    foundry => 'spacy',
    layer => 'dependency',
    cb => sub {
      my ($stream, $source, $tokens) = @_;

      # Get MultiTermToken from stream for source
      my $mtt = $stream->pos($source->get_pos);

      # Serialized information from token
      my $content = $source->get_hash;

      # Get relation information
      my $rel = $content->{rel};
      $rel = [$rel] unless ref $rel eq 'ARRAY';
      my $mt;

      # Iterate over relations
      foreach (@$rel) {
        my $label = $_->{-label};

        # Relation type is unary
        # Unary means, it refers to itself!
        if ($_->{-type} && $_->{-type} eq 'unary') {

          # Target is at the same position!
          my $pos = $source->get_pos;

          # Add relations
          $mt = $mtt->add_by_term('>:spacy/d:' . $label);
          $mt->set_pti(32); # term-to-term relation
          $mt->set_payload(
            '<i>' . $pos # right part token position
          );
          my $clone = $mt->clone;
          $clone->set_term('<:spacy/d:' . $label);
          $mtt->add_blessed($clone);
        }

        # Not unary
        elsif (!$_->{type}) {

          # Get information about the target token
          my $from = $_->{span}->{-from};
          my $to   = $_->{span}->{-to};

          # Target
          my $target = $tokens->token($from, $to);

          # Relation is term-to-term with a found target!
          if ($target) {

            $mt = $mtt->add_by_term('>:spacy/d:' . $label);
            $mt->set_pti(32); # term-to-term relation
            $mt->set_payload(
              '<i>' . $target->get_pos # right part token position
            );

            my $target_mtt = $stream->pos($target->get_pos);
            $mt = $target_mtt->add_by_term('<:spacy/d:' . $label);
            $mt->set_pti(32); # term-to-term relation
            $mt->set_payload(
              '<i>' . $source->get_pos # left part token position
            );
          }

          # Relation is possibly term-to-element with a found target!
          elsif ($target = $tokens->span($from, $to)) {

            $mt = $mtt->add_by_term('>:spacy/d:' . $label);
            $mt->set_pti(33); # term-to-element relation
            $mt->set_payload(
              '<i>' . $target->get_o_start . # end position
                '<i>' . $target->get_o_end . # end position
                '<i>' . $target->get_p_start . # right part start position
                '<i>' . $target->get_p_end # right part end position
              );

            my $target_mtt = $stream->pos($target->get_p_start);
            $mt = $target_mtt->add_by_term('<:spacy/d:' . $label);
            $mt->set_pti(34); # element-to-term relation
            $mt->set_payload(
              '<i>' . $target->get_o_start . # end position
                '<i>' . $target->get_o_end . # end position
                '<i>' . $target->get_p_end . # right part end position
                '<i>' . $source->get_pos # left part token position
              );
          };
        };
      };
    }) or return;

  return 1;
};

sub layer_info {
  ['spacy/d=rels']
};

1;

__END__
