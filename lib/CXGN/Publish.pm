package CXGN::Publish;

=head1 NAME

CXGN::Publish - functions for copying or moving files verbosely, in a
dry run, versioned, and atomically

=head1 SUMMARY

  publish( ['cp', 'myfile.tar.gz', '/data/prod/ftpsite/bonobo.tar.gz'],
           ['cp', 'myfile.all.xml', '/data/prod/ftpsite/monkey.all.xml'],
         );
  # copies myfile.tar.gz  -> /data/prod/ftpsite/bonobo.v1.tar.gz,
  #        myfile.all.xml -> /data/prod/ftpsite/monkey.v1.all.xml
  # OR maybe
  # copies myfile.tar.gz -> /data/prod/ftpsite/bonobo.v32.tar.gz,
  #        myfile.all.xml -> /data/prod/ftpsite/monkey.v8.all.xml,
  #        /data/prod/ftpsite/bonobo.v31.tar.gz
  #          -> /data/prod/ftpsite/old/bonobo.v31.tar.gz.20060312012043
  #        /data/prod/ftpsite/monkey.v7.tar.gz
  #          -> /data/prod/ftpsite/old/monkey.v7.tar.gz.20060312012043
  # if there are already published copies of those files in the
  # destination dir

  #move, copy, and unlink things
  move_or_print('myfile','/data/prod/someplace/blehfile.txt');
  copy_or_print('my_other_file','/data/prod/someplace/');
  unlink_or_print('file_i_hate.txt');
  mkdir_or_print('/home/rob/somedir');

  #just print messages about how you WOULD move, copy, or unlink
  $CXGN::Publish::dry_run = 1;
  move_or_print('myfile','/data/prod/someplace/blehfile.txt');
  copy_or_print('my_other_file','/data/prod/someplace/');
  unlink_or_print('file_i_hate.txt');
  mkdir_or_print('/home/rob/somedir');

  #dry_run and print_ops work with publish() too

  #CONFIGURATION VARIABLES

  $CXGN::Publish::dry_run = 0   #if true, don't do file ops, just
                                #print them

  $CXGN::Publish::print_ops = 0 #if true, always print file operations

  $CXGN::Publish::make_dirs = 0 #if true, make any directories
                                #necessary to complete move or copy
                                #operations

  $CXGN::Publish::suffix = [qr/\..+$/];


  #AS AN OBJECT

  #alternatively, you can make a Publish object and call all of these functions
  #through it:

  my $pubber = CXGN::Publish->new({suffix => [qr/\..+$/]});
  $pubber->suffix( [ qr/\..+$/ ] );
  $pubber->dry_run(1); #get/set dry_run setting
  $pubber->print_ops(1);
  $pubber->verbose(1); #alias for print_ops
  $pubber->publish([qw( cp myfoo.tar.gz /data/foo/bar/ )]);
  $pubber->copy_or_print('foo.txt','fooey.txt');
  $pubber->move_or_print('foo','bar/');
  $pubber->unlink_or_print('file_i_hate');
  $pubber->link_or_print('file_i_hate','file_i_just_dislike');
  $pubber->mkdir_or_print('/home/rob/mydir');

  #the object-oriented approach has the advantage of not having to set
  #global variables.  Cause setting global variables is a great way to
  #write unmodular code.

  #NOTE: All the files created using this module will have their
  # permissions set as 'chmod $CXGN::Publish::Umask, $file'
  # $CXGN::Publish::Umask defaults to 0664, meaning -rw-rw-r--

=head1 DESCRIPTION

Functions for copying, moving, and unlinking files in funny ways.
The xxx_or_print functions just do what they sound like.

If you set $CXGN::Publish::dry_run = 1 (or some other true value),
they just print what they WOULD do.  So stop writing your own functions
to do dry runs, or you will be punished.

If you set $CXGN::Publish::print_ops = 1, they will print to STDOUT
the operations they are carrying out.  So stop writing your own functions
to do verbose things, or you will be punished.

On second thought, I think I'll just punish you anyway.

Oh, one more thing.  If you set $CXGN::Publish::make_dirs = 1, copy, move,
and link will all make their destination directories if they don't exist.
Unless of course dry_run is set.  Then they'll just print that they're
making the dirs.

The interesting function in here, though, is publish().  It takes a list
of copy operations, and performs those copies, adding version numbers into
the file names, and preserving previous versions in the given destination by
moving them out of the way into an old/ subdirectory.  Additionally, it tries
to perform all these moves and copies atomically, meaning all-or-nothing, so
if your script dies because we run out of disk space or something, the
directory you're copying too should not be messed up.

This module would be useful when you're writing a script to put some kind of
data dumps on our FTP site.  And maybe for other things too.

=head1 FUNCTIONS

All functions below are @EXPORT_OK.

=cut

use strict;
use warnings;
use English;
use Carp;
use UNIVERSAL qw/isa/;

use Data::Dumper;

use File::Copy;
use File::Basename;
use File::Path;

BEGIN {
  our @EXPORT_OK = qw/
		      publish
		      published_as
                      publishing_history
		      parse_versioned_filepath
		      orig_basename
		      copy_or_print
		      move_or_print
		      unlink_or_print
		      link_or_print
		      mkdir_or_print
		     /;
};
our @EXPORT_OK;

use base qw/Exporter/;

use CXGN::Tools::List qw/max/;

use constant DEBUGGING => $ENV{CXGNPUBLISHDEBUG} ? 1 : 0;
our $Umask = 0664;
sub dprint(@) { print STDERR @_ if DEBUGGING}

