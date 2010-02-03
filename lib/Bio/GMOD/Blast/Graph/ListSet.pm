package Bio::GMOD::Blast::Graph::ListSet;
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
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs assert );
use Bio::GMOD::Blast::Graph::List;
use Bio::GMOD::Blast::Graph::ListSetEnumerator;

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

my $kLists = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "lists" );

####################################################################
sub init {
####################################################################
    my( $self ) = shift;

    $self->{ $kLists } = {};
}

####################################################################
sub getKeys {
####################################################################
    my( $self ) = shift;
    my( @keys );

    @keys = keys( %{$self->{ $kLists }} );
    #dmsgs( "getKeys(): ", @keys );

    return( @keys );
}

# overwrites any existing list at key with given list.
####################################################################
sub putListAt {
####################################################################
    my( $self, $n, $list ) = @_;

    $self->{ $kLists }->{ $n } = $list;
}

####################################################################
sub getListAt {
####################################################################
    my( $self, $n ) = @_;

    my( $list );

    $list = $self->{ $kLists }->{ $n };
    if( !defined($list) )
    {
	$self->{ $kLists }->{ $n } = $list = new Bio::GMOD::Blast::Graph::List();
	#dmsg( "getListAt( $n ): new ", $list->toString() );
    }

    return( $list );
}

####################################################################
sub removeListAt {
####################################################################
    my( $self, $n ) = @_;
    my( $ref );

    $ref = $self->{ $kLists };
    delete( $ref->{ $n } );
}

####################################################################
sub emptyP {
####################################################################
    my( $self ) = shift;
    my( @keys );
    my( $key );
    my( $list );
    my( $emptyP );

    @keys = keys( %{$self->{ $kLists }} );
    $emptyP = 1;

    while( $emptyP && scalar(@keys) > 0 )
    {
	$key = shift( @keys );
	$list = $self->{ $kLists }->{ $key };
	$emptyP = $list->emptyP();
    }

    return( $emptyP );
}

####################################################################
sub getCount {
####################################################################
    my( $self ) = shift;
    my( $count );

    $count = scalar( $self->getKeys() );

    return( $count );
}

####################################################################
sub getEnumerator {
####################################################################
    my( $self ) = shift;

    return( new Bio::GMOD::Blast::Graph::ListSetEnumerator( $self ) );
}

####################################################################
sub toString {
####################################################################
    my( $self ) = shift;
    my( $str );
    my( @strs );
    my( $enum );
    my( $list );

    $enum = $self->getEnumerator();
    while( defined( $list = $enum->getNextElement() ) )
    {
	push( @strs, " " . $list->toString() . "\n" );
    }
    $str = Bio::GMOD::Blast::Graph::MyUtils::makeDumpString( $self, $self->getCount() . "\n", @strs );

    return( $str );
}

####################################################################
1;
####################################################################
