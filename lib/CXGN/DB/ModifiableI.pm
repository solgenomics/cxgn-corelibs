
=head1 NAME

CXGN::DB::ModifiableI 
An interface for editable objects (locus, allele, individual, unigene, etc)
  

=head1 SYNOPSIS

The interface provides commonly used accessors, static functions, ad well as object functions.
The static functions take a database handle as an argument, while the object functions use the object's database handle.

Most functions need to be overridden in the class implementing it.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>
Naama Menda <nm249@cornell.edu>

=cut 


use strict;
package CXGN::DB::ModifiableI;


use CXGN::DB::Object;

use base qw | CXGN::DB::Object |;

=head1 Object methods

These methods need to be overriden in a  class implementing this interface

=cut 


=head2 new

 Usage: constructor
 Desc:
 Ret:    
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    
    my $self = $class->SUPER::new($dbh);
    return $self;
    
}

=head2 exists_in_database

 Usage:        my $already_exists = CXGN::YourSubClassImplementingModifiableI
                   ->exists_in_database($dbh, "foo");
 Desc:         this function 
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self = shift;
    my $dbh = shift;
    warn "Override this function in subclass\n";
    return 0;
}



=head2 accessors in this class:

   
    sp_person_id
    create_date
    modification_date ( modified_date is a synonym) 
    obsolete

=cut 


sub get_obsolete {
  my $self=shift;
  if (!exists($self->{obsolete}) || !defined($self->{obsolete})) { $self->{obsolete}='f'; }
  return $self->{obsolete};
}

sub set_obsolete {
  my $self=shift;
  my $obsolete = shift;
  if ($obsolete eq "1") { $obsolete = "t"; }
  if ($obsolete eq "0") { $obsolete = "f"; }
  if ($obsolete ne "t" && $obsolete ne "f") {
      print STDERR "ModifiableI.pm: set_obsolete parameters can either be t or f (passed obsolete= '$obsolete').\n";
  }
  $self->{obsolete}=$obsolete;
}

sub get_sp_person_id {
  my $self=shift;
  return $self->{sp_person_id};

}

sub set_sp_person_id {
  my $self=shift;
  $self->{sp_person_id}=shift;
}
 

sub get_create_date {
  my $self = shift;
  return $self->{create_date}; 
}

sub set_create_date {
  my $self = shift;
  $self->{create_date} = shift;
}

sub get_modification_date {
  my $self = shift;
  return $self->{modification_date}; 
}

sub set_modification_date {
  my $self = shift;
  $self->{modification_date} = shift;
}

=head2 accessors get_modified_date, set_modified_date

 Usage: 
 Desc:  a synonm for get/set_modification_date()
 Property
 Side Effects:
 Example:

=cut

sub get_modified_date {
  my $self = shift;
  return $self->get_modification_date();
}

sub set_modified_date {
  my $self = shift;
  $self->set_modification_date();
}

=head2 accessors set_updated_by, get_updated_by

  Property:	updated_by designates the sp_person entry of the
                user who updated the record last. Normally this is 
                the same as the owner, but users of type "curator" 
                can update any record. In that case, the updated_by
                would refer to the curator. The owner of the record,
                specified by sp_person_id, would remain intact.

=cut

sub get_updated_by { 
  my $self=shift;
  return $self->{updated_by};
}

sub set_updated_by { 
  my $self=shift;
  $self->{updated_by}=shift;
}

=head2 is_obsolete

 Usage:
 Desc:         a synonym for get_obsolete. Looks better in certain code.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub is_obsolete {
    my $self= shift;
    return $self->get_obsolete();
}

=head2 get_person_details

 Usage: $self->get_person_details($sp_person_id)
 Desc:  find the first and last name, and a link to personal-info.pl
         of a person using the sp_person_id
 Ret:  an html link to personal_info.pl
 Args:  none (tries to get the sp_person_id from the object) or $sp_person_id (preceeds the sp_person_id of the object)
 Side Effects:
 Example:

=cut

sub get_person_details {
    my $self=shift;
    my $sp_person_id=shift || $self->get_sp_person_id();
    my $person = CXGN::People::Person->new($self->get_dbh(), $sp_person_id);
    my $first_name = $person->get_first_name();
    my $last_name = $person->get_last_name();
    my $person_html .=qq |<a href="/solpeople/personal-info.pl?sp_person_id=$sp_person_id">$first_name $last_name</a> |;
    return $person_html;
}



=head2 add_owner

 Usage: $self->add_owner($person)
 Desc:  add an owner to your object
 Ret:   nothing 
 Args:  a CXGN::People::Person object
 Side Effects: none
 Example:

=cut


sub add_owner {
    my $self=shift;
    my $owner = shift; #person object
    push @{ $self->{owners} }, $owner;
}

=head2 get_owners
 
 Usage: $self->get_owners()
 Desc:  finnd the owners of your object
 Ret:   a list of owners  (usually Person objects)
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_owners {
  my $self=shift;
  return @{$self->{owners}};

}


###
1;# do not remove
###