=head2 publish

  Usage: publish( [ 'cp', 'myfile.tar.gz', '/data/prod/ftpsite/bonobo.tar.gz'],
                  [ 'cp', 'myfile.all.xml', '/data/prod/ftpsite/monkey.all.xml'],
                );
  Desc : Performs a set of copies or deletes on files, preserving old
         versions of any files it changes and assigning version numbers
         to new files.

         Attempts to do all operations in the set atomically, that is,
         if any of the operations fails, it undoes the operations that
         were completed before the failure.

         For copies, if the file being copied is identical to a file it
         is replacing, the operation is skipped.

  Ret  : nothing meaningful.  dies on error.
  Args : - (optional) options hash (see below for available options)
         - list of copy operations, each of which is an arrayref of the
           form [ operation, src, destination ]
  Side Effects: performs filesystem operations. dies on error.
  Example:

         publish( [ 'cp', 'myfile.tar.gz', '/data/prod/ftpsite/bonobo.tar.gz'],
                  [ 'cp', 'myfile.all.xml', '/data/prod/ftpsite/monkey.all.xml'],
                );
         # copies myfile.tar.gz  -> /data/prod/ftpsite/bonobo.v1.tar.gz,
         #        myfile.all.xml -> /data/prod/ftpsite/monkey.v1.all.xml
         # OR, if there are already published copies of those files,
         # might copy
         #   myfile.tar.gz
         #    -> /data/prod/ftpsite/bonobo.v32.tar.gz,
         #   myfile.all.xml
         #    -> /data/prod/ftpsite/monkey.v8.all.xml,
         #   /data/prod/ftpsite/bonobo.v31.tar.gz
         #    -> /data/prod/ftpsite/old/bonobo.v31.tar.gz.20060312012043
         #   /data/prod/ftpsite/monkey.v7.tar.gz
         #    -> /data/prod/ftpsite/old/monkey.v7.tar.gz.20060312012043

=head3 Incorporating Version Numbers into Copied Files

      If you want to incorporate the version numbers assigned here
      into your file(s), you can pass in code ref(s) instead of
      strings for the sources, like so:

         sub xform_xml_with_version { #sub gets one argument, the new version number of the file
	   my $version_number = shift;

	   my $infile = 'myfile.all.xml';
	   my $outfile = '/tmp/mungedxml';

	   #munge the file, putting in the version number
	   #and DIE IF THIS FAILS.

           return $outfile;
	 }

         publish( [ 'myfile.tar.gz', '/data/prod/ftpsite/bonobo.tar.gz'],
                  [ \&xform_xml_with_version, '/data/prod/ftpsite/monkey.all.xml'],
                );
         #copies myfile.tar.gz  -> /data/prod/ftpsite/bonobo.v1.tar.gz,
         #       /tmp/mungedxml -> /data/prod/ftpsite/monkey.v1.all.xml
         # OR
         #copies myfile.tar.gz -> /data/prod/ftpsite/bonobo.v32.tar.gz,
         #       /tmp/mungedxml -> /data/prod/ftpsite/monkey.v8.all.xml,
         #       /data/prod/ftpsite/bonobo.v31.tar.gz
         #         -> /data/prod/ftpsite/old/bonobo.v31.tar.gz.20060312012043
         #       /data/prod/ftpsite/monkey.v7.tar.gz
         #         -> /data/prod/ftpsite/old/monkey.v7.tar.gz.20060312012043
         # if there are already published copies of those files in the
         # destination dir


     The code refs you pass should die with an error if anything goes
     wrong during their operations, which will trigger a rollback of
     the whole publish() operation.

=cut

# atomically perform a number of copy operations, expressed
# in the form of a 2-d array as ([src,dest],[src,dest],...)

# This means that if one of the copies fails, we will undo
# any other changes made to the publishing directory.

