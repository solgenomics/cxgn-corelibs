package Bio::GMOD::Blast::Graph::MyUtils;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg assert );

my( %usedHash );

#####################################################################
sub makeVariableName {
#####################################################################
    my( @names ) = @_;

    my( $name );
    my( $varName ) = "";

    my( $pkg, $file, $line ) = caller();
    unshift( @names, $pkg );

    $varName .= "__";
    foreach $name ( @names )
    {
	$name =~ tr/a-z/A-Z/;
	$varName .= "_$name";
    }
    $varName .= "_VARIABLE__";

    assert( ! defined($usedHash{ $varName }), "duplicate variable name $varName" );
    $usedHash{ $varName } = 1;

    return( $varName );
}

#####################################################################
sub makeDumpString {
#####################################################################
    my( @args ) = @_;
    my( $str );

    $str = '[';
    $str .= join( "][", @args );
    $str .= ']';

    return( $str );
}

#####################################################################
sub parseNumber {
#####################################################################
    my( $data ) = shift;

    if( $data =~ m/\s*([\d\.]+)\s*/ )
    {
	$data = $1; # extract numbers from strings.
    }

    return( $data );
}

#####################################################################
sub getKey {
#####################################################################
    my( @parts ) = @_;

    my( $ret ) = join( ":", @parts );
   
    return( $ret );
}

# if the compare returns true, set ref = value.
#####################################################################
sub updateBoundRef {
#####################################################################
    my( $ref, $value, $cmpSub ) = @_;

    if( !defined( $$ref ) )
    {
	#dmsg( "updateBoundRef", "setting $ref to $value" );
	$$ref = $value;
    }
    elsif( &{$cmpSub}( $ref, $value ) )
    {
	$$ref = $value;
    }
}

# 1 if($value<$ref)
# 0 otherwise
#####################################################################
sub smallerP {
#####################################################################
    my( $ref, $value ) = @_;
    my( $p );

    if( $value < $$ref ) { $p = 1; }
    else { $p = 0; }

    return( $p );
}

# 1 if($value>$ref)
# 0 otherwise
#####################################################################
sub largerP {
#####################################################################
    my( $ref, $value ) = @_;
    my( $p );

    if( $value > $$ref ) { $p = 1; }
    else { $p = 0; }

    return( $p );
}

#####################################################################
sub openForReading {
#####################################################################
    my( $name ) = shift;

    unless( open( FHIN, "<$name" ) )
    {
	die( "MyUtils.openForReading(): couldn't open $name" );
    }

    return( \FHIN );
}

#####################################################################
sub getArgOrParam {
#####################################################################
    my( $dex, $param, @args ) = @_;
    my( $value );

    if( $dex < scalar(@args) )
    {
	$value = $args[ $dex ];
    }

    if( !defined( $value ) )
    {
	$value = $param;
    }

    return( $value );
}

#####################################################################
sub getArgOrDie {
#####################################################################
    my( $dex, $msg, @args ) = @_;
    my( $value );

    $value = getArgOrParam( $dex, undef, @args );

    if( !defined( $value ) )
    {
	die( $msg );
    }

    return( $value );
}

#####################################################################
1;
#####################################################################
