package KorAP::XML::Annotation::XIP::Morpho;
use KorAP::XML::Annotation::Base;

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'xip',
    layer => 'morpho',
    encoding => 'xip',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->get_pos);

      my $content = $token->get_hash->{fs}->{f}->{fs}->{f};

      my $found;

      my $capital = 0;
      foreach (@$content) {
        # pos
        if (($_->{-name} eq 'pos') &&
              ($found = $_->{'#text'})) {
          $mtt->add_by_term('xip/p:' . $found);

          $capital = 1 if $found eq 'NOUN';
        }
      };

      foreach (@$content) {
        # lemma
        if (($_->{-name} eq 'lemma') &&
              ($found = $_->{'#text'})) {

          # Verb delimiter (aus=druecken)
          $mtt->add_by_term('xip/l:' . $found);
          if ($found =~ tr/=//d) {
            $mtt->add_by_term('xip/l:' . $found);
          };

          # Composites
          my (@token) = split('#', $found);

          next if @token == 1;

          my $full = '';
          foreach (@token) {
            $full .= $_;
            $_ =~ s{/\w+$}{};
            $mtt->add_by_term('xip/l:#' . $_);
          };
        };
      };
    }) or return;

  return 1;
};

sub layer_info {
  ['xip/l=tokens', 'xip/p=tokens']
};


1;
