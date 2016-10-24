package KorAP::XML::Tokenizer;
use Mojo::Base -base;
use Mojo::ByteStream 'b';
use XML::Fast;
use Try::Tiny;
use Carp qw/croak/;
use Scalar::Util qw/weaken/;
use KorAP::XML::Tokenizer::Range;
use KorAP::XML::Tokenizer::Match;
use KorAP::XML::Tokenizer::Spans;
use KorAP::XML::Tokenizer::Tokens;
use KorAP::XML::Index::MultiTermTokenStream;
use List::MoreUtils 'uniq';
use JSON::XS;
use Log::Log4perl;

# TODO 1:
# Bei den Autoren im Index darauf achten,
# dass auch "etc." indiziert wird

# TODO 2:
# That's now implemented but deactivated

# Add punktuations to the index
# [Er sagte: "Hallo - na?"] becomes
# [s:Er|tt/l:er|_1#0-2]
# [s:sagte|tt/l:sagen|_2#3-8|.>::#8-9$1|.>tt/l:PUNCT#8-9$1|.>:"#10-11$2|.>tt/l:PUNCT#10-11$2]
# [s:Hallo|tt/l:hallo|_3#11-16|.<::#8-9$2|.<tt/l:PUNCT#8-9$2|.<:"#10-11$1|.<:tt/l:PUNCT#10-11$1|.>:-#17-18$1|.>tt/l:PUNCT#17-18$1]
# [s:na|tt/l:na|_4#19-21|.<:-#17-18$1|.<tt/l:PUNCT#17-18$1|.>:?#21-22$1|.>tt/l:PUNCT#21-22$1|.>:"#22-23$2|.>tt/l:PUNCT#22-23$2]


has [qw/path foundry doc stream should have name/];
has layer => 'Tokens';

has log => sub {
  if (Log::Log4perl->initialized()) {
    state $log = Log::Log4perl->get_logger(__PACKAGE__);
    return $log;
  };
  state $log = KorAP::XML::Log->new;
  return $log;
};

