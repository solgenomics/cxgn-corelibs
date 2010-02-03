package Bio::GMOD::Blast::Graph::MyMath;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( max round floor ceil );

sub max
{
    my( $a, $b ) = @_;

    return( ($a > $b) ? $a : $b );
}

sub round
{
    my( $float ) = shift;
    return( int($float+0.5) );
}

sub floor
{
    my( $float ) = shift;
    return( int($float) );
}

sub ceil
{
    my( $float ) = shift;
    return( int($float+0.5) );
}

1;

