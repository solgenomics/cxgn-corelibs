
=head1 NAME

CXGN::Metadata::Dbversion
a class to manipulate data from the metadata.md_dbversion table.

Version: 0.1

=head1 SYNOPSIS

   use CXGN::Metadata::Dbversion;
   use CXGN::Metadata::Metadbdata;  ### To store functions


 ### CONSTRUCTORS ###
 
 ## To create a new object

   my $dbversion = CXGN::Metadata::Dbversion->new($schema, $dbversion);

 ## If none dbversion_id is specified, it will be created an empty object

   my $empty_dbversion = CXGN::Metadata::Dbversion->new($schema);

 ## To create an object from patch_name

   my $altdbversion = CXGN::Metadata::Dbversion->new_by_patch_name($schema,$name);


 ### ACCESSORS ###

 ## To get dbversion_id, patch_name or patch_description from the object

   my $dbversion_id = $dbversion->get_dbversion_id();
   my $patch_name = $dbversion->get_patch_name();
   my $patch_description = $dbversion->get_patch_description();

 ## To set patch_name or patch_description values

   $dbversion->set_patch_name($patch_name);
   $dbversion->set_patch_description($patch_description);


 ### METADBDATA ###

 ## To get a metadbdata object, to know the user that loaded the data into the db

   my $metadbdata_v = $dbversion->get_metadbdata();
   my $loader_user = $metadbdata_v->get_create_person_id_by_username();

 ## To know if is obsolete

   if ($dbversion->is_obsolete() ) {
      print "Obsolete db_patch, you don't need to execute.\n";
   }

 
 ### DB MODIFIERS FUNCTIONS ###

 ## To store ...

   $dbversion->store($metadbdata);

 ## To obsolete ...

   $dbversion->obsolete($metadbdata, 'obsolete for some reason');

 ## ... or revert the obsolete condition.

   $dbversion->obsolete($metadata, 'now is not obsolete for something', 'REVERT');


 ### CHECKING PREVIOUS VALUES IN THE DATABASE ###

   if ( $dbversion->exists_dbpatch($mypatch) ) {
    
      my %check_previous = $dbversion->check_previous_dbpatches();

      foreach my $check_patch (keys sort %check_previous) {
       
          if ($check_previous{$check_patch} == 0) {
    
             print "$check_patch patch_number has not been executed into the database\n";

          }

       }

   }


=head1 DESCRIPTION

 The database patches are pieces of code that change the database
 (from add new tables to update data).

 The metadata.md_dbversion is a table that store what patches have
 been runned over the database. The md_dbversion rows have a metadata_id
 that can be used to know how and when a database patch was executed.

=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 

use strict;
use warnings;

package CXGN::Metadata::Dbversion;

use base qw | CXGN::DB::Object |;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use Carp qw| croak cluck |;


############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $dbversion = CXGN::Metadata::Dbversion->new($schema, $dbversion_id);

  Desc: Create a new Dbversion object

  Ret: a CXGN::Metadata::Dbversion object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );

        a $dbversion_id, if $dbversion_id is omitted, an empty dbpath object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $dbversion = CXGN::Metadata::Dbversion->new($schema, $dbversion_id);

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

    my $dbversion;
    if (defined $id) {

	unless ($id =~ m/^\d+$/) {  

            ## The id can be only an integer... so it is better if we detect this fail before.
	 
	    croak("\nDATA TYPE ERROR: The dbipath_id ($id) for CXGN::Metadata::Dbiversion->new() IS NOT AN INTEGER.\n\n");
	}

	$dbversion = $schema->resultset('MdDbversion')
	                    ->find({ dbversion_id => $id });

	unless (defined $dbversion) {                
            ## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object
	   
	    cluck("\nDB COHERENCE ERROR: dbversion_id ($id) for $class->new() DON'T EXISTS INTO DB. A empty obj. will be created.\n");

	    $dbversion = $schema->resultset('MdDbversion')
		                ->new({});
	}
    } 
    else {
	$dbversion = $schema->resultset('MdDbversion')
	                    ->new({});                        ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.

    $self->set_mddbversion_row($dbversion);
    return $self;
}