# Parse tokens of the document
sub parse {
  my $self = shift;

  # Create new token stream
  my $mtts = KorAP::XML::Index::MultiTermTokenStream->new;
  my $path = $self->path . lc($self->foundry) . '/' . lc($self->layer) . '.xml';

  unless (-e $path) {
    $self->log->warn('Unable to load base tokenization: ' . $path);
    return;
  };

  my $file = b($path)->slurp;

  my $doc = $self->doc;

  my ($should, $have) = (0, 0);

  # Create range and match objects
  my $range = KorAP::XML::Tokenizer::Range->new;
  my $match = KorAP::XML::Tokenizer::Match->new;

  my $old = 0;

  $self->log->trace('Tokenize data ' . $self->foundry . ':' . $self->layer);

  # TODO: Reuse the following code from Spans.pm and Tokens.pm
  my ($tokens, $error);
  try {
    local $SIG{__WARN__} = sub {
      $error = 1;
    };
    $tokens = xml2hash(
      $file,
      text => '#text',
      array => ['span'],
      attr => '-'
    )->{layer}->{spanList};
  } catch {
    $self->log->warn('Token error in ' . $path . ($_ ? ': ' . $_ : ''));
    $error = 1;
  };

  return if $error;

  if (ref $tokens && $tokens->{span}) {
    $tokens = $tokens->{span};
  }
  else {
    return $self;
  };

  $tokens = [$tokens] if ref $tokens ne 'ARRAY';

  # Iterate over all tokens
  # $tokens->find('span')->each(
  #    sub {
  # my $span = $_;
  my $mtt;
  my $distance = 0;
  my (@non_word_tokens);
  foreach my $span (@$tokens) {
    my $from = $span->{'-from'};
    my $to = $span->{'-to'};

    # Get the subring from primary data
    my $token = $doc->primary->data($from, $to);

    # Token is undefined
    unless (defined $token) {
      $self->log->error("Unable to find substring [$from-$to] in $path");
      next;
    };

    # This token should be recognized
    $should++;

    # Ignore non-word and non-number tokens (sorry!)
    if ($token !~ /[\w\d]/) {

      # TODO: Recognize punctuations!
      #	if ($mtt) {
      #	  my $term = [$token, $from, $to];
      #	  $mtt->add(
      #	    term => '.>:'.$token,
      #	    payload => '<i>'.$from . '<i>' . $to . '<b>' . $distance++
      #	  );
      #	  push(@non_word_tokens, $term);
      #	}
      next;
    };

    # Get a new MultiTermToken
    $mtt = $mtts->add;

    #      while (scalar @non_word_tokens) {
    #	local $_ = shift @non_word_tokens;
    #	$mtt->add(
    #	  term => '.<:' . $_->[0],
    #	  payload => '<i>' . $_->[1] . '<i>' . $_->[2] . '<b>' . --$distance
    #	);
    #	$distance = 0;
    #      };

    # Add gap for later finding matching positions before or after
    # Have here is the last valid position
    $range->gap($old, $from, $have) unless $old >= $from;

    # Add surface term
    # That's always the first term!
    $mtt->add('s:' . $token);

    # Add case insensitive term
    $mtt->add('i:' . lc $token);

    # Add offset information
    $mtt->o_start($from);
    $mtt->o_end($to);

    # Store offset information for position matching
    $range->set($from, $to, $have);
    $match->set($from, $to, $have);

    $old = $to + 1;

    # Add position term
    $mtt->add(
      term => '_' . $have,
      o_start => $mtt->o_start,
      o_end => $mtt->o_end
    );

    $have++;
  };

  # Add token count
  $mtts->add_meta('tokens', '<i>' . $have);

  # Add text boundary
  $mtts->pos(0)->add(
    term => '<>:base/s:t',
    o_start => 0,
    p_end => ($have - 1),
    o_end => $doc->primary->data_length,
    payload => '<b>0',
    pti => 64
  );

  # Create a gap for the 
  if ($doc->primary->data_length >= ($old - 1)) {
    $range->gap($old, $doc->primary->data_length + 1, $have-1)
  };

  # Add info
  $self->stream($mtts);
  $self->{range} = $range;
  $self->{match} = $match;
  $self->should($should);
  $self->have($have);

  $self->log->debug('With a non-word quota of ' . _perc($self->should, $self->should - $self->have) . ' %');

  return $self;
};


