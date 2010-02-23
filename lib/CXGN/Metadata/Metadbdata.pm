
package CXGN::Metadata::Metadbdata;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use CXGN::Metadata::Schema;
use Carp;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Metadata::Metadbdata
a class to create and manipulate the database metadata.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 Use CXGN::Metadata::Metadbdata;

 my $db_row = DBIx::Class::AnySchema->resultset('ClassName')
                                    ->find({ col1 => 'anycondition'})

 ### 1-DATA_ACCESS: to the metadata associated to any data:
 
  ## Creating a metadbdata object with a metadata_id

    my $metadbdata = CXGN::Metadata::Metadbdata->new( $schema, 
                                                      $db_row->get_column('metadata_id') );
                                                                     
  
  ## Examples of data accessing

    my $metadata_id = $metadbdata->get_metadata_id();
    my $data_creation_date = $metadbdata->get_create_date();
    my $creation_user_id = $metadbdata->get_create_person_id(); 

  ## Or using a hash
    my %metadbdata = $medadbdata->get_metadata_by_rows();
    my $data_creation_date = $metadbdata{'create_date'};


 ### 2-DATA_INSERTS/UPDATES:

  ## Creation of empty metadbdata object with a username:
 
     my $medadbdata = CXGN::Metadata::Metadbdata($schema, $username);

  ## use this $metadbdata object to transfer creation_username and
  ## creation_date to the second level store functions. 

     my $primary_id = $db_row->get_column('primary_id');

  ## If exists or not primary key should decide to create or not
  ## a complete new md_metadata row or not

     ## INSERT NEW DATA 

     unless (defined $primary_id) {                                    
                                                                      
       my $new_metadata_id = $metadbdata->store()                    
                                        ->get_metadata_id();         
                                                                                                           
       $db_row ->set_column( metadata_id => $new_metadata_id )          
               ->insert()                                               
               ->discard_changes();                                                                                              
     } 

     ## UPDATE OLD DATA

     else {                                                             
                                 
        ## Check is exists changes in the object
                                                              
  	my @columns_changed = $db_row->is_changed();                    
                                                                      
  	if (scalar(@columns_changed) > 0) {                            
  	                                                               
            my @mod_list;                                             
  	    foreach my $col_changed (@columns_changed) {               
  		push @mod_list, "set value in $col_changed column";   
  	    }                                                          
  	    my $mod_note = join(', ', @mod_list);                     
              
            ## Create a new metadbdata object with the metadata_id from the db_row
  	
            my $mod_metadbdata = CXGN::Metadata::Metadbdata($schema, 
                                                            $username, 
                                                            $db_row->get_column('metadata_id'));

            ## Transfer the object creation date from the empty metadbdata object to this object

            $mod_metadata->set_object_creation_date( $metadbdata->get_object_creation_date() );
     
            ## Store the list of columns that have been changed as modification_note
                
            my $mod_metadata_id = $mod_metadbdata->store({ modification_note=> $mod_note }) 
                                                 ->get_metadata_id();            
                                                                                                       
            $db_row->set_column( metadata_id => $mod_metadata_id )      
                   ->update()                                           
                   ->discard_changes();                                 
   	}                                                             
   }                                                                  


=head1 DESCRIPTION

This class manages database metadata.

 A piece of metadata is data that describes other data, it describes
 things about certain data in the database, such as who, when, and why
 a certain piece of data was created or modified, or if it is obsolete
 and why (obsolete and obsolete_note). Also keeps history of previous
 metadata records, to provide an audit log for tracing the history to
 data changes.

For example:

 For the following data types:

 metadata_id          as c1
 create_id            as c2
 create_preson_id     as c3
 modified_date        as c4
 modified_person_id   as c5
 modification_note    as c6
 previous_metadata_id as c7

 +----+-------+----+-------+----+----------------+----+
 | c1 | c2    | c3 | c4    | c5 | c8             | c7 |
 +----+-------+----+-------+----+----------------+----+
 | 1  | day-1 | 1  |       |    |                |    | ## Action1
 | 2  | day-1 | 1  | day-2 | 1  | set_datatype_A | 1  | ## Action2
 | 3  | day-1 | 1  | day-3 | 1  | set_datatype_B | 1  | ## Action3
 | 4  | day-1 | 1  | day-3 | 1  | set_datatype_B | 2  | ## Action3
 +----+-------+----+-------+--- +----------------+----+

 ## Action1: Insert 100 new data with datatype_A and datatype_B. 
 ##          (They will have metadata_id=1)
 ## Action2: Update 20 data, setting the datatype_A. 
 ##          (They will have metadata_id=2)
 ## Action3: Update 40 rows, setting the datatype_B (10 of them are
 ##          the same that were updated in the action2).
 ## (30 of these data will have metadata_id=3 and the rest, metadata_id=4).

 In this example, to get the history for one of the 10 datasets that
 were updated twice, you will have:

 @metadata_history = @{metadata->trace_history($metadata_id)};
 @metadata_history = ($metadata_row4_aref, $metadata_row2_aref, $metadata_row1_aref);
 @metadata_row4 = (4, day-1, 1, day-3, 1, set_datatype_B, 2, 0, undef);
 @metadata_row2 = (2, day-1, 1, day-2, 1, set_datatype_A, 1, 0, undef);
 @metadata_row1 = (1, day-1, 1, undef, undef, undef, undef, 0, undef);

 The metadata_history array will be composed as many elements as
 metadata_id have this element. Each element will be a array reference
 of a array with nine elements. If there aren't some data for one
 field, it will appears as 'undef'.

=head1 What is a metadata object?

A metadata_object is an object that store two database objects using
L<DBIx::Class>:

=over

=item * A DBIx::Class::Schema object, 
 with object of the data conection as $dbh.

=item * A DBIx::Class::Row object, 
 with the data of the database or data for put into de database

=item * A scalar $object_creation_date, 
 get from the database in the moment of the creation of a new object and
 use as default values for create_date and modified_date.

=item * A scalar, $username. 
 The idea of metadata is that trace all the bulk changes in the database,
 so need store the username that do this changes. 
 It is stored as $object_creation_username and used in create_person_id or
 modified_person_id by default.

=back

 But a metadata object also is a second level object that manages the
 DBIx::Class object, that use constraints to prevent uncontrolled data
 inserts (for example, metadata_ids that don't exist without use
 integer generated by the metadata_metadata_id_seq) and that give other
 functions as trace_history.

