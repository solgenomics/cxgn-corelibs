package CXGN::Annotation::GAMEXML::FromFile;

use strict;
use warnings;
use English;
use Carp;

use POSIX;

use File::Temp qw/tempfile tempdir/;

use Bio::SeqIO;
use Bio::Seq::SeqFactory;
use Bio::Factory::SeqAnalysisParserFactory;
use Bio::FeatureIO;
use Bio::SeqFeature::Computation;
use Bio::Index::Fasta;

use CXGN::Annotation::GAMEXML::Generate;
use CXGN::Annotation::Parse::GeneSeqer;
use CXGN::Annotation::GAMEXML::Combine qw/combine_game_xml_files/;

use CXGN::Annotation::GFF::Tools qw/clean_gff_file/;

=head1 NAME

CXGN::Annotation::GAMEXML::FromFile - convert various file formats to
GAME XML.

=head1 FUNCTIONS

All listed functions are EXPORT_OK.

=cut

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw{
		      geneseqer_to_game_xml
		      gff_to_game_xml
		      gthxml_to_game_xml
		    };
};

=head2 geneseqer_to_game_xml

  Usage: geneseqer_to_game_xml
  Desc : convert GeneSeqer output to GAME XML
  Ret  : nothing meaningful
  Args : FASTA filename that was geneseqer's input,
         GeneSeqer's result file,
         output filename for writing GAME XML,
         optional hash-style list of additional info to
         use in making the xml, as:
            ( program_name  => 'name of program',
                                #defaults to 'GeneSeqer'
              program_date  => 'datestamp of program',
                                #defaults to asctime(gmtime)
              database_name => 'name of database',
                                #default 'unknown database'
              database_date => 'database datestamp',
              computation_id => some integer,
                                #no default
            )
  Side Effects: overwrites given output file

  NOTE: this function dies on failure to translate

=cut

sub geneseqer_to_game_xml {
  my ($fastafile, $infile, $outfile) = @_;
  my @genes; # EST alignment genes
  my @exons; # EST alignment exons (parts of genes)
  my @agsexons; # AGSs exons (each exon specifies its PGL and AGS)

  # get sequence information
  my ($seq_id, $seq_string) = _get_fasta_seq($fastafile);

  # parse the file
  CXGN::Annotation::Parse::GeneSeqer::loadfile($infile, \@genes, \@exons, \@agsexons);

  # transform the parse results into XML
  my $XML = CXGN::Annotation::GAMEXML::Generate::GenerateXML($seq_id, $seq_string, \@genes, \@exons, \@agsexons);

  open FILEOUT, ">$outfile"
    or die "Could not open GAME XML output file '$outfile': $!";
  print FILEOUT $XML;
  close FILEOUT;
}

# sub geneseqer_to_game_xml {
#   my ($seqfile, $gsfile, $outfile,%other) = @_;

#   my $gs_in = Bio::FeatureIO->new(-file => $gsfile,
# 				  -format => 'geneseqer',
# 				  -mode => 'both_merged');

#   my $game_fh = Bio::SeqIO->new( -file    => ">$outfile",
# 				 -format  => 'game',
# 			       );

#   $other{program_name} ||= 'GeneSeqer';
#   return _seqs_and_features_to_gamexml($seqfile,$gs_in,$game_fh,
# 				       %other,
# 				       );
# }

=head2 gff_to_game_xml

  Usage: gff_to_game_xml('fasta_input.seq','results.gff','results.xml');
  Desc : convert GFF to GAME XML, accepts either GFF2 or GFF3
  Ret  : nothing meaningful
  Args : name of input sequence FASTA file,
         name of GFF file to convert,
         name of file to write as output,
         optional hash-style list of additional info to
         use in making the xml, as:
            ( program_name  => 'name of program',
              program_date  => 'datestamp of program',
              database_name => 'name of database',
              database_date => 'database datestamp',
              computation_id => some integer,
              render_as_annotation => 1,
              #set this to 1 to render this GFF as <annotation> instead
              #of <computational_analysis> (the default)
              gff_version    => 2,
            )
  Side Effects: overwrites output file, will die on error

=cut

