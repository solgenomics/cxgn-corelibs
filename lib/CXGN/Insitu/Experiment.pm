
=head1 NAME

=head1 AUTHRO(S)

Lukas Mueller (lam87@cornell.edu)

=cut

use strict;

use CXGN::People;
use SGN::Image;
use CXGN::Tag;
use CXGN::Insitu::Probe;

package CXGN::Insitu::Experiment;

use base qw | CXGN::Insitu::DB |;

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
	$self->set_experiment_id($id);
	$self->fetch_experiment();
    }    
    return $self;
}

sub fetch_experiment { 
    my $self = shift;
    
    my $query = "SELECT experiment_id, 
                        name, 
                        date, 
                        type,
                        is_organism_id, 
                        tissue, 
                        stage, 
                        probe_id, 
                        description, 
                        user_id 
                   FROM insitu.experiment
                  WHERE (obsolete='f' or obsolete IS NULL) 
                        and experiment_id=?";

    my $sth = $self->get_dbh()->prepare($query);

    $sth->execute($self->get_experiment_id());

    my ($experiment_id, $name, $date, $type, $organism_id, $tissue, $stage, $probe_id, $description, $user_id) = $sth->fetchrow_array();
    $self->set_experiment_id($experiment_id);
    $self->set_name($name);
    $self->set_date($date);
    $self->set_type($type);
    $self->set_organism_id($organism_id);
    $self->set_tissue($tissue);
    $self->set_stage($stage);
    $self->set_probe_id($probe_id);
    $self->set_description($description);
    $self->set_user_id($user_id);

    # fetch associated image objects
    #
    my $image_q = "SELECT image_id FROM metadata.md_image JOIN insitu.experiment_image using (image_id) WHERE (md_image.obsolete='f' or md_image.obsolete IS NULL) and experiment_image.experiment_id=?";
    my $image_h = $self->get_dbh()->prepare($image_q);
    $image_h->execute($self->get_experiment_id());
    while (my ($id) = $image_h->fetchrow_array()) { 
	$self->add_image(SGN::Image->new($self->get_dbh(), $id));
	$self->add_image_id($id);
    }

    # fetch probe data
    #
}

sub store { 
    my $self = shift;
    if ($self->get_experiment_id()) { 
	
	# it's an update
	#
	my $query = "UPDATE insitu.experiment SET
                        name=?,
                        date=?,
                        type=?,
                        is_organism_id=?,
                        tissue=?,
                        stage=?, 
                        probe_id=?,
                        description=?,
                        user_id=?
                     WHERE insitu.experiment.experiment_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_name(),
		      $self->get_date(),
		      $self->get_type(),
			  $self->get_organism_id(),
		      $self->get_tissue(),
		      $self->get_stage(),
		      $self->get_probe_id(),
		      $self->get_description(),
		      $self->get_user_id(),
			  $self->get_experiment_id()
		      );
	return $self->get_experiment_id();
    }
    else { 
	my $query = "INSERT INTO insitu.experiment ( 
                            name,
                            date,
                            type,
                            is_organism_id,
                            tissue,
                            stage, 
                            probe_id,
                            description,
                            user_id)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(),
		      $self->get_date(),
		      $self->get_type(),
		      $self->get_organism_id(),
		      $self->get_tissue(),
		      $self->get_stage(),
		      $self->get_probe_id(),
		      $self->get_description(),
		      $self->get_user_id()
		      );
	$self->set_experiment_id($self->get_dbh()->last_insert_id("experiment"));
    }
}


sub delete { 
    my $self = shift;
    if ($self->get_experiment_id()) { 
	my $query = "UPDATE insitu.experiment SET obsolete='t'
                  WHERE experiment_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_experiment_id());

	foreach my $i ($self->get_images()) { 
	    $i->delete();
	}
    }
    else { 
	print STDERR  "trying to delete an experiment that has not yet been stored to db.\n";
    }    
}		       
		       

=head2 get_experiment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_experiment_id {
  my $self=shift;
  return $self->{experiment_id};

}

