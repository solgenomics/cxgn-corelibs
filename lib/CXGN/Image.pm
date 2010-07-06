
=head1 NAME

Image.pm - a class for accessing the md_metadata.image table.


=head1 DESCRIPTION

This class provides database access and store functions
and functions to associate tags with the image.


Image uploads are handled by the SGN::Image subclass.


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)
Naama Menda (nm249@cornell.edu)

=head1 VERSION

0.02, Dec 15, 2009.

=head1 MEMBER FUNCTIONS

The following functions are provided in this class:

=cut


use strict;

use CXGN::DB::Connection;

use CXGN::Tag;


package CXGN::Image;

use base qw | CXGN::DB::ModifiableI |;



=head2 new

 Usage:        my $image = CXGN::Image->new($dbh, 23423)
 Desc:         constructor
 Ret:
 Args:         a database handle, optional identifier
 Side Effects: if an identifier is specified, the image object
               will be populated from the database, otherwise
               an empty object is returned.
               Either way, a database connection is established.
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh=shift;
    my $id = shift;

    my $self = $class->SUPER::new($dbh, $id, @_);

    $self->set_dbh($dbh);

    if ($id) {
	$self->set_image_id($id);
	$self->fetch_image();
    }
    return $self;
}

sub fetch_image {
    my $self = shift;
    my $query = "SELECT image_id,
                        name,
                        description,
                        original_filename,
                        file_ext,
                        sp_person_id,
                        modified_date,
                        create_date
                 FROM   metadata.md_image
                 WHERE  image_id=?
                        and obsolete != 't' ";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id()) ;

    my ( $image_id, $name, $description, $original_filename, $file_ext, $sp_person_id, $modified_date, $create_date) =
	$sth->fetchrow_array();


    $self->set_name($name);
    $self->set_description($description);
    $self->set_original_filename($original_filename);
    $self->set_file_ext($file_ext);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_image_id($image_id); # we do this that if is an image that has been deleted,
                                    # the object will get the NULL from the database and not
                                    # the image_id that was fed into the object.
}

=head2 store

 Usage:        $image->store()
 Desc:         will store the data in the image object to the database
               if the image has an associated image_id, an update will
               occur. if the image does not have an associated image_id,
               an insert into the database will occur.
 Ret:          the image_id of the updated or inserted object.
 Args:
 Side Effects: database update or insert. Note that the image itself is
               stored on the file system and that it is not affected by
               this operation, unless the filename property is changed.
 Example:

=cut

sub store {
    my $self = shift;
    if ($self->get_image_id()) {

	# it's an update
	#
	my $query = "UPDATE metadata.md_image SET
                            name=?,
                            description=?,
                            original_filename=?,
                            file_ext=?,
                            sp_person_id =?,
                            modified_date = now()
                      WHERE md_image.image_id=?";

	my $sth = $self->get_dbh()->prepare($query);

	$sth->execute(
		      $self->get_name(),
		      $self->get_description(),
		      $self->get_original_filename(),
		      $self->get_file_ext(),
		      $self->get_sp_person_id(),
		      $self->get_image_id()
		      );
	return $self->get_image_id();
    }
    else {

	# it is an insert
	#
	my $query = "INSERT INTO metadata.md_image
                            (name,
                            description,
                            original_filename,
                            file_ext,
                            sp_person_id,
                            obsolete,
                            modified_date)
                     VALUES (?, ?, ?, ?, ?, ?, now())";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		       $self->get_name(),
		       $self->get_description(),
		       $self->get_original_filename(),
		       $self->get_file_ext(),
		       $self->get_sp_person_id(),
		       $self->get_obsolete()
		       );
	my $image_id= $self->get_currval("metadata.md_image_image_id_seq");
	$self->set_image_id($image_id);
	return $self->get_image_id();
    }
}

=head2 delete

 Usage:  $self->delete()
 Desc:   set the image status to obsolete='t'
 Ret:    nothing
 Args:  none
 Side Effects: set to obsolete='t' in individual_image, and locus_image
 Example:

=cut

