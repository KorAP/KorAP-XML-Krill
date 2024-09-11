package KorAP::XML::ForkPool;
use strict;
use warnings;
use Mojo::File;
use Parallel::ForkManager;
use v5.10;

# Construct a new fork pool
sub new {
  my $class = shift;
  my %param = @_;

  bless {
    jobs      => $param{jobs} // 0,
    iter      => 1,      # Current text in process
    overwrite => $param{overwrite},
    output    => $param{output},
    cache     => $param{cache}
  }, $class;
};


# Create new fork pool
sub _new_pool {
  my $self = shift;

  # Zero means: everything runs in the parent process
  my $pool = Parallel::ForkManager->new($self->{jobs});

  # Report per processed text
  $pool->run_on_finish(
    sub {
      my ($pid, $code) = @_;
      my $data = pop;

      print 'Convert [' . ($self->{jobs} > 0 ? "\$$pid:" : '') .
        ($self->{iter}++) . '/' . $self->{count} . ']';
      print ($code ? " $code" : '') . " $$data\n";
    }
  );

  return $pool;
};


# Iterate over a directory and process all documents
sub process_directory {
  my $self = shift;
  my $input = shift;

  my $pool = $self->_new_pool;

  print "Reading data ...\n";

  my @dirs;

  Mojo::File->new($input[0])
      ->list_tree({hidden => 0, dir => 0})
      ->grep(qr/\/data\.xml$/)
      ->each(
        sub {
          s/\/data\.xml$//;
          push @dirs, $_;
        }
      );

  $self->{count} = scalar @dirs;

 DIRECTORY_LOOP:
  for (my $i = 0; $i < $count; $i++) {

    unless ($self->{overwrite}) {
      my $filename = catfile(
        $output,
        get_file_name($dirs[$i]) . '.json' . ($gzip ? '.gz' : '')
      );

      if (-e $filename) {
        $iter++;
        print "Skip $filename\n";
        next;
      };
    };

    # Get the next fork
    my $pid = $pool->start and next DIRECTORY_LOOP;
    my $msg;
    $msg = write_file($dirs[$i]);
    $pool->finish(0, \$msg);
  };

  $pool->wait_all_children;

  # Delete cache file
  unlink($cache_file) if $cache_delete;
};


# Take an archive, uncompress and iterate over all texts
sub process_archive {
  my $self = shift;
  my $archive = shift;
  my @input = @_;

  unless ($archive->test_unzip) {
    print "Unzip is not installed or incompatible.\n\n";
    exit(1);
  };

  # Add further annotation archived
  $archive->attach($_) foreach @input;

  print "Start processing ...\n";

  my @dirs = $archive->list_texts;
  $self->{count} = scalar @dirs;

  # Creae new pool
  my $pool = $self->_new_pool;

 ARCHIVE_LOOP:
  for (my $i = 0; $i < $count; $i++) {

    # Split path information
    my ($prefix, $corpus, $doc, $text) = $archive->split_path($dirs[$i]);

    unless ($self->{overwrite}) {

      my $filename = catfile(
        $output,
        get_file_name(
          catfile($corpus, $doc, $text)
            . '.json' . ($gzip ? '.gz' : '')
          )
      );

      if (-e $filename) {
        $iter++;
        print "Skip $filename\n";
        next;
      };
    };

    # Get the next fork
    my $pid = $pool->start and next ARCHIVE_LOOP;

    # Create temporary file
    my $temp = File::Temp->newdir;

    my $msg;

    # Extract from archive
    if ($archive->extract($dirs[$i], $temp)) {

      # Create corpus directory
      my $input = catdir("$temp", $corpus);

      # Temporary directory
      my $dir = catdir($input, $doc, $text);

      # Write file
      $msg = write_file($dir);
      $temp = undef;
      $pool->finish(0, \$msg);
    }
    else {
      $temp = undef;
      $msg = "Unable to extract " . $dirs[$i] . "\n";
      $pool->finish(1, \$msg);
    };
  };

  $pool->wait_all_children;

  # Delete cache file
  unlink($cache_file) if $cache_delete;
};


1;
