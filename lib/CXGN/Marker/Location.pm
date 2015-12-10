package CXGN::Marker::Location;

=head1 NAME

CXGN::Marker::Location;

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Location object. It's a very simple match to the marker_location table in the database, but it has a little bit of intelligence too.

=cut

use Modern::Perl;
use CXGN::Marker::Tools;
use CXGN::DB::Connection;
use CXGN::Tools::Text;
use Carp;

=head2 new

    my $location=CXGN::Marker::Location->new($dbh,$location_id);

Takes a dbh and a location_id and returns an object representing little more than a row in the marker_location table.

    my $location=CXGN::Marker::Location->new($dbh);

Takes a dbh and returns an empty object which can perform an insert into the marker_location table.

=cut

sub new {
    my $class = shift;
    my ( $dbh, $id ) = @_;
    unless ( CXGN::DB::Connection::is_valid_dbh($dbh) ) {
        croak "Invalid DBH";
    }
    my $self = bless( {}, $class );
    $self->{dbh} = $dbh;
    if ($id) {
        my $q = $dbh->prepare( '
            select 
                marker_id,
                location_id,
                lg_id,
                lg_name,
                marker_location.map_version_id,
                position,
                confidence_id,
                confidence_name as confidence,
                subscript
            from 
                marker_experiment
                inner join marker_location using (location_id)
                inner join linkage_group using (lg_id)
                inner join marker_confidence using (confidence_id)
            where 
                location_id=?
        ' );
        $q->execute($id);
        my $hr = $q->fetchrow_hashref();
        while ( my ( $key, $value ) = each %$hr ) {
            $self->{$key} = $value;
        }
    }
    return $self;
}

=head2 location_id

    my $id=$location->location_id();

Gets location ID. Cannot set it since it is either retrieved from the database or sent in to the constructor.

=cut

#this is not a setter, since these ids are assigned by the database
sub location_id {
    my $self = shift;
    return $self->{location_id};
}

=head2 marker_id, lg_name, map_version_id, position, confidence, subscript

Getters/setters.

=cut

sub marker_id {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value =~ /^\d+$/ ) {
            croak "Marker ID must be a number, not '$value'";
        }
        unless (
            CXGN::Marker::Tools::is_valid_marker_id( $self->{dbh}, $value ) )
        {
            croak "Marker ID '$value' does not exist in the database";
        }
        $self->{marker_id} = $value;
    }
    return $self->{marker_id};
}

sub lg_name {
    my $self = shift;
    my ($lg_name) = @_;
    if ($lg_name) {
        unless ( $self->{map_version_id} ) {
            croak
"You must set this object's map_version_id before throwing around lg_names like that, else how can it know what map_version those lg_names are on?";
        }
        my $lg_id =
          CXGN::Marker::Tools::get_lg_id( $self->{dbh}, $lg_name,
            $self->{map_version_id} );
        unless ($lg_id) {
            croak
"Linkage group '$lg_name' does not exist on map_version_id '$self->{map_version_id}'";
        }
        $self->{lg_id}   = $lg_id;
        $self->{lg_name} = $lg_name;
    }
    return $self->{lg_name};
}

sub lg_id {
    my $self  = shift;
    my $lg_id = shift;
    if ($lg_id) {
        unless ( $self->{map_version_id} ) {
            croak
"You must set map_version_id before trying to set lg_id. Thanks!\n";
        }
        $self->{lg_id} = $lg_id;
    }
    return $self->{lg_id};
}

sub map_version_id {
    my $self = shift;
    my ($map_version_id) = @_;
    if ($map_version_id) {
        unless ( $map_version_id =~ /^\d+$/ ) {
            croak "Map version ID must be an integer, not '$map_version_id'";
        }
        $self->{map_version_id} = $map_version_id;
    }
    return $self->{map_version_id};
}

sub position {
    my $self = shift;
    my ($position) = @_;
    if ( $self->{position} ) {
	if ( $self->{position} =~ /\-/ )
	{    # if position describes a range, such as a QTL

	    ( $self->{position_north}, $self->{position_south} ) = split "-",
	    $self->{position};
	    $self->{position} =
		( $self->{position_south} + $self->{position_north} ) / 2;
	}
    }
    if ( defined($position) ) {
        unless ( CXGN::Tools::Text::is_number($position) ) {
            print STDERR
              "Position must be a floating-point number, not '$position'";
        }
        $self->{position} = $position;
    }
    return $self->{position};
}

