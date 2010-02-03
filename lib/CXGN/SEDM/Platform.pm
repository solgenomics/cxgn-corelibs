
=head1 NAME

CXGN::SEDM::Platform - a class to create and manipulate the database platform.

Version:1.0

=head1 DESCRIPTION

 This class create and manipulate a database platform. 

 So what is a metadata object? 

   A metadata_object is an object that store two database objects using the DBIx::Class: 
     - a DBIx::Class::Schema object, with object of the data conection as $dbh
     - a DBIx::Class::Row object, with the data of the database or data for put into de database. 

 There are 6 CXGN::SEDM::Schema of these objects:
    - TechnologyTypes
    - Platform
    - PlatformDesigns
    - PlatformDbxref
    
 So the platform object are composed by SEVEN OBJECTS:
    - CXGN::SEDM::Schema object
    - CXGN::SEDM::Schema::Platform row object
    - CXGN::SEDM::Schema::TechnologyType row object
    - list of CXGN::SEDM::Schema::PlatformDesign row objects associated to CXGN::SEDM::Schema::Platform row object
    - a hash reference with keys=CXGN::SEDM::Schema::PlatformDesign row and values=organism 
      (it is used to store organism list associated with PlatformDesign objects independently of the other tables in the schema)
    - list of CXGN::SEDM::Schema::PlatformDbxref row objects associated to CXGN::SEDM::Schema::Platform row object

=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=head1 STANDARD METHODS

  Standard methods are methods to get, set or store data

=cut 

use strict;
use warnings;

package CXGN::SEDM::Platform;


use base qw| CXGN::DB::Object |;
use CXGN::SEDM::Schema;
use CXGN::Chado::Dbxref;
use Carp;



########################################################
#### FIRST: The CONSTRUCTOR for the NEW OBJECT. ########
########################################################

=head2 constructor new

  Usage: my $platform = CXGN::SEDM::Platform->new($schema, $platform_id);
  Desc:
  Ret: a CXGN::SEDM::Platform object
  Args: a $schema a schema object, preferentially created using:
        CXGN::SEDM::Schema->connect( sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, %other_parameters);
        a $platform_id, if $platform_id is omitted, an empty platform object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use. die if the id is not an integer.
  Example: my $platform = CXGN::SEDM::Metadata->new($schema, $platform_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift || croak("DATA ARGUMENT ERROR: Schema argument was not supplied to CXGN::SEDM::Platform->new() method\n");
    my $platform_id = shift;
    if ( defined($platform_id) ) {
	 unless ($platform_id =~ m/^\d+$/) {
	     my $error1 = "DATA ARGUMENT ERROR: The platform_id ($platform_id) IS NOT AN INTERGER for the method CXGN::SEDM::Platform";
	     $error1 .= "->new().\n";
	     croak($error1);
	}
    }
    
    ### First, bless the class to create the object and set the schema into de object.
    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);

    ### Second, check that ID is an integer. If it is right go and get all the data for this row in the database. If don't find
     ### anything, give an error.

    my ($platform_row, $technology_type_row);
    my (@platform_design_rows, @platform_dbxref_rows, @platform_spots_rows, @platform_spots_coordinates_rows);
    if (defined $platform_id) {	
	($platform_row) = $schema->resultset('Platforms')->search({ platform_id => $platform_id });
	unless (defined $platform_row) {
	    my $error2 = "DATABASE COHERENCE ERROR: The platform_id ($platform_id) for CXGN::SEDM::Platform->new(\$schema,\$id) ";
            $error2 .= "DON'T EXISTS INTO THE DATABASE.\n";
	    $error2 .= "If you need enforce it, you can create an empty object (my \$platform = CXGN::SEDM::Platform->new";
            $error2 .= "(\$schema);) and set the variable (\$platform->set_platform_id(\$id);)";
	    croak($error2);
	} else {
	    my $technology_type_id = $platform_row->get_column('technology_type_id');	    
	    ($technology_type_row) = $schema->resultset('TechnologyTypes')->search({ technology_type_id => $technology_type_id });
	    @platform_design_rows = $schema->resultset('PlatformsDesigns')->search({ platform_id => $platform_id });
	    
	}
    } else {
	$technology_type_row = $schema->resultset('TechnologyTypes')->new({});            ### If there is none argument_id it will 
	$platform_row = $schema->resultset('Platforms')->new({});                         ### create an empty object with empty rows
    }

    $self->set_platform_dbic_row($platform_row);
    $self->set_technology_type_dbic_row($technology_type_row);
    if (defined($platform_design_rows[0]) ) {
	$self->set_platform_design_dbic_rows(\@platform_design_rows);
	foreach my $platform_design_row (@platform_design_rows) {
	    my $organism_group_id = $platform_design_row->get_column('organism_group_id');
	    my @organism_name;
	    if (defined $organism_group_id) {
		my @group_linkage_rows = $schema->resultset('GroupLinkage')->find({ group_id => $organism_group_id });
		my @organism_name_list;
		foreach my $group_linkage_row (@group_linkage_rows) {
		    my $organism_id = $group_linkage_row->get_column('member_id');
		    my $query = "SELECT organism_name FROM sgn.organism WHERE organism_id=?";
		    my $sth = $schema->storage()->dbh()->prepare($query);
		    $sth->execute($organism_id);
		    my ($organism_name) = $sth->fetchrow_array();
		    push @organism_name, $organism_name;
		}
		$self->set_platform_design_organism_list($platform_design_row, \@organism_name);
	    }
	}
    }

### Methods to implement ##############################################################
#    if ( defined($platform_dbxref_rows[0]) ) {
#	$self->set_platform_dbxref_rows(\@platform_dbxref_rows);
#    }
#######################################################################################

    return $self;
}

=head2 create_new_with_technology_type_id

 Usage: my $platform = CXGN::SEDM::Platform->create_new_with_technology_type_id($schema, $technology_type_id)
 Desc: Create a new object with the CXGN::SEDM::Schema::TechnologyTypes object set.
       The CXGN::SEDM::Schema::Platform object will be empty
 Ret: A platform object (CXGN::SEDM::Platform object)
 Args: $schema, a schema object (DBIx::Class::Schema),
       $technology_type_id, an integer, technology_type_id data for the table sed.technology_type.
 Side Effects: die if there are not any $schema object or #technology_type_id, or if it is not into the database 
 Example:  my $platform = CXGN::SEDM::Platform->create_new_with_technology_type_id($schema, $technology_type_id)

=cut

sub create_new_with_technology_type_id {
    my $class = shift;
    my $schema = shift || 
       croak("DATA ARGUMENT ERROR: Schema was not supplied to CXGN::SEDM::Platform->create_new_with_technology_type_id() method\n");
    my $technology_type_id = shift;
    if ( defined($technology_type_id) ) {
	 unless ($technology_type_id =~ m/^\d+$/) {
	     my $error1 = "DATA ARGUMENT ERROR: The technology_type_id ($technology_type_id) IS NOT AN INTERGER used for the method";
	     $error1 .= "CXGN::SEDM::Platform->create_new_from_technology_type_id().\n";
	     croak($error1);
	}
    } else {
	my $error2 = "DATA ARGUMENT ERROR: technology_type argument was not supplied for the method ";
	$error2 .= "CXGN::SEDM::Platform->create_new_from_technology_type_id()\n";
	croak($error2);
    }
    my $platform = $class->new( $schema, undef );
    my ($technology_type_row) = $schema->resultset('TechnologyTypes')->search( { technology_type_id => $technology_type_id } );
    unless (defined $technology_type_row) {
	my $error3 = "DATA INPUT ERROR: The technology_type_id = $technology_type_id is not into the sed.technology_types.\n";
	$error3 .= "The $class->create_new_with_technology_type method can not create a new object with this technology_type_id.\n";
	croak($error3);
    } else {
	$platform->set_technology_type_dbic_row($technology_type_row);
    }
    return $platform;
}






########################################################
#### SECOND: General Accessor for SCHEMA.       ########
########################################################

## General Accessors for the platform object (schema, platform_row, technology_type_row, platform_design_rows, platform_dbxref_rows, 
 ## platform_spots_rows and platform_spot_coordinates_rows)

=head2 accessors get_schema, set_schema (deprecated)

  Usage: my $schema = $self->get_schema();
         $self->set_schema($schema);
  Desc: DEPRECATED: Now it is using as base CXGN::DB::Object with get_schema and set_schema and inherits methods
        Get or set a schema_object into a metadata_object
  Ret:   Get => $schema, a schema object (CXGN::SEDM::Schema).
         Set => none
  Args:  Get => none
         Set => $schema, a schema object (CXGN::SEDM::Schema).
  Side_Effects: With set check if the argument is a schema_object. If fail, dies
  Example: my $schema = $self->get_schema();
           $self->set_schema($schema);

=cut


## DEPRECATED FOR THE USE OF CXGN::DB::Object as base
#sub get_schema {
#  my $self = shift;
#  return $self->{schema}; 
#}

#sub set_schema {
#  my $self = shift;
#  my $schema = shift || croak("FUNCTION PARAMETER ERROR: None schema object was supplied for set_schema function");
#  my $schema_ref = ref $schema;
#  if ($schema_ref ne 'CXGN::SEDM::Schema') {
#      my $error_message = "SET_SCHEMA ARGUMENT ERROR: The schema_object:$schema ";
#      $error_message .= "is not an schema_object (package_name:CXGN::SEDM::Schema).\n";
#      croak($error_message);
#  }
#  $self->{schema} = $schema;
#}


##################################################################
#### THIRD: General accessor for Technology_Type_Row.     ########
####        Specific accessors for Technology_Type_Data:  ########
####                * technology_type_id                  ########
####                * technology_name                     ########
####                * technology_description              ########
####                * technology_metadata_id              ########
##################################################################


=head2 accessors get_technology_type_dbic_row, set_technology_type_dbic_row

  Usage: my $technology_type_row_object = $self->get_technology_type_dbic_row();
         $self->set_technology_type_dbic_row($technology_type_row_object);
  Desc: Get or set a row object into a platform_object
  Ret:   Get => $technology_type_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::TechnologyType).
         Set => none
  Args:  Get => none
         Set => $technology_type_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::TechnologyType).
  Side_Effects: With set check if the argument is a result set object. If fail, dies.
  Example: my $technology_type_row_object = $self->get_technology_type_dbic_row();
           $self->set_technology_type_dbic_row($technology_type_row_object);

=cut

sub get_technology_type_dbic_row {
  my $self = shift;
  return $self->{technology_type_row}; 
}

sub set_technology_type_dbic_row {
  my $self = shift;
  my $technology_type_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None technology_type_row object was supplied for set_technology_row function");
  
  if (ref($technology_type_row) ne 'CXGN::SEDM::Schema::TechnologyTypes') {
      my $error_message = "SET_TECHNOLOGY_TYPE_DBIC_ROW ARGUMENT ERROR: The technology_type_result_set_object:$technology_type_row ";
      $error_message .= "is not a technology_type_row object (package_name:CXGN::SEDM::Schema::TechnologyTypes).\n";
      croak($error_message);
  }
  $self->{technology_type_row} = $technology_type_row;
}

=head2 get_technology_type_id, set_technology_type_id
  
  Usage: my $technology_type_id=$platform->get_technology_type_id();
         $platform->set_technology_type_id($technology_type_id);
  Desc: get or set a technology_type_id in a platform object.
        set_technology_type_id function change at the same time technology_type_id for CXGN::SEDM::Schema::TechnologyType and 
        CXGN::SEDM::Schema::Platform, both are the same. To change the relation of a Platform with a TechnologyType simply you
        should, 
           1- Get technology_type: $technology_type_row = CXGN::SEDM::Platform->search({'TechnologyType' => {technology_name => $name}});
           2- Set the technology_type_row: $platform->set_technology_type_dbic_row($technology_type_row);
           3- Get the technology_type_id my $technology_type_id = $platform->get_technology_type_id();
           4- Set the technology_type_id for all the objects $platform->set_technology_type_id($technology_type_id)
  Ret:  get=> $technology_type_id, a scalar.
        set=> none
  Args: get=> none
        set=> $technology_type_id, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $technology_type_id=$platform->get_technology_type_id(); 

=cut

sub get_technology_type_id {
  my $self=shift;
  return $self->get_technology_type_dbic_row->get_column('technology_type_id');
}

sub set_technology_type_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The technology_id ($data) for CXGN::SEDM::Platform->set_technology_type_id() IS NOT AN INTEGER.\n\n");
      }
      my $technology_type_row = $self->get_technology_type_dbic_row();
      $technology_type_row->set_column( technology_type_id => $data );
      $self->set_technology_type_dbic_row($technology_type_row);
      my $platform_type_row = $self->get_platform_dbic_row();
      $platform_type_row->set_column( technology_type_id => $data );
      $self->set_platform_dbic_row($platform_type_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The technology_type_id was not supplied for set_technology_type_id function");
  }
}

