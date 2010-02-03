package CXGN::TomatoGenome::BACSubmission;
use strict;
use warnings;

use English;
use Carp;

use Cwd;
use Data::Dumper;
use File::Temp;
use File::Spec;
use File::Basename;
use File::Path;
use File::Copy;

use Hash::Util qw/ lock_hash /;
use List::Util qw/sum/;

use Memoize;
use Module::Pluggable
    sub_name => 'analyses',
    except => qr/::Base$/, #< skip packages called Base
    search_path => 'CXGN::TomatoGenome::BACSubmission::Analysis',
    require => 1,
    instantiate => 'new';

use LWP::Simple;
use XML::LibXML;

use Bio::SeqIO;
use Bio::SeqUtils;
use Bio::Tools::RepeatMasker;
use Bio::FeatureIO;

use CXGN::Annotation::GAMEXML::Combine qw/combine_game_xml_files/;
use CXGN::TomatoGenome::BACPublish qw/valcache/;

use CXGN::Genomic::Clone;
use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident assemble_clone_ident clean_clone_ident/;

use CXGN::Publish qw/parse_versioned_filepath/;

use CXGN::Tools::Run;
use CXGN::Tools::File qw/file_contents/;
use CXGN::Tools::List qw/str_in/;

use CXGN::TomatoGenome::BACSubmission::Analysis;
use CXGN::TomatoGenome::Config;

use constant GENBANK_ACC_PATTERN => qr/^[A-Z_]{2,4}\d+$/;
use constant GENBANK_VER_PATTERN => qr/^[A-Z_]{2,4}\d+\.\d+$/;

use Class::MethodMaker
  [ scalar => [qw/
		  _version
		  _tempdir
		  _bacname
		  _chromosome_number
		  _tarfile
		  _tarfile_dir
		  _renamed_sequences_file
		  _vector_screened_sequences_file
	       /],
  ];

#debugging utils
use constant DEBUG => $ENV{CXGNBACSUBMISSIONDEBUG} ? 1 : 0;
sub dbp(@) { DEBUG ? print 'debug: ',@_ : 1 };
$|=1 if DEBUG; #keep output synced if we are debugging
$File::Temp::DEBUG = 1 if DEBUG;

#### ERROR CONSTANTS
BEGIN {
  our @errnames = qw( E_BAD_TARFILE  E_BAD_FILENAME E_BAD_BACNAME E_BAD_LIBNAME
		      E_BAC_PARSE    E_NO_TOP_DIR  E_NO_MAIN_SEQ E_NO_MAIN_QUAL
		      E_BAD_SEQ_VER  E_UNK_CLONE   E_CLONE_STAT  E_BAD_DATA    E_MULT_SEQS
		      E_GB_ACC       E_GB_REC      E_GB_SEQ      E_GB_PHASE_1  E_GB_PHASE_3
		      E_SEQ_INFO     E_VEC
		    );
  our @EXPORT_OK = @errnames;
  our %EXPORT_TAGS = (errors => [@errnames]);
}
use base qw/Exporter/;
use enum 'DUMMY',our @errnames; #< DUMMY is there to make it start at 1

=head1 NAME

CXGN::TomatoGenome::BACSubmission - class representing a BAC sequence tar file
submitted from a sequencing center

=head1 SYNOPSIS

  #untar this submission in a temp dir
  my $submission = BACSubmission->open('C03HBa1234A12.tar.gz');
  print "Made a submission object from ",$submission->tar_file,"\n";
  print "This submission appears to be from BAC ",
        $submission->bac_name,
        "\n";

  #validate this submission file
  if( my $errors = $submission->validation_text ) {
    print "This submission is invalid for the following reasons: $errors\n";
  }

  #get filenames in temp storage containing sequence(s) in various forms
  my $original_seqs_filename = $submission->sequences_file;
  my $renamed_seqs_filename  = $submission->renamed_sequences_file;
  my $vector_screened_seqs   = $submission->vector_screened_sequences_file;

  #analyze this submission with GenomeThreader against all SGN Tomato
  #and Potato ESTs
  my @result_files = $submission->analyze_with('GenomeThreader_sgne_tomato_potato');

  #copy the analysis result files into my home directory
  system 'cp', @result_files, '/home/rob';


  #NOTE: there is a script called bsub_analyze_submission.pl that
  #wraps the above in a nice command-line interface

  $submission->close; #delete from temporary storage

=head1 CLASS METHODS

=head2 open

  Usage: my $submission = BACSubmission->open('mybac.tar.gz');
  Desc : creates a new submission object, which untars the given tar file
         into a temp directory and returns a BACSubmission object to use
         for working with its contents
  Ret  : a new BACSubmission object
  Args : the name of a submission tar file, either in the current dir or
         fully qualified
  Side Effects: untars the file into a temp directory (in a location
                settable with tempdir() below) if it cannot untar the
                file, dies with an error
  Example:

=cut

#note: init() is called by open(), which is made by Class::MethodMaker
sub open {
  my ($class,$tarfile,$stripped) = @_;
  my $self = bless {}, $class;
  local $Carp::CarpLevel = 1; #skip the MethodMaker-generated open() in the call stack

  #make sure we have our tarfile and store its name
  $tarfile or croak "must provide a filename to open\n";
  -r $tarfile or croak "Could not open file '$tarfile'.\n";
  $self->_tarfile($tarfile);

  #parse the file name into a bac name and store the results
  my ($bacname,$path,$suffix) = fileparse( $tarfile, qr{\..+$} );
  $self->_bacname($bacname);
  $self->_tarfile_dir($path);

  my $p = parse_clone_ident($bacname,'agi_bac_with_chrom');
  $self->_chromosome_number($p->{chr}) if $p;

  # make a temp dir and decompress the tar file
  $self->_tempdir( File::Temp::tempdir( "bac-submission-temp-$bacname-XXXXX",
				        DIR => __PACKAGE__->tempdir,
				        CLEANUP => DEBUG ? 0 : 1,
				      )
		 );

#  dbp "tar -xzf $tarfile -C ".$self->_tempdir."\n";
  if( $stripped ) {
    eval {
      $self->_stripped_decompress($tarfile);
    };
    warn $EVAL_ERROR if $EVAL_ERROR;
  }

  unless($stripped && !$EVAL_ERROR) {
    eval {
      CXGN::Tools::Run->run( 'tar',
			     -xzf => $tarfile,
			     -C   => $self->_tempdir,
			   );
    };
    if( $EVAL_ERROR ) {
        warn $EVAL_ERROR;
        $self->{open_failed} = $EVAL_ERROR;
    }
  }

  #open the sequences file and initialize the version of this object
  #if the identifier(s) in the file have versions
  #use eval to ignore errors in the seq file at this stage.  This will be checked in validation
  my $initial_version = eval { $self->_extract_version_from_seq_file };
#  warn "init: $EVAL_ERROR" if $EVAL_ERROR;
  $self->_version($initial_version) if $initial_version;

  return $self;
}

=head2 open_stripped

  Same as open() above, but do not include any subdirectories in temp
  storage or in the tarfile made by new_tarfile().  If this has never
  been done before with a particular submission file, caches a
  stripped copy of the tarfile in a
  .cxgn-bacsubmission-cache/stripped_tarballs directory NEXT TO the
  original tarfile.

=cut

sub open_stripped {
  shift->open(shift,'strip');
}

# given a tar file (probably on a networked filesystem), check to see
# if we have cached a stripped version of the tarball next to it.  if
# so, decompress that into our tempdir.  if not, decompress the full
# tar and make a stripped version
sub _stripped_decompress {
  my ($self,$tarfile) = @_;

  confess "trying a stripped decompress on already stripped tarball '$tarfile'"
    if $tarfile =~ m!/stripped_tarballs/!;

  my ($bn,$dir) = fileparse($tarfile);
  my $cache_base = File::Spec->catdir( $dir, '.cxgn-bacsubmission-cache' );
  my $stripped_cache = File::Spec->catdir( $cache_base, 'stripped_tarballs' );
  my $stripped_tar = File::Spec->catfile( $stripped_cache, $bn );
  my @s_stat = stat($stripped_tar);
  my @t_stat = stat($stripped_tar);
  if( @s_stat && $s_stat[9] >= $t_stat[9] ) { #< if we have a stripped tarball, and it's newer than the file we're opening
    dbp "untarring existing stripped tarball\n";
    CXGN::Tools::Run->run( 'tar',
			   -xzf => $stripped_tar,
			   -C   => $self->_tempdir,
			   "--exclude='*/*/*'"
			 );
  } else {
    dbp "making new stripped tarball from '$tarfile'\n";
    mkdir $cache_base;
    mkdir $stripped_cache;

    # now untar the tarfile with exclusions, which will read the whole
    # tarfile over NFS, but ignore everything but the stripped
    # contents
    my $t = CXGN::Tools::Run->run( 'tar',
                                   -xzf => $tarfile,
                                   "--exclude=*/*/*",
                                   -C  => $self->_tempdir,
                                 );
    print $t->out.$t->err;

    # and make new tarfile containing only the stripped contents,
    # putting it in the stripped location
    unless( copy( $self->new_tarfile, $stripped_tar ) ) {
      unlink($stripped_tar);
      die "$! copying new stripped tarball to '$stripped_tar'";
    }
    dbp "done making new stripped tarball\n";
  }

  # cleanup any files in the stripped cache that don't correspond to existing files
  foreach my $stripped (glob File::Spec->catfile($stripped_cache,'*')) {
    next unless -f $stripped;
    my ($bn,$dir) = fileparse($stripped);
    my $orig = File::Spec->catfile($dir,'..','..',$bn);
    dbp "stripped cleanup looking for orig '$orig'.\n";
    unless( -e $orig ) {
      dbp "original not found, deleting stripped copy.\n";
      rmtree $stripped
	or warn "WARNING: $! unlinking $stripped\n";
    }
  }
}

