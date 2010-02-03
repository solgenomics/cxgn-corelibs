
=head1 NAME

CXGN::Transcript::Library - a class to deal with transcript libraries.

=head1 DESCRIPTION

Transcript library data is stored in the sgn.library table. This class provides easy access to library fields and inherits from CXGN::DB::ModifiableI, so that it can be used with SimpleFormPage.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Transcript::Library;

use strict;

use CXGN::DB::ModifiableI;

use base qw | CXGN::DB::ModifiableI |;

=head2 new

 Usage:         my $lib = CXGN::Transcript::Library->new($dbh, $id);
 Desc:          creates a new library object for library_id = $id.
 Ret:           a library object populated with library data, if $id
                references an existing library, an empty library object
                if $id is omitted or false, and undef if $id is not false
                but does not correspond to a legal library_id
 Args:
 Side Effects:  accesses the database
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->set_library_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 fetch

 Usage:
 Desc:         used internally to populate the object 
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT library_id, type, library_name, library_shortname, authors, organism_id, chado_organism_id, cultivar, accession, 
                        tissue, development_stage, treatment_conditions, cloning_host, vector, rs1, rs2, cloning_kit, comments, 
                        contact_information, order_routing_id, forward_adapter, reverse_adapter, sp_person_id,  modified_date, 
                        create_date 
                 FROM sgn.library WHERE (obsolete='f' or obsolete is null) AND library_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_library_id());
    my ($library_id, $type, $library_name, $library_shortname, $authors, $organism_id, $chado_organism_id, $cultivar, $accession, 
	$tissue, $development_stage, $treatment_conditions, $cloning_host, $vector, $rs1, $rs2, $cloning_kit, $comments, 
        $contact_information, $order_routing_id, $forward_adapter, $reverse_adapter, $sp_person_id, $modified_date, $create_date) 
    = $sth->fetchrow_array();

    $self->set_library_id($library_id);
    $self->set_type($type);
    $self->set_library_name($library_name);
    $self->set_library_shortname($library_shortname);
    $self->set_authors($authors);
    $self->set_organism_id($organism_id);
    $self->set_chado_organism_id($chado_organism_id);
    $self->set_cultivar($cultivar);
    $self->set_accession($accession);
    $self->set_tissue($tissue);
    $self->set_development_stage($development_stage);
    $self->set_treatment_conditions($treatment_conditions);
    $self->set_cloning_host($cloning_host);
    $self->set_vector($vector);
    $self->set_rs1($rs1);
    $self->set_rs2($rs2);
    $self->set_cloning_kit($cloning_kit);
    $self->set_comments($comments);
    $self->set_contact_information($contact_information);
    $self->set_order_routing_id($order_routing_id);
    $self->set_forward_adapter($forward_adapter);
    $self->set_reverse_adapter($reverse_adapter);
    $self->set_sp_person_id($sp_person_id);
    $self->set_modification_date($modified_date);
    $self->set_create_date($create_date);
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
    if ($self->get_library_id()) { 
	my $query = "UPDATE sgn.library set type=?, library_name=?, library_shortname=?, authors=?, organism_id=?, chado_organism_id=?, cultivar=?, accession=?, tissue=?, development_stage=?, treatment_conditions=?, cloning_host=?, vector=?, rs1=?, rs2=?, cloning_kit=?, comments=?, contact_information=?, order_routing_id=?, forward_adapter=?, reverse_adapter=?, sp_person_id=?, obsolete=?, modified_date=?, create_date=? WHERE library_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_type(),
		      $self->get_library_name(),
		      $self->get_library_shortname(),
		      $self->get_authors(),
		      $self->get_organism_id(),
	              $self->get_chado_organism_id(),
		      $self->get_cultivar(),
		      $self->get_accession(),
		      $self->get_tissue(),
		      $self->get_development_stage(),
		      $self->get_treatment_conditions(),
		      $self->get_cloning_host(),
		      $self->get_vector(),
		      $self->get_rs1(),
		      $self->get_rs2(),
		      $self->get_cloning_kit(),
		      $self->get_comments(),
		      $self->get_contact_information(),
		      $self->get_order_routing_id(),
		      $self->get_forward_adapter(),
		      $self->get_reverse_adapter(),
		      $self->get_sp_person_id(),
		      $self->get_obsolete(),
		      $self->get_modified_date(),
		      $self->get_create_date(),
		      $self->get_library_id()
		      );
	return $self->get_library_id();
    }
    else { 
	my $query = "INSERT INTO sgn.library (type, library_name, library_shortname, authors, organism_id, chado_organism_id, cultivar, accession, tissue, development_stage, treatment_conditions, cloning_host, vector, rs1, rs2, cloning_kit, comments, contact_information, order_routing_id, forward_adapter, reverse_adapter, sp_person_id, obsolete, modified_date, create_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_type(),
		      $self->get_library_name(),
		      $self->get_library_shortname(),
		      $self->get_authors(),
		      $self->get_organism_id(),
	              $self->get_chado_organism_id(),
		      $self->get_cultivar(),
		      $self->get_accession(),
		      $self->get_tissue(),
		      $self->get_development_stage(),
		      $self->get_treatment_conditions(),
		      $self->get_cloning_host(),
		      $self->get_vector(),
		      $self->get_rs1(),
		      $self->get_rs2(),
		      $self->get_cloning_kit(),
		      $self->get_comments(),
		      $self->get_contact_information(),
		      $self->get_order_routing_id(),
		      $self->get_forward_adapter(),
		      $self->get_reverse_adapter(),
		      $self->get_sp_person_id(),
		      $self->get_obsolete(),
		      $self->get_modified_date(),
		      $self->get_create_date()
		      );
	$self->get_dbh()->last_insert_id("library", "sgn");
    }
}



