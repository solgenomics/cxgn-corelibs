package CXGN::GEM::TechnologyType;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Metadata::Metadbdata;

use Carp qw| croak cluck carp |;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::TechnologyType
a class to manipulate a technology_type data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::TechnologyType;

 ## Constructor

 my $techtype = CXGN::GEM::TechnologyType->new($schema, $techtype_id); 

 ## Simple accessors

 my $technology_name = $techtype->get_technology_name();
 $techtype->set_technology_name($new_name);

 ## Metadata functions

 my $metadbdata = $techtype->get_technology_type_metadbdata();

 if ($expdesign->is_technology_type_obsolete()) {
    ## Do something
 }

 ## Store functions

 $techtype->store($metadbdata);

 $techtype->obsolete_technology_type($metadata, 'change to obsolete test');
 


=head1 DESCRIPTION

 This object manage the target information of the database
 from the tables:
  
   + gem.ge_technologytype

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %TechnologyType_Object = ( 
    
       ge_technologytype_row        => GeTechnologyType_row,
    
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

  Usage: my $techtype = CXGN::GEM::TechnologyType->new($schema, $techtype_id);

  Desc: Create a new technology type object

  Ret: a CXGN::GEM::TechnologyType object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        A $technology_type_id, a scalar.
        If $technology_type_id is omitted, an empty platform object is created.

  Side_Effects: access to database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $techtype = CXGN::GEM::TechnologyType->new($schema, $techtype_id);

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
    ### this row in the database and after that get the data for technology_type
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $techtype;
 
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The techtype_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_technologytype_row object using a search based in the techtype_id 

	($techtype) = $schema->resultset('GeTechnologyType')
	                     ->search( { technology_type_id => $id } );

	unless (defined $techtype) {
	    $techtype = $schema->resultset('GeTechnologyType')
	                   ->new({});                              ### Create an empty object;
	}
    }
    else {
	$techtype = $schema->resultset('GeTechnologyType')
	                   ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_getechnologytype_row($techtype);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $techtype = CXGN::GEM::TechnologyType->new_by_name($schema, $name);
 
  Desc: Create a new TechnologyType object using technologytype_name
 
  Ret: a CXGN::GEM::TechnologyType object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $techtype_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the experiment name do not exists 
                into the db
 
  Example: my $techtype = CXGN::GEM::TechnologyType->new_by_name($schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the platform_id for this name and it will get the techtype_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the techtype_name for it
  
    my $techtype;

    if (defined $name) {
	my ($techtype_row) = $schema->resultset('GeTechnologyType')
	                            ->search({ technology_name => $name });
  
	unless (defined $techtype_row) {                
	    warn("DATABASE OUTPUT WARNING: technology_name ($name) for $class->new_by_name() DON'T EXISTS INTO THE DB.\n");

	    ## If do not exists any platform with this name, it will return a warning and it will create an empty
            ## object with the platform name set in it.

	    $techtype = $class->new($schema);
	    $techtype->set_technology_name($name);
	}
	else {

	    ## if exists it will take the technologytype_id to create the object with the new constructor
	    $techtype = $class->new( $schema, $techtype_row->get_column('technology_type_id') ); 
	}
    } 
    else {
	$techtype = $class->new($schema);                              ### Create an empty object;
    }
   
    return $techtype;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_getechnologytype_row, set_getechnologytype_row

  Usage: my $getechnologytype_row = $self->get_getechnologytype_row();
         $self->set_getechnologytype_row($getechnologytype_row_object);

  Desc: Get or set a getechnologytype row object into a technologytype
        object
 
  Ret:   Get => $getechnologytype_row_object, a row object 
                (CXGN::GEM::Schema::GeTechnologyType).
         Set => none
 
  Args:  Get => none
         Set => $getechnologytype_row_object, a row object 
                (CXGN::GEM::Schema::GeTechnologyType).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $getechnologytype_row = $self->get_getechnologytype_row();
           $self->set_getechnologytype_row($getechnologytype_row);

=cut

sub get_getechnologytype_row {
  my $self = shift;
 
  return $self->{getechnologytype_row}; 
}

sub set_getechnologytype_row {
  my $self = shift;
  my $getechnologytype_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None getechnologytype_row object was supplied for $self->set_getechnologytype_row function.\n");
 
  if (ref($getechnologytype_row) ne 'CXGN::GEM::Schema::GeTechnologyType') {
      croak("SET ARGUMENT ERROR: $getechnologytype_row isn't a getechnologytype_row obj. (CXGN::GEM::Schema::GeTechnologyType).\n");
  }
  $self->{getechnologytype_row} = $getechnologytype_row;
}


##########################################
### DATA ACCESSORS FOR TECHNOLOGY_TYPE ###
##########################################

=head2 get_technology_type_id, force_set_technology_type_id
  
  Usage: my $technology_type_id = $techtype->get_technology_type_id();
         $techtype->force_set_technology_type_id($technology_type_id);

  Desc: get or set a technology_type_id in a technology_type object. 
        set method should be USED WITH PRECAUTION
        If you want set a technology_type_id that do not exists into the 
        database you should consider that when you store this object you 
        CAN STORE a experiment_id that do not follow the 
        gem.ge_technology_type_technology_type_id_seq

  Ret:  get=> $technology_type_id, a scalar.
        set=> none

  Args: get=> none
        set=> $technology_type_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $technology_type_id = $techtype->get_technology_type_id(); 

=cut

sub get_technology_type_id {
  my $self = shift;
  return $self->get_getechnologytype_row->get_column('technology_type_id');
}

sub force_set_technology_type_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None technology_type_id was supplied for force_set_technology_type_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The technology_type_id ($data) for $self->force_set_technology_type_id() ISN'T AN INTEGER.\n");
  }

  $self->get_getechnologytype_row()
       ->set_column( technology_type_id => $data );
 
}

