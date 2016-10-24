package KorAP::XML::Annotation::Glemm::Morpho;
use KorAP::XML::Annotation::Base;
use strict;
use warnings;

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'glemm',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;

      my $mtt = $stream->pos($token->pos);

      my $content = $token->hash->{'fs'}->{'f'} or return;

      # All interpretations
      foreach (ref $content eq 'ARRAY' ? @$content : $content) {

	# All features
	$content = $_->{'fs'}->{'f'};

	my $lemma;
	my ($composition, $derivation) = (0,0);

	# Iterate over
	foreach (ref $content eq 'ARRAY' ? @$content : $content) {

	  # syntax
	  if (($_->{-name} eq 'lemma') && $_->{'#text'}) {
	    $lemma = $_->{'#text'};
	  }
	  elsif ($_->{-name} eq 'composition' && $_->{'#text'} eq 'true') {
	    $composition = 1;
	  }
	  elsif ($_->{-name} eq 'derivation' && $_->{'#text'} eq 'true') {
	    $derivation = 1;
	  };
	};

	$mtt->add(
	  term => 'glemm/l:' .
	    ($composition ? '+' : '_') .
	      ($derivation ? '+' : '_') .
		$lemma
	) if $lemma;
      };
    }) or return;

  return 1;
};

sub layer_info {
    ['glemm/l=tokens'];
};

1;