=head2 accessors get_technology_type_name, set_technology_type_name

  Usage: my $technology_name = $platform->get_technology_type_name();
         $platform->set_technology_type_name($technology_name);
  Desc: Get the create_date for a platform object from the database. 
  Ret:  get=> $technology_name, a scalar
        set=> none
  Args: get=> none
        set=> $technology_name, a scalar
  Side_Effects: none
  Example: my $technology_name = $metadata->get_technology_type_name();

=cut

sub get_technology_type_name {
  my $self = shift;
  return $self->get_technology_type_dbic_row->get_column('technology_name'); 
}

sub set_technology_type_name {
  my $self = shift;
  my $data = shift || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_technology_type_name function");
  my $technology_type_row = $self->get_technology_type_dbic_row();
  $technology_type_row->set_column( technology_name => $data );
  $self->set_technology_type_dbic_row($technology_type_row);
}


=head2 accessors get_technology_type_description, set_technology_type_description

  Usage: my $technology_type_description = $platform->get_technology_type_description();
         $platform->set_technology_type_description($technology_type_description);
  Desc: get or set the technology_description for a technology_description object from the database
  Ret:  get=> $technology_type_description, a scalar
        set=> none
  Args: get=> none
        set=> $technology_type_description, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $technology_type_description=$platform->get_technology_type_description();

=cut

sub get_technology_type_description {
  my $self = shift;
  return $self->get_technology_type_dbic_row->get_column('description'); 
}

sub set_technology_type_description {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      my $technology_type_row = $self->get_technology_type_dbic_row();
      $technology_type_row->set_column(description => $data);
      $self->set_technology_type_dbic_row($technology_type_row);
  }
}

=head2 get_technology_type_metadata_id, set_technology_type_metadata_id
  
  Usage: my $technology_type_metadata_id = $platform->get_technology_type_metadata_id();
         $platform->set_technology_type_metadata_id($technology_type_metadata_id);
  Desc: get or set a technology_type_metadata_id in a platform object. 
  Ret:  get=> $technology_type_metadata_id, a scalar.
        set=> none
  Args: get=> none
        set=> $technology_type_metadata_id, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $technology_type_metadata_id = $platform->get_technology_type_metadata_id(); 

=cut

sub get_technology_type_metadata_id {
  my $self=shift;
  return $self->get_technology_type_dbic_row->get_column('metadata_id');
}

sub set_technology_type_metadata_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  my $error_message = "DATA TYPE ERROR: The metadata_id ($data) for CXGN::SEDM::Platform->set_technology_type_metadata_id()";
	  $error_message .= " IS NOT AN INTEGER.\n\n";
	  croak($error_message);
      }
      my $technology_type_row = $self->get_technology_type_dbic_row();
      $technology_type_row->set_column( metadata_id => $data );
      $self->set_technology_type_dbic_row($technology_type_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The metadata_id was not supplied for set_technology_type_metadata_id function");
  }
}

=head2 accessors get_technology_type_data, set_technology_type_data

 Usage: my %technology_type_data = $platform->get_technology_type_data();
        $platform->set_technology_type_data({ %arguments });
 Desc: This methods get and set the technology types data into the platform object
       The technology_type_columns are:
         - technology_type_id
         - technology_type_name
         - description
         - metadata_id    
 Ret:  Get => A hash with keys=>column_names and values=>values
       Set => None
 Args: Get => None
       Set => A hash reference with keys=>column_names and values=>values
 Side Effects: 1- If none argument is supplied, create an empty technology_type_row and set the platform object with it.
               2- The technology_type_id of the platform object is setted with the technology_type_id from the technology_type_row
               3- If the arguments not are a hash reference, die
 Example: my %technology_type_data = %platform->get_technology_type_data()
          $platform->set_technology_type_data( { technology_name => 'test' } );

=cut

sub get_technology_type_data {
  my $self = shift;
  my $technology_type_row = $self->get_technology_type_dbic_row();
  my %technology_type_data = $technology_type_row->get_columns();
  return %technology_type_data; 
}

sub set_technology_type_data {
  my $self = shift;
  my $data_href = shift;
  my $technology_type_row = $self->get_technology_type_dbic_row();
  if ( ref($data_href) eq 'HASH' ) {
      my %data = %{ $data_href };
      
      ## Check if the columns that are using are right.

      my @column_names = $self->get_schema()->source('TechnologyTypes')->columns();
      my @data_types = keys %data;
      $self->check_column_names(\@data_types, 'TechnologyTypes', 'set_technology_type_data');

      $technology_type_row->set_columns({%data});
  } else {
      unless (defined $data_href) {

	  ## If there aren't any argument, create a new row object.

	  $technology_type_row = $self->get_schema()->resultset('TechnologyTypes')->new({});
      } else {
	  my $error = 'FUNCTION ARGUMENT ERROR: The argument suplied in the CXGN::SEDM::Platform->set_technology_type_data(\%arg) ';
	  $error .= 'is not a hash reference\n';
          croak($error);
      }
  }
  $self->{technology_type_row} = $technology_type_row;

  ## Last thing, change the technology_type_id for platform_row too.

  my $technology_type_id = $technology_type_row->get_column('technology_type_id');
  if (defined $technology_type_id) {
      $self->set_technology_type_id($technology_type_id);
  }
}



##################################################################
#### FORTH: General accessor for Platform_Row.            ########
####        Specific accessors for Platform_Data:         ########
####                * platform_id                         ########
####                * technology_type_id (see before)     ########
####                * platform_name                       ########
####                * platform_description                ########
####                * contact_person_id                   ########
####                * platform_metadata_id                ########
####        Special accessor to get/set contact_person_id ########
####                by username                           ########
##################################################################

=head2 accessors get_platform_dbic_row, set_platform_dbic_row

  Usage: my $platform_row_object = $self->get_platform_dbic_row();
         $self->set_platform_dbic_row($platform_object);
  Desc: Get or set a a result set object into a platform_object
  Ret:   Get => $platform_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::Platform).
         Set => none
  Args:  Get => none
         Set => $platform_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::Platform).
  Side_Effects: With set check if the argument is a result set object. If fail, dies.
  Example: my $platform_row_object = $self->get_platform_dbic_row();
           $self->set_platform_dbic_row($platform_row_object);

=cut

sub get_platform_dbic_row {
  my $self = shift;
  return $self->{platform_row}; 
}

sub set_platform_dbic_row {
  my $self = shift;
  my $platform_row = shift || croak("FUNCTION PARAMETER ERROR: None platform_row object was supplied for set_platform_dbic_row function");
  if (ref($platform_row)  ne 'CXGN::SEDM::Schema::Platforms') {
      my $error_message = "SET_PLATFORM_DBIC_ROW ARGUMENT ERROR: The platform_result_set_object:$platform_row ";
      $error_message .= "is not a platform_row object (package_name:CXGN::SEDM::Schema::Platforms).\n";
      croak($error_message);
  }
  $self->{platform_row} = $platform_row;
}

=head2 accessors get_platform_id, set_platform_id
  
  Usage: my $platform_id=$platform->get_platform_id();
         $platform->set_platform_id($platform_id);
  Desc: get or set a platform_id in a platform object. 
  Ret:  get=> $platform_id, a scalar.
        set=> none
  Args: get=> none
        set=> $platform_id, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $platform_id=$platform->get_platform_id(); 

=cut

sub get_platform_id {
  my $self=shift;
  return $self->get_platform_dbic_row->get_column('platform_id');
}

sub set_platform_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The platform_id ($data) for CXGN::SEDM::Platform->set_platform_id() IS NOT AN INTEGER.\n\n");
      }
      my $platform_row = $self->get_platform_dbic_row();
      $platform_row->set_column( platform_id => $data );
      $self->set_platform_dbic_row($platform_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The platform_id was not supplied for set_platform_id function");
  }
}

=head2 accessors get_platform_name, set_platform_name

  Usage: my $platform_name=$platform->get_platform_name();
         $platform->set_platform_name($platform_name);
  Desc: Get the platform_name for a platform object from the database.
  Ret:  get=> $platform_name, a scalar
        set=> none
  Args: get=> none
        set=> $platform_name, a scalar
  Side_Effects: none
  Example: my $platform_name=$platform->get_platform_name();

=cut

sub get_platform_name {
  my $self = shift;
  return $self->get_platform_dbic_row->get_column('platform_name'); 
}

sub set_platform_name {
  my $self = shift;
  my $data = shift || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_platform_name function");
  my $platform_row = $self->get_platform_dbic_row();
  $platform_row->set_column( platform_name => $data );
  $self->set_platform_dbic_row($platform_row);
}


=head2 accessors get_platform_description, set_platform_description

  Usage: my $platform_description=$platform->get_platform_description();
         $platform->set_platform_description($platform_description);
  Desc: get or set the platform_description for a platform object from the database
  Ret:  get=> $platform_description, a scalar
        set=> none
  Args: get=> none
        set=> $platform_description, a scalar
  Side_Effects: none
  Example: my $platform_description=$platform_description->get_platform_description();

=cut

sub get_platform_description {
  my $self = shift;
  return $self->get_platform_dbic_row->get_column('description'); 
}

sub set_platform_description {
  my $self = shift;
  my $data = shift;
  my $platform_row = $self->get_platform_dbic_row();
  $platform_row->set_column( description => $data );
  $self->set_platform_dbic_row($platform_row);
}

=head2 accessors get_contact_person_id, set_contact_person_id

  Usage: my $contact_person_id=$platform->get_contact_person_id();
         $platform->set_contact_person_id($contact_person_id);
  Desc: get or set the contact_person_id for a platform object from the database
  Ret:  get=> $contact_person_id, a scalar
        set=> none
  Args: get=> none
        set=> $contact_person_id, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $contact_person_id=$platform->get_contact_person_id();

=cut

sub get_contact_person_id {
  my $self = shift;
  return $self->get_platform_dbic_row->get_column('contact_person_id'); 
}

sub set_contact_person_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The contact_person_id ($data) for CXGN::SEDM::Platform->set_contact_person_id IS NOT AN INTEGER.\n\n");
      }
      my $platform_row = $self->get_platform_dbic_row();
      $platform_row->set_column(contact_person_id => $data);
      $self->set_platform_dbic_row($platform_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The parameter sp_person_id was not supplied for set_contact_person_id function");
  }
}

=head2 accessors get_contact_person_id_by_username, set_contact_person_id_by_username

  Usage: my $contact_person_username=$platform->get_contact_person_id_by_username();
         $platform->set_contact_person_id_by_username($contact_person_username);
  Desc: get or set the contact_person_id for a metadata object from the database
  Ret:  get=> $contact_person_username, a scalar
        set=> none
  Args: get=> none
        set=> $contact_person_username, a scalar (constraint)
  Side_Effects: when set is used, check if exists the username, if fails, die with a error message.
  Example: my $contact_person_username=$metadata->get_contact_person_by_username();

=cut

sub get_contact_person_id_by_username {
  my $self = shift;
  my $contact_person_id = $self->get_platform_dbic_row()->get_column('contact_person_id');
  my $platform_id = $self->get_platform_dbic_row()->get_column('platform_id');
  my $query = "SELECT username FROM sgn_people.sp_person WHERE sp_person_id=?";
  my $sth = $self->get_schema()->storage()->dbh()->prepare($query);
  $sth->execute($contact_person_id);
  my ($username)=$sth->fetchrow_array();

  ## If the query don't return any username there are some errors than should be reported:
   ##    1- If the contact_person_id store in the object using set_create_person_id do not exists (data integration error).
    ##   2- If the contact_person_id of the sed.metadata table (set in the object using fetch) do not exists (data coherence error)
     ##  3- If the contact_person_id of the sed.metadata table do not exists and the create_person_id store in the table do not
      ##    exists in the sgn_people.sp_person table (data coherence error)

  unless (defined $username) {
      my $error_message = "DATA ERROR: The contact_person_id stored in this object do not exist in the table sgn_people.sp_person.\n";
      if (defined $platform_id) {
	  my $sedquery = "SELECT contact_person_id FROM sed.platform WHERE platform_id=?";
	  my $sedsth = $self->get_schema->storage()->dbh()->prepare($sedquery);
	  $sedsth->execute($platform_id);
	  my ($sed_contact_person_id) = $sedsth->fetchrow_array();
	  if (defined $sed_contact_person_id) {
	      if ($contact_person_id != $sed_contact_person_id) {
		  $error_message = "The contact_person_id=$contact_person_id of the platform object is not the same ";
		  $error_message .= "than the sed.platform.contact_person_id for the platform_id=$platform_id";
		  croak($error_message);
	      } else {
		  $error_message = "DATA COHERENCE ERROR: The sed.platform.contact_person_id for the platform_id=$platform_id ";
		  $error_message .= "do not exists in the sgn_people.sp_person table\n\n";
		  croak($error_message);
	      }
	  } else {
	      croak("DATA COHERENCE ERROR: The contact_person_id set in the object do not exists in the sgn_people.sp_person table\n");
	  }
      } 
  } else {
      return $username;
  }
}

