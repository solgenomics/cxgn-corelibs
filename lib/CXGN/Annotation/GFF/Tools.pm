package CXGN::Annotation::GFF::Tools;

=head1 NAME

CXGN::Annotation::GFF::Tools - useful little functions for dealing
with GFF-format files

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

BEGIN {
  our @EXPORT_OK = qw/ clean_gff_file clean_gff_line /;
}
our @EXPORT_OK;
use base qw/Exporter/;


=head2 clean_gff_file

  Usage: clean_gff_file($dirtyfile,$cleanfile);
  Desc : clean up a dirty GFF file, ensure spacing consistency, etc.
  Ret  : nothing meaningful
  Args : input file name, output file name
  Side Effects: writes cleaned GFF to output file
     dies on error.
  Example:

=cut

sub clean_gff_file {
  my( $infile, $outfile ) = @_;

  open my $in, $infile
    or die "Could not open $infile for reading: $!";
  open my $out, ">$outfile"
    or die "Could not open $outfile for writing: $!";
  while(<$in>) {
    print $out clean_gff_line($_);
  }
  close $out;
  close $in;
}

=head2 clean_gff_line

  Usage: my $clean = clean_gff_line($dirty);
  Desc : clean up a line of GFF
  Ret  : clean line
  Args : dirty line
  Side Effects: none
  Example:

=cut

sub clean_gff_line {
  my $line = shift;
  unless($line =~ /^#/) {
    $line =~ s/\t +| +\t/\t/g;
  }
  return $line;
}


=head1 AUTHOR

Robert Buels

=cut

###
1;#
###
