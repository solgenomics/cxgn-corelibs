

=head2 Cross_match_vector

  Parses the cross_match vector screen results into annotations.

  Secondary input parameters:
     none

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::Cross_match_vector;
use English;
use POSIX;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis';
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;

__PACKAGE__->run_for_new_submission(1);

sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  my ($outfile,$errfile,$gff3_file,$game_xml_file) =
    map { $self->analysis_generated_file($submission,$_) }
      qw/out err gff3 game_xml/;

  system "touch $outfile $errfile $gff3_file $game_xml_file";

  open my $out_fh, '>', $outfile
    or die "Could not open '$outfile' for writing: $!";
  my $gff3_out = $submission->_open_gff3_out($gff3_file);

  #go through each sequence, find the X's, and make features where the
  #vector probably is
  my @vector_features;
  foreach my $seq ($submission->vector_screened_sequences) {
    my $seq_string = $seq->seq;
    print $out_fh $seq->primary_id.": sequence length is ".length($seq_string)." bases\n";
    while($seq_string =~ /X+/g) {
      my $end = pos($seq_string);
      my $start = $end - length($MATCH) + 1;
      my $vector_name = $submission->clone_object->library_object->cloning_vector_object->name;
      print $out_fh $seq->primary_id.": cross_match masked $vector_name vector sequence from base $start to base $end\n";
      my $feat = $self->new_feature( -start  => $start,
				     -end    => $end,
				     -type   => 'match',
				     -seq_id => $seq->primary_id,
				     -source => $self->analysis_name,
				     -annots => {ID => $self->_unique_bio_annotation_id("${vector_name}_vector_match")},
				   );
      $gff3_out->write_feature($feat);
    }
  }

  $gff3_out = undef; #make sure to close the gff3 output

  if ($submission->is_finished) {
    gff_to_game_xml($submission->vector_screened_sequences_file,
		    $gff3_file,
		    $game_xml_file,
		    program_name   => $self->analysis_name,
		    program_date   => asctime(gmtime).' GMT',
		    database_name  => 'vector sequence',
		    gff_version    => 3,
		   );
  } else {
    $submission->_write_unfinished_bac_xml_stub($game_xml_file);
  }

  #return the result files
  return ($game_xml_file, $gff3_file, $outfile);
}



1;