# this is robust w.r.t. everything except the script being killed, I think.
sub publish {
  my ($self,@publish_operations) = _objectify(@_);

  #check arguments
  ref eq 'ARRAY' or croak "publish takes an array of array refs, passed '$_'"
    foreach @publish_operations;

  local our $now_string = _now_string(); #now all subroutines can use this and be synchronized

  #make a string containing the time of this script run, used for transactional renaming of files
  my @ops_for_rollback;
  eval {

    #go over each of the copy operations and move anything in the way
    #into an old/ subdirectory with version numbers, also saving rollback
    #in case one of the operations fails and we need to restore the repository
    #to how we left it
  PUBLISH_OP:
    while( my $operation = shift @publish_operations) { #< do the while here so we can add operations inside
#      @$operation == 3 or unshift @$operation, 'cp';
      my $opcode = $operation->[0];

      if($opcode eq 'rm') {
	@$operation == 2 or
	  croak "Multiple rm targets not supported, make a separate rm operation for each file to be deleted";
	my $versioned = $self->parse_versioned_filepath($operation->[1]);
	my $published_as = $versioned->{version} ? $versioned : $self->publishing_history($operation->[1])
	  or die "Cannot do versioned rm '$operation->[1]', it does not seem to have ever been published\n";
	$published_as->{obsolete_timestamp}
	  and die "Cannot do versioned rm '$operation->[1]': no version is currently published\n";
	-f $published_as->{fullpath}
	  or die "Cannot do versioned rm '$published_as->{fullpath}': file not found\n";
 	dprint "rm removing $published_as->{fullpath}\n";
	$self->_move_file_to_old($published_as,\@ops_for_rollback);
      } elsif($opcode eq 'rm -f') {
	@$operation == 2 or
	  croak "Multiple rm -f targets not supported, make a separate rm -f operation for each file to be deleted";
	my $versioned = $self->parse_versioned_filepath($operation->[1]);
	my $published_as = $versioned->{version} ? $versioned : $self->publishing_history($operation->[1])
	  or next;
	$published_as->{obsolete_timestamp}
	  and next;
	-f $published_as->{fullpath}
	  or next;
 	dprint "rm -f removing $published_as->{fullpath}\n";
	$self->_move_file_to_old($published_as,\@ops_for_rollback);
      } elsif($opcode eq 'cp') {
	@$operation == 3
	  or croak "Copy operation takes only 2 arguments: a single source and a single destination";
	$self->_publish_copy($operation,\@ops_for_rollback,\@publish_operations);
      } elsif( $opcode eq 'touch' ) {
	@$operation == 2
	  or croak "touch operation takes only 1 argument, a single destination";
	$self->_update_curr_symlink($operation->[1],\@ops_for_rollback);
	$self->_make_old_readme($operation->[1],\@ops_for_rollback);
      } elsif( $opcode eq 'recover' ) {
	@$operation == 2
	  or croak "recover operation takes only 1 argument, a single destination";
        $self->_recover($operation->[1],\@ops_for_rollback);
	$self->_update_curr_symlink($operation->[1],\@ops_for_rollback);
	$self->_make_old_readme($operation->[1],\@ops_for_rollback);
      } else {
	die "invalid publish operation '$opcode'";
      } # if-elsif-else on opcode
    } #foreach
  }; if( $EVAL_ERROR ) {
    #if anything died, roll back and die again
    chomp $EVAL_ERROR;
    $EVAL_ERROR =~ s/\.$//;
#    $EVAL_ERROR .= " ($!)" unless $EVAL_ERROR =~ /$!/;
    warn "# Publish operation failed:\n# $EVAL_ERROR\n# Attempting rollback...\n";
    warn "# No operations required.\n" unless @ops_for_rollback;
    my $failed = 0;
    foreach my $operation (@ops_for_rollback) {
      my ($opcode,@args) = @$operation;
      warn "# rollback attempting $opcode ".join(' ',@args)."\n";
      if( $opcode eq 'mv' ) {
	if( move(@args) ) {
	  warn "# rollback moved '$args[0]' -> '$args[1]'.\n";
	} else {
	  warn "# rollback could not move '$args[0]' to '$args[1]': $!\n";
	  $failed = 1;
	}
      }
      elsif( $opcode eq 'rm' ) {
	if(not -f $args[0]) {
	  warn "# rollback skipping removal of nonexistent file '$args[0]'\n";
	}
  	elsif( $self->unlink_or_print($args[0]) ) {
# 	if( unlink_or_print($args[0]) ) {
	  warn "# rollback removed $args[0]\n";
	}
	else {
	  warn "# rollback could not unlink $args[0] during rollback: $!\n";
	  $failed = 1;
	}
      }
      elsif( $opcode eq 'ln' ) {
	if( $self->symlink_or_print( $args[0], $args[1] ) ) {
	  warn "# rollback linked $args[0] -> $args[1]\n";
	} else {
	  warn "# rollback could not symlink $args[0] -> $args[1]\n";
	}
      }
    }
    if($failed) {
      croak "Publish operation failed, ROLLBACK FAILED.  Publish failure caused by error:\n$EVAL_ERROR";
    } else {
      croak "Publish operation failed, but rollback was successful.  Failure caused by error:\n$EVAL_ERROR";
    }
  }
}

#figure out the actual filename target of a copy, if it's to a directory
sub _copy_target {
  my ($self,$operation) = @_;
  my ($opcode,$src,$dest) = @$operation;

  #if it's a copy to a dir, assemble the full destination filename
  if (-d $dest || $dest =~ m|/$|) {
    return File::Spec->catfile($dest, basename $src);
  }

  return $dest;
}

