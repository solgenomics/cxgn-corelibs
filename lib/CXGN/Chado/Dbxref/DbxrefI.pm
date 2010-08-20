

=head1 NAME

CXGN::Chado::Dbxref::DbxrefI 

An interface for all objects with associated dbxrefs.

=head1 SYNOPSIS

The interface consists of accessors used in all classes implementing an SGN object with associated dbxrefs
(e.g. LocusDbxref, IndividualDbxref)
static functions that take a database handle as an argument 
and object functions that use the object's dbh

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use strict;

package CXGN::Chado::Dbxref::DbxrefI;


use base qw / CXGN::DB::ModifiableI  /;


=head1 FUNCTIONS


=cut 


=head2 accessors in this class
    
    object_dbxref_id
    object_id
    dbxref_id
    
The following accessors are available from Tools::ModifiableI
    sp_person_id
    obsolete
    create_date
    modification_date

=cut

sub get_object_dbxref_id {
  my $self=shift;
  return $self->{object_dbxref_id};

}

sub set_object_dbxref_id {
  my $self=shift;
  $self->{object_dbxref_id}=shift;
}


sub get_object_id {
  my $self=shift;
  return $self->{object_id};

}

sub set_object_id {
  my $self=shift;
  $self->{object_id}=shift;
}


sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};

}

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}

=head2 get_object_dbxref_evidence

 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS:  my $object_dbxref->get_object_dbxref_evidence()
 Desc:  get all the evidence data associated with an object_ dbxref (ontology term)
 Ret:   a list of object_dbxref_evidence objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_object_dbxref_evidence {
    my $self=shift;
    die "OVERRIDE THIS FUNCTION IN YOUR CLASS " . $self . "\n";
   
}


	
=head2 add_object_dbxref_evidence

 Usage:        $self->add_object_dbxref_evidence($object_dbxref_evidence_object);
 Desc:         adds an object_dbxref_evidence to this object
 Ret:          nothing
 Args:        
 Side Effects:  
 Example:

=cut

sub add_object_dbxref_evidence {
    my $self=shift;
    my $evidence=shift; 
    push @{ $self->{evidences} }, $evidence;
}


=head2 get_evidences

 Usage: $self->get_evidences() ( $self->{evidences} )
 Desc:  accessor for the object_dbxref evidences
 Ret:  a list of evidence object  
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_evidences {
    my $self=shift;
    return @{$self->{evidences}};
}

=head2 get_dbxref

 Usage: $self->get_dbxref($dbxref_id)
 Desc:  get the Dbxref object of your object_dbxref, or provide a dbxref_id .
 (e.g. for tables with foreign keys to dbxref. See LocusDbxrefEvidence)
 Ret:   a CXGN::Chado::Dbxref object
 Args:  none
 Side Effects: none 
 Example:

=cut

sub get_dbxref {
    my $self=shift;
    my $dbxref_id= shift || $self->get_dbxref_id()  || warn "No dbxref_id exists for this object!\n";
    if (!$self->get_dbh()) { warn "DbxrefI does not have a dbh!!!!!!!!\n\n\n";}
    return CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
}



=head2 object_dbxref_exists

 Usage: OVERRIDE THIS FUNCTION IN CHILD CLASS.
    my $object_dbxref_id= object_dbxref_exists($dbh, $object_id, $dbxref_id)
 Desc:  check if object_id is associated with $dbxref_id  
 Ret:   $object_dbxref_id 
 Args:  $object_id, $dbxref_id
 Side Effects:
 Example:

=cut

sub object_dbxref_exists {
    my ($dbh, $object_id, $dbxref_id)=@_;
    die "Need to override this function in your class!\n";
}



