

=head1 NAME

CXGN::SNP - a class to deal with SNP information.

=head1 DESCRIPTION

This class deals with a single SNP (Simple Nucleotide Polymorphism) - it can be used to store, modify, or delete information about a SNP. The term SNP is interpreted broadly and includes indels as well as polymorphisms that may include several nucleotides.

For SNP querying of aggregate information, use the L<CXGN::SNP::Query> class [not yet implemented].

It inherits from L<CXGN::DB::ModifiableI>.

SNPs are linked to sequences and accessions, and specify the base change. In addition, SNPs can be linked to markers that exploit that SNP, and to other meta information, such as who submitted the information, if it is experimentally verified, and the method of discovery.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following methods:

=cut

use strict;


package CXGN::SNP;

use base qw | CXGN::DB::ModifiableI |;

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
    
    $self->set_snp_id($id);
    if ($id) { 
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
    my $q = "SELECT snp_id,
                    reference_unigene_id,
                    reference_position,
                    primer_left_id,
                    primer_right_id,
                    reference_accession_id,
                    snp_accession_id,
                    reference_nucleotide,
                    snp_nucleotide,
                    sp_person_id,
                    modified_date,
                    create_date,
                    obsolete
               FROM sgn.snp
              WHERE snp_id = ?";
    my $h = $self->get_dbh()->prepare($q);

    $h->execute($self->get_snp_id());

    my ($snp_id, $reference_unigene_id, $reference_position, $primer_left_id, $primer_right_id, $reference_accession_id, $snp_accession_id, $reference_nucleotide, $snp_nucleotide, $sp_person_id, $modified_date, $create_date, $obsolete) = $h->fetchrow_array();

    $self->set_snp_id($snp_id);
    $self->set_reference_unigene_id($reference_unigene_id);
    $self->set_reference_position($reference_position);
    $self->set_primer_left_id($primer_left_id);
    $self->set_primer_right_id($primer_right_id);
    $self->set_reference_accession_id($reference_accession_id);
    $self->set_snp_accession_id($snp_accession_id);
    $self->set_reference_nucleotide($reference_nucleotide);
    $self->set_snp_nucleotide($snp_nucleotide);
    $self->set_sp_person_id($sp_person_id);
    $self->set_modified_date($modified_date);
    $self->set_create_date($create_date);
    $self->set_obsolete($obsolete);
    
                    
                        
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
    
    if ($self->get_snp_id()) { 
	my $q = "UPDATE sgn.snp SET
                  reference_unigene_id=?,
		  reference_position=?,
                  primer_left_id=?,
                  primer_right_id=?,
                  reference_accession_id=?,
                  snp_accession_id=?,
                  reference_nucleotide=?,
                  snp_nucleotide=?,
                  sp_person_id=?,
                  modified_date=NOW(),
                  obsolete=?
                 WHERE 
                  snp_id=?";
	my $h = $self->get_dbh()->prepare($q);
	$h->execute(
	    $self->get_reference_unigene_id(),
	    $self->get_reference_position(),
	    $self->get_primer_left_id(),
	    $self->get_primer_right_id(),
	    $self->get_reference_accession_id(),
	    $self->get_snp_accession_id(),
	    $self->get_snp_nucleotide(),
	    $self->get_sp_person_id(),
	    $self->get_obsolete(),
	    $self->get_snp_id()
	    );
    }
    else { 
	my $q = "INSERT INTO sgn.snp
                   (reference_unigene_id,
                    reference_position,
                    primer_left_id,
                    primer_right_id,
                    reference_accession_id,
                    snp_accession_id, 
                    reference_nucleotide,
                    snp_nucleotide,
                    sp_person_id,
                    modified_date,
                    create_date,
                    obsolete)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), ?)";
	my $h = $self->get_dbh()->prepare($q);
	$h->execute();
	
    }				      

}



=Head2_snp_id, set_snp_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_snp_id {
  my $self = shift;
  return $self->{snp_id}; 
}

