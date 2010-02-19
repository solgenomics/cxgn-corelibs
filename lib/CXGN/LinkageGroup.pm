
=head1 NAME

CXGN::LinkageGroup - a class that deals with the 
sgn.linkage_group table.

=head1 DESCRIPTION

This class does basic things such as
accessing forlinkage_group_ids and their names
and storing linkage_group names 
and map_version_id to the sgn.linkage_group table.

=head1 AUTHORS

Isaak Y Tecle (iyt2@cornell.edu)


=head1 FUNCTIONS


=cut

use strict;
use CXGN::DB::Connection;
package CXGN::LinkageGroup;

=head2 new

 Usage:        my $map = CXGN::LinkageGroup->new($dbh, $map_version_id, $lg)
 Desc:         creates a new CXGN::Map object
 Ret:          
 Args:         - a database handle, if possible using 
                 CXGN::DB::Connection object
               - map_version_id 
               -an array ref of linkage groups to store linkage groups.
                Not needed if the goal is to access the linkage_groups
 Side Effects: 
 Example:

=cut

sub new {
    my $class = shift;
    my($dbh, $map_version_id, $linkage_groups) = @_;
    my $self = bless {}, $class;
   
    unless ($map_version_id) {die "You must provide a map_version_id\n";}
		    
    my $valid_map_version_id;
    if($map_version_id) {
	#think of better check, here.
	my $sth = $dbh->prepare("SELECT map_version_id 
                                        FROM sgn.map_version 
                                        WHERE map_version_id = ?");
	$sth->execute($map_version_id);
	$valid_map_version_id = $sth->fetchrow_array();
    }

    unless ($valid_map_version_id) { die "No such map version id: $map_version_id exists\n"};
    
    my (@linkage_groups, @lg_ids, $lg_ids);
    if ($linkage_groups) {
        if (@{$linkage_groups}) {
            for my $lg_name(@{$linkage_groups}) {
		# one digit, optionally followed by another, optionally followed 
		# by a lowercase letter--modify this regex if needed

		print STDERR "Linkage group: $lg_name\n";
                unless ($lg_name=~/^\d\d?[a-z]?$/) {
                    die "'$lg_name' is not a valid linkage group name";
                }                
            }          
        }
        else {

	   my $sth = $dbh->prepare("SELECT lg_id, lg_name 
                                           FROM sgn.linkage_groups 
                                           WHERE sgn.map_version_id = ? 
                                           AND current_version = 't'"
	                         );
	   $sth->execute($valid_map_version_id);

	   while (my ($lg_id, $lg_name) = $sth->fetchrow_array()) {
	       push @lg_ids, $lg_id;
	       push @linkage_groups, $lg_name;
	       
	       $lg_ids = \@lg_ids;
	       $linkage_groups = \@linkage_groups;
	   }

	   unless (@lg_ids) { die "(1) You have not provided the linkage_group names 
                                    for the new map version or \n 
                                (2) for the map_version_id you provided there 
                                    are no existing linkage groups associated with it\n";
	   }
	}	
    }
    
    $self->set_linkage_group_ids($lg_ids);
    $self->set_linkage_groups($linkage_groups);
    $self->set_map_version_id($valid_map_version_id);
    $self->set_dbh($dbh); 

    return $self;   

}



sub store {
    my $self = shift;    

    my $map_version_id = $self->get_map_version_id();
    
    die "Valid map_version_id is required!\n" unless ($map_version_id); 
    
    my $i = 1; 
    foreach my $lg (@{$self->get_linkage_groups()}) {    
	
	my $sth = $self->get_dbh()->prepare("INSERT INTO sgn.linkage_group 
                                                    (map_version_id, lg_order, lg_name) 
                                                    VALUES (?, ?, ?)"
	    );
	$sth->execute(
	             $map_version_id,
	             $i,
	             $lg
	            );
	
	print STDERR "INSERTING LINKAGE_GROUP $lg 
                      of MAP_VERSION_ID: $map_version_id\n";
	$i++;
    
    }


    if ($@) {
	print $@;
	print STDERR "Failed storing linkage groups\n";
	return 0;
    }
    else { 
	return 1;
    }    
}

=head2 accessors set_dbh, get_dbh

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_dbh { 
    my $self=shift;
    return $self->{dbh};
}

sub set_dbh { 
    my $self=shift;
    $self->{dbh}=shift;
}

=head2 accessors set_map_version_id, get_map_version_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_map_version_id { 
    my $self=shift;
    return $self->{map_version_id};
}

sub set_map_version_id { 
    my $self=shift;
    $self->{map_version_id}=shift;
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
    return $self->{linkage_groups};
}

sub set_linkage_groups { 
    my $self=shift;
    $self->{linkage_groups}=shift;
}

=head2 accessors set_linkage_group_ids, get_linkage_group_ids

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_linkage_group_ids { 
    my $self=shift;
    return $self->{linkage_group_ids};
}

sub set_linkage_group_ids { 
    my $self=shift;
    $self->{linkage_group_ids}=shift;
}

=head2 accessors set_map_version_id, get_map_version_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_map_version_id { 
    my $self=shift;
    return $self->{map_version_id};
}

sub set_map_version_id { 
    my $self=shift;
    $self->{map_version_id}=shift;
}

=head2 get_lg_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_lg_id {
    my $self = shift;
    my $lg = shift;
   # my $map_version_id = shift;
    my $sth = $self->get_dbh()->prepare("SELECT lg_id 
                                                 FROM sgn.linkage_group 
                                                 WHERE lg_name = ? 
                                                 AND map_version_id = ?"
                                       );

    $sth->execute($lg, $self->get_map_version_id());
    my $lg_id = $sth->fetchrow_array();

    if ($lg_id) { 
	return $lg_id;
    } else { 
	return undef;
    }
   

}


return 1;