#object method to extract the sequence version number in this tarball's
#sequence file.  dies if unable to do so.  returns the version number,
#or undef if none was found.
sub _extract_version_from_seq_file {
  my $self = shift;
#  return undef;
  -r $self->sequences_file
    or croak "Cannot extract sequence version, ".$self->sequences_file." not found";

  CORE::open (my $seqfile, $self->sequences_file)
    or confess "Could not open ".$self->sequences_file.": $!";

  my $v = undef;
  while (<$seqfile>) {
    if (/^\s*>\s*(\S+)/) {	#get the fasta identifier and extract the version from it
#      warn "checking identifier $1\n";
      my $thisv = $self->_extract_version_from_identifier($1);
#      warn "got version '$thisv' from $1\n";
      if ( defined($v) and defined($thisv) and !($thisv == $v) ) {
	#if the sequences in the file don't all have the same version, give up.
	croak "Conflicting versions found in sequence file for submission ",
	  $self->_tarfile,
	    ".  First, I found version '$v', then '$thisv'";
      }
      $v = $thisv;
    }
  }
  return $v;
}

#object method that, given an identifier, extracts the
#version number from it
sub _extract_version_from_identifier {
  my ($self,$ident) = @_;
  my $p = parse_clone_ident($ident,'versioned_bac_seq')
    or return;
  return $p->{version};
}

=head2 tempdir

  Usage: my $tempdir    = BACSubmission->tempdir('/data/local/tmp');
         my $using_temp = $submission->tempdir;
  Desc : get/set the temporary directory being used for objects of this
         class, or get the temporary directory being used by a
         particular object
  Ret  : the currently set temp dir
  Args : (optional) new temp dir
  Side Effects:
  Example:

=cut

our $_tempdir; #name of class-wide temp base dir
sub tempdir {
  my ($class_or_object,$requested_tempdir) = @_;

  #set the tempdir to use for this particular object
  if( ref $class_or_object ) {
    return $class_or_object->_tempdir;
  }
  #set the tempdir to use for all objects of this class
  elsif( UNIVERSAL::isa($class_or_object,__PACKAGE__) ) {

    if ( $requested_tempdir ) {
      -w $requested_tempdir
	or croak "Requested temporary directory '$requested_tempdir' is not writable";
      $_tempdir = $requested_tempdir;
    }
    elsif( ! $_tempdir ) {
      $_tempdir =
	$ENV{_extract_tempdir}  ?  $ENV{_extract_tempdir}    :
	-w '/data/local/tmp/'   ?  '/data/local/tmp/'        :
	-w '/data/local/temp/'  ?  '/data/local/temp/'       :
	-w File::Spec->tmpdir   ?  File::Spec->tmpdir        :
	    confess 'Could not find a writable directory for temporary files';
    }

    -w $_tempdir or confess "Chosen temporary dir $_tempdir is not writable!";
    dbp "using temp base dir $_tempdir\n";
    return $_tempdir;

  }
  else {
    croak "tempdir() can only be called as a class or object method";
  }
}

=head1 UTILITY METHODS

These object methods perform actions on a specific BAC submission object.

=head2 version

  Usage: my $version = $submission->version
  Desc : get/set the version number of the _sequence_ in this submission.
         Note that this is different from the _file_ version, set when
         L<CXGN::Publish> copies the files into the publishing directory.
         The version is a positive integer.
  Ret  : the current or new sequence version of this submission
  Args : (optional) new version number to set
  Side Effects: the version set here will be appended to the identifiers
                in this submission's sequence and quality files
  Example:

=cut

sub version {
  my ($self,$newversion) = @_;

  if($newversion) {
    $newversion += 0; # make sure it's numeric
    $newversion > 0 or croak "Invalid new sequence version '$newversion'";
    length($newversion) > 5 and croak "Sequence version '$newversion' is more than 5 characters long.  Currently CXGN::TomatoGenome::BACPublish can only deal with up to 5-character sequence versions";

    $self->_version($newversion);

  }

  return $self->_version;
}


=head2 renamed_sequences_file

  Usage: $submission->rename_sequences($renamed_sequences_file);
  Desc : rename the sequences in this BAC submission and write them
         to a file in this submission's temp directory
  Ret  : file name of the temporary file
  Args : none
  Side Effects: makes a file of renamed sequences in temporary storage, unless
                it already exists
  Example:

=cut

sub renamed_sequences_file {
  my $self = shift;

  local $Carp::CarpLevel += 1;

  #### read in the sequences, rename them, and write them out #####

  my $seqfile = $self->sequences_file;

  #find this submission's sequence file
  -r $seqfile || confess <<EOT;
Could not read '$seqfile', you were supposed to validate that already!
EOT

  #make SeqIO objects for sequence input (the sequence file inside the submission)
  #and sequence output (a file in the top level of this submission's temp directory)
  my $seq_in = Bio::SeqIO->new( -file => $seqfile,
				-format => 'fasta' );
  my $renamed_seqs_file = $self->generated_file_names()->{renamed_seqs};
  my $seq_out = Bio::SeqIO->new( -file => ">$renamed_seqs_file",
				 -format => 'fasta');

  #read in the sequences and write them out
  my $seq  = $seq_in->next_seq;
  my $seq2 = $seq_in->next_seq;
  if( $seq2 ) {
    #if seq2 is defined, we must have more than one sequence in this file

    #rename and write out the first seq
    $self->_rename_seq( $seq, $self->sequence_identifier(1) );
    $seq_out->write_seq($seq);

    #rename and write out the rest of the seqs
    my $n = 2;
    do {
      $self->_rename_seq($seq2, $self->sequence_identifier($n++) );
      $seq_out->write_seq($seq2);
    } while($seq2 = $seq_in->next_seq);
  }
  elsif( $seq ) {
    #there is only one sequence in this file
    #rename it and write it out
    $self->_rename_seq( $seq, $self->sequence_identifier );
    $seq_out->write_seq($seq);
  }
  else {
    die "No sequences found in file $seqfile";
  }
  return $renamed_seqs_file;
}

#internal method
#takes a Bio::Seq object and a new identifier name for it,
#format the description to include the old name and but in the
#new name as the primary identifier
#also, reformat any old submitted_as: tags to be submitted_to_sgn_as:
sub _rename_seq {
  my ($self,$seq,$new_name) = @_;

  { #fix up the submitted_as stuff in the sequence description
    #this basically takes all the submitted_as tags in the desc,
    #and takes the value of the last one, renaming it to
    #submitted_to_sgn_as:, and putting it at the beginning of the description
    my $submit_tag;
    my $genbank_accession;
    my @desc;
    if($seq->desc) {
      foreach (split /\s+/,$seq->desc) {
	if ( /submitted_(?:to_sgn_)?as:(\S+)/) {
	  $submit_tag = "submitted_to_sgn_as:$1";
	} elsif ( /^[A-Z_]{2,4}\d+(\.\d+)?$/ ) {
	  $genbank_accession = $_;
	  unless($genbank_accession eq $self->genbank_accession) {
	    warn "WARNING: replacing $genbank_accession with ".$self->genbank_accession." in sequence fasta file\n";
	    $genbank_accession = $self->genbank_accession;
	  }
	} elsif ( /^htgs_phase:(\d)/ || /^sequenced_by:(\S+)/ || /^upload_account_name:(\S+)/) {
	  #just drop it
	} else {
	  push @desc, $_;
	}
      }
    }
    $submit_tag ||= "submitted_to_sgn_as:".$seq->display_id;
    my $phase_tag = "htgs_phase:".$self->htgs_phase;
    my %seqinfo = $self->sequencing_info;
    #warn 'rename got ',Dumper \%seqinfo;
    my @possible_sequencers = $self->sequencing_possible_orgs;
    my @sequenced_by = @possible_sequencers == 1 ? ('sequenced_by:'.$seqinfo{org_shortname}) : ();
    my @upload_account =  $seqinfo{org_upload_account_name} ? ('upload_account_name:'.$seqinfo{org_upload_account_name}) : ();
    my $newdesc = join(' ',$self->genbank_accession,$phase_tag,$submit_tag, @sequenced_by, @upload_account, @desc);
    $seq->desc($newdesc);
  }

  $seq->display_id( $new_name );
  $seq->primary_id( $new_name );

  #do some transparent cleaning of the sequence
  my $seqstr = $seq->seq;
  $seqstr = uc $seqstr;
  $seqstr =~ s/\r//g; #<remove carriage returns
  $seq->seq( $seqstr );

  return $seq;
}

=head2 vector_screened_sequences_file

  Usage: my $vs_seqs_file = $submission->vector_screened_sequences_file
  Desc : looks up the vector sequence for this BAC in the database, then
         runs the $self->renamed_sequences_file through the 'cross_match'
         program with the vector sequence, and returns the name of the
         resulting screened output file
         NOTE: THIS WILL ONLY WORK IF THE SUBMISSION VALIDATES
  Ret  : the name of the vector-screened output file.  If any of this
         fails, this method will raise an error with croak()
  Args : none
  Side Effects: accesses the database, runs cross_match, which creates
                some temp files in this submission
                object's temp directory


  Note: This is currently implemented to redo the vector screen every time
        the tarfile is opened, even if a screening file already exists.
        Right now, that doesn't take much time, but in the future we might
        not want to do it every time.

=cut

