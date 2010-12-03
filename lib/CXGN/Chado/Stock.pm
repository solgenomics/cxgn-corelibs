=head1 NAME

CXGN::Chado::Stock - a second-level DBIC Bio::Chado::Schema::Stock::Stock object

Version:1.0

=head1 DESCRIPTION

Created to work with  CXGN::Page::Form::AjaxFormPage
for eliminating the need to refactor the  AjaxFormPage and Editable  to work with DBIC objects.
Functions such as 'get_obsolete' , 'store' , and 'exists_in_database' are required , and do not use standard DBIC syntax.

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=cut

package CXGN::Chado::Stock ;
use strict;
use warnings;
use Carp;
use Bio::Chado::Schema;

use base qw / CXGN::DB::Object / ;

=head2 new

  Usage: my $stock = CXGN::Chado::Stock->new($schema, $stock_id);
  Desc:
  Ret: a CXGN::Chado::Stock object
  Args: a $schema a schema object,
        $stock_id, if omitted, an empty stock object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use. die if the id is not an integer.

=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

     ### First, bless the class to create the object and set the schema into the object.
    #my $self = $class->SUPER::new($schema);
    my $self = bless {}, $class;
    $self->set_schema($schema);
    my $stock;
    if (defined $id) {
	$stock = $self->get_resultset('Stock::Stock')->find({ stock_id => $id });
    } else {
	### Create an empty resultset object;
	$stock = $self->get_resultset('Stock::Stock')->new( {} );   
    }
    ###It's important to set the object row for using the accesor in other class functions
    $self->set_object_row($stock);
    return $self;
}



=head2 store

 Usage: $self->store
 Desc:  store a new stock
 Ret:   a database id
 Args:  none
 Side Effects: checks if the stock exists in the database, and if does, will attempt to update
 Example:

=cut

sub store {
    my $self=shift;
    my $id = $self->get_stock_id();
    my $schema=$self->get_schema();
    #no stock id . Check first if the name  exists in te database
    if (!$id) {
	my $exists= $self->exists_in_database();
	if (!$exists) {
	    my $new_row = $self->get_object_row();
	    $new_row->insert();

	    $id=$new_row->stock_id();
	}else {
	    my $existing_stock=$self->get_resultset('Stock::Stock')->find($exists);
	    #don't update here if stock already exist. User should call from the code exist_in_database
	    #and instantiate a new stock object with the database id
	    #updating here is not a good idea, since it might not be what the user intended to do
            #and it can mess up the database.
	}
    }else { # id exists
	$self->get_object_row()->update();
    }
    return $id
}

########################


=head2 exists_in_database

 Usage: $self->exists_in_database()
 Desc:  check if the uniquename exists in the stock table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $stock_id = $self->get_stock_id();
    my $uniquename = $self->get_uniquename || '' ;
    my ($s) = $self->get_resultset('Stock::Stock')->search( 
	{
	    uniquename  => { 'ilike' => $uniquename },
	});
    #loading new stock - $stock_id is undef
    if (defined($s) && !$stock_id ) {  return $s->stock_id ; }

    #updating an existing stock
    elsif ($stock_id && defined($s) ) {
	if ( ($s->stock_id == $stock_id) ) {
	    return 0; 
	    #trying to update the uniquename 
	} elsif ( $s->stock_id != $stock_id ) {
	    return " Can't update an existing stock $stock_id uniquename:$uniquename.";
	    # if the new name we're trying to update/insert does not exist in the stock table.. 
	} elsif ($stock_id && !$s->stock_id) {
	    return 0; 
	}
    }
    return undef;
}

=head2 get_organism

 Usage: $self->get_organism
 Desc:  find the organism object of this stock
 Ret:   L<Bio::Chado::Schema::Organism::Organism> object
 Args:  none
 Side Effects: none 
 Example:

=cut

sub get_organism {
    my $self = shift;
    return $self->get_object_row()->organism;
}

=head2 get_type

 Usage: $self->get_type
 Desc:  find the cvterm type of this stock
 Ret:   L<Bio::Chado::Schema::Cv::Cvterm> object
 Args:   none 
 Side Effects: none 
 Example:

=cut

sub get_type {
    my $self = shift;

    if ($self->get_type_id) {
	return  $self->get_object_row()->type;
    }
    return undef;

}



sub get_object_row {
    my $self = shift;
    return $self->{object_row};
}

sub set_object_row {
  my $self = shift;
  $self->{object_row} = shift;
}

=head2 get_resultset

 Usage: $self->get_resultset(ModuleName::TableName)
 Desc:  Get a ResultSet object for source_name
 Ret:   a ResultSet object
 Args:  a source name
 Side Effects: none
 Example:

=cut

sub get_resultset {
    my $self=shift;
    my $source = shift;
    return $self->get_schema()->resultset("$source");
}

=head2 accessors get_schema, set_schema

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_schema {
  my $self = shift;
  return $self->{schema}; 
}

sub set_schema {
  my $self = shift;
  $self->{schema} = shift;
}


###mapping accessors to DBIC 

=head2 accessors get_name, set_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_name {
    my $self = shift;
    return $self->get_object_row()->get_column("name"); 
}

sub set_name {
    my $self = shift;
    $self->get_object_row()->set_column(name => shift);
}

=head2 accessors get_uniquename, set_uniquename

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_uniquename {
    my $self = shift;
    return $self->get_object_row()->get_column("uniquename"); 
}

sub set_uniquename {
    my $self = shift;
    $self->get_object_row()->set_column(uniquename => shift);
}

=head2 accessors get_organism_id, set_organism_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_organism_id {
    my $self = shift;
    return $self->get_object_row()->get_column("organism_id"); 
}

sub set_organism_id {
    my $self = shift;
    $self->get_object_row()->set_column(organism_id => shift);
}

=head2 accessors get_type_id, set_type_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_type_id {
    my $self = shift;
    return $self->get_object_row()->get_column("type_id"); 
}

sub set_type_id {
    my $self = shift;
    $self->get_object_row()->set_column(type_id => shift);
}

=head2 accessors get_description, set_description

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_description {
    my $self = shift;
    return $self->get_object_row()->get_column("description"); 
}

sub set_description {
    my $self = shift;
    $self->get_object_row()->set_column(description => shift);
}

=head2 accessors get_stock_id, set_stock_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_stock_id {
    my $self = shift;
    return $self->get_object_row()->get_column("stock_id"); 
}

sub set_stock_id {
    my $self = shift;
    $self->get_object_row()->set_column(stock_id => shift);
}

=head2 accessors get_is_obsolete, set_is_obsolete

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_is_obsolete {
    my $self = shift;
    my $stock = $self->get_object_row();
    return $stock->get_column("is_obsolete") if $stock;
}

sub set_is_obsolete {
    my $self = shift;
    $self->get_object_row()->set_column(is_obsolete => shift);
}



##########
1;########
##########
