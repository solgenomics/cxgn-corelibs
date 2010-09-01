package CXGN::GEM::Hybridization;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::GEM::Platform;
use CXGN::GEM::Target;
use CXGN::Biosource::Protocol;
use CXGN::DB::Connection;

use Carp qw| croak cluck carp|;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Hybridization
a class to manipulate hybridization data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Hybridization;

 ## Constructor

 my $hybridization = CXGN::GEM::Hybridization->new($schema, $hyb_id); 

 ## Simple accessors

 my $target_id = $hybridization->get_target_id();
 $hybridization->set_target_id($target_id);

 ## Metadata functions

 my $metadbdata = $hybridization->get_hybridization_metadbdata();

 if ($hybridization->is_hybridization_obsolete()) {
    ## Do something
 }

 ## Store functions

 $hybridization->store($metadbdata);

 $hybridization->obsolete_hybridization($metadata, 'change to obsolete test');



=head1 DESCRIPTION

 This object manage the experiment information of the database
 from the tables:
  
   + gem.ge_hybridization

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %Hybridization_Object = ( 
    
       ge_hybridization_row        => GeExperiment_row, 
    
  );


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 




############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $hybridization = CXGN::GEM::Hybridization->new($schema, $hybridization_id);

  Desc: Create a new hybridization object

  Ret: a CXGN::GEM::Hybridization object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        A $hybridization_id, a scalar.
        If $hybridization_id is omitted, an empty hybridization object is 
        created.

  Side_Effects: access to database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $hybridization = CXGN::GEM::Hybridization->new($schema,$hyb_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new() function.\n");
    my $id = shift;

    ### First, bless the class to create the object and set the schema into de object 
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);                                   

    ### Second, check that ID is an integer. If it is right go and get all the data for 
    ### this row in the database and after that get the data for hybridization
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $hybridization;
 
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The hybridization_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_hybridization_row object using a search based in the hybridization_id 

	($hybridization) = $schema->resultset('GeHybridization')
	                          ->search( { hybridization_id => $id } );

	unless (defined $hybridization) {
	    	$hybridization = $schema->resultset('GeHybridization')
	                                ->new({});                              ### Create an empty object;
	}
    }
    else {
	$hybridization = $schema->resultset('GeHybridization')
	                        ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_gehybridization_row($hybridization);

    return $self;
}




##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_gehybridization_row, set_gehybridization_row

  Usage: my $gehybridization_row = $self->get_gehybridization_row();
         $self->set_gehybridization_row($gehybridization_row_object);

  Desc: Get or set a gehybridization row object into a hybridization
        object
 
  Ret:   Get => $gehybridization_row_object, a row object 
                (CXGN::GEM::Schema::GeExperriment).
         Set => none
 
  Args:  Get => none
         Set => $gehybridization_row_object, a row object 
                (CXGN::GEM::Schema::GeHybridization).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $gehybridization_row = $self->get_gehybridization_row();
           $self->set_gehybridization_row($gehybridization_row);

=cut

sub get_gehybridization_row {
  my $self = shift;
 
  return $self->{gehybridization_row}; 
}

sub set_gehybridization_row {
  my $self = shift;
  my $gehybridization_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None gehybridization_row object was supplied for $self->set_gehybridization_row function.\n");
 
  if (ref($gehybridization_row) ne 'CXGN::GEM::Schema::GeHybridization') {
      croak("SET ARGUMENT ERROR: $gehybridization_row isn't a gehybridization_row obj. (CXGN::GEM::Schema::GeHybridization).\n");
  }
  $self->{gehybridization_row} = $gehybridization_row;
}


########################################
### DATA ACCESSORS FOR HYBRIDIZATION ###
########################################

=head2 get_hybridization_id, force_set_hybridization_id
  
  Usage: my $hybridization_id = $hybridization->get_hybridization_id();
         $hybridization->force_set_hybridization_id($hybridization_id);

  Desc: get or set a hybridization_id in a hybridization object. 
        set method should be USED WITH PRECAUTION
        If you want set a hybridization_id that do not exists into the 
        database you should consider that when you store this object you 
        CAN STORE a hybridization_id that do not follow the 
        gem.ge_hybridization_hybridization_id_seq

  Ret:  get=> $hybridization_id, a scalar.
        set=> none

  Args: get=> none
        set=> $hybridization_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $hybridization_id = $hybridization->get_hybridization_id(); 

=cut

sub get_hybridization_id {
  my $self = shift;
  return $self->get_gehybridization_row->get_column('hybridization_id');
}

sub force_set_hybridization_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None hybridization_id was supplied for force_set_hybridization_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The hybridization_id ($data) for $self->force_set_hybridization_id() ISN'T AN INTEGER.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( hybridization_id => $data );
 
}