#given a source file, a destination path, and the array
#to store rollback operations in, do a versioned copy
#of the source to the destination
sub _publish_copy {
    my ( $self, $operation, $ops_for_rollback, $publish_operations ) = _objectify(@_);
    my ( $opcode, $src_in, $dest ) = @$operation;

    # stringify everything except coderefs
    my $src = $src_in;
    $src = "$src" unless ref $src eq 'CODE';

    #check that this is the right opcode
    $opcode eq 'cp'
        or die "Sanity check failed, _publish_copy called with wrong opcode '$opcode'";

    $dest = $self->_copy_target($operation);

    #check for version numbers already in the intended publish destination
    if ((my $bn = basename($dest)) =~ /(\.v\d+)$/) {
        die "The destination filename '$bn' contains the characters '$1', which are recognized by CXGN::Publish as a version number.  Please pick a different filename for publishing this file.\n";
    }


    #look up any currently published versions of this file
    my $published_as = $self->publishing_history($dest);

    #our new version is going to be the most recent version
    #plus one.
    my $new_version = ($published_as->{version} || 0) + 1;

    $self->_clean_up_lingerers($published_as,$ops_for_rollback);

    #now check whether the published file is actually different
    #from the one we're publishing.  If they're actually the same,
    #then skip this particular publishing operation


    if( $published_as &&  $published_as->{fullpath} ) {
        my $files_differ =
            ref($src) #< source is a subref (don't know its output beforehand)
         || !(-s $src == -s $published_as->{fullpath}) # or file sizes differ
         || do {
             system "diff -q $src $published_as->{fullpath} >/dev/null"; # or diff says they're different
             $? != 0 ? 1 : 0
         };

        #otherwise, since they're different, move the most recent existing file into
        #old/ as well

        my $tgt_obsolete = $published_as->{obsolete_timestamp};

        if( $files_differ) {
            dprint "source $src differs from existing $published_as->{fullpath}, OK to publish";

            unless( $tgt_obsolete ) {
                # move it to old and publish
                dprint "moving currently published version ($published_as->{fullpath}) to old\n";
                $self->_move_file_to_old($published_as,$ops_for_rollback);
            }

            #now publish

        } else { #< files are the same
            if( $tgt_obsolete ) {
                dprint "src is same as most recent obsolete version $published_as->{fullpath}, recovering it";
                # un-rm the old one
                unshift @$publish_operations,['recover',$published_as];
            } else {
                # do nothing, let the current non-obsolete file stay
                dprint "src $src is same as currently published $published_as->{fullpath}, doing nothing\n";
            }
            return;
        }
    }

    #if source is a code ref, pass it the version we're going to publish with
    #and get back our source file name
    if ( ref($src) eq 'CODE' ) {
        #	warn "calling code ref with $new_version, dest is $dest\n";
        $src = $src->($new_version);
        -f $src or croak "Code ref did not give back a valid file name, it gave back '$src'";
        -r $src or croak "Code ref gave back the filename '$src', but it's not readable";
    }

    #add the version number to the dest filename
    $dest = $self->_assemble_versioned_filename($dest,$new_version);

    #do the copy of our new file
    unshift @$ops_for_rollback,['rm',$dest];
    $self->copy_or_print($src,$dest)
        or die "Could not copy '$src' to '$dest' ($!)\n";
    chmod $Umask, $dest;        #< try to make sure it's world-readable
    $self->_update_curr_symlink($dest,$ops_for_rollback);
}

sub _assemble_versioned_filename {
    my ($self, $dest, $new_version) = @_;

    my ($dest_name,$dest_dir,$dest_ext) = fileparse($dest,@{$self->suffix});

    return File::Spec->catfile($dest_dir, "$dest_name.v$new_version$dest_ext");
}

sub _recover {
    my ( $self, $published_as, $ops_for_rollback ) = @_;

    unless( ref $published_as ) {
        $published_as = $self->_parse_versioned_filepath( $published_as );
    }

    die "cannot recover a file that is not obsolete!\n"
        unless $published_as->{obsolete_timestamp};

    my $recovery_destination = $self->_assemble_versioned_filename( $published_as->{fullpath_unversioned},
                                                                    $published_as->{version},
                                                                  );

    unshift @$ops_for_rollback, ['mv', $recovery_destination, $published_as->{fullpath}];
    $self->move_or_print( $published_as->{fullpath}, $recovery_destination )
        or die "could not recover '$published_as->{fullpath}' -> '$recovery_destination'";
    $self->_update_curr_symlink($recovery_destination,$ops_for_rollback);
}

sub _clean_up_lingerers {
  my ($self,$published_as,$ops_for_rollback) = _objectify(@_);
  #make sure any lingering old files go in the old/ subdirectory
  foreach my $lingerer ( @{$published_as->{lingerers}} ) {
    dprint "moving lingerer $lingerer->{fullpath}\n";
    $self->_move_file_to_old($lingerer,$ops_for_rollback);
  }
  #OMG D00D WTF IS A LINGERER?!?! you ask?  ;-)
  # a lingerer is an old version of the file that's in the publishing dir but has
  # no right to be.  like if we had both
  #   monkeys/bonobo.v1.tar.gz
  #   monkeys/bonobo.v2.tar.gz
  # then bonobo.v1 would be a lingerer.
}

=head2 parse_versioned_filepath

  Usage: my $info = parse_versioned_filepath('/tmp/myfile.v2.seq');
  Desc : parse a versioned filename
  Ret  : a hash ref as:
     { dir      => directory the file is in,
       dir_unversioned  => directory of the original published location of the file
       name     => the basename of the file (with no extensions),
       extension => all extensions, except for versioning extensions,
       fullpath => full filename passed in,
       fullpath_unversioned => full filename, minus the file version,
       basename => the file's basename with extensions, including version,
       basename_unversioned => the file's basename, minus version,
       ver      => (optional) the file's publishing version, if present,
       obsolete_timestamp => the timestamp of when the file was
                             superseded by a newer version, in the form
                             YYYYMMDDHHMMSS
     }
  Args : a single filename, with or without path
  Side Effects: none

=cut

sub parse_versioned_filepath {
  return _parse_versioned_filepath(@_);
}

#take a full path to a versioned file, and parse it into its
#constituent parts into a hashref like
# { dir => 'dir',
#   name => 'name',
#   extension => 'ext',
#   version => 2,
#   fullpath => 'fullfilename'
#   fullpath_unversioned => full path without version number
#   dir_unversioned      => dirname without old/ (if old is present)
# }
sub _parse_versioned_filepath($) {
  @_ = _objectify(@_);
  my $self = shift;
  my $filepath = shift;
  my %f = ( fullpath => $filepath );
  #warn "we are:\n",Dumper($self->suffix);
  @f{qw/name dir extension/} = fileparse($filepath,@{$self->suffix});
  $f{dir} =~ s|[\\/]$||; #< remove trailing slash on dir if present
  $f{basename} = $f{name}.$f{extension};
  @f{qw/version extension/} = ( $1, $2 || '') if $f{extension} =~ /^\.v(\d+)(\..+)?$/;
  if( ($f{obsolete_timestamp}) = $f{extension} =~ /\.(\d+)$/) {
    $f{extension} =~ s/\.\d+$//;
  }
  $f{basename_unversioned} = $f{name}.$f{extension};

  my @split = File::Spec->splitdir( $f{dir} );
  my @dir_without_old = @split; pop @dir_without_old if $dir_without_old[-1] eq 'old';
  $f{fullpath_unversioned} = File::Spec->catfile(@dir_without_old,$f{name}.$f{extension});
  $f{dir_unversioned} = File::Spec->catdir(@dir_without_old);

  return \%f;
}

