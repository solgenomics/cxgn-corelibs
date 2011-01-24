#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME

agp_to_fasta.pl - assemble an AGP file into fasta

=head1 SYNOPSIS

agp_to_fasta.pl foo.agp source.fasta > result.fasta

=head1 OPTIONS

=head2 -w <num>

Column width of fasta output, with 0 being unlimited (no additional
newlines).  Default 80.

=cut

use File::Temp;
use Getopt::Std;
use Pod::Usage;

use Bio::Index::Fasta;

use CXGN::BioTools::AGP qw/ agp_to_seqs /;

my %opts;
getopts( 'w', \%opts );
$opts{w} = 80 unless defined $opts{w};
pod2usage() unless @ARGV;

@ARGV == 2 or die "must pass exactly 2 file names as arguments\n";

for( @ARGV ) {
    -r or die "cannot read file '$_'"
}
my ( $agp_file, $source_seqs ) = @ARGV;

my $index = make_seqs_index( $source_seqs );

my @seqs = agp_to_seqs(
    $agp_file,
    fetch_default => sub {
        my $s = $index->fetch( $_[0] )
            or return;
        return $s->seq;
    }
   );

my $o = Bio::SeqIO->new(
    -format => 'fasta',
    -fh     => \*STDOUT,
    ( $opts{w} ? (-width  => 80) : () ),
   );

# the while/shift cuts down a bit on disk space usage
while( @seqs ) {
    $o->write_seq( shift @seqs );
}

exit;

################# SUBS ###########3

my $temp;
sub make_seqs_index {
    my ( $seqs ) = @_;
    $temp = File::Temp->new;
    $temp->close;

    # index of source sequences, for random access
    my $inx = Bio::Index::Fasta->new(
        -filename => "$temp",
        -write_flag => 1 );
    $inx->make_index( $source_seqs );

    return $inx;
}