sub set_contact_person_id_by_username {
  my $self = shift;
  my $data = shift || croak("FUNCTION PARAMETER ERROR: The username was not supplied for set_contact_person_id_by_username function");
  my $query = "SELECT sp_person_id FROM sgn_people.sp_person WHERE username=?";
  my $sth = $self->get_schema()->storage()->dbh()->prepare($query);
  $sth->execute($data);
  my ($contact_person_id) = $sth->fetchrow_array();

  ## Only need be reported if the username that it is being set is not in the sgn_people.sp_person table

  if (defined $contact_person_id) {
      my $platform_row = $self->get_platform_dbic_row();
      $platform_row->set_column(contact_person_id => $contact_person_id);
      $self->set_platform_dbic_row($platform_row);
  } else {
      croak("DATA INTEGRATION ERROR: The username=$data do not exists in the sgn_people.sp_person table.\n");
  }
}

=head2 accessors get_platform_metadata_id, set_platform_metadata_id

  Usage: my $platform_metadata_id=$platform->get_platform_metadata_id();
         $platform->set_platform_metadata_id($platform_metadata_id);
  Desc: get or set the platform_metadata_id for a platform object from the database
  Ret:  get=> $platform_metadata_id, a scalar
        set=> none
  Args: get=> none
        set=> $platform_metadata_id, a scalar (constraint, it must be an integer)
  Side_Effects: when set is used, check that the $platform_metadata_id is an integer, if fails, die with a error message.
  Example: my $platform_metadata_id=$metadata->get_platform_metadata_id();

=cut

sub get_platform_metadata_id {
  my $self = shift;
  return $self->get_platform_dbic_row()->get_column('metadata_id'); 
}

sub set_platform_metadata_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR:The metadata_id ($data) in CXGN::SEDM::Platform->set_platform_metadata_id() IS NOT AN INTEGER.\n");
      }
      my $platform_row = $self->get_platform_dbic_row();
      $platform_row->set_column( metadata_id => $data );
      $self->set_platform_dbic_row($platform_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The paramater metadata_id was not supplied for set_platform_metadata_id function");
  }
}

=head2 accessors get_platform_data, set_platform_data

 Usage: my %platform_data = $platform->get_platform_data();
        $platform->set_platform_data({ %arguments });
 Desc: This methods get and set the technology types data into the platform object.
       The column names are: 
         - platform_id,
         - technology_type_id, 
         - platform_name, 
         - description,
         - contact_person_id, 
         - metadata_id,
 Ret:  Get => A hash with keys=>column_names and values=>values
       Set => None
 Args: Get => None
       Set => A hash reference with keys=>column_names and values=>values
 Side Effects: 1- If none argument is supplied, create an empty platform_row and set the platform object with it.
               2- The technology_type_id of the platform object is setted with the technology_type_id from the technology_type_row
               3- If the arguments not are a hash reference, die
 Example: my %platform_data = %platform->get_platform_data()
          $platform->set_platform_data( { platform_name => 'test' } );

=cut

sub get_platform_data {
  my $self = shift;
  my $platform_row = $self->get_platform_dbic_row();
  my %platform_data = $platform_row->get_columns();
  return %platform_data; 
}

sub set_platform_data {
  my $self = shift;
  my $data_href = shift;
  my $platform_row = $self->get_platform_dbic_row();
  if ( ref($data_href) eq 'HASH' ) {
      my %data = %{ $data_href };
      
      ## Check if the columns that are using are right.

      my @column_names = $self->get_schema()->source('Platforms')->columns();
      my @data_types = keys %data;
      $self->check_column_names(\@data_types, 'Platforms', 'set_platform_data');

      $platform_row->set_columns({%data});
  } else {
      unless (defined $data_href) {

	  ## If there aren't any argument, create a new row object.

	  $platform_row = $self->get_schema()->resultset('Platform')->new({});
      } else {
	  my $error = 'FUNCTION ARGUMENT ERROR: The argument suplied in the CXGN::SEDM::Platform->set_platform_data(\%arg) ';
	  $error .= 'is not a hash reference\n';
          croak($error);
      }
  }
  $self->{platform_row} = $platform_row;

  ## Last thing, change the platform_id for all the platform objects too.

  my $platform_id = $platform_row->get_column('platform_id');
  if (defined $platform_id) {
      $self->set_platform_design_data({}, { platform_id => $platform_id } );
  }
}



##################################################################
#### FIFTH: General accessor for Platform_Design_Row_Aref.########
####        Specific accessors for Platform_Design_Data   ########
####        Special accessor for organism list            ########
##################################################################


=head2 accessors get_platform_design_dbic_rows, set_platform_design_dbic_rows

  Usage: my @platform_design_rows = $self->get_platform_design_dbic_rows(%column_data);
         $self->set_platform_design_dbic_rows(\@platform_design_rows);
  Desc: Get or set a a result set object into a platform_object
  Ret:   Get => $platform_design_row_object, a list of DBIx::Class::Row objects (CXGN::SEDM::Schema::PlatformsDesigns).
         Set => none
  Args:  Get => $column_data is a hash with keys=column names for sed.platform_design table and values=values, 
                If an empty hash is used ( get_platform_design_dbic_rows({}) ) it will return all the platform_design_rows.
                If none hash reference is used ( get_platform_design_row() it will return all the platform_design rows)
         Set => $platform_design_row_object, reference of a list of DBIx::Class::Row objects (CXGN::SEDM::Schema::PlatformsDesigns).
  Side_Effects: With set check if the argument is a result set object. If fail, dies.
  Example: my @platform_design_rows = $self->get_platform_design_dbic_rows({ sequence_type => 'mRNA'});
           $self->set_platform_dbic_row(\@platform_design_rows);

=cut

sub get_platform_design_dbic_rows {
  my $self = shift;
  my $href = shift;
    
  my $platform_design_rows_aref = $self->{platform_design_rows};
  my @platform_design_rows;
  if (ref($platform_design_rows_aref) eq 'ARRAY' ) {
      @platform_design_rows = @{ $platform_design_rows_aref };
  }
  my @selected_rows;

  ## If none arguments were used, return all the platform_design rows, else it will try to find equivalences between the argument data
   ## and the data stored in the platform_design row object.

  if (ref $href eq 'HASH') {     
      my %query_values = %{$href};

      ## Check if the keys are the column names for the sed.platform_design table.

      my @column_names = $self->get_schema()->source('PlatformsDesigns')->columns();
      my @data_types = keys %query_values;
      if (scalar(@data_types) == 0) {
	  @selected_rows = @platform_design_rows;
      } else {
	  $self->check_column_names(\@data_types, 'PlatformsDesigns', 'get_platform_design_row');
     
          ## Search equivalences between the argument data and the platform_design_rows, if find match put the row in the array that
          ## will be return by this function

	  foreach my $platform_design_row (@platform_design_rows) {
	      my @query_columns = keys %query_values;
	      my $query_columns_n = scalar(@query_columns);
	      foreach my $col (@query_columns) {  ## Check every field detailed as function parameter 
		  my $query_val = $query_values{$col};
		  my $val = $platform_design_row->get_column($col);
		  if (defined $val && defined $query_val && $val eq $query_val) {  ## If match, decrease 1 the parameters counts
		      $query_columns_n--;
		  }
	      }
	      if ($query_columns_n == 0) {                   ## If the parameters counts is 0 means that all the parameters match so,
		  push @selected_rows, $platform_design_row; ## it can push the object into the array.
	      }
	  }
      }
  } else {
      @selected_rows = @platform_design_rows;
  }
  return @selected_rows; 
}

sub set_platform_design_dbic_rows {
  my $self = shift;
  my $platform_design_rows_aref = shift;

  ## Check that the object that you are adding into the platform_design_rows is a real CXGN::SEDM::Schema::PLatformsDesigns object

  unless (defined $platform_design_rows_aref) {
      croak("FUNCTION PARAMETER ERROR: None platform_design_rows array reference was supplied for set_platform__design_rows function");
  } else {
      unless (ref($platform_design_rows_aref) eq 'ARRAY') {
	  croak("FUNCTION PARAMETER ERROR: The parameter used in the set_platform_design_dbic_rows is not an array reference.\n");
      }
      my @platform_design_rows = @{$platform_design_rows_aref};
      foreach my $platform_design_row (@platform_design_rows) {
	  if (ref($platform_design_row) ne 'CXGN::SEDM::Schema::PlatformsDesigns') {
	      my $error_message = "SET_PLATFORM_DESIGN_DBIC_ROWS ARGUMENT ERROR: The platform_design_row object:$platform_design_row ";
	      $error_message .= "is not a platform_design_row object (package_name:CXGN::SEDM::Schema::PlatformsDesigns).\n";
	      croak($error_message);
	  }
      }
  }
  my @test = @{ $platform_design_rows_aref };
  $self->{platform_design_rows} = $platform_design_rows_aref;
}

=head2 add_platform_design_data

  Usage: $platform->add_platform_design_data({%columns_data_hash}); 
  Desc: Add a new platform_design_row to the platform object with the parameters detailed in the arguments.
        The column name are:
            - platform_design_id
            - platform_id
            - organism_group_id
            - sequence_type
            - dbiref_id
            - dbiref_type
            - metadata_id
        Additionally it can use 'organism_list' => array_reference. It will replace the organism_group_id if it exists into the 
        the database, and set the organism_list associated to the new row.
  Ret: none
  Args: %column_data_hash, a hash reference with keys=column name for the sed.plataforms_designs table and value=value for these fields
  Side_Effects: croak if is used a keys that is not a column name for the platform_design table
  Example: $platform->add_platform_design_data({ organims_group_id => 1, 
						 sequence_type     => 'unigene', 
						 dbiref_id         => 42,
						 description       => 'platform designin the tobaco unigene build 2'});

=cut

sub add_platform_design_data {
    my $self = shift;
    my $parameters_href = shift || croak "DATA INPUT ERROR: None parameter was detailed in the function add_platform_design_data().\n";
    unless (ref $parameters_href eq 'HASH') {
	croak "DATA INPUT ERROR: The parameter detailed in the add_platform_design_data() function, is not a hash reference.\n";
    }

    my @platform_design_rows = $self->get_platform_design_dbic_rows();
    my %parameters = %{$parameters_href};
    my $organism_list;
    if ( exists($parameters{'organism_list'}) ) {
	$organism_list = $parameters{'organism_list'};
	my $organism_group_id =  $self->get_organism_group_id_from_db_by_organism_list($self->get_schema(), $organism_list);
	if (defined $organism_group_id) {
	    $parameters{'organism_group_id'} = $organism_group_id;
	}
	delete($parameters{'organism_list'});
    }
    $parameters_href = \%parameters;
    my @column_names = $self->get_schema()->source('PlatformsDesigns')->columns();
    my @data_types = keys %parameters;
    unless (scalar(@data_types) == 0) {
        $self->check_column_names(\@data_types, 'PlatformsDesigns', 'add_platform_design_data');	
    }
    
    my $new_row = $self->get_schema()->resultset('PlatformsDesigns')->new($parameters_href);
    my $platform_id = $self->get_platform_id();
    if ( defined($platform_id) ) {
	if ( exists($parameters{'platform_id'}) ) {
	    if ( $platform_id ne $parameters{'platform_id'} ) {
		my $error = "DATA INTEGRITY ERROR: The argument platform_id:$parameters{'platform_id'} is not the same than the ";
		$error .= "platform_id in the platform object for CXGN::SEDM::Platform->add_platform_design_data() method.\n";
		croak($error);
	    }
	} else {
	    $new_row->set_column( platform_id => $platform_id );
	    if (defined $organism_list) {
		my $platform_design_organism_list_href = $self->{platform_design_organism_list};
		if (defined $platform_design_organism_list_href && ref($platform_design_organism_list_href) eq 'HASH') {
		    my %platform_design_organism_list = %{ $platform_design_organism_list_href };
		    $platform_design_organism_list{$new_row} = $organism_list;
		    $self->{platform_design_organism_list} = \%platform_design_organism_list;
		}
	    }
	}
    }
    push @platform_design_rows, $new_row;
    $self->set_platform_design_dbic_rows(\@platform_design_rows);
}

