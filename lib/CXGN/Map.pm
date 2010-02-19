
=head1 NAME

CXGN::Map - classes to get information on SGN mapping information and to add new map and map version data (new_map, store, & map_version functions).

=head1 DESCRIPTION

This class was originally written to retrieve data on genetic maps in the SGN database. However, map types multiplied and this class was re-written as a factory object producing a map object of the appropriate type - genetic, fish, individual, user, etc. These map objects are defined in the CXGN::Map:: namespace. Previous documentation mentioned the existence of a CXGN::Map::Storable class, however, this never seemed to exist and the new map interface and subclasses have been written as read/write objects.

The "new" function has been re-cast to act as a factory object and will produce the right type of Map object given the appropriate parameters, which are defined as follows:

 parameter       map type
 ---------       --------
 map_id          genetic or fish
 map_version_id  genetic or fish
 user_map_id     user_map
 population_id   IL map
 individual_id   indivdual_map

Note that much of the functionality of this class has been factored out into a CXGN::LinkageGroup object, which also exists in different incarnations for the different map types.

=head1 AUTHORS

John Binns <zombieite@gmail.com>, Lukas Mueller (lam87@cornell.edu) and Isaak Y Tecle (iyt2@cornell.edu)



=head1 FUNCTIONS

This class defines the following functions to be implemented by the subclasses, and keeps the old functions for compatibility (see deprecated functions below).

=cut

use strict;
use CXGN::DB::Connection;
use CXGN::Map::Version;
package CXGN::Map;

=head2 new

 Usage:        my $map = CXGN::Map->new($dbh, {map_version_id=>30})
 Desc:         creates a new CXGN::Map object
 Ret:          
 Args:         - a database handle, if possible using 
                 CXGN::DB::Connection object
               - a hashref, containing either a key map_id or a key 
                 map_version_id, but not both!
 Side Effects: 
 Example:

=cut