sub delete {
    my $self = shift;
    if ($self->get_image_id()) {
	my $query = "UPDATE metadata.md_image set obsolete='t' WHERE image_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_image_id());
	$self->set_obsolete(1);
	#delete image-individual associations
	my $query2 = "UPDATE phenome.individual_image set obsolete = 't' WHERE image_id = ?";
	my $sth2 = $self->get_dbh()->prepare($query2);
	$sth2->execute($self->get_image_id() );
        #deanx - nov.14 2007 remove from locus_image too
	my $query3 = "UPDATE phenome.locus_image set obsolete = 't', modified_date = now() WHERE image_id = ?";
      	my $sth3 = $self->get_dbh()->prepare($query3);
	$sth3->execute($self->get_image_id() );

    }
    else {
	warn("Image.pm: Trying to delete an image from the db that has not yet been stored.");
    }

}

=head2 get_image_id, set_image_id

 Usage:        accessor for the image_id property.
 Desc:
 Ret:
 Args:
 Side Effects: if the image_id is not set, the store() function
               will insert a new row and set the image_id to
               the inserted row. Otherwise, store() performs
               an update.
 Example:

=cut

sub get_image_id {
    my $self=shift;
    return $self->{image_id};

}

sub set_image_id {
    my $self=shift;
    $self->{image_id}=shift;
}


=head2 get_name, set_name

 Usage:
 Desc:         gets/sets the name of the image
 Ret:
 Args:
 Side Effects: will be stored in db
 Example:

=cut

sub get_name {
    my $self=shift;
    return $self->{name};

}

sub set_name {
    my $self=shift;
    $self->{name}=shift;
}

=head2 get_description, set_description

 Usage:
 Desc:         accessor for the description property
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


=head2 get_original_filename, set_original_filename

 Usage:
 Desc:         accessor for the original_filename property
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_original_filename {
    my $self=shift;
    return $self->{original_filename};
}

sub set_original_filename {
    my $self=shift;
    $self->{original_filename}=shift;
}

=head2 get_file_ext, set_file_ext

 Usage:
 Desc:         accessor for the file_ext property
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_file_ext {
  my $self=shift;
  return $self->{file_ext};

}

sub set_file_ext {
    my $self=shift;
    $self->{file_ext}=shift;
}


=head2 get_filename

 Usage:
 Desc:
 Ret:
 Args:         "full" | "relative", "original" | "large" | "medium" | "small" | "thumbnail"
 Side Effects:
 Example:

=cut

# sub get_filename {
#     my $self = shift;
#     my $which = shift;
#     my $size = shift;

#     my $path = $self->get_image_dir($which)."/".$self->get_image_id();
#     if ($size eq "original") {
#       return $path."/".($self->get_original_filename()).($self->get_file_ext());
#     }
#     elsif ($size eq "medium") {
# 	return $path."/medium.jpg";
#     }
#     elsif ($size eq "small") {
# 	return $path."/small.jpg";
#     }
#     elsif ($size eq "thumbnail") {
# 	return $path."/thumbnail.jpg";
#     }

#     # default is medium
#     #
#     return $path."/medium.jpg";

# }



=head2 associate_individual

 Usage:        $image->associate_individual($individual_id)
 Desc:         associate a CXGN::Phenome::Individual with this image
 Ret:          a database id (individual_image)
 Args:         individual_id
 Side Effects:
 Example:

=cut

sub associate_individual {
    my $self = shift;
    my $individual_id = shift;
    my $query = "INSERT INTO phenome.individual_image
                   (individual_id, image_id) VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($individual_id, $self->get_image_id());

    my $id= $self->get_currval("phenome.individual_image_individual_image_id_seq");
    return $id;
}

=head2 get_individuals

 Usage: $self->get_individuals()
 Desc:  find associated individuals with the image
 Ret:   list of 'Individual' objects
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_individuals {
    my $self = shift;
    my $query = "SELECT individual_id FROM phenome.individual_image WHERE individual_image.image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @individuals;
    while (my ($individual_id) = $sth->fetchrow_array()) {
	my $i = CXGN::Phenome::Individual->new($self->get_dbh(), $individual_id);
	if ( $i->get_individual_id() ) { push @individuals, $i; } #obsolete individuals should be ignored!
    }
    return @individuals;
}


