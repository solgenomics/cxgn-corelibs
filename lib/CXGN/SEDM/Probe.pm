
=head1 NAME

CXGN::SEDM::Probe - a class to create and manipulate the expression database module probes.

Version:1.0

=head1 DESCRIPTION

 This class create and manipulate a expression database module probes. 

 So what is a probe object? 

   A probe object is an object that store two database objects using the DBIx::Class: 
     - a DBIx::Class::Schema object, with object of the data conection as $dbh
     - a DBIx::Class::Row object, with the data of the database or data for put into de database. 

 There are 5 CXGN::SEDM::Schema of these objects:
    - Probes
    - Primers
    - Sequences_files
    
 So the platform object are composed by FIVE OBJECTS:
    - CXGN::SEDM::Schema object
    - CXGN::SEDM::Schema::Probes row object
    - list of CXGN::SEDM::Schema::Primers row objects associated with Probes using primer_forward_id and primer_reverse_id stored as
      a hash with key = primer_row_object and value = sequence_file object associated to the primer object (if exists). 
    - CXGN::SEDM::Schema::SequencesFiles row object associated with Probes using sequence_file_id column

Structure of the probe object:

  %probe = ( probe_row             => CXGN::SEDM::Schema::Probes row object,
             primer_rows           => { primer_type => CXGN::SEDM::Schema::Primer row object };
             spots_rows            => [ CXGN::SEDM::Schema::ProbeSpots row objects ] );

  indirect methods are:
    my @spot_coordinates_rows = $class->get_spot_coordinates_rows($probe_spot_id);
    my $sequence_file = $class->get_sequence_file($sequence_file_id);



=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=head1 STANDARD METHODS

  Standard methods are methods to get, set or store data

=cut

use strict;
use warnings;

package CXGN::SEDM::Probe;

use CXGN::SEDM::Schema;
use CXGN::Chado::Dbxref;
use Carp;



########################################################
#### FIRST: The CONSTRUCTOR for the NEW OBJECT. ########
########################################################

=head2 constructor new

  Usage: my $platform = CXGN::SEDM::Probe->new($schema, $probe_id);
  Desc: Create a new probe object
  Ret: a CXGN::SEDM::Probe object
  Args: a $schema a schema object, preferentially created using:
        CXGN::SEDM::Schema->connect( sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, %other_parameters);
        a $probe_id, if $probe_id is omitted, an empty platform object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use. die if the id is not an integer.
  Example: my $platform = CXGN::SEDM::Metadata->new($schema, $probe_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift || croak("DATA ARGUMENT ERROR: Schema argument was not supplied to CXGN::SEDM::Probe->new() method\n");
    my $probe_id = shift;
    if ( defined($probe_id) ) {
	 unless ($probe_id =~ m/^\d+$/) {
	     my $error1 = "DATA ARGUMENT ERROR: The probe_id ($probe_id) IS NOT AN INTERGER for the method CXGN::SEDM::Probe";
	     $error1 .= "->new().\n";
	     croak($error1);
	}
    }
    
    ### First, bless the class to create the object and set the schema into de object.
    my $self = bless {}, $class;
    $self->set_schema($schema);

    ### Second, check that ID is an integer. If it is right go and get all the data for this row in the database. If don't find
     ### anything, give an error.

    my ($probe_row, $primer_forward_row, $primer_reverse_row);
    my (%primers);
    my (@probe_spots_rows);
    if (defined $probe_id) {	
	($probe_row) = $schema->resultset('Probes')->search({ probe_id => $probe_id });
	unless (defined $probe_row) {
	    my $error2 = "DATABASE COHERENCE ERROR: The probe_id ($probe_id) for CXGN::SEDM::Probe->new(\$schema,\$id) ";
            $error2 .= "DON'T EXISTS INTO THE DATABASE.\n";
	    $error2 .= "If you need enforce it, you can create an empty object (my \$probe = CXGN::SEDM::Probe->new";
            $error2 .= "(\$schema);) and set the variable (\$probe->set_probe_id(\$id);)";
	    croak($error2);
	} else {

	    ### Get all the objects associated with the probe
	    ## PRIMER FORWARD AND SEQUENCE FILE FOR THIS PRIMER

	    my $primer_forward_id = $probe_row->get_column('primer_forward_id');
	    if ( defined $primer_forward_id ) {
		($primer_forward_row) = $schema->resultset('Primers')->search({ primer_id => $primer_forward_id });
		if ( defined $primer_forward_row ) {
		    $primers{'primer_forward'} = $primer_forward_row;
		}
	    }

	    ## PRIMER REVERSE AND SEQUENCE FILE FOR THIS PRIMER
	    
	    my $primer_reverse_id = $probe_row->get_column('primer_reverse_id');
	    if ( defined $primer_reverse_id ) {
		($primer_reverse_row) = $schema->resultset('Primers')->search({ primer_id => $primer_reverse_id });
		if ( defined $primer_reverse_row ) {
		    $primers{'primer_reverse'} = $primer_reverse_row;
		}
	    }

	    ## PROBE SPOTS
	    @probe_spots_rows = $schema->resultset('ProbeSpots')->search({ probe_id => $probe_id });
	}
    } else {                                                                       ### If there is none argument_id it will 
	$probe_row = $schema->resultset('Probe')->new({});                         ### create an empty object with empty rows
    }

    $self->set_probe_dbic_row($probe_row);
    if ( defined($primer_forward_row) || defined($primer_reverse_row) ) {
	$self->set_primers_dbic_rows(\%primers);
    }
    if ( defined($probe_spots_rows[0]) ) {
	$self->set_probe_spots_dbic_rows(\@probe_spots_rows);
    }

    return $self;
}

########################################################
#### SECOND: General Accessor for SCHEMA.       ########
########################################################

## General Accessors for the platform object (schema, platform_row, technology_type_row, platform_design_rows, platform_dbxref_rows, 
 ## platform_spots_rows and platform_spot_coordinates_rows)

=head2 accessors get_schema, set_schema

  Usage: my $schema = $self->get_schema();
         $self->set_schema($schema);
  Desc: Get or set a schema_object into a metadata_object
  Ret:   Get => $schema, a schema object (CXGN::SEDM::Schema).
         Set => none
  Args:  Get => none
         Set => $schema, a schema object (CXGN::SEDM::Schema).
  Side_Effects: With set check if the argument is a schema_object. If fail, dies
  Example: my $schema = $self->get_schema();
           $self->set_schema($schema);

=cut

# DEPRECATED FOR THE USE OF CXGN::DB::Object as base with get and set_schema as inherits
#
#sub get_schema {
#  my $self = shift;
#  return $self->{schema}; 
#}
#
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
#### THIRD: General accessor for Probe_Row.               ########
####        Specific accessors for Probe_Data:            ########
####                * probe_id (mandatory)                ########
####                * platform_spot_id                    ########
####                * platform_id (mandatory)             ########
####                * probe_type                          ########
####                * sequence_file_id                    ########
####                * template_id (mandatory)             ########
####                * template_start                      ########
####                * template_end                        ########
####                * primer_forward_id                   ########
####                * primer_reverse_id                   ########
####                * metadata_id (mandatory)             ########
####        Special accessor to get/set probe_data        ########
##################################################################

=head2 accessors get_probe_dbic_row, set_probe_dbic_row

  Usage: my $probe_object = $self->get_probe_dbic_row();
         $self->set_probe_dbic_row($probe_object);
  Desc: Get or set a a result set object into a probe_object
  Ret:   Get => $probe_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::Probe).
         Set => none
  Args:  Get => none
         Set => $probe_row_object, a DBIx::Class::Row object (CXGN::SEDM::Schema::Probe).
  Side_Effects: With set check if the argument is a result set object. If fail, dies.
  Example: my $probe_row_object = $self->get_probe_dbic_row();
           $self->set_probe_dbic_row($probe_row_object);

=cut

sub get_probe_dbic_row {
  my $self = shift;
  return $self->{probe_row}; 
}

