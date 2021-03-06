package CXGN::Tools::Wget;

use strict;
use warnings;
use Carp::Clan qr/^CXGN::Tools::Wget/;

use File::Copy;
use File::Temp qw/tempfile/;
use File::Flock;
use Digest::MD5 qw/ md5_hex /;
use URI;

use CXGN::Tools::List qw/ all str_in /;
use CXGN::Tools::File qw/ is_filehandle /;

=head1 NAME

CXGN::Tools::Wget - contains functions for getting files via http
or ftp in ways that aren't directly supported by L<LWP>.

=head1 SYNOPSIS

  use CXGN::Tools::Wget qw/wget_filter/;

  #get a gzipped file from a remote site, gunzipping it as it comes in
  #and putting in somewhere else
  wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
               { gunzip => 1 },
             );

  #get the same file, but transform each line as it comes in with the given
  #subroutine, because they really mean bonobos, not monkeys
  wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
               sub {
                 my $line = shift;
                 $line =~ s/\s+monkey/ bonobo/;
                 return $line;
               },
               { gunzip => 1 },
             );

  # get a cxgn-resource file defined in public.resource_file
  wget_filter( cxgn-resource://all_tomato_repeats => 'myrepeats.seq');
  OR
  my $temp_repeats_file = wget_filter( 'cxgn-resource://all_tomato_repeats' );

=head1 CXGN-RESOURCE URLS

Sometimes we have a need for making datasets out of several other
datasets.  For example, say you wanted a combined set of sequences
composed of NCBI's NR dataset, SGN's ESTs, and some random thing from
MIPS.  You could define a resource file like:

  insert into public.resource_file (name,expression)
  values ('robs_composite_set','cat( gunzip(ftp://ftp.ncbi.nlm.nih.gov/nr.gz), ftp://ftp.sgn.cornell.edu/ests/Tomato_current.seq.gz, http://mips.gsf.de/some_random_set.fasta )');

Then, when you go

  my $file = wget_filter('cxgn-resource://robs_composite_set');

You will get the concatenation of the unzipped NR set, the SGN est
set, and the MIPs set.  What actually happens behind the scenes is,
wget downloads each of the files, gunzips the nr file, then
concatenates the three into another file and caches it, then copies
the cached copy into another tempfile, whose name it returns to you.

But you didn't have to know that.  All you have to know is, define a
resource in the resource_file table, and wget_filter will build it for
you when you ask for it by wgetting a URL with the cxgn-resource
protocol.

=head1 CXGN-WGET URLS

Just like cxgn-resource URLs, except the resource expression is right
in the URL.  Example:

  cxgn-wget://cat( http://google.com, 

=head1 FUNCTIONS

All functions are @EXPORT_OK.

=cut

BEGIN { our @EXPORT_OK = qw/   wget_filter clear_cache / }

our @EXPORT_OK;
use base 'Exporter';



=head2 wget_filter

  Usage: wget_filter( http://example.com/myfile.txt => 'somelocalfile.txt');
  Desc : get a remote file, optionally gunzipping it,
         and/or running some subroutines on each line as it
         comes in.
  Ret  : filename where the output was written, which
         is either the destination file you provided,
         or a tempfile if you did not provide a destination
         file
  Args : (url of file,
          optional destination filename or filehandle,
          optional list of filters to run on each line,
          optional hashref of behavior options, as:
            { gunzip => 1, #< gunzip the downloaded file before returning it.  default false.
              cache  => 1, #< enable/disable persistent caching.  default enabled
              max_age => 3*24*60*60 (3 days), #< if caching maximum age of cached copy in seconds
              unlink => 1, #< enable/disable automatic deletion of the
                           #temp file made and returned to you.  only
                           #relevant if no destination filename is
                           #provided
              test_only => 0, #if true, only download the first few
                              #bytes of each of the components of the
                              #resource, to check if everything looks OK
            },
         )
  Side Effects: dies on error
  Example:
     #get the same file, but transform each line as it comes in with the given
     #subroutine, because they really mean bonobos, not monkeys
     wget_filter( http://example.com/myfile.gz => '/tmp/somelocalfile.txt',
                  sub {
                    my $line = shift;
                    $line =~ s/\s+monkey/ bonobo/;
                    return $line;
                  },
                  { gunzip => 1 },
                );
     # get a composite resource file defined in the public.resource_file
     # table
     wget_filter( cxgn-resource://test => '/tmp/mytestfile.html' );

=cut

use constant DEFAULT_CACHE_MAX_AGE => 3*24*60*60; #< 3 days ago, in seconds

sub wget_filter {
  my ($url,@args) = @_;

  #get our options hash if present
  my %options = (ref($args[-1]) eq 'HASH') ? %{pop @args} : ();

  $options{cache}  = 1 unless exists $options{cache};
  $options{unlink} = 1 unless exists $options{unlink};

  $options{cache} = 0 if $options{test_only};

  my $destfile = do {
    if( !$args[0] || ref $args[0]) {
      my (undef,$f) = tempfile( File::Spec->catfile( __PACKAGE__->temp_root_dir(), 'cxgn-tools-wget-XXXXXX'), UNLINK => $options{unlink});
      #      cluck "made tempfile $f\n";
      $f
    } else {
      shift @args
    }
  };

  #and the rest of the arguments must be our filters
  my @filters = @args;
  !@filters || all map ref $_ eq 'CODE', @filters
    or confess "all filters must be subroutine refs or anonymous subs (".join(',',@filters).")";

  my $do_actual_fetch = sub {
      _wget_filter({ filters  => \@filters,
                     destfile => $destfile,
                     url      => $url,
                     options  => \%options,
                   })
  };

  # if we are filtering, just do the fetch without caching
  return $do_actual_fetch->() if @filters || !$options{cache};

  # otherwise, we are caching, and we need to do locking

  # only do caching if we don't have any filters (we can't represent
  # these in a persistent way in a hash key, because the CODE(...)
  # will be different at every program run
  my $cache_key = $url.' WITH OPTIONS '.join('=>',%options);
  my $cache_filename = cache_filename( $cache_key );
  my $lock_filename = "$cache_filename.lock";
  my $try_read_lock  = sub { File::Flock->new( $lock_filename, 'shared', 'nonblocking' ) };
  my $try_write_lock = sub { File::Flock->new( $lock_filename,  undef,   'nonblocking' ) };

  my $cache_file_looks_valid = sub {
      -r $cache_filename
      && (time-(stat($cache_filename))[9]) <= ($options{max_age} || DEFAULT_CACHE_MAX_AGE)
  };

  my $copy_from_cache = sub {
      my $gunzip_error = system qq!gunzip -c '$cache_filename' > '$destfile'!;
      return 0 if $gunzip_error;
      return 1;
  };

  my $read_cache = sub {
      my $read_lock;
      sleep 1 until $read_lock = $try_read_lock->();
      return $destfile if $cache_file_looks_valid->() && $copy_from_cache->();
      return;
  };

  # OK, the cache file needs updating or is corrupt, so try to get an
  # exclusive write lock
  my $dest_from_cache;
  until ( $dest_from_cache = $read_cache->() ) {
      if( my $write_lock = $try_write_lock->() ) {
          $do_actual_fetch->();

          # write the destfile into the cache
          system qq!gzip -c '$destfile' > '$cache_filename'!
              and confess "$! writing downloaded file to CXGN::Tools::Wget persistent cache (gzip $destfile -> $cache_filename.gz)";

          return $destfile;

      }
  }

  return $dest_from_cache;

}

# the get, minus caching
sub _wget_filter {
    my $args = shift;
    my %options = %{$args->{options}};
    my $url = $args->{url};
    my $destfile = $args->{destfile} or die 'pass destfile stupid';
    my @filters = @{ $args->{filters} };

    #properly form the gunzip command
    $options{gunzip} = $options{gunzip} ? ' gunzip -c |' : '';

    my $parsed_url = URI->new($url)
        or croak "could not parse uri '$url'";

    if ( str_in( $parsed_url->scheme, qw/ file http ftp / ) ) {

        #try to use ncftpget for fetching from ftp with no wildcards, since
        #wget suffers from some kind of bug with large ftp transfers.
        #use wget for everything else, since it's a little more flexible
        my $fetchcommand =
            $parsed_url->scheme eq 'file'                      ? 'cat'           :
            $parsed_url->scheme eq 'ftp' && $url !~ /[\*\?]/   ? "ncftpget -cV"  :
                                                                 "wget -q -O -"  ;


        $url = $parsed_url->path if $parsed_url->scheme eq 'file';

        #check that all of the given filters are code refs
        @filters = grep {$_} @filters; #just ignore false things in the filters
        foreach (@filters) {
            ref eq 'CODE' or croak "Invalid filter argument '$_', must be a code ref";
        }

        #open the output filehandle if our argument isn't already a filehandle
        my $out_fh;
        my $open_out = ! is_filehandle($destfile);
        if ($open_out) {
            open $out_fh, '>', $destfile
                or croak "Could not write to destination file $destfile: $!";
        } else {
            $out_fh = $destfile;
        }

        my $testhead = $options{test_only} ?  'head -c 30 |' : '';
        #warn "testhead is $testhead\n";

        #run wget to download the file
        open my $urlpipe,"cd /tmp; $fetchcommand '$url' |$options{gunzip}$testhead"
            or croak "Could not use wget to fetch $url: $!";
        while (my $line = <$urlpipe>) {
            #if we were given filters, run them on it
            foreach my $filter (@filters) {
                $line = $filter->($line);
            }
            print $out_fh $line;
        }
        close $urlpipe;

        #close the output filehandle if it was us who opened it
        close $out_fh if $open_out;
        (stat($destfile))[7] > 0 || croak "Could not download $url using command '$fetchcommand'";
        #  print "done.\n";
    }
    ### cxgn-resource urls
    elsif ( $parsed_url->scheme eq 'cxgn-resource' ) {
        require CXGN::Tools::Wget::ResourceFile;

        confess 'filters do not work with cxgn-resource urls' if @filters;

        #look for a resource with that name
        my $resource_name = $parsed_url->authority;

        my ( $resource_file, $multiple_resources ) =
            CXGN::Tools::Wget::ResourceFile->search(
                name => $resource_name,
             );

        $resource_file or croak "no cxgn-resource found with name '$resource_name'";
        $multiple_resources and croak "multiple cxgn-resource entries found with name '$resource_name'";

        if ( $options{test_only} ) {
            #warn "test fetch\n";
            $resource_file->test_fetch();
        } else {
            $resource_file->fetch($destfile);
        }
    }
    elsif ( $parsed_url->scheme eq 'cxgn-wget' ) {
        require CXGN::Tools::Wget::ResourceExpression;

        confess 'filters do not work with cxgn-wget urls' if @filters;
        ( my $expression = "$url" ) =~ s!cxgn-wget://!!;

        CXGN::Tools::Wget::ResourceExpression::fetch_expression( $expression, $destfile );

    } else {
        croak "unable to handle URIs with scheme '".($parsed_url->scheme || '')."', URI is '$url'";
    }
}


#given a url, return the full path to where it should be stored on the
#filesystem
sub cache_filename {
  my ($keystring) = @_;
  my $name = md5_hex($keystring);
  # md5sum the key to make a filename that is compact, does not need
  # escaping, and that is still unique
  return File::Spec->catfile(cache_root_dir(), "$name.gz");
}


=head2 temp_root_dir

  Usage: CXGN::Tools::Wget->temp_dir( $new_dir );
  Desc : class method to get/set the class-wide temp directory where
         the wget file cache and temporarily fetched files
         are kept
  Args : (optional) new directory to set.
         defaults to /tmp/cxgn-tools-wget-<username>
  Ret  : root directory where wget will keep its cache files
  Side Effects: sets a piece of class data

=cut

{
    my $cache_root;
    sub temp_root_dir {
        my ($class,$new_root) = @_;
        $cache_root = $new_root if defined $new_root;
        return $cache_root ||=  do {
            my $username = getpwuid $>;
            my $dir_name = File::Spec->catdir( File::Spec->tmpdir, "cxgn-tools-wget-$username" );
            system 'mkdir', -p => $dir_name;
            -w $dir_name or die "could not make and/or write to cache dir $dir_name\n";
            $dir_name
        };
    }
    sub cache_root_dir {
        my $c = File::Spec->catdir( temp_root_dir(), 'cxgn-tools-wget-cache' );
        -d $c or mkdir $c or die "$! making cache dir '$c'";
        $c
    }
}

=head2 clear_cache

  Usage: CXGN::Tools::Wget::clear_cache
  Desc : delete all the locally cached files managed by this module
  Args :
  Ret  :
  Side Effects:
  Example:

=cut

sub clear_cache {
  my ($class) = @_;
  my @delete_us = glob cache_root_dir().'/*';
  my $num_deleted = unlink @delete_us;
  unless ($num_deleted == @delete_us) {
    croak "could not delete all files in the cache root directory (".cache_root_dir().") : $!";
  }
}

=head2 vacuum_cache

  Usage: CXGN::Tools::Wget::vacuum_cache(1200)
  Desc : delete all cached files that are older than N seconds old
  Args : number of seconds old a file must be to be deleted
  Ret  : nothing meaningful
  Side Effects: dies on error

=cut

sub vacuum_cache {
  my ($max_age) = @_;
  my @delete_us = grep { (stat $_)[9] < time-$max_age }
                  glob cache_root_dir().'/*';

  unlink @delete_us == scalar @delete_us
    or croak "could not vacuum files in the cache root directory (".cache_root_dir().") : $!";
}

1;

