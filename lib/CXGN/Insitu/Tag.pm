
=head1 NAME

Tag.pm -- an object to deal with the CXGN::Insitu::Tag's.

=head1 DESCRIPTION

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)


=head1 FUNCTIONS

Class functions:

=cut

use strict;

package CXGN::Insitu::Tag; 

use base qw / CXGN::Insitu::DB /;

=head2 new

 Usage:        my $tag = CXGN::Insitu::Tag->new($dbh)
 Desc:         constructor
 Ret:          Tag object
 Args:         database handle
 Side Effects: calls the parent constructor.
 Example:

=cut

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(shift);

    my $id = shift;
    
    if ($id) { 
	$self->set_tag_id($id);
	$self->fetch_tag();
    }
    return $self;
}

sub fetch_tag { 
    my $self = shift;
    
    my $query = "SELECT name, description, user_id 
                        FROM insitu.tag
                       WHERE tag_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_tag_id());
    my ($name, $description, $user_id) = $sth->fetchrow_array();
    $self->set_name($name);
    $self->set_description($description);
    $self->set_user_id($user_id);

    # get implied tags
    #
    #my $implied_q = "SELECT Q (later)
}

=head2 store

 Usage:        
 Desc:         stores the object into the database
 Ret:          the id of the inserted or updated object
 Args:
 Side Effects:
 Example:

=cut

sub store { 
    my $self = shift;
    if ($self->get_tag_id()) { 
	my $query = "UPDATE insitu.tag SET 
                            name=?,
                            description =?,
                            user_id=?
                      WHERE insitu.tag.tag_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_user_id(),
		      $self->get_tag_id()
		      );
    }
    else { 
	my $query = "INSERT INTO insitu.tag (
                            name, description, user_id)
                     VALUES (?, ?, ?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_user_id()
		      );
	
	$self->set_tag_id($self->get_dbh()->last_insert_id("tag"));

    }
    return $self->get_tag_id();
                         
}

=head2 get_tag_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_tag_id {
  my $self=shift;
  return $self->{tag_id};

}

=head2 set_tag_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_tag_id {
  my $self=shift;
  $self->{tag_id}=shift;
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

=head2 add_implied_tag

  Usage:        DEPRECATED
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_implied_tag {
    my $self = shift;
    my $implied_tag = shift;
    if (!exists($self->{implied_tags})) { @{$self->{implied_tags}}=(); }
    push @{$self->{implied_tags}}, $implied_tag;
}

=head2 get_implied_tags

 Usage:         DEPRECATED FOR NOW
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut
    
sub get_implied_tags {
    my $self = shift;
    return @{$self->{implied_tags}};
}

=head2 get_associated_images

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_associated_images {
    my $self = shift;
    my $query = "SELECT image_id 
                   FROM insitu.image_tag
                  WHERE tag_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth -> execute($query);
    my @images = ();
    while (my ($image_id) = $sth->fetchrow_array()) { 
	my $image = CXGN::Insitu::Image->new($self->get_dbh(), $image_id);
	push @images, $image;
    }
    return @images;

}

=head2 exists_tag_named

 Usage:        my $exists = CXGN::Insitu::Tag::exists($dbh, $name)
 Desc:         static function that returns true if a tag 
               named $name already exists
 Ret:          true if tag exists, false otherwise
 Args:         a database handle, a string with the tag name
 Side Effects:
 Example:

=cut

sub exists_tag_named {
    my $dbh = shift;
    my $name = shift;
    my $query = "SELECT tag_id 
                   FROM insitu.tag
                  WHERE name ILIKE ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    if (my ($id)=$sth->fetchrow_array()) { 
	return $id;
    }
    else { 
	return 0;
    }
}




return 1;