sub set_snp_id {
  my $self = shift;
  $self->{snp_id} = shift;
}

=head2 accessors get_position, set_position

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_position {
  my $self = shift;
  return $self->{position}; 
}

sub set_position {
  my $self = shift;
  $self->{position} = shift;
}
=head2 accessors get_reference_nucleotide, set_reference_nucleotide

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_reference_nucleotide {
  my $self = shift;
  return $self->{reference_nucleotide}; 
}

sub set_reference_nucleotide {
  my $self = shift;
  $self->{reference_nucleotide} = shift;
}
=head2 accessors get_snp_nucleotide, set_snp_nucleotide

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_snp_nucleotide {
  my $self = shift;
  return $self->{snp_nucleotide}; 
}

sub set_snp_nucleotide {
  my $self = shift;
  $self->{snp_nucleotide} = shift;
}


=head2 accessors get_reference_accession_id, set_reference_accession_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_reference_accession_id {
  my $self = shift;
  return $self->{reference_accession_id}; 
}

sub set_reference_accession_id {
  my $self = shift;
  $self->{reference_accession_id} = shift;
}

=head2 accessors get_snp_accession_id, set_snp_accession_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_snp_accession_id {
  my $self = shift;
  return $self->{snp_accession_id}; 
}

sub set_snp_accession_id {
  my $self = shift;
  $self->{snp_accession_id} = shift;
}


=head2 accessors get_dbxrefs, set_dbxrefs

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_dbxrefs {
  my $self = shift;
  return $self->{dbxrefs}; 
}

sub set_dbxrefs {
  my $self = shift;
  $self->{dbxrefs} = shift;
}

=head2 add_marker

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_marker {

}

=head2 get_markers

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_markers {

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
    my $class = shift;
    my $dbh = shift;

    my $q = qq{
                CREATE TABLE sgn.snp (
				      snp_id serial primary key,
				      reference_unigene_id bigint references sgn.unigene,
				      reference_position bigint,
				      primer_left_id bigint references sgn."sequence",
				      primer_right_id bigint references sgn."sequence",
				      reference_accession_id bigint references sgn.accession,
				      snp_accession_id bigint references sgn.accession,
				      reference_nucleotide varchar(1),
				      snp_nucleotide varchar(1),
				      sp_person_id bigint REFERENCES sgn_people.sp_person,
				      modified_date timestamp with time zone,
				      create_date timestamp with time zone,
				      obsolete boolean default false
				      
				      )
		};
    
    $dbh->do($q);

    $dbh->do("GRANT SELECT, UPDATE, INSERT ON sgn.snp TO web_usr");
    $dbh->do("GRANT SELECT, UPDATE, INSERT ON snp_snp_id_seq TO web_usr");
    
    my $p = qq { 
	        CREATE TABLE sgn.snp_marker (
					     snp_marker_id serial primary key,
					     snp_id bigint references sgn.snp,
					     marker_id bigint references sgn.marker
					     )
		};
		
    $dbh->do($p);

    $dbh->do("GRANT SELECT, UPDATE, INSERT ON sgn.snp_marker TO web_usr");
    $dbh->do("GRANT SELECT, UPDATE, INSERT ON sgn.snp_marker_snp_marker_id_seq TO web_usr");


    my $x = " CREATE TABLE sgn.snp_dbxref ( 
                 snp_dbxref_id serial primary key,
                 snp_id bigint references sgn.snp,
                 dbxref_id bigint references public.dbxref,
                 obsolete boolean,
                 sp_person_id bigint references sgn_people.sp_person,
                 create_date timestamp with time zone,
                 modified_date timestamp with time zone
              )";

    $dbh->do($x);
    
    $dbh->do("GRANT SELECT, UPDATE, INSERT ON sgn.snp_dbxref TO web_usr");
    $dbh->do("GRANT SELECT, UPDATE, INSERT ON sgn.snp_dbxref_snp_dbxref_id_seq TO web_usr");

    

    $dbh->commit();
}




return 2; #haha
