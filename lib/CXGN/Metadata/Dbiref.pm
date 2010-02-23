
package CXGN::Metadata::Dbiref;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Dbipath;
use CXGN::Metadata::Metadbdata;
use Carp qw(croak cluck);


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Metadata::Dbiref 
a class to manipulate a internal database reference (Dbiref).

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

   use CXGN::Metadata::Dbiref;
   use CXGN::Metadata::Metadbdata;

 ## Create an dbiref object based in dbiref_id

   my $dbiref = CXGN::Metadata::Dbiref->new($schema, $dbiref_id);

 ## Get dbiref data

   my $accession = $dbiref->get_accession();
   my @dbipath = $dbiref->get_dbipath_obj()
                        ->get_dbipath();


 ## Create an empty object

   my $dbiref_new = CXGN::Metadata::Dbiref->new($schema);

 ## Set dbiref data

   $dbiref_new->set_accession($accession);
   $dbiref_new->set_dbipath_id_by_dbipath_elements(\@dbipath);

 ## Store the data into the database

   my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $username);

   $dbiref_new->store($metadbdata);

 ## Is obsolete? If it isn't do it

    unless ($dbiref_new->is_obsolete) {
        $dbiref_new->obsolete($metadbdata);
    }

=head1 DESCRIPTION

 A database internal reference is a combination of two data (and internal 
 accession and a database path) that let access to any data inside the database.

 It will be used in cases where a reference can be VARIABLE, for example members
 in metadata.md_groups table or matches in the expresion.em_template table 
 (where it can be a clone, est or unigene).

  The object structure is:
  + An schema object (CXGN::Metadata::Schema) store using the base module 
    (CXGN::DB::Object).
  + A row object CXGN::Metadata::Schema::MdDbiref row


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



###########################
### GENERAL CONSTRUCTOR ###
###########################


=head2 constructor new

  Usage: my $metadata = CXGN::Metadata::Dbiref->new($schema, $dbiref_id);
 
  Desc: Create a new Dbiref object
 
  Ret: a CXGN::Metadata::Dbiref object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $dbiref_id, if $dbiref_id is omitted, an empty metadata object is 
        created.
 
  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.
 
  Example: my $dbiref = CXGN::Metadata::Dbiref->new($schema, $dbiref_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into de object 
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);                                   

    ### Second, check that ID is an integer. If it is right go and get all the data.
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $dbiref;
    if (defined $id) {

	unless ($id =~ m/^\d+$/) {  

            ## The id can be only an integer... so it is better if we detect this fail before.
	    my $error_message = "\nDATA TYPE ERROR: The dbiref_id ($id) for CXGN::Metadata::Dbiref->new() IS NOT AN INTEGER.\n\n";
	    croak($error_message);
	}
	$dbiref = $schema->resultset('MdDbiref')
	                 ->find( 
                                 { 
                                   dbiref_id => $id 
                                 }
                                );

	unless (defined $dbiref) {    
            
            ## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object

	    my $error_message2 = "\nDATABASE COHERENCE ERROR: The dbref_id ($id) for CXGN::Metadata::Dbiref->new(\$schema,\$id)";
            $error_message2 .= " DON'T EXISTS INTO THE DATABASE.\nIt will be created an empty Dbiref object.\n";
	    cluck($error_message2);

	    $dbiref = $schema->resultset('MdDbiref')
		             ->new({});
	}
    }
 
    else {
	$dbiref = $schema->resultset('MdDbiref')
                         ->new({});                  ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_mddbiref_row($dbiref);
    return $self;
}

=head2 constructor new_by_accession

  Usage: my $metadata = CXGN::Metadata::Dbiref->new_by_accession($schema, 
                                                                 $iref_accession, 
                                                                 [$schema, $table, $column]);
  Desc: Create a new Dbiref object

  Ret: a CXGN::Metadata::Dbiref object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        $iref_accession, an dbiref accession
        $schema, $table, $column, in an array reference (db path) 

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $dbiref = CXGN::Metadata::Dbiref->new_by_accession($schema, 
                                                                 $specie, 
                                                                 ['chado', 'organism', 'specie']);

=cut

