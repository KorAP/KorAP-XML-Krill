package KorAP::XML::Annotation::XIP::Constituency;
use KorAP::XML::Annotation::Base;
use Set::Scalar;
use Scalar::Util qw/weaken/;

our $URI_RE = qr/^[^\#]+\#(.+?)$/;

sub parse {
  my $self = shift;

  # Collect all spans
  my %xip_const = ();

  # Collect all roots
  my $xip_const_root = Set::Scalar->new;

  # Collect all non-roots
  my $xip_const_noroot = Set::Scalar->new;

  # First run:
  $$self->add_spandata(
    foundry => 'xip',
    layer => 'constituency',
    encoding => 'xip',
    cb => sub {
      my ($stream, $span) = @_;

      # Collect the span
      $xip_const{$span->id} = $span;
      # warn 'Remember ' . $span->id;

      # It's probably a root
      $xip_const_root->insert($span->id);

      my $rel = $span->hash->{rel} or return;

      $rel = [$rel] unless ref $rel eq 'ARRAY';

      # Iterate over all relations
      foreach (@$rel) {
        next if $_->{-label} ne 'dominates';

        my $target = $_->{-target};
        if (!$target && $_->{-uri} &&
              $_->{-uri} =~ $URI_RE)  {
          $target = $1;
        };

        # The target may not be addressable
        next unless $target;

        # It's definately not a root
        $xip_const_noroot->insert($target);

        # if ($target =~ /^s2_n(?:36|58|59|60|40)$/) {
        #   warn 'Probably not a root ' . $target . ' but ' . $span->id;
        # };
      };
    }
  ) or return;

  # Get the stream
  my $stream = $$self->stream;

  # Recursive tree traversal method
  my $add_const;
  $add_const = sub {
    my ($span, $level) = @_;

    weaken $xip_const_root;
    weaken $xip_const_noroot;

    # Get the correct position for the span
    my $mtt = $stream->pos($span->p_start);

    my $content = $span->hash;
    my $f = $content->{fs}->{f};

    unless ($f->{-name} eq 'const') {
      warn $f->{-id} . ' is no constant';
      return;
    };

    my $type = $f->{'#text'};

    unless ($type) {
      warn $f->{-id} . ' has no content';
      return;
    };

    # $type is now NPA, NP, NUM ...
    my %term = (
      term => '<>:xip/c:' . $type,
      o_start => $span->o_start,
      o_end => $span->o_end,
      p_end => $span->p_end,
      pti => 64
    );

    # Only add level payload if node != root
    $term{payload} ='<b>' . ($level // 0);

    $mtt->add(%term);

    # my $this = __SUB__
    my $this = $add_const;

    my $rel = $content->{rel};

    unless ($rel) {
      warn $f->{-id} . ' has no relation' if $f->{-id};
      return;
    };

    $rel = [$rel] unless ref $rel eq 'ARRAY';

    # Iterate over all relations (again ...)
    foreach (@$rel) {
      next if $_->{-label} ne 'dominates';

      my $target = $_->{-target};
      if (!$target && $_->{-uri} &&
            $_->{-uri} =~ $URI_RE)  {
        $target = $1;
      };

      # if ($span->id =~ /^s2_n(?:36|58|59|60|40)$/ && $target =~ /^s2_n(?:36|58|59|60|40)$/) {
      # warn 'B: ' . $span->id . ' points to ' . $target;
      # };

      next unless $target;

      my $subspan = delete $xip_const{$target};
      # warn "A-Forgot about $target: " . ($subspan ? 'yes' : 'no');

      unless ($subspan) {
        next;
      };
      #  warn "Span " . $target . " not found";

      $this->($subspan, $level + 1);
    };
  };

  # Calculate all roots
  my $roots = $xip_const_root->difference($xip_const_noroot);

  # Start tree traversal from the root
  foreach ($roots->members) {
    my $obj = delete $xip_const{$_};

    # warn "B-Forgot about $_: " . ($obj ? 'yes' : 'no');

    unless ($obj) {
      next;
    };

    $add_const->($obj, 0);
  };

  return 1;
};


# Layer info
sub layer_info {
  ['xip/c=spans']
};


1;
