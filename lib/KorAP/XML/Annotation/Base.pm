package KorAP::XML::Annotation::Base;
use strict;
use warnings;
use feature ':5.10';

# Importing method
sub import {
  my $class = shift;
  my $caller = caller;

  no strict 'refs';

  push @{"${caller}::ISA"}, $class;

  strict->import;
  warnings->import;
  utf8->import;
  feature->import(':5.10');
};


# Constructor
sub new {
  my ($class, $tokens) = @_;
  bless \$tokens, $class;
};

# Basic layer info
sub layer_info {
  []
};

1;

__END__

=pod

=head1 KorAP::XML::Annotation::Base
