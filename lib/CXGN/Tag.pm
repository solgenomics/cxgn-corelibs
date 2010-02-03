
=head1 NAME

CXGN::Tag -- a class to deal with tags. 

=head1 DESCRIPTION

A tag is a keyword to describe an image. The tag can contain spaces but should really be a single word in general ("new york" could be a tag containing a space). All tags are lower-cased by the tag object.

Tags can be associated to database objects. Currently, only images can have tags, but it could be expanded to other database items, such as libraries, sequences, whatever.

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)


=head1 FUNCTIONS

Class functions:

=cut

use strict;

package CXGN::Tag; 

use base qw / CXGN::DB::ModifiableI /;

=head2 new

 Usage:        my $tag = CXGN::Tag->new($dbh)
 Desc:         constructor
 Ret:          Tag object
 Args:         database handle
 Side Effects: calls the parent constructor.
 Example:

=cut

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $dbh = shift;
    my $id = shift;
    
    $self->set_dbh($dbh);

    if ($id) { 
	$self->set_tag_id($id);
	$self->fetch_tag();
    }
    return $self;
}

# internal function
#
sub fetch_tag { 
    my $self = shift;
    
    my $query = "SELECT name, description, sp_person_id 
                        FROM metadata.md_tag
                       WHERE tag_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_tag_id());
    my ($name, $description, $user_id) = $sth->fetchrow_array();
    $self->set_name($name);
    $self->set_description($description);
    #$self->set_sp_person_id($user_id);
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
	my $query = "UPDATE metadata.md_tag SET 
                            name=?,
                            description =?,
                            sp_person_id=?,
                            modified_date=now()
                      WHERE tag_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_sp_person_id(),
		      $self->get_tag_id()
		      );
    }
    else { 
	my $query = "INSERT INTO metadata.md_tag (
                            name, description, sp_person_id)
                     VALUES (?, ?, ?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_sp_person_id()
		      );
	my $tag_id= $self->get_currval("metadata.md_tag_tag_id_seq");
	$self->set_tag_id($tag_id);
	print STDERR "NEW TAG ID = ".($self->get_tag_id())."\n";

    }
    return $self->get_tag_id();
}

=head2 get_tag_id

 Usage:        getter for the tag_id property
 Desc:         the object will assign the tag_id, 
               so it should not be necessary to call the
               setter ever.
 Ret:          the tag_id of this object
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_tag_id {
  my $self=shift;
  return $self->{tag_id};
}

sub set_tag_id {
  my $self=shift;
  $self->{tag_id}=shift;
}

=head2 get_name, set_name

 Usage:        my $tag = $tag->get_name()
 Desc:         the tag string that describes that tag itself
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name {
  my $self=shift;
  return $self->{name};
}

sub set_name {
  my $self=shift;
  my $tag = shift;
  $tag = lc($tag);
  $self->{name}=$tag;
}

=head2 get_description, set_description

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

sub set_description {
  my $self=shift;
  $self->{description}=shift;
}

=head2 function associate_experiment

  Synopsis:	$tag->associate_experiment($experiment_id, $sp_person_id)
  Arguments:	experiment_id, person_id
  Returns:	
  Side effects:	
  Description:	

=cut

sub associate_experiment {
    my $self = shift;
    my $experiment_id = shift;
    my $sp_person_id=shift;
    my $query = "INSERT INTO insitu.experiment_tag (tag_id, experiment_id, sp_person_id) values (?,?,?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_tag_id(), $experiment_id, $sp_person_id);
}

=head2 function get_associated_experiments

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_associated_experiments {
    my $self = shift;
    my $query = "SELECT experiment_id FROM insitu.experiment_tag WHERE experiment_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_tag_id());
    my @experiments=();
    while (my ($id) = $sth->fetchrow_array()) { 
	my $exp = CXGN::Insitu::Experiment->new($self->get_dbh(), $id);
	push @experiments, $exp;
    }
    return @experiments;


}



=head2 function associate_image

  Synopsis:	$tag->associate_image($image_id, $sp_peron_id)
  Arguments:	An id for an CXGN::Image object and the sp_person_id 
                of the person making the image_tag association
  Returns:	$tag_image_id
  Side effects:	
  Description:	

=cut

