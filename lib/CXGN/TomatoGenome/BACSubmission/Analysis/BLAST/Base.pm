package CXGN::TomatoGenome::BACSubmission::Analysis::BLAST::Base;
use base qw/CXGN::TomatoGenome::BACSubmission::Analysis/;
use Carp;
use English;
use File::Spec;
use File::Basename;
use POSIX;

use CXGN::BlastDB;

use CXGN::Tools::File qw/ executable_is_in_path file_contents /;
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;


sub list_params {
  return ( blastall_binary => 'optional full path to blastall executable',
	 );
}

sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  #find all the various files we need
  my $executable = find_blastall($aux_inputs);
  my $vector_screened_seqs = $submission->vector_screened_sequences_file;
  my @fileset = $self->_fileset($aux_inputs);
  my ($bdb) = CXGN::BlastDB->search(file_base => $fileset[0])
    or croak "Cannot find blastdb with file_base '$fileset[0]'.  Is it in the ".CXGN::BlastDB->table." table?";

  my ($outfile,$errfile,$gff3_file,$game_xml_file) =
    map { $self->analysis_generated_file($submission,$_) }
      qw/out err gff3 game_xml/;
  my $tempdir = $submission->_tempdir;
  -w $tempdir or confess "Cannot write to temp dir '$tempdir'";

  unless($ENV{CXGNBACSUBMISSIONFAKEANNOT}) {
    my $unsorted_out = File::Spec->catfile($tempdir,'blast_out_unsorted');

    CXGN::Tools::Run->run( $executable,
			   -i => $vector_screened_seqs,
			   -d => $bdb->full_file_basename,
			   $self->_blastparams,
			   -m => 8,
			   { working_dir => $tempdir,
			     out_file    => $unsorted_out,
			     err_file    => $errfile,
			   }
			 );

    #sort the blast m8 output
    #    warn "sorting blast output...\n";
    CXGN::Tools::Run->run( 'sort', $unsorted_out, { out_file => $outfile } );

    #convert the blast report to gff3
    $self->_write_gff3( $submission, $outfile, $gff3_file );

    #convert the GFF3 to GAME XML if this is a finished bac
    if( $submission->is_finished ) {
      gff_to_game_xml($vector_screened_seqs, $gff3_file, $game_xml_file,
		      program_name   => $self->analysis_name,
		      program_date   => asctime(gmtime).' GMT',
		      database_name  => $bdb->title,
		      database_date  => $bdb->format_time,
		      gff_version    => 3,
		     );
    }
    else {
      $submission->_write_unfinished_bac_xml_stub($game_xml_file);
    }
  } else {
    warn "look at me, I'm not really running BLAST\n";
    `touch $game_xml_file $outfile $gff3_file`;
  }

  #return the result files
  return ($game_xml_file, $gff3_file, $outfile);
}

sub _write_gff3 {
  my ($self,$submission,$outfile, $gff3_file) = @_;
  open my $out_fh, '<', $outfile or die "Could not open blast output file $outfile: $!";
  my $fo = $submission->_open_gff3_out($gff3_file);
  while (my $line = <$out_fh> ) {
    next if $line =~ /^\#/ || $line =~ /^\s+$/;
    next unless $self->_use_line($line);
    my $feature = $self->_line_to_feature($line);
    $fo->write_feature( $feature );
  }
}

sub _line_to_feature {
  my ($self,$line) = @_;

  my @fields = my ($qname,$hname, $percent_id, $hsp_len, $mismatches,$gapsm,
		   $qstart,$qend,$hstart,$hend,$evalue,$bits) = split /\s+/,$line;
  my $fwdrev = $hstart >= $hend ? 'rev' : 'fwd';
  #	   my $plusminus = $hstart >= $hend ? '-' : '+';
  return $self->new_feature( -start => $qstart,
				    -end   => $qend,
				    -score => $bits,
				    -type  => $self->_feature_type(\@fields),
				    -source => $self->analysis_name,
				    -seq_id => $qname,
				    -target => { -start => $hstart,
						 -end   => $hend,
						 -target_id => $self->_target_name($hname),
					       },
				    -annots => { ID => $self->_unique_bio_annotation_id("${hname}_${fwdrev}_alignment"),
						 blast_percent_identity => $percent_id,
						 blast_mismatches => $mismatches,
						 blast_gaps => $gapsm,
						 blast_evalue => $evalue,
						 blast_match_length => $qend-$qstart,
					       },
				  );

}

#hook for changing the target names that are used.  takes hit target
# name, returns the name as it should appear in the GFF3 Target this
# one doesn't change it, but some of the subclasses might override
# this to change it
sub _target_name {
  my ($self,$tgt) = @_;
  return $tgt;
}

# hook for changing the types of features.  gets passed an arrayref containing the m8 fields
sub _feature_type {
  'match'
}

#figure out where our blastall executable is
sub find_blastall {
  my $aux = shift;

  return ($aux->{blastall_binary} && -x $aux->{blastall_binary})
      || (executable_is_in_path 'blastall' && 'blastall')
      || croak 'Cannot find blastall binary';
}

sub check_ok_to_run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  no warnings;

  croak "Could not find blastall executable.  Do you need to set the 'blastall_binary' analysis option?"
    unless find_blastall($aux_inputs);

  my @fileset = $self->_fileset($aux_inputs,$submission);

  my ($bdb) = CXGN::BlastDB->search(file_base => $fileset[0]);

  croak "Specified blast database '$fileset[0]' could not be found or was not readable"
    unless $bdb;

  return 1;
}

sub _fileset {
  my ($self,$aux_inputs) = @_;
  croak "not implemented";
}
sub _blastparams {
  -e => '1e-10', -p => 'blastn'
}
sub _use_line {
  1;
}


1;


