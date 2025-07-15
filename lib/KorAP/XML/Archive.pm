package KorAP::XML::Archive;
use Carp qw/carp/;
use Mojo::Util qw/quote/;
use List::Util qw/uniq/;
use File::Spec::Functions qw(rel2abs);
use strict;
use warnings;

our $RIPUNZIP_AVAILABLE;

# Construct new archive helper
sub new {
  my $class = shift;
  my @file;

  foreach (@_) {
    my $file = _file_to_array($_) or return;
    push(@file, $file);
  };

  return unless @file;

  bless \@file, $class;
};


# Check if classic Info-ZIP unzip is installed
sub test_InfoZIP_unzip {
  return 1 if grep { -x "$_/unzip"} split /:/, $ENV{PATH};
  return;
};

# Check if ripunzip is installed
sub test_ripunzip {

  if (!defined $RIPUNZIP_AVAILABLE) {
    $RIPUNZIP_AVAILABLE = grep { -x "$_/ripunzip" } split /:/, $ENV{PATH};
  }
  return $RIPUNZIP_AVAILABLE;
}

# Check if unzip is installed (ripunzip can be used only for some tasks)
sub test_unzip {
  test_ripunzip();
  return test_InfoZIP_unzip();
};


# Check the compressed archive
sub test {
  my $self = shift;
  foreach (@$self) {
    my $x = $_->[0];
    my $out = `unzip -t $x`;
    if ($out !~ /no errors/i) {
      return 0;
    };
  };
  return 1;
};


# List all text paths contained in the file
sub list_texts {
  my $self = shift;
  my @texts;
  my $file = $self->[0]->[0];
  foreach (`unzip -l -UU -qq $file "*/data.xml"`) {
    if (m![\t\s]
          ((?:\./)?
            [^\s\t/\.]+?/ # Corpus
            [^\/]+?/   # Document
            [^/]+?    # Text
          )/data\.xml$!x) {
      push @texts, $1;
    };
  };
  return @texts;
};

# Create an iterator for text paths
sub list_texts_iterator {
  my $self = shift;
  my $file = $self->[0]->[0];
  
  # Open pipe to unzip command
  open(my $unzip, "unzip -l -UU -qq $file \"*/data.xml\" |") 
    or die "Failed to run unzip: $!";
  
  return sub {
    while (my $line = <$unzip>) {
      if ($line =~ m![\t\s]
            ((?:\./)?
              [^\s\t/\.]+?/ # Corpus
              [^\/]+?/   # Document
              [^/]+?    # Text
            )/data\.xml$!x) {
        return $1;  # Return next path
      }
    }
    close($unzip);
    return undef;  # No more paths
  };
}

# Get count of texts without storing paths
sub count_texts {
  my $self = shift;
  my $count = 0;
  my $iter = $self->list_texts_iterator;
  while (defined(my $path = $iter->())) {
    $count++;
  }
  return $count;
};


# Check, if the archive has a prefix
sub check_prefix {
  my $self = shift;
  my $nr = shift // 0;
  my $file = $self->[$nr]->[0];
  my ($header) = `unzip -l -UU -qq $file "*/header.xml"`;
  return ($header && $header =~ m![\s\t]\.[/\\]!) ? 1 : 0;
};


# Split a text path to prefix, corpus, document, text
sub split_path {
  my $self = shift;
  my $text_path = shift;

  unless ($text_path) {
    carp('No text path given');
    return 0;
  };

  # Check for '.' prefix in text
  my $prefix = '';
  if ($text_path =~ s!^\./!!) {
    $prefix = '.';
  };

  # Unix form
  if ($text_path =~ m!^([^/]+?)/([^/]+?)[\\/]([^/]+?)$!) {
    return ($prefix, $1, $2, $3);
  }

  # Windows form
  elsif ($text_path =~ m!^([^\\]+?)\\([^\\]+?)[\\/]([^\\]+?)$!) {
    return ($prefix, $1, $2, $3);
  };

  # Text has not the expected pattern
  carp $text_path . ' is not a well-formed text path in ' . $self->[0]->[0];
  return;
};


# Get the archives path
# Deprecated
sub path {
  my $self = shift;
  my $archive = shift // 0;
  return rel2abs($self->[$archive]->[0]);
};


# Attach another archive
sub attach {
  my $self = shift;
  my $file = _file_to_array(shift()) or return;
  push @$self, $file;
  return 1;
};