=head1 How does store metadata function work?

 Store function for metadbdata always will use find_or_create over the metadata_row, 
 so when store function is used allways check if exists any md_metadata row with
 these data:

 +-------------+-------------+---------------+---------------------------------+
 | metadata_id | create_data | modified_data | response                        |
 +-------------+-------------+---------------+---------------------------------+
 | UNDEF       | UNDEF       | UNDEF         | Search in DB using object       |
 |             |             |               | creation_date and creation_user |
 |             |             |               | as create data row              |
 |             |             |               | + => set the metadbdata with    | 
 |             |             |               |      the returning row          |
 |             |             |               | - => create a new row with the  |
 |             |             |               |      object creation arguments  |
 |             |             |               |      for create data row        |
 +-------------+-------------+---------------+---------------------------------+
 | DEF         | DEF         | UNDEF         | Search in DB using object       |
 |             |             |               | creation_date and creation_user |
 |             |             |               | as modified data row            |
 |             |             |               | + => set the metadbdata with    | 
 |             |             |               |      the returning row          |
 |             |             |               | - => create a new row with the  |
 |             |             |               |      object creation arguments  |
 |             |             |               |      for modified data & using  |
 |             |             |               |      the previous create data   |
 |             |             |               |      previous metadata id will  |
 |             |             |               |      be the old metadata_id     |
 +-------------+-------------+---------------+---------------------------------+
 | DEF         | DEF         | DEF           | Same as above                   |
 +-------------+-------------+---------------+---------------------------------+



=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>

=head1 CLASS METHODS

The following class methods are implemented:

=head1 STANDARD METHODS

Standard methods are methods to get, set or store data

IMPORTANT NOTE!!!
All the SQL searches related with sgn_people should be replaced by the methods
  CXGN::People::Person->new()
  CXGN::People::Person->get_person_by_username()


=cut


=head2 constructor: new

  Usage: my $metadata = CXGN::Metadata::Metadbdata
                          ->new($schema, $username, $metadata_id);

  Desc: A constructor to create a new metadbdata object

  Ret: a CXGN::Metadata::Metadbdata object

  Args: CXGN::Metadata::Schema object,
        $username used in the create_person_id and/or modified_person_id,
        (optional) a metadata ID (if not passed, creates empty metadata obj)

  Side_Effects: accesses the database, check if exists the database
                columns that this object use. die if the id is not an
                integer.

  Example: my $metadata = CXGN::Metadata::Metadbdata->new($schema, 
                                                          $username, 
                                                          $metadata_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift 
	|| croak("INPUT ERROR: None schema object was supplied to the constructor CXGN::Metadata::Metadbdata->new().\n");
    my $username = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into de object.

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);
    $self->set_object_creation_date();

    if (defined $username) {
	$self->set_object_creation_user($username);
    }

    ### Second, check that ID is an integer. If it is right go and get
    ### all the data for this row in the database. If don't find
    ### anything, we have three options, create a new one with the
    ### metadata_id=$metadata_id, die or create a new one with an
    ### empty object. The solution will be the following:

    ###  (1) Create a new one with a metadata_id=$metadata_id is not a
    ###      good idea because when you store it, it will store this
    ###      metadata_id (if do not exists) without any consideration
    ###      with the metadata_metadata_id_seq. The alternative (if
    ###      you want to force it), is use set_metadata_id.
    ###  (2) Die - this is the default
    ###  (3) Create a new one with an empty object... if the user
    ###      don't know it, could be confuse.

    my $metadata;
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {

            ## The id can be only an integer... so it is better if we
            ## detect this fail before.

	    croak("\nDATA TYPE ERROR: The metadata_id ($id) for CXGN::Metadata::Metadbdata->new() IS NOT AN INTEGER.\n\n");
	}
	$metadata = $schema->resultset('MdMetadata')
                           ->find({ metadata_id => $id })
            or croak( <<EOM );

"DATABASE COHERENCE ERROR: 
  The metadata_id ($id) for CXGN::Metadata::Metadbdata->new(\$schema,\$id) DOES NOT EXIST.

  If you need force-add it, you can create an empty object:
    my $metadata = CXGN::Metadata::Metadbdata->new(\$schema);
  and set the metadata_id:
    $metadata->set_metadata_id(\$id);"

EOM

    } 
    else {
	$metadata = $schema->resultset('MdMetadata')
                           ->new({});                       ### Create an empty object; 
    }
    
    $self->set_mdmetadata_row($metadata);
    return $self;
}

=head2 accessors get_object_creation_date, set_object_creation_date

  Usage: my $creation_date = $self->get_object_creation_date();
         $self->set_object_creation_date();

  Desc: Get or set the creation date of the object. When the object is
        created, it run the query "SELECT now()" and store the
        data. It will be used in the metadata object for create_date
        and modified_date fields.

  Ret:  Get => A scalar with the date as timestamp with time zone.
        Set => none

  Args: Get => none
        Set => none

  Side_Effects: none

  Example: my $creation_date = $self->get_object_creation_date();

=cut

sub get_object_creation_date {
  my $self = shift;

  return $self->{object_creation_date};
}

sub set_object_creation_date {
  my $self = shift;
 
  my ($date) = $self->get_schema()
                    ->storage()
                    ->dbh()
                    ->selectrow_array("SELECT now()");

  $self->{object_creation_date} = $date;
}

=head2 accessors get_object_creation_user, set_object_creation_user

  Usage: my $creation_user = $self->get_object_creation_user();
        $self->set_object_creation_user();

  Desc: Get or set the creation user of the object. When the object is
        created, get the $user as argument. It can exists into the
        database or not, bu it can be used to create or modify
        different metadata objects. Before store something the
        metadata object will transfer the sp_person_id to the create
        or modified user by default (If they are not empty)

  Ret:  Get => A scalar with the user name.
        Set => none

  Args: Get => none
        Set => A scalar with the user name.

  Side_Effects: croak if the username is not into the database

  Example: my $creation_user = $self->get_object_creation_user();

=cut

sub get_object_creation_user {
  my $self = shift;

  return $self->{object_creation_user}; 
}

sub set_object_creation_user {
  my $self = shift;
  my $username = shift;

  my $query = "SELECT sp_person_id 
                FROM sgn_people.sp_person 
                 WHERE username = ?";

  my ($sp_person_id) = $self->get_schema()
                            ->storage()
                            ->dbh()
                            ->selectrow_array($query, undef, $username);

  if (defined $sp_person_id) {
      $self->{object_creation_user} = $username;
  } 
  
  else {
      croak("DATA INTEGRATION ERROR:The username ($username) used set_object_creation_user dont exists in sgn_people.sp_person table\n");
  }
}

