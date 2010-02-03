
=head1 NAME

CXGN::Transcript::UnigeneBuild;

=head1 DESCRIPTION

Deals with the concept of a unigene build. Maps quite well to the sgn.unigene_build table.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class defines the following methods:

=cut

use strict;

package CXGN::Transcript::UnigeneBuild;

use CXGN::DB::Connection;
use CXGN::DB::Object;

use base qw| CXGN::DB::Object |;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;

    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->set_unigene_build_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 fetch

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT unigene_build_id, source_data_group_id, organism_group_id, build_nr, build_date, method_id, status, unigene_build.comment, superseding_build_id, next_build_id, latest_build_id, blast_db_id, groups.comment FROM sgn.unigene_build JOIN sgn.groups ON (organism_group_id=groups.group_id) WHERE unigene_build_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_build_id());
    my ($unigene_build_id, $source_data_group_id, $organism_group_id, $build_nr, $build_date, $method_id, $status, $comment, $superseding_build_id, $next_build_id, $latest_build_id, $blast_db_id, $organism_group_name) = 
	$sth->fetchrow_array();
    
    $self->set_unigene_build_id($unigene_build_id);
    $self->set_source_data_group_id($source_data_group_id);
    $self->set_organism_group_id($organism_group_id);

    $self->set_build_nr($build_nr);
    $self->set_build_date($build_date);
    $self->set_method_id($method_id);
    $self->set_status($status);
    $self->set_comment($comment);
    $self->set_superseding_build_id($superseding_build_id);
    $self->set_next_build_id($next_build_id);
    $self->set_latest_build_id($latest_build_id);
    $self->set_blast_db_id($blast_db_id);
    
    $self->set_organism_group_name($organism_group_name);
}

=head2 store
    
 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store {
    die "store not implemented for CXGN::Transcript::UnigeneBuild\n";
}


=head2 get_active_build_ids

 Usage:        my @build_ids = CXGN::Transcript::UnigeneBuilds::get_active_build_ids($dbh)
 Desc:
 Ret:          all build ids that have status='C'
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_active_build_ids {
    my $dbh = shift;
    my $query = "SELECT unigene_build_id FROM unigene_build WHERE status='C' order by unigene_build_id desc";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @build_ids = ();
    while (my ($build_id) = $sth->fetchrow_array()) { 
	push @build_ids, $build_id;
    }
    return @build_ids;

}

=head2 get_all_build_ids

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_all_build_ids {
    my $dbh = shift;
    my $query = "SELECT unigene_build_id FROM unigene_build order by unigene_build_id desc";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @build_ids = ();
    while (my ($build_id) = $sth->fetchrow_array()) { 
	push @build_ids, $build_id;
    }
    return @build_ids;

}



=head2 get_member_unigene_ids

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_member_unigene_ids {
    my $self = shift;
    my $query = "SELECT unigene_id FROM unigene WHERE unigene_build_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_build_id());
    my @unigene_ids = ();
    while (my ($unigene_id) = $sth->fetchrow_array()) { 
	push @unigene_ids, $unigene_id;
    }
    return @unigene_ids;
}




=head2 accessors get_unigene_build_id, set_unigene_build_id

 Usage:        my $build_id = $ub->get_unigene_build_id()
 Desc:         gets the build_id of the unigene build. This
               is the primary key of the table.
 Ret:          [int]
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_unigene_build_id {
    my $self=shift;
    return $self->{unigene_build_id};

}

sub set_unigene_build_id {
    my $self=shift;
    $self->{unigene_build_id}=shift;
}

=head2 accessors get_source_data_group_id, set_source_data_group_id

 Usage:        my $source_group = $ub->get_source_data_group_id()
 Desc:         gets the source group id, which is the group_id in the
               groups table identifying the group of all input 
               sequences (I think).
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_source_data_group_id {
  my $self=shift;
  return $self->{source_data_group_id};

}

sub set_source_data_group_id {
  my $self=shift;
  $self->{source_data_group_id}=shift;
}

=head2 accessors get_organism_group_id, set_organism_group_id
    
 Usage: 
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_group_id {
  my $self=shift;
  return $self->{organism_group_id};

}

sub set_organism_group_id {
  my $self=shift;
  $self->{organism_group_id}=shift;
}

=head2 get_organism_group_name, set_organism_group_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_group_name {
  my $self=shift;
  return $self->{organism_group_name};

}

sub set_organism_group_name {
  my $self=shift;
  $self->{organism_group_name}=shift;
}



=head2 accessors get_build_nr, set_build_nr

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_build_nr {
  my $self=shift;
  return $self->{build_nr};

}

