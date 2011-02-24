#!/usr/bin/env perl
use strict;
use warnings;
use English;
use Carp;
use FindBin;
use Getopt::Std;

#use Data::Dumper;
use CXGN::Publish qw/publish/;

sub usage {
  my $message = shift || '';
  $message = "Error: $message\n" if $message;
  die <<EOU;
$message
Usage:
  $FindBin::Script <options> rm FILE...
  $FindBin::Script <options> rm -f FILE...
  $FindBin::Script <options> cp SOURCE... DEST
  $FindBin::Script <options> cp SOURCE... DIRECTORY
  $FindBin::Script <options> touch FILE

  Do deletes or copies, preserving a file-based version history of the
  target file(s).  Try it out, you'll see what I mean.

  Makes its best effort to keep the operation atomic.  For example, if
  you're copying a bunch of files to a directory and the destination
  runs out of disk space, all of the files that _were_ copied will be
  removed, and the old ones put back in place, as if the operation
  never happened.

  Note that operations are skipped if the new file is the same as the
  old file.

  Operations:

  rm      'remove' the target file.  Die if it is not present.
  rm -f   'remove' the target file.  Ignore if not present.
  cp      'copy' the source(s) to the destination
  touch   right now, simply ensures that the proper curr/ symlink is
          present, making it if necessary.

  Uses the CXGN::Publish module.  If you need to do more than what's
  provided by this script, chances are you can do it by using the
  module directly.

  Options:

  -x   dry run.  don't actually do anything, just print.

  -v   be verbose

  -d   create target directories if necessary

  -b   bac repository mode.  processes filename extensions a bit
       differently to allow for sequence versions.  Requires
       CXGN::TomatoGenome::BACPublish to be installed
EOU
}

#get command-line switches
our %opt;
getopts('vxdb',\%opt) or usage();
$CXGN::Publish::print_ops = 1 if $opt{v};
$CXGN::Publish::dry_run   = 1 if $opt{x};
$CXGN::Publish::make_dirs = 1 if $opt{d};

#parse the rest of the arguments
@ARGV >= 2 or usage;

my @operands = @ARGV; #the 
my $operation = shift @operands; #the operation we will perform
if($operation eq 'rm' && $operands[0] eq '-f') {
  shift @operands;
  $operation = 'rm -f';
}

#assemble the list of publishing operations (see CXGN::Publish)
my @publish_operations = do {

  if( $operation eq 'rm'  ||  $operation eq 'rm -f' || $operation eq 'touch' ) {
    map {[$operation,$_]} @operands
  }
  elsif($operation eq 'cp') {
    my $destination =  pop @operands;
    @operands == 1 or -d $destination or $opt{d} or die "'$destination' is not a directory\n";
    map {['cp',$_,$destination]} @operands;
  }
  else {
    usage("unknown operation '$operation'");
  }

};

#do the publish operation
if($opt{b}) {
  eval 'require CXGN::TomatoGenome::BACPublish';
  die "Cannot load CXGN::TomatoGenome::BACPublish, required for -b mode:\n$@" if $@;
  CXGN::TomatoGenome::BACPublish::bac_publish(@publish_operations);
}
else {
  publish(@publish_operations);
}