=head2 accessors get_object_creation_user_by_id

  Usage: my $creation_user_id = $self->get_object_creation_user_by_id();

  Desc: Get the creation user id of the object.

  Ret:  A scalar with the user id (sp_person_id).

  Args: none

  Side_Effects: none

  Example: my $creation_user = $self->get_object_creation_user_by_id();

=cut

sub get_object_creation_user_by_id {
  my $self = shift;
  my $username = $self->{object_creation_user};

  my $sp_person_id;

  if (defined $username) {
      my $query = "SELECT sp_person_id 
                    FROM sgn_people.sp_person 
                     WHERE username=?";

      ($sp_person_id) = $self->get_schema()
                             ->storage()
                             ->dbh()
                             ->selectrow_array($query, undef, $username);
  }
  return $sp_person_id;
}

=head2 accessors get_mdmetadata_row, set_mdmetadata_row

  Usage: my $metadata_row_object = $self->get_mdmetadata_row();
         $self->set_mdmetadata_row($metadata_result_set_object);
  
  Desc: Get or set a a result set object into a metadata_object

  Ret:   Get => $metadata_row_object, a schema object (CXGN::Metadata::Schema::MdMetadata).
         Set => none

  Args:  Get => none
         Set => $metadata_row_object, a schema object (CXGN::Metadata::Schema::MdMetadata).

  Side_Effects: With set check if the argument is a result set object. If fail, dies.

  Example: my $metadata_row_object = $self->get_mdmetadata_row();
           $self->set_mdmetadata_row($metadata_row_object);

=cut

sub get_mdmetadata_row {
  my $self = shift;

  return $self->{mdmetadata_row}; 
}

sub set_mdmetadata_row {
  my $self = shift;
  my $metadata_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None metadata_row object was supplied for set_mdmetadata_row function");

  if (ref($metadata_row) ne 'CXGN::Metadata::Schema::MdMetadata') {

      croak("ARGUMENT ERROR: The metadata_row: $metadata_row is not an metadata_row object (CXGN::Metadata::Schema::MdMetadata).\n");
  }

  $self->{mdmetadata_row} = $metadata_row;
}

=head2 get_metadata_id, set_metadata_id

  Usage: my $metadata_id=$metadata->get_metadata_id();
         $metadata->set_metadata_id($metadata_id);

  Desc: get or set a metadata_id in a metadata object. 
        If you want set a metadata_id that do not exists into the database you should consider that when you store this object
        you can store a metadata_id that do not follow the metadata_id

  Ret:  get=> $metadata_id, a scalar.
        set=> none

  Args: get=> none
        set=> $metadata_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $metadata_id=$metadata->get_metadata_id(); 

=cut

sub get_metadata_id {
  my $self=shift;

  return $self->get_mdmetadata_row
              ->get_column('metadata_id');
}

sub set_metadata_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The metadata_id ($data) for CXGN::Metadata::MdMetadata->set_metadata_id() IS NOT AN INTEGER.\n\n");
      }
      
      $self->get_mdmetadata_row()
           ->set_column( metadata_id => $data );
  
  } 
  
  else {
      croak("FUNCTION PARAMETER ERROR: The metadata_id was not supplied for set_metadata_id function");
  }
}

=head2 accessors get_create_date, set_create_date

  Usage: my $create_date=$metadata->get_create_date();
         $metadata->set_create_date($create_date);

  Desc: Get the create_date for a metadata object from the database.
        The create_date should not be set, because it is create by
        default with now() value into the database when is created a
        new metadata.

  Ret:  get=> $create_date, a scalar
        set=> none

  Args: get=> none
        set=> $create_date, a scalar

  Side_Effects: none

  Example: my $create_date=$metadata->get_create_date();

=cut

sub get_create_date {
  my $self = shift;

  return $self->get_mdmetadata_row->get_column('create_date');
}

sub set_create_date {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_create_date function");
  
  $self->get_mdmetadata_row()
       ->set_column( create_date => $data );
}


=head2 accessors get_create_person_id, set_create_person_id

  Usage: my $create_person_id=$metadata->get_create_person_id();
         $metadata->set_create_person_id($create_person_id);

  Desc: get or set the create_person_id for a metadata object from the database
  
  Ret:  get=> $create_person_id, a scalar
        set=> none
  
  Args: get=> none
        set=> $create_person_id, a scalar (constraint: it must be an integer)
  
  Side_Effects: none
  
  Example: my $create_person_id=$metadata->get_create_person_id();

=cut

sub get_create_person_id {
  my $self = shift;
  
  return $self->get_mdmetadata_row
              ->get_column('create_person_id'); 
}

sub set_create_person_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
    
	  croak("DATA TYPE ERROR: create_person_id ($data) for CXGN::Metadata::Metadbdata->set_create_person_id IS NOT AN INTEGER\n");
      }

      $self->get_mdmetadata_row()
           ->set_column(create_person_id => $data);

  } 
  
  else {
      croak("FUNCTION PARAMETER ERROR: The parameter sp_person_id was not supplied for set_create_person_id function");
  }
}


=head2 accessors get_create_person_id_by_username, set_create_person_id_by_username

  Usage: my $create_person_username=$metadata->get_create_person_id_by_username();
         $metadata->set_create_person_id_by_username($create_person_username);

  Desc: get or set the create_person_id for a metadata object from the database

  Ret:  get=> $create_person_username, a scalar
        set=> none

  Args: get=> none
        set=> $create_person_username, a scalar (constraint)

  Side_Effects: when set is used, check if exists the username, if
                fails, die with a error message.

  Example: my $create_person_username = $metadata->get_create_person_by_username();

=cut