=head2 associate_experiment

 Usage: $image->associate_experiment($experiment_id);
 Desc:  associate and image with and insitu experiment
 Ret:   a database id
 Args:  experiment_id
 Side Effects:
 Example:

=cut

sub associate_experiment {
    my $self = shift;
    my $experiment_id = shift;
    my $query = "INSERT INTO insitu.experiment_image
                 (image_id, experiment_id)
                 VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id(), $experiment_id);
    my $id= $self->get_currval("insitu.experiment_image_experiment_image_id_seq");
    return $id;

}

=head2 get_experiments

 Usage:
 Desc:
 Ret:          a list of CXGN::Insitu::Experiment objects associated
               with this image
 Args:
 Side Effects:
 Example:

=cut

sub get_experiments {
    my $self = shift;
    my $query = "SELECT experiment_id FROM insitu.experiment_image
                 WHERE image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @experiments = ();
    while (my ($experiment_id) = $sth->fetchrow_array()) {
	push @experiments, CXGN::Insitu::Experiment->new($self->get_dbh(), $experiment_id);
    }
    return @experiments;
}

=head2 associate_fish_result

 Usage:        $image->associate_fish_result($fish_result_id)
 Desc:         associate a CXGN::Phenome::Individual with this image
 Ret:          database_id
 Args:         fish_result_id
 Side Effects:
 Example:

=cut

sub associate_fish_result {
    my $self = shift;
    my $fish_result_id = shift;
    my $query = "INSERT INTO sgn.fish_result_image
                   (fish_result_id, image_id) VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($fish_result_id, $self->get_image_id());
    my $id= $self->get_currval("sgn.fish_result_image_fish_result_image_id_seq");
    return $id;
}

=head2 get_fish_result_clone_ids

 Usage:        my @clone_ids = $image->get_fish_result_clones();
 Desc:         because fish results are associated with genomic
               clones, this function returns the genomic clone ids
               that are associated through the fish results to
               this image. The clone ids can be used to construct
               links to the BAC detail page.
 Ret:          A list of clone_ids
 Args:
 Side Effects:
 Example:

=cut

sub get_fish_result_clone_ids {
    my $self = shift;
    my $query = "SELECT distinct(clone_id) FROM sgn.fish_result_image join sgn.fish_result using(fish_result_id)  WHERE fish_result_image.image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @fish_result_clone_ids = ();
    while (my ($fish_result_clone_id) = $sth->fetchrow_array()) {
	push @fish_result_clone_ids, $fish_result_clone_id;
    }
    return @fish_result_clone_ids;
}

=head2 add_tag

 Usage:        $self->add_tag($tag)
 Desc:         adds a tag to the image
 Ret:          database id
 Args:         a tag object (CXGN::Tag).
 Side Effects: the tag is immediately store in the database.
               there is no need to call store() on the image object.
 Example:

=cut

sub add_tag {
    my $self = shift;
    my $tag = shift;

    my $query = "INSERT INTO metadata.md_tag_image (tag_id, image_id) values (?, ?)";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
    my $id= $self->get_currval("metadata.md_tag_image_tag_image_id_seq");
    return $id;
}

=head2 get_tags

 Usage:        my @tags = $image->get_tags();
 Desc:         gets all the tags associated with this image object
 Ret:
 Args:
 Side Effects: the tags are being fetched from the database. The image
               object does not 'buffer' tag associations (see also add_tag()).
 Example:

=cut

sub get_tags {
    my $self  = shift;

    my $query = "SELECT tag_id FROM metadata.md_tag_image WHERE image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my @tags = ();
    while (my ($tag_id) = $sth->fetchrow_array()) {
	push @tags, CXGN::Tag->new($self->get_dbh(), $tag_id);
    }
    return @tags;
}