#takes a filename or a parsed filename, moves it into the appropriate
#old/ subdir
#optionally takes a now_string and a rollback array to use for this
sub _move_file_to_old {
  @_ = _objectify(@_);
  my $self = shift;
  my $oldfile = shift;
  $oldfile = $self->_parse_versioned_filepath($oldfile) unless ref $oldfile;

  -f $oldfile->{fullpath} or die "$oldfile->{fullpath} not found!\n";
  dprint "asked to move file $oldfile->{fullpath} to old\n";
  confess "$oldfile->{fullpath} is already in an old subdir!"
    if $oldfile->{dir} =~ m|/old\/*$|; #if file is already obsolete, this should not be called

  our $now_string;
  my $ops_for_rollback = shift;

  #make a now_string if we don't have it already (from the local in publish())
  my $old_dir = File::Spec->catdir($oldfile->{dir},'old');
  unless(-d $old_dir) {
    mkdir_or_print($old_dir)
      or die "Could not create old dir $old_dir: $!";
    unshift @$ops_for_rollback, ['rm', $old_dir];
  }
  $self->_make_old_readme($old_dir,$ops_for_rollback);

  my $attic_dest =
    File::Spec->catfile($old_dir,"$oldfile->{basename}.$now_string");

  $self->move_or_print($oldfile->{fullpath},$attic_dest)
    or die "could not do mv '$oldfile->{fullpath}' '$attic_dest' ($!)";
  chmod $Umask, $attic_dest; #< attempt to make sure it's world-readable
  if($ops_for_rollback) {
    unshift @$ops_for_rollback, ['mv', $attic_dest, $oldfile->{fullpath} ];
  }
  $self->_update_curr_symlink($oldfile,$ops_for_rollback);
}

sub _update_curr_symlink {
  @_ = _objectify(@_);
  my ($self,$pubfile,$ops_for_rollback) = @_;
  my $orig_pubfile = $pubfile;
  unless( ref $pubfile ) {
    $pubfile = $self->_parse_versioned_filepath($pubfile);
  }

  unless($pubfile->{name}) {
    if( $self->dry_run ) {
      return;
    } else {
      confess "cannot update curr symlink, invalid file $orig_pubfile -> ".Dumper($pubfile);
    }
  }

  return if $pubfile->{obsolete_timestamp}; #< don't make curr links for obsolete files

  # use Data::Dumper;
  # Carp::cluck(Dumper $pubfile);

  my $currdir = File::Spec->catdir($pubfile->{dir},'curr');
  my $currlink =  File::Spec->catfile( $currdir, $pubfile->{name}.$pubfile->{extension});
  my $curr_readme =  File::Spec->catfile( $currdir, 'README.txt');

  #shared code that (reversibly) removes the current symlink
  my $rmlink = sub {
    if( -l $currlink ) {
      my $curr_target = readlink($currlink);
      $self->unlink_or_print($currlink);
      if( $curr_target ) {
	unshift @$ops_for_rollback, ['ln', $curr_target, $currlink];
      }
    }
  };

  unless(-d $currdir ){
    $self->mkdir_or_print($currdir);
    unshift @$ops_for_rollback, ['rm', $currdir];
  }
  chmod $Umask|0775, $currdir; #< attempt to make sure it's world-readable

  unless(-f $curr_readme ) {
    unless( $self->dry_run ) {
      open my $rm, ">$curr_readme" or die "$! writing $curr_readme";
      print $rm <<EOF;
This curr/ directory contains symlinks to the most current versions of
versioned files in the parent directory.  These are intended for use
by automatic tools that need a stable path from which to download a
file.

Use of these links for other than automatic downloading is
discouraged, because the filenames have no version numbers, and thus
results obtained from these files may be difficult to reproduce.
EOF
      close $rm;
      unshift @$ops_for_rollback, ['rm', $curr_readme ];
    } else {
      print "would do: echo blah blah blah > $curr_readme\n";
    }
  }

  if( -f $pubfile->{fullpath} ) {
    #we need to make a (relative) link to it

    $rmlink->(); #< remove any old curr link that might be in the way

    my $link_target =  File::Spec->catfile( '..',$pubfile->{basename} );
    $self->symlink_or_print( $link_target,$currlink )
      or die "could not symlink $link_target -> $currlink ($!)\n";
    unshift @$ops_for_rollback, ['rm',$currlink];
  } else {
    $rmlink->();
  }
}

sub _make_old_readme {
  my ($self,$old_dir,$ops_for_rollback) = @_;

  # if we're passed some dir or filename, try to figure out where the
  # old/ dir for it would be
  unless( basename($old_dir) eq 'old' ) {
    my ($bn,$dir) = fileparse($old_dir);
    if( -d $old_dir ) {
      $old_dir = File::Spec->catdir($old_dir,'old');
    } else {
      $old_dir = File::Spec->catdir($dir,'old');
    }
  }

  return unless -d $old_dir;

  my $old_readme = File::Spec->catfile($old_dir,'README.txt');
  unless( -f $old_readme ) {
    unless( $self->dry_run ) {
      open my $rm, ">$old_readme" or die "$! writing $old_readme";
      print $rm <<EOF;
This old/ directory contains old versions of files in its parent
directory.  Each file has the same name with which it was formally
available, except a date string is appended to each file containing
the date it was obsoleted and moved to this old/ directory, formatted
as .YYYYMMDDHHMMSS.

Very old versions of some files may not be available.
EOF
      close $rm;
      unshift @$ops_for_rollback, ['rm', $old_readme ];
    } else {
      print "would do: echo blah blah blah > $old_readme\n";
    }
  }
}

#returns a string representation of the moment in time when this is called
#like 20060514193642 (down to the second)
sub _now_string {
  my @now = gmtime(time);
  $now[4]++; $now[5]+=1900;
  @now[0..4] = map {sprintf('%02d',$_)} @now[0..4];
  join('',reverse @now[0..5]);
}

#check the first argument, and if it's a publish object, then fine.
#otherwise, make a new publish object and prepend it to the arguments.
#return the new list of arguments
sub _objectify {
  if(ref($_[0]) && isa($_[0],'CXGN::Publish')) {
#    warn "$_[0] isa.\n";
    return @_;
  } else {
    return (CXGN::Publish->new(),@_);
  }
}

=head2 published_as

  Usage: my $published_as = published_as($publish_dir,$filename);
         #OR
         my $published_as = published_as($filename);
  Desc : given a publishing destination and filename,
         or a path with those two components, look in the publishing
         destination and get info about
  Ret  : a hash ref as:
         {  version   => <num>, #the file version this was published as
            fullpath  => <string>, #the full path to the most recent published
                         version,
            ancestors => arrayref listing previous versions of the file
                         that are present, each of which is a hashref
                         { version => num, fullpath => path }
         }
         or undef if there is no current published version of the file
         at that location
  Args : publishing directory, filename
         OR
         filename with path
  Side Effects: lists directories in the file system
  Example:

=cut

sub published_as {
  my $full_info = publishing_history(@_);
  return if $full_info->{obsolete_timestamp};

  return unless $full_info->{fullpath};

  #return a subset of the full info
  return  { map { $_ => $full_info->{$_} }
            'version',
            'fullpath',
            'ancestors',
	  };
}

=head2 publishing_history

  Usage: my $status = $pub->publishing_history( $filepath );
  Desc : get the full version history of the given (versioned or
         unversioned) file.  Succeeds regardless of whether the
         file in question is currently present.
  Args : file path,
         OR
         dir, file
  Ret  : a hash ref as:
         {  version   => <num>, #the file version this was published as
            fullpath  => <string>, #the full path to the most recent published
                         version,
            fullpath_unversioned => full path to the unversioned published
                                    location of the file,
            obsolete_timestamp => if given file is obsolete, the string
                                  obsolete timestamp, which is in the form
                                  of 'YYYYMMDDHHMMSS'
            ancestors => arrayref listing previous versions of the file
                         that are present in the old/ dir,  each of which is a
                         hashref { version => num, fullpath => path },
            lingerers => arrayref listing previous versions of the file
                         that do not appear to be current, but for some
                         reason are not in the old/ dir.  Same format as
                         ancestors above.
         }
  Side Effects: none

=cut

#and this is the real-deal function, that returns a whole lot more stuff
#it gives everything that comes from the filename parser above,
#(ver, full, name, dir, etc), plus ancestors and lingerers,
# which are arrayrefs of full paths to files.  The ancestors array is all the
# files that preceded the published one, sitting in the old/ directory
# lingerers are files of an earlier version that _should_ be in the old dir, but
# are still erroneously in the publishing dir.  Feed them to _move_file_to_old to
# clean them up.

sub publishing_history {

  @_ = _objectify(@_);
  my $self = shift;
  @_ > 2 || @_ < 1 and croak "published_as takes either 1 or 2 arguments, you passed ".scalar(@_);
  my $fullpath = @_ == 1 ? shift : File::Spec->catfile(@_);
  my $p = $self->_parse_versioned_filepath($fullpath);
  my ($file,$pubdir,$ext) = ($p->{name},$p->{dir},$p->{extension});#fileparse($fullpath,@{$self->suffix});

  #check whether there are any files in the destination _OR_ in the old/ with that name and extension
  my @matching_files = ( glob(File::Spec->catfile($pubdir,"$file.v*$ext")), glob(File::Spec->catfile($pubdir,'old',"$file.v*$ext.*")) );
  #if that glob didn't pick up anything, then this file has not yet been published
  #return unless @matching_files;

  @matching_files = map  {$self->_parse_versioned_filepath($_)} @matching_files;
  @matching_files = sort { $b->{version} <=> $a->{version} } @matching_files;

  #find the non-obsolete file with the highest version number and take it off the array
  #or if there is none, make an empty record to hold the ancestors
  my $current_version = shift(@matching_files) || { fullpath => undef,
                                                    fullpath_unversioned => $p->{fullpath_unversioned},
                                                    version => undef,
                                                    obsolete_timestamp => undef,
                                                  };

  #now sort the rest of the matching files into ancestors and lingerers
  $current_version->{lingerers} = [];
  $current_version->{ancestors} = [];
  #note: the current version might also be an ancestor or lingerer, if the repository
  #somehow got a little broken
  foreach my $oldfile (@matching_files) {
    #is it a virtuous ancestor or a dissolute lingerer?
    my $verdict = $oldfile->{obsolete_timestamp}
      ? 'ancestors' : 'lingerers';
    #put it where it belongs in the return
    dprint "I think $oldfile->{fullpath} is one of the $verdict\n";
    push @{$current_version->{$verdict}}, $oldfile;
  }

  dprint "publishing_history returning:\n",Dumper $current_version if DEBUGGING;

  die "sanity check failed" if ! $current_version->{fullpath} && @{$current_version->{lingerers}};


  return $current_version;
}

=head2 orig_basename

  Usage: my $origbn = orig_basename('/my/pub/foo.v2.bar');
         #returns 'foo.bar'
  Desc : given a path to a published file, return a string with
         the original basename (with extensions) of the file,
         that is, the filename without the version and/or timestamp strings.
         This just calls parse_versioned_filepath, then concatenates the
         'name' and 'ext' fields.
  Ret  : the original basename of the file, without versions or timestamps
         or whatnot, or undef if the filepath could not be parsed
  Args : a single file path, or a directory
  Side Effects: none
  Example:

    my $origbn = orig_basename('/my/pub/foo.v2.bar');
    #returns 'foo.bar'

    #OR

    my $bn2 = orig_basename('/my/pub/old/foo.v1.bar.200606051922');
    #also returns 'foo.bar'

=cut

sub orig_basename {
  my ($self,$filepath) = _objectify(@_);

  my $p = $self->parse_versioned_filepath($filepath)
    or return undef;

  return $p->{name}.$p->{extension};
}

=head2 revert_published_file

  Usage: revert_published_file($published_path, -1)
         OR
         revert_published_file($published_path, 27)
  Desc : revert a published file to an earlier version.
         WARNING: this is not undoable!
  Ret  : nothing meaningful
  Args : full path to the file to revert (can be a versioned
         or unversioned file name),
         revision to revert.  Negative numbers signify an
         offset from the current revision, while a positive
         number explicitly specifies a revision to revert to.
  Side Effects: dies on failure

  NOT YET IMPLEMENTED, since it hasn't been needed yet.

=cut

sub revert_published_file {
  confess 'not yet implemented.  pester rob to write me!';
}


################# FUNCTIONS FOR DRY RUNS ################


=head2 unlink_or_print

  Usage: unlink_or_print('file_I_hate.txt')
           or die "Could not unlink file_I_hate.txt: $!";
  Desc : unlinks given unless $CXGN::Publish::dry_run is set
  Ret  : true if successful, false if not
  Args : a SINGLE file name
  Side Effects: unlinks the given file, returns false on failure

=cut

sub unlink_or_print($) {
  my($self,$target) = _objectify(@_);

  @_ > 2 and croak 'unlink_or_print takes a SINGLE file name';

  if( $self->dry_run ) {
    print "would do: rm $target\n";
    return 1;
  }
  print "rm $target\n" if $self->print_ops;
  return unlink($target);
}

=head2 move_or_print

  Usage: move_or_print('myfile','mydir/')
           or die "Could not move myfile->otherfile: $!";
  Desc : move unless $CXGN::Publish::dry_run is set
  Ret  : true if successful, false if not
  Args : filename to move, filename or dir to move it to
  Side Effects: moves the named file, returns false on failure

=cut

sub move_or_print($$) {
  @_ = _objectify(@_);
  my $self = shift;
  my($src, $dest) = @_;

  @_ == 2 or croak 'move_or_print takes TWO file names';

  if($self->make_dirs) {
    my ($destfile,$destdir) = fileparse($dest);
    mkdir_or_print($destdir) unless -d $destdir;
  }

  if( $self->dry_run ) {
    print "would do: mv $src $dest\n";
    return 1;
  }
  print "mv `$src' -> `$dest'\n" if $self->print_ops;
  return move($src,$dest);
}

=head2 copy_or_print

  Usage: copy_or_print('myfile','mydir/')
           or die "Could not copy myfile->otherfile: $!";
  Desc : copy unless $CXGN::Publish::dry_run is set
  Ret  : true on success, false on failure
  Args : file to copy, file or dir to copy it to
  Side Effects: copies the given file to the given file
                or dir.  returns false on error.

=cut

sub copy_or_print($$) {
  @_ = _objectify(@_);
  my $self = shift;
  my($src, $dest) = @_;

  @_ == 2 or croak 'copy_or_print takes TWO file names';

  if($self->make_dirs) {
    my ($destfile,$destdir) = fileparse($dest);
    mkdir_or_print($destdir) unless -d $destdir;
  }

  if( $self->dry_run ) {
    print "would do: cp $src $dest\n";
    return 1;
  }
  print "cp `$src' -> `$dest'\n" if $self->print_ops;
  return copy($src,$dest);
}

=head2 link_or_print

  Usage: link_or_print('myfile','mydir/')
           or die "Could not link myfile->otherfile: $!";
  Desc : link unless $CXGN::Publish::dry_run is set
  Ret  : true on success, false on failure
  Args : file to link, file or dir to link it to
  Side Effects: hardlinks the given file to the given file
                or dir.  returns false on error.

=cut

sub link_or_print($$) {
  my ($self,$src,$dest) = _objectify(@_);

  if( $self->dry_run ) {
    print "would do: ln $src $dest\n";
    return 1;
  }
  print "ln `$src' -> `$dest'\n" if $self->print_ops;


  if(-d $dest) {
    my ($filename) = fileparse($src);
    return link($src,File::Spec->catfile($dest,$filename));
  } else {
    return link($src,$dest);
  }
}


=head2 symlink_or_print

  Usage: symlink_or_print('myfile','mydir/')
           or die "Could not link myfile->otherfile: $!";
  Desc : symlink unless $CXGN::Publish::dry_run is set
  Ret  : true on success, false on failure
  Args : file to symlink, file or dir to symlink it to
  Side Effects: symlinks the given file to the given file
                or dir.  returns false on error.

=cut

sub symlink_or_print($$) {
  my ($self,$src,$dest) = _objectify(@_);

  if( $self->dry_run ) {
    print "would do: ln -s $src $dest\n";
    return 1;
  }

  if(-d $dest) {
    my ($filename) = fileparse($src);
    $dest = File::Spec->catfile($dest,$filename);
  }

  print "ln -s `$src' -> `$dest'\n" if $self->print_ops;
  return symlink($src,$dest);
}

=head2 mkdir_or_print

  Usage: mkdir_or_print('/my/dir/somewhere');
  Desc : same as the others, except for mkdir.  Uses
         File::Path::mkdir with the default args, so
         L<File::Path> for what permissions it sets, etc.
  Ret  : 1 if successful, undef otherwise
  Args : single directory name to create.  Will also
         create parent directories if necessary (like
         perl mkpath or `mkdir -p`)
  Side Effects: makes directories in the filesystem

=cut

sub mkdir_or_print {
  my ($self,$dir) = _objectify(@_);

  if( $self->dry_run ) {
    print "would do: mkdir -p $dir\n";
    return 1;
  }
  print "mkdir -p `$dir'\n" if $self->print_ops;

  return mkpath([$dir]);
}

=head1 CONFIGURATION VARIABLES AND ACCESSORS

Publishing configuration is done by either global variables or object
accessors.  If you call the functions in this module without using an
object, they take their configurations from the global variables in
this package.  If you call them using an object, they take their
configuration from the settings in that object.  When a new object is
made, its configuration variables are initialized to the values of the
package globals.

=cut

use Class::MethodMaker
  [
    scalar => [qw(
		  dry_run
		  make_dirs
		  print_ops
		  suffix
		 )
	      ],
  ];

# GLOBALS and their defaults
our $dry_run = 0;
our $make_dirs = 0;
our $print_ops = DEBUGGING ? 1 : 0;
our $suffix = [ qr/\..+$/ ];

sub new {
    my $self = bless {}, shift;
    $self->dry_run(our $dry_run);
    $self->make_dirs(our $make_dirs);
    $self->print_ops(our $print_ops);
    $self->suffix(our $suffix);
    return $self;
}

=head2 dry_run / $CXGN::Publish::dry_run

  Usage: $pub->dry_run(1);    $CXGN::Publish::dry_run = 1;
  Desc : Flag for getting/setting whether to do a dry run,
         not doing anything to the filesystem, just printing
         what would be done
  Ret  : the current/new value of dry_run
  Args : optional new value for dry_run (0 to unset)

=cut

#dry_run() is made with Class::MethodMaker above

=head2 make_dirs / $CXGN::Publish::make_dirs

  Usage: $pub->make_dirs(1);    $CXGN::Publish::make_dirs = 1;
  Desc : Flag for getting/setting whether to make any directories
         necessary for doing our operations.
  Ret  : the current/new value of make_dirs
  Args : optional new value for make_dir (0 to unset)

=cut

#make_dirs() is made with Class::MethodMaker above

=head2 print_ops() / $CXGN::Publish::print_ops

  Usage: $pub->print_ops(1);    $CXGN::Publish::print_ops = 1;
  Desc : Flag for getting/setting whether to print all file operations
         that we do (as well as doing them)
  Ret  : the current/new value of print_ops
  Args : optional new value for print_ops (0 to unset)

=cut

#print_ops() is made with Class::MethodMaker above

=head2 suffix() / $CXGN::Publish::suffix

publish() places version numbers before the suffix of each file to
avoid confusing programs (and operating systems) that rely on these
suffixes.  By changing the regular expression(s) publish() uses to
find the suffix, you can control where in each filename the version
information is placed.  By default, publish uses the regex qr/\..+$/
to match suffixes, meaning that everything after and including the
first '.' in the filename is considered the suffix.

For example, if you don't care about Windows users and want the
version information to always be inserted at the end of the filename,
you can set { suffix => [] }.

Another example: if some of your files have a .1,.2,.3 extension that
you don't want split from the rest of the name, you can set { suffix
=> [qr/(<=\d)\..+/,qr/\..+/] }.  Since the regexps are matched in the
order they're given, the first one will match for files with a numeric
part, and the second will match for files that don't have a numeric
part.


  Usage: $pubber->suffix([qr/(?<=\d)\..+$/,qr/\..+$/]);
  Desc : set the regexp(s) used to match file suffixes
  Ret  : the new arrayref of quoted regexps
  Args : (optional) arrayref of regexps to use
  Side Effects: if an argument is passed, sets the suffix regexps in
                the object

=cut

#suffix() is made with Class::MethodMaker above

=head1 MAINTAINER

Robert Buels, E<lt>you@cornell.eduE<gt>

=head1 AUTHOR

Robert Buels, E<lt>you@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

###
1;#do not remove
###