sub get_create_person_id_by_username {
  my $self = shift;
  my $username;

  my $create_person_id = $self->get_mdmetadata_row()
                              ->get_column('create_person_id');

  my $metadata_id = $self->get_mdmetadata_row()
                         ->get_column('metadata_id');

  if (defined $create_person_id) {
      my $query = "SELECT username 
                    FROM sgn_people.sp_person 
                     WHERE sp_person_id=?";
      
      ($username)= $self->get_schema()
                        ->storage()
                        ->dbh()
                        ->selectrow_array($query, undef, $create_person_id);

      ## If the query doesn't return any user name there are some errors than should be reported:
       ##    1- If the create_person_id store in the object using set_create_person_id do not exists (data integration error).
        ##   2- If the create_person_id of the sed.metadata table (set in the object using fetch) do not exists (data coherence error)
         ##  3- If the create_person_id of the sed.metadata table do not exists and the create_person_id store in the table do not
          ##    exists in the sgn_people.sp_person table (data coherence error)

      unless (defined $username) {

	  my $error = "DATA INTEGRATION ERROR: create_person_id stored in this object don't exist in the table sgn_people.sp_person.\n";

	  if (defined $metadata_id) {

	      my ($sed_create_person_id) = $self->get_schema
                                                ->resultset('MdMetadata')
                                                ->find({ metadata_id => $metadata_id })
                                                ->get_column('create_person_id');

	      if (defined $sed_create_person_id) {
		  
		  if ($create_person_id != $sed_create_person_id) {
		      $error .= "The create_person_id=$create_person_id of the metadata object is not the same ";
		      $error .= "than the sed.metadata.create_person_id for the metadata_id=$metadata_id";
		      croak($error);
		  } 
		  
		  else {
		      $error .= "DATA COHERENCE ERROR: The sed.metadata.create_person_id for the metadata_id=$metadata_id ";
		      $error .= "do not exists in the sgn_people.sp_person table\n\n";
		      croak($error);
		  }
	      } 
	      
	      else {
		  croak("DATA COHERENCE ERROR:The create_person_id set in the object do not exists in the sed.metadata table\n");
	      }
	  } 
	  
	  else {
	      croak($error);
	  }
      }
  } 
  return $username;
}

sub set_create_person_id_by_username {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: The username was not supplied for set_create_person_id_by_username function");
  
  my $query = "SELECT sp_person_id 
                FROM sgn_people.sp_person 
                 WHERE username=?";
  
  my ($create_person_id) = $self->get_schema()
                                ->storage()
                                ->dbh()
                                ->selectrow_array($query, undef, $data);

  ## Only need be reported if the username that it is being set is not in the sgn_people.sp_person table

  if (defined $create_person_id) {
      
      $self->get_mdmetadata_row()
	   ->set_column( create_person_id => $create_person_id );
     
  } 
  
  else {
      croak("DATA INTEGRATION ERROR: The username=$data do not exists in the sgn_people.sp_person table.\n");
  }
}

=head2 accessors get_modified_date, set_modified_date

  Usage: my $modified_date=$metadata->get_modified_date();
         $metadata->set_modified_date($modified_date);
 
  Desc: get or set the modified_date for a metadata object from the database
 
  Ret:  get=> $modified_date, a scalar
        set=> none
 
   Args: get=> none
        set=> $modified_date, a scalar
  
  Side_Effects: none
  
  Example: my $modified_date=$metadata->get_modified_date();

=cut

sub get_modified_date {
  my $self = shift;
  
  return $self->get_mdmetadata_row()
              ->get_column('modified_date'); 
}

sub set_modified_date {
  my $self = shift;
  my $data = shift;
 
  $self->get_mdmetadata_row()
       ->set_column( modified_date => $data );
}


=head2 accessors get_modified_person_id, set_modified_person_id

  Usage: my $modified_person_id=$metadata->get_modified_person_id();
         $metadata->set_modified_person_id($modified_person_id);

  Desc: get or set the modified_person_id for a metadata object from the database

  Ret:  get=> $modified_person_id, a scalar
        set=> none

  Args: get=> none
        set=> $modified_person_id, a scalar (constraint, it must be an integer)

  Side_Effects: when set is used, check that the $modified_person_id is an integer, if fails, die with a error message.

  Example: my $modified_person_id=$metadata->get_modified_person_id();

=cut

sub get_modified_person_id {
  my $self = shift;

  return $self->get_mdmetadata_row()
              ->get_column('modified_person_id'); 
}

sub set_modified_person_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {

      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR:The modified_person_id ($data) CXGN::Metadata::Metadbdata->set_modified_person_id IS NOT AN INTEGER.\n");
      }

      $self->get_mdmetadata_row()
           ->set_column( modified_person_id => $data );
 
  } 
  
  else {
      croak("FUNCTION PARAMETER ERROR: The paramater modified_person_id was not supplied for set_modified_person_id function");
  }
}

=head2 accessors get_modified_person_id_by_username, set_modified_person_id_by_username

  Usage: my $modified_person_username=$metadata->get_modified_person_id_by_username();
         $metadata->set_modified_person_id_by_username($modified_person_username);
 
  Desc: get or set the modified_person_id for a metadata object from the database
 
  Ret:  get=> $modified_person_username, a scalar
        set=> none
 
  Args: get=> none
        set=> $modified_person_username, a scalar (constraint)
 
  Side_Effects: when set is used, check if exists the username, if fails, die with a error message.
 
  Example: my $modified_person_username=$metadata->get_modified_person_by_username();

=cut

sub get_modified_person_id_by_username {
  my $self = shift;
 
  my $username;
  my $modified_person_id = $self->get_mdmetadata_row()
                                ->get_column('modified_person_id'); 
 
  my $metadata_id = $self->get_mdmetadata_row()
                         ->get_column('metadata_id');
  
  if (defined $modified_person_id) {
      my $query = "SELECT username 
                    FROM sgn_people.sp_person 
                     WHERE sp_person_id=?";
      
      ($username)= $self->get_schema()
                        ->storage()
                        ->dbh()
                        ->selectrow_array( $query, undef, $modified_person_id );

      ## If the query don't return any username there are some errors than should be reported:
       ##    1- If the modified_person_id store in the object using set_create_person_id do not exists (data integration error).
        ##   2- If the modified_person_id of the sed.metadata table (set in the object using fetch) do not exists (data coherence error)
         ##  3- If the modified_person_id of the sed.metadata table do not exists and the create_person_id store in the table do not
          ##    exists in the sgn_people.sp_person table (data integration error)

      unless (defined $username) {

	  my $error_message = "DATA ERROR:The modified_person_id stored in this object do not exist in table sgn_people.sp_person.\n";

	  if (defined $metadata_id) {

	      my $sed_modified_person_id = $self->get_schema()
	                                        ->resultset('MdMetadata')
						->find({ metadata_id => $metadata_id })
	         				->get_column('modified_person_is');

              ## Error controls

	      if (defined $sed_modified_person_id) {
		  
		  if ($modified_person_id != $sed_modified_person_id) {

		      $error_message .= "The modified_person_id=$modified_person_id of the metadata object is not the same ";
		      $error_message .= "than the sed.metadata.modified_person_id for the metadata_id=$metadata_id";
		      croak($error_message);

		  }
 
		  else {

		      $error_message .= "DATA COHERENCE ERROR: The sed.metadata.modified_person_id for the metadata_id=$metadata_id ";
		      $error_message .= "do not exists in the sgn_people.sp_person table\n\n";
		      croak($error_message);

		  }
	      } 

	      else {

		  croak("DATA INTEGRATION ERROR:The modified_person_id set in the object do not exists in the sed.metadata table\n");

	      }
	  } 

	  else {

	      croak($error_message);

	  }
      }
  }

  return $username;
}

