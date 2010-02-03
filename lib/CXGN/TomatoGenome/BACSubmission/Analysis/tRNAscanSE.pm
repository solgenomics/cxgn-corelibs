=head2 tRNAscanSE

  Secondary input parameters:
    trnascanse_binary   - (optional) full path to tRNAscan-SE executable

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::tRNAscanSE;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;
use Carp;
use English;
use File::Spec;
use File::Basename;

use POSIX;

use Bio::Tools::tRNAscanSE;

use CXGN::Tools::File qw/ executable_is_in_path file_contents /;
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;


__PACKAGE__->run_for_new_submission(1); #set this to be run on new BAC submissions

sub list_params {
  return ( trnascanse_binary => 'optional full path to tRNAscan-SE executable',
	 );
}

sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  #find all the various files we need
  my $executable = find_trnascanse($aux_inputs);
  my $vector_screened_seqs = $submission->vector_screened_sequences_file;
  my ($outfile,$errfile,$gff3_file,$game_xml_file) =
    map { $self->analysis_generated_file($submission,$_) }
      qw/out err gff3 game_xml/;
  my $tempdir = $submission->_tempdir;
  -w $tempdir or confess "Cannot write to temp dir '$tempdir'";

  unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
    my $run = CXGN::Tools::Run->run( $executable,
				     $vector_screened_seqs,
				     { working_dir => $tempdir,
				       out_file    => $outfile,
				       err_file    => $errfile,
				     }
				   );
    #convert the output to gff3
    do { my $fi = Bio::Tools::tRNAscanSE->new(-file => $outfile);
	 my $fo = $submission->_open_gff3_out($gff3_file);
	 while (my $feature = $fi->next_prediction() ) {
	   $feature->primary_tag('tRNA');
	   my $f = Bio::SeqFeature::Annotated->new( -feature => $feature );
	   $fo->write_feature( $f );
	 }
       };

    #convert the GFF3 to GAME XML if this is a finished bac
    if( $submission->is_finished ) {
      gff_to_game_xml($vector_screened_seqs, $gff3_file, $game_xml_file,
		      program_name   => 'tRNAscan-SE',
		      program_date   => asctime(gmtime).' GMT',
		      gff_version    => 3,
		     );
    }
    else {
      $submission->_write_unfinished_bac_xml_stub($game_xml_file);
    }
  } else {
    warn "look at me, I'm not really running tRNAscan-SE\n";
    `touch $game_xml_file $outfile $gff3_file`;
  }

  #return the result files
  return ($game_xml_file, $gff3_file, $outfile);
}

#figure out where our geneseqer executable is
sub find_trnascanse {
  my $aux = shift;

  return ($aux->{trnascanse_binary} && -x $aux->{trnascanse_binary})
      || (executable_is_in_path 'tRNAscan-SE' && 'tRNAscan-SE')
      || croak 'Cannot find tRNAscan-SE binary';
}

sub check_ok_to_run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  no warnings;

  croak "Could not find tRNAscan-SE executable.  Do you need to set the 'trnascanse_binary' analysis option?"
    unless find_trnascanse($aux_inputs);

  return 1;
}


1;


