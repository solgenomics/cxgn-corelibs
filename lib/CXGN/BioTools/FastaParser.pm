package CXGN::BioTools::FastaParser;
use strict;
use FileHandle;

our $errstr;
sub load_file {
  my ($pkg, $seq_filename, $qual_filename) = @_;
  my ($inputline, $seqname, $position, $seq_fh, $qual_fh);
  my ($qualfile_posref, $seqfile_posref);
  my ($fasta_file);
  my %seqfile_pos;
  my %qualfile_pos;

  $seq_fh = new FileHandle;
  if (! $seq_fh->open("< $seq_filename")) {
    print STDERR "Failed opening FASTA sequence file \"$seq_filename\" ($!)";
    $errstr = "$!";
    return 0;
  }

  my $n_seq = 0;
  while($inputline = <$seq_fh>) {
    if ($inputline =~ m/^>/) {
      # Get rid of the leading > and the trailing newline
      chomp $inputline;
      $inputline = substr $inputline, 1;
      ($seqname) = split/\s/,$inputline;
      $position = tell $seq_fh;
      $seqfile_pos{$seqname} = [ $position, $inputline ];
      $n_seq++;
    }
  }
  $seqfile_posref = \%seqfile_pos;

  if ($qual_filename) {
    $qual_fh = new FileHandle;
    if (! $qual_fh->open("< $qual_filename")) {
      print STDERR "Failed opening FASTA quality file \"$qual_filename\" ($!)";
      $errstr = "$!";
      return 0;
    }

    while($inputline = <$qual_fh>) {
      if ($inputline =~ m/^>/) {
	chomp $inputline;
	$inputline = substr $inputline, 1;
	($seqname) = split/\s/,$inputline;
	$position = tell $qual_fh;
	
	$qualfile_pos{$seqname} = [ $position, $inputline ];
      }
    }
    $qualfile_posref = \%qualfile_pos;
  } else {
    $qualfile_posref = undef;
    $qual_fh = undef;
  }

  $fasta_file = { "seq_filename" => $seq_filename,
		   "qual_filename" => $qual_filename,
		   "seq_fh" => $seq_fh,
		   "qual_fh" => $qual_fh,
		   "seqfile_pos" => $seqfile_posref,
		   "qualfile_pos" => $qualfile_posref,
		   "last_error" => "No Errors",
		   "n_seq" => $n_seq };
  bless $fasta_file, $pkg;
  return $fasta_file;
}

sub get_seqids {
  my ($obj) = @_;

  return sort { $obj->{seqfile_pos}->{$a}->[0] <=> $obj->{seqfile_pos}->{$b}->[0] } keys %{$obj->{seqfile_pos}};
}

sub sort_seqids {
  my ($obj, @ids) = @_;

  return sort { $obj->{seqfile_pos}->{$a}->[0] <=> $obj->{seqfile_pos}->{$b}->[0] } @ids;
}

sub get_sequence {
  my ($obj, $seqname, $qualref) = @_;
  my ($seq, $position, $inputline);

  if (! defined($obj->{seqfile_pos}->{$seqname})) {
    if ($qualref) {
      @{$qualref} = ();
    }
    $obj->{last_error} = "Can't find sequence for query \"$seqname\"";
    return "";
  }
  $position = $obj->{seqfile_pos}->{$seqname}->[0];

  seek $obj->{seq_fh}, $position, 0;

  $seq = "";

  while ($inputline = $obj->{seq_fh}->getline()) {
    last if $inputline =~ m/^>/;
    chomp $inputline;
    $seq = $seq . $inputline;
  }

  if ($qualref && $obj->{qual_fh}) {
    @{$qualref} = ();
    if (! defined($obj->{qualfile_pos}->{$seqname})) {
      $obj->{last_error} = "Can't find quality information for query \"$seqname\"";
      return $seq;
    }
    $position = $obj->{qualfile_pos}->{$seqname}->[0];
    seek $obj->{qual_fh}, $position, 0;
    while($inputline = $obj->{qual_fh}->getline()) {
      last if $inputline =~ m/^>/;
      chomp $inputline;
      push @{$qualref}, split/\s/,$inputline;
    }
  }

  if ($seq eq "") {
      $obj->{last_error} = "No sequence data found after header";
  }
  return $seq;
}

sub get_header {
  my ($obj, $seqname) = @_;

  if ($obj->{seqfile_pos}->{$seqname}) {
    return $obj->{seqfile_pos}->{$seqname}->[1];
  }

  $obj->{last_error} = "No header found for query \"$seqname\"";
  return "";
}

sub last_error {
  my ($obj) = @_;

  return $obj->{last_error};
}


sub close { 
  my ($fasta_file) = @_;

  $fasta_file->{"seq_fh"}->close();
  if ($fasta_file->{"qual_fh"}) { $fasta_file->{"qual_fh"}->close(); }
  $fasta_file = ();

}

sub DESTROY {
  my ($fasta_file) = @_;
  $fasta_file->close();
}

sub format_sequence {
  my ($header, $seq) = @_;
  my $rval;

  $rval = ">$header\n";
  while($seq) {
    $rval .= substr $seq,0,50,"";
    $rval .= "\n";
  }

  return $rval;
}

sub format_qualdata {
  my ($header, $qualdata_ref) = @_;
  my $rval;

  $rval = ">$header\n";
  while(@{$qualdata_ref} > 0) {
    $rval .= join(" ",splice(@{$qualdata_ref},0,17));
    $rval .= "\n";
  }

  return $rval;
}

return 1;