=head2 set_experiment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_experiment_id {
  my $self=shift;
  $self->{experiment_id}=shift;
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

=head2 get_date

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_date {
  my $self=shift;
  return $self->{date};

}

=head2 set_date

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_date {
  my $self=shift;
  $self->{date}=shift;
}

=head2 get_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_type {
  my $self=shift;
  return $self->{type};

}

=head2 set_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_type {
  my $self=shift;
  $self->{type}=shift;
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

sub get_organism { 
    my $self = shift;
    my $query = "SELECT is_organism.name FROM insitu.is_organism WHERE is_organism_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id()); 
    return ($sth->fetchrow_array())[0];
}

=head2 get_tissue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_tissue {
  my $self=shift;
  return $self->{tissue};

}

=head2 set_tissue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_tissue {
  my $self=shift;
  $self->{tissue}=shift;
}

=head2 get_stage

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_stage {
  my $self=shift;
  return $self->{stage};

}

=head2 set_stage

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_stage {
  my $self=shift;
  $self->{stage}=shift;
}

=head2 get_probe_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_probe_id {
  my $self=shift;
  return $self->{probe_id};

}

=head2 set_probe_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_probe_id {
  my $self=shift;
  $self->{probe_id}=shift;
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

sub get_user { 
    my $self = shift;
    my $person = CXGN::People::Person->new($self->get_dbh(), $self->get_user_id());
    return $person;
}

sub get_probe { 
    my $self = shift;
    return CXGN::Insitu::Probe->new($self->get_dbh(), $self->get_probe_id());
}

sub get_images { 
    my $self = shift;
    if (!exists($self->{images})) { @{$self->{images}}=(); }
    return @{$self->{images}};
}

sub add_image { 
    my $self = shift;
    my $image = shift; # image object
    push @{$self->{images}}, $image;
}

sub get_image_ids { 
    my $self = shift;
    if (!exists($self->{image_ids})) { @{$self->{image_ids}}=(); }
    return @{$self->{image_ids}};
}

sub add_image_id { 
    my $self = shift;
    my $id = shift; # image id
    push @{$self->{image_ids}}, $id;
}

sub remove_image { 
}

=head2 get_tags

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_tags {
    my $self = shift;
    my $query = "SELECT tag_id FROM insitu.experiment_tag WHERE experiment_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_experiment_id);
    my @tags = ();
    while (my ($tag_id) = $sth->fetchrow_array()) { 
	push @tags, CXGN::Tag->new($self->get_dbh(), $tag_id);
    }
    return @tags;
}

=head2 add_tag

 Usage: $experiment->add_tag($tag_id, $sp_person_id)
 Desc:
 Ret: 
 Args:
 Side Effects:
 Example:

=cut

sub add_tag {
    print STDERR "Experiment: Adding tag to experiment..\n";
    my $self = shift;
    my $tag_id = shift;
    my $sp_person_id=shift;
    # check if tag - experiment connection is already there
    #
    my $check = "SELECT tag_id FROM insitu.experiment_tag WHERE experiment_id=? AND tag_id=?";
    my $check_sth = $self->get_dbh()->prepare($check);
    $check_sth->execute($self->get_experiment_id(), $tag_id);
    my ($check_result) = $check_sth->fetchrow_array();
    if ($check_result) { 
	return 0;
    }

    my $query = "INSERT INTO insitu.experiment_tag 
                        (experiment_id, tag_id, sp_person_id)
                  VALUES (?,?,?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_experiment_id(), $tag_id, $sp_person_id);
    
}

sub remove_tag { 
    my $self = shift;
    my $tag_id = shift;
    my $query = "DELETE FROM insitu.experiment_tag 
                        WHERE experiment_id=? AND tag_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_experiment_id(), $tag_id);
}

=head2 exists_tag_experiment

 Usage: my $id=CXGN::Insitu::Experiment::exists_tag_experiment($dbh, $tag_id, $experiment_id)
 Desc:
 Ret:  $tag_experiment_id 
 Args:
 Side Effects:
 Example:

=cut

sub exists_tag_experiment {
    my $dbh = shift;
    my $tag_id = shift;
    my $experiment_id=shift;
    my $query = "SELECT experiment_tag_id 
                 FROM insitu.experiment_tag
                  WHERE tag_id= ? AND experiment_id= ? AND obsolete= 'f'";
    my $sth = $dbh->prepare($query);
    $sth->execute($tag_id, $experiment_id);
    if (my ($id)=$sth->fetchrow_array()) { 
	return $id;
    }
    else { 
	return 0;
    }
}





# sub as_html { 
#     my $self = shift;
#     my $username = $self->get_user()->get_first_name()." ".
# 	$self->get_user()->get_last_name();
#     my $experiment_id = $self->get_experiment_id();
#     my $date = $self->get_date();
#     my $tissue = $self->get_tissue();
#     my $stage = $self->get_stage();
#     my $name = $self->get_name();
#     my $description = $self->get_description();
#     my $organism_id = $self->get_organism_id();
#     my $organism = $self->get_organism();
#     my $probe = $self->get_probe()->get_name();

#     my $categories = "";
    
#     print <<HTML;

#     <center><table border="0" cellpadding="0" cellspacing="0" width="90%">
# <tr>
# 	<th class="fielddef" style="text-align:center" colspan="2">Experiment Info</td>
# </tr>
# <tr>
# 	<td class="fielddef">Name</td>
# 	<td class="fieldinput"><a href=\"?experiment_id=$experiment_id\">$name</a></td>
# </tr>
# <tr>
# 	<td class="fielddef">Submitter</td>
# 	<td class="fieldinput">$username</td>
# 	</td>
# <tr>
# 	<td class="fielddef">Date</td>
# 	<td class="fieldinput">$date</td>
# </tr>
# <tr>
# 	<td class="fielddef">Organism</td>
# 	<td class="fieldinput">$organism</td>
# </tr>
# <tr>
# 	<td class="fielddef">Tissue</td>
# 	<td class="fieldinput">$tissue</td>
# </tr>
# <tr>
# 	<td class="fielddef">Stage</td>
# 	<td class="fieldinput">$stage</td>
# </tr>
# <tr>
# 	<td class="fielddef">Probe</td>
# 	<td class="fieldinput">$probe</td>
# </tr>
# <tr>
# 	<td class="fielddef">Other Info</td>
# 	<td class="fieldinput">$description</td>
# </tr>
# <tr>
# 	<td class="fielddef">Categories</td>
# 	<td class="fieldinput">$categories</td>
# </tr>
# </table></center>

# HTML

#     print qq {<center> <table><tr> };
#     for (my $i=0; $i< (my @image = $self->get_images()); $i++) { 
	
# 	print "<td valign=\"top\">".$image[$i]->get_img_src_tag()."</td><td width=\"20\">&nbsp;</td>";
# 	if (($i+1) % 3 == 0 ) { print "</tr><tr>"; }

#     }
#     print qq { </tr></table></center> };
    

# }

return 1;