sub new_by_accession {
    my $class = shift;
    my $schema = shift;
    my $accession = shift;
    my $path_aref = shift;

    ### First, bless the class to create the object and set the schema into de object 
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);                                   


    ## Declare the variable

    my $dbiref_row;

    ### SECOND, check the dbipath.

    if (ref($path_aref) eq 'ARRAY') {
        my @path = @{$path_aref};
        my $schema_name = $path[0] 
	    || croak("INPUT ERROR: None schema was supplied to CXGN::Metadata::Dbiref->new_by_accession.\n");
        my $table_name = $path[1] 
	    || croak("INPUT ERROR: None table was supplied to CXGN::Metadata::Dbiref->new_by_acccession.\n");
        my $column_name = $path[2] 
	    || croak("INPUT ERROR: None column was supplied to CXGN::Metadata::Dbiref->new_by_accession.\n");
	

	## Get the dbipath

	my $dbipath = CXGN::Metadata::Dbipath->new_by_path($schema, $path_aref);
	my $dbipath_id = $dbipath->get_dbipath_id();
	
	if (defined $dbipath_id) {
	
	    ## Get the dbiref_row based in accession + path, if it don't find anything it will return warnings based if exists
	    ## the dbipath_id in the md_dbipath table

	    $dbiref_row = $schema->resultset('MdDbiref')
		                 ->find( { 
				            iref_accession => $accession,
				            dbipath_id     => $dbipath_id 
				          } 
                                        );
	
	    unless (defined $dbiref_row) {    
            
		## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object

		cluck("INPUT WARNING: accession for dbiref do not exists into DB.\n\tIt'll be created a dbiref obj. without dbiref_id\n");
		$dbiref_row = $schema->resultset('MdDbiref')->new({});
		$dbiref_row->set_column( iref_accession => $accession );
		$dbiref_row->set_column( dbipath_id     => $dbipath_id );
	    }
	}
	else {

	    ## If don't exists a dbipath_id it will return a warning message and it will create a object with the accession

	    my $p = join('.', @path);
	    cluck("INPUT WARNING: dbipath ($p) don't exists into DB. It'll be created a dbiref obj. without dbiref_id and dbipath_id.\n");
	    $dbiref_row = $schema->resultset('MdDbiref')->new({});
	    $dbiref_row->set_column( iref_accession => $accession);
	}
        
    } 
    else {
        die("INPUT METHOD ERROR (CXGN::Metadata::Dbiref->new_by_accession): The dbipath ($path_aref) is not an array reference.\n");
    }
   
    ## Finally it will load the dbiref_row and dbipath_row into the object.

    $self->set_mddbiref_row($dbiref_row);
    return $self;
}



##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_mddbiref_row, set_mddbiref_row

  Usage: my $dbiref_row_object = $self->get_mddbiref_row();
         $self->set_mddbiref_row($dbiref_row_object);

  Desc: Get or set a a dbiref row object into a dbiref object

  Ret:   Get => $dbiref_row_object, a row object 
               (CXGN::Metadata::Schema::MdDbiref).
         Set => none

  Args:  Get => none
         Set => $dbiref_row_object, a row object 
               (CXGN::Metadata::Schema::MdDbiref).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my $dbiref_row_object = $self->get_mddbiref_row();
           $self->set_mddbiref_row($dbiref_row_object);

=cut

sub get_mddbiref_row {
  my $self = shift;
  return $self->{mddbiref_row}; 
}

sub set_mddbiref_row {
  my $self = shift;
  my $dbiref_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None dbiref_row object was supplied for set_mddbiref_row function.\n");
 
  if (ref($dbiref_row) ne 'CXGN::Metadata::Schema::MdDbiref') {
      my $error_message = "SET_MDDBIREF_ROW ARGUMENT ERROR: The dbipath_result_set_object:$dbiref_row ";
      $error_message .= "is not an dbiref_row object (package_name:CXGN::Metadata::Schema::MdDbiref).\n";
      croak($error_message);
  }
  $self->{mddbiref_row} = $dbiref_row;
}


######################
### DATA ACCESSORS ###
######################

=head2 get_dbiref_id, force_set_dbiref_id
  
  Usage: my $dbiref_id = $dbiref->get_dbiref_id();
         $dbiref->force_set_dbiref_id($dbiref_id);

  Desc: get or set a dbiref_id in a dbiref object. 
        set method should be USED WITH PRECAUTION
        If you want set a dbiref_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        dbiref_id that do not follow the metadata.md_dbiref_dbiref_id_seq

  Ret:  get=> $dbiref_id, a scalar.
        set=> none

  Args: get=> none
        set=> $dbiref_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $dbiref_id = $dbiref->get_dbiref_id(); 

=cut

sub get_dbiref_id {
  my $self = shift;
  return $self->get_mddbiref_row->get_column('dbiref_id');
}

sub force_set_dbiref_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The dbiref_id ($data) for CXGN::Metadata::MdDbiref->force_set_dbiref_id() IS NOT AN INTEGER.\n\n");
      }

      $self->get_mddbiref_row()
           ->set_column( dbiref_id => $data );

  } else {
      croak("FUNCTION PARAMETER ERROR: The dbiref_id was not supplied for force_set_dbiref_id function");
  }
}

