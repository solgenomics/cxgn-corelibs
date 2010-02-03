=head1 NAME

CXGN::Chado::Dbxref::EvidenceI 

An interface for all objects with associated dbxrefs_evidence codes (See Phenome::Locus::LocusDbxrefEvidence).

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut


package CXGN::Chado::Dbxref::EvidenceI;


use base qw / CXGN::DB::ModifiableI  /;



=head2 delete

 Usage: $self->delete()
 Desc:  an alias for $self->obsolete()
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self=shift;
    $self->obsolete();
}


=head2 obsolete
    
 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS
    $self->obsolete()
 Desc:  sets to obsolete an_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: may call $self->store_history() 
 Example:

=cut

sub obsolete {
    my $self = shift;
    die "OVERRIDE THE obsolete() FUNCTION IN YOUR CLASS\n";   
}		     

=head2 unobsolete

 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS
    $self->unobsolete()
 Desc:  unobsolete object_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: 
 Example:

=cut

sub unobsolete {
    my $self = shift;
    die "OVERRIDE THE unobsolete() FUNCTION IN YOUR CLASS\n";
}		     


=head2 store_history

 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS
    $self->store_history() . call this function before deleting or updating 
 Desc:  'moves' the record to the [object] _dbxref_evidence table
               this is important for allowing future updates of the [object] _dbxref_evidence table
               is cases of [object]_dbxref being obsoleted and then being un-obsoleted with a new
               set of evidence codes and references. The old evidence codes will be kept in the history table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store_history {
    my $self=shift;
    die "OVERRIDE THE store_history() FUNCTION IN YOUR CLASS\n";
}

=head2 evidence_exists

 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS
        $self->evidence_exists()
 Desc:  find if the evidence details already exists in db 
 Ret:   database id or undef 
 Args:  none
 Side Effects: none
 Example:

=cut

sub evidence_exists {
    my $self=shift;
    die "YOU NEED TO OVERRIDE THIS FUNCTION (evidence_exists()) IN YOUR CLASS! "
}

=head2 get_object_dbxref

 Usage: OVERRIDE THIS FUNCTION IN YOUR CLASS
        $self->get_object_dbxref()
 Desc:  get the $objectDbxref object for this evidence 
 Ret:   a $objectDbxref object
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_locus_dbxref {
    my $self=shift;
    die "YOU NEED TO OVERRIDE THIS FUNCTION IN YOUR CLASS! "
}



=head2 Accessors available
    object_dbxref_id
    object_dbxref_evidence_id
    relationship_type_id
    evidence_code_id
    evidence_description_id
    evidence_description_id
    evidence_with
    reference_id

=cut

sub get_object_dbxref_id {
  my $self=shift;
  return $self->{object_dbxref_id};

}

sub set_object_dbxref_id {
  my $self=shift;
  $self->{object_dbxref_id}=shift;
}

sub get_object_dbxref_evidence_id {
    my $self=shift;
    return $self->{object_dbxref_evidence_id};

}

sub set_object_dbxref_evidence_id {
  my $self=shift;
  $self->{object_dbxref_evidence_id}=shift;
}


sub get_relationship_type_id {
  my $self=shift;
  return $self->{relationship_type_id};

}

sub set_relationship_type_id {
  my $self=shift;
  $self->{relationship_type_id}=shift;
}

sub get_evidence_code_id {
  my $self=shift;
  return $self->{evidence_code_id};

}

sub set_evidence_code_id {
  my $self=shift;
  $self->{evidence_code_id}=shift;
}

sub get_evidence_description_id {
  my $self=shift;
  return $self->{evidence_description_id};

}

sub set_evidence_description_id {
  my $self=shift;
  $self->{evidence_description_id}=shift;
}


sub get_evidence_with {
  my $self=shift;
  return $self->{evidence_with};

}

sub set_evidence_with {
  my $self=shift;
  $self->{evidence_with}=shift;
}

sub get_reference_id {
  my $self=shift;
  return $self->{reference_id};

}

sub set_reference_id {
  my $self=shift;
  $self->{reference_id}=shift;
}





##########
return 1;#
##########
