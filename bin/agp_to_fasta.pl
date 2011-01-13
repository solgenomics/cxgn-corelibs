#!/usr/bin/env perl
use strict;
use warnings;

=head1 NAME

agp_to_fasta.pl - assemble an AGP file into fasta

=head1 SYNOPSIS

agp_to_fasta.pl foo.agp source.fasta > result.fasta

=cut

use File::Temp;
use Getopt::Std;
use Pod::Usage;

use Bio::Index::Fasta;

use CXGN::BioTools::AGP qw/ agp_to_seqs /;

my %opts;
getopts( '', \%opts );
pod2usage() unless @ARGV;

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
    -width  => 80,
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