sub vector_screened_sequences_file {
  my $self = shift;

  #get the vector sequence and put it in a temp file
  my $vector_seq_file = do {

    my $clone = $self->clone_object
      or confess "Could not find a clone object for BAC name ".$self->bac_name;
    my $vector = $clone->library_object->cloning_vector_object
      or croak 'No cloning vector object found for this clone';
    my $vecname = $vector->name;
    my $vecseq = $vector->seq;
    my $file = $self->generated_file_names->{vector_seq};
    #need to call it CORE::open because we have defined our own open() method in this package
    CORE::open(my $vector_seq_fh,">$file")
	or confess "Could not open vecseq file '$file': $!";
    print $vector_seq_fh <<EOVEC;
>$vecname
$vecseq
EOVEC
    close $vector_seq_fh;
    $file
  };

  #check that cross_match is found in the path
  `which cross_match` or croak "cross_match executable not found in path, and it is required for vector screening\n";

  my $renamed_seqs_file = $self->renamed_sequences_file;
  #screen the renamed sequences versus the vector with cross_match
  my $cm = CXGN::Tools::Run->run('cross_match',
				 $renamed_seqs_file,
				 $vector_seq_file,
				 -minmatch => 10,
				 -minscore => 20,
				 '-screen',
				 { out_file => $self->generated_file_names->{cross_match_output},
				   err_file => $self->generated_file_names->{cross_match_err},
				 });

  #check that the sequences file is where we expect it to be, and return it
  -r $renamed_seqs_file.'.screen'
    or confess "cross_match did not produce the expected output file\n";
  dbp "got vector-screened sequences file $renamed_seqs_file.screen\n";

  my $screened_seqs_file = $self->generated_file_names->{vector_screened_seqs};
  move($renamed_seqs_file.'.screen',$screened_seqs_file)
    or confess "could not move cross_match screened file $renamed_seqs_file.screen -> $screened_seqs_file: $!";

  return $screened_seqs_file;
}

=head2 repeat_masked_sequences_file

  Usage: my $rm_seqs = $submission->repeat_masked_sequences_file
  Desc : get a repeat-masked, vector-screened version of the main
         sequence file.  Uses the RepeatMasker analysis defined
         below
  Args : none
  Ret  : filename
  Side Effects: might run the RepeatMasker analysis

=cut

sub repeat_masked_sequences_file {
  my ($self) = @_;

  my $rm_filename = $self->vector_screened_sequences_file.'.masked';
  unless(-f $rm_filename) {
    $self->analyze_with('RepeatMasker');
    -f $rm_filename or confess "The RepeatMasker analysis did not produce the expected output file $rm_filename";
  }
  return $rm_filename;
}

=head2 repair

  Usage: $submission->repair or die "submission is broken beyond repair()";
  Desc : Attempt to repair some aspects of this submission so that it validates.
         This may or may not be successful.
  Ret  : 1 if the repair was successful, 0 otherwise
  Args : none
  Side Effects: Changes file content, renames directories, and otherwise munges
                the decompressed copy of this submission in temporary storage.
                Does not affect the original tar file.
  Example:

=cut

sub repair {
  my ($self) = @_;

  #only try to repair if there are errors
  if( $self->validation_errors ) {
    dbp "attempting to repair submission\n";

    #check the naming of the enclosed directory
    unless( -d $self->main_submission_dir ) {
      #try to rename it to the right name
      my @dirs = glob($self->_tempdir.'/*/');
      if( @dirs == 1 ) {
	move($dirs[0],$self->main_submission_dir);
	dbp "repair moving $dirs[0] -> ".$self->main_submission_dir."\n";
      }
      else {
	#maybe it just doesn't have a main directory.  make one and
	#move everything into it
	mkdir($self->main_submission_dir)
	  or die "repair could not make directory ".$self->main_submission_dir.": $!";
	foreach my $file (glob($self->_tempdir.'/*')) {
	  move($file,$self->main_submission_dir);
	  dbp "repair moving $file -> ".$self->main_submission_dir."\n";
	}
      }
    }

    #check for the existence of the enclosed sequence file
    unless( -f $self->sequences_file ) {
      #look for candidate seqs files
      my @files = glob($self->main_submission_dir.'/*.seq');
      if( @files == 1 ) {
	move($files[0],$self->sequences_file);
	dbp "repair moving $files[0] -> ".$self->sequences_file."\n";
      }
    }

    if( -f $self->sequences_file) {
      #try to repair the sequences
      CORE::open my $f, $self->sequences_file;
      my ($tfh,$t) = File::Temp::tempfile(DIR=>$self->_tempdir);
      while( <$f> ) {
	$_ = uc $_ unless /^>/;
	print $tfh $_;
      }
      close $tfh;
      close $f;
      copy($t,$self->sequences_file);
      dbp "repair processed sequence file\n";
    }

    #check for the existence of the enclosed qual file
    unless( -f $self->qual_file ) {
      #look for candidate seqs files
      my @f = glob($self->main_submission_dir.'/*.qual');
      if( @f == 1 ) {
	move($f[0],$self->qual_file);
	dbp "repair moving $f[0] -> ".$self->qual_file."\n";
      }
    }
  } else {
    return 1;
  }

  #run validation_errors again to see if we fixed it.  return 0 if not
  #(if there were still errors), or return 1 if we did fix it (no
  #errors)
  return $self->validation_errors ? 0 : 1;
}

=head2 new_tarfile

  Usage: my $new_tarfile_name = $submission->new_tarfile
  Desc : make a new .tar.gz file of this submission, usually used in conjunction
         with repair() above.  The file is created in temporary storage, which
         is deleted when you call close() on this object or at the end of the
         program, so move it somewhere else if you want to keep it.
  Ret  : string containing the name of the tar file in temporary storage.  You
         should move or copy it out of there.
  Args : none
  Side Effects: makes a new .tar.gz file in temporary storage
  Example:

=cut

sub new_tarfile {
  my ($self) = @_;

  dbp "creating new tarfile for ".$self->bac_name."\n";
  ####tar up the contents of our temp dir###

  #figure out what to name our new tarball
  my $tarname = $self->generated_file_names->{new_tarfile};

  #delete the current tar if present
  unlink $tarname;

  #make sure we have a vector screened sequence file by now,
  #because we have to include that in the tarball
  #ignore dies from this step, because we might not be operating
  #on a validated submission
  eval{ $self->vector_screened_sequences_file };

  #make a list of all the dirs and files to put in our new tarball,
  #excluding all of the temp files that were generated by this object
  my @things_to_tar = do {
    my $prefix = $self->_generated_file_prefix;
    opendir(my $temp_dh,$self->_tempdir)
      or confess 'Cannot open temp dir '.$self->_tempdir.": $!";
    grep { ! /^\./ && ! /^$prefix/ } readdir $temp_dh;
  };

  #make the new tarball, tarring from the correct perspective
  my $tempdir = $self->_tempdir;

  #need to do the pipe to gzip because we need the -n option.  using
  #-n, gzip does not store the original name and timestamp.  this
  #makes two tarballs that contain the same data have the exact same
  #tarfile, so that tarballs don't keep incrementing their file
  #versions artificially if they are republished.

  #will die if the command fails
  my $things_to_tar = join(' ',@things_to_tar);
  system "tar -C $tempdir -cf - $things_to_tar | gzip -n --rsyncable > $tarname";
  die "tar failed with exit code $CHILD_ERROR" if $CHILD_ERROR;
  die "tar failed, did not make a file!"       unless -f $tarname;
  die "tar failed, tarball was zero size!"     unless -s $tarname;

  return $tarname;
}


=head2 genbank_submission_file

  Usage: my $file = $submission->genbank_submission_file
  Desc : use NCBI's fa2htgs program and the given template file
         to make a properly formatted file for submitting this
         BAC's sequence to genbank
  Args : (optional) HTGS phase to apply, either 1, 2, or 3
         (optional) sequencing center name to use, guesses by default,
         (optional) template file to use.  By default, uses
          /root/sgn-tools/bac/genbank_submit/template/<seq center>.sqn
  Ret  : filename of the .htgs file this made
  Side Effects: runs fa2htgs, might run vector screening if it
                hasn't already been run

=cut

sub genbank_submission_file {
  my ($self,$force_phase,$seq_center,$template_file) = @_;
  defined($force_phase) && !($force_phase == 1 || $force_phase == 2 || $force_phase == 3)
    and croak "invalid phase '$force_phase'";

  #make sure the submission is valid, except for genbank accession
  if (grep { $_ != E_GB_ACC  && $_ != E_GB_SEQ && $_ != E_GB_REC } $self->validation_errors) {
    die $self->validation_text;
  }

  #array holding seq center names, indexed by chromosome number.  right now only Cornell is defined,
  #but we can add others
  my @chr_centers; @chr_centers[1,10,11] = ('Cornell') x 3;

  #figure out what sequencing center to use
  $seq_center ||= $chr_centers[$self->clone_object->chromosome_num]
    or confess $self->bac_name.": No sequencing center defined for chromosome ".$self->clone_object->chromosome_num.".  Either add it to the \@chr_centers array in this script, or pass the optional seq center argument to this function.\n";

  #does this submission currently have a genbank accession?
  my $current_accession = $self->genbank_accession;
  $current_accession =~ s/\.\d+$// if $current_accession;

  #make sure we have a template file
  unless($template_file) {
    ($template_file) = grep -f, map {
      File::Spec->catfile(File::Spec->rootdir,'root','sgn-tools','bac','genbank_submit','templates',$_)
      } ($current_accession ? "$current_accession.sqn" : ()), "$seq_center.sqn";
  }
#  warn "using template file $template_file\n";

  -r $template_file
    or confess "Expected template file $template_file not found or not readable.  Do you need to create it?\n";

  #count the bases of vector sequence present in this sequence
  my $vector_seq_count = do {
    my $vecfile = $self->vector_screened_sequences_file
      or confess "no vector screened sequences file?!?!";

    my $seq_in = Bio::SeqIO->new(-file => $vecfile,
				 -format => 'fasta');

    my $x_count = 0;
    while (my $seq = $seq_in->next_seq) {
      my $seqstr = $seq->seq;
      while ($seqstr =~ /X+/g) {
	$x_count += length($MATCH);
      }
    }
    #return
    $x_count;
  };

  #check whether there is more than 1KB of vector sequence in the submission.  if so, reject it
  if($vector_seq_count >= 1000) {
    my $bacname = $self->bac_name;
    die "$vector_seq_count bases of vector sequence detected in submission for $bacname.  Cowardly refusing to make a genbank submission for it.";
  }

  my $outfile = $self->generated_file_names->{genbank_htgs};
  system( 'fa2htgs',
	  -i => $self->is_finished ? $self->sequences_file : $self->_make_broken_up_sequences_file,
	  -t => $template_file,
	  -u => 'T',
	  -p => $force_phase || ($self->is_finished ? 3 : 1),
	  -g => $seq_center,
	  -b => 100,
	  -m => 'T', #< use the comment in the template
	  -s => $self->clone_object->clone_name_with_chromosome,
	  -c => $self->clone_object->clone_name_with_chromosome,
	  -h => $self->clone_object->chromosome_num,
	  -C => $self->clone_object->library_object->shortname,
	  $current_accession ? (-a => $current_accession) : (),
	  -n => 'Lycopersicon esculentum',
	  -o => $outfile,
	);
  #ignore exit value of fa2htgs.  sometimes it's nonzero, but it
  #generates the submission fine anyway
  -f $outfile or confess "expected fa2htgs output file '$outfile' not created!";
  my $tail = `tail -1 $outfile`;
  $tail =~ /"( }){4,6}\n$/ or confess "fa2htgs produced a malformed file (ended in '$tail')\n";

  return $outfile;
}

