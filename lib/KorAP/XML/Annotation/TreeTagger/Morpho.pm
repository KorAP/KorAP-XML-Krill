package KorAP::XML::Annotation::TreeTagger::Morpho;
use KorAP::XML::Annotation::Base;
use POSIX 'floor';
use Scalar::Util 'looks_like_number';

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'tree_tagger',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->get_pos);

      my $content = $token->get_hash->{fs}->{f};

      my $found;

      $content = ref $content ne 'ARRAY' ? [$content] : $content;

      my (%lemma, %pos) = ();

      # Iterate over feature structures
      foreach my $fs (@$content) {
        $content = $fs->{fs}->{f};

        my @val;
        my $certainty = 1;
        foreach (@$content) {
          if ($_->{-name} eq 'certainty') {

            if (looks_like_number($_->{'#text'})) {
              $certainty = $_->{'#text'};
            }
            else {
              $certainty = 1;
              $$self->log->warn('"' . $_->{'#text'} . '" is not a valid certainty value');
            }
          }
          else {
            push @val, $_
          };
        };

        # Iterate over values
        foreach (@val) {
          # lemma
          if (($_->{-name} eq 'lemma') &&
                ($found = $_->{'#text'}) &&
                ($found ne 'UNKNOWN') &&
                ($found ne '?')) {
            $lemma{$found} += $certainty // 1;
          };

          # pos
          if (($_->{-name} eq 'ctag' || $_->{-name} eq 'pos') && ($found = $_->{'#text'})) {
            $pos{$found} += $certainty // 1;
          };
        };
      };

      my %term;
      my $mt;
      foreach (keys %lemma) {
        if ($lemma{$_} < 1) {
          $mt = $mtt->add_by_term('tt/l:' . $_);
          $mt->set_pti(129);
          $mt->set_payload('<b>' . floor(($lemma{$_} * 255)));
        } else {
          $mtt->add_by_term('tt/l:' . $_);
        };
      };

      foreach (keys %pos) {
        if ($pos{$_} < 1) {
          $mt = $mtt->add_by_term('tt/p:' . $_);
          $mt->set_pti(129);
          $mt->set_payload('<b>' . floor(($pos{$_} * 255)));
        } else {
          $mtt->add_by_term('tt/p:' . $_);
        };
      };

    }) or return;

  return 1;
};

sub layer_info {
  ['tt/p=tokens', 'tt/l=tokens']
};

1;
