
use strict;
use CXGN::Insitu::Experiment;


package CXGN::Insitu::Organism;

use base qw / CXGN::Insitu::DB /;

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
    my $self  = $class -> SUPER::new($dbh);

    if ($id) { 
	$self->set_organism_id($id);
	$self->fetch_organism();
    }
    return $self;
}

sub fetch_organism { 
    my $self = shift;
    my $query = "SELECT is_organism_id,
                        name,
                        common_name,
                        description,
                        user_id
                   FROM insitu.is_organism
                  WHERE is_organism_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id());
    my ($organism_id, $name, $common_name, $description, $user_id) =
	$sth->fetchrow_array();
    $self->set_organism_id($organism_id);
    $self->set_name($name);
    $self->set_common_name($common_name);
    $self->set_description($description);
    $self->set_user_id($user_id);
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
    my $self = shift;
    if ($self->get_organism_id()) { 
	my $query = "UPDATE insitu.is_organism SET
                        name=?,
                        common_name=?,
                        description=?,
                        user_id=?
                     WHERE is_organism_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_common_name(),
		      $self->get_description(),
		      $self->get_organism_id(),
		      $self->get_user_id()
		      
		      );
    }
    else { 
	my $query = "INSERT INTO insitu.is_organism
                                 (name, common_name, description, user_id)
                          VALUES (?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_common_name(),
		      $self->get_description(),
		      $self->get_user_id()
		      );
	return $self->get_dbh()->last_insert_id("is_organism");
    }
}

=head2 get_all_organisms

 Usage:        my ($names_ref, $ids_ref) = CXGN::Insitu::Organism::get_all_organisms($dbh);
 Desc:         This is a static function.
 Ret:          Returns to arrayrefs. One array contains all the
               organism names, and the other all the organism ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_organisms {
    my $dbh = shift;
    my $query = "SELECT name, is_organism_id 
                   FROM insitu.is_organism";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($name, $organism_id) = $sth->fetchrow_array()) { 
	print STDERR "get_all_organisms: $name, $organism_id\n";
	push @names, $name;
	push @ids, $organism_id;
    }
    return (\@names, \@ids);
}



=head2 get_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_id {
  my $self=shift;
  return $self->{organism_id};

}

=head2 set_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_organism_id {
  my $self=shift;
  $self->{organism_id}=shift;
}

=head2 get_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name {
  my $self=shift;
  return $self->{name};

}

=head2 set_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_name {
  my $self=shift;
  $self->{name}=shift;
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
  my $self=shift;
  return $self->{common_name};

}

=head2 set_common_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_common_name {
  my $self=shift;
  $self->{common_name}=shift;
}

=head2 get_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_description {
  my $self=shift;
  return $self->{description};

}

=head2 set_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_description {
  my $self=shift;
  $self->{description}=shift;
}

=head2 get_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_id {
  my $self=shift;
  return $self->{user_id};

}

=head2 set_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_id {
  my $self=shift;
  $self->{user_id}=shift;
}




=head2 get_associated_experiments

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_associated_experiments {
    my $self = shift;
    my $query = "SELECT experiment.experiment_id FROM insitu.experiment 
                  WHERE is_organism_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id());
    my @experiments = ();
    while (my ($experiment_id) = $sth->fetchrow_array()) { 
	push @experiments, CXGN::Insitu::Experiment->new($self->get_dbh(), $experiment_id);
    }
    return @experiments;
	
}




return 1;

