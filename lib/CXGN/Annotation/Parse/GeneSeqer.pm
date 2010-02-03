package CXGN::Annotation::Parse::GeneSeqer;
use strict;
use Class::Struct;

# struct for storing gene information from EST alignment
struct (__PACKAGE__.'::gene' => {
				 number => '$',
				 exons => '@',
				 esttitle => '$',
				 q_align => '$',
				 s_align => '$',
				});

# struct for storing information on individual exons within each gene
struct (__PACKAGE__.'::exon' => {
				 gene => '$',
				 num => '$',
				 strand => '$',
				 start => '$',
				 end => '$',
				 cdna_start => '$',
				 cdna_end => '$',
				 score => '$',
				});

# struct for storing predicted gene location information
struct (__PACKAGE__.'::agsexon' => {
				    pglnum => '$',
				    agsnum => '$',
				    num => '$',
				    start => '$',
				    end => '$',
				    score => '$',
				   });

# returns a new gene struct containing the given exon struct
sub startNewGene {
  my $exon = $_[0];
  my $gene = (__PACKAGE__.'::gene')->new;
  $gene->number($exon->gene);
  push @{$gene->exons}, $exon;
  return $gene;
}

# parses the output file into gene/exon structs
sub loadfile {
  my $infile = $_[0];
  my $genes_ref = $_[1];
  my $exons_ref = $_[2];
  my $agsexon_ref = $_[3];

  open (FILEIN, $infile) or die "Cannot open file: '$infile': $!\n";

  my ($gene, $exon, $agsexon);
  $gene = (__PACKAGE__.'::gene')->new;
  $gene->number(1);

  my $b_topstrand = 1;
  my $b_alignments = 1;
  my $currentpeptide = "";
  my ($b_readexon, $b_readest, $b_readalign, $est_count, $esttitle, $pgl_count, $ags_count);


  my @current_exons = ();

  while (my $line = <FILEIN>) {
    chomp $line;
    # process the EST alignments [first half of file]
    if ($b_alignments) {
      # end of "Alignment" (exon table)
      if ($line =~ /hqPGS_/) {
        $gene->esttitle($esttitle);
        push @$genes_ref, $gene;
        $b_readalign = 0;
      }
      # end of "Predicted gene exon" (exon table)
      if ($line =~ /MATCH/) {
        $b_readexon = 0;
      }
      # end of "EST sequence" / start of "Predicted gene exon" (exon table)
      if ($line =~ /Predicted gene structure /) {
        $b_readest = 0;
        $b_readexon = 1;
      }
      # exon line pattern
      if ($line =~ /Exon\s+\d+\s+\d+\s+\d+/) {
        if ($b_readexon) {
          $exon = &readexon($line, $est_count);
          push @$exons_ref, $exon;
          if ($exon->gene() == $gene->number()) {
            push @{$gene->exons()}, $exon;
          }
          else {
            $gene = &startNewGene($exon);
          }
        }
      }
      # alignment
      if ($b_readalign) {
        if ($line =~ /^([A-Za-z \.\-]+)[0-9]+$/) {
          my $alignline = $1;
          $alignline =~ s/[\s+]//g;
          # upper line of alignment
          if ($b_topstrand) {
            $alignline = $gene->q_align() . $alignline;
            $gene->q_align($alignline);
            $b_topstrand = 0;
          }
          # lower line of alignment
          else {
            $alignline = $gene->s_align() . $alignline;
            $gene->s_align($alignline);
            $b_topstrand = 1;
          }
        }
      }
      # start of "EST sequence"
      if ($line =~ /File: (.*)\)/) {
        $b_readest = 1;
        $est_count++;
        $esttitle = $1;
      }
      # start of "Alignment"
      if ($line =~ /Alignment/) {
        $b_readalign = 1;
        $gene->q_align("");
        $gene->s_align("");
      }
      # start of predicted gene locations
      if ($line =~ /Predicted gene locations/) {
        $b_alignments = 0;
      }
    }
    # process the PGLs (predicted gene locations) [second part of file]
    else {
      # start of new PGL
      if ($line =~ /^PGL\s+(\d+)/) {
        $pgl_count = $1;
      }
      # start of new AGS
      if ($line =~ /^AGS\-(\d+)/) {
        $ags_count = $1;
      }
      # end of exon table
      if ($line =~ /3-phase translation/) {
        $b_readexon = 0;
      }
      # exon line pattern
      if ($line =~ /  Exon\s+\d+\s+\d+\s+\d+/) {
        if ($b_readexon) {
          $agsexon = &readagsexon($line, $pgl_count, $ags_count);
          push @$agsexon_ref, $agsexon;
        }
      }
      # start of exon table
      if ($line =~ /^SCR/) {
        $b_readexon = 1;
      }
    }
  }
  close FILEIN;

  # check if the parser gathered sufficient data
  if (!@$genes_ref || !@$exons_ref || !@$agsexon_ref) { die "missing results" }

# display the parsing results
#print "genes: " . @$genes_ref . "\n";
#print "exons: " . @$exons_ref . "\n";
#print "agsexons: " . @$agsexon_ref . "\n";
}

# generates an exon struct
sub readexon {
  my $line = $_[0];
  my $count = $_[1];
  my $exon = (__PACKAGE__.'::exon')->new;
  my @items = split(/[^\d\.]+/, $line);
  $exon->gene($count);
  $exon->num($items[1]);
  $exon->start($items[2]);
  $exon->end($items[3]);
  $exon->cdna_start($items[5]);
  $exon->cdna_end($items[6]);
  $exon->score($items[8]);
  return $exon;
}

# generates an agsexon struct
sub readagsexon {
  my $line = $_[0];
  my $pgl_count = $_[1];
  my $ags_count = $_[2];
  my $agsexon = (__PACKAGE__.'::agsexon')->new;
  my @items = split(/[^\d\.]+/, $line);
  $agsexon->pglnum($pgl_count);
  $agsexon->agsnum($ags_count);
  $agsexon->num($items[1]);
  $agsexon->start($items[2]);
  $agsexon->end($items[3]);
  $agsexon->score($items[5]);
  return $agsexon;
}

###
1;#do not remove
###



