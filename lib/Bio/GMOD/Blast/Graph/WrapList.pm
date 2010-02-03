package Bio::GMOD::Blast::Graph::WrapList;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Bio::GMOD::Blast::Graph::BaseObj;
use Bio::GMOD::Blast::Graph::List;
use Bio::GMOD::Blast::Graph::ListEnumerator;
use Bio::GMOD::Blast::Graph::ScientificNotation;
use Bio::GMOD::Blast::Graph::HitWrapper;
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs );

@ISA = qw( Bio::GMOD::Blast::Graph::List );

sub pValueSorterIncreasing
{
    my( $cmp );
    my( $aP, $bP );

    $aP = $a->getP();
    $bP = $b->getP();
    $cmp = Bio::GMOD::Blast::Graph::ScientificNotation::cmp( $aP, $bP );

    return( $cmp );
}

sub mapHelper
{
    $_->getP();
}

sub sortByPValue
{
    my( $self ) = shift;
    my( @ray );

    @ray = @{$self->getElementsRef()};
    #dmsgs( "sortByPValue(): before = ", map( mapHelper, @ray ) );

    @ray = sort pValueSorterIncreasing @ray;
    #dmsgs( "sortByPValue(): after = ", map( mapHelper, @ray ) );

    $self->putElementsRef( \@ray );
}

# really, we're looking at the p value.
sub getLeastNonZeroElement
{
    my( $self ) = shift;
    my( $elem );
    my( $ref, $te );
    
    $ref = $self->getElementsRef();
    foreach $te ( @{$ref} )
    {
	if( ! Bio::GMOD::Blast::Graph::ScientificNotation::isZero( $te->getP() ) )
	{
	    $elem = $te;
	    last;
	}
    }

    return( $elem );
}

1;

