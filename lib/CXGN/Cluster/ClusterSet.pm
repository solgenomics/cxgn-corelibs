


=head1 NAME CXGN::Cluster::ClusterSet

CXGN::Cluster::ClusterSet - a package to manage sets of preclusters

=head1 DESCRIPTION

This package keeps track of all the sequence ids that are being clustered, and builds hashes for fast access to determine if a sequence is already in a cluster. It has a function, add_match, that takes two ids and adds them to existing clusters or creates a new cluster if applicable.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

use strict;

package CXGN::Cluster::ClusterSet;

use base qw( CXGN::Cluster::Object );

=head2 new()

 Usage:        my $cluster_set = CGN::Cluster::ClusterSet->new()
 Desc:         Constructor
 Ret:          a cluster set object
 Args:         none
 Side Effects: none

=cut

sub new { 
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    $self->reset_unique_key();
    keys(%{$self->{key_hash}})=100000;
    return $self;
}

=head2 add_match()

 Usage:        $cluster_set -> add_match($query_id, $subject_id)
 Desc:         this function checks if the query and subject ids are
               already in clusters; if they are in the same cluster
               the function does nothing, if only subject id or query 
               id are in a cluster, the other is added to that same
               cluster, and if both are in different clusters, the two
               clusters are pulled together.
 Ret:
 Args:         two ids representing the match.
 Side Effects:
 Example:

=cut


sub add_match { 
    my $self = shift;
    my $query_id = shift;
    my $subject_id = shift;
#    $self->set_debug(1);
    if (!$query_id || !$subject_id) { 
	$self->debug("Ignoring $query_id and $subject_id - incomplete match.\n");
	return;
    }

    my $c1 = $self->get_cluster($query_id);
    my $c2 = $self->get_cluster($subject_id);
    if ( ($c1 && $c2) && ($c1 == $c2) ) { 
	$self->debug(" [ ignoring both in ".$c1->get_unique_key()."]\n");
	# do nothing, because both have already been added
	# to the same precluster
    }
    elsif ( ($c1 && $c2) && ($c1 != $c2) ) { 
	$self->debug("IDs already in distinct clusters. Combining...\n");
	# we have a problem because the two have 
	# already been assigned to distinct sub-clusters.
	# we need to pull the clusters together.
	$self->debug("Before combining: " 
		     .$c1->get_unique_key().":".$c1->get_size().
		     " ".$c2->get_unique_key().":".$c2->get_size()."\n");
	$c1->combine($c2);
	$self->debug("After combining: "
		     .$c1->get_unique_key().":".$c1->get_size()."\n");
    }
    elsif ($c1 && !$c2) { 
	$self->debug("query $query_id already in cluster [".$c1->get_unique_key()."], adding $subject_id\n");
	$c1->add_member($subject_id);	    
	$self->debug("Now containing ".$c1->get_size()." members.\n");
    }
    elsif (!$c1 && $c2) { 
	$self->debug("subject $subject_id already in cluster [".$c2->get_unique_key()."], adding $query_id\n");
	$c2->add_member($query_id);
    }
    else { 
	$self->debug("creating new cluster...\n");
	# there is no cluster yet...
	# generate a new cluster
	my $new = CXGN::Cluster::Precluster->new($self);
	$self->add_cluster($new);
	$new->add_member($query_id);
	$new->add_member($subject_id);
	$new->debug($self->get_debug());
    }
}

=head2 add_cluster()

 Usage:        $cluster_set->add_cluster($c)
 Desc:         adds a new cluster, $c, to the cluster set. 
               The cluster will be tracked through the 
               internal cluster key hash for fast access.
 Ret:          nothing meaningful
 Args:         a CXGN::Cluster::Precluster to add to this set

=cut

sub add_cluster { 
    my $self = shift;
    my $cluster = shift;
#    my $unique_key = $cluster->get_unique_key();
    $self->add_key_hash($cluster);
}

sub add_key_hash { 
    my $self = shift;
    my $cluster = shift;
    my $unique_key = $cluster->get_unique_key();
    $self->{key_hash}{$unique_key}=$cluster;
}

=head2 remove_cluster()

 Usage: $set->remove_cluster($c);
 Desc:  remove the cluster from this set
 Ret:   nothing meaningful
 Args:  CXGN::Cluster::Precluster to remove

=cut

sub remove_cluster { 
    my $self = shift;
    my $cluster = shift;
    $self->debug("Deleting cluster ".$cluster->get_unique_key()."...\n");
    delete($self->{key_hash}{$cluster->get_unique_key()});
}

=head2 get_clusters()

 Usage: $set->get_clusters
 Desc: gets all clusters as list of CXGN::Cluster::Precluster
       objects
 Ret:  list of CXGN::Cluster::Precluster objects, in ascending
       order of number of members
 Args: nothing

=cut

sub get_clusters { 
    my $self = shift;

    return sort {$a->get_member_count <=> $b->get_member_count}
           values %{$self->{key_hash}};
}

=head2 add_id()

 Usage:
 Desc:         add a seq id to the cluster hash for fast 
               cluster retrieval using a seq id.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_id { 
    my $self = shift;
    my $cluster = shift;
    my $id = shift;
    if (!$id || !$cluster) { die "need cluster object and id"; }
    $self->{id_map}{$id}=$cluster;
}

=head2 get_cluster()

 Usage:
 Desc:         gets the cluster that contains the sequence with id $id.
               see also add_id().
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cluster { 
    my $self = shift;
    my $id = shift;
    if (!$id) { die "get_cluster: need an id!\n"; }
    return $self->{id_map}{$id};
}

=head2 generate_unique_key()

 Usage:        my $key = $cluster_set->generate_unique_key()
 Desc:         returns a new unique key for a cluster. Unique
               keys are simply generated by added 1 to the previous
               key.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub generate_unique_key {
    my $self=shift;
    return ($self->{unique_key})++;
}

=head2 reset_unique_key()

 Usage:        $cluster_set->reset_unique_key()
 Desc:         resets the unique key to 0. Should not
               be called during normal operation, because
               keys will not be unique anymore.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub reset_unique_key {
    my $self=shift;
    $self->{unique_key}=0;
}

return 1;
