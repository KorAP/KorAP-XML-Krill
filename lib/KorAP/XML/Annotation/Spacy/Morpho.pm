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

        # XPOS tag (language-specific POS)
        if (($f->{-name} eq 'pos') &&
              ($found = $f->{'#text'})) {
          $mtt->add_by_term('spacy/p:' . $found);
        }

        # UPOS tag (universal POS)
        elsif (($f->{-name} eq 'upos') &&
                 ($found = $f->{'#text'})) {
          $mtt->add_by_term('spacy/u:' . $found);
        }

        # lemma tag
        elsif (($f->{-name} eq 'lemma')
                 && ($found = $f->{'#text'})) {
          $mtt->add_by_term('spacy/l:' . $found);
        }

        # morphological features (msd)
        elsif ($f->{-name} eq 'msd' &&
                 ($found = lc($f->{'#text'}))) {

          # Split all values
          foreach (split '\|', $found) {
            my ($x, $y) = split "=", $_;
            # case, tense, number, mood, person, degree, gender, etc.
            $mtt->add_by_term('spacy/m:' . $x . ($y ? ':' . $y : ''));
          };
        };
      };
    }) or return;
  return 1;
};

sub layer_info {
  ['spacy/l=tokens', 'spacy/p=tokens', 'spacy/u=tokens', 'spacy/m=tokens']
};

1;
