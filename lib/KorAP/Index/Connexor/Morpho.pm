package KorAP::Index::Connexor::Morpho;
use KorAP::Index::Base;

our %MAP = (
  'v_ind'   => 'mood',
  'v_imp'   => 'mood',
  'v_sub'   => 'mood',
  'v_fin'   => 'inf',
  'v_pcp'   => 'inf',
  'v_pres'  => 'tense',
  'v_past'  => 'tense',
  'v_prog'  => 'tense',
  'v_perf'  => 'tense',
  'n_abbr'  => 'type',
  'n_prop'  => 'type',
  'n_pl'    => 'type',
  'a_cmp'   => 'degree',
  'a_sub'   => 'degree',
  'num_ord' => 'type'
);

sub parse {
  my $self = shift;

  $$self->add_tokendata(
    foundry => 'connexor',
    layer => 'morpho',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->pos);

      my $content = $token->hash->{fs}->{f};

      my $found;

      my $features = $content->{fs}->{f};

      for my $f (@$features) {

      # Lemma
	if (($f->{-name} eq 'lemma') && ($found = $f->{'#text'})) {
	  if (index($found, "\N{U+00a0}") >= 0) {
	    foreach (split(/\x{00A0}/, $found)) {
	      $mtt->add(
		term => 'cnx/l:' . $_
	      );
	    }
	  }
	  else {
	    $mtt->add(
	      term => 'cnx/l:' . $found
	    );
	  };
	}

	# POS
	elsif (($f->{-name} eq 'pos') && ($found = $f->{'#text'})) {
	  $mtt->add(
	    term => 'cnx/p:' . $found
	  );

	}
	# MSD
	# This could follow
	# http://www.ids-mannheim.de/cosmas2/projekt/referenz/connexor/morph.html
	elsif (($f->{-name} eq 'msd') && ($found = $f->{'#text'})) {
	  foreach (split(':', $found)) {
	    $mtt->add(
	      term => 'cnx/m:' . $_
	    );
	  };
	};
      };
    }
  ) or return;

  return 1;
};

sub layer_info {
    ['cnx/l=tokens', 'cnx/p=tokens', 'cnx/m=tokens'];
};



1;