sub confidence {
    my $self = shift;
    my ($confidence) = @_;
    if ($confidence) {
        my $confidence_id;
        $confidence_id =
          CXGN::Marker::Tools::get_marker_confidence_id( $self->{dbh},
            $confidence );
        unless ( defined($confidence_id) ) {
            croak "Confidence ID not found for confidence '$confidence'";
        }
        $self->{confidence_id} = $confidence_id;
        $self->{confidence}    = $confidence;
    }
    return $self->{confidence};
}

sub subscript {
    my $self = shift;
    my ($subscript) = @_;
    if ($subscript) {
        $subscript = uc($subscript);
        unless ( $subscript =~ /^[ABC]$/ ) {
            croak "Subscript must be a 'A', 'B', or 'C', not '$subscript'";
        }
        $self->{subscript} = $subscript;
    }
    return $self->{subscript};
}

=head2 equals

    if($location1->equals($location2)){print"Location 1 and 2 are the same.";}

Takes another location object and tells you if it is equivalent to the first location object.

=cut

sub equals {
    my $self = shift;
    my ($other) = @_;
    no warnings 'uninitialized';
    if (    $self->{marker_id} == $other->{marker_id}
        and $self->{lg_id} == $other->{lg_id}
        and $self->{map_version_id} == $other->{map_version_id}
        and $self->{position} == $other->{position}
        and $self->{confidence} eq $other->{confidence}
        and $self->{subscript}  eq $other->{subscript} )
    {
        return 1;
    }
    return 0;
}

=head2 exists

    if($location->exists()){print"Location exists in database.";}

Returns its location_id if location is already in the database, or undef if not. Mainly used by store_unless_exists. 

=cut

sub exists {
    my $self = shift;
    unless ( $self->{marker_id} ) {
        croak
"Cannot test for a location's existence without knowing which marker it goes with--store marker and set experiment's marker ID before storing locations";
    }
    unless ( $self->{lg_id} ) {
        croak
"You really should have an lg_id set before testing for a location's existence";
    }
    unless ( $self->{map_version_id} ) {
        croak
"You really should have a map_version_id set before testing for a location's existence";
    }
    unless ( defined( $self->{position} ) ) {
        croak
"You really should have a position set before testing for a location's existence";
    }
    unless ( defined( $self->{confidence_id} ) ) {
        croak
"You really should have a confidence_id set before testing for a location's existence";
    }
    if ( $self->{location_id} ) {

#warn"I think it's pretty obvious that this location exists, since it seems to have been loaded from the database, or recently stored to the database--it already has an id of $self->{location_id}";
        return $self->{location_id};
    }
    my $dbh = $self->{dbh};
    my $q;
    $q = $dbh->prepare(
        '    
        select 
            distinct location_id
        from 
            marker_location 
            inner join marker_experiment using (location_id)
        where
            marker_id=?
            and lg_id=? 
            and marker_location.map_version_id=? 
            and position=? 
            and confidence_id=?
            and not(subscript is distinct from ?)  
    '
    );
    $q->execute(
        $self->{marker_id}, $self->{lg_id},         $self->{map_version_id},
        $self->{position},  $self->{confidence_id}, $self->{subscript}
    );
    my %found_location_ids
      ; #a place to keep all location IDs that match for this marker, for use in error checking in a moment
    my ($location_id) = $q->fetchrow_array();
    if ($location_id)    #if we found some matching locations for this marker
    {
        $self->{location_id} = $location_id
          ; #get the ID of the existing row in the database so we know we've already been stored
        $found_location_ids{$location_id} =
          1;    #make a note of the location ID found
        while ( my ($other_location_id) =
            $q->fetchrow_array() )    #grab all other location IDs
        {
            $found_location_ids{$other_location_id} = 1;
        }
        if (
            keys(%found_location_ids) > 1
          ) #if we found more than one matching location ID, then the database data is not how we expect it to be
        {
            die "Multiple locations found like\n"
              . $self->as_string()
              . "Locations found: "
              . CXGN::Tools::Text::list_to_string( keys(%found_location_ids) );
        }
        return $self->{location_id};
    }
    return;
}

=head2 exists_with_any_confidence

Checks to see if a location exists, but not knowing its confidence. Used by CAPS loading scripts which know which location
the PCR experiment maps to, but they do not know the confidence.

    $loc->exists_with_any_confidence() or die"Could not find location:\n".$loc->as_string()."in database--load locations first, before running this script";

=cut

