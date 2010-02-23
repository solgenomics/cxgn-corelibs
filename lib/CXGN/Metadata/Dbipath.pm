
package CXGN::Metadata::Dbipath;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use Carp qw| croak cluck |;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Metadata::Dbipath
a class to manipulate a internal database path (Dbipath).

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

   use CXGN::Metadata::Dbipath;
   use CXGN::Metadata::Metadbdata; ## Used to store functions

 ## Create a new object

   my $dbipath = CXGN::Metadata::Dbipath->new($schema, $dbipath_id);

 ## Create a new object using path elements

   my $alt_dbipath = CXGN::Metadata::Dbipath->new

 ## Get the variables from the object
 
   my $dbipath_id = $dbipath->get_dbipath_id();
   my $column = $dbipath->get_column_name();
   my $table = $dbipath->get_table_name();
   my $schema = $dbipath->get_schema_name();

   my ($schema, $table, $column) = $dbipath->get_dbipath();

 ## Set the variables in the object

   $dbipath->get_column_name( $column );
   $dbipath->get_table_name( $table );
   $dbipath->get_schema_name( $schema );

   $dbipath->set_dbipath( $schema, $table, $column );
 
 ## Get the metadbdata using obsolete

   if ($dbipath->is_obsolete() ) {
      my $dbipath_metadbdata = $dbipath->get_metadbdata();
   }

 ## Store (Insert if it don't exists or update it)

   my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $user);
   $dbipath->store($metadbdata);

 ## Obsolete

   $dbipath->obsolete($metadbdata, $obsolete_note);


=head1 DESCRIPTION

 A database internal reference is a combination of two data (and internal 
 accession and a database path) that let access to any data inside the database.

 It will be used in cases where a reference can be VARIABLE, for example members
 in metadata.md_groups table or matches in the expresion.em_template table 
 (where it can be a clone, est or unigene).

  The object structure is:
  + An schema object (CXGN::Metadata::Schema) store using the base module 
    (CXGN::DB::Object).
  + A row object: CXGN::Metadata::Schema::MdDbpath row


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $dbipath = CXGN::Metadata::Dbipath->new($schema, $dbipath_id);

  Desc: Create a new Dbipath object

  Ret: a CXGN::Metadata::Dbipath object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $dbipath_id, if $dbipath_id is omitted, an empty dbpath object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $dbipath = CXGN::Metadata::Dbipath->new($schema, $dbipath_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into de object 
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);                                   

    ### Second, check that ID is an integer. If it is right go and get all the data for 
    ### this row in the database and after that get the data for dbipath. 
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $dbipath;
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  

            ## The id can be only an integer... so it is better if we detect this fail before.
	    my $error_message = "\nDATA TYPE ERROR: The dbipath_id ($id) for CXGN::Metadata::Dbipath->new() IS NOT AN INTEGER.\n\n";
	    croak($error_message);
	}
	$dbipath = $schema->resultset('MdDbipath')->find({ dbipath_id => $id });
	unless (defined $dbipath) {                
            ## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object
	    my $error_message2 = "\nDATABASE COHERENCE ERROR: The dbpath_id ($id) for CXGN::Metadata::Dbipath->new(\$schema,\$id)";
            $error_message2 .= " DON'T EXISTS INTO THE DATABASE.\n";
	    $error_message2 .= "It will be created an empty Dbipath object.\n";
	    cluck($error_message2);
	    $dbipath = $schema->resultset('MdDbipath')->new({});
	}
    } 
    else {
	$dbipath = $schema->resultset('MdDbipath')->new({});   ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_mddbipath_row($dbipath);
    return $self;
}

=head2 constructor new_by_path

  Usage: my $dbipath = CXGN::Metadata::Dbipath->new_by_path($schema, $dbipath_aref);
 
  Desc: Create a new Dbipath object using dbipath as input
 
  Ret: a CXGN::Metadata::Dbipath object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $dbipath_aref, an array reference with three elements schema, table and column
 
  Side_Effects: accesses the database,
                check if the dbipath is schema.table.column. If it is false die.
                Die if the schema.table.column do not exists into the database.
 
  Example: my $dbipath = CXGN::Metadata::Dbipath->new_by_path( $schema, 
                                                               ['schema', 
                                                                'table', 
                                                                'column']);