sub set_build_nr {
  my $self=shift;
  $self->{build_nr}=shift;
}

=head2 accessors get_build_date, set_build_date

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_build_date {
  my $self=shift;
  return $self->{build_date};

}

sub set_build_date {
  my $self=shift;
  $self->{build_date}=shift;
}

=head2 accessors get_method_id, set_method_id

 Usage:
 Desc:         possibly a foreign key to some unknown or non-
               existent table describing the method. 
               Currently returns 2 for most builds.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_method_id {
  my $self=shift;
  return $self->{method_id};

}

sub set_method_id {
  my $self=shift;
  $self->{method_id}=shift;
}

=head2 accessors get_status, set_status

 Usage:        my $status = $ub->get_status()
 Desc:         retrieves the status of the unigene build.
               possibilities: 
               "C": Current
               "P": Previous (not current)
               "D": Deprecated 
 Ret:          one of the above
 Args:         
 Side Effects:
 Example:

=cut

sub get_status {
  my $self=shift;
  return $self->{status};
}

sub set_status {
  my $self=shift;
  $self->{status}=shift;
}

=head2 accessors get_comment, set_comment

 Usage:
 Desc:         provides the possibility to store a 
               comment with the unigene build. 
               As of 10/07, no comments have been
               stored.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_comment {
  my $self=shift;
  return $self->{comment};

}

sub set_comment {
  my $self=shift;
  $self->{comment}=shift;
}

=head2 accessors get_superseding_build_id, set_superseding_build_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_superseding_build_id {
  my $self=shift;
  return $self->{superseding_build_id};

}

sub set_superseding_build_id {
  my $self=shift;
  $self->{superseding_build_id}=shift;
}

=head2 accessors get_next_build_id, set_next_build_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_next_build_id {
  my $self=shift;
  return $self->{next_build_id};

}

sub set_next_build_id {
  my $self=shift;
  $self->{next_build_id}=shift;
}

=head2 accessors get_latest_build_id, set_latest_build_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_latest_build_id {
  my $self=shift;
  return $self->{latest_build_id};

}

sub set_latest_build_id {
  my $self=shift;
  $self->{latest_build_id}=shift;
}

=head2 get_common_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_common_name {
    my $self = shift;
    my $query = "SELECT distinct(common_name) FROM unigene_build JOIN group_linkage ON (unigene_build.organism_group_id=group_linkage.group_id) JOIN organism ON (group_linkage.member_id=organism.organism_id) JOIN common_name USING(common_name_id) WHERE unigene_build_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_build_id());
    my ($common_name) = $sth->fetchrow_array();
    return $common_name;
}

=head2 get_builds_with_common_name

 Usage: CXGN::Transcript::UnigeneBuild::get_builds_with_common_name($dbh, 1)
 Desc:  find the unigene builds for a common_name (see sgn.common_name table)
        Second argument will fetch only current builds.
 Ret:  list of unigeneBuild objects
 Args: dbh, and a flag for retrieving only current builds.  
 Side Effects: none
 Example:

=cut

sub get_builds_with_common_name {
    my $dbh=shift;
    my $common_name=shift;
    my $is_current = shift;
    my @builds = ();
    my $query= "SELECT distinct (unigene_build_id) FROM unigene_build 
                JOIN group_linkage ON (unigene_build.organism_group_id=group_linkage.group_id)
                JOIN sgn.organism ON (group_linkage.member_id=sgn.organism.organism_id) 
                JOIN common_name USING(common_name_id) WHERE common_name ilike ? ";
    $query .= " AND status = 'C'" if $is_current;
    my $sth = $dbh->prepare($query);
    $sth->execute($common_name);
    while (my ($unigene_build_id) = $sth->fetchrow_array()){
	my $build= CXGN::Transcript::UnigeneBuild->new($dbh, $unigene_build_id);
	push @builds, $build; 
    }
    return @builds || undef;
}


=head2 accessors get_blast_db_id, set_blast_db_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_blast_db_id {
  my $self = shift;
  return $self->{blast_db_id}; 
}

sub set_blast_db_id {
  my $self = shift;
  $self->{blast_db_id} = shift;
}



=head2 function get_superseding_build_info

 Usage:
 Desc:
 Ret:          a list: (superseding build name, build_nr)
 Args:
 Side Effects:
 Example:

=cut

sub get_superseding_build_info {
    my $self = shift;
    my $superseding_build_id = $self->get_superseding_build_id();
    my $superseding_build = CXGN::Transcript::UnigeneBuild->new($self->get_dbh(), $superseding_build_id);

    return ($superseding_build->get_organism_group_name(), $superseding_build->get_build_nr());
}

return 1;
