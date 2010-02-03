
=head2 Contigs

  Annotates contigs in the sequence.

  Secondary input parameters:
     none

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::Contigs;
use English;
use POSIX;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis';
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;

__PACKAGE__->run_for_new_submission(1);

sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  my ($gff3_file,$game_xml_file) =
    map { $self->analysis_generated_file($submission,$_) }
      qw/gff3 game_xml/;

  system "touch $gff3_file $game_xml_file";

  unless( $submission->is_finished ) {
    my @seqs = $submission->sequences;

    #don't do this unless it's an N-gapped sequence
    last unless @seqs == 1;

    my @chunks = split /(?<=N)(?=[^N])|(?<=[^N])(?=N)/, $seqs[0]->seq;

    my @contigs;
    my $curr_offset = 1;
    foreach (@chunks) {
      unless( /N/ ) {
	push @contigs, [$curr_offset,$curr_offset+length($_)-1];
      }
      $curr_offset += length($_);
    }

    my ($seqname,$seqlength) = ( $seqs[0]->display_id, $seqs[0]->length );
    open my $gff3, '>', $gff3_file or die "$! writing to $gff3_file";
    print $gff3 "##gff-version 3\n##sequence-region $seqname 1 $seqlength\n";
    my $ctr = 0;
    foreach my $contig (@contigs) {
      my $len = $contig->[1]-$contig->[0]+1;
      print $gff3 join( "\t", ( $seqname, $self->analysis_name, 'contig', @$contig, '.', '.', 0, 'ID=contig'.++$ctr.";length=$len") )."\n";
    }
    close $gff3;

  }

  #make a game-xml file
  gff_to_game_xml($submission->vector_screened_sequences_file,
		  $gff3_file,
		  $game_xml_file,
		  program_name   => $self->analysis_name,
		  program_date   => asctime(gmtime).' GMT',
		  gff_version    => 3,
		 );

  #return the result files
  return ($game_xml_file, $gff3_file);
}


1;