sub set_modified_person_id_by_username {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: The username was not supplied for set_modified_person_id_by_username function");
  
  my $query = "SELECT sp_person_id 
                FROM sgn_people.sp_person 
                 WHERE username=?";
  
  my ($modified_person_id) = $self->get_schema()
                                  ->storage()
                                  ->dbh()
                                  ->selectrow_array($query, undef, $data);

  ## Only need be reported if the username that it is being set is not in the sgn_people.sp_person table

  if (defined $modified_person_id) {

      $self->get_mdmetadata_row()
           ->set_column( modified_person_id => $modified_person_id);

  } 
  else {
      croak("DATA INTEGRATION ERROR: The username=$data do not exists in the sgn_people.sp_person table.\n");
  }
}

=head2 accessors get_modification_note, set_modification_note


  Usage: my $modification_note=$metadata->get_modification_note();
         $metadata->set_modification_note($modification_note);

  Desc: get or set the modification_note for a metadata object from the database

  Ret:  get=> $modification_note, a scalar
        set=> none

  Args: get=> none
        set=> $modification_note, a scalar.

  Side_Effects: none

  Example: my $modification_note=$metadata->get_modification_note();

=cut

sub get_modification_note {
  my $self = shift;

  return $self->get_mdmetadata_row()
              ->get_column('modification_note'); 
}

sub set_modification_note {
  my $self = shift;
  my $data = shift;

  $self->get_mdmetadata_row()
       ->set_column( modification_note => $data );
}

=head2 accessors get_previous_metadata_id, set_previous_metadata_id

  Usage: my $previous_metadata_id=$metadata->get_previous_metadata_id();
         $metadata->set_previous_metadata_id($previous_metadata_id);
 
 Desc: get or set the previous_metadata_id for a metadata object from the database

  Ret:  get=> $previous_metadata_id, a scalar
        set=> none

  Args: get=> none
        set=> $previous_metadata_id, a scalar (constraint, it must be an integer)

  Side_Effects: none

  Example: my $previous_metadata_id=$metadata->get_previous_metadata_id();

=cut

sub get_previous_metadata_id {
  my $self = shift;
 
 return $self->get_mdmetadata_row()
             ->get_column('previous_metadata_id'); 
}

sub set_previous_metadata_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {

      unless ($data =~ m/^\d+$/) {
	 croak("DATA ERROR: previous_metadata_id ($data) CXGN::Metadata::Metadbdata->set_previous_metadata_id ISN'T AN INTEGER.\n");
      }

      $self->get_mdmetadata_row()
           ->set_column( previous_metadata_id => $data );

  } 
  else {
      croak("FUNCTION PARAMETER ERROR: The paramater previous_metadata_id was not supplied for set_previous_metadata_id function");
  }
}

=head2 accessors get_obsolete, set_obsolete

  Usage: my $obsolete=$metadata->get_obsolete();
         $metadata->set_obsolete($obsolete);

  Desc: get or set obsolete for a metadata object from the database. Obsolete=0 means false and Obsolete=1 means true

  Ret:  get=> $obsolete, a scalar
        set=> none

  Args: get=> none
        set=> $obsolete, a scalar (constraint, it must be an integer with values 0 or 1)

  Side_Effects: none

  Example: my $obsolete=$metadata->get_obsolete();

=cut

sub get_obsolete {
  my $self = shift;

  return $self->get_mdmetadata_row()
              ->get_column('obsolete'); 
}

sub set_obsolete {
  my $self = shift;
  my $data = shift;

  if (defined $data) {
      if ($data != 0 && $data != 1) {
	  croak("DATA TYPE ERROR: obsolete ($data) for CXGN::Metadata::Metadbdata->set_obsolete() HAS DIFFERENT VALUE FROM 0 or 1.\n");
      }
      
      $self->get_mdmetadata_row()
           ->set_column( obsolete => $data );

  } 
  
  else {
      croak("FUNCTION PARAMETER ERROR: The paramater obsolete (1 or 0) was not supplied for set_obsolete function");
  }
}

=head2 accessors get_obsolete_note, set_obsolete_note

  Usage: my $obsolete_note=$metadata->get_obsolete_note();
         $metadata->set_obsolete_note($obsolete_note);

  Desc: get or set the obsolete_note for a metadata object from the database

  Ret:  get=> $obsolete_note, a scalar
        set=> none

  Args: get=> none
        set=> $obsolete_note, a scalar

  Side_Effects: none

  Example: my $obsolete_note=$metadata->get_obsolete_note();

=cut

sub get_obsolete_note {
  my $self = shift;

  return $self->get_mdmetadata_row()
              ->get_column('obsolete_note'); 
}

sub set_obsolete_note {
  my $self = shift;
  my $data = shift;

  $self->get_mdmetadata_row()
       ->set_column( obsolete_note => $data );
}

=head2 accessors get_permission_id, set_permission_id

  Usage: my $obsolete_note=$metadata->get_permission_id();
         $metadata->set_permission_id($permission_id);

  Desc: get or set the permission_id for a metadata object from the database

  Ret:  get=> $permission_id, a scalar
        set=> none

  Args: get=> none
        set=> $permission_id, a scalar

  Side_Effects: none

  Example: my $permission_id = $metadata->get_permission_id();

=cut

sub get_permission_id {
  my $self = shift;

  return $self->get_mdmetadata_row()
              ->get_column('permission_id'); 
}

sub set_permission_id {
  my $self = shift;
  my $data = shift;

  $self->get_mdmetadata_row()
       ->set_column( permission_id => $data );
}


=head2 accessors get_metadata_by_rows, set_metadata_by_rows

  Usage: my %metadata_complete_rows = $self->get_metadata_by_rows();
         $self->set_metadata_by_rows( { metadata_id = $metadata_id, 
					create_date = $create_date,
					create_person_id = $create_person_id,
					modified_date = $modified_date,
				        modified_person_id = $modified_person_id, 
				        modification_note = $modification_note, 
				        previous_metadata_id = $previous_metadata_id, 
				        obsolete = $obsolete, 
				        obsolete_note = $obsolete_note });

  Desc: Get or set all the metadata for a row.

  Ret:   Get => a hash with keys=column_name and values=field_value
         Set => none

  Args:  Get => none
         Set => a hash reference with keys=column_name and values=field_value

  Side_Effects: Check if all the parameters are right, if not croak

  Example: $self->set_metadata_by_rows( { modification_note => 'this is a test', obsolete => 1} );