=head2 delete_platform_design_data

  Usage: my @deleted_platform_design_rows = $self->delete_platform_design_data({ %column_name_value_pairs })
  Desc: Remove from the object all the platform_design_rows with the values detailed in the parameter_hash.
        If any parameter was specify, remove all the platform_design_rows (undef the value for platform_design_rows)
  Ret: @deleted_platform_design_rows, a list with teh platform_design_row objects removed from the platform object
  Args: %column_name_value_pairs, a hash reference with keys=column_name and values=column_value to remove 
  Side_Effects: croak if is used a keys that is not a column name for the platform_design table
  Example: my @deleted_platform_design_rows = $self->delete_platorm_design_rows({ platform_id => 1 });
           my @all_deleted_platform_design_rows = $self->delete_platform_design_data();

=cut

sub delete_platform_design_data {
    my $self = shift;
    my $parameters_href = shift;
    my (@deleted_platform_design_rows, @non_deleted_platform_design_rows);

    unless (defined $parameters_href) {
	@deleted_platform_design_rows = $self->get_platform_design_dbic_rows();
	$self->{platform_design_rows} = undef;
    } else { 
	unless (ref $parameters_href ne 'HASH') {
	    croak "DATA INPUT ERROR: The parameter detailed in the delete_platform_design_row() function, is not a hash reference.\n";
	}
	my @data_types = keys %{$parameters_href};
        if (scalar(@data_types) == 0) {
	    	@deleted_platform_design_rows = $self->get_platform_design_dbic_rows();
		$self->{platform_design_rows} = undef;
	} else {
	    $self->check_column_names(\@data_types, 'PlatformDesign', 'delete_platform_design_data');	
	    my @platform_design_rows = $self->get_platform_design_dbic_rows();
	    foreach my $platform_design_row (@platform_design_rows) {
		my @query_columns = keys %{$parameters_href};
		my $query_columns_n = scalar(@query_columns);
		foreach my $col (@query_columns) {
		    my $query_val = $parameters_href->{$col};
		    my $val = $platform_design_row->get_column($col);
		    if ($val eq $query_val) {
			$query_columns_n--;
		    }
		}
		if ($query_columns_n == 0) {
		    push @deleted_platform_design_rows, $platform_design_row;
		} else {
		    push @non_deleted_platform_design_rows, $platform_design_row;
		}
	    }
	    $self->set_platform_design_dbic_rows(\@non_deleted_platform_design_rows);
	}   
    }    
    return @deleted_platform_design_rows;
}

=head2 accessors get_platform_design_data, set_platform_design_data

  Usage: my @platform_design_data_aref = $self->get_platform_design_data({%column_name_value_pairs_for_search}, [@column_names]);
         $self->set_platform_design_data({%column_name_value_pairs_for_search}, {%column_name_value_pairs_for_set});
  Desc: Get an array of array references where each array reference is a list of a platform_designs_data
        Set the values specified in a hash for the platform_design_rows that have tha values specified in a first hash.
        The platform_design columns are:
          - platform_design_id (primary_key, an integer).
          - organism_group_id (reference of group table, an integer)
          - sequence_type (varchar(250))
          - dbiref_id (an integer)
          - dbiref_type (varchar(250))
          - description (text)
          - metadata_id (reference of metadata_id in metadata table, an integer)
  Ret:   Get => An array of hash references with the columns specified in an argument array.
                it will return: my %hash = %{$data[0]}; ... with keys=col_name and values=values
         Set => none
  Args:  Get => {%column_name_value_pairs_for_search}, A hash reference with the conditions for the search into the object, with
                                                       keys=column_names and values=values to search
                [@column_names], An array reference with the columns names to get.
                If none parameters is used, get all the columns for all the platform_design_rows.
         Set => {%column_name_value_pairs_for_search}, A hash reference with the conditions for the search into the object, with
                                                       keys=column_names and values=values to search
                {%column_name_value_pairs_for_set}, A hash reference with the values to set into the platform_design_rows objects
                                                    with keys=column_names and values=values to set 
  Side_Effects: croak if is used a column_name that do not exits in the object
                using the set function, set platform_design_rows and platform_design_organism_list.
  Examples: 
    - To get all the platform_design data: 
            my @platform_design_data_aref = $self->get_platform_design_data();
    - To get all the platform_design_id for the platform_design_data objects that have sequence_type = 'mRNA'.
            my @platform_design_ids_mRNA_aref = $self->get_platform_design_data({ sequence_type => 'mRNA' }, ['platform_design_ids']);
    - To set all the platform_design_rows that have a sequence_type='mRNA' to 'EST'
            $self->set_platform_design_data({ sequence_type => 'mRNA'}, { sequence_type => 'EST' });
    - To set all the platform_design_rows in a platform object with sequence_type='EST'
            $self->set_platform_design_data({}, { sequence_type => 'EST' });

=cut

sub get_platform_design_data {
  my $self = shift;
  my $search_href = shift;
  my $col_aref = shift;
  my (@platform_design_data, @columns_selected);
  my %search_parameters;

  ##   Checking the different arguments: 
   ##     * First, hash reference:
    ##                    1- it is defined, if not get_all_the_rows
     ##                   2- it is a hash reference, if not die.
      ##                  3- it has the right column names, if not die
       ## * Second, array reference:
        ##                1- it is defined, if not get_all_the_columns in the row_objects
         ##               2- it is an array reference, if not die
          ##              3- it has the right column names, if not die
   
  if (defined $search_href) {
      if (ref($search_href) ne 'HASH') {
	  croak "FUNCTION ARGUMENT ERROR: The first argument type for the function get_platform_design_data() is not hash reference.\n";
      } else {
	  %search_parameters = %{$search_href};
	  my @search_col = keys %search_parameters;
	  if (scalar(@search_col) > 0) {
	      $self->check_column_names(\@search_col, 'PlatformsDesigns', 'get_platform_design_data(), first argument');
	      if (defined $col_aref) {
		  if (ref($col_aref) ne 'ARRAY') {
		      my $error2 = "FUNCTION ARGUMENT ERROR: The second argument type for the function get_platform_design_data() ";
		      $error2 .= "is not an array reference.\n";
		      croak($error2);
		  } else {
		      @columns_selected = @{$col_aref};
		      $self->check_column_names(\@columns_selected, 'PlatformsDesigns', 'get_platform_design_data(), second argument');
		  }
	      }
	  }
      }
  }
	
  ## Now get the data
	      
  my @platform_design_rows = $self->get_platform_design_dbic_rows($search_href); ## If $search_href is undef, it will get all the rows
  foreach my $platform_design_row (@platform_design_rows) {
      my %platform_design_data_row;
      my %values = $platform_design_row->get_columns();
      my @testk = keys %values;
      my @testv = values %values;
      if (defined $col_aref) {                                          ## If the columns names is not defined, it will get
	  my @col = @{ $col_aref };
	  if (defined $col[0]) {
	       @columns_selected = @{ $col_aref };
	  } else {
	      @columns_selected = keys %values;                         ## all the columns names of the table (get using get_columns)
	  }
      } else {
	  @columns_selected = keys %values;  
      }
      foreach my $col (@columns_selected) {
	  my $val = $values{$col};
	  $platform_design_data_row{$col} = $val;
      }
      push @platform_design_data, \%platform_design_data_row;
  }
  return @platform_design_data; 
}

sub set_platform_design_data {
  my $self = shift;
  my $search_href = shift;
  my $set_href = shift;
  my (%search_parameters, %set_parameters);
  my @platform_design_rows_set;

  ## First, check that the arguments are right. They can not be undefined, for the first argument because if you use undefined, 
  ## you can not use a defined second argument. For the second argument, why you can set something and don't give the value to set.
  ## To set columns without any search parameters you should use get_platform_design_data({}, { foo => 'foo'}), so means, use an empty
  ## hash. 

  unless (defined $search_href) {
      croak "FUNCTION ARGUMENT ERROR:The first argument (search parameters) for the function set_platform_design_data IS NOT DEFINED.\n";
  } else {
      %search_parameters = %{$search_href};
      my @search_columns = keys %search_parameters;
      if (scalar(@search_columns) > 0) {
	  $self->check_column_names(\@search_columns, 'PlatformsDesigns', 'set_platform_design_data(), first argument');
      }
  }
  unless (defined $set_href) {
      croak "FUNCTION ARGUMENT ERROR:The second argument (set parameters) for the function set_platform_design_data IS NOT DEFINED.\n";
  } else {
      %set_parameters = %{$set_href};
      my @set_columns = keys %set_parameters;
      if (scalar(@set_columns) > 0) {
	  $self->check_column_names(\@set_columns, 'PlatformsDesigns', 'set_platform_design_data(), second argument');
      }
  }
  
  ## Now set the parameters. To do it, first, get the row objects using the parameters of the search_hash and second, set the values
  ## in these row_objects.

  my @all_platform_design_rows = $self->get_platform_design_dbic_rows();
  my @selected_platform_design_rows = $self->get_platform_design_dbic_rows({ %search_parameters });
  foreach my $platform_design_row (@all_platform_design_rows) {
      my $match = 0;
      foreach my $selected_platform_design_row (@selected_platform_design_rows) {
	  if ($platform_design_row eq $selected_platform_design_row) {           ## compare the row_object from the selected and
	      $match = 1;                                                            ## unselected list. If it is in both, change the
	  }                                                                          ## match variable and set the parameters. If not, 
      }                                                                              ## add to the list without changes.
      if ($match == 1) {
	  
	  my $new_platform_design_row = $platform_design_row->set_columns({ %set_parameters });

          ## If any organism_group_id was set, the platform_design_organism_list also will be set.    
      
	  if (exists $set_parameters{'organism_group_id'}) {
	      my @organism_list = $self->get_organism_list_from_db_by_organism_group_id($set_parameters{'organism_group_id'});
	      $self->set_platform_design_organism_list($new_platform_design_row, \@organism_list);
	  }
	  push @platform_design_rows_set, $new_platform_design_row;
      } else {
	  push @platform_design_rows_set, $platform_design_row;
      }
  }
  $self->set_platform_design_dbic_rows(\@platform_design_rows_set);
}

### The list of organism associated to platform_design rows will be stored as hash reference with keys=platform_design_row and 
## values a list of organism. The justification is the follow: To store a organism_list using DBIx::Class we will store the organism_names
## and the organism_ids in a Organism object (from sgn schema), the organism_id as member_id and a group_id and finally this group_id
## in the platform_design object. It can be hard to manipulate and the sgn schema, today, it is not implemented using DBIx::Class, so
## it is more easy if we store the organism_list in a value of a hash and get from here we it is necessary. To store, we can use 
## a mix between DBIx::Class objects (for sed schema) and standard searches (for sgn.organism). Ok, it is not elegant, but for the
## moment should be work. When all the sgn tables use DBIx::Class objects, this method should be deprecated or updated to this system.  


=head2 accessors get_platform_design_organism_list, set_platform_design_organism_list

  Usage:  my @organism_design_list = $self->get_platform_design_list({%search_arguments});
          $self->set_platform_design_list({%search_arguments}, \@organism_design_list);
  Desc: Get and set a list of organism (associated to organism_group_id) in the platform_object.
  Ret:  Get => @organism_design_list, a list, an array,  of organisms.
        Set => none
  Args: Get => %search_arguments to get a platform_design_row, with keys=>platform_design column names and values=>values to search.
               If none %search argument is supplied, will return a non redundant list of all the organism for all the platform_design 
               objects
        Set => $platform_design_row, a row_object with a organims_group_id => list_of_organism and 
               \@organisms_design_list, list of organism.
               If the value 'undef' is used, set the value to undef.
  Side_Effects: none
  Example: my @organism_design_list = $self->get_platform_design_list($platform_design_row);
           $platform->set_platform_design_organsim_list($platform->get_platform_design_row{}, @organism)

=cut

sub get_platform_design_organism_list {
  my $self = shift;
  my $search_hash_reference = shift;
  my @platform_design_rows = $self->get_platform_design_dbic_rows( $search_hash_reference );
  my %platform_design_organism_list;
  my $platform_design_organism_list_href = $self->{platform_design_organism_list};
  if ( defined($platform_design_organism_list_href) && ref($platform_design_organism_list_href) eq 'HASH') {
      %platform_design_organism_list = %{ $platform_design_organism_list_href };
  }
  my @organism_list;
  foreach my $platform_design_row (@platform_design_rows) {
      if (defined $platform_design_row) {
	  my $organism_list_aref = $platform_design_organism_list{$platform_design_row};
	  if (defined $organism_list_aref) {
	      @organism_list = @{$organism_list_aref};
	  }
      } else {
	  my @platform_design_rows = keys %platform_design_organism_list;
	  my %organism;
	  foreach my $platform_design_row (@platform_design_rows) {
	      my @organism = @{ $platform_design_organism_list{$platform_design_row} };
	      foreach my $single_organism (@organism) {
		  unless (exists $organism{$single_organism}) {
		      $organism{$single_organism} = 1;
		  } else {
		      $organism{$single_organism} += 1;
		  }
	      }
	  }
	  @organism_list = keys %organism;
      }
  }  
  return @organism_list; 
}