# Check attached file for prefix negation
sub _file_to_array {
  my $file = shift;
  my $prefix = 1;

  # Should the archive support prefixes
  if (index($file, '#') == 0) {
    $file = substr($file, 1);
    $prefix = 0;
  };

  # The archive is a valid file
  if (-e $file) {
    return [$file, $prefix]
  };
};


sub extract_all {
  my $self = shift;
  my ($quiet, $target_dir, $jobs) = @_;

  my @init_cmd = (test_ripunzip() ?
    # Use ripunzip program
    ('ripunzip', 'unzip-file', '-q', '-d', $target_dir)
    :
    # Use InfoZIP unzip program
    ('unzip', '-qo', '-uo', '-d', $target_dir)
  );

  # Iterate over all attached archives
  my @cmds;
  foreach my $archive (@$self) {

    # $_ is the zip
    my @cmd = @init_cmd;
    push(@cmd, $archive->[0]); # Extract from zip

    # Run system call
    push @cmds, \@cmd;
  };

  $self->_extract($quiet, $jobs, @cmds);
};


sub _extract {
  my ($self, $quiet, $jobs, @cmds) = @_;

  # Only single call
  if (!$jobs || $jobs == 1) {
    foreach (@cmds) {

      system(@$_);

      # Check for return code
      my $code = $?;

      unless ($quiet) {
        print "Extract" .
          ($code ? " $code" : '') . " " . join(' ', @$_) . "\n";
      };
    };
  }

  # Extract annotations in parallel
  else {
    my $pool = Parallel::ForkManager->new($jobs);
    $pool->run_on_finish(
      sub {
        my ($pid, $code) = @_;
        my $data = pop;
        unless ($quiet) {
          print "Extract [\$$pid] " .
            ($code ? " $code" : '') . " $$data\n";
        };
      }
    );

  ARCHIVE_LOOP:
    foreach my $cmd (@cmds) {
      my $pid = $pool->start and next ARCHIVE_LOOP;
      system(@$cmd);
      my $code = $?;
      my $last = $cmd->[4];
      $pool->finish($code, \"$last");
    };
    $pool->wait_all_children;
  };

  # Fine
  return 1;
};



# Extract from sigle
sub extract_sigle {
  my ($self, $quiet, $sigle, $target_dir, $jobs) = @_;
  my @cmds = $self->cmds_from_sigle($sigle);

  @cmds = map {
    push @{$_}, '-d', $target_dir;
    $_;
  } @cmds;

  return $self->_extract($quiet, $jobs, @cmds);
};


# Create commands for sigle
sub cmds_from_sigle {
  my ($self, $sigle) = @_;

  my $first = 1;

  my @init_cmd = (
    'unzip',          # Use unzip program
    '-qo',            # quietly overwrite all existing files
    '-uo',
  );

  my @cmds;

  # Iterate over all attached archives
  for  (my $i = 0; $i < @$self; $i++) {
    my $archive = $self->[$i];
    my $prefix_check = 0;
    my $prefix = 0;

    # $_ is the zip
    my @cmd = @init_cmd;
    push(@cmd, $archive->[0]); # Extract from zip

    foreach (@$sigle) {
      my ($corpus,$doc,$text) = split '/', $_;

      # Add some interesting files for extraction
      # Can't use catfile(), as this removes the '.' prefix
      my @breadcrumbs = ($corpus);

      # If the prefix is not forbidden - prefix!
      unless ($prefix_check) {
        $prefix = $self->check_prefix($i);
        $prefix_check = 1;
      };

      unshift @breadcrumbs, '.' if $prefix;

      if ($first) {

        # Only extract from first file
        push(@cmd, join('/', @breadcrumbs, 'header.xml'));
        push(@cmd, join('/', @breadcrumbs, $doc, 'header.xml'));
      };

      # With wildcard on doc level
      if (index($doc, '*') > 0) {
        push @breadcrumbs, $doc;
      }

      # For full-defined doc sigle
      elsif (!$text) {
        push @breadcrumbs, $doc, '*';
      }

      # For text sigle
      else {
        push @breadcrumbs, $doc, $text, '*';
      }

      # Add to command
      push(@cmd, join('/', @breadcrumbs));
    };

    # Add to commands
    push @cmds, [uniq @cmd];

    $first = 0;
  };

  return @cmds;
};

1;


__END__

=POD

C<KorAP::XML::Archive> expects the unzip tool to be installed.


=head1 new

=head1 test

=head1 attach

=head1 check_prefix

=head1 list_texts

Returns all texts found in the zip file

=head1 extract_text

  $archive->extract_text('./GOE/AGU/0004', '~/temp');

Extract all files for the named text to a certain directory.