# library_id           | integer                | 
#  type                 | bigint                 | 
#  submit_user_id       | integer                | 
#  library_name         | character varying(80)  | 
#  library_shortname    | character varying(16)  | 
#  authors              | character varying(255) | 
#  organism_id          | integer                | 
#  cultivar             | character varying(255) | 
#  accession            | character varying(255) | 
#  tissue               | character varying(255) | 
#  development_stage    | character varying(255) | 
#  treatment_conditions | text                   | 
#  cloning_host         | character varying(80)  | 
#  vector               | character varying(80)  | 
#  rs1                  | character varying(12)  | 
#  rs2                  | character varying(12)  | 
#  cloning_kit          | character varying(255) | 
#  comments             | text                   | 
#  contact_information  | text                   | 
#  order_routing_id     | bigint                 | 
#  sp_person_id         | integer                | 
#  forward_adapter      | character varying      | 
#  reverse_adapter      | character varying      |
#  chado_organism_id    | integer                |

=head2 get_library_id, set_library_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_library_id {
  my $self=shift;
  return $self->{library_id};

}

sub set_library_id {
  my $self=shift;
  $self->{library_id}=shift;
}



=head2 get_type, set_type

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

sub set_type {
  my $self=shift;
  $self->{type}=shift;
}



=head2 get_library_name, set_library_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_library_name {
  my $self=shift;
  return $self->{library_name};

}

sub set_library_name {
  my $self=shift;
  $self->{library_name}=shift;
}

=head2 get_library_shortname, set_library_shortname

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_library_shortname {
  my $self=shift;
  return $self->{library_shortname};

}

sub set_library_shortname {
  my $self=shift;
  $self->{library_shortname}=shift;
}

=head2 get_authors, set_authors

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_authors {
  my $self=shift;
  return $self->{authors};

}

sub set_authors {
  my $self=shift;
  $self->{authors}=shift;
}

=head2 get_organism_id, set_organism_id

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

sub set_organism_id {
  my $self=shift;
  $self->{organism_id}=shift;
}

=head2 get_chado_organism_id, set_chado_organism_id

 Usage:
 Desc: This is a function used in the transition of this system to transcript schema
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_chado_organism_id {
  my $self=shift;
  return $self->{chado_organism_id};

}

sub set_chado_organism_id {
  my $self=shift;
  $self->{chado_organism_id}=shift;
}



=head2 get_cultivar, set_cultivar

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cultivar {
  my $self=shift;
  return $self->{cultivar};

}

sub set_cultivar {
  my $self=shift;
  $self->{cultivar}=shift;
}