sub set_probe_dbic_row {
  my $self = shift;
  my $probe_row = shift || croak("FUNCTION PARAMETER ERROR: None probe_row object was supplied for set_probe_dbic_row function");
  if (ref($probe_row)  ne 'CXGN::SEDM::Schema::Probes') {
      my $error_message = "SET_PROBES_DBIC_ROW ARGUMENT ERROR: The probes_result_set_object:$probe_row ";
      $error_message .= "is not a probes_row object (package_name:CXGN::SEDM::Schema::Probes).\n";
      croak($error_message);
  }
  $self->{probe_row} = $probe_row;
}

=head2 accessors get_probe_id, set_probe_id
  
  Usage: my $probe_id=$probe->get_probe_id();
         $probe->set_probe_id($probe_id);
  Desc: get or set a probe_id in a probe object. 
  Ret:  get=> $probe_id, a scalar.
        set=> none
  Args: get=> none
        set=> $probe_id, a scalar (constraint: it must be an integer)
  Side_Effects: none
  Example: my $probe_id=$probe->get_probe_id(); 

=cut

sub get_probe_id {
  my $self=shift;
  return $self->get_probe_dbic_row->get_column('probe_id');
}

sub set_probe_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_id() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( probe_id => $data );
      $self->set_probe_dbic_row($probe_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The probe_id was not supplied for set_probe_id function\n");
  }
}

=head2 accessors get_probe_platform_id, set_probe_platform_id

  Usage: my $probe_platform_id = $probe->get_probe_platform_id();
         $probe->set_probe_platform_id($probe_platform_id);
  Desc: Get or Set the platform_id for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_platform_id, a scalar
        set=> none
  Args: get=> none
        set=> $probe_platform_id, a scalar
  Side_Effects: none
  Example: my $probe_platform_id = $probe->get_probe_platform_id();

=cut

sub get_probe_platform_id {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('platform_id'); 
}