=cut

sub new_by_path {
    my $class = shift;
    my $schema = shift;
    my $path_aref = shift;

    ### FIRST, bless the class (also we can get the dbipath and create a new object using dbipath_id, but it 
    ### need get the dbipath_row anyway)

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);     

    my $dbipath_row;

    ### SECOND, check the dbipath.
    if (ref($path_aref) eq 'ARRAY') {
	my @path = @{$path_aref};
	
	my $schema_name = $path[0] 
	    || croak("INPUT ERROR: None schema was supplied to CXGN::Metadata::Dbipath->new_by_path.\n");
	
	my $table_name = $path[1] 
	    || croak("INPUT ERROR: None table was supplied to CXGN::Metadata::Dbipath->new_by_path.\n");
	
	my $column_name = $path[2] 
	    || croak("INPUT ERROR: None column was supplied to CXGN::Metadata::Dbipath->new_by_path.\n");

	## To check if exists or not any column without schema dependencies, it will use a sql query to pg_catalog

	my $dbh = $self->get_schema()
	               ->storage()
                       ->dbh();

	my $query = "SELECT count(a.attname) AS tot 
                      FROM pg_catalog.pg_stat_user_tables AS t, pg_catalog.pg_attribute a
                       WHERE t.relid = a.attrelid AND t.schemaname = ? AND t.relname = ? AND a.attname = ?";
        
        my ($e) = $dbh->selectrow_array($query, undef, ($schema_name, $table_name, $column_name));
	if ($e == 0) {
	    my $error1 = "INPUT METHOD ERROR (CXGN::Metadata::Dbipath->new_by_dbipath): The column:$schema_name.$table_name.$column_name";
	    $error1 .= " do not exists into the database.\n\n";
	    die($error1);
	} 
	else {

	    ## If it do not find any row with these parameters, it will create a new row object with that.
	    $dbipath_row = $schema->resultset('MdDbipath')->find_or_new( { schema_name => $schema_name, 
									   table_name  => $table_name, 
									   column_name => $column_name } );
	}
    } 
    else {
	die("INPUT METHOD ERROR (CXGN::Metadata::Dbipath->new_by_path): The dbipath ($path_aref) is not an array reference.\n");
    }
   
    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_mddbipath_row($dbipath_row);
    return $self;
}

##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_mddbipath_row, set_mddbipath_row

  Usage: my $dbipath_row_object = $self->get_mddbipath_row();
         $self->set_mddbipath_row($dbipath_row_object);

  Desc: Get or set a a dbipath row object into a dbiref object
 
  Ret:   Get => $dbipath_row_object, a row object 
                (CXGN::Metadata::Schema::MdDbipath).
         Set => none
 
  Args:  Get => none
         Set => $dbipath_row_object, a row object 
                (CXGN::Metadata::Schema::MdDbipath).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $dbipath_row_object = $self->get_mddbipath_row();
           $self->set_mddbipath_row($dbipath_row_object);

=cut

sub get_mddbipath_row {
  my $self = shift;
 
  return $self->{mddbipath_row}; 
}

sub set_mddbipath_row {
  my $self = shift;
  my $dbipath_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None dbipath_row object was supplied for set_mddbipath_row function.\n");
 
  if (ref($dbipath_row) ne 'CXGN::Metadata::Schema::MdDbipath') {
      croak("SET ARGUMENT ERROR: dbipath_result_set_object:$dbipath_row isn't a dbipath_row obj. (CXGN::Metadata::Schema::MdDbipath).\n");
  }
  $self->{mddbipath_row} = $dbipath_row;
}

######################
### DATA ACCESSORS ###
######################

=head2 get_dbipath_id, force_set_dbiref_id
  
  Usage: my $dbipath_id = $dbipath->get_dbipath_id();
         $dbipath->force_set_dbipath_id($dbipath_id);

  Desc: get or set a dbipath_id in a dbipath object. 
        set method should be USED WITH PRECAUTION
        If you want set a dbipath_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        dbipath_id that do not follow the metadata.md_dbipath_dbipath_id_seq

  Ret:  get=> $dbipath_id, a scalar.
        set=> none

  Args: get=> none
        set=> $dbipath_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $dbipath_id = $dbipath->get_dbipath_id(); 

