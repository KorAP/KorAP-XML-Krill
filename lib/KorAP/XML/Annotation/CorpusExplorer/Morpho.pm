package KorAP::XML::Annotation::CorpusExplorer::Morpho;
use KorAP::XML::Annotation::Base;
use Mojo::Util qw'trim';

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'corpusexplorer',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->get_pos);

      my $content = $token->get_hash->{fs}->{f} or return;

      $content = ref $content ne 'ARRAY' ? [$content] : $content;

      my $start = $token->get_hash->{-from};

      # Iterate over feature structures
      foreach my $fs (@$content) {
        $content = $fs->{fs}->{f} or next;

        foreach (@$content) {

          next unless $_->{'#text'};
          my $value = trim $_->{'#text'} or next;

          # POS
          if ($_->{-name} eq 'ctag') {
            $mtt->add_by_term('cex/p:' . $value);
          }

          # Lemma
          elsif ($_->{-name} eq 'lemma') {
            $mtt->add_by_term('cex/l:' . $value);
          }

          # Phrase
          elsif ($_->{-name} eq 'phrase') {
            $mtt->add_by_term('cex/phrase:' . $value);
          };

          if ($start == 809) {
            warn $mtt->to_string;
            warn $value;
          };
        };
      };
    }) or return;

  return 1;
};

sub layer_info {
  ['cex/p=tokens','cex/l=tokens','cex/phrase=tokens'];
};

1;