=head2 evidence_details

 Usage: $object_dbxref->evidence_details()
 Desc:  Find all the evidences for your object_dbxref (usually an ontology annotation)
        in your code go through the array and build the html for displaying the annotation evidence information.
 Ret:   array of hashes (one hash for each evidence) 
    my $ev_hash={
	    dbxref_ev_object=> an ObjectDbxrefEvidence object (e.g. CXGN::Phenome::Locus::LocusDbxrefEvidence),
	    obsolete        => the evidence object obsolete status ('t' of 'f'),,
	    relationship    => a formatted cvterm_name of the relationship field,
	    ev_code         => a formatted cvterm_name of the evidence_code field,,
	    ev_with         => a formatted cvterm_name of the evidence_with field,,
	    ev_desc         => a formatted cvterm_name of the evidence_description field,, 
	    ev_with_url     => the full url (urlprefix+url+accession) for the evidence_with field,
	    ev_with_acc     => a full accession (db_name:accession) for the evidence_with field (null if undef),
	    reference_url   => the full url for the reference field (SGN references use the pub_id as the accession for constructing the url),
	    reference_acc   => the full accession for the evidence reference field,  
	    submitter       => a string with the name of the evidence owner wrapped in a link to  personal_info SGN page + the current date (the latter of modified_date or create date),
	};

 Args: none
 Side Effects:
 Example:

=cut

sub evidence_details {
    
    my $self=shift; #object_dbxref object
    my @AoH=();
    my @evidences=$self->get_object_dbxref_evidence();
    foreach my $ev(@evidences) {
	#A Dbxref object for 'evidence_with' field
	my $ev_with= CXGN::Chado::Dbxref->new($self->get_dbh(), $ev->get_evidence_with() );
	my $ev_with_db_id = $ev_with->get_accession();
	my $ev_with_acc= $ev_with->get_db_name() . ":" . $ev_with->get_accession() if $ev_with->get_db_name();
	#if ($ev_with->get_db_name() eq 'SP') { $ev_with_db_id = $ev_with->get_cvterm_id(); }
        #A Dbxref object for the evidence 'reference' field
	my $reference=CXGN::Chado::Dbxref->new($self->get_dbh() , $ev->get_reference_id() );
	my $ref_db_id = $reference->get_accession();
	if ($reference->get_db_name() eq 'SGN_ref') { $ref_db_id = $reference->get_publication()->get_pub_id(); }
	my $ref_acc= $reference->get_db_name() . ":" . $reference->get_accession() if $reference->get_db_name();
	#The submitter + date information
	my $ev_owner= $ev->get_person_details();
	my $ev_date = $ev->get_modification_date() || $ev->get_create_date();
	#The evidence details hash. These are the fields that will be used in your code for printing the ontology evidences
        no warnings 'uninitialized';
	my $ev_hash={
	    dbxref_ev_object=> $ev,
	    obsolete        => $ev->get_obsolete(),
	    relationship    => $self->get_cvterm_string($ev->get_relationship_type_id() ),
	    ev_code         => $self->get_cvterm_string($ev->get_evidence_code_id() ),
	    ev_with         => $self->get_cvterm_string($ev->get_evidence_with() ),
	    ev_desc         => $self->get_cvterm_string($ev->get_evidence_description_id() ), 
	    ev_with_url     => $ev_with->get_urlprefix() . $ev_with->get_url() . $ev_with_db_id,
	    ev_with_acc     => $ev_with_acc ,
	    reference_url   => $reference->get_urlprefix() . $reference->get_url() . $ref_db_id,
	    reference_acc   => $ref_acc,  
	    submitter       => $ev_owner . substr($ev_date, 0, 10),
	};
	#Now push each hash into the array of evidences for your object_dbxref
	push @AoH, $ev_hash;
    }
    return @AoH;
}

###########

=head2 get_cvterm_string

 Usage: $self->get_cvterm_string($dbxref_id)
 Desc:  get the cvterm name. Useful for finding the cvterm for each of the 
        evidence object details, which all are foreign keys to the public.dbxref table
        (relationship_type_id, evidence_code_id, reference_id, evidence_with, evidence_description_id) 
 Ret:   a cvterm_name string
 Args:  dbxref_id
 Side Effects: removes underscores from cvterm_name string
 Example:

=cut

sub get_cvterm_string {
    my $self=shift;
    my $dbxref_id=shift;
    my $dbxref_obj=CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    my $cvterm_name=$dbxref_obj->get_cvterm_name();
    if ($cvterm_name) {$cvterm_name=~s /_/ / ; }
    return $cvterm_name;
}




###
1;#do not remove
###