=cut

sub get_dbipath_id {
  my $self = shift;
  return $self->get_mddbipath_row->get_column('dbipath_id');
}

sub force_set_dbipath_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The dbipath_id ($data) for CXGN::Metadata::MdDbipath->force_set_dbipath_id() IS NOT AN INTEGER.\n\n");
      }

      $self->get_mddbipath_row()
           ->set_column( dbipath_id => $data );

  } else {
      croak("FUNCTION PARAMETER ERROR: The dbipath_id was not supplied for force_set_dbipath_id function");
  }
}

=head2 accessors get_column_name, set_column_name

  Usage: my $column = $dbipath->get_column_name();
         $dbipath->set_column_name($column);

  Desc: Get or set the column_name from a dbipath. 

  Ret:  get=> $column, a scalar
        set=> none

  Args: get=> none
        set=> $column, a scalar

  Side_Effects: none

  Example: my $column = $dbipath->get_column_name();

=cut

sub get_column_name {
  my $self = shift;
  return $self->get_mddbipath_row->get_column('column_name'); 
}

sub set_column_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_column_name function to CXGN::Metadata::Dbipath.\n");

  $self->get_mddbipath_row()
       ->set_column( column_name => $data );
}

=head2 accessors get_table_name, set_table_name

  Usage: my $table = $dbipath->get_table_name();
         $dbipath->set_table_name($table);
 
  Desc: Get or set the table_name from a dbipath. 
 
  Ret:  get=> $table, a scalar
        set=> none
 
  Args: get=> none
        set=> $table, a scalar
 
  Side_Effects: none
 
  Example: my $table = $dbipath->get_table_name();

=cut

sub get_table_name {
  my $self = shift;
  return $self->get_mddbipath_row->get_column('table_name'); 
}

sub set_table_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_table_name function to CXGN::Metadata::Dbipath.\n");

  $self->get_mddbipath_row()
       ->set_column( table_name => $data );
}

=head2 accessors get_schema_name, set_schema_name

  Usage: my $schema = $dbipath->get_schema_name();
         $dbipath->set_schema_name($schema);

  Desc: Get or set the schema_name from a dbipath. 

  Ret:  get=> $schema, a scalar
        set=> none

  Args: get=> none
        set=> $schema, a scalar

  Side_Effects: none

  Example: my $schema = $dbipath->get_schema_name();

=cut

sub get_schema_name {
  my $self = shift;
  return $self->get_mddbipath_row->get_column('schema_name'); 
}

sub set_schema_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_column_name function to CXGN::Metadata::Dbipath.\n");

  $self->get_mddbipath_row()
       ->set_column( schema_name => $data );
}

=head2 accessors get_dbipath, set_dbipath

  Usage: my ($schema, $table, $column) = $dbipath->get_dbipath();
         $dbipath->set_dbipath($schema, $table, $column);
  
  Desc: Get or set the schema, table and column for the dbipath object
  
  Ret:  get=> An array where $array[0] = $schema, $array[1] = $table and 
              $array[2] = $column
        set=> none
  
  Args: get=> none
        set=> An array where $array[0] = $schema, $array[1] = $table and 
              $array[2] = $column
  
  Side_Effects: none
  
  Example: my @dbipath_elements = $dbipath->get_dbipath();

=cut

sub get_dbipath {
  my $self = shift;
  my %mddbipath_data = $self->get_mddbipath_row
                            ->get_columns();
  
 return ($mddbipath_data{'schema_name'}, $mddbipath_data{'table_name'}, $mddbipath_data{'column_name'});
}

sub set_dbipath {
  my $self = shift;
  my $schema = shift 
      || croak("FUNCTION PARAMETER ERROR: None schema_name data was supplied for set_column_name function to CXGN::Metadata::Dbipath.\n");
  my $table = shift 
      || croak("FUNCTION PARAMETER ERROR: None table_name data was supplied for set_column_name function to CXGN::Metadata::Dbipath.\n");
  my $column = shift 
      || croak("FUNCTION PARAMETER ERROR: None column_name data was supplied for set_column_name function to CXGN::Metadata::Dbipath.\n");
  
  my $dbipath_row = $self->get_mddbipath_row();
  $dbipath_row->set_column( schema_name => $schema );
  $dbipath_row->set_column( table_name => $table );
  $dbipath_row->set_column( column_name => $column );
  $self->set_mddbipath_row($dbipath_row);
}




