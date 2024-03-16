package KorAP::XML::Annotation::Spacy::Morpho;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'spacy',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->get_pos);

      my $content = $token->get_hash->{fs}->{f};

      my $array = $content->{fs}->{f} or return;

      # In case there is only a lemma/pos ...
      $array = ref $array ne 'ARRAY' ? [$array] : $array;

      my $found;

      foreach my $f (@$array) {

        next unless $f->{-name};

        # pos tag
        if (($f->{-name} eq 'pos') &&
              ($found = $f->{'#text'})) {
          $mtt->add_by_term('spacy/p:' . $found);
        }

        # lemma tag
        elsif (($f->{-name} eq 'lemma')
                 && ($found = $f->{'#text'})) {
          $mtt->add_by_term('spacy/l:' . $found);
        };
      };
    }) or return;
  return 1;
};

sub layer_info {
  ['spacy/l=tokens', 'spacy/p=tokens']
};

1;
