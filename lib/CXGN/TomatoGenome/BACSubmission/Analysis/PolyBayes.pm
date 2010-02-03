
=head2 PolyBayes

  Annotates candidate SNPs in the sequence.  Only works if the
  submission has a .qual file to match its .seq file.

  Secondary input parameters:
     none

=cut

package CXGN::TomatoGenome::BACSubmission::Analysis::PolyBayes;
use English;
use POSIX;
use base 'CXGN::TomatoGenome::BACSubmission::Analysis';
use CXGN::TomatoGenome::BACPublish qw/publishing_locations publisher/;
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;

use CXGN::CDBI::SGN::Unigene;

use CXGN::Tools::List qw/distinct/;

use Data::Dumper;

__PACKAGE__->run_for_new_submission(1);


sub run {
  my $self = shift;
  my $submission = shift; #BACSubmission object
  my $aux_inputs = shift; #hash ref of auxiliary inputs

  # open the output files, which will stay empty until we fill them.  we might quit prematurely due to an error condition
  my ($gamexml_out,$gff3_out,$pb_out,$pb_align_gz,$pb_ace_gz) =
    my @analysis_output_files =
      map File::Spec->catfile( $submission->_tempdir, 'polybayes_analysis'.$_ ),
	qw/ .xml .gff3 .out .align.gz .ace.gz/;

  # un-gzipped .align tempfile
  my ($pb_align,$pb_ace) = map File::Spec->catfile( $submission->_tempdir, $_), 'pb.align', 'pb.ace';

  { # write stub output files, in case this BAC doesn't get analyzed

    open my $f, '>', $_
      for $pb_out, $pb_align, $pb_ace;

    my $fio = $submission->_open_gff3_out($gff3_out);
    gff_to_game_xml($submission->vector_screened_sequences_file,
		    $gff3_out,
		    $gamexml_out,
		    program_name   => $self->analysis_name,
		    program_date   => asctime(gmtime).' GMT',
		    gff_version    => 3,
		   );

    # now gzip the stub .align and .ace output files
    foreach ( [$pb_align => $pb_align_gz], [$pb_ace => $pb_ace_gz] ) {
      my $gz = CXGN::Tools::Run->run( 'gzip',
                                      -c =>
                                      $_->[0],
                                      { out_file => $_->[1] }
                                    );
    }
  }

  #we must have a qual file for this analysis
  unless( -f $submission->qual_file ) {
    warn "WARNING: ".$submission->sequence_identifier." has no main .qual file, cannot run PolyBayes analysis";
    return @analysis_output_files;
  }

  # look up which tomato unigenes align to this BAC
  my $gth_sgnu_tomato_gff3 = do {
      my (undef,$gff3) = $submission->analyze_with('GenomeThreader_SGN_U_tomato');
      $gff3
  };
  my @unigene_list;
  open my $gff3, '<', $gth_sgnu_tomato_gff3 or die "$! reading from $gth_sgnu_tomato_gff3";
  while( <$gff3> ) {
    my ($ug) = /ID=SGN-U(\d+)/;
    push @unigene_list,$ug if $ug;
  }

  #we must have a qual file for this analysis
  unless( @unigene_list ) {
    warn "WARNING: ".$submission->sequence_identifier." has no unigene alignments, cannot run PolyBayes analysis";
    return @analysis_output_files;
  }

  #print "for ".$submission->sequence_identifier.", got unigenes:\n";
  #print map "$_\n",sort keys %unigene_list;

  my %est_accessions; #< hash to store the accession name of each EST

  #get the ESTs sequences and quals, put them in tempfiles
  my $est_seqs_file = File::Spec->catfile( $submission->_tempdir, 'pb_ests.seq' );
  open my $seqs, '>', $est_seqs_file or die "$! writing $est_seqs_file";
  my $est_qual_file = File::Spec->catfile( $submission->_tempdir, 'pb_ests.seq.qual' );
  open my $qual, '>', $est_qual_file or die "$! writing $est_qual_file";
  my $base_pos_file = File::Spec->catfile( $submission->_tempdir, 'pb_ests.seq.bpos' );
  open my $pos, '>', $base_pos_file or die "$! writing $base_pos_file";

  #for each one
  foreach my $ug_id (distinct @unigene_list) {
    my $ug_obj = CXGN::CDBI::SGN::Unigene->retrieve($ug_id)
      or die "unknown unigene id $ug_id!\n";
    #get its member ESTs
    my @member_ests = map $_->est_id, $ug_obj->members;
    next unless @member_ests > 1;

    # look up the accession name for each EST
    foreach my $est ( @member_ests ) {

      my $eid = $est->est_id;
      $est_accessions{'SGN-E'.$eid} ||= do {
	my ($accession) =  CXGN::CDBI::SGN::Unigene->db_Main->selectrow_array('select l.accession from sgn.est e join sgn.seqread r using(read_id) join sgn.clone c using(clone_id) join sgn.library l using(library_id) where e.est_id = ? limit 1',undef,$eid);
	$accession
      };

      print $seqs ">SGN-E".$est->est_id."\n".$est->seq."\n";
      print $qual ">SGN-E".$est->est_id."\n".$est->qscore."\n";

      if( $est->call_positions ) {
	print $pos ">SGN-E".$est->est_id."\n".$est->call_positions."\n";
      }

    }
  }

  close $_ for $seqs, $qual, $pos;


    #system "cat $est_seqs_file $est_qual_file $base_pos_file";

  #generate discrepancy lists with cross_match, needed by polybayes
  my $cm = CXGN::Tools::Run->run('cross_match',
				 -discrep_lists =>
				 -tags =>
				 -masklevel => 5,
				 $est_seqs_file,
				 $submission->sequences_file,
				);

  #### run polybayes on them to look for SNPs

  my $pb = CXGN::Tools::Run->run(
				 'polybayes.pl',
				 -project => 'cxgnbacpipeline',
				 -analysis => 'polybayes-snps',,
				 #-cluster => 'SGN-U'.$ug_id,
				 -inputFormat => 'map',
				 -anchorDna => $submission->sequences_file,
				 -anchorBaseQuality => $submission->qual_file,
				 -memberDna => $est_seqs_file,
				 -memberBaseQuality => $est_qual_file,
				 -memberBasePosition => $base_pos_file,
				 -crossMatch => $cm->out_file,
				 -anchorBaseQualityDefault => 40,
				 -memberBaseQualityDefault => 20,
				 -maskAmbiguousMatches =>
				 -filterParalogs =>
				 -paralogFilterMinimumBaseQuality => 12,
				 -priorParalog => 0.02,
				 -thresholdNative => 0.75,
				 -screenSnps =>
				 -considerAnchor =>
				 -considerTemplateConsensus =>
				 -prescreenSnps =>
				 -preScreenSnpsMinimumBaseQuality => 30,
				 -priorPoly => 0.0001,
				 -priorPoly2 => 0.99666,
				 -priorPoly3 => 0.00333,
				 -priorPoly4 => 1e-05,
				 -priorPolyAC => 0.1666,
				 -priorPolyAG => 0.1666,
				 -priorPolyAT => 0.1666,
				 -priorPolyCG => 0.1666,
				 -priorPolyACG => 0.25,
				 -priorPolyACT => 0.25,
				 -thresholdSnp => 0.6,
				 -maxTerms => 50,
				 -writeAlignment =>
				 -alignmentOut => $pb_align,
				 -lineLength => 50,
				 -showUnAligned =>
				 -displayQuality =>
				 -writeAce =>
				 -aceOut => $pb_ace,
				 -nowritePhdFiles =>
				 #-phdFilePathOut => "$CLUSTERPATH/phd_dir",
				 -writeReport =>
				 -reportOut => $pb_out,
				 -nodebug =>
				 -monitor =>
				);


  open my $pb_read_fh, '<', $pb_out or die "$! opening $pb_out";
  my $gff3_featureio = $submission->_open_gff3_out($gff3_out);
  while( my $line = <$pb_read_fh> ) {
    if( $line =~ /SNP_ID:/ ) {
      my %data = parse_snp_line($line);

      #try to link alleles with accessions
      my %a_cnt; #< hash as accession->allele->count
      foreach my $seq (map $_->{template}, @{$data{COLUMN}}) {
	my $accession_name = $est_accessions{ $seq->{seqname} } || 'unknown accession(s)';
	$a_cnt{ $accession_name }{ $seq->{base} }++;
	$a_cnt{ $accession_name }{ total }++;
      }

      my $allele_accession_linkage = '';
      foreach my $accession (sort keys %a_cnt) {
	my $arec = $a_cnt{$accession};
	my $total = delete $arec->{total};
	my %pct = map { $_ => sprintf('%0.1f',($arec->{$_}||0)/$total*100) } qw/a c t g -/;
	$allele_accession_linkage .= qq|("$accession" a:$pct{a} c:$pct{c} t:$pct{t} g:$pct{g} -:$pct{'-'})|;
      }

      # construct the feature we will write to gff3
      my $new_id = do { $data{SNP_ID} =~ /polybayes-snps-(.+)$/i; 'pbsnp-'.$1 };
      my $ta = $data{TEMPLATE_ALLELES};
      my $feature = $self->new_feature( -start => $data{UNPADDED_POS},
					-end   => $data{UNPADDED_POS},
					-score => $data{P_SNP},
					-type  => 'SNP',
					-source => $self->analysis_name,
					-seq_id => $data{ALIGNMENT},
					-annots => { ID => $new_id,
						     pb_variant => $data{VAR},
						     pb_allele_count => (join ' ',map { $_.':'.$ta->{$_}} sort keys %$ta),
						     ( map { 'pb_'.lc($_) => $data{$_} } qw/ P_VAR P_1 P_2 P_3 P_4 P_5 / ),
						     accession_alleles => $allele_accession_linkage,
						   },
				      );
      $gff3_featureio->write_feature( $feature );
    }
  }

  #make a game-xml file
  gff_to_game_xml($submission->vector_screened_sequences_file,
		  $gff3_out,
		  $gamexml_out,
		  program_name   => $self->analysis_name,
		  program_date   => asctime(gmtime).' GMT',
		  gff_version    => 3,
		 );

  # now gzip the .align and .ace output files
  foreach ( [$pb_align => $pb_align_gz], [$pb_ace => $pb_ace_gz] ) {
      my $gz = CXGN::Tools::Run->run( 'gzip',
                                      -c =>
                                      $_->[0],
                                      { out_file => $_->[1] }
                                    );
  }

  return  @analysis_output_files;
}