sub _make_broken_up_sequences_file {
  my ($self) = @_;

  my $f = File::Spec->catfile($self->_tempdir,'broken_up_sequences_for_fa2htgs.seq');
  #  my $f = '/tmp/fakeseq.seq';
  my $out = Bio::SeqIO->new(-format => 'fasta', -file => ">$f" );
  my $in  = Bio::SeqIO->new(-format => 'fasta', -file => $self->sequences_file);
  my $seq_ctr = 0;
  while(my $s = $in->next_seq) {
    my @contigs = split /N{5,}/,$s->seq;
    foreach my $c (@contigs) {
      $s->id("sgn_fake_contig".++$seq_ctr);
      $s->seq($c);
      $out->write_seq($s);
    }
  }

  #close in and out filehandles
  $out = $in = undef;

  #and return
  return $f;
}



=head2 close

  Usage: $submission->close
  Desc : close this BAC submission, freeing its temporary space
         calling this is optional, the space will be freed at the end of the
         program anyway
  Ret  : the number of files deleted from temporary storage
  Args : none
  Side Effects: deletes the temporary storage used by this bac submission

  NOTE:  a close() is also automatically done when the BACSubmission object
         is DESTROYed (goes out of scope).

=cut

sub close {
  my $self = shift;

  if($self->_tempdir) {
    dbp "close() removing ".$self->_tempdir."\n";
    #rmtree is from File::Path - works just like rm -r
    rmtree($self->_tempdir) if -d $self->_tempdir;
  }
}

sub DESTROY {
  my ($self) = @_;
  $self->close;
}

=head2 list_analyses

  Usage: $obj_or_class->list_analyses
  Desc: get the names of all the available BAC analyses
  Args : none
  Ret  : list of analysis names,

=cut

sub list_analyses {
  my ( $self, ) = @_;
  return map {$_->analysis_name} $self->analyses;
}

=head2 get_analysis

  Usage: my $a_obj = $bac->get_analysis($aname)
  Desc : get an analysis object by its name
  Args : string analysis name
  Ret  : analysis object, or nothing if not found
  Side Effects: none

=cut


# index and check for conflicts in our analyses
my %analyses_by_name;
for my $a ( __PACKAGE__->analyses ) {
    my $n = $a->analysis_name;
    my $p = ref $a;
    if( my $conflict = $analyses_by_name{$n} ) {
        die "both '$p' and ".ref($conflict)." have name '$n'.  Cannot compile";
    }
    $analyses_by_name{$n} = $a;
}

sub get_analysis {
    my ( $self, $aname ) = @_;
    return $analyses_by_name{$aname};
}


=head2 analyze_with

  Usage: my @resultfiles =
           $submission->analyze_with('GeneSeqer',
                                     { geneseqer_est_seq_file =>
                                       '/data/shared/bleh.seq'
                                     });
  Desc : analyze this BAC end submission with the requested analysis package
         and return the filenames of the analysis results
  Ret  : list of result files to publish, with the first one being the
         analysis's primary output file in GAME XML format
         and the rest being secondary output files (intermediates, etc)
         that should also be published
  Args : name of analysis to run, e.g. 'GeneSeqer', and an optional reference
         to a hash of secondary input arguments to the analysis
  Side Effects: runs the analysis (usually a command-line executable),
                throws an error with die() or croak() if it failed
  Example:

  For a list of available analysis packages, see AVAILABLE ANALYSES below.

=cut

sub analyze_with {
  my ( $self, $analysis_name, $secondary_args ) = @_;
  $secondary_args ||= {};

  no strict 'refs'; #using symbolic refs

  dbp "Analyzing with $analysis_name.  Curdir is ".File::Spec->curdir.".\n";

  my $analysis = $self->get_analysis($analysis_name)
      or croak "analysis '$analysis_name' not found";

  $analysis->check_ok_to_run($self,$secondary_args);

  if( $analysis->already_run( $self ) ) {
    return $analysis->output_files( $self );
  } else {
    my @ret = $analysis->run($self,$secondary_args);
    dbp "$analysis_name done.  Curdir is now ".File::Spec->curdir.".\n";
    return @ret;
  }
}

=head2 analyze_new_submission

  Usage: $submission->analyze_new_submission
  Desc : run all analyses on this submission that are marked as needing to
         be run on new BAC submissions
  Ret  : hash-style list as:
           ( merged        => ['filename.xml','filename.gff3',...],
             analysis_name => [game xml, other file, other file, ...],
             analysis_name => [game xml, other file, other file, ...],
           )
  Args : hash ref of secondary parameters for the analyses
  Side Effects: runs analyses, creates files in this submission's temp
  Example:

  For a list of available analysis packages, see AVAILABLE ANALYSES below.

=cut

sub analyze_new_submission {
  my $self = shift;
  my $secondary_params = shift || {};

  dbp "Got secondary params: ".Dumper($secondary_params);

  my @a_objects;

  #make analysis objects and check that they are runnable
  foreach my $anal_name (CXGN::TomatoGenome::BACSubmission::Analysis->analyses_to_run) {
    dbp "checking whether $anal_name can run...\n";
    my $a = $self->get_analysis($anal_name);
    $a->analysis_name eq $anal_name or confess 'analysis names are not being properly generated';

#    #uncomment these lines if we want to run partial sets of analyses when some are not runnable
#    eval {
      $a->check_ok_to_run( $self, $secondary_params ); #this check will die if not OK
#     }; if( $EVAL_ERROR ) {
#       print "Submission: ".$submission->bac_name." skipping analysis $anal_name.  Unable to run: $EVAL_ERROR";
#     } else {
    push @a_objects,$a;
#    }
  }

  #we do it in two loops like this so that if one analysis is not runnable, we won't discover
  #that fact after already spending a long time running the other analyses

  #run all the analyses, and they should all run fine, since we already checked them in the loop above
  #if they don't, maybe someone should improve their check_ok_to_run subroutine
  @a_objects or croak 'No runnable analyses found!';

  my %result_files;
  foreach my $a (@a_objects) {
    dbp "running analysis ",$a->analysis_name,", curdir is ".File::Spec->curdir."\n";

    my @result = $a->run( $self, $secondary_params );
    @result or confess $a->analysis_name.' did not return a game xml file';

    unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
      ##make sure the game xml parses
      if( $self->is_finished ) {
	#don't parse the XML if the BAC isn't finished, cause if there are
	#multiple sequences the xml is going to be either empty or crap
	dbp "parsing XML result file '$result[0]'\n";
	eval {
	  my $doc = XML::LibXML->new->parse_file( $result[0] );
	  #	$doc->dispose; #avoid memory leaks
	}; if( $EVAL_ERROR ) {
	  die "GAME XML file produced by ".$a->analysis_name." is not well-formed, parser said: $EVAL_ERROR\n";
	}
      } else {
	dbp "BAC not finished, skipping parse validation of game xml file '$result[0]'\n";
      }
    } else {
      warn "debugging environment set, not checking validity of game xml file produced by ".$a->analysis_name;
    }
    $result_files{$a->analysis_name} = \@result;
    dbp $a->analysis_name."done, curdir is ".File::Spec->curdir."\n";
  }

  my @game_files = map { $_->[0] } values %result_files;
  my @gff3_files = map { $_->[1] } values %result_files;

  #merge the GAME XML files together if this is a finished BAC
  #add a 'merged' set of result files
  $result_files{merged} = [ $self->generated_file_names->{merged_game_xml},
			    $self->generated_file_names->{merged_gff3},
			  ];
  if($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
    warn "debugging environment set, not really merging the game xml and gff3 files";
    system('touch',@{$result_files{merged}});
  } else {
    eval {
      if( $self->is_finished ) {
	combine_game_xml_files(@game_files,$result_files{merged}->[0])
	  or confess 'Could not merge files'; #function itself should die on error, but die here too just in case
      } else {
	$self->_write_unfinished_bac_xml_stub($result_files{merged}->[0]);
      }
    }; if($EVAL_ERROR) {
      die "Could not merge GAME XML files into $result_files{merged}->[0]: $EVAL_ERROR\n";
    }

    #_combine_analysis_gff3_files is defined below
    $self->_combine_analysis_gff3_files(@gff3_files,$result_files{merged}->[1]);
  }

  return %result_files;
}

sub _write_gamexml_stub {
  my ($self,$filename,$message) = @_;
  CORE::open my $throwaway_handle, ">$filename"
    or die "Can't open '$filename' for opening: $!";
  print $throwaway_handle  "<!-- $message -->\n";
}

sub _write_unfinished_bac_xml_stub {
  my ($self,$filename) = @_;
  $self->_write_gamexml_stub($filename,'GAMEXML annotation is not currently implemented for unfinished BACS.  However, annotation results are available in GFF3 format in this directory.');
}

sub _write_gth_parse_error_bac_xml_stub {
  my ($self,$filename) = @_;
  $self->_write_gamexml_stub($filename,'No results.  GenomeThreader produced invalid output XML.');
}