sub set_platform_design_organism_list {
    my $self = shift;
    my $search_hash_ref = shift || 
	croak "FUNCTION ARGUMENT ERROR: None argument was supplied in the set_platform_design_organism_list() function.\n";
    my @platform_design_rows = $self->get_platform_design_dbic_rows( $search_hash_ref );
    if ( scalar(@platform_design_rows) == 0 ) { 
        my $error = "FUNCTION ARGUMENT ERROR: There are not any platform_design_row associated to the search argument supplied in ";
	$error .= "the set_platform_design_organism_list() function.\n";
	croak($error);
    }
    my $organism_list_aref = shift ||
        croak "FUNCTION ARGUMENT ERROR: The second argument (Array reference of organism list) was supplied in the 
               set_platform_design_organism_list function.\n";
  
    my %platform_design_organism_list;
    
    foreach my $platform_design_row (@platform_design_rows) {
	if (ref $platform_design_row ne 'CXGN::SEDM::Schema::PlatformsDesigns') {
	    croak "FUNCTION ARGUMENT ERROR: The platform_design_row is not a CXGN::SEDM::Schema::PlatformsDesigns object for 
                   set_platform_design_organism_list function.\n";
	}

	my $platform_design_organism_list_href = $self->{platform_design_organism_list};
	if (defined $platform_design_organism_list_href) {
	    %platform_design_organism_list = %{ $platform_design_organism_list_href };
	    if ($organism_list_aref eq 'undef') {
		$platform_design_organism_list{$platform_design_row} = '';
	    } elsif (ref $organism_list_aref ne 'ARRAY') {
		croak "FUNCTION ARGUMENT ERROR: The array reference for the list of organism is not an array reference for the 
                       Set_platform_design_organism_list function";
	    } else {
		$platform_design_organism_list{$platform_design_row} = $organism_list_aref;
	    }
	} else {
	    if ($organism_list_aref eq 'undef') {
		$platform_design_organism_list{$platform_design_row} = '';
	    } elsif (ref $organism_list_aref ne 'ARRAY') {
		croak "FUNCTION ARGUMENT ERROR: The array reference for the list of organism is not an array reference for the 
                       Set_platform_design_organism_list function";
	    } else {
		$platform_design_organism_list{$platform_design_row} = $organism_list_aref;
	    }
	}

	## Finally we set the platform_design_organism_group_id (if exists this value)

	my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list($self->get_schema(), $organism_list_aref);
	if (defined $organism_group_id) {
	    $platform_design_row->set_column( organism_group_id => $organism_group_id);
	}
    }
    $self->{platform_design_organism_list} = \%platform_design_organism_list;


}



=head2 accessors get_platform_design_data_using_organism_list, set_platform_design_data_using_organism_list

  Usage: my @platform_design_data = $self->get_platform_design_data_using_organism_list({%column_pairs_for_search}, [@column_names]);
         $self->set_platform_design_data_using_organism_list({%column_pairs_for_search}, {%column_pairs_for_set});
  Desc: These accessors works in the same way than the get_platform_design_data() and set_platform_design_data() but can use the
        column_name 'organism_list' and an array reference as value. 
  Ret:  Get=> An array of array references where each array reference contains the columns detail as parameter. 
              If none column was detailed, it will get all the columns.
        Set=> None
  Args: Get=> An array reference with keys=column_name OR organism_list and value=values OR array reference with organism names.
              A list of column names.
        Set=> An array reference with keys=column_name OR organism_list to search and values=values OR array reference with organisms.
              An array reference with keys=column_name OR organism_list to set and values=values OR array reference with organisms.
  Side_Effects: croak with the wrong arguments.
                using the set function, set platform_design_rows and platform_design_organism_list.
  Example: @platform_design_data = $self->get_platform_design_data_using_organism_list({ organism_list => ['Solanum lycopersicum'], });
           $self->set_platform_design_data_using_organism_list({ platform_design_id => 1}, { organism_list => ['Solanum tuberosum'], })

=cut

sub get_platform_design_data_using_organism_list {
  my $self = shift;
  my $search_href = shift;
  my $col_aref = shift;
  my (@platform_design_data, @columns_selected);
  my %search_parameters;
  my $selected_organism_list='-1';

  ##   Checking the different arguments: 
   ##     * First, hash reference:
    ##                    1- it is defined, if not get_all_the_rows
     ##                   2- it is a hash reference, if not die.
      ##                  3- if exists the column organism_list, change it for organism_group_id
      ##                  4- it has the right column names, if not die
       ## * Second, array reference:
        ##                1- it is defined, if not get_all_the_columns in the row_objects
         ##               2- it is an array reference, if not die
          ##              3- if exists the column organism_list, change it for organism_group_id
          ##              4- it has the right column names, if not die
   
  if (defined $search_href) {
      if (ref($search_href) ne 'HASH') {
	  my $error1 = "FUNCTION ARGUMENT ERROR: The first argument type for the function ";
	  $error1 .= "get_platform_design_data_using_organism_list() is not hash reference.\n";
	  croak($error1);
      } else {
	  %search_parameters = %{$search_href};
	  if (exists $search_parameters{'organism_list'}) {
	      my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list( $self->get_schema(),
											     $search_parameters{'organism_list'});
	      if (defined $organism_group_id) {
		  $search_parameters{'organism_group_id'} = $organism_group_id;
	      }
	      delete $search_parameters{'organism_list'};
	  }
	  my @search_col = keys %search_parameters;
	  if (scalar(@search_col) > 0) {
	      $self->check_column_names(\@search_col, 'PlatformsDesigns', 'get_platform_design_data(), first argument');
	      if (defined $col_aref) {
		  if (ref($col_aref) ne 'ARRAY') {
		      my $error2 = "FUNCTION ARGUMENT ERROR: The second argument type for the function get_platform_design_data() ";
		      $error2 .= "is not an array reference.\n";
		      croak($error2);
		  } else {
		      my @columns_preselected = @{$col_aref};
		      my $n=0;
		      foreach my $col (@columns_preselected) {
			  if ($col eq 'organism_list') {
			      push @columns_selected, 'organism_group_id';
			      $selected_organism_list = $n;
			  } else {
			      push @columns_selected, $col;
			  }
			  $n++;
		      }
		      $self->check_column_names(\@columns_selected, 'PlatformsDesigns', 'get_platform_design_data(), second argument');
		  }
	      }
	  }
      }
  }
  @platform_design_data = $self->get_platform_design_data({%search_parameters}, [@columns_selected]);
  
  if ($selected_organism_list != '-1') {
      foreach my $platform_design_datarow (@platform_design_data) {
	  my $organism_group_id = $platform_design_datarow->[$selected_organism_list];
	  my @organism_list = $self->get_organism_list_from_db_by_organism_group_id($self->get_schema(), $organism_group_id);
	  $platform_design_datarow->[$selected_organism_list] = \@organism_list;
      }
  }
  foreach my $platform_design_single_data_href (@platform_design_data) {
      $platform_design_single_data_href = shift(@platform_design_data);
      my %platform_design_single_data = %{ $platform_design_single_data_href};
      if ( defined($platform_design_single_data{'organism_group_id'}) ) {
	 my $organism_group_id = $platform_design_single_data{'organism_group_id'}; 
	 my @organism_list_pd = $self->get_organism_list_from_db_by_organism_group_id($self->get_schema(), $organism_group_id);
	 $platform_design_single_data{'organism_list'} = \@organism_list_pd;
      }
      push @platform_design_data, \%platform_design_single_data;
  }
      
  return @platform_design_data; 
}

sub set_platform_design_data_using_organism_list {
  my $self = shift;
  my $search_href = shift;
  my $set_href = shift;
  my (%search_parameters, %set_parameters);
  my @platform_design_rows_set;

  ## First, check that the arguments are right. They can not be undefined, for the first argument because if you use undefined, 
  ## you can not use a defined second argument. For the second argument, why you can set something and don't give the value to set.
  ## To set columns without any search parameters you should use get_platform_design_data_using_organism_list({}, { foo => 'foo'}),
  ## so means, use an empty hash. 

  unless (defined $search_href) {
      my $error1 = "FUNCTION ARGUMENT ERROR:The first argument (search parameters) for the function ";
      $error1 .= "set_platform_design_data_using_organism_list IS NOT DEFINED.\n";
      croak($error1);
  } else {
      %search_parameters = %{$search_href};
      my @search_columns = keys %search_parameters;
      if (exists $search_parameters{'organism_list'}) {
	  my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list( $self->get_schema(), 
											 $search_parameters{'organism_list'} );
          if (defined $organism_group_id) {
	      $search_parameters{'organism_group_id'} = $organism_group_id;
	  }
	  
          delete $search_parameters{'organism_list'};	      
      }     
      @search_columns = keys %search_parameters;

      if (scalar(@search_columns) > 0) {
	  $self->check_column_names(\@search_columns, 'PlatformsDesigns', 'set_platform_design_data(), first argument');
      }
  }
  unless (defined $set_href) {
      my $error2 = "FUNCTION ARGUMENT ERROR:The second argument (set parameters) for the function ";
      $error2 .= "set_platform_design_data_using_organism_list IS NOT DEFINED.\n";
      croak($error2);
  } else {
      %set_parameters = %{$set_href};
      my @set_columns = keys %set_parameters;
      if (exists $set_parameters{'organism_list'}) {
	  my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list( $self->get_schema(), 
											 $set_parameters{'organism_list'} );
          if (defined $organism_group_id) {
	      $set_parameters{'organism_group_id'} = $organism_group_id;
	  }
          delete $set_parameters{'organism_list'};
      }     
      @set_columns = keys %set_parameters;
      if (scalar(@set_columns) > 0) {
	  $self->check_column_names(\@set_columns, 'PlatformsDesigns', 'set_platform_design_data(), second argument');
      }
  }
  $self->set_platform_design_data({%search_parameters}, {%set_parameters});
}

###################################################################
#### SIXTH: General accessor for Platforms_Dbxref_Row_Aref.########
####        Specific accessors for Platform_Dxref_Data     ########
####        Special accessor for Platform_Dbxref by DB     ########
###################################################################


############################# IN PROCESS ##########################



###################################################################
#### STORE FUNCTIONS: General store function               ########                                    
####                  Store condition check method         ########
####                  Specific store function for objects  ########
###################################################################

=head2 store

  Usage: my $platform_id=$self->store($metadata, [@list_of_platform_elements]);
  Desc: Store in the database the data of the platform object.
        If none platform element has been detailed in the arguments it will store all.
  Ret: $platform_id, the platform_id for the platform object.
  Args: $metadata, a metadata object.
        @list_of_platform_elements, is a list of elements of the platform object that can be stored independiently
        ('technology_type', 'platform', 'platform_designs', 'platform_dbxref', 'platform_spots' or/and 'platform_spots_coordinates')
  Side_Effects: modify the database
  Example: my $new_platform_id=$platform->store($metadata);
           $platform->store($metadata, ['technology_type'])

=cut

sub store {
    my $self = shift;
    my $metadata = shift || croak("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store().\n");
    my $platform_elements_aref = shift;
    my $new_platform;

    $self->check_store_conditions('store()', $metadata, $platform_elements_aref);
    
    ## The store process will be composed by:
    ##   1- Get the primary key (table_id). If it is defined and exists into the database the store process will be an UPDATE.
    ##      If it is not defined or do not exists into the database the store process will be an INSERT.
    ##   2- Both process INSERT and UPDATE will add a new metadata_id to metadata table. The metadata requeriments will be the 
    ##      follows: 
    ##               * INSERT, a new metadata_object with a metadata_id, create_date, create_person_id and obsolete=0;
    ##               * UPDATE, a new metadata_object with a metadata_id, create_date, create_person_id, modified_date, 
    ##                         modified_person_id, obsolete and obsolete_note.

    ## Each part of the platform object will be stored by a function and coordinate by the store function.

    my %substore_elements;
    if (defined $platform_elements_aref) {                            ## Get the platform elements to store from function arguments
	my @platform_elements = @{ $platform_elements_aref }; 
	foreach my $element (@platform_elements) {
	    $substore_elements{$element} = 1;
	}
    } else {                                                          ## By default it will try to store all the Platform elements
	%substore_elements = ( 'technology_types'           => 1, 
			       'platforms'                  => 1, 
			       'platforms_designs'          => 1, 
			       'platform_dbxref'            => 1, 
			       'platform_spots'             => 1, 
			       'platform_spots_coordinates' => 1);
	
    }

    my ($st_technology_type_id, $st_platform_id);
    if ( exists $substore_elements{'technology_types'} ) {
	$self->store_technology_type($metadata);
	$st_technology_type_id = $self->get_technology_type_id();            ## After store the technology_type data we set technology
	$self->set_technology_type_id($st_technology_type_id);               ## type_id for CXGN::SEDM::Schema::Platform. To do it, get
    }                                                                        ## (from CXGN::SEDM::Schema::TechnologyType) using
    if ( exists $substore_elements{'platforms'} ) {                          ## CXGN::SEDM::Platform->get_technology_type_id() and set
	$self->store_platform($metadata);                                    ## CXGN::SEDM::Schema::Platform and
	$st_platform_id = $self->get_platform_id();                          ## CXGN::SEDM::Schema::TechnologyType using the
	$self->set_platform_design_data({},{platform_id => $st_platform_id} ); ## CXGN::SEDM::Platform->set_technology_type that set both.
    }
    if ( exists $substore_elements{'platforms_designs'} ) {
	$self->store_platform_design($metadata);
    }
 
    return $st_platform_id;    
}

