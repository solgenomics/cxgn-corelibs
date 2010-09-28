=head1 NAME

CXGN::Chado::Stock - a second-level DBIC Bio::Chado::Schema::Stock::Stock object

Version:1.0

=head1 DESCRIPTION

Created to work with  CXGN::Page::Form::AjaxFormPage
for eliminating hte need to refactor the  AjaxFormPage and Editable  to work with DBIC objects.
Functions such as 'get_obsolete' , 'store' , and 'exists_in_database' are required , and do not 
use standard DBIC syntax. 

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
    my $self = $class->SUPER::new($schema);
    my $stock;
    if (defined $id) {
	$stock = $self->get_resultset('Stock::Stock')->find({ stock_id => $id });
    } else {
	$self->debug("Creating a new empty Stock object! " . $self->get_resultset('Stock::Stock'));
	$stock = $self->get_resultset('Stock::Stock')->new( {} );   ### Create an empty resultset object;
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
    my $id= $self->get_object_row->stock_id();
    my $schema=$self->get_schema();
    #no stock id . Check first if the name  exists in te database
    if (!$id) {
	my $exists= $self->exists_in_database();
	if (!$exists) {
	    
	    my $new_row = $self->get_object_row();
	    $new_row->insert();
	    
	    $id=$new_row->stock_id();
	    
	    $self->d(  "Inserted a new stock  " . $new_row->stock_id()  ." \n");
	}else {
	    ##$self->set_stock_id($exists);
	    my $existing_stock=$self->get_resultset('Stock::Stock')->find($exists);
	    #don't update here if stock already exist. User should call from the code exist_in_database
	    #and instantiate a new stock object with the database id
	    #updating here is not a good idea, since it might not be what the user intended to do
            #and it can mess up the database.

	    $self->debug("stock " . $id .   " exists in database!");

	}
    }else { # id exists
	$self->d( "Updating existing stock_id $id\n");
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
    my $uniquename = $self->get_row_object()->uniquename || '' ;
    my $s = $self->get_resultset('Stock::Stock')->search( 
	{
	    uniquename  => { 'ilike' => $uniquename },
	})->single(); #  ->single() for retrieving a single row (there sould be only one uniquename entry)
    if ($s) { return $s->stock_id(); }
    return undef;
}

=head2 get_obsolete

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_obsolete {
    my $self = shift;
    my $is_obsolete = $self->get_object_row()->is_obsolete();
    
    $self->{obsolete} = $is_obsolete;
    return $self->{obsolete};
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


##########
1;########
##########