=head2 accessors get_technology_name, set_technology_name

  Usage: my $technology_name = $techtype->get_technology_name();
         $techtype->set_technology_name($technology_name);

  Desc: Get or set the technology_name from technology object. 

  Ret:  get=> $technology_name, a scalar
        set=> none

  Args: get=> none
        set=> $technology_name, a scalar

  Side_Effects: none

  Example: my $technology_name = $techtype->get_technology_name();
           $techtype->set_technology_name($new_name);
=cut

sub get_technology_name {
  my $self = shift;
  return $self->get_getechnologytype_row->get_column('technology_name'); 
}

sub set_technology_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_technology_name function.\n");

  $self->get_getechnologytype_row()
       ->set_column( technology_name => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $techtype->get_description();
         $techtype->set_description($description);

  Desc: Get or set the description from technology_type object. 

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: none

  Example: my $description = $techtype->get_description();
           $techtype->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_getechnologytype_row->get_column('description'); 
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_getechnologytype_row()
       ->set_column( description => $data );
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_technology_type_metadbdata

  Usage: my $metadbdata = $techtype->get_technology_type_metadbdata();

  Desc: Get metadata object associated to platform data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $techtype->get_technology_type_metadbdata();
       my $metadbdata = $techtype->get_technology_type_metadbdata($metadbdata);

=cut

sub get_technology_type_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_getechnologytype_row
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
      my $techtype_id = $self->get_technology_type_id();
      if (defined $techtype_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the technology_type_id=$techtype_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any technology_type_id. Probably it hasn't been stored yet.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_technology_type_obsolete

  Usage: $techtype->is_technology_type_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        technology_type data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($techtype->is_technology_type_obsolete()) { 
                   ## do something 
           }

=cut

sub is_technology_type_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_technology_type_metadbdata();
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

  Usage: $techtype->store($metadbdata);
 
  Desc: Store in the database the all technology_type data for the 
        technology_type object.
        For now it is equivalent to store_technology_type but open the
        possibility of coordinate the storing with other technology_type
        data 

  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $platform->store($metadata);

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

    $self->store_technology_type($metadata);
}


=head2 store_technology_type

  Usage: $techtype->store_technology_type($metadata);
 
  Desc: Store in the database the technology_type data for the technology_type
        object (Only the getechnologytype row)
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $techtype->store_technology_type($metadata);

=cut

sub store_technology_type {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_technology_type().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_tecnology_type() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not technology_type_id. 
    ##   if exists technology_type_id         => update
    ##   if do not exists technology_type_id  => insert

    my $getechnologytype_row = $self->get_getechnologytype_row();
    my $techtype_id = $getechnologytype_row->get_column('technology_type_id');

    unless (defined $techtype_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	$metadata->store();
	my $metadata_id = $metadata->get_metadata_id();

	$getechnologytype_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$getechnologytype_row->insert()
                             ->discard_changes();                           ## It will set the row with the updated row
	
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $getechnologytype_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata = $self->get_technology_type_metadbdata($metadata);
	    $mod_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id(); 

	    $getechnologytype_row->set_column( metadata_id => $mod_metadata_id );

	    $getechnologytype_row->update()
                                 ->discard_changes();
	}
    }
}


=head2 obsolete_technology_type

  Usage: $techtype->obsolete_technology_type($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $techtype->obsolete_technology_type($metadata, 'change to obsolete');

=cut

sub obsolete_technology_type {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_technology_type().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_technology_type isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_technology_type().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata = $self->get_technology_type_metadbdata($metadata);
    $mod_metadata->store( { modification_note => $modification_note,
			    obsolete          => $obsolete, 
			    obsolete_note     => $obsolete_note } );
    my $mod_metadata_id = $mod_metadata->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $getechnologytype_row = $self->get_getechnologytype_row();

    $getechnologytype_row->set_column( metadata_id => $mod_metadata_id );
         
    $getechnologytype_row->update()
	                 ->discard_changes();
}


#####################
### OTHER METHODS ###
#####################

=head2 get_platform_list

  Usage: my @platforms = $techtype->get_platform_list();
  
  Desc: Get a list CXGN::GEM::Platform objects.
  
  Ret:  An arrray CXGN::GEM::Platform object.
  
  Args: none
  
  Side_Effects: die if the platform object have not any 
                experiment_id
  
  Example: my @platforms = $techtype->get_platform_list();

=cut

sub get_platform_list {
   my $self = shift;
 
   my @platforms = ();
  
   my $techtype_id = $self->get_technology_type_id();
   
   unless (defined $techtype_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any technology_type_id. Probably it hasn't store yet.\n");
   }
  
   my @platform_rows = $self->get_schema()
                            ->resultset('GePlatform')
                            ->search( { technology_type_id => $techtype_id } );

   foreach my $platform_row (@platform_rows) {
       my $platform = CXGN::GEM::Platform->new($self->get_schema(), $platform_row->get_column('platform_id'));
      
       push @platforms, $platform;
   }
   
   return @platforms;
}



####
1;##
####