sub exists_with_any_confidence {
    my $self = shift;
    unless ( $self->{marker_id} ) {
        croak
"Cannot test for a location's existence without knowing which marker it goes with--store marker and set experiment's marker ID before storing locations";
    }
    unless ( $self->{lg_id} ) {
        croak
"You really should have an lg_id set before testing for a location's existence";
    }
    unless ( $self->{map_version_id} ) {
        croak
"You really should have a map_version_id set before testing for a location's existence";
    }
    unless ( defined( $self->{position} ) ) {
        croak
"You really should have a position set before testing for a location's existence";
    }
    if ( defined( $self->{confidence_id} ) ) {
        croak
"You have a confidence_id set--why not just use the 'exists' function instead?";
    }
    if ( $self->{location_id} ) {

#warn"I think it's pretty obvious that this location exists, since it seems to have been loaded from the database, or recently stored to the database--it already has an id of $self->{location_id}";
        return $self->{location_id};
    }
    my $dbh = $self->{dbh};
    my $q;
    $q = $dbh->prepare(
        '    
        select 
            distinct location_id
        from 
            marker_location 
            inner join marker_experiment using (location_id)
        where
            marker_id=?
            and lg_id=? 
            and map_version_id=? 
            and position=? 
            and not(subscript is distinct from ?)  
    '
    );
    $q->execute(
        $self->{marker_id}, $self->{lg_id}, $self->{map_version_id},
        $self->{position},  $self->{subscript}
    );
    my %found_location_ids
      ; #a place to keep all location IDs that match for this marker, for use in error checking in a moment
    my ($location_id) = $q->fetchrow_array();
    if ($location_id)    #if we found some matching locations for this marker
    {
        $self->{location_id} = $location_id
          ; #get the ID of the existing row in the database so we know we've already been stored
        $found_location_ids{$location_id} =
          1;    #make a note of the location ID found
        while ( my ($other_location_id) =
            $q->fetchrow_array() )    #grab all other location IDs
        {
            $found_location_ids{$other_location_id} = 1;
        }
        if (
            keys(%found_location_ids) > 1
          ) #if we found more than one matching location ID, then the database data is not how we expect it to be
        {
            die "Multiple locations found like\n"
              . $self->as_string()
              . "Locations found: "
              . CXGN::Tools::Text::list_to_string( keys(%found_location_ids) );
        }
        return $self->{location_id};
    }
    return;
}

=head2 store_unless_exists

    my $location_id,$existing_location_id,$new_location_id;
    $location_id=$new_location_id=$location->store_unless_exists();
    unless($location_id)
    {
        $location_id=$existing_location_id=$location->location_id();    
    }    

Makes a database insert unless a similar row exists. Returns a location_id ONLY if a new insert was made. If a matching entry was found, location_id is now set, but not returned.

=cut

sub store_unless_exists {
    my $self = shift;
    if ( $self->exists() ) { return; }
    unless ( $self->{lg_id} ) {
        croak "No lg_id set";
    }
    unless ( $self->{map_version_id} ) {
        croak "No map_version_id set";
    }
    unless ( defined( $self->{position} ) ) {
        croak "No position set";
    }
    unless ( defined( $self->{confidence_id} ) ) {
        croak "No confidence set";
    }
    my $dbh = $self->{dbh};

    my $statement =
'insert into sgn.marker_location (lg_id,map_version_id,position,confidence_id,subscript, position_north, position_south) values (?,?,?,?,?,?,?)';
    my @values = (
        $self->{lg_id},     $self->{map_version_id},
        $self->{position},  $self->{confidence_id},
        $self->{subscript}, $self->{position_north},
        $self->{position_south}
    );
    my $q = $dbh->prepare($statement);

    #print STDERR "$statement; (@values)\n";
    $q->execute(@values);
    $self->{location_id} = $dbh->last_insert_id('marker_location')
      or croak "Can't find last insert id for location " . $self->as_string();
    return ( $self->{location_id} );
}

=head2 as_string

    print $location->as_string();

Prints a location string for debugging.

=cut

sub as_string {
    my $self   = shift;
    my $string = "<location>\n";
    $string .=
      "\tmarker_id: '$self->{marker_id}'\tsubscript: '$self->{subscript}'\n";
    $string .=
"\tlg_name: '$self->{lg_name}'\tlg_id: '$self->{lg_id}'\tposition: '$self->{position}'\n";
    $string .=
"\tlocation_id: '$self->{location_id}'\tmap_version_id: '$self->{map_version_id}'\n";
    $string .=
"\tconfidence: '$self->{confidence}'\tconfidence_id: '$self->{confidence_id}'\n";
    $string .= "</location>\n";
    return $string;
}

1;