# Parses a SNP line from the report file
# Returns an object (hash) containing two elements
#   header - all header elements (hash)
#   templates - all templates (array of hashes)
sub parse_snp_line {
  my ($line) = @_;
  chomp $line;
  #print "$line\n";
  my @tokens = split /\s+/,$line;

  my %data;
  while( my ($k,$v) = splice @tokens,0,2 ) {
    $k =~ s/:$//;
    if( $k eq 'TEMPLATE_ALLELES' || $k eq 'SEQUENCE_ALLELES' ) {
      $v =~ s/(\d)-/"$1,-"/e;
      $v = {split /[=,]/,$v};
    }
    elsif( $k eq 'COLUMN' ) {
      $v = _parse_pb_column($v);
    }
    $data{$k} = $v;
  }
  #print Dumper \%data;
  return %data;
}
sub _parse_pb_column {
  my ($col) = @_;

  my @templates = split /\|/, $col;
  return [
	  map {
	    my ($tdesc,$s) = split /;/,$_;
	    $tdesc =~ s/^TEMPLATE,// or die "parse failed for column desc '$col'";
	    $s =~ s/^SEQUENCE,// or die "parse failed for column desc '$col'";
	    { template => _parse_template($tdesc), sequence => _parse_sequence($s) }
	  } @templates
	 ];
}
sub _parse_template {
  my ($template) = @_;
  my ($seqname,$base,$quality) = split /,/,$template;

  return { seqname => $seqname, base => $base, quality => $quality };
}
sub _parse_sequence {
  my ($sequence) = @_;
  my (undef,$dir,$pos,$qual,$base,$name) = reverse split /,/,$sequence;

  return { name => $name, dir => $dir, pos => $pos, qual => $qual, base => $base };
}


###
1;#do not remove
###