=head2 accessors get_iref_accession, set_iref_accession

  Usage: my $iref_accession = $dbiref->get_iref_accession();
         $dbiref->set_iref_accession($iref_accession);

  Desc: Get the iref_accession for a dbiref object from the database. 

  Ret:  get=> $iref_accession, a scalar
        set=> none

  Args: get=> none
        set=> $iref_accession, a scalar

  Side_Effects: none

  Example: my $iref_accession = $dbiref->get_iref_accession();

=cut

sub get_iref_accession {
  my $self = shift;
  return $self->get_mddbiref_row->get_column('iref_accession'); 
}

sub set_iref_accession {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_iref_accession function");
  
  $self->get_mddbiref_row()
       ->set_column( iref_accession => $data );
}

=head2 accessors get_accession, set_accession

  Usage: my $iref_accession = $dbiref->get_accession();
         $dbiref->set_accession($iref_accession);
 
  Desc: Synonyms for get_iref_accession and set_iref_accession functions
        (see get_iref_accession and set_iref_accession methods)
 
  Ret:  get=> $iref_accession, a scalar
        set=> none
 
  Args: get=> none
        set=> $iref_accession, a scalar
 
  Side_Effects: none
 
  Example: my $iref_accession = $dbiref->get_accession();

=cut

sub get_accession {
  my $self = shift;
  return $self->get_mddbiref_row->get_column('iref_accession'); 
}

sub set_accession {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_accession function");
  
  $self->get_mddbiref_row()
       ->set_column( iref_accession => $data );
}

=head2 accessors get_dbipath_id, set_dbipath_id

  Usage: my $dbipath_id = $dbiref->get_dbipath_id();
         $dbiref->set_dbipath_id($dbipath_id);

  Desc: get or set the dbpath_id for a dbiref object from the database.

  Ret:  get=> $dbpath_id, a scalar
        set=> none

  Args: get=> none
        set=> $dbipath_id, a scalar (constraint: it must be an integer)

  Side_Effects: For set method, die if the dbipath_id do not exists into the db.

  Example: my $dbipath_id = $dbiref->get_dbipath_id();

=cut

sub get_dbipath_id {
  my $self = shift;
  return $self->get_mddbiref_row->get_column('dbipath_id'); 
}

sub set_dbipath_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The dbpath_id ($data) for CXGN::Metadata::Dbiref->set_dbipath_id IS NOT AN INTEGER.\n\n");
      }

      $self->get_mddbiref_row()
           ->set_column( dbipath_id => $data );
  } 
  else {
      croak("FUNCTION PARAMETER ERROR: The parameter dbpath_id was not supplied for CXGN::Metadata::Dbiref->set_dbipath_id function.\n");
  }
}

=head2 get_dbipath_obj

  Usage: my $dbipath = $dbiref->get_dbipath_obj();
  
  Desc: get a dbpath object associated to dbiref object.
  
  Ret:  $dbpath, an CXGN::Metadata::Dbpath object
  
  Args: none
  
  Side_Effects: none
  
  Example: my $dbipath = $dbipath->get_dbipath_obj();

=cut

sub get_dbipath_obj {
  my $self = shift;
  my $dbipath = CXGN::Metadata::Dbipath->new( $self->get_schema, 
					      $self->get_dbipath_id );
  return $dbipath; 
}

=head2 set_dbipath_id_by_dbipath_elements

  Usage: $dbiref->set_dbipath_by_dbipath_elements(\@elements);

  Desc: set a dbpath_id in the dbiref object using dbipath elements

  Ret:  none

  Args: \@elements, an array reference with three elements:
        $elements->[0] => schema_name
        $elements->[1] => table_name
        $elements->[2] => column_name

  Side_Effects: die if do not exists a dbipath row with the
                specified elements

  Example: my $dbipath = $dbipath->set_dbipath_id_by_dbipath_elements( 
                                                [ 'metadata', 
                                                  'md_dbipath', 
                                                  'dbpath_id'   ] );

=cut

sub set_dbipath_id_by_dbipath_elements {
    my $self = shift;
    my $e_aref = shift || 
	croak("INPUT ERROR: None element arrayref was supplied CXGN::Metadata::DBiref->set_dbipath_id_by_dbipath_elements function.\n");

    if (ref($e_aref) ne 'ARRAY') {
	croak("INPUT ERROR: $e_aref supplied CXGN::Metadata::DBiref->set_dbipath_id_by_dbipath_elements function is not an ARRAY REF.\n");
    }
    my $dbipath_id = CXGN::Metadata::Dbipath->new_by_path($self->get_schema, $e_aref)
                                           ->get_dbipath_id();
    
    $self->set_dbipath_id($dbipath_id);
}