=head2 check_store_conditions

  Usage: $self->check_store_conditions($function, $metadata, $platform_elements_aref);
  Desc: Check if the database conection user and the metadata object are right 
  Ret: none
  Args: $function, name of the function checked and $metadata, a metadata object.
  Side_Effects: croak if there are something wrong
  Example: $self->check_store_conditions('store()', $metadata);

=cut

sub check_store_conditions {
    my $self = shift;
    my $function = shift;
    my $metadata = shift || croak("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function $function.\n");
    my $platform_elements_aref = shift;
    my $new_platform;

    ## Check that the database user can store data (so means that the database user is postgres).

    my $usercheck="SELECT current_user";    
    my $sth0=$self->get_schema->storage()->dbh()->prepare($usercheck);
    $sth0->execute();
    my ($user)=$sth0->fetchrow_array();
    if ($user ne 'postgres') {
	croak("USER ACCESS ERROR: Only postgres user can store data.\n");
    }
   
    ## Check the metadata object.

    if (ref $metadata ne 'CXGN::SEDM::Metadata') {
	croak ("FUNCTION ARGUMENT ERROR:The metadata object supplied in the $function function is not a CXGN::SEDM::Metadata object.\n");
    }

    ## Check platform_elements_aref

    if (defined $platform_elements_aref) {
	if (ref $platform_elements_aref ne 'ARRAY') {
	    croak ("FUNCTION ARGUMENT ERROR:The array reference supplied in the $function function is NOT a ARRAY REFERENCE.\n");
	} else {
	    my @platform_elements = @{ $platform_elements_aref };
	    my @allowed_elements = ('technology_types', 'platforms', 'platforms_designs', 'platforms_dbxref', 'platform_spots', 
				    'platform_spots_coordinates');
	    foreach my $element (@platform_elements) {
		my $match = 0;
		foreach my $allow_element (@allowed_elements) {
		    if ($element eq $allow_element) {
			$match = 1;
		    }
		}
		if ($match != 1) {
		    croak("FUNCTION ARGUMENT ERROR: The array element $element is not allowed as argument in the $function function.\n");
		}
	    }
	}
    }
}

=head2 store_technology_type

  Usage: $self->store_technology_type($metadata);
  Desc: Store the Platform data for technology_type. 
        This method is intrinsic of store function, so you can use it as $self->store($metadata, ['technology_type']);
  Ret: none
  Args: $metadata
  Side_Effects: none
  Example: $self->store_technology_type($metadata);

=cut

sub store_technology_type {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_technology_type().\n");
    $self->check_store_conditions('store()', $metadata);
    my $technology_type_row = $self->get_technology_type_dbic_row();
    my $technology_type_id = $self->get_technology_type_id();
    ## Exists technology_type_id? If do not exists the first question is exists another technology_type with the same name?

    if (defined $technology_type_id) {
	if ($self->exists_platform_data( { technology_types => { technology_type_id => $technology_type_id } } ) == 1) {
	    if ($technology_type_row->is_changed()) {                 ## If something change, it consider that need do an UPDATE
		my @columns_changed = $technology_type_row->is_changed();
		my @modification_note_list;
		foreach my $col_changed (@columns_changed) {
		    push @modification_note_list, "set value in $col_changed column";
		}
		my $modification_note = join ', ', @modification_note_list;
		my $technology_type_metadata_id = $self->get_technology_type_metadata_id();
		my $new_technology_type_metadata_id;
		if (defined $technology_type_metadata_id) {
		    my $u_technology_type_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                                                $metadata->get_object_creation_user(),
										$technology_type_metadata_id);
		    $u_technology_type_metadata->set_modification_note( $modification_note );
		    $u_technology_type_metadata->set_modified_person_id_by_username( $metadata->get_object_creation_user() );
		    $u_technology_type_metadata->set_modified_date( $metadata->get_object_creation_date() );
		    my $u_tech_type_metadata_id = $u_technology_type_metadata->find_or_store()->get_metadata_id();

		    ### Now we are going to set the new metadata_id in the technology_type_row object before store it.
                    ### Update all the data and set in the platform object the new_row

		    $technology_type_row = $self->set_technology_type_metadata_id( 
			$u_tech_type_metadata_id )->get_technology_type_dbic_row();
		    my $technology_type_row_updated = $technology_type_row->update()->discard_changes();              
		    $self->set_technology_type_dbic_row( $technology_type_row_updated );                  
		} else {
		    my $error = "DATA COHERENCE ERROR: The store function in CXGN::SEDM::Platform has reported a db coherence error.\n";
		    $error .= "The sed.technology_type.technology_type_id=$technology_type_id has not any metadata_id.\n";
		    $error .= "The store function can not be applied to rows with data coherence errors.\n";
		    croak($error);
		}
	    }
	} else {
	    
	   ### The technology_type_id of the platform object do not exists into the database. The store function should not update
           ### or insert primary keys without the use of the database sequence (for special cases use enforce functions). So this
	   ### should give an error and die.
	    
	    croak("DATA INTERGRITY ERROR: The technology_type_id of the platform object do not exists into the database.\n");
	}
    } else {

	## If the platform object hasn't defined the technology_type_id we consider the store function as an INSERT, but before
        ## we need check that do not exists a technology type with the same name.
	my $technology_name = $self->get_technology_type_name();
	if (defined $technology_name && $self->exists_platform_data({ technology_types => {technology_name => $technology_name} }) == 1) {
	    my $error ="DATA INTEGRITY ERROR: The technology_name:$technology_name exists into the table sed.technology_type,";
	    $error .= " but the Platform object has not any technology_type_id so it can not be stored as a new technology_type.";
	    $error .= " (the technology_name exists).\n";
	    $error .= "OPTIONS:\n\t1- Create a new Platform object using new_by_names().\n";
	    $error .= "\t2- Get the technology_type_id using ";
	    $error .= "search_platform_data_in_db(\$schema, { technlogy_type => {technology_name => $technology_name }})";
	    $error .= " and set the value using set_technology_type_id().\n";
	    croak($error);
	} else {

	    ## We can consider a real new data. So we can use insert, but before we new a metadata object.
	    my $i_technology_type_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                                        $metadata->get_object_creation_user(),
								        undef);
	    my $metadata_date = $metadata->get_object_creation_date;
	    my $metadata_user = $metadata->get_object_creation_user;
	    $i_technology_type_metadata->set_create_date( $metadata_date );
	    $i_technology_type_metadata->set_create_person_id_by_username( $metadata_user );
	    my $i_new_technology_type_metadata_object = $i_technology_type_metadata->find_or_store();
	    my $i_new_technology_type_metadata_id = $i_new_technology_type_metadata_object->get_metadata_id();
	    $self->set_technology_type_metadata_id($i_new_technology_type_metadata_id);
	    $technology_type_row = $self->get_technology_type_dbic_row();
	    my $technology_type_row_inserted = $technology_type_row->insert()->discard_changes();
	    $self->set_technology_type_dbic_row($technology_type_row_inserted);
	}
    }
}


=head2 store_platform

  Usage: $self->store_platform($metadata);
  Desc: Store the Platform data for platform (platform_id, technology_type_id, platform_name, description, contact_person_id 
        and metadata_id). 
        This method is intrinsic of store function, so you can use it as $self->store($metadata, ['platform']);
  Ret: none
  Args: $metadata
  Side_Effects: none
  Example: $self->store_technology_type($metadata);

=cut

sub store_platform {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_platform().\n");

    $self->check_store_conditions('store()', $metadata);

    my $platform_row = $self->get_platform_dbic_row();
    my $platform_id = $self->get_platform_id();

    ## Exists technology_type_id? If do not exists the first question is exists another technology_type with the same name?

    if (defined $platform_id) {
	if ($self->exists_platform_data( { platforms => { platform_id => $platform_id } } ) == 1) {
	    if ($platform_row->is_changed()) {                 ## If something change, it consider that need do an UPDATE
		my @columns_changed = $platform_row->is_changed();
		my @modification_note_list;
		foreach my $col_changed (@columns_changed) {
		    push @modification_note_list, "set value in $col_changed column";
		}
		my $modification_note = join ', ', @modification_note_list;
		my $platform_metadata_id = $self->platform_type_metadata_id();
		my $new_platform_metadata_id;
		if (defined $platform_metadata_id) {
		    my $u_platform_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                                         $metadata->get_object_creation_user(),
									 $platform_metadata_id);
		    $u_platform_metadata->set_modification_note( $modification_note );
		    $u_platform_metadata->set_modified_person_id_by_username( $metadata->get_object_creation_user() );
		    $u_platform_metadata->set_modified_date( $metadata->get_object_creation_date() );
		    my $u_platform_metadata_id = $u_platform_metadata->find_or_store()->get_metadata_id();

		    ### Now we are going to set the new metadata_id in the technology_type_row object before store it.
                    ### Update all the data and set in the platform object the new_row

		    $platform_row = $self->set_platform_metadata_id( $u_platform_metadata_id )->get_platform_dbic_row();
		    my $platform_row_updated = $platform_row->update()->discard_changes();              
		    $self->set_platform_dbic_row( $platform_row_updated );                  
		} else {
		    my $error = "DATA COHERENCE ERROR: The store function in CXGN::SEDM::Platform has reported a db coherence error.\n";
		    $error .= "The sed.platform.platform_id=$platform_id has not any metadata_id.\n";
		    $error .= "The store function can not be applied to rows with data coherence errors.\n";
		    croak($error);
		}
	    }
	} else {
	    
	   ### The platform_id of the platform object do not exists into the database. The store function should not update
           ### or insert primary keys without the use of the database sequence (for special cases use enforce functions). So this
	   ### should give an error and die.
	    
	    croak("DATA INTERGRITY ERROR: The platform_id of the platform object do not exists into the database.\n");
	}
    } else {

	## If the platform object hasn't defined the platform_id we consider the store function as an INSERT, but before
        ## we need check that do not exists a platform with the same name.

	my $platform_name = $self->get_platform_name();
	if (defined $platform_name && $self->exists_platform_data({ platforms => {platform_name => $platform_name} }) == 1) {
	    my $error ="DATA INTEGRITY ERROR: The platform_name:$platform_name exists into the table sed.platform,";
	    $error .= " but the Platform object has not any platform_id so it can not be stored as a new platform.";
	    $error .= " (the platform_name exists).\n";
	    $error .= "OPTIONS:\n\t1- Create a new Platform object using new_by_names().\n";
	    $error .= "\t2- Get the platform_id using ";
	    $error .= "search_platform_data_in_db(\$schema, { platform => {platform_name => $platform_name }})";
	    $error .= " and set the value using set_platform_id().\n";
	    croak($error);
	} else {
	    ## We can consider a real new data. So we can use insert, but before we new a metadata object.

	    my $i_platform_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                                 $metadata->get_object_creation_user(),
			       				         undef);
	    $i_platform_metadata->set_create_date( $metadata->get_object_creation_date() );
	    $i_platform_metadata->set_create_person_id_by_username( $metadata->get_object_creation_user() );
	    my $i_new_platform_metadata_object = $i_platform_metadata->find_or_store();
	    my $i_new_platform_metadata_id = $i_new_platform_metadata_object->get_metadata_id();
	    $self->set_platform_metadata_id($i_new_platform_metadata_id);
	    $platform_row = $self->get_platform_dbic_row();
	    my $platform_row_inserted = $platform_row->insert()->discard_changes();
	    $self->set_platform_dbic_row($platform_row_inserted);
	}
    }
}