=head2 get_accession, set_accession

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_accession {
  my $self=shift;
  return $self->{accession};

}

sub set_accession {
  my $self=shift;
  $self->{accession}=shift;
}

=head2 get_accession_id, set_accession_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_accession_id {
  my $self=shift;
  return $self->{accession_id};

}

sub set_accession_id {
  my $self=shift;
  $self->{accession_id}=shift;
}
=head2 get_tissue, set_tissue

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

sub set_tissue {
  my $self=shift;
  $self->{tissue}=shift;
}

=head2 get_development_stage, set_development_stage

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_development_stage {
  my $self=shift;
  return $self->{development_stage};

}

sub set_development_stage {
  my $self=shift;
  $self->{development_stage}=shift;
}

=head2 get_treatment_conditions, set_treatment_conditions

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_treatment_conditions {
  my $self=shift;
  return $self->{treatment_conditions};

}

sub set_treatment_conditions {
  my $self=shift;
  $self->{treatment_conditions}=shift;
}

=head2 get_cloning_host, set_cloning_host

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cloning_host {
  my $self=shift;
  return $self->{cloning_host};

}



sub set_cloning_host {
  my $self=shift;
  $self->{cloning_host}=shift;
}

=head2 get_vector, set_vector

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_vector {
  my $self=shift;
  return $self->{vector};

}


sub set_vector {
  my $self=shift;
  $self->{vector}=shift;
}


=head2 get_rs1, set_rs1

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_rs1 {
  my $self=shift;
  return $self->{rs1};

}

sub set_rs1 {
  my $self=shift;
  $self->{rs1}=shift;
}

=head2 get_rs2, set_rs2

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_rs2 {
  my $self=shift;
  return $self->{rs2};

}

sub set_rs2 {
  my $self=shift;
  $self->{rs2}=shift;
}

=head2 get_cloning_kit, set_cloning_kit

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cloning_kit {
  my $self=shift;
  return $self->{cloning_kit};

}

sub set_cloning_kit {
  my $self=shift;
  $self->{cloning_kit}=shift;
}

=head2 get_comments, set_comments

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_comments {
  my $self=shift;
  return $self->{comments};

}

sub set_comments {
  my $self=shift;
  $self->{comments}=shift;
}

=head2 get_contact_information, set_contacdt_information

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_contact_information {
  my $self=shift;
  return $self->{contact_information};

}

sub set_contact_information {
  my $self=shift;
  $self->{contact_information}=shift;
}

=head2 get_forward_adapter, set_forward_adapter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_forward_adapter {
  my $self=shift;
  return $self->{forward_adapter};
}

sub set_forward_adapter {
  my $self=shift;
  $self->{forward_adapter}=shift;
}

=head2 get_reverse_adapter, set_reverse_adapter

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_reverse_adapter {
  my $self=shift;
  return $self->{reverse_adapter};

}

sub set_reverse_adapter {
  my $self=shift;
  $self->{reverse_adapter}=shift;
}


=head2 function get_est_count

 Usage:        my $est_count = $library->get_est_count();
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_est_count {
    my $self = shift;
    
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $query = "SELECT count(*) FROM 
                    $sgn.clone join $sgn.seqread using(clone_id) join $sgn.est using(read_id) 
                 WHERE library_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_library_id());
    my ($count) = $sth->fetchrow_array();
    return $count;
}


=head2 function get_clone_count

 Usage:        my $clone_count = $library->get_clone_count();
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_clone_count {
    my $self = shift;
    
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $query = "SELECT count(*) FROM 
                    $sgn.clone 
                 WHERE library_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_library_id());
    my ($count) = $sth->fetchrow_array();
    return $count;
}

=head2 get_order_routing_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_order_routing_id {
  my $self=shift;
  return $self->{order_routing_id};

}

=head2 set_order_routing_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_order_routing_id {
  my $self=shift;
  $self->{order_routing_id}=shift;
}

=head2 get_organism_name 

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_name  {
    my $self = shift;
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $query = "SELECT organism_name FROM $sgn.organism WHERE organism_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_organism_id());
    my ($organism_name) = $sth->fetchrow_array();
    return $organism_name;
}




return 1;