#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_metadbdata

  Usage: my $metadbdata = $dbiref->get_metadbdata();
  
  Desc: Get metadata object associated to dbipath data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)
  
  Args: none
  
  Side_Effects: none
  
  Example: my $metadbdata = $dbiref->get_metadbdata();

=cut

sub get_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_mddbiref_row
                         ->get_column('metadata_id');

  if (defined $metadata_id) {

      $metadbdata = CXGN::Metadata::Metadbdata->new( $self->get_schema(), 
                                                     undef, 
                                                     $metadata_id );
      if (defined $metadata_obj_base) {

	  ## This will transfer the creation data from the base object to the new one
	  $metadbdata->set_object_creation_date( $metadata_obj_base->get_object_creation_date() );
	  $metadbdata->set_object_creation_user( $metadata_obj_base->get_object_creation_user() );
      }	  
  } 
  else {
      my $dbiref_id = $self->get_dbiref_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the dbiref=$dbiref_id is undefined.\n");
  }
  return $metadbdata;
}

=head2 is_obsolete

  Usage: $dbiref->is_obsolete();
  
  Desc: Get obsolete field form metadata object associated to dbiref data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($dbiref->is_obsolete()) { ## do something }

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

  Usage: my $dbiref = $dbiref->store($metadata);
  
  Desc: Store in the database the data of the metadata object.
  
  Ret: $dbiref, the dbiref object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
  
  Example: my $dbiref = $dbiref->store($metadata_id);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbiref->store().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata object supplied to CXGN::Metadata::Dbiref->store() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not dbipath_id. 
    ##   if exists dbiref_id         => update
    ##   if do not exists dbiref_id  => insert

    my $mddbiref_row = $self->get_mddbiref_row();
    my $dbiref_id = $mddbiref_row->get_column('dbiref_id');
    
    ## THIRD, check if exists the dbipath_id
    my $dbipath_id = $mddbiref_row->get_column('dbipath_id');
    
    unless (defined $dbipath_id) {
	croak("STORE ERROR: CXGN::Metadata::Dbiref object hasn't set dbipath_id. This is mandatory parameter to use store functions.\n");
    } 
    else {
	my $dbipath_row = $self->get_schema()
                               ->resultset('MdDbipath')
                               ->find({ dbipath_id => $dbipath_id });
 
	unless (defined $dbipath_row) {
	    my $error_msg2 = "DATA COHERENCE ERROR: The dbpath_id ($dbipath_id) do not exists into the database.\n";
	    $error_msg2 .= "It can not set dbipath_id using set_dbpath_id_dbiref function for a value that do not exists in the db.\n";
	    croak($error_msg2);
	}    
    }

    unless (defined $dbiref_id) {                                  ## NEW INSERT and DISCARD CHANGES
	my $new_metadata = $metadata->store();
	my $metadata_id = $new_metadata->get_metadata_id();
	
	## Set the metadata_id column. It will set the row with the updated row
        $mddbiref_row->set_column( metadata_id => $metadata_id );  
        $mddbiref_row->insert()
                     ->discard_changes();                
	                    
    } 
    else {                                                        ## UPDATE IF SOMETHING has change
	my @columns_changed = $mddbiref_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	    my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
 
	    my $modification_note = join ', ', @modification_note_list;
	    my $old_metadata = $self->get_metadbdata($metadata); 
	    my $mod_metadata_id = $old_metadata->store({ modification_note => $modification_note })
	                                       ->get_metadata_id();

	    $mddbiref_row->set_column( metadata_id => $mod_metadata_id );
	    $mddbiref_row->update()
                         ->discard_changes();
	}
    }
    return $self;    
}

=head2 obsolete

  Usage: my $dbiref = $dbiref->obsolete($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $dbiref, the dbiref object updated with the db data.
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
 
  Example: my $dbiref = $dbiref->store($metadata, 'change to obsolete test');

=cut

sub obsolete {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbiref->obsolete().\n");
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to CXGN::Metadata::Dbiref->obsolete is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to CXGN::Metadata::Dbiref->obsolete().\n");
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
    
    my $mddbiref_row = $self->get_mddbiref_row();

    $mddbiref_row->set_column( metadata_id => $mod_metadata_id );
    $mddbiref_row->update()
                 ->discard_changes();

    return $self;
}


###########
return 1;##
###########