=head2 store_platform_design

  Usage: $self->store_platform_design($metadata);
  Desc: Store the Platform data for platform (platform_design_id, platform_id, organism_group_id, sequence_type, dbiref_id,  
        description and metadata_id). 
        This method is intrinsic of store function, so you can use it as $self->store($metadata, ['platform_design']);
  Ret: none
  Args: $metadata, a metadata object (it can be an empty metadata object)
  Side_Effects: none
  Example: $self->store_platform_design($metadata);

=cut

sub store_platform_design {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_platform_design().\n");

    $self->check_store_conditions('store()', $metadata);

    my @platform_design_rows = $self->get_platform_design_dbic_rows();
    my @new_platform_design_rows;

    ## We stored each element using foreach function. If there isn't any platform_design_rows, foreach will not return anything.        

    foreach my $platform_design_row (@platform_design_rows) {

	## And now, it is the same that with other store subfunctions. Check if there is any platform_design_id to see if this
        ## store function will be a INSERT or an UPDATE.
	
	my $platform_design_id = $platform_design_row->get_column('platform_design_id');

	if (defined $platform_design_id) {
	    if ($self->exists_platform_data( { platforms_designs => { platform_design_id => $platform_design_id } } ) == 1) {
		## We need store the organism information, so first see if exists a group id with these information. If exists
                ## it should be in organism_group_id when the platform_design_organism_list or set_platform_design_data was set.
                ## but if not we need add a new organism_group_id

		my @organism_group = $self->get_platform_design_organism_list({ platform_design_id => $platform_design_id });
		if (scalar(@organism_group) > 0) {                       ### means that it is defined and there are a organism list
		    my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list($self->get_schema(), \@organism_group);
		    unless (defined $organism_group_id) {   ## if it is not defined, means that do not exists, so we need add a new
			$organism_group_id = $self->store_organism_group($metadata, \@organism_group);
			$platform_design_row->set_column( organism_group_id => $organism_group_id );
		    }
		}
		 
		## If something change, it consider that need do an UPDATE

		if ($platform_design_row->is_changed()) {    
		    my @columns_changed = $platform_design_row->is_changed();
		    my @modification_note_list;
		    foreach my $col_changed (@columns_changed) {
			push @modification_note_list, "set value in $col_changed column";
		    }
		    my $modification_note = join ', ', @modification_note_list;
		    my $platform_design_metadata_id = $platform_design_row->get_column('metadata_id');
		    my $new_platform_design_metadata_id;
		    if (defined $platform_design_metadata_id) {
			my $u_platform_design_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
										    $metadata->get_object_creation_user(),
										    $platform_design_metadata_id);
			$u_platform_design_metadata->set_modification_note( $modification_note );
			$u_platform_design_metadata->set_modified_person_id_by_username( $metadata->get_object_creation_user() );
			$u_platform_design_metadata->set_modified_date( $metadata->get_object_creation_date() );
			my $u_platform_design_metadata_id = $u_platform_design_metadata->find_or_store()->get_metadata_id();

			### Now we are going to set the new metadata_id in the technology_type_row object before store it.
			### Update all the data and set in the platform object the new_row

			$platform_design_row->set_column( metadata_id => $u_platform_design_metadata_id );
			my $platform_design_row_updated = $platform_design_row->update()->discard_changes();              
			push @new_platform_design_rows, $platform_design_row_updated;                  
		    } else {
			my $error = "DATA COHERENCE ERROR: The store function in CXGN::SEDM::Platform has reported a db coherence error";
			$error .= ".\nThe sed.platform_design.platform_design_id=$platform_design_id has not any metadata_id.\n";
			$error .= "The store function can not be applied to rows with data coherence errors.\n";
			croak($error);
		    }
		} else {
		    push @new_platform_design_rows, $platform_design_row;
		}
	    } else {
	    
		### The platform_design_id of the platform object do not exists into the database. The store function should not update
		### or insert primary keys without the use of the database sequence (for special cases use enforce functions). So this
		### should give an error and die.
	    
		croak("DATA INTERGRITY ERROR: The platform_design_id=$platform_design_id (platform object) do not exists into DB.\n");
	    }
	} else {

	    ## If the platform object hasn't defined the platform_design_id we consider the store function as an INSERT, but before
	    ## we need check that do not exists a platform with the same platform_id, organism_group_id and sequence_type.

	    my %data = $platform_design_row->get_columns();
	    my $platform_id = $data{'platform_id'};
	    my $organism_group_id = $data{'organism_group_id'};
	    my $sequence_type = $data{'sequence_type'};
	    my $exists_check = $self->exists_platform_data( { platforms_designs => { platform_id       => $platform_id, 
										     organism_group_id => $organism_group_id,
										     sequence_type     => $sequence_type 
										 }
							  } );
	                                                                       
	    if (defined $platform_id && defined $organism_group_id && defined $sequence_type && $exists_check == 1) {
		my $error ="DATA INTEGRITY ERROR: The platform_design with platform_id:$platform_id, ";
		$error .= "organism_group_id:$organism_group_id and sequence_type:$sequence_type exists into the table sed.platform,";
		$error .= " but the Platform object has not any platform_id so it can not be stored as a new platform.";
		$error .= " (the platform_design variables exists).\n";
		$error .= "OPTIONS:\n\t1- Create a new Platform object using new_by_names().\n";
		$error .= "\t2- Get the platform_design_id using ";
		$error .= "search_platform_data_in_db(\$schema, { platform_design => {platform_id => $platform_id, ";
		$error .= "organism_group_id => $organism_group_id, sequence_type => $sequence_type}})";
		$error .= " and set the value using set_platform_id().\n";
		croak($error);
	    } else {
 
		## We can consider a real new data. So we can use insert, but before we new an organism_group_id, 
                ## if the object have not any and a metadata object.

		my @organism_group = $self->get_platform_design_organism_list({ %data });
		if (defined($organism_group[0]) ) {                       ### means that it is defined and there are a organism list
		    my $organism_group_id = $self->get_organism_group_id_from_db_by_organism_list($self->get_schema(), \@organism_group);
		    unless (defined $organism_group_id) {   ## if it is not defined, means that do not exists, so we need add a new
			$organism_group_id = $self->store_organism_group($metadata, \@organism_group);
			$platform_design_row->set_column( organism_group_id => $organism_group_id );
		    }
		}

		my $i_platform_design_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
									    $metadata->get_object_creation_user(),
									    undef);
		$i_platform_design_metadata->set_create_date( $metadata->get_object_creation_date() );
		$i_platform_design_metadata->set_create_person_id_by_username( $metadata->get_object_creation_user() );
		my $i_new_platform_design_metadata_object = $i_platform_design_metadata->find_or_store();
		my $i_new_platform_design_metadata_id = $i_new_platform_design_metadata_object->get_metadata_id();
		$platform_design_row->set_column( metadata_id => $i_new_platform_design_metadata_id );
		my $platform_design_row_updated = $platform_design_row->insert()->discard_changes();              
		push @new_platform_design_rows, $platform_design_row_updated;  
	    }
	}
    }
    $self->set_platform_design_dbic_rows(\@new_platform_design_rows);
}

=head2 store_organism_group

 Usage: my $organism_group_id = $self->store_organism_group($metadata, [@organism_name_list]);
 Desc: Store a organism list as a new group in the sed.group and sed.group_linkage
 Ret: a new organism group_id
 Args: $metadata, a metadata object
       An array reference as $aref, \@list or [@list] of organism_names
 Side Effects: die if there are something wrong or simply do not exists the organism name into the organism table
 Example: my $organism_group_id = $platform->store_prganism_group($metadata, ['Nicotiana tabacum', 'Nicotiana sylvestris'] )

=cut