# This is now done by glemm
sub add_subtokens {
  my $self = shift;
  my $mtts = $self->stream or return;

  foreach my $mtt (@{$mtts->multi_term_tokens}) {
    my $o_start = $mtt->o_start;
    my $o_end = $mtt->o_end;
    my $l = $o_end - $o_start;

    my $os = my $s = $mtt->lc_surface;

    # Algorithm based on aggressive tokenization in
    # tokenize.pl from Carsten Schnober
    $s =~ s/[[:alpha:]]/a/g;
    $s =~ s/[[:digit:]]/0/g;
    $s =~ s/\p{Punct}/#/g;
    $s =~ y/~/A/;
    $s .= 'E';

    while ($s =~ /(a+)[^a]/g) {
      my $from = $-[1];
      my $to = $+[1];
      $mtt->add(
	term => 'i^1:' . substr($os, $from, $from + $to),
	o_start => $from + $o_start,
	o_end => $to + $o_start
      ) unless $to - $from == $l;
    };
    while ($s =~ /(0+)[^0]/g) {
      my $from = $-[1];
      my $to = $+[1];
      $mtt->add(
	term => 'i^2:' . substr($os, $from, $from + $to),
	o_start => $from + $o_start,
	o_end => $to + $o_start
      ) unless $to - $from == $l;
    };
    while ($s =~ /(#)/g) {
      my $from = $-[1];
      my $to = $+[1];
      $mtt->add(
	term => 'i^3:' . substr($os, $from, $from + $to),
	o_start => $from + $o_start,
	o_end => $to + $o_start
      ) unless $to - $from == $l;
    };
  };

  return $self;
};


# Get span positions through character offsets
sub range {
  return shift->{range} // KorAP::XML::Tokenizer::Range->new;
};


# Get token positions through character offsets
sub match {
  return shift->{match} // KorAP::XML::Tokenizer::Match->new;
};


# Add information of spans to the tokens
sub add_spandata {
  my $self = shift;
  my %param = @_;

  unless ($self->stream) {
    $self->log->warn(
      'No token data available'
    );
    return;
  };

  $self->log->trace(
    ($param{skip} ? 'Skip' : 'Add').' span data '.$param{foundry}.':'.$param{layer}
  );

  return if $param{skip};

  my $cb = delete $param{cb};

  $param{primary} = $self->doc->primary;

  # Todo: Match and range may be part of stream!
  my $spans = KorAP::XML::Tokenizer::Spans->new(
    path => $self->path,
    range => $self->range,
    match => $self->match,
    stream => $self->stream,
    %param
  );

  my $spanarray = $spans->parse or return;

  if ($self->log->is_debug) {
    if ($spans->should == $spans->have) {
      $self->log->trace('With perfect alignment!');
    }
    else {
      $self->log->debug('With an alignment quota of ' . _perc($spans->should, $spans->have) . ' %');
    };
  };

  if ($cb) {
    foreach (@$spanarray) {
      $cb->($self->stream, $_) if defined $_->p_start;
    };
    return 1;
  };
  return $spans;
};

# Add information to the tokens
sub add_tokendata {
  my $self = shift;
  my %param = @_;

  unless ($self->stream) {
    $self->log->warn(
      'No token data available'
    );
    return;
  };

  $self->log->trace(
    ($param{skip} ? 'Skip' : 'Add').' token data '.$param{foundry}.':'.$param{layer}
  );
  return if $param{skip};

  my $cb = delete $param{cb};

  $param{primary} = $self->doc->primary;

  my $tokens = KorAP::XML::Tokenizer::Tokens->new(
    path => $self->path,
    range => $self->range,
    match => $self->match,
    stream => $self->stream,
    %param
  );

  my $tokenarray = $tokens->parse or return;

  # Output some debug information
  # on token alignment
  if ($self->log->is_debug) {
    if ($tokens->should == $tokens->have) {
      $self->log->trace('With perfect alignment!');
    }
    else {
      my $perc = _perc(
	$tokens->should, $tokens->have, $self->should, $self->should - $self->have
      );
      $self->log->debug('With an alignment quota of ' . $perc);
    };
  };

  # There is a callback defined!
  if ($cb) {
    foreach (@$tokenarray) {
      # weaken $tokens;
      $cb->($self->stream, $_, $tokens) if defined $_->pos;
      #, $tokens);
    };
    return 1;
  };
  return $tokens;
};


# Add Foundry#Layer annotation
sub add {
  my $self = shift;
  my $foundry = shift;
  my $layer = shift;

  unless ($foundry && $layer) {
    $self->log->warn('Unable to add specific module - not enough information given!');
    return;
  };

  my $mod = 'KorAP::XML::Annotation::' . $foundry . '::' . $layer;

  if ($mod->can('new') || eval("require $mod; 1;")) {
      my $obj = $mod->new($self);
      
      if (my $retval = $obj->parse(@_)) {

      # This layer is supported
      $self->support($foundry => $layer, @_);

      # Get layerinfo
      $self->layer_info($mod->layer_info);
      return $retval;
    }
    else {
      $self->log->debug('Unable to parse '.$mod);
    };
  }
  else {
    $self->log->warn('Unable to load '.$mod . '(' . $@ . ')');
  };

  return;
};


sub _perc {
  if (@_ == 2) {
    # '[' . $_[0] . '/' . $_[1] . ']' .
    return sprintf("%.2f", ($_[1] * 100) / $_[0]);
  }

  my $a_should = shift;
  my $a_have   = shift;
  my $b_should = shift;
  my $b_have   = shift;
  my $a_quota = ($a_have * 100) / $a_should;
  my $b_quota = ($b_have * 100) / $b_should;
  return sprintf("%.2f", $a_quota) . '%' .
    ((($a_quota + $b_quota) <= 100) ?
       ' [' . sprintf("%.2f", $a_quota + $b_quota) . '%]' : '');
};


sub support {
  my $self = shift;

  # No setting - just getting
  unless ($_[0]) {
    my @supports;

    # Get all foundries
    foreach my $foundry (keys %{$self->{support}}) {
      push(@supports, $foundry);

      # Get all layers
      foreach my $layer (@{$self->{support}->{$foundry}}) {
	  my @layers = @$layer;
	  push(@supports, $foundry . '/' . $layers[0]);

	  # More information
	  if ($layers[1]) {
	      push(@supports, $foundry . '/' . join('/', @layers));
	  };
      };
    };
    return lc ( join ' ', sort {$a cmp $b } @supports );
  }
  elsif (!$_[1]) {
    return $self->{support}->{$_[0]} // []
  };
  my $f = lc shift;
  my $l = lc shift;
  my @info = @_;
  $self->{support} //= {};
  $self->{support}->{$f} //= [];
  push(@{$self->{support}->{$f}}, [$l, @info]);
};


sub layer_info {
    my $self = shift;
    $self->{layer_info} //= [];
    if ($_[0]) {
	push(@{$self->{layer_info}}, @{$_[0]});
    }
    else {
	return join ' ', sort {$a cmp $b } uniq @{$self->{layer_info}};
    };
};


sub to_string {
  my $self = shift;
  my $primary = defined $_[0] ? $_[0] : 1;
  my $string = "<meta>\n";
  $string .= $self->doc->to_string;
  $string .= "</meta>\n";
  if ($primary) {
    $string .= "<text>\n";
    $string .= $self->doc->primary->data . "\n";
    $string .= "</text>\n";
  };
  $string .= '<field name="' . $self->name . "\">\n";
  $string .= "<info>\n";
  $string .= 'tokenization = ' . $self->foundry . '#' . $self->layer . "\n";

  # There is support info
  if (my $support = $self->support) {
    $string .= 'support = ' . $support . "\n";
  };
  if (my $layer_info = $self->layer_info) {
    $string .= 'layer_info = ' . $layer_info . "\n";
  };

  $string .= "</info>\n";
  $string .= $self->stream->to_string;
  $string .= "</field>";
  return $string;
};

sub to_data {
  my $self = shift;
  my $primary = defined $_[0] ? $_[0] : 1;
  my $legacy  = defined $_[1] ? $_[1] : 0;

  my %data = %{$self->doc->to_hash};
  my @fields;

  if ($legacy) {
    push(@fields, { primaryData => $self->doc->primary->data }) if $primary;

    push(@fields, {
      name => $self->name,
      data => $self->stream->to_array,
      tokenization => lc($self->foundry) . '#' . lc($self->layer),
      foundries => $self->support,
      layerInfo => $self->layer_info
    });

    $data{fields} = \@fields;
  }

  else {
    my $tokens = $self->to_hash;

    $tokens->{text} = $self->doc->primary->data if $primary;
    $data{data} = $tokens;
    $data{version} = '0.03';
  };

  \%data;
};

sub to_hash {
  my $self = shift;
  return {
    name => $self->name,
    stream => $self->stream->to_array,
    tokenSource => lc($self->foundry) . '#' . lc($self->layer),
    foundries => $self->support,
    layerInfos => $self->layer_info
  }
};


sub to_json_legacy {
  encode_json($_[0]->to_data($_[1], 1));
};

sub to_json {
  encode_json($_[0]->to_data($_[1], 0));
};


sub to_pretty_json {
  JSON::XS->new->pretty->encode($_[0]->to_data($_[1]));
};


1;


__END__

=pod

=head1 NAME

KorAP::XML::Tokenizer

=head1 SYNOPSIS

  my $tokens = KorAP::XML::Tokenizer->new(
    path    => '../examples/00003',
    doc     => KorAP::XML::Krill->new( ... ),
    foundry => 'opennlp',
    layer   => 'tokens'
  );

  $tokens->parse;

=head1 DESCRIPTION

Convert token information from the KorAP XML
format into Lucene Index compatible token streams.

=head1 ATTRIBUTES

=head2 path

  print $tokens->path;

The path of the document.


=head2 foundry

  print $tokens->foundry;

The name of the foundry.

=head2 should

Number of tokens that exist at all.

=head2 have

Number of tokens effectively stored in the token stream (e.g., no punctuations).

=head2 layer

  print $tokens->layer;

The name of the tokens layer.


=head2 doc

  print $tokens->doc->corpus_id;

The L<KorAP::XML::Krill> object.


=head2 stream

  $tokens->stream->add_meta('adjCount', '<i>45');

The L<KorAP::XML::Index::MultiTermTokenStream> object


=head2 range

  $tokens->range->lookup(45);

The L<KorAP::XML::Tokenizer::Range> object for converting span offsets to positions.

=head2 match

  $tokens->match->lookup(45);

The L<KorAP::XML::Tokenizer::Match> object for converting token offsets to positions.


=head1 METHODS

=head2 parse

  $tokens->parse;

Start the tokenization process.


=head2 to_json_legacy

  print $tokens->to_json_legacy;
  print $tokens->to_json_legacy(1);

Return the token data in legacy JSON format.
An optional parsed boolean parameter indicates,
if primary data should be included.

=head2 to_json

  print $tokens->to_json;
  print $tokens->to_json(1);

Return the token data in JSON format
An optional parsed boolean parameter indicates,
if primary data should be included.


=head2 add_subtokens

  $tokens->split_tokens;
  $tokens->split_tokens(
    sub {
       ...
    }
  );

Add sub token information to the index.
This is based on the C<aggressive> tokenization, written by Carsten Schnober.


=head2 add_spandata

  $tokens->add_spandata(
    foundry => 'base',
    layer => 'sentences',
    cb => sub {
      my ($stream, $span) = @_;
      my $mtt = $stream->pos($span->p_start);
      $mtt->add(
	term    => '<>:s',
	o_start => $span->o_start,
	o_end   => $span->o_end,
	p_end   => $span->p_end
      );
    }
  );

Add span information to the parsed token stream.
Expects a C<foundry> name, a C<layer> name and a
callback parameter, that will be called after each parsed
span. The L<KorAP::XML::Index::MultiTermTokenStream> object will be passed,
as well as the current L<KorAP::XML::Tokenizer::Span>.

An optional parameter C<encoding> may indicate that the span offsets
are either refering to C<bytes> or C<utf-8> offsets.

An optional parameter C<skip> allows for skipping the process.


=head2 add_tokendata

  $tokens->add_tokendata(
    foundry => 'connexor',
    layer => 'syntax',
    cb => sub {
      my ($stream, $token) = @_;
      my $mtt = $stream->pos($token->pos);
      my $content = $token->content;

      # syntax
      if ((my $found = $content->at('f[name="pos"]')) && ($found = $found->text)) {
	$mtt->add(
	  term => 'cnx_syn:' . $found
	);
      };
    });

Add token information to the parsed token stream.
Expects a C<foundry> name, a C<layer> name and a
callback parameter, that will be called after each parsed
token. The L<KorAP::XML::Index::MultiTermTokenStream> object will be passed,
as well as the current L<KorAP::XML::Tokenizer::Span>.

An optional parameter C<encoding> may indicate that the token offsets
are either refering to C<bytes> or C<utf-8> offsets.

An optional parameter C<skip> allows for skipping the process.

=cut