=cut

sub get_metadata_by_rows {
  my $self = shift;

  return $self->get_mdmetadata_row
              ->get_columns(); 
}

sub set_metadata_by_rows {
  my $self = shift;
  my $href = shift;

  unless (ref $href eq 'HASH') {

      croak("FUNCTION PARAMETER ERROR: The paramater $href for set_metadata_complete_row function is not a hash reference.\n");

  } 
  else {

      my %hash = %{$href};

      my @columns = ( 'metadata_id', 
                      'create_date', 
                      'create_person_id', 
                      'modified_date', 
                      'modified_person_id', 
                      'modification_note', 
                      'previous_metadata_id', 
                      'obsolete', 
                      'obsolete_note', 
                      'permission_id');
      
      foreach my $key (keys %hash) {
	  my $match = 0;

	  foreach my $col (@columns) {

	      if ($key eq $col) {
		  $match = 1;
	      }

	  }

	  if ($match == 0) {

	      my $error = "FUNCTION PARAMETER ERROR: The parameter is a hash with a non valid key ($key). Only are permited the follow";
	      $error .= "keys:\n";
	      my $permited_keys = join ', ', @columns;
	      $error .= "$permited_keys\n";
	      croak($error);

	  }

      }

      $self->get_mdmetadata_row()
	   ->set_columns($href);
  }
}


=head2 trace_history

  Usage: my @history=$self->trace_history($metadata_id);

  Desc: get the history of a metadata and return an array with metadata objects

  Ret: An array of metadata objects order from the argument to the previous metadata object.

  Args: $metadata_id, trace from it to the oldest.

  Side_Effects: none

  Example: my @history=$self->trace_history($metadata_id);

=cut

sub trace_history {
    my $self = shift;
    my $metadata_id = shift 
	|| croak("FUNCTION PARAMETER ERROR: The paramater metadata_id was not supplied for trace_history function");
    
    my @history;

    while (defined $metadata_id) {
	my $metadata = ref($self)->new( $self->get_schema(), 
                                        $self->get_object_creation_user, 
                                        $metadata_id 
	                               );

	push @history, $metadata;

        my $previous_metadata_id = $metadata->get_mdmetadata_row()
                                            ->get_column('previous_metadata_id');

	if (defined $previous_metadata_id) {
	    $metadata_id = $previous_metadata_id;
	} 
	
	else {
	    undef $metadata_id;
	}
    }
    return @history;
}

=head2 store

  Usage: my $metadata = $metadata->store();

  Desc: Store in the database the data of the metadata object.
        See the methods modified_data_store and new_data_store for more details

  Ret: $metadata, a new metadata object.

  Args: none

  Side_Effects: modify the database

  Example: my $metadata = $metadata->store();

=cut

sub store {
    my $self = shift;
    my $modify_data_href = shift;

    ## Check the database user (only the postgres user have permission to insert/update data)

    my ($user)= $self->get_schema
	             ->storage()
                     ->dbh()
                     ->selectrow_array("SELECT current_user");

    if ($user ne 'postgres') {
	croak("USER ACCESS ERROR: Only postgres user can store data.\n");
    }


    my $metadata_row = $self->get_mdmetadata_row();
    my %all_metadata = $metadata_row->get_columns();
    my $metadata_id = $all_metadata{'metadata_id'};

    if (defined $metadata_id) {

        ## It can be a modified data
	$self->modified_data_store($modify_data_href);

    } 
    else {

	## Check if exists the rest of the data (without any metadata_id). If exists, it will replace the
        ## the mdmetadata_row object inside the CXGN::Metadata::Metadbdata object

	if (defined $all_metadata{'create_date'}) {

	    my $metadata_from_db = $self->get_schema()
		                        ->resultset('MdMetadata')
                                        ->find(\%all_metadata);

	    if (defined $metadata_from_db) {	    
		
		$self->set_mdmetadata_row($metadata_from_db);
	    }
	} 
	else {
	    
            ## It will create a new metadata id. It will not check the creation_user because it was checked during the
	    ## the creation of the object
	    $self->new_data_store();
	}
    }

    return $self;    
}

=head2 new_data_store

  Usage: my $new_metadata_object = $metadata->new_store();

  Desc: Check if exists a metadata_row into the database with all the parameters
         of the metadata object except metadata_id.
        If exists return this line as a new metadata_object with the metadata_id 
         of the metadata row from the database.
        If it do not exists, store a new metadata object using the function store.

  Ret: A new metadata object 

  Args: none

  Side_Effects: Store data in the database if the metadata row do not exists

  Example: my $new_metadata_object = $metadata->new_store();

=cut

sub new_data_store {
    my $self = shift;
    
    ## Get from the metadata object creation date and creation user
    my $creation_date = $self->get_object_creation_date();
    my $creation_user = $self->get_object_creation_user();

    my $statement = "SELECT sp_person_id FROM sgn_people.sp_person WHERE username=?";
    my $creation_user_id = $self->get_schema()
	                        ->storage()
				->dbh()
				->selectrow_array($statement, undef, ($creation_user));

    unless (defined $creation_user) {
	my $error = "STORE ERROR: None creation user was supplied to CXGN::Metadata::Metadbdata object.\n";
	$error .= " This parameter is a mandatory parameter for store functions\n";
	croak($error);
    }

    ## If you are creating a new object into the database you don't need check, if the 
    ## old object have some data inside the row. Simply, it will create a new
    ## row and set the old value.

    ## Find if exists or not a Metadata with this creation user + creation date
    ## If do not exists, it will create a new one

    my $new_metadata_row = $self->get_schema()
	                        ->resultset('MdMetadata')
				->find_or_new({ create_date      => $creation_date, 
				     		create_person_id => $creation_user_id });

    my $metadata_id = $new_metadata_row->get_column('metadata_id');
    if (defined $metadata_id) {                 
	                                                             ## Means that exists this metadata row
	$self->set_mdmetadata_row($new_metadata_row);                ## so, it will set the object with the result.
    } 
    else {

	$new_metadata_row->insert()->discard_changes();              ## Don't exists, so it will insert a new one
	$self->set_mdmetadata_row($new_metadata_row);
    }

    return $self;
}