=head2 constructor new_by_patch_name

  Usage: 
    my $dbversion = CXGN::Metadata::Dbipath->new_by_patch_name($schema, 
                                                               $patch_name);
 
  Desc: Create a new Dbversion object using dbpatch as input
 
  Ret: a CXGN::Metadata::Dbversion object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $patch_name, a patch name
 
  Side_Effects: accesses the database,
                check if the dbipath is schema.table.column. If it is false die.
                Die if the schema.table.column do not exists into the database.
 
  Example:
    my $dbversion = CXGN::Metadata::Dbipath->new_by_patch_name( $schema, 
                                                                $patch_name);

=cut

sub new_by_patch_name {
    my $class = shift;
    my $schema = shift;
    my $patch_name = shift;
    
    ## FIRST search a dbversion row with this dbversion name
    
    my $dbversion;  ### Declare the variable

    my $dbversion_row = $schema->resultset('MdDbversion')
	                       ->find({ patch_name => $patch_name });

    ## SECOND, create the object using the standard constructor
    
    if (defined $dbversion_row) {

	my $dbversion_id = $dbversion_row->get_column('dbversion_id');
	$dbversion = $class->new($schema, $dbversion_id);

    }
    else {          ### It will create an empty object and i will set the patch_name
    
	$dbversion = $class->new($schema);
	$dbversion->set_patch_name($patch_name);

    }
    return $dbversion;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_mddbversion_row, set_mddbversion_row

  Usage: my $dbversion_row_object = $self->get_mddbversion_row();
         $self->set_mddbversion_row($dbversion_row_object);

  Desc: Get or set a md_dbversion row object into a dbversion object
 
  Ret:   Get => $dbversion_row_object, a row object 
                (CXGN::Metadata::Schema::MdDbversion).
         Set => none
 
  Args:  Get => none
         Set => $dbversion_row_object, a row object 
                (CXGN::Metadata::Schema::MdDbversion).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $dbversion_row_object = $self->get_mddbversion_row();
           $self->set_mddbversion_row($dbversion_row_object);

=cut

sub get_mddbversion_row {
  my $self = shift;
 
  return $self->{mddbversion_row}; 
}

sub set_mddbversion_row {
  my $self = shift;
  my $dbversion_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None dbversion_row object was supplied for set_mddbversion_row function.\n");
 
  if (ref($dbversion_row) ne 'CXGN::Metadata::Schema::MdDbversion') {
      croak("SET ARGUMENT ERROR: dbversion_row:$dbversion_row isn't a dbversion_row obj. (CXGN::Metadata::Schema::MdDbversion).\n");
  }
  $self->{mddbversion_row} = $dbversion_row;
}


######################
### DATA ACCESSORS ###
######################

=head2 get_dbversion_id, force_set_dbversion_id
  
  Usage: my $dbversion_id = $dbipath->get_dbversion_id();
         $dbversion->force_set_dbversion_id($dbversion_id);

  Desc: get or set a dbversion_id in a dbversion object. 
        set method should be USED WITH PRECAUTION
        If you want set a dbipath_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        dbversion_id that do not follow the metadata.md_dbversion_dbversion_id_seq

  Ret:  get=> $dbversion_id, a scalar.
        set=> none

  Args: get=> none
        set=> $dbversion_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $dbversion_id = $dbversion->get_dbversion_id(); 

=cut

sub get_dbversion_id {
  my $self = shift;
  return $self->get_mddbversion_row->get_column('dbversion_id');
}

sub force_set_dbversion_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The dbversion_id ($data) for CXGN::Metadata::Dbversion->force_set_dbversion_id() ISN'T AN INTEGER.\n");
      }

      $self->get_mddbversion_row()
           ->set_column( dbversion_id => $data );

  } 
  else {
      croak("FUNCTION PARAMETER ERROR: The dbversion_id was not supplied for force_set_dbversion_id function");
  }
}

=head2 accessors get_patch_name, set_patch_name

  Usage: my $patch_name = $dbversion->get_patch_name();
         $dbversion->set_patch_name($column);

  Desc: Get or set the patch_name from a dbversion. 

  Ret:  get=> $patch_name, a scalar
        set=> none

  Args: get=> none
        set=> $patch_name, a scalar

  Side_Effects: none

  Example: my $patch_name = $dbversion->get_patch_name();

=cut

sub get_patch_name {
  my $self = shift;
  return $self->get_mddbversion_row->get_column('patch_name'); 
}