sub gff_to_game_xml {
  my( $seqfile, $gff_file, $outfile, %other ) = @_;

  #for some reason, Apollo really really wants a database name
  #for these, or it won't display.  set a default one.
  $other{database_name} ||= 'unknown database';

  my $gff_version = delete $other{gff_version};

  while(my($key,$val) = each %other) {
    #make the hyphenated forms for passing to bioperl
    $other{"-$key"} = $val;
    delete $other{$key};
  }

  #clean up the gff file
  my (undef,$clean_gff_file) = tempfile(File::Spec->catfile(File::Spec->tmpdir,'cxgn-annotation-gamexml-fromfile-clean-gff-XXXXXXXX'),
					UNLINK => 1,
				       );
  clean_gff_file($gff_file,$clean_gff_file);

  open my $gff_fh, "$clean_gff_file"
    or die "Could not open GFF file $clean_gff_file for reading: $!";

  #choose a parser to use based on which gff version we've got
  my $parser = do {
    if($gff_version && $gff_version == 3) {
      Bio::FeatureIO->new(-fh => $gff_fh, -format => 'gff', -version => 3);
    }
    else {
      my $factory = Bio::Factory::SeqAnalysisParserFactory->new();
      $factory->get_parser(-input => $gff_fh, -method => 'gff');
    }
  };
  return _seqs_and_features_to_gamexml($seqfile,$parser,$outfile,%other);
}

=head2 gthxml_to_gamexml

  Usage: gthxml_to_game_xml('fasta_input.seq','results.gth.xml','results.xml');
  Desc : convert GenomeThreader XML to GAME XML
  Ret  : nothing meaningful
  Args : name of input sequence FASTA file,
         name of gthxml file to convert,
         name of file to write as output,
         optional hash-style list of additional info to
         use in making the xml, as:
            ( program_name  => 'name of program',
              program_date  => 'datestamp of program',
              database_name => 'name of database',
              database_date => 'database datestamp',
              computation_id => some integer,
              render_as_annotation => 1,
              #set this to 1 to render all the results as <annotation> instead
              #of <computational_analysis> (the default)
            )
  Side Effects: overwrites output file, will die on error

=cut

sub gthxml_to_game_xml {
  my( $seqfile, $gth_file, $outfile, %other ) = @_;

  $other{program_date} ||= asctime(gmtime).' GMT';

  my $tempdir = tempdir(File::Spec->catdir(File::Spec->tmpdir,'cxgn-annotation-gamexml-fromfile-XXXXXXXX'),
			CLEANUP => 1,
		       );

  #general strategy: make a separate gamexml file for the alignments and the features,
  #then merge them.  this is the easiest way right now to make separate tracks
  #for alignments and pgls

  ### make the alignments game
  my $alignments_file = do {
    my $alignments = Bio::FeatureIO->new( -format => 'gthxml', -file => $gth_file,
					  -mode => 'alignments_merged', -attach_alignments => 0);
    my (undef,$tempfile) = tempfile(File::Spec->catfile($tempdir,'gthxml-to-gamexml-alignmenxts-XXXXXXXX'));
    _seqs_and_features_to_gamexml($seqfile,$alignments,$tempfile,%other);
    $tempfile;
  };

  ### make the pgls game, rendering as annotation
  my $pgls_file = do {
    my $pgls = Bio::FeatureIO->new( -format => 'gthxml', -file => $gth_file,
				    -mode => 'pgls', -attach_alignments => 0);
    my (undef,$tempfile) = tempfile(File::Spec->catfile($tempdir,'gthxml-to-gamexml-pgls-XXXXXXXX'));
    my $seq = do { my $io = Bio::SeqIO->new(-format => 'fasta', -file => $seqfile);
		   my $s = $io->next_seq;
		   $io->next_seq and croak 'gthxml_to_game_xml does not work for multiple genomic sequences';
		   $s
		 };
    my $pglctr;
    while( my $pgl = $pgls->next_feature) {
      my $pglname = "GT_PGL_".++$pglctr;
      my $agsctr;
      foreach my $ags ($pgl->get_SeqFeatures) {
	my $agsname = $pglname.'_AGS_'.++$agsctr;
	$ags->type('gene');
	$ags->display_name($agsname);
	$_->type('exon') foreach $ags->get_SeqFeatures;
	$seq->add_SeqFeature($ags);
      }
    }
    #write out the game xml
    Bio::SeqIO->new( -format => 'game', -file => ">$tempfile", %other)->write_seq($seq);
    $tempfile
  };

  #now merge the temp gamexml files
  combine_game_xml_files($alignments_file,$pgls_file,$outfile);
}

