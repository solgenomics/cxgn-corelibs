package CXGN::Garbage::n_to_p_trans;
use strict;
# NOTE: This pacakge originally created by Dan Ilut for use on the website
#
# modified and incorporated into koni's SGN script repository on Feb 21, 2004

#ugly-looking code to create the translation hash. 
#auto-generated from a translation table
my %trans_hash;

$trans_hash{AAA}=['K','Lys'];
$trans_hash{AAC}=['N','Asn'];
$trans_hash{AAG}=['K','Lys'];
$trans_hash{ATA}=['I','Ile'];
$trans_hash{ATC}=['I','Ile'];
$trans_hash{CCA}=['P','Pro'];
$trans_hash{ATG}=['M','Met'];
$trans_hash{CCC}=['P','Pro'];
$trans_hash{CCG}=['P','Pro'];
$trans_hash{CGA}=['R','Arg'];
$trans_hash{AAT}=['N','Asn'];
$trans_hash{CGC}=['R','Arg'];
$trans_hash{GCA}=['A','Ala'];
$trans_hash{GCC}=['A','Ala'];
$trans_hash{CGG}=['R','Arg'];
$trans_hash{ATT}=['I','Ile'];
$trans_hash{GCG}=['A','Ala'];
$trans_hash{TCA}=['S','Ser'];
$trans_hash{CCT}=['P','Pro'];
$trans_hash{GGA}=['G','Gly'];
$trans_hash{TCC}=['S','Ser'];
$trans_hash{GGC}=['G','Gly'];
$trans_hash{TCG}=['S','Ser'];
$trans_hash{GGG}=['G','Gly'];
$trans_hash{TGA}=['*','Ter'];
$trans_hash{CGT}=['R','Arg'];
$trans_hash{TGC}=['C','Cys'];
$trans_hash{GCT}=['A','Ala'];
$trans_hash{TGG}=['W','Trp'];
$trans_hash{TCT}=['S','Ser'];
$trans_hash{GGT}=['G','Gly'];
$trans_hash{TGT}=['C','Cys'];
$trans_hash{ACA}=['T','Thr'];
$trans_hash{CAA}=['Q','Gln'];
$trans_hash{ACC}=['T','Thr'];
$trans_hash{CAC}=['H','His'];
$trans_hash{ACG}=['T','Thr'];
$trans_hash{CTA}=['L','Leu'];
$trans_hash{CAG}=['Q','Gln'];
$trans_hash{AGA}=['R','Arg'];
$trans_hash{CTC}=['L','Leu'];
$trans_hash{AGC}=['S','Ser'];
$trans_hash{CTG}=['L','Leu'];
$trans_hash{AGG}=['R','Arg'];
$trans_hash{GAA}=['E','Glu'];
$trans_hash{GAC}=['D','Asp'];
$trans_hash{ACT}=['T','Thr'];
$trans_hash{GTA}=['V','Val'];
$trans_hash{GAG}=['E','Glu'];
$trans_hash{CAT}=['H','His'];
$trans_hash{TAA}=['*','Ter'];
$trans_hash{GTC}=['V','Val'];
$trans_hash{TAC}=['Y','Tyr'];
$trans_hash{TAG}=['*','Ter'];
$trans_hash{AGT}=['S','Ser'];
$trans_hash{GTG}=['V','Val'];
$trans_hash{CTT}=['L','Leu'];
$trans_hash{TTA}=['L','Leu'];
$trans_hash{TTC}=['F','Phe'];
$trans_hash{GAT}=['D','Asp'];
$trans_hash{TTG}=['L','Leu'];
$trans_hash{GTT}=['V','Val'];
$trans_hash{TAT}=['Y','Tyr'];
$trans_hash{TTT}=['F','Phe'];
#sequence translator
#########################
sub translate_3n_1letter{
    my ($triplet)=@_;
    my $toreturn=$trans_hash{$triplet}[0];
    unless($toreturn){
	(length $triplet)==3
	    and $toreturn='X';
    }
}

sub translate_3n_3letter{
    my ($triplet)=@_;
    return $trans_hash{$triplet}[1];
}

sub translate_3n_both{
    my ($triplet)=@_;
    return @{$trans_hash{$triplet}};
}

#don't know what dan's wackass functions are doing... I added the below funcs
#for wholesale translation (koni)

sub translate {
  my ($seq) = @_;

  my $i = 0;
  my $l = length($seq)-3;
  my @AA = ();
  while($i <= $l) {
    my $codon = substr $seq, $i, 3;
    my $aa = $trans_hash{$codon}->[0];

    # Ambiguity codes like Ns should probably be handled better, since the
    # amino acid residue may still be uniquely defined. For now this just
    # says X whenever a mapping from the hash above is not found
    if (!defined($aa)) {
      $aa = "X";
    }
    push @AA, $aa;
    $i+=3;
  }
  if (wantarray()) {
    return @AA;
  } else {
    return join("",@AA);
  }
}

sub translate_frame {
  my ($seq, $frame) = @_;

  if (!defined($frame)) {
    $frame = 1;
  }
  if ($frame==0 || abs($frame)>3) {
    return undef;
  }

  if ($frame < 0) {
    $seq = reverse_complement($seq);
    $frame = -1*$frame;
  }

  $seq = substr $seq, $frame-1;

  return translate($seq);
}

sub reverse_complement {
  my ($seq) = @_;

  $seq = join("",reverse(split(//,$seq)));
  $seq =~ tr/ACGT/TGCA/;

  return $seq;
}

return 1;
