=head2 AUGUSTUS

  Secondary input parameters:
    none yet

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::AUGUSTUS::Base;

use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;

use Carp;
use English;

use POSIX;

use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;

use CXGN::Tools::File qw/executable_is_in_path/;

__PACKAGE__->run_for_new_submission(0);

sub list_params {
  return ( augustus_exec   => 'optional full path to augustus executable',
	   blat_exec       => 'optional full path to blat executable',
	   blat2hints_exec => 'optional full path to the augustus blat2hints.pl script',
	 );
}

sub _get_cdna_seqs_file {
  die 'not implemented in superclass';
}

sub run {
  my ($self,$submission,$aux_inputs) = @_;

  my ($blat,$augustus,$blat2hints) = find_executables($aux_inputs);
  my @outfiles = 
    my ($game_xml_file,$gff3_file,$hints_psl,$hints_gff) =
      map { $self->analysis_generated_file($submission,$_) }
	qw/game_xml gff3 hints.psl hints.gff/;

  unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {

    #prepare our input sequence, with no defline
    my $rm_seqs_with_no_defline = $self->_remove_defline($submission,$submission->repeat_masked_sequences_file);

    my @hints_arg = do {
      #get our cDNA set, run BLAT on it against this sequence into a
      #tempfile, and generate augustus hints with it
      if( my $cdna_file = $self->_get_cdna_seqs_file($aux_inputs) ) {

	#symlink the cdna file into our submission's temp dir
	my $local_name = File::Spec->catfile( $submission->_tempdir, 'augustus_cdna_file'.ref($self));
	symlink( $cdna_file, $local_name )
	  or die "$! symlinking '$local_name' -> '$cdna_file'";
	
	my $blat = CXGN::Tools::Run->run( $blat,
					  '-minIdentity=92',
					  $submission->repeat_masked_sequences_file,
					  $local_name,
					  $hints_psl,
					);
	my $gen_hints = CXGN::Tools::Run->run( $blat2hints,
					       "--in=$hints_psl",
					       "--out=$hints_gff",
					     );
	("--hintsfile=$hints_gff")
      } else {
	#take the hints files out of the output files array
	@outfiles = @outfiles[0,1];
	#and return an empty array so no hints argument will be passed
	()
      }
    };
    my $tempgff3 = $self->analysis_generated_file($submission,'tempgff3');
    my $augustus = CXGN::Tools::Run->run( $augustus,
					  '--species=tomato',
					  @hints_arg,
					  '--extrinsicCfgFile=extrinsic.ME.cfg',
					  '--gff3=on',
					  $rm_seqs_with_no_defline,
					  { out_file => $tempgff3 }
					);

    #now filter the augustus gene separator comments
    $self->_filter_augustus_gff3( $tempgff3, $gff3_file );

    #convert the gff3 to gamexml
    gff_to_game_xml($submission->repeat_masked_sequences_file,
		    $gff3_file,
		    $game_xml_file,
		    program_name   => $self->analysis_name,
		    program_date   => asctime(gmtime).' GMT',
		    database_name  => 'de novo',
		    gff_version    => 3,
		    render_as_annotation => 0,
		   );
  } else {
    warn "look at me, I'm not really running ".$self->analysis_name."\n";
    system 'touch', @outfiles;
  }
  return @outfiles;
}

sub _remove_defline {
  my ($self,$submission,$seq_file) = @_;

  my $temp_seq = $self->analysis_generated_file( $submission, 'seq_with_defline_removed');

  my $aname = $self->analysis_name;

  #preprocess the seq file to remove the defline, since augustus puts it in the output if we don't
  open my $seq_in, '<', $seq_file or die "$! opening '$seq_file'";
  open my $temp_seq_out, '>', $temp_seq or die "$! opening $temp_seq for writing\n";
  while(<$seq_in>) {
    s/(>\S+).+/$1/ if />/;
    print $temp_seq_out $_;
  }
  close $temp_seq_out;
  close $seq_in;

  return $temp_seq;
}

sub _filter_augustus_gff3 {
  my ($self,$temp_gff,$gff_out) = @_;

  my $aname = $self->analysis_name;

  #convert the dirty gff3 to valid gff3
  do {
    open my $gff_in, '<', $temp_gff or die "$! opening $temp_gff";
    open my $gff_out, '>', $gff_out or die "$! opening $gff_out for writing";
    while(<$gff_in>) {	
      next if /\tb2h\t/;
      $_ = "###\n" if /^###/;
      s/\tAUGUSTUS\t/\t${aname}\t/;
      print $gff_out $_;
    }
    close $gff_in;
    close $gff_out;
  };
  return $gff_out;
}

#figure out where our blastall executable is
sub find_executables {
  my $aux = shift;

  return ( ( ($aux->{blat_exec} && -x $aux->{blat_exec})
	     || (executable_is_in_path 'blat' && 'blat')
	     || croak 'Cannot find blat executable',
	   ),

	   ( ($aux->{augustus_exec} && -x $aux->{augustus_exec})
	     || (executable_is_in_path 'augustus' && 'augustus')
	     || croak 'Cannot find augustus executable',
	   ),

	   ( ($aux->{blat2hints_exec} && -x $aux->{blat2hints_exec})
	     || -x '/usr/share/augustus/scripts/blat2hints.pl' && '/usr/share/augustus/scripts/blat2hints.pl'
	     || croak 'Cannot find augustus blast2hints.pl script'
	   ),
	 );
}


sub check_ok_to_run {
  my ($self,$submission,$aux) = @_;
  my ($blat,$augustus,$blat2hints) = find_executables($aux);
  return 1;
}


1;

