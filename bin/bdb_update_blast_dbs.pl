#!/usr/bin/env perl

# NOTE: This script is deprecated. 
# The current version has bin moved to the sgn/ repo
# as bin/bdb_update_blast_dbs.pl


use strict;
use warnings;
use English;
use Carp;
#$Carp::Verbose = 1;
use FindBin;
use Getopt::Std;

#use Data::Dumper;

use File::Spec;
use File::Temp qw/tempfile/;

use CXGN::Tools::Wget qw/wget_filter/;
use CXGN::BlastDB;

sub usage {
  my $message = shift || '';
  $message = "Error: $message\n" if $message;

  my $file_bases = join '', sort map '    '.$_->file_base."\n", CXGN::BlastDB->retrieve_all;

  die <<EOU;
$message
Usage:

    Do not use this script. It is deprecated.
    Use cxgn/sgn/bin/bdb_update_blast_dbs.pl instead.

  $FindBin::Script [ options ] -d <path>

  Go over all the BLAST databases we keep in stock and update them if
  needed.  When run with just the -g option, goes over all the BLAST
  dbs listed in the sgn.blast_db table and updates them if needed,
  putting them under the top-level BLAST db path given with the -d
  option.

  Options:

  -d <path>     required.  path where all blast DB files are expected to go.

  -t <path>     path to put tempfiles.  must be writable.  Defaults to /tmp.

  -x   dry run, just print what you would update

  -f <db name>  force-update the DB with the given file base (e.g. 'genbank/nr')

   Current list of file_bases:
$file_bases
EOU
}

our %opt;
getopts('xt:d:f:',\%opt) or usage('invalid arguments');
$opt{t} ||= File::Spec->tmpdir;

#if a alternate blast dbs path was given, set it in the BlastDB
#object
$opt{d} or usage('-d option is required');
-d $opt{d} or usage("directory $opt{d} not found");
CXGN::BlastDB->dbpath($opt{d});

my @dbs = $opt{f} ? CXGN::BlastDB->search( file_base => $opt{f} ) 
                  : CXGN::BlastDB->retrieve_all;
unless(@dbs) {
  print $opt{f} ? "No database found with file_base='$opt{f}'.\n"
                : "No dbs found in database.\n";
}

foreach my $db (@dbs) {

  #check if the blast db needs an update
  unless($opt{f} || $db->needs_update) {
    print $db->file_base." is up to date.\n";
    next;
  }

  #skip the DB if it does not have a source url defined
  unless($db->source_url) {
    warn $db->file_base." needs to be updated, but has no source_url.  Skipped.\n";
    next;
  }

  if( $opt{x} ) {
    print "Would update ".$db->file_base." from source url ".$db->source_url."\n";
    next;
  } else {
    print "Updating ".$db->file_base." from source url...\n";
  }

  eval {
    # check whether we have permissions to do the format
    if( my $perm_error = $db->check_format_permissions() ) {
      die "Cannot format ".$db->file_base.":\n$perm_error";
    }

    #download the sequences from the source url to a tempfile
    print "Downloading source (".$db->source_url.")...\n";
    my (undef,$sourcefile) = tempfile('blastdb-source-XXXXXXXX',
				      DIR => $opt{t},
				      UNLINK => 1,
				     );

    my $wget_opts = { cache => 0 };
    $wget_opts->{gunzip} = 1 if $db->source_url =~ /\.gz$/i;
    wget_filter( $db->source_url => $sourcefile, $wget_opts );

    #formatdb it into the correct place
    print "Formatting database...\n";
    $db->format_from_file($sourcefile);

    unlink $sourcefile or warn "$! unlinking tempfile '$sourcefile'";

    print $db->file_base." done.\n";
  }; if( $EVAL_ERROR ) {
    print "Update failed for ".$db->file_base.":\n$EVAL_ERROR";
  }
}



