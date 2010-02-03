


=head1 NAME

CXGN::Cview::MapFactory - a factory object for CXGN::Cview::Map objects
           
=head1 SYNOPSYS

my $map_factory  = CXGN::Cview::MapFactory->new($dbh);
$map = $map_factory->create({map_version_id=>"u1"});
         
=head1 DESCRIPTION

The MapFactory object is part of a compatibility layer that defines the data sources of the comparative mapviewer. If there are different types of maps that can be distinguished by their ids, the MapFactory should be implemented to return the right map object for the given id. Of course, the corresponding map object also needs to be implemented, using the interface defined in CXGN::Cview::Map .

The MapFactory constructor takes a database handle (preferably constructed using CXGN::DB::Connection object). The map objects can then be constructed using the create function, which takes a hashref as a parameter, containing either map_id or map_version_id as a key (but not both). map_ids will be converted to map_version_ids immediately. Map_version_ids are then analyzed and depending on its format, CXGN::Cview::Map object of the proper type is returned. 

The function get_all_maps returns all maps as list of appropriate CXGN::Cview::Map::* objects.

For the current SGN implementation, the following identifier formats are defined and yield following corresponding map objects

 \d+       refers to a map id in the database and yields either a
           CXGN::Cview::Map::SGN::Genetic (type genetic)
           CXGN::Cview::Map::SGN::FISH (type fish)
           CXGN::Cview::Map::SGN::Sequence (type sequence)
 u\d+      refers to a user defined map and returns:
           CXGN::Cview::Map::SGN::User object
 filepath  refers to a map defined in a file and returns a
           CXGN::Cview::Map::SGN::File object
 il\d+      refers to a population id in the phenome.population table
           (which must be of type IL) and returns a
           CXGN::Cview::Map::SGN::IL object
 p\d+      CXGN::Cview::Map::SGN::Physical
 c\d+      CXGN::Cview::Map::SGN::Contig
 o         CXGN::Cview::Map::SGN::ProjectStats map object
 
The actual map objects returned are defined in the CXGN::Cview::Maps namespace. Because this is really a compatibility layer, an additional namespace of the resource is appended, such that a genetic map at SGN could be defined as CXGN::Cview::Maps::SGN::Genetic . If no corresponding map is found, undef is returned.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 VERSION
 
1.0, March 2007

=head1 LICENSE

Refer to the L<CXGN::LICENSE> file.

=head1 FUNCTIONS

This class implements the following functions:

(See the superclass, CXGN::Cview::Maps, for a definition of the class interface)

=cut

use strict;

package CXGN::Cview::MapFactory::SGN;

use base qw| CXGN::DB::Object |;

use CXGN::Cview::Map::SGN::Genetic;
use CXGN::Cview::Map::SGN::User;
use CXGN::Cview::Map::SGN::Fish;
use CXGN::Cview::Map::SGN::Sequence;
use CXGN::Cview::Map::SGN::IL;
use CXGN::Cview::Map::SGN::Physical;
use CXGN::Cview::Map::SGN::ProjectStats;
use CXGN::Cview::Map::SGN::AGP;
use CXGN::Cview::Map::SGN::ITAG;
use CXGN::Cview::Map::SGN::Contig;

=head2 function new()

  Synopsis:	constructor
  Arguments:	none
  Returns:	a CXGN::Cview::MapFactory::SGN object
  Side effects:	none
  Description:	none

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    
    my $self = $class->SUPER::new($dbh);

    return $self;
}

=head2 function create()

  Description:  creates a map based on the hashref given, which 
                should either contain the key map_id or map_version_id 
                and an appropriate identifier. The function returns undef
                if a map of the given id cannot be found/created.
  Example:      

=cut