sub store_organism_group {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_organism_group().\n");
    my $organism_aref = shift;
    my $organism_group_id;
    unless (defined $organism_aref) {
	my $error = "DATA ARGUMENT ERROR: None organism group array reference was supplied to the function ";
        $error .= "CXGN::SEDM::Platform->store_organism_group()";
        croak($error);
    } elsif ( ref($organism_aref) ne 'ARRAY' ) {
	my $error2 = "DATA ARGUMENT ERROR: The variable organism_group_array_reference supplied as argument in the ";
	$error2 .= "CXGN::SEDM::Platform->store_organism_group() is not an array reference.\n";
	croak($error2);
    } else {
	my @organism_name = @{ $organism_aref };
	my %organism_ids;
	my $group_name = "OrganismGroup_";                                                        ## It will create an organism group
	foreach my $organism (@organism_name) {                                                   ## by default composed for OrganismGroup
	    my @var = split(/ /, $organism);                                                      ## _ and Gs (Genus first uppercase  
	    my $first = substr($var[0], 0, 1);                                                    ## letter and specie first lowercase   
	    my $second = substr($var[1], 0, 1);                                                   ## letter).
	    $group_name .= uc($first);
	    $group_name .= lc($second);
	    my $query = "SELECT sgn.organism.organism_id FROM sgn.organism WHERE organism_name = ?";
	    my $sth = $self->get_schema()->storage()->dbh()->prepare($query);
	    $sth->execute($organism);
	    my ($organism_id) = $sth->fetchrow_array();
	    unless (defined $organism_id) {
		my $error3 = "DATA INPUT ERROR: The organism:$organism do not exists into the sgn.organism table. ";
		$error3 .= "The function CXGN::SEDM::Platform->store_organism_group() can not store organism that do not exists into";
		$error3 .= " sgn.organism table.\n";
		croak($error3);
	    } else {
		$organism_ids{$organism_id} = $organism;
	    }
	}
	
	## We build the function to get the group_id form a list of organism_id
	my @organism_id_list = keys %organism_ids;
	my $list = join(',', @organism_id_list); 
	my $first_organism_id = shift(@organism_id_list);
	my $query = "SELECT group_id FROM sed.group_linkage WHERE member_type = 'organism' AND member_id = $first_organism_id ";
	if (scalar(@organism_id_list) > 0 ) {
	    foreach my $member (@organism_id_list) {
		$query .= "INTERSECT (SELECT group_id FROM sed.group_linkage WHERE member_id = $member) ";
	    }
	}
	$query .= "EXCEPT (SELECT group_id FROM sed.group_linkage WHERE member_id IN ($list))";     ## It do a search to check if exists
	                                                                                            ## a group_id for the organism_list
	my $sth = $self->get_schema()->storage()->dbh()->prepare($query);                           ## if exists, it will return the    
	$sth->execute();                                                                            ## group_id for the organism_list
	$organism_group_id = $sth->fetchrow_array();                                                ## The metadata will be the same
	unless (defined $organism_group_id) {                                                       ## so, it easy to know that the group
	    my $group_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(),                    ## existed before use store method
                                                            $metadata->get_object_creation_user(),  ## if it do nor exists, it will
							     undef);                                ## insert a new group with the 
	    $group_metadata->set_create_date( $metadata->get_object_creation_date() );              ## metadata of the group action
	    $group_metadata->set_create_person_id_by_username( $metadata->get_object_creation_user() );
	    my $group_metadata_object = $group_metadata->find_or_store();
	    my $group_metadata_id = $group_metadata_object->get_metadata_id();
	    my $group_description = "This is a group for the following organism list: $list";
	    my $groups_row = $self->get_schema()->resultset('Groups')->new( { name        => $group_name, 
									      description => $group_description, 
									      metadata_id => $group_metadata_id 
									   } );
	    $groups_row->insert();
	    my $new_groups_row = $groups_row->discard_changes();
	    my $new_group_id = $new_groups_row->get_column('group_id');
	    my @member_id_list = keys %organism_ids;                                                
	    foreach my $member_id (@member_id_list) {                                               
		$self->get_schema()->resultset('GroupLinkage')->new( { group_id  => $new_group_id,
	      							       member_id => $member_id,
								       member_type => 'organism',
								       metadata_id => $group_metadata_id } )->insert();
	    }
	    $organism_group_id = $new_group_id;
	}
    }
    return $organism_group_id;
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
    if ($mode eq 'die' || $mode eq 'croack') {
	$die_mode = 1;
    }
	
    my @columns_to_check = ('sgn_people.sp_person.sp_person_id', 'sgn.organism.organism_name', 'sgn.organism.organism_id');
    my @platform_db_columns = $self->get_schema()->source('Platforms')->columns();  ## Aditional columns to check of other tables
    foreach my $column_name (@platform_db_columns) {                                ## Get all the column_names for the table metadata
	my $complete_name = 'sed.platforms.';                                       ## Complete the name with schema.table
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @technology_type_db_columns = $self->get_schema()->source('TechnologyTypes')->columns();
    foreach my $column_name (@technology_type_db_columns) {
	my $complete_name = 'sed.technology_type.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @platform_design_db_columns = $self->get_schema()->source('PlatformsDesigns')->columns();
    foreach my $column_name (@platform_design_db_columns) {
	my $complete_name = 'sed.platforms_design.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @platform_dbxref_db_columns = $self->get_schema()->source('PlatformsDbxref')->columns();
    foreach my $column_name (@platform_dbxref_db_columns) {
	my $complete_name = 'sed.platforms_dbxref.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @platform_spots_db_columns = $self->get_schema()->source('PlatformSpots')->columns();
    foreach my $column_name (@platform_spots_db_columns) {
	my $complete_name = 'sed.platform_spots.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @platform_spots_coordinates_db_columns = $self->get_schema()->source('PlatformSpotCoordinates')->columns();
    foreach my $column_name (@platform_spots_coordinates_db_columns) {
	my $complete_name = 'sed.platform_spot_coordinates.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @groups = $self->get_schema()->source('Groups')->columns();
    foreach my $column_name (@groups) {
	my $complete_name = 'sed.groups.';
	$complete_name .= $column_name;
	push @columns_to_check, $complete_name;
    }
    my @groups_linkage = $self->get_schema()->source('GroupLinkage')->columns();
    foreach my $column_name (@groups_linkage) {
	my $complete_name = 'sed.group_linkage.';
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

=head2 exists_platform_data

  Usage: my $check = $self->exists_metadata( { $platform_table => { $platform_type => $platform_data } );
  Desc: Check if exists (true) or not (false) a platform_data into the database.
  Ret: $check, a scalar with $check=1 for true and $check=0 for false
  Args: $platform_data 
  Side_Effects: none
  Example: if ($self->exists_metadata_id($metadata_id, 'metadata_id') == 1) { }

=cut

sub exists_platform_data {
    my $self = shift;
    my $href = shift;
    my $check;
    my @sources = $self->get_schema()->sources();
    my $source_list = join(',', @sources);
    if (ref($href) ne 'HASH') {
	$check = 0;
    } else {
	my %tables = %{$href};
	my @tables = keys %tables;
	foreach my $table (@tables) {
	    my $table_object;
	    my @partial_names = split(/_/, $table);
	    foreach my $partial_name (@partial_names) {
		$table_object .= ucfirst $partial_name;
	    }
	    unless ($source_list =~ m/,$table_object,/) {
		$check = 0;
	    } else {
		my $search_conditions_href = $tables{$table};
		if (ref($search_conditions_href) ne 'HASH') {
		    $check = 0;
		} else {
		    my %search_conditions = %{$search_conditions_href};
		    my $db_metadata_row = $self->get_schema->resultset($table_object)->find({%search_conditions});
		    unless (defined $db_metadata_row) {
			$check = 0;
		    } else {
			$check = 1;
		    }
		}
	    }
	}
    }
    return $check;    
}


=head2 check_column_names

   Usage: $self->check_column_names(\@columns_names, $dbix_objectname, $function_name);
   Desc: check if the columns names in an array are the same that for an DBIx::Class::Resultset object
   Ret: none
   Args: \@column_names, an array reference of column_names and $function_name, the function name whered is being used this function
   Side_Effects: croak if find a couln that do not exists
   Example: $self->check_column_names(\@platform_design, 'PlatformDesign', 'add_platform_design_row')

=cut

sub check_column_names {
    my $self = shift;
    my $column_names_aref = shift;
    my $dbix_objectname = shift;
    my $function_name = shift;
	
    unless (ref $column_names_aref eq 'ARRAY') {
	croak "FUNCTION PARAMETER ERROR: The parameter $column_names_aref in the function check_column_names() is not an array ref.\n";
    }
    my @data_types = @{$column_names_aref};
    my @column_names = $self->get_schema()->source($dbix_objectname)->columns();
    foreach my $data_type (@data_types) {
	my $match = 0;
        foreach my $col (@column_names) {
	    if ($data_type eq $col) {
		$match = 1;
	    }
	}
	if ($match == 0) {
	    my $error = "DATA INPUT ERROR: The data_type (column_name) ($data_type) used in the function $function_name ";
	    $error .= "is not a column name for the $dbix_objectname table.\n";
	    croak("$error");
	}
    }
    
}

=head2 get_organism_group_id_from_db_by_organism_list

  Usage: my $organism_group_id = $class->get_organism_group_id_by_organism_list($schema, \@organism_name_list);
  Desc: Get the organism_group_id from the database (sed.group table) for a list of organism_list where obsolete=0;
  Ret: $organism_group_id, an scalar.
  Args:  $schema, a schema object.
         \@organism_name_list, an array reference of organism_names
  Side_Effects: none
  Example: my $organism_group_id = CXGN::SEDM::Platform->get_organism_group_id_by_organism_list($schema, ['Solanum lycopersicum'])

=cut

sub get_organism_group_id_from_db_by_organism_list {
    my $class = shift;
    my $schema = shift || croak( 
	"FUNCTION ARGUMENT ERROR: None argument was supplied to the function: get_organism_group_id_from_db_by_organism_name_list.\n");
    my $organism_name_list_aref = shift || croak( 
       "FUNCTION ARGUMENT ERROR:Array ref argument was not supplied to function: get_organism_group_id_by_from_db_organism_name_list.\n");

    my $organism_group_id;

    ## Check if the argument is an array reference.

    if (ref($organism_name_list_aref) ne 'ARRAY') {
	my $error = "FUNCTION ARGUMENT ERROR: The argument ($organism_name_list_aref) supplied to the function ";
	$error .= "get_organism_group_id_by_organism_name_list() IS NOT AN ARRAY REFERENCE.\n";
	croak($error);
    } else {
	my @organism_name_list = @{$organism_name_list_aref};
	my $input_organism_list = join ',', sort @organism_name_list;
	my %groups;
	
	## Get the list of group_id associated to an organism an put into a hash as key=group_id and value=array reference of
        ## organism names.
	
	foreach my $organism_name (@organism_name_list) {
	    my $query = "SELECT group_id FROM sed.group_linkage JOIN sgn.organism 
                         ON sed.group_linkage.member_id=sgn.organism.organism_id 
                         JOIN sed.metadata ON sed.group_linkage.metadata_id=sed.metadata.metadata_id
                         WHERE organism_name=? AND member_type='organism' AND obsolete=0";
	    my $sth = $schema->storage()->dbh()->prepare($query);
	    $sth->execute($organism_name);
	    while (my ($group_id) = $sth->fetchrow_array() ) {
		unless (exists $groups{$group_id}) {
		    $groups{$group_id} = [$organism_name];
		} else {
		    my @organism_list = @{ $groups{$group_id} };
		    push @organism_list, $organism_name;
		    $groups{$group_id} = \@organism_list;
		}
	    }
	}

        ## Compare if the string that comes the join function of the sort organism array is the same than the string that come from
        ## join the sorted organism_names of the arrays stored as values in the group hash. If it is the same, put the key of this
        ## hash (a group_id) as organism_group_id. If not, it will return a undef variable.

	my @keys = keys %groups;
	foreach my $key (@keys) {
	    my @organism = @{ $groups{$key} };
	    my $db_organism_list = join ',', sort @organism;
	    if ($db_organism_list eq $input_organism_list) {
		$organism_group_id = $key;
	    }
	}
    }
    return $organism_group_id;
}

=head2 get_organism_list_from_db_by_organism_group_id

  Usage: my @organism_name = CXGN::SEDM::Platform->get_organism_list_from_db_by_organism_group_id($schema, $organism_group_id);
  Desc: Get the list of organism names from the database (sed.group_linkage table) for a organism_group_id.
  Ret: @organism_name, an array with the organism names.
  Args: $schema, a schema object
        $organism_group_id, a scalar, an integer.
  Side_Effects: croak if the argument is wrong
  Example: my @organism_name = CXGN::SEDM::Platform->get_organism_list_from_db_by_organism_group_id($schema, $organism_group_id);

=cut

sub get_organism_list_from_db_by_organism_group_id {
    my $class = shift;
    my $schema = shift || croak 
        "FUNCTION ARGUMENT ERROR: None argument was supplied in the function get_organism_name_list_from_db_by_organism_group_id().\n";
    my $organism_group_id = shift || croak 
	"FUNCTION ARGUMENT ERROR: Organism_group_id argument was not supplied to get_organism_name_list_db_by_organism_group_id().\n";
    my @organism_name_list;
    unless ($organism_group_id =~ m/^\d+$/) {
	my $error = "FUNCTION ARGUMENT ERROR: The argument organism_group_id supplied in the function ";
	$error .= "get_organism_name_list_from_db_by_organism_group_id() IS NOT AN INTEGER.\n";
	croak($error);
    } else {
	my $query = "SELECT organism_name FROM sgn.organism JOIN sed.group_linkage 
                     ON sgn.organism.organism_id=sed.group_linkage.member_id WHERE group_id=?";
	my $sth = $schema->storage()->dbh()->prepare($query);
	$sth->execute($organism_group_id);
	while (my ($organism_name) = $sth->fetchrow_array() ) {
	    push @organism_name_list, $organism_name;
	}
    }
    return @organism_name_list;
}

=head2 search_platform_id

  Usage: my %table_name_rows = $class->search_platform_id($schema, { %table_name => { %table_values } });
  Desc: The search function go to the database and do a search with the parameters described in the arguments;
  Ret: A hash with keys => table_name and values => array reference with row results. 
  Args: $schema, a schema object;
        A hash reference with keys => $table_name, a scalar with the name of the table.
                         with values => a hash reference with keys => column_name and values => value to search
  Side_Effects: none
  Example:
   To get a list of platforms_ids with organism_names = 'Nicotiana tabacum'; 


=cut

sub search_platform_id {
    my $class = shift;
    my $schema = shift || 
	croak("DATA ARGUMENT ERROR: None argument was supplied to the CXGN::SEDM::Platform->search_platform_id() method.\n");
    my $search_arguments_href = shift || 
	croak("DATA ARGUMENT ERROR: The search argument was not supplied to the CXGN::SEDM::Platform->search_platform_id() method.\n");
    
    my @platform_id_list;
    my %platform_id_collection;

    if ( ref($schema) ne 'CXGN::SEDM::Schema' ) {
	my $error1 = "DATA INPUT ERROR: The argument $schema is not a DBIx::Class::Schema object (CXGN::SEDM::Schema) for the method ";
	$error1 .= " CXGN::SEDM::Platform->search_platform_id().\n";
    }
    if ( ref($search_arguments_href) ne 'HASH' ) {
	my $error2 = "DATA INPUT ERROR: The argument $search_arguments_href is not a HASH REFERENCE for the method ";
	$error2 .= "CXGN::SEDM::Platform->search_platform_id().\n";
	croak($error2);
    } else {
	my %search_arguments = %{ $search_arguments_href };
	my @tables = keys %search_arguments;
	foreach my $table (@tables) {
	    my $table_arguments_href = $search_arguments{$table};
	    if ( ref($table_arguments_href) ne 'HASH' ) {
		my $error3 = "DATA INPUT ERROR: The table argument { $table => $table_arguments_href } is not an ARRAY REFERENCE for the";
		$error3 .= " method CXGN::SEDM::Platform->serach_platform_id().\n";
		croak($error3);
	    } else {
		my $table_object;
		my @partial_names = split(/_/, $table);
		foreach my $partial_name (@partial_names) {
		    $table_object .= ucfirst $partial_name;
		}		
		my %table_arguments = %{ $table_arguments_href };
		if ( exists $table_arguments{'organism_list'} ) {
		    my $organism_group_id = $class->get_organism_group_id_from_db_by_organism_list($schema, 
												   $table_arguments{'organism_list'}
			                                                                          );
		    $table_arguments{'organism_group_id'} = $organism_group_id;
		    delete($table_arguments{'organism_list'});
		}
		my @table_rows = $schema->resultset($table_object)->search({ });
		if (defined $table_rows[0]) {
		    
		    ### Technology_type table haven't platform_id so it is better to take technology_type_id's and do a new 
		    ### search in the platforms table with these values

		    if ($table eq 'technology_types') {                 
			my @tt_table_rows;                   
			foreach my $table_row (@table_rows) {       
			    my $technology_type_id = $table_row->get_column('technology_type_id');
			    my @new_table_rows = $schema->resultset('Platforms')->search({ technology_type_id => $technology_type_id });
			    push @tt_table_rows, @new_table_rows;
			}
			@table_rows = @tt_table_rows;
		    }
		    foreach my $table_row (@table_rows) {
			my $platform_id = $table_row->get_column('platform_id');
			unless ( exists($platform_id_collection{$platform_id}) ) {           ### To remove the redundancy
			    $platform_id_collection{$platform_id} = 1;
			}
		    }
		}
	    }
	}
    }
    @platform_id_list = sort {$a <=> $b} keys %platform_id_collection;
    return @platform_id_list;
}


###########
return 1;##
###########
