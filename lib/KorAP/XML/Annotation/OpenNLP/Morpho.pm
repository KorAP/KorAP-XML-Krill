package KorAP::XML::Annotation::OpenNLP::Morpho;
use KorAP::XML::Annotation::Base;
use Scalar::Util 'weaken';
use POSIX 'floor';
use Scalar::Util 'looks_like_number';


sub parse {
  ${shift()}->add_tokendata(
    foundry => 'opennlp',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->get_pos);

      my $content = $token->get_hash->{fs}->{f} or return;

      $content = $content->{fs}->{f} or return;

      if (ref $content eq 'HASH') {
        # syntax
        if (($content->{-name} eq 'pos') && $content->{'#text'}) {
          $mtt->add_by_term('opennlp/p:' . $content->{'#text'});
        };
      }

      elsif (ref $content eq 'ARRAY') {
        my ($pos, $certainty);

        foreach (@$content) {
          if (($_->{-name} eq 'pos') && $_->{'#text'}) {
            $pos = $_->{'#text'};
          }

          elsif ($_->{-name} eq 'certainty') {
            if (looks_like_number($_->{'#text'})) {
              $certainty = $_->{'#text'};
            }
          };
        };

        return unless $pos;

        my $mt = $mtt->add_by_term('opennlp/p:' . $pos);
        $mt->set_pti(129);
        $mt->set_payload('<b>' . floor((($certainty//1) * 255)));
      };
    }) or return;

  return 1;
};

sub layer_info {
  ['opennlp/p=tokens'];
};

1;