=head2 accessors get_platform_id, set_platform_id

  Usage: my $platform_id = $hybridization->get_platform_id();
         $hybrization->set_platform_id($platform_id);
 
  Desc: Get or set platform_id from a hybridization object. 
 
  Ret:  get=> $platform_id, a scalar
        set=> none
 
  Args: get=> none
        set=> $platform_id, a scalar
 
  Side_Effects: For the set accessor, die if the platform_id don't
                exists into the database or it is not an integer
 
  Example: my $platform_id = $hybridization->get_platform_id();
           $hybridization->set_platform_id($platform_id);
=cut

sub get_platform_id {
  my $self = shift;
  return $self->get_gehybridization_row->get_column('platform_id'); 
}

sub set_platform_id {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_platform_id() function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The platform_id ($data) for $self->set_platform_id() ISN'T AN INTEGER.\n");
  }

  ## Check if exists the platform_id into the database

  my ($platform_row) = $self->get_schema()
                          ->resultset('GePlatform')
	 	          ->search( { platform_id => $data } );

  unless (defined $platform_row) {
      croak("INPUT PARAMETER ERROR: Platform_id=$data do not exists into the db. It can not be used to set_platform_id in $self.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( platform_id => $data );
}

=head2 accessors get_platform_by_name, set_platform_by_name

  Usage: my $platform_name = $hybridization->get_platform_by_name();
         $hybrization->set_platform_by_name($platform_name);
 
  Desc: Get the platform_name associated with the platform_id in the
        hybridization object. 
        Set the platform_id in the hybridization object using the platform
        name.
 
  Ret:  get=> $platform_name, a scalar
        set=> none
 
  Args: get=> none
        set=> $platform_name, a scalar
 
  Side_Effects: For the set accessor, die if the platform_name don't
                exists into the database
 
  Example: my $platform_id = $hybridization->get_platform_id();
           $hybridization->set_platform_id($platform_id);
=cut

sub get_platform_by_name {
  my $self = shift;
  my $platform = CXGN::GEM::Platform->new( $self->get_schema, 
                                           $self->get_gehybridization_row
                                                ->get_column('platform_id') 
                                         );

  return $platform->get_platform_name();
}

sub set_platform_by_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_platform_by_name() function.\n");

  my $platform_id;

  ## It will use a DBIx::Class search instead CXGN::GEM::Platform->new_by_name() because if it used a platform_name that
  ## do not exists into the database the constructor will give a warning from the point of the constructor and not from
  ## the point of view of the hybridzation accessor

  my ($platform_row) = $self->get_schema()
                            ->resultset('GePlatform')
			    ->search( { platform_name => $data } );

  if (defined $platform_row) {
      $platform_id = $platform_row->get_column('platform_id');
  }
  else {
      croak("INPUT PARAMETER ERROR: Platform_name=$data do not exists in database. It can not be used to $self->set_platform_by_name.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( platform_id => $platform_id );
}

=head2 accessors get_platform_batch, set_platform_batch

  Usage: my $platform_batch = $hybridization->get_platform_batch();
         $hybrization->set_platform_batch($platform_batch);
 
  Desc: Get or set platform_batch from a hybridization object. 
 
  Ret:  get=> $platform_batch, a scalar
        set=> none
 
  Args: get=> none
        set=> $platform_batch, a scalar
 
  Side_Effects: None
 
  Example: my $platform_batch = $hybridization->get_platform_batch();
           $hybridization->set_platform_batch($platform_batch);
=cut

sub get_platform_batch {
  my $self = shift;
  return $self->get_gehybridization_row->get_column('platform_batch'); 
}

sub set_platform_batch {
  my $self = shift;
  my $data = shift; 

  $self->get_gehybridization_row()
       ->set_column( platform_batch => $data );
}

=head2 accessors get_target_id, set_target_id

  Usage: my $target_id = $hybridization->get_target_id();
         $hybrization->set_target_id($target_id);
 
  Desc: Get or set target_id from a hybridization object. 
 
  Ret:  get=> $target_id, a scalar
        set=> none
 
  Args: get=> none
        set=> $target_id, a scalar
 
  Side_Effects: For the set accessor, die if the target_id don't
                exists into the database or it is not an integer
 
  Example: my $target_id = $hybridization->get_target_id();
           $hybridization->set_target_id($target_id);
=cut

sub get_target_id {
  my $self = shift;
  return $self->get_gehybridization_row->get_column('target_id'); 
}

sub set_target_id {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_target_id() function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The target_id ($data) for $self->set_target_id() ISN'T AN INTEGER.\n");
  }

  ## Check if exists the target_id into the database

  my ($target_row) = $self->get_schema()
                          ->resultset('GeTarget')
	 	          ->search( { target_id => $data } );

  unless (defined $target_row) {
      croak("INPUT PARAMETER ERROR: Target_id=$data do not exists into the db. It can not be used to set_target_id in $self.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( target_id => $data );
}

=head2 accessors get_target_by_name, set_target_by_name

  Usage: my $target_name = $hybridization->get_target_by_name();
         $hybrization->set_target_by_name($target_name);
 
  Desc: Get the target_name associated with the target_id in the
        hybridization object. 
        Set the target_id in the hybridization object using the target
        name.
 
  Ret:  get=> $target_name, a scalar
        set=> none
 
  Args: get=> none
        set=> $target_name, a scalar
 
  Side_Effects: For the set accessor, die if the target_name don't
                exists into the database
 
  Example: my $target_id = $hybridization->get_target_id();
           $hybridization->set_target_id($target_id);
=cut

sub get_target_by_name {
  my $self = shift;
  my $target = CXGN::GEM::Target->new( $self->get_schema, 
                                       $self->get_gehybridization_row
                                            ->get_column('target_id') 
                                     );

  return $target->get_target_name();
}

sub set_target_by_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_target_by_name() function.\n");

  my $target_id;

  ## It will use a DBIx::Class search instead CXGN::GEM::Target->new_by_name() because if it used a target_name that
  ## do not exists into the database the constructor will give a warning from the point of the constructor and not from
  ## the point of view of the hybridzation accessor

  my ($target_row) = $self->get_schema()
                          ->resultset('GeTarget')
	      	          ->search( { target_name => $data } );

  if (defined $target_row) {
      $target_id = $target_row->get_column('target_id');
  }
  else {
      croak("INPUT PARAMETER ERROR: Target_name=$data do not exists in database. It can not be used to $self->set_target_by_name.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( target_id => $target_id );
}

=head2 accessors get_protocol_id, set_protocol_id

  Usage: my $protocol_id = $hybridization->get_protocol_id();
         $hybrization->set_protocol_id($protocol_id);
 
  Desc: Get or set protocol_id from a hybridization object. 
 
  Ret:  get=> $protocol_id, a scalar
        set=> none
 
  Args: get=> none
        set=> $protocol_id, a scalar
 
  Side_Effects: For the set accessor, die if the protocol_id don't
                exists into the database or it is not an integer
 
  Example: my $protocol_id = $hybridization->get_protocol_id();
           $hybridization->set_protocol_id($protocol_id);
=cut

sub get_protocol_id {
  my $self = shift;
  return $self->get_gehybridization_row->get_column('protocol_id'); 
}

sub set_protocol_id {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_protocol_id() function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The protocol_id ($data) for $self->set_protocol_id() ISN'T AN INTEGER.\n");
  }

  ## Check if exists the protocol_id into the database

  my ($protocol_row) = $self->get_schema()
                            ->resultset('BsProtocol')
	 	            ->search( { protocol_id => $data } );

  unless (defined $protocol_row) {
      croak("INPUT PARAMETER ERROR: Protocol_id=$data do not exists into the db. It can not be used to set_protocol_id in $self.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( protocol_id => $data );
}

=head2 accessors get_protocol_by_name, set_protocol_by_name

  Usage: my $protocol_name = $hybridization->get_protocol_by_name();
         $hybrization->set_protocol_by_name($protocol_name);
 
  Desc: Get the platform_name associated with the protocol_id in the
        hybridization object. 
        Set the protocol_id in the hybridization object using the protocol
        name.
 
  Ret:  get=> $protocol_name, a scalar
        set=> none
 
  Args: get=> none
        set=> $protocol_name, a scalar
 
  Side_Effects: For the set accessor, die if the protocol_name don't
                exists into the database
 
  Example: my $protocol_id = $hybridization->get_protocol_id();
           $hybridization->set_protocol_id($protocol_id);
=cut

sub get_protocol_by_name {
  my $self = shift;
  my $protocol = CXGN::Biosource::Protocol->new( $self->get_schema, 
                                                 $self->get_gehybridization_row
                                                      ->get_column('protocol_id') 
                                               );

  return $protocol->get_protocol_name();
}

sub set_protocol_by_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_protocol_by_name() function.\n");

  my $protocol_id;

  ## It will use a DBIx::Class search instead CXGN::Biosource::Protocol->new_by_name() because if it used a protocol_name that
  ## do not exists into the database the constructor will give a warning from the point of the constructor and not from
  ## the point of view of the hybridzation accessor

  my ($protocol_row) = $self->get_schema()
                            ->resultset('BsProtocol')
		 	    ->search( { protocol_name => $data } );

  if (defined $protocol_row) {
      $protocol_id = $protocol_row->get_column('protocol_id');
  }
  else {
      croak("INPUT PARAMETER ERROR: Protocol_name=$data do not exists in database. It can not be used to $self->set_protocol_by_name.\n");
  }

  $self->get_gehybridization_row()
       ->set_column( protocol_id => $protocol_id );
}



#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_hybridization_metadbdata

  Usage: my $metadbdata = $hybridization->get_hybridization_metadbdata();

  Desc: Get metadata object associated to hybridization data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $target->get_hybridization_metadbdata();
           my $metadbdata = $target->get_hybridization_metadbdata($metadbdata);

=cut

sub get_hybridization_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_gehybridization_row
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

      ## If do not exists the metadata_id, check the possible reasons.
      my $hybridization_id = $self->get_hybridization_id();
      if (defined $hybridization_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the hybridization_id=$hybridization_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any hybridization_id. Probably it hasn't been stored yet.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_hybridization_obsolete

  Usage: $hybridization->is_hybridization_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($hybridization->is_hybridization_obsolete()) { 
                   ## do something 
           }

=cut

sub is_hybridization_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_hybridization_metadbdata();
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

  Usage: $hybridization->store($metadbdata);
 
  Desc: Store in the database the all hybridization data for the 
        hybridizational design object.
        See the methods store_hybridization for more details.

  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $hybridization->store($metadata);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## SECOND, the store functions return the updated object, so it will chain the different store functions

    $self->store_hybridization($metadata);
}



=head2 store_hybridization

  Usage: $hybridization->store_hybridization($metadata);
 
  Desc: Store in the database the hybridization data for the hybridization
        design object (Only the geexpdesign row, don't store any 
        hybridizational_design_dbxref data)
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $hybridization->store_hybridization($metadata);

=cut

sub store_hybridization {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_hybridization().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_hybridization() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not hybridization_id. 
    ##   if exists hybridization_id         => update
    ##   if do not exists hybridization_id  => insert

    my $gehybridization_row = $self->get_gehybridization_row();
    my $hybridization_id = $gehybridization_row->get_column('hybridization_id');

    unless (defined $hybridization_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$gehybridization_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$gehybridization_row->insert()
                            ->discard_changes();                           ## It will set the row with the updated row
	          
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $gehybridization_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_hybridization_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $gehybridization_row->set_column( metadata_id => $mod_metadata_id );

	    $gehybridization_row->update()
                             ->discard_changes();
	}
    }
}


=head2 obsolete_hybridization

  Usage: $hybridization->obsolete_hybridization($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $hybridization->obsolete_hybridization($metadata, 'change to obsolete test');

=cut

sub obsolete_hybridization {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_hybridization().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_hybridization isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_hybridization().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_hybridization_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $gehybridization_row = $self->get_gehybridization_row();

    $gehybridization_row->set_column( metadata_id => $mod_metadata_id );
         
    $gehybridization_row->update()
  	                ->discard_changes();
}



#####################
### OTHER METHODS ###
#####################


=head2 get_platform

  Usage: my $platform = $hybridization->get_platform();
  
  Desc: Get a CXGN::GEM::Platform object.
  
  Ret:  A CXGN::GEM::Platform object.
  
  Args: none
  
  Side_Effects: die if the hybridization_object have not any 
                platform_id
  
  Example: my $platform = $hybridization->get_platform();

=cut

sub get_platform {
   my $self = shift;
   
   my $platform_id = $self->get_platform_id();
   
   unless (defined $platform_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any platform_id. Probably it hasn't store yet.\n");
   }

   my $platform = CXGN::GEM::Platform->new($self->get_schema(), $platform_id);
  
   return $platform;
}

=head2 get_target

  Usage: my $target = $hybridization->get_target();
  
  Desc: Get a CXGN::GEM::Target object.
  
  Ret:  A CXGN::GEM::Target object.
  
  Args: none
  
  Side_Effects: die if the hybridization_object have not any 
                target_id
  
  Example: my $target = $hybridization->get_target();

=cut

sub get_target {
   my $self = shift;
   
   my $target_id = $self->get_target_id();
   
   unless (defined $target_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any target_id. Probably it hasn't store yet.\n");
   }
	my $dbh = CXGN::DB::Connection->new;
   my $target = CXGN::GEM::Target->new($dbh, $target_id);
  
   return $target;
}

=head2 get_protocol

  Usage: my $protocol = $hybridization->get_protocol();
  
  Desc: Get a CXGN::Biosource::Protocol object.
  
  Ret:  A CXGN::Biosource::Protocol object.
  
  Args: none
  
  Side_Effects: die if the hybridization_object have not any 
                protocol_id
  
  Example: my $protocol = $hybridization->get_protocol();

=cut

sub get_protocol {
   my $self = shift;
   
   my $protocol_id = $self->get_protocol_id();
   
   unless (defined $protocol_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any protocol_id. Probably it hasn't store yet.\n");
   }

   my $protocol = CXGN::Biosource::Protocol->new($self->get_schema(), $protocol_id);
  
   return $protocol;
}










####
1;##
####