sub associate_image {
    my $self = shift;
    my $image_id = shift;
    my $sp_person_id= shift;

    my $check_q = "SELECT count(*) as count FROM metadata.md_tag_image WHERE image_id=? and tag_id=?";
    my $check_h = $self->get_dbh()->prepare($check_q);
    $check_h->execute($image_id, $self->get_tag_id());
    my ($count) = $check_h->fetchrow_array();
    if ($count) { 
	print STDERR "The image $image_id already has an associated tag \"".$self->get_name()."\".\n";
	return;
    }
    my $query = "INSERT INTO metadata.md_tag_image (tag_id, image_id, sp_person_id) values (?,?,?)";
    my $sth = $self->get_dbh()->prepare($query);
    print STDERR "About to store a tag_image . tag_id = ". $self->get_tag_id() . "image_id =  $image_id, person_id = $sp_person_id*!*!*!\n";
    $sth->execute($self->get_tag_id(), $image_id, $sp_person_id);  
    my $tag_image_id= $self->get_currval("metadata.md_tag_image_tag_image_id_seq");
    return $tag_image_id;
}

=head2 get_associated_images

 Usage:        $tag->get_associated_images()
 Desc:         
 Ret:          retrieves the associates images as CXGN::Image objects
 Args:
 Side Effects: none
 Example:

=cut

sub get_associated_images {
    my $self = shift;
    my $query = "SELECT image_id 
                   FROM metadata.md_tag_image
                  WHERE tag_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth -> execute($query);
    my @images = ();
    while (my ($image_id) = $sth->fetchrow_array()) { 
	my $image = CXGN::Image->new($self->get_dbh(), $image_id);
	push @images, $image;
    }
    return @images;

}

=head2 exists_tag_named

 Usage:        my $exists = CXGN::Tag::exists($dbh, $name)
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
                   FROM metadata.md_tag
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


sub create_schema { 
    my $self = shift;


    eval { 
    
	$self->get_dbh()->do(
			 "CREATE table metadata.md_tag (
						    tag_id serial primary key,
						    name varchar(100), 
						    description text,
						    sp_person_id bigint REFERENCES sgn_people.sp_person,
						    modified_date timestamp with time zone,
						    create_date timestamp with time zone,
						    obsolete boolean default false
						    )");

	$self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON metadata.md_tag TO web_usr");
	$self->get_dbh()->do("GRANT select, update, insert ON metadata.md_tag_tag_id_seq TO web_usr");
    
	$self->get_dbh()->do(
                         "CREATE table metadata.md_tag_image (
				                    tag_image_id serial primary key,
						    image_id bigint references metadata.md_image,
						    tag_id bigint references metadata.md_tag,
                                                    obsolete boolean default false ,
                                                    sp_person_id integer REFERENCES sgn_people.sp_person,
						    create_date timestamp with time zone ,
                                                    modified_date timestamp with time zone
	               )");

	$self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT, DELETE ON metadata.md_tag_image TO web_usr");
	$self->get_dbh()->do("GRANT select, update  ON metadata.md_tag_image_tag_image_id_seq TO web_usr");
			     

	$self->get_dbh()->do(
			 "CREATE table insitu.experiment_tag (
                                                     experiment_tag_id serial primary key,
                                                     tag_id bigint references metadata.md_tag,
                                                     experiment_id bigint references insitu.experiment,
                                                     sp_person_id bigint REFERENCES sgn_people.sp_person,
						     modified_date timestamp with time zone,
						     create_date timestamp with time zone,
						     obsolete boolean default false)");
	
	$self->get_dbh()->do ("GRANT SELECT, UPDATE, INSERT, DELETE ON insitu.experiment_tag TO web_usr");
	$self->get_dbh()->do ("GRANT select, update ON insitu.experiment_tag_experiment_tag_id_seq TO web_usr");
			     

    };
    if ($@) { 
	$self->get_dbh()->rollback();
	die "An error occurred while instantiating the schemas. The commands have been rolled back.\n";
	
    }
    else { 
	$self->get_dbh()->commit();
    }  
    print STDERR "Schemas created.\n";
}

=head2 get_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbh {
  my $self=shift;
  return $self->{dbh};

}

=head2 set_dbh

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}





return 1;
