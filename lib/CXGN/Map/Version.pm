
=head1 NAME

CXGN::Map::Version

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Object for creating a new map version.

=head2 

new

    #simple example (uses linkage group names from previous current version of this map)
    my $new_map_version=CXGN::Map::Version->new($dbh,{map_id=>$map_id});    

    #example where you want to base a new map_version on an old on (which in not necessarily a current one)
    my $new_map_version=CXGN::Map::Version->new($dbh,{map_version_id=>$map_version_id});

    #example where you have new linkage group names to define, because they have changed since the previous version.
    #linkage group order matters, and is taken from the order of the linkage group names in the list. 
    my $linkage_groups=['1','2','3','4','5','6','7a','7b','8','9','10','11','12'];
    my $new_map_version=CXGN::Map::Version->new($dbh,{map_id=>$map_id},$linkage_groups);

=head2

insert_into_database

    #note: this WILL INSERT data into the database... EVERY time you call it!
    #it is not like some of my other modules which do a "store_unless_exists".
    #calling it, say, 5 times, will store 5 new map versions (it was simpler 
    #to write this way). if you have created this map version from an existing 
    #map_version, this function will return a NEW map_version_id for the NEW 
    #row that you have inserted. 
    my $new_map_version_id=$new_map_version->insert_into_database();

=head2

set_current

    #how to make an existing map_version current
    my $existing_map_version=CXGN::Map::Version->new($dbh,{map_version_id=>$map_version_id});
    $existing_map_version->set_current(); 

=cut

use strict;
use CXGN::DB::Connection;
use CXGN::Map;
use CXGN::Tools::Text;

package CXGN::Map::Version;

sub new {    
    my $class = shift;
    my($dbh,$map_info,$linkage_groups) = @_;
    my $self = bless({},$class);
    CXGN::DB::Connection::is_valid_dbh($dbh) 
	or die "You must supply a dbh as the first argument";
    $self->{dbh} = $dbh;
    



    #just a test to make sure our map_id is valid
    unless (CXGN::Map->new($dbh,$map_info)) {
        die "Cannot create a map object, so this map ID or map_version_id "
#	    . "--\n\n".Dumper $map_info."\n\n-- "
	    . "is probably invalid";
    }



    $self->{map_id} = $map_info->{map_id};
    $self->{map_version_id} = $map_info->{map_version_id};

    # if the caller has specified a map_version_id, 
    # why would they also specify the linkage groups?
    # shouldn't they just specify a map_id and linkage groups instead? 
    # i don't think they know what they're doing.
    if ($self->{map_version_id} and $linkage_groups) {
        die "If you're specifying the linkage groups manually,"
	    . "there's no reason to import them by specifying a "
	    . "map_version_id. Specify a map_id and linkage groups instead.";
    }

    #if the caller is sending in linkage group names, use them
    if ($linkage_groups) {
        if (@{$linkage_groups}) {
            for my $lg_name(@{$linkage_groups}) {
		# one digit, optionally followed by another, optionally followed 
		# by a lowercase letter--modify this regex if needed
#                unless ($lg_name=~/^\d\d?(\.\d|[a-z]?)$/) {
#                    die "'$lg_name' is not a valid linkage group name";
#                }                
            }
            $self->{linkage_groups}=$linkage_groups;
        }
        else { die "No linkage groups found" }
    }
    # otherwise, use the linkage group names from the previous current version of this map
    else {
        my $sth;
        if ($self->{map_id}) {
	    my $select = "select lg_name,lg_order from map_version inner "
		. "join linkage_group using (map_version_id) where "
		. "current_version and map_id=? order by lg_order";
            $sth = $dbh->prepare($select);
            $sth->execute($self->{map_id});
        }
        elsif ($self->{map_version_id}) {
	    my $select = "select map_id from map_version where map_version_id=?";
            $sth = $dbh->prepare($select);
            $sth->execute($self->{map_version_id});
            ($self->{map_id}) = $sth->fetchrow_array();
            $self->{map_id} or die "Could not find map_id from map_version_id";
	    $select = "select lg_name,lg_order from map_version inner "
		. "join linkage_group using (map_version_id) where "
		. "map_version_id=? order by lg_order";
            $sth=$dbh->prepare($select);
            $sth->execute($self->{map_version_id});            
        }
        else {
            die "Oops, I seem to have no map_id or map_version_id "
		. "to base this new map version on";
        }
        while (my($lg_name)=$sth->fetchrow_array()) {
            push(@{$self->{linkage_groups}},$lg_name);
        }
    }    
    
    return $self;
}