=head2 modified_data_store

  Usage: my $new_metadata_object = $metadata->modified_data_store();

  Desc: Check if exists a metadata_row into the database with all the parameters
         of the metadata object except metadata_id.
        If exists return this line as a new metadata_object with the metadata_id 
         of the metadata row from the database.
        If it do not exists, store a new metadata object using the function store.

  Ret: A new metadata object 

  Args: die if don't exists metadata_id

  Side_Effects: Store data in the database if the metadata row do not exists

  Example: my $metadata_object = $metadata->modified_data_store();

=cut

sub modified_data_store {
    my $self = shift;
    my $modified_data_href = shift;
    
    my $metadata_row = $self->get_mdmetadata_row();
    if (defined $modified_data_href) {
	
        ## if modified data is defined... it will set them in the metadata_row object before get the data
	$metadata_row->set_columns( $modified_data_href );
    }

    ## Get from the metadata object creation date and creation user
    my $obj_creation_date = $self->get_object_creation_date();
    my $obj_creation_user = $self->get_object_creation_user();

    my $statement = "SELECT sp_person_id FROM sgn_people.sp_person WHERE username=?";
    my $obj_creation_user_id = $self->get_schema()
	                            ->storage()
				    ->dbh()
				    ->selectrow_array($statement, undef, ($obj_creation_user));

    unless (defined $obj_creation_user) {
	my $error = "STORE ERROR: None creation user was supplied to CXGN::Metadata::Metadbdata object.\n";
	$error .= " This parameter is a mandatory parameter for store functions\n";
	croak($error);
    }

    ## In this case the old metadata_id should be contained in this object
    
    my %data = $metadata_row->get_columns();

    unless (defined $data{'metadata_id'}) {

	croak("STORE ERROR: CXGN::Metadata::Metadbdata->modified_data_store() can't be used on metadbdata obj with metadata_id undef.\n");
    } 
    else {
	
	## Now it will check if exists changes in the metadata_row object
	my %col_changed;
	my @columns_changes = $metadata_row->is_changed();
      
	foreach my $col (@columns_changes) {
	    $col_changed{$col} = 1;
	}
	
	if (scalar(@columns_changes) > 0) {  ## Means that really the metadata row has changed
	    
	    ## There are some changes that should be done before check if exists or not this metadata
	    ## 1- modified_date = $obj_creation_date and modified_user_id = $obj_creation_user (if this colums has change)
	    ## 2- previous_metadata_id = $data{'metadata_id'} 
	    
	    my ($modified_date, $modified_person_id);
	
	    if (exists $col_changed{'modified_date'}) {
		$modified_date = $data{'modified_date'};
	    } else {
		$modified_date = $obj_creation_date;
	    }
	    if (exists $col_changed{'modified_user_id'}) {
		$modified_person_id = $data{'modified_user_id'};
	    } else {
		$modified_person_id = $obj_creation_user_id;
	    }
	    
	    
	    my $new_metadata_row = $self->get_schema()
		                        ->resultset('MdMetadata')
					->find_or_new({ create_date          => $data{'create_date'}, 
						      	create_person_id     => $data{'create_person_id'},
						        modified_date        => $modified_date,
						        modified_person_id   => $modified_person_id, 
						        modification_note    => $data{'modification_note'},
							previous_metadata_id => $data{'metadata_id'},
							obsolete             => $data{'obsolete'},
							obsolete_note        => $data{'obsolete_note'},
							permission_id        => $data{'permission_id'} 
						      });

	    my $metadata_id = $new_metadata_row->get_column('metadata_id');

	    if (defined $metadata_id) {                                      ## Means that exists this metadata row
		
		$self->set_mdmetadata_row($new_metadata_row);                ## so, it will set the object with the result.
	    } 
	    else {
		
		$new_metadata_row->insert()->discard_changes();              ## Don't exists, so it will insert a new one
		$self->set_mdmetadata_row($new_metadata_row);
	    }
	} 
    }	    
    return $self;
}


=head1 CHECK METHODS

  The check methods return true ($check = 1) if exists the variable that you are testing.

=cut


=head2 exists_database_columns

  Usage: my $check_columns_href = $self->exists_database_columns($mode);
  Desc: check is exists the column in the schema object
  Ret: A hash reference with keys=column_name and values=0 (false) or 1(true)
  Args: $mode, a scalar that can be 'die' or 'croack'
  Side_Effects: die (or croack) with a error message if do not exists the column (in mode die or croack)
  Example: my $check_columsn_href = $self->exists_database_columns();
           $self->check_database_columns('croack')

=cut

sub exists_database_columns {
    my $self = shift;
    my $mode = shift || "none";

    my %check_columns;
    my $die_mode = 0;
    if ($mode eq 'die' || $mode eq 'croak') {
	$die_mode = 1;
    }
	
    my @columns_to_check = ('sgn_people.sp_person.sp_person_id');                       ## Aditional columns to check of other tables
    my @database_columns_used = $self->get_schema()->source('MdMetadata')->columns();   ## Get all the column_names for the table metadata
    foreach my $column_name (@database_columns_used) {                                  ## Complete the name with schema.table
	my $complete_name = 'metadata.md_metadata.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    foreach my $column_name (@columns_to_check) {                        ## Check for all the columns of the array if exists or not
	my @data = split(/\./, $column_name);
	my $schema = $data[0];
	my $table = $data[1];
	my $column = $data[2];

	my $query = "SELECT count(a.attname) AS tot FROM pg_catalog.pg_stat_user_tables AS t, pg_catalog.pg_attribute a
                     WHERE t.relid = a.attrelid AND t.schemaname = ? AND t.relname = ? AND a.attname = ?";
	my $sth = $self->get_schema()->storage()->dbh()->prepare($query);
        $sth->execute($schema,$table,$column);
        my ($e) = $sth->fetchrow_array();
	$check_columns{$column_name} = $e;
        if ($e == 0 && $die_mode == 1) {                                                   ## If do not exists return 0.
            if ($mode eq 'die') {
		die("\nDATABASE TABLE ERROR: The column:$schema.$table.$column do not exists into the database.\n\n");
	    } elsif ($mode eq 'croack') {
		croack("\nDATABASE TABLE ERROR: The column:$schema.$table.$column do not exists into the database.\n\n");
	    }
        }
    }
    return \%check_columns;
}