sub _combine_analysis_gff3_files {
  my ($self,@files) = @_;
  my $outfile = pop @files;
  @files > 1 or die 'must have at least 2 gff3 files to combine';

  my $out = $self->_open_gff3_out($outfile);

  # for each input file, open it, renumber its feature IDs so that
  # they'll be unique in the merged file, and write them to our merged
  # output
  my $renumbering_state = { mapping=>{}, counters=>{},}; # <-a hash where the renumbering routine keeps its counters
  foreach my $file (@files) {
    my $in = Bio::FeatureIO->new( -file => $file,       -format => 'gff', -version => 3);
    while( my $feature = $in->next_feature ) {
      _renumber_gff3_identifiers( $renumbering_state, $feature );
      $out->write_feature($feature);
    }
  }
}

#open a gff3 outfile with the right version and sequence-region
sub _open_gff3_out {
  my ($self,$outfile) = @_;

  # handle for out merged output file
  return Bio::FeatureIO->new( -file => ">$outfile",
			      -format => 'gff',
			      -sequence_region => Bio::SeqFeature::Generic->new( -seq_id => $self->sequence_identifier,
										 -start => 1,
										 -end => sum(map $_->length,$self->sequences),
									       ),
			      -version => 3);
}

sub _renumber_gff3_identifiers {
  my ($state,$feature) = @_;

  my $new_id; #save the new ID of this feature

  #if it has a Parent and the ID of its parent was changed
  if(my ($parent) = $feature->get_Annotations('Parent')) {
    $parent->value($state->{mapping}{$parent->value} || $parent->value);
  }

  #if it has an ID
  if( my ($id) = $feature->get_Annotations('ID') ) {
    my $orig_id = my $idstr = $id->value;

    #if it's a PGL_X_AGS_X, replace its number with the correct one
    if(my ($prevpgl) = $idstr =~ /^PGL_(\d+)_AGS_\d+$/) {
      $idstr =~ s/(PGL_\d+)/$state->{mapping}{$1} || $1/e;
    }

    #take off the uniqifying number if present
    $idstr =~ s/_\d+$//;

    #give it a new uniqifying number
    $new_id = $idstr .= '_'.++$state->{counters}{$idstr};

    #set it back in the ID object
    $id->value($idstr);
    $state->{mapping}{$orig_id} = $idstr;
  }
}



=head1 INFORMATION METHODS

These object methods provide information about a BAC submission.

=head2 error_string

  Usage: print $submission->error_string(E_BAD_FILENAME);
         #returns a string describing the E_BAD_FILENAME error
  Desc : convert error numbers (positive integers) into descriptive error strings
  Ret  : error string
  Args : error number
  Side Effects: none
  Example:

  If you 'use' this package with the :errors tag, the following error number
  constants will be imported:

        E_BAD_TARFILE   - the submission tarfile is incomplete or corrupt
	E_BAD_FILENAME  - improperly formatted file name
	E_BAD_BACNAME   - bac name is not correctly formatted
	E_BAD_LIBNAME   - invalid library name
	E_BAC_PARSE     - bac name not parsable
	E_NO_TOP_DIR    - did not find expected top-level directory inside
                          submission file
	E_NO_MAIN_SEQ   - no main sequence file found
        E_NO_MAIN_QUAL  - no main qual file found
	E_BAD_SEQ_VER   - sequence versions are not properly formed
	E_UNK_CLONE     - the specified BAC clone does not exist in the sgn database
	E_CLONE_STAT    - the specified BAC clone does not have the correct attribution
                          and/or sequencing status in the SGN BAC registry
        E_BAD_DATA      - the submission contains malformed data, most likely from
                          file corruption
        E_MULT_SEQS     - multiple sequences found in submitted file.  Sequences should
                          be submitted as for Genbank, with N's representing gaps.
        E_GB_ACC        - the GenBank accession file (gbacc.txt) is missing or does
                          not contain a valid GenBank accession
        E_GB_REC        - the GenBank record for this accession is not properly formatted
        E_GB_SEQ        - the sequence in this BAC sequence's GenBank record is not the same
                          as the sequence provided in the tarball
        E_GB_PHASE_1    - the GenBank record reports this BAC as phase 1,
                          but the sequence does not contain any N's
        E_GB_PHASE_3    - the GenBank record does not contain any HTGS_PHASE[1/2] keyword,
                          but the sequence contains N's
        E_SEQ_INFO      - sequencing_info.txt contains invalid data
        E_VEC           - vector sequence detected in the submission

   Of course, you can always just use these constants by prepending the
   package, like CXGN::TomatoGenome::BACSubmission::E_BAD_FILENAME.

=cut

sub error_string {
  my ($self,$errnum) = @_;

  my @errors = ( undef,
		 'submission tarfile is corrupt or incompletely uploaded',
		 'improperly formatted file name',
		 'bac name is not correctly formatted',
		 'invalid library name',
		 'bac name not parsable',
		 "did not find expected top-level directory '"
		   .basename($self->main_submission_dir)."' inside submission file",
		 'no main sequence file found',
		 'no main qual file found',
		 'improper sequence versions found in main sequence file',
		 'BAC clone '.$self->bac_name.' does not exist in the database',
                 'BAC clone '.$self->bac_name.' does not have the correct chromosome attribution and/or sequencing status in the SGN BAC registry',
		 'invalid sequence or quality data.  is the file incomplete or corrupted?',
		 'multiple sequences found in the submission sequence file.  Updated guidelines require unfinished BACs to be submitted as a single sequence, with gaps represented by N\'s, identical to the format used for Genbank/EMBL/DDBJ submissions.',
		 'the genbank accession file (gbacc.txt) is missing or does not contain a valid GenBank accession',
		 'the GenBank record for this BAC ('.($self->genbank_accession || '<not set>').') is not properly formatted.  Check the latest version of the SOL Bioinformatics standards guidelines on SGN for the proper format to use for GenBank submissions.',
		 'the submitted sequence and the sequence in GenBank ('.($self->genbank_accession() || '<not set>').') are not the same',
		 "the GenBank record reports this BAC as phase 1, but the sequence does not contain any N's",
		 "the GenBank record does not contain any HTGS_PHASE[1/2] keyword, but the sequence contains N's",
		 "sequencing_info.txt contains invalid data",
		 'vector sequence detected in submission',
	       );

  confess "errnum must be numeric" unless $errnum < @errors && $errnum > 0;

  return $errors[$errnum];
}

=head2 validation_errors

  Usage: my @errors = $submission->validation_errors
  Desc : make sure that this BAC submission is properly formatted
  Ret  : list of integer constants describing the errors present in
         this BAC submission, or an empty array if there are no errors
         If you want text descriptions, use validation_text() instead,
         or use error_string() to convert each of the integers into text.
  Args : none
  Side Effects: none
  Example:

=cut