#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_metadbdata

  Usage: my $metadbdata = $dbipath->get_metadbdata();

  Desc: Get metadata object associated to dbipath data (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: none

  Side_Effects: none

  Example: my $metadbdata = $dbipath->get_metadbdata();

=cut

sub get_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  my $metadbdata; 
  my $metadata_id = $self->get_mddbipath_row->get_column('metadata_id');

  if (defined $metadata_id) {
      $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
      if (defined $metadata_obj_base) {

	  ## This will transfer the creation data from the base object to the new one
	  $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	  $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
      }	  
  } 
  else {
      my $dbipath_id = $self->get_dbipath_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the dbipath=$dbipath_id is undefined.\n");
  }
  
  return $metadbdata;
}

=head2 is_obsolete

  Usage: $dbipath->is_obsolete();
  
  Desc: Get obsolete field form metadata object associated to dbipath data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($dbipath->is_obsolete()) { ## do something }

=cut

sub is_obsolete {
  my $self = shift;
  my $metadbdata = $self->get_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}

#######################
### STORING METHODS ###
#######################

=head2 store

  Usage: my $dbipath = $dbipath->store($metadata);
  
  Desc: Store in the database the data of the metadata object.
  
  Ret: $dbipath, the dbipath object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
  
  Example: my $dbipath = $dbipath->store($metadata_id);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbipath->store().\n");
   
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata object supplied to CXGN::Metadata::Dbipath->store() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not dbipath_id. 
    ##   if exists dbipath_id         => update
    ##   if do not exists dbipath_id  => insert

    my $mddbipath_row = $self->get_mddbipath_row();
    my $dbipath_id = $mddbipath_row->get_column('dbipath_id');

    unless (defined $dbipath_id) {                                  ## NEW INSERT and DISCARD CHANGES
	my $new_metadata = $metadata->store();
	my $metadata_id = $new_metadata->get_metadata_id();
	
	$mddbipath_row->set_column( metadata_id => $metadata_id );  ## Set the metadata_id column
        $mddbipath_row->insert()
	              ->discard_changes();                ## It will set the row with the updated row
	
	$self->set_mddbipath_row($mddbipath_row);                    
    } 
    else {                                                        ## UPDATE IF SOMETHING has change
	my @columns_changed = $mddbipath_row->is_changed();
	if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	    my @modification_note_list;                             ## the changes and the old metadata object for
	    
	    foreach my $col_changed (@columns_changed) {            ## this dbipath and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	    
	    my $modification_note = join ', ', @modification_note_list;
	    my $old_metadata = $self->get_metadbdata($metadata); 
	    my $mod_metadata = $old_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id();

	    $mddbipath_row->set_column( metadata_id => $mod_metadata_id );
	    $mddbipath_row->update()
		          ->discard_changes();
	    
	    $self->set_mddbipath_row($mddbipath_row);
	}
    }
    return $self;    
}

=head2 obsolete

  Usage: my $dbipath = $dbipath->obsolete($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
  
  Ret: $dbipath, the dbipath object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $dbipath = $dbipath->store($metadata, 'change to obsolete test');

=cut

sub obsolete {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbipath->obsolete().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to CXGN::Metadata::Dbipath->obsolete is not CXGN::Metadata::Metadbdata obj.\n");
    }
    
    my $obsolete_note = shift || croak("OBSOLETE ERROR: None obsolete note was supplied to CXGN::Metadata::Dbipath->obsolete().\n");
    
    my $revert_tag = shift;

    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag
   
    my $old_metadata = $self->get_metadbdata($metadata); 
    my $mod_metadata = $old_metadata->store({ modification_note => $modification_note,
					      obsolete          => $obsolete, 
					      obsolete_note     => $obsolete_note });

    my $mod_metadata_id = $mod_metadata->get_metadata_id();
    
    my $mddbipath_row = $self->get_mddbipath_row();
    $mddbipath_row->set_column( metadata_id => $mod_metadata_id );
    $mddbipath_row->update()
	          ->discard_changes();

    $self->set_mddbipath_row($mddbipath_row);

    return $self;
}



###########
return 1;##
###########
