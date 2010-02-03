package Bio::GMOD::Blast::Graph::ListSetEnumerator;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Bio::GMOD::Blast::Graph::BaseObj;
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs );
use Bio::GMOD::Blast::Graph::List;

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

my $kListSet = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "list", "set" );
my $kIndex = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "index" );
my $kKeys = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "key" );
my $kMaxDex = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "max", "dex" );

#####################################################################
sub init {
#####################################################################
    my( $self, $listSet ) = @_;
    my( @keys );

    $self->{ $kListSet } = $listSet;
    $self->{ $kIndex } = -1;
    @keys = sort $listSet->getKeys();
    #dmsg( "init(): keys = (", join( ", ", @keys ), ")" );
    $self->{ $kMaxDex } = scalar( @keys ) - 1;
    $self->{ $kKeys } = \@keys;
    #dmsgs( "init(): $listSet ", $self->{$kMaxDex}, @{$self->{$kKeys}} );
}

#####################################################################
sub getCurrentKey {
#####################################################################
    my( $self ) = shift;
    my( $dex );
    my( $key );

    $dex = $self->getIndex();
    $key = $self->getKey( $dex );

    return( $key );
}

#####################################################################
sub getNextElement {
#####################################################################
    my( $self ) = shift;
    my( $elem );
    my( $dex );
    my( $key );
    my( $maxDex );

    $elem = undef;
    $dex = $self->getIndex();
    $maxDex = $self->getMaxIndex();

    # have to pre-index so getCurrentKey() will work.
    $self->putIndex( ++$dex );

    if( $dex <= $maxDex )
    {	
	$key = $self->getKey( $dex );
	$elem = $self->getListSet()->getListAt( $key );
	#dmsg( "getNextElement(): $dex $key $elem" );
    }

    return( $elem );
}

#####################################################################
sub getListSet {
#####################################################################
    my( $self ) = shift;
    return( $self->{ $kListSet } );
}

#####################################################################
sub getKey {
#####################################################################
    my( $self, $dex ) = @_;
    my( $key );

    $key = $ { $self->{ $kKeys } } [ $dex ];

    return( $key );
}

#####################################################################
sub getMaxIndex {
#####################################################################
    my( $self ) = shift;
    return( $self->{ $kMaxDex } );
}

#####################################################################
sub getIndex {
#####################################################################
    my( $self ) = shift;
    return( $self->{ $kIndex } );
}

#####################################################################
sub putIndex {
#####################################################################
    my( $self, $dex ) = @_;
    $self->{ $kIndex } = $dex;
}
#####################################################################
1;
#####################################################################