sub _seqs_and_features_to_gamexml {
  my ($seqfile, $features_in, $game_outfile,%other) = @_;
  my $game_out = Bio::SeqIO->new(-file    => ">$game_outfile",
				 -format  => 'game',
				);

  my $seq_index = _get_seq_index($seqfile);

#  my $oot = Bio::FeatureIO->new(-format => 'gff', -fh => \*STDOUT, -version => 3);

  my %feature_buffer; #this is where we put features that come off the
                      #feature stream that don't belong to the current
                      #sequence

  my $featuretype = delete($other{render_as_annotation})
    ? 'Bio::SeqFeature::Generic'
      : 'Bio::SeqFeature::Computation';

  #ugly ugly crap to match features to their reference sequences
  #without blowing out our memory.  assumes that the feature stream
  #has all the features for a given reference seq grouped together in
  #one chunk
  my $seq;
  my $annotated_seqs_count;
  my ($track_fwd,$track_rev);
  my $previous_seq_id;
  my %already_written;
  while (my $feature = $features_in->next_feature() ) {
#    $oot->write_feature($feature);
    my $current_seq_id = $feature->seq_id;
    # now read in all the features and write them out
#    warn "using seq_id $current_seq_id\n";
    if ($previous_seq_id and "$previous_seq_id" ne "$current_seq_id" ) {

      #do some checks
      $seq or die "sanity check failed";
      croak "feature stream does not have the features grouped by reference sequence.  bailing."
	if $already_written{$previous_seq_id};
      $already_written{$previous_seq_id} = 1;
      #write out the sequence
      _write_seq_with_tracks( $seq, $game_out, $track_fwd, $track_rev );
      $annotated_seqs_count++;

      #now that these are written out, delete them and make new ones
      $seq = undef; #need to get the next seq
      ($track_fwd,$track_rev) = undef,undef;
      #make a new track pair
    }

    #make a new sequence and tracks if necessary
    unless($seq && $track_fwd && $track_rev) {
      $seq = $seq_index->fetch($current_seq_id)
	or croak "No sequence found with ID '$current_seq_id'";
      ($track_fwd,$track_rev) =  map {
	$featuretype->new( -start => 1, -end   => $seq->length,
			   -strand => $_, %other,
			 )
      } (1,-1);
    }

    #try to make a useful display name
    #if we don't already have one
    unless ( $feature->display_name ) {
      #if it's a similarity, and we have a Target, use that as a
      #display name
      if ( grep {$feature->primary_tag eq $_} qw/nucleotide_motif similarity/
	   and (my ($target) = $feature->get_tag_values('Target')) >= 1) {
	$feature->display_name($target);
      }
      #feel free to add more elsifs here to make display names
      #using other tag types
      #       elsif( some other condition ) {
      # 	set some other display name
      #       }
    }

    #add this feature to the proper track (either forward or reverse strand)
    if ($feature->strand >= 0) {
      $track_fwd->add_SeqFeature( $feature );
    } else {
      $track_rev->add_SeqFeature( $feature );
    }

    $previous_seq_id = $current_seq_id;
  }
  if($seq && $track_fwd && $track_rev) {
    _write_seq_with_tracks( $seq, $game_out, $track_fwd, $track_rev );
    $annotated_seqs_count++;
  } else {
    #if no seq object by the time we get here, the feature stream was empty.
    #write a bare gamexml file with no annotations
    my $seqs = Bio::SeqIO->new(-file => $seqfile, -format => 'fasta');
    while(my $seq = $seqs->next_seq) {
      $game_out->write_seq($seq);
      $annotated_seqs_count++;
    }
  }

  carp "WARNING: $annotated_seqs_count <game> blocks written.  Apollo cannot display GAME XML files with more than one <game> block" if $annotated_seqs_count > 1;
}
sub _write_seq_with_tracks {
  my ($seq,$game_out,@tracks) = @_;
  $seq or confess 'no seq!';
  $seq->add_SeqFeature($_) for @tracks;
  $game_out->write_seq($seq);
}

sub _get_fasta_seq {
  my $FASTAFile = shift;

  my $seq_id;
  my $sequence;

  open FILEIN, $FASTAFile
    or die "Cannot open '$FASTAFile': $!";

  while (my $line = <FILEIN>) {
    chomp $line;
    if ($line =~ />([\S]+)/) {
      $seq_id = $1;
    } else {
      $sequence .= $line;
    }
  }
  close FILEIN;

  return ($seq_id, $sequence);
}

our %index_files; #list of files we've already indexed this run
#given a fasta seq file name, return an indexed version of it
sub _get_seq_index {
  my ($seqfile) = @_;

  my $index_filename = $index_files{$seqfile} ||= do {
    my (undef,$tempfile) = tempfile(File::Spec->catfile(File::Spec->tmpdir, 'cxgn-annotation-gamexml-fromfile-seq-index-XXXXXX'),UNLINK=>1);
    $tempfile
  };

  #make the index if necessary
  unless(-s $index_filename) {
    Bio::Index::Fasta->new( -filename => $index_filename,
			    -write_flag => 1,
			  )->make_index($seqfile);
  }

  #now open the index and return the index object
  return Bio::Index::Fasta->new( -filename => $index_filename );
}


###
1;#do not remove
###