=head2 exists_sp_person_id

  Usage: my $check = exists_person_id($person_id)
  Desc: Check if exists a person_id in the sgn_people.sp_person table
  Ret: $check, with 0 if it is true and 1 if is it false
  Args: $person_id, an integer
  Side_Effects: none
  Example: my $check = exists_person_id($person_id);

=cut

sub exists_sp_person_id {
    my $self = shift;
    my $person_id = shift || croak("FUNCTION PARAMETER ERROR: None sp_person_id was supplied for exists_sp_person_id function");
    my $check;
    unless ($person_id =~ m/^\d+$/) {
	$check = 0;
    } else {
	my $query = "SELECT sp_person_id FROM sgn_people.sp_person WHERE sp_person_id=?";
	my $sth = $self->get_schema()->storage()->dbh()->prepare($query);
	$sth->execute($person_id);
	my ($sp_person_id) = $sth->fetchrow_array();
	if (defined $sp_person_id) {
	    $check = 1;
	} else {
	    $check = 0;
	}
    }
    return $check;
}

=head2 exists_metadata

  Usage: my $check = $self->exists_metadata_id($metadata_id, $metadata_type);
  Desc: Check if exists (true) or not (false) a metadata_id into the database.
  Ret: $check, a scalar with $check=1 for true and $check=0 for false
  Args: $metadata_id, an integer and 
  Side_Effects: none
  Example: if ($self->exists_metadata_id($metadata_id, 'metadata_id') == 1) { }

=cut

sub exists_metadata {
    my $self = shift;
    my $metadata_id = shift;
    my $metadata_type = shift;
    my $check;
    unless ($metadata_id =~ m/^\d+$/) {
	$check = 0;
    } else {
	my $db_mdmetadata_row = $self->get_schema->resultset('MdMetadata')->search( {metadata_id => $metadata_id} )->single();
	unless (defined $db_mdmetadata_row) {
	    $check = 0;
	} else {
	    my $metadata_data = $db_mdmetadata_row->get_column($metadata_type => $metadata_id);
	    if (defined $metadata_data) {
		$check = 1;
	    } else {
		$check = 0;
	    }
	}
    }
    return $check;
}

=head1 FORCE METHODS

  Description: The metadata are data about other data in the
               database. When you add a new metadata always it is
               created a new metadata_id according with the
               metadata_metadata_seq_id and a create_date=now(). But
               perhaps, there are circunstances you need add a
               specific metadata_id or/and create_date. For this cases
               you can use the force_insert function.

  Example: There are old data that do not have any metadata and you want to
           add it. You know when these data were created (and it is not now),
           so you can do:

      my $new_metadata_id = CXGN::Metadata::Metadbdata
                              ->new
                              ->set_create_date($old_date)
                              ->force_insert
                              ->get_metadata_id;


  Description: Another posibility is that you need update a metadata
               record. In normal usage, updating a metadata means
               inserting a new metadata record with a
               previous_metadata_id=old_metadata_id,
               create_date=old_create_date, and
               create_person_id=old_create_person_id and the rest of
               the metadata that you put into the
               metadata_object. After that change the obsolete field
               in the old one to 1 and add obsolete_note, "added new
               metadata with metadata_id=$new_metadata_id". But
               perhaps, there are some circunstances where you need
               really update a metadata line. For this cases you can
               use the force_update function.

  Example: There are some data into the database with the wrong

           modification_note (It should be the function used to change
           the data but perhaps the function name changes). So, you
           should use:

           CXGN::Metadata::Metadbdata
               ->new($metadata_id)
               ->set_modification_note("set_platform_description")
               ->force_update;

=cut

=head2 force_insert

  Usage: my $new_metadata_object = $self->force_insert();
  Desc: This function force to store a new metadata object with all
        the parameters given by the metadata object, without the use
        of the store function constraints (you can not store an
        specific metadata_id or create_date). The database constraints
        are still in use.
  Ret: A new metada_object with the data stored.
  Args: None
  Side_Effects: Stores the data into the database without the store
                function
  Example: my $metadata_object = $self->force_insert();

=cut

sub force_insert {
    my $self = shift;
    my $create_date = $self->get_mdmetadata_row()->get_column('create_date');
    my $create_person_id = $self->get_mdmetadata_row('create_person_id');
    unless (defined $create_date) {
	croak("DATA INPUT ERROR: The create_date column CAN NOT BE NULL in the metadata_object using force_insert function.\n");
    }
    unless (defined $create_person_id) {
	croak("DATA INPUT ERROR: The create_person_id column CAN NOT BE NULL in the metadata_object using force_insert function.\n");
    }
    my $new_row = $self->get_mdmetadata_row()->insert();
    my $new_metadata_id = $new_row->get_column('metadata_id');
    my $new_metadata_object = ref($self)->new($self->get_schema, $self->get_object_creation_user, $new_metadata_id);
    return $new_metadata_object;
}

=head2 force_update

  Usage: my $new_metadata_object = $self->force_update();


  Desc: This function force to update an old metadata with all
        the parameters given in the metadata object or in a hash
        reference with keys=column_name and values=value to search in
        the database. This function do not use the store() function,
        so it is free of the store constraints (when you use the store
        function over a metadata_object with a metadata_id that exists
        into the database, create a new metadata row in the database
        with the previous_metadata_id = old_metadata_id), and update
        the data for a metadata_object for a concrete conditions given
        by the hash reference.


  Ret: A new metadata_object, or undef if there are no any row to
       update with these conditions
  Args: none or a hash reference with the update conditions

  Example:

    my $new_metadata_object = $self->force_update;
    my $new_metadata_object = $self->force_update({ obsolete => 1 });

=cut

sub force_update {
    my $self = shift;
    my $columns_href = shift;
    my $create_date = $self->get_mdmetadata_row()->get_column('create_date');
    my $create_person_id = $self->get_mdmetadata_row('create_person_id');
    unless (defined $create_date) {
	croak("DATA INPUT ERROR: The create_date column CAN NOT BE NULL in the metadata_object using force_insert function.\n");
    }
    unless (defined $create_person_id) {
	croak("DATA INPUT ERROR: The create_person_id column CAN NOT BE NULL in the metadata_object using force_insert function.\n");
    }
    my $row_updated = $self->get_mdmetadata_row()->update($columns_href);
    my $metadata_id = $row_updated->id();
    my $metadata_object;
    if (defined $metadata_id) {
	$metadata_object = ref($self)->new($self->get_schema, $self->get_object_creation_user, $metadata_id);
    }
    return $metadata_object;
}

####
1;##
####