sub create { 
    my $self = shift;
    my $hashref = shift;
    
    #print STDERR "Hashref = map_id => $hashref->{map_id}, map_version_id => $hashref->{map_version_id}\n";
    
    if (!exists($hashref->{map_id}) && !exists($hashref->{map_version_id})) { 
	die "[CXGN::Cview::MapFactory] Need either a map_id or map_version_id.\n"; 
    }
    if ($hashref->{map_id} && $hashref->{map_version_id}) { 
	die "[CXGN::Cview::MapFactory] Need either a map_id or map_version_id - not both.\n";
    }
    if ($hashref->{map_id}) { 
	$hashref->{map_version_id}=CXGN::Cview::Map::Tools::find_current_version($self->get_dbh(), $hashref->{map_id}); 
    }
    
    # now, we only deal with map_versions...
    #
    my $id = $hashref->{map_version_id};

    #print STDERR "MapFactory: dealing with id = $id\n";

    # if the map_version_id is purely numeric, 
    # check if the map is in the maps table and generate the
    # appropriate map

    if ($id=~/^\d+$/) { 
	my $query = "SELECT map_version_id, map_type, map_id, short_name FROM sgn.map join sgn.map_version using(map_id) WHERE map_version_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($id);
	my ($id, $map_type) = $sth->fetchrow_array();
	if ($map_type =~ /genetic/i) { 
	    return CXGN::Cview::Map::SGN::Genetic->new($self->get_dbh(), $id);
	}
	elsif ($map_type =~ /fish/) { 
	    #print STDERR "Creating a fish map...\n";
	    return CXGN::Cview::Map::SGN::Fish->new($self->get_dbh(), $id);
	}
	elsif ($map_type =~ /seq/) { 
	    #print STDERR "Creating a seq map...\n";
	    return CXGN::Cview::Map::SGN::Sequence->new($self->get_dbh(), $id);
	}
    }
    elsif ($id =~ /^u/i) { 
	return CXGN::Cview::Map::SGN::User->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^il/i) { 
	return CXGN::Cview::Map::SGN::IL->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^\//) { 
	#return CXGN::Cview::Map::SGN::File->new($dbh, $id);
    }
    elsif ($id =~ /^p\d+/) { 
	return CXGN::Cview::Map::SGN::Physical->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^o$/i) { 
	return CXGN::Cview::Map::SGN::ProjectStats->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^agp$/i) { 
	return CXGN::Cview::Map::SGN::AGP->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^itag$/i) { 
	return CXGN::Cview::Map::SGN::ITAG->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^u\d+$/i) {
	return CXGN::Cview::Map::SGN::User->new($self->get_dbh(), $id);
    }
    elsif ($id =~ /^c\d+$/i) { 
	return CXGN::Cview::Map::SGN::Contig->new($self->get_dbh(), $id);
    }

    print STDERR "Map NOT FOUND!!!!!!!!!!!!!!!!!!\n\n";
    return undef;

}

=head2 function get_all_maps()

  Synopsis:	
  Arguments:	none
  Returns:	a list of all maps currently defined, as 
                CXGN::Cview::Map objects (and subclasses)
  Side effects:	Queries the database for certain maps
  Description:	

=cut

sub get_all_maps {
    my $self = shift;

    my @system_maps = $self->get_system_maps();
    my @user_maps = $self->get_user_maps();
    my @maps = (@system_maps, @user_maps);
    return @maps;
    
}


=head2 get_system_maps

  Usage:        my @system_maps = $map_factory->get_system_maps();
  Desc:         retrieves a list of system maps (from the sgn 
                database) as a list of CXGN::Cview::Map objects
  Ret:
  Args:
  Side Effects:
  Example:

=cut

sub get_system_maps {
    my $self = shift;

    my @maps = ();
    
    my $query = "SELECT map.map_id FROM sgn.map LEFT JOIN sgn.map_version USING(map_id) LEFT JOIN sgn.accession on(parent_1=accession.accession_id) LEFT JOIN sgn.organism USING(organism_id) LEFT JOIN common_name USING(common_name_id) WHERE current_version='t' ORDER by common_name.common_name";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute();

    while (my ($map_id) = $sth->fetchrow_array()) { 
	my $map = $self->create({ map_id => $map_id });
	if ($map) { push @maps, $map; }
    }

    # push il, physical, contig, and agp map
    #
    foreach my $id ("il6.5", "il6.9", "p9", "c9", "agp", "itag") { 
	my $map = $self->create( {map_id=>$id} );
	if ($map) { push @maps, $map; }
    }

    return @maps;
}



=head2 get_user_maps

 Usage:
 Desc:         retrieves the current user maps of the logged in user.
 Ret:          a list of CXGN::Cview::Map objects
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_user_maps {
    my $self = shift;
    # push the maps that are specific to that user and not public, if somebody is logged in...
    #
    my @maps = ();
    my $login = CXGN::Login->new($self->get_dbh());
    my $user_id = $login->has_session();
    if ($user_id) { 
	my $q3 = "SELECT user_map_id FROM sgn_people.user_map WHERE obsolete='f' AND sp_person_id=?";
	my $h3 = $self->get_dbh()->prepare($q3);
	$h3->execute($user_id);
	while (my ($user_map_id) = $h3->fetchrow_array()) { 
	    my $map = $self->create( {map_id=>"u".$user_map_id} );
	    
	    if ($map) { push @maps, $map; }
	}
    }
    return @maps;
}



return 1;