sub set_probe_platform_id {
  my $self = shift;
  my $data = shift || croak("FUNCTION PARAMETER ERROR: None data was supplied for CXGN::SEDM::Probe->set_probe_platform_id function");
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_platform_id() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( platform_id => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_name, set_probe_name

  Usage: my $probe_name = $probe->get_probe_name();
         $probe->set_probe_name($probe_type);
  Desc: Get or Set the probe_name for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_name, a scalar
        set=> none
  Args: get=> none
        set=> $probe_name, a scalar
  Side_Effects: none
  Example: my $probe_type = $probe->get_probe_name();

=cut

sub get_probe_name {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('probe_name'); 
}

sub set_probe_name {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( probe_name => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_type, set_probe_type

  Usage: my $probe_type = $probe->get_probe_type();
         $probe->set_probe_type($probe_type);
  Desc: Get or Set the probe_type for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_type, a scalar
        set=> none
  Args: get=> none
        set=> $probe_type, a scalar
  Side_Effects: none
  Example: my $probe_type = $probe->get_probe_type();

=cut

sub get_probe_type {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('probe_type'); 
}

sub set_probe_type {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( probe_type => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_sequence_file_id, set_probe_sequence_file_id

  Usage: my $probe_sequence_file_id = $probe->get_probe_sequence_file_id();
         $probe->set_probe_sequence_file_id($probe_sequence_file_id);
  Desc: Get or Set the sequence_file_id for a CXGN::SEDM::Probe object.
  Ret:  get=> $sequence_file_id, a scalar
        set=> none
  Args: get=> none
        set=> $sequence_file_is, a scalar
  Side_Effects: none
  Example: my $sequence_file_id = $probe->get_probe_sequence_file_id();

=cut

sub get_probe_sequence_file_id {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('sequence_file_id'); 
}

sub set_probe_sequence_file_id {
  my $self = shift;
  my $data = shift; 
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_sequence_file_id() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( probe_sequence_file_id => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_template_id, set_probe_template_id

  Usage: my $probe_template_id = $probe->get_probe_template_id();
         $probe->set_probe_template_id($probe_template_id);
  Desc: Get or Set the template_id for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_template_id, a scalar
        set=> none
  Args: get=> none
        set=> $probe_template_id, a scalar
  Side_Effects: none
  Example: my $probe_template_id = $probe->get_probe_template_id();

=cut

sub get_probe_template_id {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('template_id'); 
}

sub set_probe_template_id {
  my $self = shift;
  my $data = shift || croak("FUNCTION PARAMETER ERROR: None data was supplied for CXGN::SEDM::Probe->set_probe_template_id function");
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_template_id() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( template_id => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_template_start, set_probe_template_start

  Usage: my $probe_template_start = $probe->get_probe_template_start();
         $probe->set_probe_template_start($probe_template_start);
  Desc: Get or Set the template_start for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_template_start, a scalar
        set=> none
  Args: get=> none
        set=> $probe_template_start, a scalar, an integer
  Side_Effects: none
  Example: my $probe_template_start = $probe->get_probe_template_start();

=cut

sub get_probe_template_start {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('template_start'); 
}

sub set_probe_template_start {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_template_start() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( template_start => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_probe_template_end, set_probe_template_end

  Usage: my $probe_template_end = $probe->get_probe_template_end();
         $probe->set_probe_template_end($probe_template_end);
  Desc: Get or Set the template_end for a CXGN::SEDM::Probe object.
  Ret:  get=> $probe_template_end, a scalar
        set=> none
  Args: get=> none
        set=> $probe_template_end, a scalar, an integer
  Side_Effects: none
  Example: my $probe_template_end = $probe->get_probe_template_end();

=cut

sub get_probe_template_end {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('template_end'); 
}

sub set_probe_template_end {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_probe_template_end() IS NOT AN INTEGER.\n\n");
      }
      my $probe_row = $self->get_probe_dbic_row();
      $probe_row->set_column( template_end => $data );
      $self->set_probe_dbic_row($probe_row);
  }
}

=head2 accessors get_primer_forward_id, set_primer_forward_id

  Usage: my $primer_forward_id = $probe->get_primer_forward_id();
         $probe->set_primer_forward_id($primer_forward_id);
  Desc: Get or Set the primer_forward_id for a CXGN::SEDM::Probe object.
  Ret:  get=> $primer_forward_id, a scalar
        set=> none
  Args: get=> none
        set=> $primer_forward_id, a scalar, an integer
  Side_Effects: none
  Example: my $primer_forward_id = $probe->get_primer_forward_id();

=cut

sub get_primer_forward_id {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('primer_forward_id'); 
}

sub set_primer_forward_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_primer_forward_id() IS NOT AN INTEGER.\n\n");
      }

      ### It will check here if exists or not this primer_id in the sed.primer table. If do not exists, it will return an error
      ### because after set_primer_reverse_id, will set_primer_dbic_row with this new object based in this id.

      my ($primer_row) = $self->get_schema()->resultset('Primers')->search({ primer_id => $data });
      unless (defined $primer_row) {
	  my $error = "DATA INTEGRITY ERROR: The probe_id=$data used in the CXGN::SEDM::Probe->set_primer_forward_id DO NOT EXISTS ";
	  $error .= "into the database.\n";
	  croak($error);
      } else {
	  my $primer_href = $self->get_primer_dbic_rows();
	  unless (defined $primer_href) {
	      my %primers = ( 'primer_forward' => $primer_row );
	      $primer_href = \%primers;
	  } else {
	      $primer_href->{'primer_forward'} = $primer_row;
	  }
	  $self->set_primer_dbic_rows($primer_href);
      }
  }
   
  ## Not is necessary use get_probe_row()->set_column( primer_forward_id => $primer_forward_id) because it was done in the method
  ## set_primer_dbic_rows().
  
}


=head2 accessors get_primer_reverse_id, set_primer_reverse_id

  Usage: my $primer_reverse_id = $probe->get_primer_reverse_id();
         $probe->set_primer_reverse_id($primer_reverse_id);
  Desc: Get or Set the primer_reverse_id for a CXGN::SEDM::Probe object.
  Ret:  get=> $primer_reverse_id, a scalar
        set=> none
  Args: get=> none
        set=> $primer_reverse_id, a scalar, an integer
  Side_Effects: none
  Example: my $primer_reverse_id = $probe->get_primer_reverse_id();

=cut

sub get_primer_reverse_id {
  my $self = shift;
  return $self->get_probe_dbic_row->get_column('primer_reverse_id'); 
}

sub set_primer_reverse_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The probe_id ($data) for CXGN::SEDM::Probe->set_primer_reverse_id() IS NOT AN INTEGER.\n\n");
      }

      ### It will check here if exists or not this primer_id in the sed.primer table. If do not exists, it will return an error
      ### because after set_primer_reverse_id, will set_primer_dbic_row with this new object based in this id.

      my ($primer_row) = $self->get_schema()->resultset('Primers')->search({ primer_id => $data });
      unless (defined $primer_row) {
	  my $error = "DATA INTEGRITY ERROR: The probe_id=$data used in the CXGN::SEDM::Probe->set_primer_reverse_id DO NOT EXISTS ";
	  $error .= "into the database.\n";
	  croak($error);
      } else {
	  my $primer_href = $self->get_primer_dbic_rows();
	  unless (defined $primer_href) {
	      my %primers = ( 'primer_reverse' => $primer_row );
	      $primer_href = \%primers;
	  } else {
	      $primer_href->{'primer_reverse'} = $primer_row;
	  }
	  $self->set_primer_dbic_rows($primer_href);
      }
  }
   
  ## Not is necessary use get_probe_row()->set_column( primer_reverse_id => $primer_reverse_id) because it was done in the method
  ## set_primer_dbic_rows().
  
}

=head2 accessors get_probe_metadata_id, set_probe_metadata_id

  Usage: my $probe_metadata_id=$probe->get_probe_metadata_id();
         $probe->set_probe_metadata_id($probe_metadata_id);
  Desc: get or set the probe_metadata_id for a CXGN::SEDM::Probe object from the database
  Ret:  get=> $probe_metadata_id, a scalar
        set=> none
  Args: get=> none
        set=> $probe_metadata_id, a scalar (constraint, it must be an integer)
  Side_Effects: when set is used, check that the $platform_metadata_id is an integer, if fails, die with a error message.
  Example: my $probe_metadata_id=$metadata->get_probe_metadata_id();

=cut

sub get_probe_metadata_id {
  my $self = shift;
  return $self->get_probe_dbic_row()->get_column('metadata_id'); 
}

sub set_probe_metadata_id {
  my $self = shift;
  my $data = shift;
  if (defined $data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR:The metadata_id ($data) in CXGN::SEDM::Probe->set_probe_metadata_id() IS NOT AN INTEGER.\n");
      }
      my $platform_row = $self->get_probe_dbic_row();
      $platform_row->set_column( metadata_id => $data );
      $self->set_probe_dbic_row($platform_row);
  } else {
      croak("FUNCTION PARAMETER ERROR: The paramater metadata_id was not supplied for set_probe_metadata_id function");
  }
}

=head2 accessors get_probe_data, set_probe_data

 Usage: my %probe_data = $probe->get_probe_data();
        $probe->set_probe_data({ %arguments });
 Desc: This method get and set the probe data into the CXGN::SEDM::Probe object.
       The column names are:
         - probe_id
         - platform_id,
         - probe_name,
         - probe_type,
         - sequence_file_id,
         - template_id, 
         - template_start,
         - template_end,
         - primer_forward_id,
         - primer_reverse_id 
         - metadata_id,
 Ret:  Get => A hash with keys=>column_names and values=>values
       Set => None
 Args: Get => None
       Set => A hash reference with keys=>column_names and values=>values
 Side Effects: 1- If none argument is supplied, create an empty probe_row and set the probe object with it.
               2- If the arguments not are a hash reference, die
 Example: my %probe_data = $probe->get_probe_data()
          $probe->set_probe_data( { probe_name => 'test' } );

=cut

sub get_probe_data {
  my $self = shift;
  my $probe_row = $self->get_probe_dbic_row();
  my %probe_data = $probe_row->get_columns();
  return %probe_data; 
}

sub set_probe_data {
  my $self = shift;
  my $data_href = shift;
  my $probe_row = $self->get_probe_dbic_row();
  if ( ref($data_href) eq 'HASH' ) {
      my %data = %{ $data_href };
      
      ## Check if the columns that are using are right.

      my @column_names = $self->get_schema()->source('Probes')->columns();
      my @data_types = keys %data;
      $self->check_column_names(\@data_types, 'Probes', 'set_platform_data');

      $probe_row->set_columns({%data});
  } else {
      unless (defined $data_href) {

	  ## If there aren't any argument, create a new row object.

	  $probe_row = $self->get_schema()->resultset('Probe')->new({});
      } else {
	  my $error = 'FUNCTION ARGUMENT ERROR: The argument suplied in the CXGN::SEDM::Probe->set_probe_data(\%arg) ';
	  $error .= 'is not a hash reference\n';
          croak($error);
      }
  }
  $self->{probe_row} = $probe_row;

  ## Last thing, change the probe_id for all the probe objects too.

  my $probe_id = $probe_row->get_column('probe_id');
  if (defined $probe_id && defined $self->get_probe_spots_rows()->[0] ) {
      $self->set_probe_spot_data({}, { probe_id => $probe_id } );
  }
}

##################################################################
#### FORTH: General accessor for Primers Rows             ########
####        Specific accessors for Primer Data            ########
##################################################################

=head2 accessors get_primer_dbic_rows, set_primer_dbic_rows

 Usage: my $primer_href = $probe->get_primer_dbic_rows();
        $probe->set_primer_dbic_rows(\%primer_rows);
 Desc: Get or Set the hash reference that contains the primer rows 
 Ret:  Get => A hash reference with keys => 'primer_forward' or 'primer_reverse' and values => primer_row_object
       Set => none
 Args: Get => none
       Set => A hash reference with keys => 'primer_forward' or 'primer_reverse' and values => primer_row_object
 Side Effects: 1- Die if the argument used in set is not a hash reference with @keys = ('primer_forward', 'primer_reverse');
 Example: my %primers = %{ $probe->get_primer_dbic_rows() };
          $probe->set_primer_dbic_rows( { 'primer_forward' => $primer_row_f, 'primer_reverse' => $primer_row_r } );

=cut

sub get_primer_dbic_rows {
  my $self = shift;
  return $self->{primer_rows}; 
}

sub set_primer_dbic_rows {
  my $self = shift;
  my $primer_href = shift;
  if ( defined $primer_href ) {
      unless ( ref($primer_href) ne 'HASH' ) {
	  my $error = "DATA ARGUMENT ERROR: The argument supplied in the CXGN::SEDM::Probe->set_primer_dbic_rows method is not ";
	  $error .= "a HASH REFERENCE.\n";
	  croak($error);
      } else {                                                                                    ## Check if the keys are right
	  my %primers = %{ $primer_href };
	  my $keys_list = join(' ', sort keys %primers);
	  my $error2 = "DATA ARGUMENT ERROR: The hash reference supplied as argument for the function ";
	  $error2 .= "CXGN::SEDM::Probe->set_primer_dbic_rows has not the keys 'primer_forward' AND/OR 'primer reverse'";
	  if ($keys_list eq 'primer_forward primer_reverse') {
	      ## Has the right keys
	  } elsif ($keys_list eq 'primer_forward') {
	      ## Has the right keys
	  } elsif ($keys_list eq 'primer_reverse') {
	      ## Has the right keys
	  } else {
	      ## Has the wrong keys, so must croak
	      croak($error2);
	  }
      }
  }	     
  $self->{primer_rows} = $primer_href;

  ### When set the primer_object, it will check if it have the same primer_id in the probe_row. If it is different, it will change it.

  my $primer_forward_id = $primer_href->{'primer_forward'}->get_column('primer_id');
  if (defined $primer_forward_id) {
      $self->get_probe_dbic_row()->set_column( primer_forward_id => $primer_forward_id );
  }
  my $primer_reverse_id = $primer_href->{'primer_reverse'}->get_column('primer_id');
  if (defined $primer_reverse_id) {
      $self->get_probe_dbic_row()->set_column( primer_reverse_id => $primer_reverse_id );
  }  
}

=head2 accessors get_primer_id

 Usage: my $primer_id_href = $probe->get_primer_id();
        my $primer_forward_id = $probe->get_primer_id('primer_forward');
        my $primer_reverse_id = $probe->get_primer_id('primer_reverse');
 Desc: Get the primer_id from the primer_row objects store in the CXGN::SEDM::Probe object.
       Set has been replaces by the set_forward_primer_id and set_reverse_primer_id
 Ret: A hash reference without any argument with key='primer_forward' or 'primer_reverse' and values=primer_ids
      A scalar when is specified the primer_type
 Args: None or a scalar, $primer_type ('primer_forward' or 'primer_reverse') 
 Side Effects: None
 Example: my $primer_id_href = $probe->get_primer_id();
          my $primer_forward_id = $probe->get_primer_id('primer_forward');
          my $primer_reverse_id = $probe->get_primer_id('primer_reverse');

=cut

sub get_primer_id {
  my $self = shift;
  my $primer_type = shift;
  my $primer_rows_href = $self->get_primer_dbic_rows();
  if (defined $primer_rows_href) {
      my %primer_rows = %{ $primer_rows_href };
      my @object_primer_types = keys %primer_rows;
      if (defined $primer_type) {
	  my $primer_row = $primer_rows{$primer_type};
	  if (defined $primer_row) {
	      return $primer_row->get_column('primer_id');
	  }
      } else {
	  my %primer_ids;
	  foreach my $object_primer_type (@object_primer_types) {
	      my $obj_primer_row = $primer_rows{$object_primer_type};
	      if (defined $obj_primer_row) {
		  my $primer_id = $obj_primer_row->get_column('primer_id');
		  $primer_ids{$object_primer_type} = $primer_id;
	      }
	  }
	  return \%primer_ids;
      }
  } else {
      return undef;
  }
}

=head2 accessors get_primer_name, set_primer_name

 Usage: my $primer_name_href = $probe->get_primer_name();
        my $primer_forward_name = $probe->get_primer_name('primer_forward');
        my $primer_reverse_name = $probe->get_primer_name('primer_reverse');
        $probe->set_primer_name({ primer_forward => $primer_name, primer_reverse => $primer_name });
 Desc: Get or Set the primer_name from the primer_row objects store in the CXGN::SEDM::Probe object.
 Ret:  Get => A hash reference without any argument with key='primer_forward' or 'primer_reverse' and values=primer_ids
              A scalar when is specified the primer_type.
       Set => None
 Args: Get => None or a scalar, $primer_type ('primer_forward' or 'primer_reverse')
       Set => A hash reference with keys=primer_type and values=primer_names 
 Side Effects: For set, die if it is used the wrong argumnent (something different of a hash reference with keys='primer_forward' or
               primer_reverse)
 Example: my $primer_id_href = $probe->get_primer_id();
          my $primer_forward_id = $probe->get_primer_id('primer_forward');
          my $primer_reverse_id = $probe->get_primer_id('primer_reverse');
 
=cut

sub get_primer_name {
  my $self = shift;
  my $primer_type = shift;
  my $primer_rows_href = $self->get_primer_dbic_rows();
  if (defined $primer_rows_href) {
      my %primer_rows = %{ $primer_rows_href };
      my @object_primer_types = keys %primer_rows;
      if (defined $primer_type) {
	  my $primer_row = $primer_rows{$primer_type};
	  if (defined $primer_row) {
	      return $primer_row->get_column('primer_name');
	  }
      } else {
	  my %primer_names;
	  foreach my $object_primer_type (@object_primer_types) {
	      my $obj_primer_row = $primer_rows{$object_primer_type};
	      if (defined $obj_primer_row) {
		  my $primer_name = $obj_primer_row->get_column('primer_name');
		  $primer_names{$object_primer_type} = $primer_name;
	      }
	  }
	  return \%primer_names;
      }
  } else {
      return undef;
  }
}

sub set_primer_name {
  my $self = shift;
  my $primer_hash = shift || 
      croak("DATA ARGUMENT ERROR: None argument was supplied in the method CXGN::SEDM::Probe->set_primer_name().\n");
  unless ( ref($primer_hash) ne 'HASH') {
      croak("DATA ARGUMENT ERROR: The argument supplied in the method CXGN::SEDM::Probe->set_primer_name() is not a hash reference.\n");
  } else {
   
      ## Check if the keys are 'primer_forward' and/or 'primer_reverse'  

      my @primers_types = keys %{$primer_hash};
      foreach my $primer_type (@primers_types) {
	  unless ($primer_type ne 'primer_forward' or $primer_type ne 'primer_reverse') {
	      my $error = "DATA ARGUMENT ERROR: The key ($primer_type) used as argument in the method CXGN::SEDM::Probe->set_primer_name";
	      $error .= "() is a non-permited key (only are permited 'primer_forward' and 'primer_reverse').\n";
	      croak($error);
	  }
      }

      ## Get the primer_names from the argument and the rows form the probe object
      
      my $primer_forward_name = $primer_hash->{'primer_forward'};
      my $primer_reverse_name = $primer_hash->{'primer_reverse'};
      my $primer_rows_href = $self->get_primer_dbic_rows();

      ## There are two possibilities, that exists or does not exists a value for the key=primer_rows in the object. If exists, 
      ## it ask if exists each primer_type and if do not exists it will create a new row with the primer_name. If do not exists
      ## it will create a new primer_row value with the hash with the primer_rows for primer_forward and/or primer_reverse 

      if (defined $primer_rows_href) {
	  if (defined $primer_rows_href->{'primer_forward'} && defined $primer_forward_name ) {
	      $primer_rows_href->{'primer_forward'}->set_column( primer_name => $primer_forward_name );
	  } elsif ( defined $primer_forward_name ) {
	      $primer_rows_href->{'primer_forward'} = $self->get_schema()
                                                           ->resulset('Primers')
                                                           ->new_result( { primer_name => $primer_forward_name } );
	  }
	  if (defined $primer_rows_href->{'primer_reverse'} && defined $primer_reverse_name ) {
	       $primer_rows_href->{'primer_reverse'}->set_column( primer_name => $primer_reverse_name );
	  } elsif (defined $primer_reverse_name ) {
	       $primer_rows_href->{'primer_reverse'} = $self->get_schema()
                                                            ->resulset('Primers')
                                                            ->new_result( { primer_name => $primer_reverse_name } );
	  }
      } else {
	  my %primer_rows;
	  if ( defined $primer_forward_name ) {
	      $primer_rows{'primer_forward'} = $self->get_schema()
                                                ->resulset('Primers')
                                                ->new_result( { primer_name => $primer_forward_name } );
	  }
	  if (defined $primer_reverse_name ) {
	       $primer_rows{'primer_reverse'} = $self->get_schema()
                                                 ->resulset('Primers')
                                                 ->new_result( { primer_name => $primer_reverse_name } );
	  }
	  $primer_rows_href = \%primer_rows;
      }
      $self->set_primer_dbic_rows($primer_rows_href);
  }
}

=head2 accessors get_primer_sequence_file_id, set_primer_sequence_file_id

 Usage: my $primer_sequence_file_id_href = $probe->get_primer_sequence_file_id();
        my $primer_forward_sequence_file_id = $probe->get_primer_sequence_file_id('primer_forward');
        my $primer_reverse_sequence_file_id = $probe->get_primer_sequence_file_id('primer_reverse');
        $probe->set_primer_sequence_file({ primer_forward => $primer_sequence_file_id, primer_reverse => $primer_sequence_file_id });
 Desc: Get or Set the sequence_file_id from the primer_row objects store in the CXGN::SEDM::Probe object.
 Ret:  Get => A hash reference without any argument with key='primer_forward' or 'primer_reverse' and values=sequence_file_id
              A scalar when is specified the primer_type.
       Set => None
 Args: Get => None or a scalar, $primer_type ('primer_forward' or 'primer_reverse')
       Set => A hash reference with keys=primer_type and values=sequence_file_id
 Side Effects: For set, die if it is used the wrong argumnent (something different of a hash reference with keys='primer_forward' or
               primer_reverse) or if is used a sequence_file_id that do not exists into the database
 Example:  my $primer_sequence_file_id_href = $probe->get_primer_sequence_file_id();
           my $primer_forward_sequence_file_id = $probe->get_primer_sequence_file_id('primer_forward');
           my $primer_reverse_sequence_file_id = $probe->get_primer_sequence_file_id('primer_reverse');
           $probe->set_primer_sequence_file({ primer_forward => $primer_sequence_file_id, primer_reverse => $primer_sequence_file_id });
=cut

sub get_primer_sequence_file_id {
  my $self = shift;
  my $primer_type = shift;
  my $primer_rows_href = $self->get_primer_dbic_rows();
  if (defined $primer_rows_href) {
      my %primer_rows = %{ $primer_rows_href };
      my @object_primer_types = keys %primer_rows;
      if (defined $primer_type) {
	  my $primer_row = $primer_rows{$primer_type};
	  if (defined $primer_row) {
	      return $primer_row->get_column('sequence_file_id');
	  }
      } else {
	  my %primer_sequence_file_ids;
	  foreach my $object_primer_type (@object_primer_types) {
	      my $obj_primer_row = $primer_rows{$object_primer_type};
	      if (defined $obj_primer_row) {
		  my $primer_sequence_file_id = $obj_primer_row->get_column('sequence_file_id');
		  $primer_sequence_file_ids{$object_primer_type} = $primer_sequence_file_id;
	      }
	  }
	  return \%primer_sequence_file_ids;
      }
  } else {
      return undef;
  }
}

sub set_primer_sequence_file_id {
  my $self = shift;
  my $primer_hash = shift || 
      croak("DATA ARGUMENT ERROR: None argument was supplied in the method CXGN::SEDM::Probe->set_primer_sequence_file_id().\n");
  unless ( ref($primer_hash) ne 'HASH') {
      my $error0 = "DATA ARGUMENT ERROR: The argument supplied in the method CXGN::SEDM::Probe->set_primer_sequence_file() ";
      $error0 = "is not a hash reference.\n";
      croak($error0);
  } else {
   
      ## Check if the keys are 'primer_forward' and/or 'primer_reverse'  

      my @primers_types = keys %{$primer_hash};
      foreach my $primer_type (@primers_types) {
	  unless ($primer_type ne 'primer_forward' or $primer_type ne 'primer_reverse') {
	      my $error1 = "DATA ARGUMENT ERROR: The key ($primer_type) used as argument in the method CXGN::SEDM::Probe->set";
	      $error1 .= "_primer_sequence_file_id() is a non-permited key (only are permited 'primer_forward' and 'primer_reverse').\n";
	      croak($error1);
	  }
      }

      ## Get the primer_names from the argument and the rows form the probe object
      
      my $primer_forward_sequence_file_id = $primer_hash->{'primer_forward'};
      if (defined $primer_forward_sequence_file_id) {
	  unless ($self->get_schema()->exists_data('sequence_files', 'sequence_file_id', $primer_forward_sequence_file_id)) {
	      my $error2 = "DATA ARGUMENT ERROR: The value (primer_forward => $primer_forward_sequence_file_id) used as argument in the ";
	      $error2 .= "method CXGN::SEDM::Probe->set_primer_sequence_file_id() does not exists into the sed.sequence_file table.\n";
	      croak($error2);
	  }
      }
      my $primer_reverse_sequence_file_id = $primer_hash->{'primer_reverse'};
      if (defined $primer_reverse_sequence_file_id) {
	  unless ($self->get_schema()->exists('sequence_files', 'sequence_file_id', $primer_reverse_sequence_file_id)) {
	      my $error3 = "DATA ARGUMENT ERROR: The value (primer_reverse => $primer_reverse_sequence_file_id) used as argument in the ";
	      $error3 .= "method CXGN::SEDM::Probe->set_primer_sequence_file_id() does not exists into the sed.sequence_file table.\n";
	      croak($error3);
	  }
      }
      my $primer_rows_href = $self->get_primer_dbic_rows();

      ## There are two possibilities, that exists or does not exists a value for the key=primer_rows in the object. If exists, 
      ## it ask if exists each primer_type and if do not exists it will create a new row with the primer_name. If do not exists
      ## it will create a new primer_row value with the hash with the primer_rows for primer_forward and/or primer_reverse 

      if (defined $primer_rows_href) {
	  if (defined $primer_rows_href->{'primer_forward'} && defined $primer_forward_sequence_file_id ) {
	      $primer_rows_href->{'primer_forward'}->set_column( sequence_file_id => $primer_forward_sequence_file_id );
	  } elsif ( defined $primer_forward_sequence_file_id ) {
	      $primer_rows_href->{'primer_forward'} = $self->get_schema()
                                                           ->resulset('Primers')
                                                           ->new_result( { sequence_file_id => $primer_forward_sequence_file_id } );
	  }
	  if (defined $primer_rows_href->{'primer_reverse'} && defined $primer_reverse_sequence_file_id ) {
	       $primer_rows_href->{'primer_reverse'}->set_column( sequence_file_id => $primer_reverse_sequence_file_id );
	  } elsif (defined $primer_reverse_sequence_file_id ) {
	       $primer_rows_href->{'primer_reverse'} = $self->get_schema()
                                                            ->resulset('Primers')
                                                            ->new_result( { sequence_file_id => $primer_reverse_sequence_file_id } );
	  }
      } else {
	  my %primer_rows;
	  if ( defined $primer_forward_sequence_file_id ) {
	      $primer_rows{'primer_forward'} = $self->get_schema()
                                                ->resulset('Primers')
                                                ->new_result( { sequence_file_id => $primer_forward_sequence_file_id } );
	  }
	  if (defined $primer_reverse_sequence_file_id ) {
	       $primer_rows{'primer_reverse'} = $self->get_schema()
                                                 ->resulset('Primers')
                                                 ->new_result( { sequence_file_id => $primer_reverse_sequence_file_id } );
	  }
	  $primer_rows_href = \%primer_rows;
      }
      $self->set_primer_dbic_rows($primer_rows_href);
  }
}

=head2 accessors get_primer_metadata_id, set_primer_metadata_id

 Usage: my $primer_metadata_id_href = $probe->get_primer_metadata_id();
        my $primer_forward_metadata_id = $probe->get_primer_metadata_id('primer_forward');
        my $primer_reverse_metadata_id = $probe->get_primer_metadata_id('primer_reverse');
        $probe->set_primer_metadata({ primer_forward => $primer_metadata_id, primer_reverse => $primer_metadata_id });
 Desc: Get or Set the metadata_id from the primer_row objects store in the CXGN::SEDM::Probe object.
 Ret:  Get => A hash reference without any argument with key='primer_forward' or 'primer_reverse' and values=metadata_id
              A scalar when is specified the primer_type.
       Set => None
 Args: Get => None or a scalar, $primer_type ('primer_forward' or 'primer_reverse')
       Set => A hash reference with keys=primer_type and values=metadata_id
 Side Effects: For set, die if it is used the wrong argumnent (something different of a hash reference with keys='primer_forward' or
               primer_reverse) or if is used a metadata_id that do not exists into the database
 Example:  my $primer_metadata_id_href = $probe->get_primer_metadata_id();
           my $primer_forward_metadata_id = $probe->get_primer_metadata_id('primer_forward');
           my $primer_reverse_metadata_id = $probe->get_primer_metadata_id('primer_reverse');
           $probe->set_primer_metadata({ primer_forward => $metadata_id, primer_reverse => $metadata_id });
=cut

sub get_primer_metadata_id {
  my $self = shift;
  my $primer_type = shift;
  my $primer_rows_href = $self->get_primer_dbic_rows();
  if (defined $primer_rows_href) {
      my %primer_rows = %{ $primer_rows_href };
      my @object_primer_types = keys %primer_rows;
      if (defined $primer_type) {
	  my $primer_row = $primer_rows{$primer_type};
	  if (defined $primer_row) {
	      return $primer_row->get_column('metadata_id');
	  }
      } else {
	  my %primer_metadata_ids;
	  foreach my $object_primer_type (@object_primer_types) {
	      my $obj_primer_row = $primer_rows{$object_primer_type};
	      if (defined $obj_primer_row) {
		  my $primer_metadata_id = $obj_primer_row->get_column('metadata_id');
		  $primer_metadata_ids{$object_primer_type} = $primer_metadata_id;
	      }
	  }
	  return \%primer_metadata_ids;
      }
  } else {
      return undef;
  }
}

sub set_primer_metadata_id {
  my $self = shift;
  my $primer_hash = shift || 
      croak("DATA ARGUMENT ERROR: None argument was supplied in the method CXGN::SEDM::Probe->set_primer_metadata_id().\n");
  unless ( ref($primer_hash) ne 'HASH') {
      my $error0 = "DATA ARGUMENT ERROR: The argument supplied in the method CXGN::SEDM::Probe->set_primer_metadata_id() ";
      $error0 = "is not a hash reference.\n";
      croak($error0);
  } else {
   
      ## Check if the keys are 'primer_forward' and/or 'primer_reverse'  

      my @primers_types = keys %{$primer_hash};
      foreach my $primer_type (@primers_types) {
	  unless ($primer_type ne 'primer_forward' or $primer_type ne 'primer_reverse') {
	      my $error1 = "DATA ARGUMENT ERROR: The key ($primer_type) used as argument in the method CXGN::SEDM::Probe->set";
	      $error1 .= "_primer_metadata_id() is a non-permited key (only are permited 'primer_forward' and 'primer_reverse').\n";
	      croak($error1);
	  }
      }

      ## Get the primer_names from the argument and the rows form the probe object
      
      my $primer_forward_metadata_id = $primer_hash->{'primer_forward'};
      if (defined $primer_forward_metadata_id) {
	  unless ($self->get_schema()->exists_data('metadata', 'metadata_id', $primer_forward_metadata_id)) {
	      my $error2 = "DATA ARGUMENT ERROR: The value (primer_forward => $primer_forward_metadata_id) used as argument in the ";
	      $error2 .= "method CXGN::SEDM::Probe->set_primer_metadata_id() does not exists into the sed.metadata table.\n";
	      croak($error2);
	  }
      }
      my $primer_reverse_metadata_id = $primer_hash->{'primer_reverse'};
      if (defined $primer_reverse_metadata_id) {
	  unless ($self->get_schema()->exists_data('metadata', 'metadata_id', $primer_reverse_metadata_id)) {
	      my $error3 = "DATA ARGUMENT ERROR: The value (primer_reverse => $primer_reverse_metadata_id) used as argument in the ";
	      $error3 .= "method CXGN::SEDM::Probe->set_primer_metadata_id() does not exists into the sed.metadata table.\n";
	      croak($error3);
	  }
      }
      my $primer_rows_href = $self->get_primer_dbic_rows();

      ## There are two possibilities, that exists or does not exists a value for the key=primer_rows in the object. If exists, 
      ## it ask if exists each primer_type and if do not exists it will create a new row with the metadata_id. If do not exists
      ## it will create a new primer_row value with the hash with the primer_rows for primer_forward and/or primer_reverse 

      if (defined $primer_rows_href) {
	  if (defined $primer_rows_href->{'primer_forward'} && defined $primer_forward_metadata_id ) {
	      $primer_rows_href->{'primer_forward'}->set_column( metadata_id => $primer_forward_metadata_id );
	  } elsif ( defined $primer_forward_metadata_id ) {
	      $primer_rows_href->{'primer_forward'} = $self->get_schema()
                                                           ->resulset('Primers')
                                                           ->new_result( { metadata_id => $primer_forward_metadata_id } );
	  }
	  if (defined $primer_rows_href->{'primer_reverse'} && defined $primer_reverse_metadata_id ) {
	       $primer_rows_href->{'primer_reverse'}->set_column( metadata_id => $primer_reverse_metadata_id );
	  } elsif (defined $primer_reverse_metadata_id ) {
	       $primer_rows_href->{'primer_reverse'} = $self->get_schema()
                                                            ->resulset('Primers')
                                                            ->new_result( { metadata_id => $primer_reverse_metadata_id } );
	  }
      } else {
	  my %primer_rows;
	  if ( defined $primer_forward_metadata_id ) {
	      $primer_rows{'primer_forward'} = $self->get_schema()
                                                ->resulset('Primers')
                                                ->new_result( { sequence_file_id => $primer_forward_metadata_id } );
	  }
	  if (defined $primer_reverse_metadata_id ) {
	       $primer_rows{'primer_reverse'} = $self->get_schema()
                                                 ->resulset('Primers')
                                                 ->new_result( { metadata_id => $primer_reverse_metadata_id } );
	  }
	  $primer_rows_href = \%primer_rows;
      }
      $self->set_primer_dbic_rows($primer_rows_href);
  }
}

=head2 accessors get_primer_data, set_primer_data

 Usage: my $primer_data_href = $probe->get_primer_data();
        my $primer_forward_data = $probe->get_primer_data('primer_forward');
        my $primer_reverse_data = $probe->get_primer_data('primer_reverse');
        $probe->set_primer_metadata({ primer_forward => { $col => $data } , primer_reverse => { $col => $data } });
 Desc: Get or Set the data from the primer_row objects store in the CXGN::SEDM::Probe object.
 Ret:  Get => Without any argument, a hash reference with key='primer_forward' or 'primer_reverse' and values=hash reference with
                  keys=column_name and values=value of the row for this column name
              If is specified the primer_type, a hash reference with keys=column_names and values=value of the row for this column name
       Set => None
 Args: Get => None or a scalar, $primer_type ('primer_forward' or 'primer_reverse')
       Set => A hash reference with keys=primer_type and values= a hash reference with keys=column_name and values=row_value
 Side Effects: For set, die if it is used the wrong argumnent (something different of a hash reference with keys='primer_forward' or
               primer_reverse) or if is used a any primer_id, sequence_file_id or metadata_id that do not exists into the database.
               Also the columns primer_forward_id and primer_reverse_id will be set for the probe row object
 Example:  my $primer_data_href = $probe->get_primer_data();
           my $primer_forward_data = $probe->get_primer_data('primer_forward');
           my $primer_reverse_data = $probe->get_primer_data('primer_reverse');
           $probe->set_primer_metadata({  primer_forward => {
                                                              primer_id   => $primer_id1,
                                                              primer_name => $primer_name1,
                                                              metadata_id => $metadata_id  
                                                            }
                                          primer_reverse => {
                                                              primer_id   => $primer_id2,
                                                              primer_name => $primer_name2,
                                                              metadata_id => $metadata_id  
                                                            }
                                        } );
=cut

sub get_primer_data {
  my $self = shift;
  my $primer_type = shift;
  my $primer_rows_href = $self->get_primer_dbic_rows();
  if (defined $primer_rows_href) {
      my %primer_rows = %{ $primer_rows_href };
      my @object_primer_types = keys %primer_rows;
      if (defined $primer_type) {
	  my $primer_row = $primer_rows{$primer_type};
	  if (defined $primer_row) {
	      return $primer_row->get_columns();
	  }
      } else {
	  my %primer_data;
	  foreach my $object_primer_type (@object_primer_types) {
	      my $obj_primer_row = $primer_rows{$object_primer_type};
	      if (defined $obj_primer_row) {
		  my $primer_data_href = $obj_primer_row->get_columns();
		  $primer_data{$object_primer_type} = $primer_data_href;
	      }
	  }
	  return \%primer_data;
      }
  } else {
      return undef;
  } 
}

sub set_primer_data {
  my $self = shift;
  my $primer_hash = shift || 
      croak("DATA ARGUMENT ERROR: None argument was supplied in the method CXGN::SEDM::Probe->set_primer_metadata_id().\n");
  unless ( ref($primer_hash) ne 'HASH') {
      my $error0 = "DATA ARGUMENT ERROR: The argument supplied in the method CXGN::SEDM::Probe->set_primer_metadata_id() ";
      $error0 = "is not a hash reference.\n";
      croak($error0);
  } else {
   
      ## Check if the keys are 'primer_forward' and/or 'primer_reverse', if they have hash references associated and if the columns 
      ## names are right  

      my @primers_types = keys %{$primer_hash};
      foreach my $primer_type (@primers_types) {
	  unless ($primer_type ne 'primer_forward' or $primer_type ne 'primer_reverse') {
	      my $error1 = "DATA ARGUMENT ERROR: The key ($primer_type) used as argument in the method CXGN::SEDM::Probe->set";
	      $error1 .= "_primer_metadata_id() is a non-permited key (only are permited 'primer_forward' and 'primer_reverse').\n";
	      croak($error1);
	  }
	  unless (ref($primer_hash->{$primer_type}) eq 'HASH') {
	      my $error2 = "DATA ARGUMENT ERROR: The value ( $primer_hash->{$primer_type} ) used as argument in the method ";
	      $error2 .= "CXGN::SEDM::Probe->set_primer_metadata_id() is not a HASH REFERENCE).\n";
	      croak($error2);
	  } else {
	      my @column_names = keys %{ $primer_hash->{$primer_type} };
	      foreach my $col (@column_names) {
		  unless ($col =~ m/^[primer_id|primer_name|sequence_file_id|metadata_id]$/ ) {
		       my $error3 = "DATA ARGUMENT ERROR: The column_name ( $col ) used as argument in the method ";
		       $error3 .= "CXGN::SEDM::Probe->set_primer_metadata_id() is not a sed.primer column).\n";
		       croak($error3);
		  }
	      }
	  }
      }
      
      ## Get the primer_data from the argument and the rows form the probe object and check it
      
      my @primers = keys %{ $primer_hash };
      foreach my $primer (@primers) {
	  if (defined $primer_hash->{$primer}) {
	      my $error4;
	      my $primer_id = $primer_hash->{$primer}->{'primer_id'};
	      my $primer_sequence_file_id = $primer_hash->{$primer}->{'sequence_file_id'};
	      my $primer_metadata_id = $primer_hash->{$primer}->{'metadata_id'};
	      if (defined $primer_id) {
		  unless ($self->get_schema()->exists_data('primers', 'primer_id', $primer_id)) {
		      $error4 .= "The primers.primer_id=$primer_id used as argument in ";
		      $error4 .= "CXGN::SEDM::Probe->set_primer_data() do not exists in the sed.primer table.\n";
		  }
	      }
	      if (defined $primer_sequence_file_id) {
		  unless ($self->get_schema()->exists_data('primers', 'sequence_file_id', $primer_sequence_file_id)) {
		      $error4 .= "The primers.primer_id=$primer_sequence_file_id used as argument in ";
		      $error4 .= "CXGN::SEDM::Probe->set_primer_data() do not exists in the sed.primer table.\n";
		  }
	      }
	      if (defined $primer_metadata_id) {
		  unless ($self->get_schema()->exists_data('primers', 'sequence_file_id', $primer_sequence_file_id)) {
		      $error4 .= "The primers.primer_metadata_id=$primer_metadata_id used as argument in ";
		      $error4 .= "CXGN::SEDM::Probe->set_primer_data() do not exists in the sed.primer table.\n";
		  }
	      }
	      if (defined $error4) {
		  croak("DATA INPUT ERROR for $primer : $error4");
	      }
	  }
      }
      my $primer_forward_data = $primer_hash->{'primer_forward'};
      my $primer_reverse_data = $primer_hash->{'primer_reverse'};
      my $primer_rows_href = $self->get_primer_dbic_rows();

      ## There are two possibilities, that exists or does not exists a value for the key=primer_rows in the object. If exists, 
      ## it ask if exists each primer_type and if do not exists it will create a new row with the metadata_id. If do not exists
      ## it will create a new primer_row value with the hash with the primer_rows for primer_forward and/or primer_reverse 

      if (defined $primer_rows_href) {
	  if (defined $primer_rows_href->{'primer_forward'} && defined $primer_forward_data ) {
	      $primer_rows_href->{'primer_forward'}->set_columns($primer_forward_data);
	  } elsif ( defined $primer_forward_data ) {
	      $primer_rows_href->{'primer_forward'} = $self->get_schema()->resulset('Primers')->new_result($primer_forward_data);
	  }
	  if (defined $primer_rows_href->{'primer_reverse'} && defined $primer_reverse_data ) {
	       $primer_rows_href->{'primer_reverse'}->set_column($primer_reverse_data);
	  } elsif (defined $primer_reverse_data ) {
	       $primer_rows_href->{'primer_reverse'} = $self->get_schema()->resulset('Primers')->new_result($primer_reverse_data);
	  }
      } else {
	  my %primer_rows;
	  if ( defined $primer_forward_data ) {
	      $primer_rows{'primer_forward'} = $self->get_schema()->resulset('Primers')->new_result( $primer_forward_data );
	  }
	  if (defined $primer_reverse_data ) {
	       $primer_rows{'primer_reverse'} = $self->get_schema()->resulset('Primers')->new_result( $primer_reverse_data );
	  }
	  $primer_rows_href = \%primer_rows;
      }
      $self->set_primer_dbic_rows($primer_rows_href);
  }
}




##################################################################
#### FIFTH: General accessor for ProbeSpots rows          ########
####        Specific accessors for ProbeSpots_Data        ########
##################################################################

############################# IN PROCESS ##########################



###################################################################
#### STORE FUNCTIONS: General store function               ########                                    
####                  Store condition check method         ########
####                  Specific store function for objects  ########
###################################################################

=head2 store

  Usage: my $platform_id=$self->store($metadata, [@list_of_probe_elements]);
  Desc: Store in the database the data of the probe object.
        If none probe element has been detailed in the arguments it will store all.
  Ret: $probe_id, the platform_id for the platform object.
  Args: $metadata, a metadata object.
        @list_of_probe_elements, is a list of elements of the probe object that can be stored independiently
        ('probes', 'primers')
  Side_Effects: modify the database
  Example: my $new_probe_id=$probe->store($metadata);
           $probe->store($metadata, ['probe'])

=cut

sub store {
    my $self = shift;
    my $metadata = shift || croak("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store().\n");
    my $probe_elements_aref = shift;
    my $new_platform;

    $self->check_store_conditions('store()', $metadata, $probe_elements_aref);
    
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
    if (defined $probe_elements_aref) {                               ## Get the probe elements to store from function arguments
	my @probe_elements = @{ $probe_elements_aref }; 
	foreach my $element (@probe_elements) {
	    $substore_elements{$element} = 1;
	}
    } else {                                                          ## By default it will try to store all the Platform elements
	%substore_elements = ( 'probe'           => 1, 
			       'primers'         => 1, 
	                      );
    }

    my ($st_probe_id);
    if ( exists $substore_elements{'primers'} ) {
	$self->store_primers($metadata);
	my $st_primer_forward_id = $self->get_primer_id('primer_forward');
        my $st_primer_reverse_id = $self->get_primer_id('primer_reverse');
	$self->set_primer_forward_id($st_primer_forward_id);
	$self->set_primer_reverse_id($st_primer_reverse_id);	                                                                     
    }                                                                        
    if ( exists $substore_elements{'probe'} ) {                          
	$self->store_probe($metadata);                                   
	$st_probe_id = $self->get_probe_id();
    }
 
    return $st_probe_id;    
}

=head2 check_store_conditions

  Usage: $self->check_store_conditions($function, $metadata, $probe_elements_aref);
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
    my $probe_elements_aref = shift;
    my $new_probe;

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

    ## Check probe_elements_aref

    if (defined $probe_elements_aref) {
	if (ref $probe_elements_aref ne 'ARRAY') {
	    croak ("FUNCTION ARGUMENT ERROR:The array reference supplied in the $function function is NOT a ARRAY REFERENCE.\n");
	} else {
	    my @probe_elements = @{ $probe_elements_aref };
	    my @allowed_elements = ('primers', 'probes');
	    foreach my $element (@probe_elements) {
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

=head2 store_primers

  Usage: $self->store_primers($metadata);
  Desc: Store the primers data for technology_type. 
        This method is intrinsic of store function, so you can use it as $self->store($metadata, ['primers']);
  Ret: none
  Args: $metadata
  Side_Effects: none
  Example: $self->store_primers($metadata);

=cut

sub store_primers {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_technology_type().\n");
    $self->check_store_conditions('store()', $metadata);
    my $primer_row_href = $self->get_primers_dbic_row();
    my @primer_types = keys %{ $primer_row_href };
    foreach my $primer_type (@primer_types) {
	my $primer_row = $primer_row_href->{$primer_type};
	my $primer_id = $primer_row->get_column('primer_id');

	## Exists primer_id? If do not exists the first question is exists another primer with the same name?

	if (defined $primer_id) {
	    if ($self->get_schema()->exists_data('primer', 'primer_id', $primer_id)) {
		if ($primer_row->is_changed()) {                 ## If something change, it consider that need do an UPDATE
		    my @columns_changed = $primer_row->is_changed();
		    my @modification_note_list;
		    foreach my $col_changed (@columns_changed) {
			push @modification_note_list, "set value in $col_changed column";
		    }
		    my $modification_note = join ', ', @modification_note_list;
		    my $primer_metadata_id = $primer_row->get_column('metadata_id');
		    my $new_primer_metadata_id;
		    if (defined $primer_metadata_id) {
			my $u_primer_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
									   $metadata->get_object_creation_user(),
									   $primer_metadata_id);
			$u_primer_metadata->set_modification_note( $modification_note );
			$u_primer_metadata->set_modified_person_id_by_username( $metadata->get_object_creation_user() );
			$u_primer_metadata->set_modified_date( $metadata->get_object_creation_date() );
			my $u_primer_metadata_id = $u_primer_metadata->find_or_store()->get_metadata_id();

			### Now we are going to set the new metadata_id in the technology_type_row object before store it.
			### Update all the data and set in the platform object the new_row

			$primer_row->set_column( metadata_id => $u_primer_metadata_id );
			my $primer_row_updated = $primer_row->update()->discard_changes();              
			$primer_row_href->{$primer_type} = $primer_row_updated;                  
		    } else {
			my $error = "DATA COHERENCE ERROR: The store function in CXGN::SEDM::Probe has reported a db coherence error.\n";
			$error .= "The sed.primer.primer_id=$primer_id has not any metadata_id.\n";
			$error .= "The store function can not be applied to rows with data coherence errors.\n";
			croak($error);
		    }
		}
	    } else {
	    
		### The primer_id of the probe object do not exists into the database. The store function should not update
		### or insert primary keys without the use of the database sequence (for special cases use enforce functions). So this
		### should give an error and die.
	    
		croak("DATA INTERGRITY ERROR: The primer_id of the platform object do not exists into the database.\n");
	    }
	} else {

	    ## If the probe object hasn't defined the primer_id we consider the store function as an INSERT, but before
	    ## we need check that do not exists a primer with the same name.
	    my $primer_name = $primer_row->get_column('primer_name');
	    if (defined $primer_name && $self->get_schema()->exists_data('primer', 'primer_name', $primer_name)) {
		my $error ="DATA INTEGRITY ERROR: The primer_name:$primer_name exists into the table sed.primer,";
		$error .= " but the Probe object has not any primer_id so it can not be stored as a new primer.";
		$error .= " (the primer exists).\n";
		croak($error);
	    } else {
		
		## We can consider a real new data. So we can use insert, but before we new a metadata object.
		my $i_primer_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
			  					   $metadata->get_object_creation_user(),
							           undef);
		my $metadata_date = $metadata->get_object_creation_date;
		my $metadata_user = $metadata->get_object_creation_user;
		$i_primer_metadata->set_create_date( $metadata_date );
		$i_primer_metadata->set_create_person_id_by_username( $metadata_user );
		my $i_new_primer_metadata_object = $i_primer_metadata->find_or_store();
		my $i_new_primer_metadata_id = $i_new_primer_metadata_object->get_metadata_id();
		$primer_row->set_column( metadata_id => $i_new_primer_metadata_id);
		my $primer_row_inserted = $primer_row->insert()->discard_changes();
		$primer_row_href->{$primer_type} = $primer_row_inserted;
	    }
	}
    }
    $self->set_primer_dbic_row($primer_row_href);
}


=head2 store_probe

  Usage: $self->store_probe($metadata);
  Desc: Store the Probe data for probe. 
        This method is intrinsic of store function, so you can use it as $self->store($metadata, ['probes']);
  Ret: none
  Args: $metadata
  Side_Effects: none
  Example: $self->store_probe($metadata);

=cut

sub store_probe {
    my $self = shift;
    my $metadata = shift || croak ("FUNCTION ARGUMENT ERROR: None metadata object was supplied in function store_probe().\n");

    $self->check_store_conditions('store()', $metadata);

    my $probe_row = $self->get_probe_dbic_row();
    my $probe_id = $self->get_probe_id();

    ## Exists probe_id? If do not exists the first question is exists another probe with the same name?

    if (defined $probe_id) {
	if ( $self->get_schema->exists_data('probe', 'probe_id' ,$probe_id) ) {
	    if ($probe_row->is_changed()) {                 ## If something change, it consider that need do an UPDATE
		my @columns_changed = $probe_row->is_changed();
		my @modification_note_list;
		foreach my $col_changed (@columns_changed) {
		    push @modification_note_list, "set value in $col_changed column";
		}
		my $modification_note = join ', ', @modification_note_list;
		my $probe_metadata_id = $self->probe_metadata_id();
		my $new_probe_metadata_id;
		if (defined $probe_metadata_id) {
		    my $u_probe_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                                      $metadata->get_object_creation_user(),
			      					      $probe_metadata_id);
		    $u_probe_metadata->set_modification_note( $modification_note );
		    $u_probe_metadata->set_modified_person_id_by_username( $metadata->get_object_creation_user() );
		    $u_probe_metadata->set_modified_date( $metadata->get_object_creation_date() );
		    my $u_probe_metadata_id = $u_probe_metadata->find_or_store()->get_metadata_id();

		    ### Now we are going to set the new metadata_id in the technology_type_row object before store it.
                    ### Update all the data and set in the probe object the new_row

		    $probe_row = $self->set_probe_metadata_id( $u_probe_metadata_id )->get_probe_dbic_row();
		    my $probe_row_updated = $probe_row->update()->discard_changes();              
		    $self->set_probe_dbic_row( $probe_row_updated );                  
		} else {
		    my $error = "DATA COHERENCE ERROR: The store function in CXGN::SEDM::Probe has reported a db coherence error.\n";
		    $error .= "The sed.probe.probe_id=$probe_id has not any metadata_id.\n";
		    $error .= "The store function can not be applied to rows with data coherence errors.\n";
		    croak($error);
		}
	    }
	} else {
	    
	   ### The probe_id of the probe object do not exists into the database. The store function should not update
           ### or insert primary keys without the use of the database sequence (for special cases use enforce functions). So this
	   ### should give an error and die.
	    
	    croak("DATA INTERGRITY ERROR: The probe_id of the probe object do not exists into the database.\n");
	}
    } else {

	## If the probe object hasn't defined the probe_id we consider the store function as an INSERT, but before
        ## we need check that do not exists a probe with the same name.

	my $probe_name = $self->get_probe_name();
	if (defined $probe_name && $self->get_schema()->exists_data('probes', 'probe_name', $probe_name) == 1) {
	    my $error ="DATA INTEGRITY ERROR: The probe_name:$probe_name exists into the table sed.probe,";
	    $error .= " but the Probe object has not any probe_id so it can not be stored as a new probe.";
	    $error .= " (the probe_name exists).\n";
	    croak($error);
	} else {
	    ## We can consider a real new data. So we can use insert, but before we new a metadata object.

	    my $i_probe_metadata = CXGN::SEDM::Metadata->new( $self->get_schema(), 
                                                              $metadata->get_object_creation_user(),
		          				      undef);
	    $i_probe_metadata->set_create_date( $metadata->get_object_creation_date() );
	    $i_probe_metadata->set_create_person_id_by_username( $metadata->get_object_creation_user() );
	    my $i_new_probe_metadata_object = $i_probe_metadata->find_or_store();
	    my $i_new_probe_metadata_id = $i_new_probe_metadata_object->get_metadata_id();
	    $self->set_probe_metadata_id($i_new_probe_metadata_id);
	    $probe_row = $self->get_probe_dbic_row();
	    my $probe_row_inserted = $probe_row->insert()->discard_changes();
	    $self->set_probe_dbic_row($probe_row_inserted);
	}
    }
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

####
1;##
####