sub set_patch_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_patch_name function to CXGN::Metadata::Dbversion.\n");

  $self->get_mddbversion_row()
       ->set_column( patch_name => $data );
}

=head2 accessors get_patch_description, set_patch_description

  Usage: my $patch_description = $dbversion->get_patch_description();
         $dbversion->set_patch_description($description);
 
  Desc: Get or set the patch_description from a dbversion object. 
 
  Ret:  get=> $patch_description, a scalar
        set=> none
 
  Args: get=> none
        set=> $patch_description, a scalar
 
  Side_Effects: none
 
  Example: my $patch_description = $dbversion->get_patch_description();

=cut

sub get_patch_description {
  my $self = shift;
  return $self->get_mddbversion_row->get_column('patch_description'); 
}

sub set_patch_description {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_patch_description function to CXGN::Metadata::Dbversion.\n");

  $self->get_mddbversion_row()
       ->set_column( patch_description => $data );
}



#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_metadbdata

  Usage: my $metadbdata = $dbversion->get_metadbdata();

  Desc: Get metadata object associated to dbversion data (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: none

  Side_Effects: none

  Example: my $metadbdata = $dbversion->get_metadbdata();

=cut

sub get_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  my $metadbdata; 
  my $metadata_id = $self->get_mddbversion_row
                         ->get_column('metadata_id');
  

  if (defined $metadata_id) {
      $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
      if (defined $metadata_obj_base) {

	  ## This will transfer the creation data from the base object to the new one
	  $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	  $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
      }	  
  } 
  else {
      my $dbversion_id = $self->get_dbversion_id();
      if (defined $dbversion_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the dbversion=$dbversion_id is undefined.\n");
      }
      else {
	  croak("OBJECT VARIABLE ERROR: This object haven't any dbversion_id and metadata_id. Probably it haven't been stored in DB.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_obsolete

  Usage: $dbversion->is_obsolete();
  
  Desc: Get obsolete field form metadata object associated to dbipath data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($dbversion->is_obsolete()) { ## do something }

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

  Usage: my $dbversion = $dbversion->store($metadata);
  
  Desc: Store in the database the data of the metadata object.
  
  Ret: $dbversion, the dbversion object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
  
  Example: my $dbversion = $dbversion->store($metadata_id);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbversion->store().\n");
   
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata object supplied to CXGN::Metadata::Dbversion->store() isn't CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not dbversion_id. 
    ##   if exists dbversion_id         => update
    ##   if do not exists dbversion_id  => insert

    my $mddbversion_row = $self->get_mddbversion_row();
    my $dbversion_id = $mddbversion_row->get_column('dbversion_id');

    unless (defined $dbversion_id) {                                    ## NEW INSERT and DISCARD CHANGES
	my $new_metadata = $metadata->store();
	my $metadata_id = $new_metadata->get_metadata_id();
	
	$mddbversion_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        $mddbversion_row->insert()
	                ->discard_changes();                            ## It will set the row with the updated row
	
	$self->set_mddbversion_row($mddbversion_row);      
    } 
    else {                                                              ## UPDATE IF SOMETHING has change
	my @columns_changed = $mddbversion_row->is_changed(); 
	if (scalar(@columns_changed) > 0) {                             ## ...something has change, it will take
	    my @modification_note_list;                                 ## the changes and the old metadata object for
	    
	    foreach my $col_changed (@columns_changed) {                ## this dbipath and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	    
	    my $modification_note = join ', ', @modification_note_list;
	    my $old_metadata = $self->get_metadbdata($metadata); 
	    my $mod_metadata = $old_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id();

	    $mddbversion_row->set_column( metadata_id => $mod_metadata_id );
	    $mddbversion_row->update()
		            ->discard_changes();
	    
	    $self->set_mddbversion_row($mddbversion_row);
	}
    }

    return $self;    
}


=head2 obsolete

  Usage: my $dbversion = $dbversion->obsolete($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
  
  Ret: $dbversion, the dbversion object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $dbversion = $dbversion->store($metadata, 'change to obsolete test');

=cut

sub obsolete {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbversion->obsolete().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to CXGN::Metadata::Dbversion->obsolete isn't CXGN::Metadata::Metadbdata obj.\n");
    }
    
    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to CXGN::Metadata::Dbversion->obsolete().\n");
    
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
    
    my $mddbversion_row = $self->get_mddbversion_row();
    $mddbversion_row->set_column( metadata_id => $mod_metadata_id );
    $mddbversion_row->update()
	            ->discard_changes();

    $self->set_mddbversion_row($mddbversion_row);

    return $self;
}


########################
### SPECIAL  METHODS ###
########################

=head2 get_patch_number

  Usage: my $patch_number = $dbversion->get_patch_number($patch_name);
 
  Desc: Parse the patch_name contained in the object and return the 
        patch number without the normalization.

        For example: An object with patch_name 0034_my_patch will
                     return $patch_number = 34

  Ret: $patch_number, a scalar
  
  Args: $patch_name
  
  Side_Effects: If none patch name is specified, it will take the patch_name from
                the object
                give a warning if the patch_name haven't a patch_number format
  
  Example: my $patch_number = $dbversion->get_patch_number();

=cut

sub get_patch_number {
    my $self = shift;

    my $patch_name = shift || $self->get_patch_name();

    my $patch_number;

    if (defined $patch_name) {
	
	if ($patch_name =~ m/(\d+)_\w+/) {
	    $patch_number = $1;   
	    $patch_number =~ s/^0*//;
	}
	else {
	    cluck("WARNING: The patch_name=$patch_name haven't patch_number associated as (digit+underline+name) name.\n");
	}
    }

    return $patch_number;
}

=head2 exists_dbpatch

  Usage: $dbversion->exists_dbpatch($patch_name);
 
  Desc: Check if exists or not a dbpatch into the db.
        return a boolean 0 => false and 1 => true

  Ret: A scalar, a boolean 0 for false and 1 for true 
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($dbversion->exists_dbpatch) {
              print "Warning...";
           }

=cut

sub exists_dbpatch {
    my $self = shift;

    my $patch_name = shift || $self->get_patch_name();

    ## This method define the boolean as 0 and change the value to 1 if find some results

    my $boolean = 0;

    if (defined $patch_name) {

	my $dbversion_row = $self->get_schema()
	                         ->resultset('MdDbversion')
			         ->find( { patch_name => $patch_name });
	
	if (defined $dbversion_row) {
	    $boolean = 1;
	}
    }

    return $boolean;
}


=head2 check_previous_dbpatches

  Usage: my %check_previous = $dbversion->check_previous_dbpatches();
 
  Desc: Check if exists or not a previous dbpatches into the db.
        return hash with key =  patch_name and a boolean value 
        0 => false and 1 => true.
        It will take the patch name and i will find it all the dbpatches
        with a patch number bellow it


  Ret: A hash with key=patch_name and value=boolean (false/true) 
  
  Args: @listm, an array with patch name list
  
  Side_Effects: If none list is used as argument, it will check
                for all the dbpatches with a patch value below the
                current value for the patch_name in the object.
                If the object have not any patch_name it will take
                the last patch_name as default

  Example: my %check = $dbversion->check_previous_dbpatches();

=cut

sub check_previous_dbpatches {
    my $self = shift;
    my $patch_name = shift || $self->get_patch_name();  ## If don't exists argument it will
                                                        ## take the patch name from the object

    my %checkings;

    ## If the patch name still haven't any patch name, this will take the last one

    unless (defined $patch_name) {
	
	my $last_dbversion  = $self->get_schema()
	                           ->resultset('MdDbversion')
			           ->search( undef, 
				             { order_by => 'dbversion_id DESC' })
			           ->first();
	    
	if (defined $last_dbversion) {
	    $patch_name = $last_dbversion->get_column('patch_name');
	}
    }

    ## Now it take the patch_number

    my $patch_number = $self->get_patch_number($patch_name);

    ## The search will descrease the patch number by one searching this number
    ## as dbpatch name and adding as many zeros to take four digits

    while ($patch_number > 1) {
	$patch_number--;

	my $searchnumber = sprintf('%04s', $patch_number);
	my $searchnumber_f = "'" . $searchnumber . "_%'"; 

	## There are the possibility of find more than one patch_name with the same patch_number
	## This should return all of them (form example during the test, it will add 9998_patch_test, but
	## can exists another 9998_something
	
	my @previous_patches = $self->get_schema()
			            ->resultset('MdDbversion')
				    ->search( { patch_name => { like => $searchnumber . "_" . "%" } } );
		  
	if (scalar(@previous_patches) > 0) {
	    
	    foreach my $previous_patch (@previous_patches) {
		
		if (defined $previous_patch) {
		    $checkings{$previous_patch->get_column('patch_name')} = 1; ## True if exists
		}
	    } 
	}

	else {
		$checkings{$searchnumber} = 0; ## False if the search don't return anything
	}
    }
		
    return %checkings;
}

=head2 complete_checking

  Usage: my $dbversion = $dbversion->complete_checking(\%options);
 
  Desc: Use different check functions and print/die according the 
        results

  Ret: $dbversion object
  
  Args: A hash reference with the following keys:
        patch_name    => $patch_name
        patch_descr   => $patch_description
        prepatch      => A array ref with the list of the 
                         patches required for this script
                         (all with a patch number bellow the
                          current by default)
        force         => 1 (skip the die and force to execute
                            the patch)
  
  Side_Effects: set patch_name and patch_description in the dbversion
                object

  Example: $dbversion->complete_checking({ patch_name  => $patch_name,
                                           patch_descr => $patch_descr,
                                           force       => 1            }); 

=cut

sub complete_checking {
    my $self = shift;
    my $options_href = shift;

    my %opt;
    if (defined $options_href) {
	if (ref($options_href) eq 'HASH') {
	    %opt = %{$options_href};
	}
	else {
	    die("INPUT PARAMETER ERROR: The argument options used in complete_checking method is not a hash reference.\n");
	}
    }
    
    if ($opt{'patch_name'}) {
	$self->set_patch_name($opt{'patch_name'});
    }
    if ($opt{'patch_descr'}) {
	$self->set_patch_description($opt{'patch_descr'});
    }


    if ($self->exists_dbpatch($opt{'patch_name'})) {
    
	my $metadata = CXGN::Metadata::Dbversion->new_by_patch_name($self->get_schema, $opt{'patch_name'})
	                                        ->get_metadbdata();
					    
	my $creation_user = $metadata->get_create_person_id_by_username();
	my $creation_date = $metadata->get_create_date(); 

	my $ms1 = "DBPATCH EXECUTION ERROR: Sorry, this db_patch has been executed in the db:\n\t by $creation_user in $creation_date.\n";
	
	if (defined $opt{'force'} && $opt{'force'} == 1) {
	    print STDERR "$ms1\n";
	}
	else {
	    die($ms1);
	}
    } 
    else {
	## Check if the previous patches have been executed

	if (defined $opt{'prepatch'} && ref($opt{'prepatch'}) eq 'ARRAY') {
	    my @prev_patches = @{$opt{'prepatch'}};
	    
	    my @absent = ();

	    foreach my $prev (@prev_patches) {
		unless ($self->exists_dbpatch($prev) ) {
		     push @absent, $prev;
		}
	    }
	    my $c_absent = scalar(@absent);
	    if ( $c_absent > 0) {
		my $list = join(',', @absent);
		my $ms2 = "PREVIOUS DB_PATCH ERROR, THERE ARE $c_absent PATCHES ($list) that do not exists into the database.\n";

		if (defined $opt{'force'} && $opt{'force'} == 1) {
		    print STDERR "$ms2\n";
		}
		else {
		    die($ms2);
		}
	    }
	    
	}
	else {

	    my %check_previous = $self->check_previous_dbpatches();
	    my @absent_patches = ();

	    foreach my $prepatch (sort keys %check_previous) {
		
		if ($check_previous{$prepatch} == 0) {
		    
		    push @absent_patches, $prepatch;
		    
		}
	    }
       
	    if (scalar(@absent_patches) > 0) {
		my $missing_patches = join("\n\t- ", @absent_patches);
		my $ms3 = "PREVIOUS DB_PATCH by default ERROR: The previous patches\n\t- $missing_patches \nhave not been executed\n"; 
		
		if (defined $opt{'force'} && $opt{'force'} == 1) {
		    print STDERR "$ms3\n";
		}
		else {
		    die($ms3);
		}
	    }
	    
	}
    }
    return $self;
}




###########
return 1;##
###########
