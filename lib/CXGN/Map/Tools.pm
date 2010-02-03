
=head1 NAME

CXGN::Map::Tools

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Non-object-oriented quick functions for getting random bits of data about maps.

=head2 is_current_version

    #example: make a new map object but only if we have the current version
    if(CXGN::Map::Tools::is_current_version($dbh,$map_version_id))
    {
        my $map=CXGN::Map->new({map_version_id=>$map_version_id});
    }

=head2 find_current_version

    #example: find the current map_version_id for a map_id
    my $map_version_id=CXGN::Map::Tools::find_current_version($map_id);

=head2 current_tomato_map_id

    returns 9. whatever.

=cut

use strict;

package CXGN::Map::Tools;

sub is_current_version
{    
    my ($dbh,$map_version_id)=@_;
    my $q=$dbh->prepare('select current_version from sgn.map_version where map_version_id=?');
    $q->execute($map_version_id);
    my ($current)=$q->fetchrow_array();
    return $current;   
}

sub find_current_version
{
    my ($dbh,$map_id)=@_;
    my $q=$dbh->prepare("select map_version_id from sgn.map_version where current_version='t' and map_id=?");
    $q->execute($map_id);
    my ($current)=$q->fetchrow_array();
    return $current; 
}

sub current_tomato_map_id {
	# returns the current Tomato EXPEN-2000 map, which I keep changing.
	return 9;
}

sub find_map_id_with_version { 
    my $dbh = shift;
    my $map_version_id = shift;
    my $q =$dbh->prepare("select map_id from sgn.map_version where map_version_id=?");
    $q->execute($map_version_id);
    my ($map_id) = $q->fetchrow_array();
    return $map_id;
}

1;
