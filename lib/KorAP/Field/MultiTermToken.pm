package KorAP::Field::MultiTermToken;
use KorAP::Field::MultiTerm;
use List::MoreUtils 'uniq';
use Carp qw/carp croak/;
use strict;
use warnings;

# This tries to be highly optimized - it's not supposed to be readable

sub new {
  bless [], shift;
};


sub add {
  my $self = shift;
  my $mt;
  unless (ref $_[0] eq 'MultiTerm') {
    if (@_ == 1) {
      $mt = KorAP::Field::MultiTerm->new(term => $_[0]);
    }
    else {
      $mt = KorAP::Field::MultiTerm->new(@_);
    };
  }
  else {
    $mt = $_[0];
  };
  $self->[0] //= [];
  push(@{$self->[0]}, $mt);
  $mt;
};

# 0 -> mt

# 1
sub o_start {
  if (defined $_[1]) {
    return $_[0]->[1] = $_[1];
  };
  $_[0]->[1];
};

# 2
sub o_end {
  if (defined $_[1]) {
    return $_[0]->[2] = $_[1];
  };
  $_[0]->[2];
};

# 3: Return a new term id
sub id_counter {
  $_[0]->[3] //= 1;
  return $_[0]->[3]++;
};

sub surface {
  substr($_[0]->[0]->[0]->term,2);
};

sub lc_surface {
  substr($_[0]->[0]->[1]->term,2);
};

sub to_array {
  my $self = shift;
  [uniq(map($_->to_string, sort _sort @{$self->[0]}))];
};


sub to_string {
  my $self = shift;
  my $string = '[(' . $self->o_start . '-'. $self->o_end . ')';
  $string .= join ('|', @{$self->to_array});
  $string .= ']';
  return $string;
};

# Get relation based positions
sub _rel_right_pos {

  # There are relation ids!

  # token to token - right token
  if ($_[0] =~ m/^<i>(\d+)<s>/o) {
    return ($1, $1);
  }

  # token/span to span - right token
  elsif ($_[0] =~ m/^<i>(\d+)<i>(\d+)<s>/o) {
    return ($1, $2);
  }

  # span to token - right token
  elsif ($_[0] =~ m/^<b>\d+<i>(\d+)<s>/o) {
    return ($1, $1);
  };
  carp 'Unknown relation format!';
  return (0,0);
};

# Sort spans, attributes and relations
sub _sort {

  # Both are no spans
  if (index($a->[5], '<>:') != 0 && index($b->[5], '<>:') != 0) {

    # Both are attributes
    # Order attributes by reference id
    if (index($a->[5], '@:') == 0 && index($b->[5], '@:') == 0) {
      my ($a_id) = ($a->[0] =~ m/^<s>(\d+)/);
      my ($b_id) = ($b->[0] =~ m/^<s>(\d+)/);
      if ($a_id > $b_id) {
	return 1;
      }
      elsif ($a_id < $b_id) {
	return -1;
      }
      else {
	return 1;
      };
    }

    # Both are relations
    elsif (
      (index($a->[5],'<:') == 0 || index($a->[5],'>:') == 0)  &&
      (index($b->[5], '<:') == 0 || index($b->[5],'>:') == 0)) {
      my $a_end = $a->[2] // 0;
      my $b_end = $b->[2] // 0;

      # left is p_end
      if ($a_end < $b_end) {
	return -1;
      }
      elsif ($a_end > $b_end) {
	return 1;
      }
      else {
	# Check for right positions
	(my $a_start, $a_end) = _rel_right_pos($a->[0]);
	(my $b_start, $b_end) = _rel_right_pos($b->[0]);
	if ($a_start < $b_start) {
	  return -1;
	}
	elsif ($a_start > $b_start) {
	  return 1;
	}
	elsif ($a_end < $b_end) {
	  return -1;
	}
	elsif ($a_end > $b_end) {
	  return 1;
	}
	else {
	  return 1;
	};
      };
    };

    # This has to be sorted alphabetically!
    return $a->[5] cmp $b->[5];
  }

  # Not identical
  elsif (index($a->[5], '<>:') != 0) {
    return $a->[5] cmp $b->[5];
  }
  # Not identical
  elsif (index($b->[5], '<>:') != 0) {
    return $a->[5] cmp $b->[5];
  }

  # Sort both spans
  else {
    if ($a->[2] < $b->[2]) {
      return -1;
    }
    elsif ($a->[2] > $b->[2]) {
      return 1;
    }

    # Check depth
    else {
      my ($a_depth) = ($a->[0] =~ m/^<b>(\d+)/);
      my ($b_depth) = ($b->[0] =~ m/^<b>(\d+)/);

      $a_depth //= 0;
      $b_depth //= 0;
      if ($a_depth < $b_depth) {
	return -1;
      }
      elsif ($a_depth > $b_depth) {
	return 1;
      }
      else {
	return 1;
      };
    };
  };
};


sub to_solr {
  my $self = shift;
  my @array = map { $_->to_solr(0) } @{$self->{mt}};
  $array[0]->{i} = 1;
  return \@array;
};


1;


__END__

[
  {
   "e":128,
   "i":22,
   "p":"DQ4KDQsODg8=",
   "s":123,
   "t":"one",
   "y":"word"
  },
  {
   "e":8,
   "i":1,
   "s":5,
   "t":"two",
   "y":"word"
  },
  {
   "e":22,
   "i":1,
   "s":20,
   "t":"three",
   "y":"foobar"
  }
 ]