=head2 remove_tag

 Usage:        $self->remove_tag($tag)
 Desc:         Delete a tag_image association
 Ret:          nothing
 Args:         a tag object.
 Side Effects: the association to the tag object will be removed
               directly accessing the database backstore. There is no
               need to call store() after remove_tag(). The tag itself
               is not affected.
 Example:

=cut

sub remove_tag {
    my $self = shift;
    my $tag = shift;
    my $query = "DELETE FROM metadata.md_tag_image WHERE tag_id=? and image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($tag->get_tag_id(), $self->get_image_id());
}


=head2 exists_tag_image_named

 Usage: CXGN::Image::exists_tag_image_named($dbh, $tag_id, $image_id)
 Desc:  Check if a tag is already associated with an image
 Ret:   a database id or undef
 Args:  dbh, tag_id, image_id
 Side Effects: none
 Example:

=cut

sub exists_tag_image_named {
    my $dbh = shift;
    my $tag_id = shift;
    my $image_id=shift;
    my $query = "SELECT tag_image_id
                   FROM metadata.md_tag_image
                  WHERE tag_id= ? AND image_id= ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($tag_id, $image_id);
    if (my ($id)=$sth->fetchrow_array()) {
	return $id;
    }
    else {
	return 0;
    }
}



=head2 function get_associated_objects

  Synopsis:
  Arguments:
  Returns:
  Side effects:
  Description:

=cut

sub get_associated_objects {
    my $self = shift;
    my @associations = ();
    my @individuals=$self->get_individuals();
    foreach my $ind (@individuals) {
	print STDERR  "found individual '$ind' !!\n";
	my $individual_id = $ind->get_individual_id();
	my $individual_name = $ind->get_name();
	push @associations, [ "individual", $individual_id, $individual_name ];

#	print "<a href=\"/phenome/individual.pl?individual_id=$individual_id\">".($ind->get_name())."</a>";
    }

    foreach my $exp ($self->get_experiments()) {
	my $experiment_id = $exp->get_experiment_id();
	my $experiment_name = $exp->get_name();

	push @associations, [ "experiment", $experiment_id, $experiment_name ];

	#print "<a href=\"/insitu/detail/experiment.pl?experiment_id=$experiment_id&amp;action=view\">".($exp->get_name())."</a>";
    }

    foreach my $fish_result_clone_id ($self->get_fish_result_clone_ids()) {
	push @associations, [ "fished_clone", $fish_result_clone_id ];
    }
    foreach my $locus ($self->get_loci() ) {
	push @associations, ["locus", $locus->get_locus_id(), $locus->get_locus_name];
    }
    return @associations;
}

=head2 function get_associated_object_links

  Synopsis:
  Arguments:
  Returns:	a string
  Side effects:
  Description:	gets the associated objects as links in tabular format

=cut

sub get_associated_object_links {
    my $self = shift;
    my $s = "";
    foreach my $assoc ($self->get_associated_objects()) {

	if ($assoc->[0] eq "individual") {
	    $s .= "<a href=\"/phenome/individual.pl?individual_id=$assoc->[1]\">Individual name: $assoc->[2].</a>";
	}

	if ($assoc->[0] eq "experiment") {
	    $s .= "<a href=\"/insitu/detail/experiment.pl?experiment_id=$assoc->[1]&amp;action=view\">insitu experiment $assoc->[2]</a>";
	}

        if ($assoc->[0] eq "fished_clone") {
	    $s .= qq { <a href="/maps/physical/clone_info.pl?id=$assoc->[1]">FISHed clone id:$assoc->[1]</a> };

	}
      if ($assoc->[0] eq "locus" ) {
	  $s .= qq { <a href="/phenome/locus_display.pl?locus_id=$assoc->[1]">Locus name:$assoc->[2]</a> };
      }

    }
    return $s;
}


=head2 create_schema

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut



sub create_schema {
    my $self = shift;

    eval {

	$self->get_dbh()->do(
			 "CREATE table metadata.md_image (
						    image_id serial primary key,
						    name varchar(100),
						    description text,
						    original_filename varchar(100),
						    file_ext varchar(20),
						    sp_person_id bigint REFERENCES sgn_people.sp_person,
						    modified_date timestamp with time zone,
						    create_date timestamp with time zone,
						    obsolete boolean default false
						    )");

	$self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON metadata.md_image TO web_usr");
	$self->get_dbh()->do("GRANT select, update ON metadata.md_image_image_id_seq TO web_usr");

	$self->get_dbh()->do(
                         "CREATE table phenome.individual_image (
				                    individual_image_id serial primary key,
						    image_id bigint references metadata.md_image,
						    individual_id bigint references phenome.individual,
                                                    obsolete boolean DEFAULT 'false',
                                                    sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                    create_date timestamp with time zone DEFAULT now(),
                                                    modified_date timestamp with time zone
	               )");

	$self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.individual_image TO web_usr");
	$self->get_dbh()->do("GRANT select, update ON phenome.individual_image_individual_image_id_seq TO web_usr");

	$self->get_dbh()->do(
	    "CREATE table phenome.locus_image (
				                    locus_image_id serial primary key,
						    image_id bigint references metadata.md_image,
						    locus_id bigint references phenome.locus,
                                                    obsolete boolean DEFAULT 'false',
                                                    sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                    create_date timestamp with time zone DEFAULT now(),
                                                    modified_date timestamp with time zone
	               )");

	$self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.locus_image TO web_usr");
	$self->get_dbh()->do("GRANT select, update ON phenome.locus_image_locus_image_id_seq TO web_usr");


	$self->get_dbh()->do(
			 "CREATE table insitu.experiment_image (
                                                     experiment_image_id serial primary key,
                                                     image_id bigint references metadata.md_image,
                                                     experiment_id bigint references insitu.experiment,
                                                      obsolete boolean DEFAULT 'false',
                                                    sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id),
                                                    create_date timestamp with time zone DEFAULT now(),
                                                    modified_date timestamp with time zone
                      )");

	$self->get_dbh()->do ("GRANT SELECT, UPDATE, INSERT ON insitu.experiment_image TO web_usr");
	$self->get_dbh()->do ("GRANT select, update ON insitu.experiment_image_experiment_image_id_seq TO web_usr");

	$self->get_dbh()->do ("CREATE table sgn.fish_result_image (
                                                      fish_result_image_id serial primary key,
                                                      image_id bigint references metadata.md_image,
                                                      fish_result_id bigint references sgn.fish_result
                        )");
	$self->get_dbh()->do ("GRANT SELECT ON sgn.fish_result_image TO web_usr");
	$self->get_dbh()->do ("GRANT select ON sgn.fish_result_image_fish_result_image_id_seq TO web_usr");
	# we don't grant access to webusr for image_fish_result because as of now users cannot submit
	# these image directly themselves.

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

### deanx additions - Nov 13, 2007

=head2 associate_locus

 Usage:        $image->associate_locus($locus_id)
 Desc:         associate a locus with this image
 Ret:          database_id
 Args:         locus_id
 Side Effects:
 Example:

=cut

sub associate_locus {
    my $self = shift;
    my $locus_id = shift;
    my $sp_person_id= $self->get_sp_person_id();
    my $query = "INSERT INTO phenome.locus_image
                   (locus_id,
		   sp_person_id,
		   image_id)
		 VALUES (?, ?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute(
    		$locus_id,
    		$sp_person_id,
    		$self->get_image_id()
		);

    my $locus_image_id= $self->get_currval("phenome.locus_image_locus_image_id_seq");
    return $locus_image_id;
}


=head2 get_loci

 Usage:   $self->get_loci
 Desc:    find the locus objects asociated with this image
 Ret:     a list of locus objects
 Args:    none
 Side Effects: none
 Example:

=cut

sub get_loci {
    my $self = shift;
    my $query = "SELECT locus_id FROM phenome.locus_image WHERE locus_image.obsolete = 'f' and locus_image.image_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_image_id());
    my $locus;
    my @loci = ();
    while (my ($locus_id) = $sth->fetchrow_array()) {
       $locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
        push @loci, $locus;
    }
    return @loci;
}


###########
1;#########
###########