sub new {
    my $class=shift;
    my($dbh,$map_info)=@_;
    my $self=bless({},$class);
    unless(CXGN::DB::Connection::is_valid_dbh($dbh)){die"Invalid DBH";}
    ref($map_info) eq 'HASH' or die"Must send in a dbh and hash ref with a map_id key or a map_version_id key";
    $self->{map_version_id}=$map_info->{map_version_id};
    $self->{map_id}=$map_info->{map_id};
   
    my $map_id_t = $self->{map_id};
    print STDERR "map id: $map_id_t from map object\n";
    if($self->{map_id})
    {
        if($self->{map_version_id})
        {
            die"You must only send in a map_id or a map_version_id, not both";
        }
        my $map_version_id_q=$dbh->prepare("SELECT map_version_id 
                                                   FROM map_version 
                                                   WHERE map_id=? 
                                                   AND current_version='t'"
                                           );
        $map_version_id_q->execute($self->{map_id});
        ($self->{map_version_id})=$map_version_id_q->fetchrow_array();
    }
   $self->{map_version_id} or return undef;
    my $general_info_q=$dbh->prepare
    ('
        select 
            map_id,
            map_version_id,
            date_loaded,
            current_version,
            short_name,
            long_name,
            abstract,
            map_type,
            population_id,
            has_IL,
            has_physical
        from
            map_version
            inner join map using (map_id)
        where
            map_version_id=?
    ');
    $general_info_q->execute($self->{map_version_id});
    (
        $self->{map_id},
        $self->{map_version_id},
        $self->{date_loaded},
        $self->{current_version},
        $self->{short_name},
        $self->{long_name},
        $self->{abstract},
        $self->{map_type},
        $self->{population_id},
        $self->{has_IL},
        $self->{has_physical}
       
    )=$general_info_q->fetchrow_array();
    if(!$self->{map_version_id}){return undef;}
    my $linkage_q=$dbh->prepare('SELECT linkage_group.lg_id AS lg_id,linkage_group.map_version_id AS map_version_id,
                                         lg_order,lg_name, min(position) AS north_centromere, MAX(position) AS south_centromere 
                                        FROM linkage_group 
                                        LEFT JOIN marker_location ON (north_location_id=location_id 
                                             OR south_location_id=location_id) 
                                        WHERE linkage_group.map_version_id=? 
                                        GROUP BY linkage_group.lg_id, linkage_group.map_version_id, 
                                                 lg_order, lg_name order by lg_order');
    $linkage_q->execute($self->{map_version_id});
    while(my $linkage_group=$linkage_q->fetchrow_hashref())
    {
        push(@{$self->{linkage_groups}},$linkage_group);
    }
    return $self;
}

sub store {
    my $self = shift;
    my $dbh = CXGN::DB::Connection->new();
    my $map_id = $self->get_map_id();
    print STDERR "map id from store: $map_id\n";
    if ($map_id) {
	my $sth = $dbh->prepare("UPDATE sgn.map SET 
                                        short_name = ?,
                                        long_name  = ?,
                                        abstract   = ?,
                                        map_type   = ?,
                                        parent_1   = ?,
                                        parent_2   = ?,
                                        units       = ?,
                                        population_id = ?
				  WHERE map_id = ?"
	    );
	$sth->execute($self->{short_name},
		      $self->{long_name},
		      $self->{abstract},
		      $self->{map_type},
		      $self->{parent_1},
		      $self->{parent_2},
		      $self->get_units(),
                      $self->{population_id},
		      $map_id
	    );

	print STDERR "Storing map data... \n";
	print STDERR "updated map id: $map_id\n";
	 #$dbh->last_insert_id("map", "sgn");
	return $map_id;

    } else { 
	print STDERR "No map id\n";
	return 0;
    }

    
}

sub new_map {
    my $self=shift;
    my $dbh = shift;
    my $name = shift;
    my ($map_id, $sth);

    print STDERR "Short map name: $name\n";
    if ($name) {
	$sth = $dbh->prepare("SELECT map_id 
                                     FROM sgn.map 
                                     WHERE short_name ILIKE ?"
                           );
	$sth->execute($name);
	$map_id = $sth->fetchrow_array();
      print STDERR "Map Id: $map_id\n";
    }
     else { 
	print STDERR "Provide map name, please.\n";
	die "No map name provided!\n";
    }  

    unless ($map_id) {
	    $sth = $dbh->prepare("INSERT INTO sgn.map (short_name) VALUES (?)");
	    $sth->execute($name);
	    $map_id = $dbh->last_insert_id("map", "sgn");
	    print STDERR "stored new Map Id: $map_id\n";
    }
    
    my ($map, $map_version_id);
    if ($map_id) {
	$map_version_id = CXGN::Map::Version->map_version($dbh, $map_id);
	#$map_version_id= $self->map_version($dbh, $map_id);
	print STDERR "created map version_id: $map_version_id for map_id: $map_id\n";
	$map = CXGN::Map->new($dbh, {map_id=>$map_id});
	my $new_map_id = $map->{map_id};
	print STDERR "new_map function with map_id = $new_map_id.\n";
    
    }
    
        
    return $map;
}



=head2 accessors set_short_name, get_short_name

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_short_name { 
    my $self=shift;
    return $self->{short_name};
}

sub set_short_name { 
    my $self=shift;
    $self->{short_name}=shift;
}

=head2 accessors set_long_name, get_long_name

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_long_name { 
    my $self=shift;
    return $self->{long_name};
}

sub set_long_name { 
    my $self=shift;
    $self->{long_name}=shift;
}

=head2 accessors set_abstract, get_abstract

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_abstract { 
    my $self=shift;
    return $self->{abstract};
}

sub set_abstract { 
    my $self=shift;
    $self->{abstract}=shift;
}


=head2 accessors get_parent_1, set_parent_1

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_parent_1 {
  my $self = shift;
  return $self->{parent_1}; 
}

sub set_parent_1 {
  my $self = shift;
  $self->{parent_1} = shift;
}
=head2 accessors get_population_id, set_population_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_population_id {
  my $self = shift;
  return $self->{population_id}; 
}

sub set_population_id {
  my $self = shift;
  $self->{population_id} = shift;
}

=head2 get_map_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub set_map_id {
    my $self = shift;
    $self->{map_id}=shift;
}
sub get_map_id {
    my $self = shift;
    return $self->{map_id};

}



=head2 accessors set_linkage_groups, get_linkage_groups

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_linkage_groups { 
    my $self=shift;
    return @{$self->{linkage_groups}};
}

sub set_linkage_groups { 
    my $self=shift;
    @{$self->{linkage_groups}}=@_;
}

=head2 function add_linkage_group

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub add_linkage_group {
    my $self = shift;
    my $lg = shift;
    push @{$self->{linkage_groups}}, $lg;
}


=head2 accessors set_map_type, get_map_type

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_map_type { 
    my $self=shift;
    return $self->{map_type};
}

sub set_map_type { 
    my $self=shift;
    $self->{map_type}=shift;
}


=head2 function get_units

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_units {
    my $self=shift;
    if ($self->get_map_type() eq "genetic") { 
	return "cM";
    }
    elsif ($self->get_map_type() eq "fish") { 
	return "%";
    }
    elsif ($self->get_map_type() =~ /sequenc/) { 
	return "MB";
    }
    else { 
	return "unknown";
    }
}






=head1 DEPRECATED FUNCTIONS

These functions are still working but should not be used in new code.

Note that these functions only work as getters and not as setters.

=cut

=head2 function map_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut


sub map_id {
    my $self=shift;
    return $self->{map_id};
}

=head2 function map_version_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub map_version_id {
    my $self=shift;
    return $self->{map_version_id};
}

=head2 function short_name

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub short_name  {
    my $self=shift;
    return $self->{short_name};
}

=head2 function long_name

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub long_name  {
    my $self=shift;
    return $self->{long_name};
}

=head2 function abstract

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub abstract {
    my $self=shift;
    return $self->{abstract};
}

=head2 linkage_groups

 Usage:
 Desc:
 Ret:          a reference to an array of hashrefs with linkage group info.
               hash keys include lg_name and lg_order
 Args:
 Side Effects:
 Example:

=cut

sub linkage_groups {
    my $self=shift;
    if($self->{linkage_groups})
    {
        return $self->{linkage_groups};
    }
    else
    {
        return [];
    }
}

=head2 map_type

 Usage:
 Desc:
 Ret:          the type of the map, either 'fish' for a fish map
               or 'genetic' for a genetic map.
 Args:
 Side Effects:
 Example:

=cut

sub map_type {
    my $self = shift;
    return $self->{map_type};
}

=head2 has_IL

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub has_IL { 
    my $self = shift;
    return $self->{has_IL};
}

=head2 has_physical

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub has_physical { 
    my $self = shift;
    return $self->{has_physical};
}




=head2 get_chr_names

 Usage:
 Desc:         a shortcut function to get at the chromosome names,
               sorted by lg_order
 Ret:          a list of chromosome names.
 Args:
 Side Effects:
 Example:

=cut

sub get_chr_names { 
    my $self = shift;
    my $linkage_groups_ref = $self->linkage_groups();
    my @names = map $_->{lg_name}, @{$linkage_groups_ref};
    return @names;
}

=head2 has_linkage_group

 Usage:
 Desc:
 Ret:          1 if the string or number represents a linkage group
                 of this map
               0 if it doesn\'t
 Args:         a string or number describing a possible linkage
               group of this map
 Side Effects:
 Example:

=cut

sub has_linkage_group {
    my $self = shift;
    my $candidate = shift;
    chomp($candidate);
    $candidate=~ s/\s*(.*)\s*/$1/;
    foreach my $n (map $_->{lg_name} , @{$self->linkage_groups()}) { 
	#print STDERR "comparing $n with $candidate...\n";
	if ($candidate =~ /^$n$/i) { 
	    #print STDERR "Yip!\n";
	    return 1;
	}
    }
    return 0;
}

=head2 function get_centromere

  Synopsis:	my ($north, $south, $center) = $map->get_centromere($lg_name)
  Arguments:	a valid linkage group name
  Returns:	a three member list, the first element corresponds
                to the north boundary of the centromere in cM
                the second corresponds to the south boundary of 
                the centromere in cM, the third is the arithmetic mean
                of the two first values. 
  Side effects:	none
  Description:	

=cut

sub get_centromere { 
    my $self=shift;
    my $lg = shift;
    
    if (! $self->has_linkage_group($lg)) { 
	die "Not a valid linkage group for this map!\n"; 
    }
    
    my $lg_hash = $self->get_linkage_group_hash($lg);
#    foreach my $k (keys %$lg_hash) { 
#	print "   $k, $lg_hash->{$k}\n";
#    }
    my $north = $lg_hash->{north_centromere};
    my $south = $lg_hash->{south_centromere};
    return ($north, $south, int(($north+$south)/2));
}

sub get_linkage_group_hash { 
    my $self= shift;
    my $lg_name = shift;
    foreach my $lg_hash (@{$self->linkage_groups()}) { 
	if ($lg_hash->{lg_name} eq $lg_name) {
	    return $lg_hash;
	}
    }
    
}

return 1;