#call this any old time, for debugging or informational purposes
sub as_string {
    my $self = shift;
    if ($self->{map_version_id}) {
	print "Map version ID: $self->{map_version_id}\n";
    }
    else {
	print "This object has no map_version_id.\nIt was not "
	    . "created from an existing map_version,\nand it has "
	    . "not yet been inserted into the database.\n";
    }
    print "Map ID: $self->{map_id}\n";
    print "Linkage group names (in order):\n";
    my @lgs = @{$self->{linkage_groups}};
    for my $lg(@lgs) {
	print "$lg\n";
    }
}

# note that this is NOT a "store_unless_exists"-type function.
# this method WILL INSERT a new map version in the database--EVERY time you call it!
sub insert_into_database {
    my $self = shift;
    my $dbh = $self->{dbh};
    my $insert = "insert into sgn.map_version (map_id,date_loaded) values (?,current_timestamp) RETURNING map_version.map_version_id";
    my $sth = $dbh->prepare($insert);
    $sth->execute($self->{map_id});
    #$self->{map_version_id} = 
    #$dbh->last_insert_id('map_version')
    ($self->{map_version_id}) = $sth->fetchrow_array()
	or die "Could not get last_insert_id from map_version table from dbh";
    # the other lg_order values currently in the db start with 1,
    # so i'm keeping this convention. it doesn't really matter
    # too much, since the only time lg_order is used (as far as i know)
    # is in an "order by" clause, which doesn't care what number you start with.
    my $lg_order=1;

    for my $lg_name (@{$self->{linkage_groups}}) {
	$insert = "insert into sgn.linkage_group "
	    . "(lg_name,lg_order,map_version_id) values (?,?,?)";
        my $sth = $dbh->prepare($insert);
        $sth->execute($lg_name,$lg_order,$self->{map_version_id});
        $lg_order++;
    }
    return $self->{map_version_id};
}

#this sets all other versions of the map to be not current and sets this one to be current
sub set_current {
    my $self = shift;
    my $dbh = $self->{dbh};
    $self->{map_id}
    or die "I can't set the other versions to be not current without knowing our map_id";
    $self->{map_version_id} 
    or die "I can't set myself to be current without knowing "
	. "what my map_version_id is--insert me into the database first";
    my $update = "update map_version set current_version='f' where map_id=?";
    my $sth = $dbh->prepare($update);
    $sth->execute($self->{map_id});
    $update = "update map_version set current_version='t' where map_version_id=?";
    $sth=$dbh->prepare($update);
    $sth->execute($self->{map_version_id});
}



sub map_version {
    my $self = shift;
    my $dbh = shift;
    my $map_id = shift;

    print STDERR "mapid from map_version func: $map_id\n";
    my ($map_version_id_old, $map_version_id_new, $sth);
    if ($map_id) {
	$sth = $dbh->prepare("SELECT map_version_id 
                                        FROM sgn.map_version 
                                        WHERE map_id =?");
	$sth->execute($map_id);
	$map_version_id_old = $sth->fetchrow_array();
    
   
	$sth = $dbh->prepare("INSERT INTO sgn.map_version (map_id, date_loaded) 
                                          VALUES (?, current_timestamp) RETURNING map_version.map_version_id"
                            );  
  
	$sth->execute($map_id);
	#	$map_version_id_new = $dbh->last_insert_id("map_version", "sgn") ;
	($map_version_id_new) = $sth->fetchrow_array();
	if (!$map_version_id_new) { die "did not insert new map version\n";
	}
	else {
	    print STDERR "stored new map version id: $map_version_id_new\n";
	}
    } else { die "map_version function: I need a map id to create map version\n";}


    if ($map_version_id_old) {
	
	my $sth = $dbh->prepare("UPDATE map_version 
                                        SET current_version='f' 
                                        WHERE map_version_id=?"
                                );
	$sth->execute($map_version_id_old);
    }
    if($map_version_id_new) {
	    $sth=$dbh->prepare("UPDATE map_version 
                                   SET current_version='t' 
                                   WHERE map_version_id=?"
                          );
	    $sth->execute($map_version_id_new);
	} else {die "I can't set myself to be current without knowing "
	. "what my map_version_id is--insert me into the database first";
	}
    
    return $map_version_id_new;

}


1;
