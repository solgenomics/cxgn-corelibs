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
use CXGN::Metadata::Schema;

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
    if (my $bcs_stock = $self->get_object_row) {
        return $bcs_stock->organism;
    }
    return undef;
}


=head2 get_species

 Usage: $self->get_species
 Desc:  find the species name of this stock , if one exists
 Ret:   string
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_species {
    my $self = shift;
    my $organism = $self->get_organism;
    if ($organism) {
        return $organism->species;
    }else { return undef; }
}

=head2 set_species

Usage: $self->set_species
 Desc:  set organism_id for the stock using organism.species name
 Ret:   nothing
 Args:  species name (case insensitive)
 Side Effects: sets the organism_id for the stock
 Example:

=cut

sub set_species {
    my $self = shift;
    my $species_name = shift; # this has to be EXACTLY as stored in the organism table
    my $organism = $self->get_schema->resultset('Organism::Organism')->search(
        { 'lower(species)' => { like =>  lc($species_name) } } )->single ; #should be 1 result
    if ($organism) {
        $self->get_object_row->set_column(organism_id => $organism->organism_id );
    }
    else {
        warn "NO organism found for species name $species_name!!\n";
    }
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

    if (my $bcs_stock = $self->get_object_row ) {
	return  $bcs_stock->type;
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
    if (my $bcs_stock =  $self->get_object_row ) {
        return $bcs_stock->get_column("organism_id");
    }
    return undef;
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
    if (my $bcs_stock = $self->get_object_row ) {
        return $bcs_stock->get_column("type_id");
    }
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
    if ( my $bcs_stock = $self->get_object_row ) {
        return $bcs_stock->get_column("stock_id");
    }
    return undef;
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

=head2 function get_image_ids

  Synopsis:     my @images = $self->get_image_ids()
  Arguments:    none
  Returns:      a list of image ids
  Side effects:	none
  Description:	a method for fetching all images associated with a stock

=cut

sub get_image_ids {
    my $self = shift;
    my $ids = $self->get_schema->storage->dbh->selectcol_arrayref
	( "SELECT image_id FROM phenome.stock_image WHERE stock_id=? ",
	  undef,
	  $self->get_stock_id
        );
    return @$ids;
}

=head2 associate_allele

 Usage: $self->associate_allele($allele_id, $sp_person_id)
 Desc:  store a stock-allele link in phenome.stock_allele
 Ret:   a database id
 Args:  allele_id, sp_person_id
 Side Effects:  store a metadata row
 Example:

=cut

sub associate_allele {
    my $self = shift;
    my $allele_id = shift;
    my $sp_person_id = shift;
    if (!$allele_id || !$sp_person_id) {
        warn "Need both allele_id and person_id for linking the stock with an allele!";
        return
    }
    my $metadata_id = $self->_new_metadata_id($sp_person_id);
    #check if the allele is already linked
    my $ids =  $self->get_schema->storage->dbh->selectcol_arrayref
        ( "SELECT stock_allele_id FROM phenome.stock_allele WHERE stock_id = ? AND allele_id = ?",
          undef,
          $self->get_stock_id,
          $allele_id
        );
    if ($ids) { warn "Allele $allele_id is already linked with stock " . $self->get_stock_id ; }
#store the allele_id - stock_id link
    my $q = "INSERT INTO phenome.stock_allele (stock_id, allele_id, metadata_id) VALUES (?,?,?) RETURNING stock_allele_id";
    my $sth  = $self->get_schema->storage->dbh->prepare($q);
    $sth->execute($self->get_stock_id, $allele_id, $metadata_id);
    my ($id) =  $sth->fetchrow_array;
    return $id;
}

=head2 associate_owner

 Usage: $self->associate_owner($owner_sp_person_id, $sp_person_id)
 Desc:  store a stock-owner link in phenome.stock_owner
 Ret:   a database id
 Args:  owner_id, sp_person_id
 Side Effects:  store a metadata row
 Example:

=cut

sub associate_owner {
    my $self = shift;
    my $owner_id = shift;
    my $sp_person_id = shift;
    if (!$owner_id || !$sp_person_id) {
        warn "Need both owner_id and person_id for linking the stock with an owner!";
        return
    }
    my $metadata_id = $self->_new_metadata_id($sp_person_id);
    #check if the owner is already linked
    my $ids =  $self->get_schema->storage->dbh->selectcol_arrayref
        ( "SELECT stock_owner_id FROM phenome.stock_owner WHERE stock_id = ? AND owner_id = ?",
          undef,
          $self->get_stock_id,
          $owner_id
        );
    if ($ids) { warn "Owner $owner_id is already linked with stock " . $self->get_stock_id ; }
#store the owner_id - stock_id link
    my $q = "INSERT INTO phenome.stock_owner (stock_id, owner_id, metadata_id) VALUES (?,?,?) RETURNING stock_owner_id";
    my $sth  = $self->get_schema->storage->dbh->prepare($q);
    $sth->execute($self->get_stock_id, $owner_id, $metadata_id);
    my ($id) =  $sth->fetchrow_array;
    return $id;
}

=head2 _new_metadata_id

Usage: my $md_id = $self->_new_metatada_id($sp_person_id)
Desc:  Store a new md_metadata row with a $sp_person_id
Ret:   a database id
Args:  sp_person_id

=cut

sub _new_metadata_id {
    my $self = shift;
    my $sp_person_id = shift;
    my $metadata_schema = CXGN::Metadata::Schema->connect(
        sub { $self->get_schema->storage->dbh },
        );
    my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema);
    $metadata->set_create_person_id($sp_person_id);
    my $metadata_id = $metadata->store()->get_metadata_id();
    return $metadata_id;
}
##########
1;########
##########