sub validation_errors {
  my ($self) = @_;

  return (E_BAD_TARFILE) if $self->{open_failed};

  my $tarball = $self->_tarfile;
  my $decompression_path = $self->_tempdir;
  my @errors = ();

  my ($bacname,$dir) = ( $self->_bacname, $self->_tarfile_dir );

  $bacname && $bacname !~ /\./
    or push @errors,E_BAD_FILENAME;#improperly formatted file name

  #check the formatting and library name of the BAC name
  my %valid_libs = ( HBa => 1, SLm => 1, SLe => 1, SLf => 1 );
  unless( $bacname =~ /^C\d{2}([A-Za-z]{3})\d{4}[A-Z]\d{2}$/ ) {
    push @errors,E_BAD_BACNAME;#"bac name '$bacname' is not correctly formatted";
  } else {
    $valid_libs{$1}
      or push @errors,E_BAD_LIBNAME;#"'$1' is not a valid library name";
  }

  #check if the clone name is correctly formatted
  my $parsed = parse_clone_ident($bacname,'agi_bac_with_chrom')
    or push @errors,E_BAC_PARSE;#"file's basename '$bacname' is not a parsable BAC name";

  #check if the clone name exists in the database
  my $got_clone = 0;
  if($parsed) {
    if(my $clone = CXGN::Genomic::Clone->retrieve_from_parsed_name($parsed)) {
      $got_clone = 1;

      $clone->chromosome_num
	and $clone->chromosome_num eq $parsed->{chr}
	  and str_in($clone->sequencing_status,qw/in_progress complete/)
	    or push @errors,E_CLONE_STAT;

    } else {
      push @errors,E_UNK_CLONE;
    }
  }

  #fatal if no subdirectory
  my $maindir = $self->main_submission_dir;
  unless( -d $maindir ) {
    push @errors,E_NO_TOP_DIR;#"did not find expected top-level directory '$bacname' inside submission file";
    return @errors;
  }

  #check for sequence file
  my $have_sequence_file = -r $self->sequences_file
    or push @errors,E_NO_MAIN_SEQ;#"no sequence file '$bacname/$bacname.seq' found";

  #check for qual file
  unless(-r $self->qual_file or $self->{_warned_about_qual_file}) {
    warn "WARNING: No .qual file found in ".$self->_tarfile.", please consider providing one.\n";
    $self->{_warned_about_qual_file} = 1;
  }
  #TODO: when quals are made mandatory, comment out the warning above
  # and replace it with the push below
  #or push @errors,E_NO_MAIN_QUAL;

  #if we have the sequence file, check it over for weirdness
  if($have_sequence_file) {

    #check for versions in sequence file
    eval {
      $self->_extract_version_from_seq_file;
    };
    if($EVAL_ERROR) {
      push @errors, E_BAD_SEQ_VER;
      warn "error extracting versions from seq file: $EVAL_ERROR";
    }

    eval {
      #check integrity of sequence file, using shell commands instead
      #of bioperl, in order to avoid bioperl dependency in
      #validate_submission.pl script
      my $seqfile = $self->sequences_file;
      my $num_seqs = `grep '>' $seqfile | wc -l`;
      chomp $num_seqs;
      push @errors, E_MULT_SEQS if $num_seqs > 1;
      CORE::open my $seq_in, $seqfile
	or die "could not open sequence file: $!";
      while( my $seqline = <$seq_in> ) {
	chomp $seqline;
	my $invalid_chars;
	if($seqline =~ /^>/) {
	  ($invalid_chars) = $seqline =~ /[^\r\n\t\040-\176]+/;
	} else {
	  ($invalid_chars) = $seqline =~ /[^\r\nACGTURYKMSWBDHVNacgturykmswbdhvn]+/;
	}
	if( defined $invalid_chars ) {
	  #hex-escape any weird characters
	  $invalid_chars =~ s/[^\040-\176]/uc(sprintf('\%02x',ord($MATCH)))/eg;
	  die "invalid characters in sequence file line $. (control characters hex escaped): '$invalid_chars'\n";
	}
      }
    };
    if($EVAL_ERROR) {
      push @errors, E_BAD_DATA;
      warn "error reading sequence file: $EVAL_ERROR\n";
    }
    elsif($got_clone) {
      my @vs_seqs = $self->vector_screened_sequences;
      my $all = join '', map $_->seq, @vs_seqs;
      #do not tolerate any vector matches in the first or last 1000 bases
      # but allow up to 50 bases of vector match in the internal parts of the sequence
      my $ends = substr($all,0,1000).substr($all,length($all)-1000,1000);
      my $all_count = ($all =~ tr/X//);
      push @errors, E_VEC if $ends =~ /X/i || $all_count > 50;
    }
  }

  my $seqinfo_errors = [];
  $self->_parsed_seqinfo_file($seqinfo_errors);
  if( @$seqinfo_errors ) {
    warn map "WARNING: $_\n", @$seqinfo_errors;
    push @errors, E_SEQ_INFO;
  }

  #check that the submission contains a genbank accession
  my $gbacc = $self->genbank_accession;
  #check that it's valid-looking
  unless( $gbacc && ($gbacc =~ GENBANK_ACC_PATTERN || $gbacc =~ GENBANK_VER_PATTERN) ) {
    push @errors, E_GB_ACC;
  } else {
    #looks valid, pull its genbank record and check the sequence and fields
    push @errors, $self->_check_genbank_record;
  }

  #cache the validation errors if we can write to it
  eval { #< just warn if it fails
    valcache($self->_tarfile, { text => $self->_err2txt(@errors),
				errors => \@errors,
			      }
	    );
  };
  warn "cannot write to validation cache: $EVAL_ERROR" if $EVAL_ERROR;

  return @errors;
}

#without using bioperl, fetch this bac's genbank record. we're not
#using bioperl here because this code has to go into the
#validate_submission.pl script, which can't have a dependency on
#anything except core modules
use constant FETCHFORM => 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?retmode=text&rettype=gbwithparts&db=nucleotide&id=%s&usehistory=n&email=sgn-feedback@sgn.cornell.edu&tool=sgn_bac_pipeline';
memoize('_parsed_gb_entry');
sub _parsed_gb_entry {
  my ($id) = @_;
  confess "must give an id\n" unless $id;
  my $url = sprintf FETCHFORM,$id;
#  warn "fetching with url $url\n";

  my $rec;
  foreach (1..5) {
    warn "Trying again to fetch GenBank record for $id (attempt $_)...\n" if $_ > 1;
    $rec = get($url);
    last if $rec
      && index($rec,'DEFINITION') != -1
      && index($rec,'ORIGIN') != -1
      && index($rec,$id) != -1;
    sleep 1;
    $rec ||= "<nothing>"; chomp $rec; $rec .= "\n"; #< clean up the return
    if ($_==5) {
      warn "Could not retrieve GenBank record for $id.\nServer returned:\n$rec";
      return {};
    }
  }

  my @lines = split /\n/,$rec;

  my %parsed;
  my $curr_section;
  foreach my $line (@lines) {
    last if $line =~ m!^//!;
    if($line =~ /^([A-Z]+)(.+)$/) {
      $curr_section = $1;
      $line = $2;
    }
    $line =~ s/^\s+//;
    $parsed{$curr_section} .= $line.' ';
  }

  #now post-process a couple of the sections
  $parsed{ORIGIN} =~ s/[\d\s]//g;
  $parsed{ORIGIN} = uc $parsed{ORIGIN};
  return \%parsed;
}

=head2 parsed_genbank_record

  Usage: my $record = $sub->parsed_genbank_record
  Desc : get a hashref containing the contents of the
         GenBank/EMBL/DDBJ record for this BAC's sequence
  Args : none
  Ret  : hashref as { FIELD => 'text' },
         or nothing if the record could not be fetched
  Side Effects: none

=cut

sub parsed_genbank_record {
  my ($self) = @_;
  my $record = eval {_parsed_gb_entry($self->genbank_accession)}
    or return;
  return $record;
}

#pull the genbank record for this BAC and check that it's proper,
#returning an array of error constants for what we find
sub _check_genbank_record {
  my ($self) = @_;

  my @errors; #< accumulate errors in this array and return it

  #fetch the genbank sequence and comment
  my $entry = _parsed_gb_entry($self->genbank_accession)
    or return (E_GB_ACC);

  #get our submitted sequence
  if(-r $self->sequences_file) {
    my $seq = file_contents($self->sequences_file);
    $seq =~ s/>.+\n//g; #remove all deflines
    $seq =~ s/\s//g;    #remove all whitespace

    #make sure the sequences are equal
    unless( uc($seq) eq uc($entry->{ORIGIN}) ) {
      push @errors, E_GB_SEQ;
    }
  }

  #now check for the expected TOMGEN tag in the comment field
  my $comment = $entry->{COMMENT};

  #check for the clone name somewhere in the DEFINITION field
  #and keywords ITAG and TOMGEN somewhere in the COMMENT field
  push @errors, E_GB_REC
    unless
      #DEFINITION has either SOL bioinformatics-style clone name or intl clone name
       ( $entry->{DEFINITION} &&
	 ( index($entry->{DEFINITION},$self->clone_object->clone_name_with_chromosome || '') != -1
           || index($entry->{DEFINITION},$self->clone_object->intl_clone_name) != -1
         )
       )
      #COMMENT exists and has TOMGEN keyword in it
      && $comment
      && $comment =~ /\bTOMGEN\b/;


  #if there is an HTGS phase tag, check it against our is_finished;
  if( -r $self->sequences_file ) {
    if ($entry->{KEYWORDS} && $entry->{KEYWORDS} =~ /HTGS_PHASE1/) {
      push @errors, E_GB_PHASE_1 if $self->_seq_looks_finished;
    }
    if (!$entry->{KEYWORDS} || $entry->{KEYWORDS} !~ /HTGS_PHASE[12]/) {
      push @errors, E_GB_PHASE_3 unless $self->_seq_looks_finished;
    }
  }

#  print "is '".$self->clone_object->intl_clone_name."' in:\n$entry->{DEFINITION} ???";


  return @errors;
}

=head2 validation_text

  Usage: my $t = $submission->validation_text
  Desc : Get a string of text suitable for printing informative error
         messages about why a submission is invalid.  If the submission
         is valid, returns undef
  Ret  : a text string, possibly empty
  Args : none
  Side Effects:
  Example:

=cut

sub validation_text {
  my $self = shift;
  my @errors = $self->validation_errors
    or return '';;

  return $self->_err2txt($self->validation_errors);
}
sub _err2txt {
  my $self = shift;
  my $bn = basename($self->_tarfile);
  return join('',( "Problems with submission file $bn:\n",
		   map {my $s=$self->error_string($_); "   - $s\n"} @_,
		 )
	     );
}

=head2 sequences_file

  Usage: my $filename = $submission->sequences_file
  Desc : get the path to this submission's original sequence file.
         NOTE: this is only guaranteed to exist if $this->validation_errors
               returns an empty array (that is, this submission is
               formatted correctly)
  Ret  : string containing the path to this submission's sequence file
  Args : none
  Side Effects: none

=cut

sub sequences_file {
  my $self = shift;
  my $seqfile = File::Spec->catfile( $self->_tempdir,
				     $self->bac_name,
				     $self->bac_name.'.seq'
				   );
  return $seqfile;
}

=head2 sequences_count

  Usage: my $cnt = $submission->sequences_count
  Ret  : number of sequences present in this submission's sequences file
  Args : none

=cut

sub sequences_count {
  my ($self) = @_;

  CORE::open(my $seqs_fh,"<".$self->sequences_file)
      or do { warn "Could not open sequence file ",$self->sequences_file;
	      return 0;
	    };
  my $idents = 0;
  while(my $line = <$seqs_fh>) {
    if(index($line,'>') == 0) {
      $idents++;
    }
  }
  CORE::close $seqs_fh;

  return $idents;
}


=head2 qual_file

  Usage: my $filename = $submission->qual_file
  Desc : get the path to this submission's original qual file
         NOTE: this is only guaranteed to exist if $this->validation_errors
               returns an empty array (that is, this submission is
               formatted correctly)
  Ret  : string containing the path to this submission's qual file
  Args : none
  Side Effects: none

=cut

sub qual_file {
  shift->sequences_file.".qual";
}

=head2 sequences

  Usage: my @seqs = $submission->sequences
  Desc : a list of (renamed) sequences in this submission, or undef
         if the submission is invalid
  Ret  : list of Bio::SeqI objects for the sequences in this submission
  Args : none
  Side Effects: none

=cut

sub sequences {
  my ($self) = @_;

  return _getseqs($self->renamed_sequences_file);
}

sub _getseqs {
  my ($file) = @_;

  my $seqio = Bio::SeqIO->newFh( -file   => $file,
				 -format => 'fasta')
    or confess "Could not open our sequence file for writing!";

  my @seqs = <$seqio>;
  @seqs or confess "We have 0 seqs, but this submission passed validation.  That's not good.";
  return @seqs;
}

=head2 vector_screened_sequences

  Usage: my @vs_seqs = $submission->vector_screened_sequences
  Desc : just like sequences(), but the sequences returned are vector screened
  Ret  : list of Bio::SeqI objects
  Args : none
  Side Effects: none

=cut

sub vector_screened_sequences {
  my ($self) = @_;

  return _getseqs($self->vector_screened_sequences_file);
}



=head2 main_submission_dir

  Usage: my $dirname = $submission->main_submission_dir
  Desc : get the full path to the main submission directory of this bac submission
  Ret  : string containing the path to the main submission directory
  Args : none
  Side Effects: none
  Example:

=cut

sub main_submission_dir {
  my $self = shift;
  return File::Spec->catdir($self->_tempdir,$self->_bacname);
}


=head2 bac_name

  Usage: my $bacname = $submission->bac_name
  Desc : get the properly-formatted BAC name of this submission.
         NOTE: THIS IS ONLY RELIABLE IF THE SUBMISSION VALIDATES
  Ret  : string containing the bac name
  Args : none
  Side Effects: none
  Example:

     NOTE: THIS IS ONLY RELIABLE IF THE SUBMISSION VALIDATES

=cut

sub bac_name {
  shift->_bacname
}

=head2 chromosome_number

  Usage: $submission->chromosome_number(4);
  Desc : get/set the chromosome number for this BAC submission.
  Args : (optional) chromosome number to set, with 0 representing 'unknown'
  Ret  : chromosome number, or 'unmapped' for unmapped chromosome
  Side Effects: renames files in the archive.  DOES NOT alter the contents
                of any files, particularly sequence deflines.  This is fine
                if you're planning on re-publishing this file, since the
                sequence names and deflines are rewritten during the
                publishing process.

                Dies on failure.

  NOTE: THIS IS ONLY GUARANTEED TO WORK IF THE SUBMISSION VALIDATES

=cut

sub chromosome_number {
  my ($self, $new_number) = @_;

  # if we're setting a new number in this tarball
  #warn "got $new_number, ".$self->_chromosome_number;
  my $curr_number = $self->_chromosome_number;
  $curr_number = 0 if lc($curr_number) eq 'unmapped';
  $new_number = 0 if lc($new_number) eq 'unmapped';
  if( defined($new_number)  && $new_number != $curr_number ) {
  # CHANGE:
  #   main submission dir name
  #   names of files in main directory that begin with the clone name

    #warn "OK, renaming";
    my $old_name = $self->bac_name;
    my @things_to_rename =
      (
       # list the files we need to rename, then the main directory
       glob( File::Spec->catfile($self->main_submission_dir, "$old_name*.*") ), #< files
       $self->main_submission_dir, #< main dir
      );

    #warn 'renaming '.Dumper \@things_to_rename;

    my $parsed_name = parse_clone_ident($old_name, 'agi_bac_with_chrom')
      or confess "could not parse current bac name $old_name";
    $parsed_name->{chr} = $new_number;
    my $new_name = assemble_clone_ident(agi_bac_with_chrom => $parsed_name);

    foreach my $thing ( @things_to_rename ) {
      my ($bn,$dir) = fileparse($thing);
      my $newname = $bn;
      $newname =~ s/$old_name/$new_name/;
      $newname = File::Spec->catfile($dir,$newname);
      #warn "mv $thing => $newname\n";
      move( $thing, $newname )
	or confess "$! moving $thing -> $newname\n";
    }

    # rename was successful, now update our internal ideas of our bac
    # name and chromosome number
    $self->_bacname( $new_name );
    $self->_chromosome_number( $new_number || 'unmapped' );
  }

  return $self->_chromosome_number;
}


=head2 sequence_identifier

  Usage: my $vbn = $submission->sequence_identifier
  Desc : get the bac name (with version) for this submission.
         If no version is set, omits the version
  Ret  : the identifier to use for sequence(s) from this BAC
  Args : (optional) fragment number to include in the identifier
  Side Effects: none

=cut

sub sequence_identifier {
  my ($self,$fragnum) = @_;

  #validate the fragment number
  !defined($fragnum)
    or $fragnum > 0
      or croak "Invalid fragment number '$fragnum'";

  #assemble the identifier
  my $parsed_bac_name = parse_clone_ident($self->bac_name,'agi_bac_with_chrom')
    or return $self->bac_name;
  $parsed_bac_name->{version} = $self->version if $self->version;
  $parsed_bac_name->{fragment} = $fragnum if defined $fragnum;

  return assemble_clone_ident(($self->version ? 'versioned_bac_seq' : 'agi_bac_with_chrom'), $parsed_bac_name);
}


=head2 genbank_accession

  Usage: my $gbacc = $submission->genbank_accession
  Desc : get or set a string containing the genbank accession provided
         in this submission tarball, or undef if it does not exist.
         If an unversioned accession is given, will look up the
         accession in GenBank and find the most recent version for it,
         and append that version number.  You can turn off this
         feature by passing a true value as the third argument, in
         which case the unversioned accession will be stored.
  Args : optional new accession to set,
         optional true value to NOT resolve the accessions's version
  Ret  : a string containing the genbank accession, or
         undef if it does not exist
  Side Effects: opens the genbank accession file for
                reading, may look up the sequence's entry in GenBank
                via http, may add the sequence version to the genbank
                accession in the file

=cut

sub genbank_accession {
  my ($self,$acc,$no_version) = @_;

  my $gbfile = File::Spec->catdir($self->main_submission_dir,'gbacc.txt');

  #set a new accession if passed
  _write_acc($gbfile,$acc,$no_version) if defined $acc;

  return unless -f $gbfile;

  my $gbacc = file_contents($gbfile);
  $gbacc =~ s/\s//g;

  croak "'$gbacc' does not look like a valid genbank accession to me"
    unless $gbacc =~ GENBANK_ACC_PATTERN || $gbacc =~ GENBANK_VER_PATTERN;

  #add the sequence version to our genbank accession if it needs it
  unless( $no_version || $gbacc =~ GENBANK_VER_PATTERN ) {
    my $entry = _parsed_gb_entry($gbacc)
      or warn "no entry for $gbacc";
    if($entry && $entry->{VERSION}) {
      my ($seqversion) = split /\s+/,$entry->{VERSION};
      $gbacc = $seqversion;
      _write_acc($gbfile,$gbacc);
    }
  }

  return $gbacc;
}
sub _write_acc {
  my ($file,$acc) = @_;
  CORE::open my $f, ">$file"
      or die "Can't open genbank file '$file' for writing: $!";
  print $f $acc,"\n";
}


=head2 sequencing_info

  Usage: my %info = $submission->sequencing_info
  Desc : get information about this submission's sequencing, if present.
         if an upload_account_name and/or sp_organization_id is given,
         write it to the sequencing_info.txt file in this submission
  Args : zero or more of
           org_upload_account_name => string,
           org_shortname => shortname of organization
           org_sp_organization_id => sgn_people.sp_organization.sp_organization_id
                                 of the organization to set info for
  Ret  : hash-style list of what information is known about the sequencer,
         as:
          (
            org_upload_account_name => system account name under which
                                       this was uploaded,
            org_shortname           => sgn_people.sp_organization.shortname
                                       for this organization,

            in addition, other key-value pairs may be present
          )
  Side Effects: dies on error

=cut

sub sequencing_info {
  my ($self,%args) = @_;

  #warn "sequencing_info called with ".Dumper \%args;

  #if we got args, check them and write the sequencing info file
  if( %args ) {

    my %writable_args = %args; #< set of sequencer info we can write
                               # to the file, which is everything
                               # except the organization ID, cause that
                               # could change with different databases
    delete $writable_args{org_sp_organization_id};

    do {
      CORE::open my $si, '>', $self->_seqinfo_filename
	  or confess "$! opening ".$self->_seqinfo_filename;
      #warn "1 writing to ".$self->_seqinfo_filename;
      while( my ($k,$v) = each %writable_args ) {
	print $si "$k\t$v\n";
      }
      CORE::close $si;
      #warn "1 done writing ".$self->_seqinfo_filename;
    };

    #now check which matches we might have
    my @orgs = $self->sequencing_possible_orgs(%args);
    if( @orgs == 1 ) {
      # if we have just one possible organization this should match,
      # rewrite the file with what's in the database for that
      # organization rewrite our info file with the info that's in the
      # only matching

      CORE::open my $si, '>', $self->_seqinfo_filename
	  or confess "$! opening ".$self->_seqinfo_filename;
      %writable_args = %{$orgs[0]};
      delete $writable_args{org_sp_organization_id};
      #warn "2 writing to ".$self->_seqinfo_filename;
      while( my ($k,$v) = each %writable_args ) {
	print $si "$k\t$v\n" if defined $v;
      }
      CORE::close $si;
      #warn "2 done writing ".$self->_seqinfo_filename;
    }
  }
#   else {
#       warn "skipping write";
#   }
  #/ finished handling args

  #now parse the seq info file and return it
  return $self->_parsed_seqinfo_file;
}

#return hash-style list from parsing the sequencing_info.txt file,
#takes optional arrayref to push errors onto if you're interested
sub _parsed_seqinfo_file {
  my ($self,$errors) = @_;

  $errors ||= [];

  #if we have no file, just return nothing
  return unless -f $self->_seqinfo_filename;

  my @disallowed_keys =  qw/org_sp_organization_id sp_organization_id/;

  my %info;
  CORE::open my $si, $self->_seqinfo_filename
    or confess "$! opening ".$self->_seqinfo_filename;
  while(my $line = <$si>) {
    next unless $line =~ /\S/; #< skip blank lines
    next if $line =~ /^\s*#/; #< skip comments
    chomp $line;
    my ($key,$value) = split /\t/,$line;
    if( $key =~ /\s/ || str_in($key,@disallowed_keys ) ) {
      push @$errors, "invalid key $key in sequencing_info.txt for ".$self->_tarfile;
    }
    elsif( $key eq 'org_shortname' ) {
      #check that this is a valid shortname
      our $shortname_list ||= CXGN::Genomic::Clone->db_Main->selectcol_arrayref('select shortname from sgn_people.sp_organization where shortname is not null');
      str_in($value,@$shortname_list)
	or push @$errors, "unknown organization shortname '$value' in sequencing_info.txt for ".$self->_tarfile;
    }
	
    $info{$key} = $value;
  }
  lock_hash(%info);
  return %info;
}

=head2 sequencing_possible_orgs

  Usage: my @orgs = $submission->sequencing_possible_orgs
  Desc : look up which organizations match the sequencer info
         attached to this submission.  should be just one in most
         cases
  Args : optional hash-style list of additional key-value pairs to filter for
  Ret  : list of hashrefs, each of which contains as organization that
         could have been the sequencer of this submission, based
         on what info is found in the sequencing_info.txt file in the
         submission
  Side Effects: dies on error

=cut

sub sequencing_possible_orgs {
  my ($self, %additional) = @_;

  #convert an exec'd sth into a list of hashrefs
  sub _hashall {
    my $sth = shift;
    my @hashes;
    while( my $h = $sth->fetchrow_hashref ) {
      my $new_h = {};
      while(my ($k,$v) = each %$h) {
	#add an org_ to the beginning of each column name,
	#and don't include undefined values
	if( defined $v ) {
	  $new_h->{"org_$k"} = $v;
	}
      }
      push @hashes, $new_h;
    }
    return @hashes;
  }

  #look up orgs based on our sequencing_info
  my %info = $self->sequencing_info;
  #merge in the additional info, but don't override anything already set
  while(my ($k,$v) = each %additional) {
    $info{$k} = $v unless defined $info{$k};
  }
#  use Data::Dumper;
#  warn "got info ".Dumper(\%info);

  my @lookup_keys = qw/ org_upload_account_name org_shortname /; #< list of keys that are also organization column names
  my %lookup_info = map {
    my $k = $_;
    my $v = $info{$_};
    $k =~ s/^org_//;
    $k => $v
  }
    grep $info{$_}, @lookup_keys;

  if( %lookup_info ) {
#    warn "got info ".Dumper \%info;
    my $where = join ' AND ', map { "$_ = ?"} keys %lookup_info;
    my $orgs_sth = CXGN::Genomic::Clone->db_Main->prepare_cached(<<EOSQL);
select * from sgn_people.sp_organization
where $where
EOSQL
    #warn "executing with ".join(',',values %lookup_info);
    $orgs_sth->execute(values %lookup_info);
    return _hashall($orgs_sth);
  } else {
    my $orgs_sth = CXGN::Genomic::Clone->db_Main->prepare_cached(<<EOSQL);
select * from sgn_people.sp_organization
EOSQL
    $orgs_sth->execute;
    return _hashall($orgs_sth);
  }
}

sub _seqinfo_filename {
  my ($self) = @_;
  return File::Spec->catfile( $self->main_submission_dir, 'sequencing_info.txt');
}


=head2 clone_object

  Usage: my $clone = $submission->clone_object
  Desc : get the CXGN::Genomic::Clone object corresponding to this BAC
         submission, gets info from the database
         NOTE: THIS IS ONLY RELIABLE IF THE SUBMISSION VALIDATES
  Ret  : the clone object, or undef if it could not be found
  Args : none
  Side Effects: none

=cut

sub clone_object {
  my ($self) = @_;

  #parse this submission's BAC name
  my $parsed_name = parse_clone_ident( $self->bac_name, 'agi_bac_with_chrom' )
    or return;

  return CXGN::Genomic::Clone->retrieve_from_parsed_name($parsed_name);
}

=head2 tar_file

  Usage: my $submission = BACSubmission->open($tarfile);
         $submission->tar_file eq $tarfile or die 'something is wrong';
  Desc : get the full path to the original tar file for this submission
  Ret  : string containing the path to the tar file
  Args : none
  Side Effects: none

=cut

sub tar_file {
  shift->_tarfile
}

=head2 is_finished

  Usage: print "it's got only one sequence!" if $submission->is_finished;
  Desc : returns true if this submission appears to contain a finished sequence,
         that is, if its primary sequence file contains only one sequence and
         that sequence does not contain any N's
         NOTE: THIS IS ONLY RELIABLE IF THE SUBMISSION VALIDATES
  Ret  : 1 if it seems to be finished, undef if not
  Args : none
  Side Effects: none
  Example:

=cut

sub is_finished {
  my $self = shift;

  return 0 unless $self->_seq_looks_finished;

  my $p = $self->_genbank_reported_phase;
  return 0 if $p && $p < 3; #no Ns or mult idents, but genbank phase is 1 or 2

  return 1; #not reported unfinished in genbank, and doesn't look
            #obviously unfinished
}

#return 1 if the sequence in this submission looks finished.
#must have only one sequence, and no Ns in the sequence
sub _seq_looks_finished {
  my ($self) = @_;

  CORE::open(my $seqs_fh,"<".$self->sequences_file)
      or do { warn "Could not open sequence file ",$self->sequences_file;
	      return 0;
	    };
  my $idents = 0;
  while(my $line = <$seqs_fh>) {
    if(index($line,'>') == 0) {
      $idents++;
    } elsif( $line =~ /N/) {
      return 0;
    }
  }
  CORE::close $seqs_fh;

  return 0 if $idents > 1; #definitely not finished if mult. idents

  return 1;
}

=head2 htgs_phase

  Usage: my $phase = $sub->htgs_phase
  Desc : get the HTGS phase of this submission.  For a definition of HTGS phases,
         see L<http://www.ncbi.nlm.nih.gov/HTGS/faq.html>

         NOTE: THIS IS ONLY RELIABLE IF THE SUBMISSION VALIDATES
  Args : none
  Ret  : a number, either 1, 2, or 3
  Side Effects: none

=cut

sub htgs_phase {
  my ($self) = @_;

  my $p = $self->_genbank_reported_phase;

  return $p || ( $self->is_finished ? 2 : 1 ); #must assume unordered unless the
                                               #genbank entry tells us it's
                                               #ordered
}

sub _genbank_reported_phase {
  my ($self) = @_;

  my $gbrec = $self->parsed_genbank_record
    or return;

  return $1 if $gbrec->{KEYWORDS} && $gbrec->{KEYWORDS} =~ /HTGS_PHASE([123])/;

  return 3;
}


#the filename prefix that precedes all files generated by this object
sub _generated_file_prefix {
  'temp-cxgn-bac-submit'
}

#central place where the names of all of the files we generate are kept
#returns a hashref of names
sub generated_file_names {
  my $self = shift;
  shift and croak 'generated_file_names takes no arguments';

  my $prefix = $self->_generated_file_prefix;
  my $bacname = $self->bac_name || 'unknown_bac';
  my %names = (
	       #basic submission files
	        renamed_seqs          => File::Spec->catfile($self->_tempdir,"$prefix-renamed.seq"),
		vector_screened_seqs  => $self->sequences_file.'.screen',
		new_tarfile           => File::Spec->catfile($self->_tempdir,"$bacname.tar.gz"),
	        genbank_htgs          => File::Spec->catfile($self->_tempdir,"$prefix-genbank-submission.htgs"),
		cross_match_output    => File::Spec->catfile($self->_tempdir,"$prefix-crossmatch-output.txt"),
		cross_match_err       => File::Spec->catfile($self->_tempdir,"$prefix-crossmatch.err"),
		vector_seq            => File::Spec->catfile($self->_tempdir,"$prefix-vector.seq"),

	       #merged annotation files
		merged_game_xml       => File::Spec->catfile($self->_tempdir,$self->bac_name.".all.xml"),
		merged_gff3           => File::Spec->catfile($self->_tempdir,$self->bac_name.".all.gff3"),

	      );

  return \%names;
}


=head2 submitters

  Usage: my @addresses = $sub->submitters
  Desc : get the email addresses of the probable submitter contact for
         this BAC, uses the bac_contacts_chr_* CXGN configuration
         variables
  Args : none
  Ret  : possibly empty list of
        { name => full name, email => email address}, {...}, ...
  Side Effects: none

=cut

sub submitters {
  my ($self) = @_;


#   # does it have project info already in the database?  that's the most
#   # reliable information


#   # otherwise, is our tarfile in a country_upload directory?  that's
#   # a very good indication
#   my (undef,$dir,undef) = File::Spec->splitpath($self->_tarfile_dir, 'no_file' );
#   my @dirs = File::Spec->splitdir( $dirs );
#   my $country_dir = '';
#   $country_dir = pop @dirs while $dirs[-1] ne 'country_uploads';
#   if( $dirs[-1] eq 'country_uploads' ) {
#       # at this point, $country_dir will be 'korea' or something like that
#   }

  # otherwise, look at its chromosome number and try to guess the
  # submitter from that
  my $chr = $self->chromosome_number
      or return;
  $chr = 0 if $chr eq 'unmapped';
  my $conf_var_name = 'bac_contacts_chr_'.($chr+0);
  my $submitters_string = join ' ',@{CXGN::TomatoGenome::Config->load_locked->{$conf_var_name}}
      or return;

  return map _parse_submitter($_), split /,/,$submitters_string;
}
sub _parse_submitter {
  my ($str) = @_;
  #warn "parsing '$str'\n";
  my ($email,$name) = do {
    if( $str =~ /</ ) {
      reverse split /\s*[<>]\s*/,$str;
    } else {
      $str
    }
  };

  $name =~ s/"|^\s+|\s+$//g if $name;
  croak "invalid email address '$email'" unless $email =~ /@/;

  return { email => $email, name => $name || ''};
}


###
1;#do not remove
###


# BEGIN_SKIP_FOR_PORTABLE_VALIDATION (do not remove or change this line, it's used by automated scripts)
##############################################################################
##############################################################################
#######################     BAC SUBMISSION ANALYSIS   ########################
##############################################################################
##############################################################################


########### ADD NEW ANALYSIS DOWN HERE ####################

=head1 AVAILABLE ANALYSES

=cut

#### TO ADD A NEW ANALYSIS
# 1. make a new analysis package under CXGN::TomatoGenome::BACSubmission::Analysis::*
# 2. fill in its run() subroutine
# 3. optionally, fill in its check_ok_to_run() subroutine

