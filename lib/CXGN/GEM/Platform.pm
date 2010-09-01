package CXGN::GEM::Platform;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Biosource::Sample;
use CXGN::Metadata::Metadbdata;
use CXGN::GEM::TechnologyType;
use CXGN::GEM::Template;

use Carp qw| croak cluck carp |;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Platform
a class to manipulate a platform data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Platform;

 ## Constructors

 my $platform = CXGN::GEM::Platform->new($schema, $platform_id);
 my $platform = CXGN::GEM::Platform->new_by_name($schema, $name);

 ## Simple accessors (platform_name, technology_type_id, description and contact_id)

 my $platform_name = $platform->get_platform_name();
 $platform->set_platform_name($platform_name);

 ## Advance accessors (platform_design, pub and dbxref)

 $platform->add_platform_design( $sample_name );
 my @sample_id_list = $platform->get_design_list();

 $platform->add_dbxref($dbxref_id);
 my @dbxref_list_id = $platform->get_publication_list();

 $platform->add_publication($pub_id);
 my @pub_id_list = $platform->get_publication_list();

 ## Metadata objects (also for, platform_design, platform_dbxref and platform_pub)

 my $metadbdata = $platform->get_platform_metadbdata();
 unless ($platform->is_experiment_obsolete()) {
                   ## do something
 }

 ## Store

 $platform->store($metadbdata);

 ## Obsolete (also for platform_design, platform_dbxref and platform_pub)

 $platform->obsolete_platform($metadata, $note, 'REVERT');



=head1 DESCRIPTION

 This object manage the target information of the database
 from the tables:

   + gem.ge_platform
   + gem.ge_platform_design
   + gem.ge_platform_dbxref
   + gem.ge_platform_pub

 This data is stored inside this object as dbic rows objects with the
 following structure:

  %Platform_Object = (

       ge_platform_row        => GePlatform_row,

       ge_plaform_design      => [ @GePlatformDesign_rows ],

       ge_platform_dbxref_row => [ @GePlatformDbxref_rows ],

       ge_platform_pub_row    => [ @GePlatformPub_rows ],

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

  Usage: my $platform = CXGN::GEM::Platform->new($schema, $platform_id);

  Desc: Create a new platform object

  Ret: a CXGN::GEM::Platform object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
                   %other_parameters );
        A $platform_id, a scalar.
        If $platform_id is omitted, an empty platform object is created.

  Side_Effects: access to database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $platform = CXGN::GEM::Platform->new($schema, $platform_id);

=cut

sub new {
    my ($class,$dbh,$id) = @_;
	croak("PARAMETER ERROR: No dbh object was supplied to the $class->new() function.\n") unless $dbh;

    ### First, bless the class to create the object and set the schema into the object
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($dbh);
    $self->set_dbh($dbh);
    my $schema = CXGN::DB::DBICFactory->open_schema(
        'CXGN::GEM::Schema',
         search_path => [qw/gem biosource metadata public/],
    );

    ### Second, check that ID is an integer. If it is right go and get all the data for
    ### this row in the database and after that get the data for platform
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $platform;
    my @platform_design_rows = ();
    my @platform_dbxrefs = ();
    my @platform_pubs = ();

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.

	    croak("\nDATA TYPE ERROR: The platform_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_platform_row object using a search based in the platform_id

	($platform) = $schema->resultset('GePlatform')
	                     ->search( { platform_id => $id } );

	if (defined $platform) {
	    ## Search also the platform elements associated to this platform

	    @platform_design_rows = $schema->resultset('GePlatformDesign')
 	                                   ->search( { platform_id => $id } );

	    ## Search platform_dbxref associations

	    @platform_dbxrefs = $schema->resultset('GePlatformDbxref')
  	                               ->search( { platform_id => $id } );

	    @platform_pubs = $schema->resultset('GePlatformPub')
	                            ->search( { platform_id => $id });
	}
	else {
	    	$platform = $schema->resultset('GePlatform')
		                   ->new({});                              ### Create an empty object;
	}
    }
    else {
	$platform = $schema->resultset('GePlatform')
	                   ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_geplatform_row($platform);
    $self->set_geplatformdesign_rows(\@platform_design_rows);
    $self->set_geplatformdbxref_rows(\@platform_dbxrefs);
    $self->set_geplatformpub_rows(\@platform_pubs);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $platform = CXGN::GEM::Platform->new_by_name($schema, $name);

  Desc: Create a new Experiment object using platform_name

  Ret: a CXGN::GEM::Platform object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
                   %other_parameters );
        a $platform_name, a scalar

  Side_Effects: accesses the database,
                return a warning if the experiment name do not exists
                into the db

  Example: my $platform = CXGN::GEM::Platform->new_by_name($schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift ||
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the platform_id for this name and it will get the platform_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the platform_name for it

    my $platform;

    if (defined $name) {
	my ($platform_row) = $schema->resultset('GePlatform')
	                          ->search({ platform_name => $name });

	unless (defined $platform_row) {
	    warn("DATABASE OUTPUT WARNING: platform_name ($name) for $class->new_by_name() DON'T EXISTS INTO THE DB.\n");

	    ## If do not exists any platform with this name, it will return a warning and it will create an empty
            ## object with the platform name set in it.

	    $platform = $class->new($schema);
	    $platform->set_platform_name($name);
	}
	else {

	    ## if exists it will take the platform_id to create the object with the new constructor
	    $platform = $class->new( $schema, $platform_row->get_column('platform_id') );
	}
    }
    else {
	$platform = $class->new($schema);                              ### Create an empty object;
    }

    return $platform;
}

=head2 constructor new_by_design

  Usage: my $platform = CXGN::GEM::Platform->new_by_design($schema,
                                                               \@sample_names);

  Desc: Create a new Platform object using a list of a sample_name used
        in the design of the platform

  Ret: a CXGN::GEM::Platform object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                     sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
                     %other_parameters );
        a \@sample_names, an array reference with a list of sample
        names

  Side_Effects: accesses the database,
                return a warning if the platform name do not exists into the db

  Example: my $platform = CXGN::GEM::Platform->new_by_design( $schema,
                                                                  [$e1, $e2]);

=cut

sub new_by_design {
    my $class = shift;
    my $schema = shift ||
        croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $elements_aref = shift;

    ### It will search the platform_id for the list of these elements. If find a platform_id it will create a new object with it.
    ### if not, it will create an empty object and it will add all the elements over the empty object using the add_element_by_name
    ### function (it will search a element in the database and it will add it to the platform)

    my $platform;

    if (defined $elements_aref) {
        if (ref($elements_aref) ne 'ARRAY') {
            croak("PARAMETER ERROR: The element array reference supplied to $class->new_by_design() method IS NOT AN ARRAY REF.\n");
        }
        else {
            my $elements_n = scalar(@{$elements_aref});

	    ## First it will change sample_names by sample_ids

	    my @sample_ids = ();

	    foreach my $sample_name ( @{$elements_aref} ) {
		my $sample_id = CXGN::Biosource::Sample->new_by_name($schema, $sample_name)
		                                       ->get_sample_id();
		unless (defined $sample_id) {
		    croak("DATABASE OUTPUT WARNING: The sample_name=$sample_name do not exists into the biosource.bs_sample_table.");
		}
		else {
		    push @sample_ids, $sample_id;
		}
	    }

            ## Dbix::Class search to get an id in a group using the elements of the group

            my @geplatform_design_row = $schema->resultset('GePlatformDesign')
                                                 ->search( undef,
                                                          {
                                                            columns  => ['platform_id'],
                                                            where    => { sample_id => { -in  => \@sample_ids } },
                                                            group_by => [ qw/platform_id/ ],
                                                            having   => { 'count(platform_design_id)' => { '=', $elements_n } }
                                                          }
                                                        );

	    ## This search will return all the platform_design that contains the elements specified, it will filter
	    ## by the number of element to take only the rows where have all these elements

	    my $geplatform_design_row;
	    foreach my $row (@geplatform_design_row) {
		my $count = $schema->resultset('GePlatformDesign')
		                   ->search( platform_id => $row->get_column('platform_id') )
				   ->count();
		if ($count == $elements_n) {
		    $geplatform_design_row = $row;
		}
	    }

            unless (defined $geplatform_design_row) {

                ## If platform_id don't exists into the  db, it will warning with carp and create an empty object
                warn("DATABASE OUTPUT WARNING: Elements specified haven't a Platform. It'll be created an empty platform object.\n");
                $platform = $class->new($schema);

                foreach my $element_name (@{$elements_aref}) {
                    $platform->add_platform_design($element_name);
                }
            }
            else {
                $platform = $class->new( $schema, $geplatform_design_row->get_column('platform_id') );
            }
        }

    }
    else {
            $platform = $class->new($schema);                              ### Create an empty object;
    }

    return $platform;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_geplatform_row, set_geplatform_row

  Usage: my $geplatform_row = $self->get_geplatform_row();
         $self->set_geplatform_row($geplatform_row_object);

  Desc: Get or set a geplatform row object into a platform
        object

  Ret:   Get => $geplatform_row_object, a row object
                (CXGN::GEM::Schema::GePlatform).
         Set => none

  Args:  Get => none
         Set => $geplatform_row_object, a row object
                (CXGN::GEM::Schema::GePlatform).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my $geplatform_row = $self->get_geplatform_row();
           $self->set_geplatform_row($geplatform_row);

=cut

sub get_geplatform_row {
  my $self = shift;

  return $self->{geplatform_row};
}

sub set_geplatform_row {
  my $self = shift;
  my $geplatform_row = shift
      || croak("FUNCTION PARAMETER ERROR: None geplatform_row object was supplied for $self->set_geplatform_row function.\n");

  if (ref($geplatform_row) ne 'CXGN::GEM::Schema::GePlatform') {
      croak("SET ARGUMENT ERROR: $geplatform_row isn't a geplatform_row obj. (CXGN::GEM::Schema::GePlatform).\n");
  }
  $self->{geplatform_row} = $geplatform_row;
}

=head2 accessors get_geplatformdesign_rows, set_geplatformdesign_rows

  Usage: my @geplatformdesign_rows = $self->get_geplatformdesign_rows();
         $self->set_geplatformdesign_rows(\@geplatformdesign_rows);

  Desc: Get or set a geplatformdesign row object into a platform object
        as hash reference where keys = name and value = row object

  Ret:   Get => An array reference with GePlatformDesign object
         Set => none

  Args:  Get => none
         Set => An array with GePlatformDesign row objects
                (CXGN::GEM::Schema::GePlatformDesign).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example:  my @geplatformdesign_rows = $self->get_geplatformdesign_rows();
            $self->set_geplatformdesign_rows(\@geplatformdesign_rows);

=cut

sub get_geplatformdesign_rows {
  my $self = shift;

  return @{$self->{geplatformdesign_rows}};
}

sub set_geplatformdesign_rows {
  my $self = shift;
  my $geplatformdesign_aref = shift
      || croak("FUNCTION PARAMETER ERROR: None ge_platform_design_row hash ref. was supplied for set_geplatformdesign_row function.\n");

  if (ref($geplatformdesign_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: array ref. = $geplatformdesign_aref isn't an array reference.\n");
  }
  else {
      my @geplatformdesign = @{$geplatformdesign_aref};

      foreach my $element_row (@geplatformdesign) {
          unless (ref($element_row) eq 'CXGN::GEM::Schema::GePlatformDesign') {
               croak("SET ARGUMENT ERROR: row obj = $element_row isn't a row obj. (GePlatformDesign).\n");
          }
      }
  }
  $self->{geplatformdesign_rows} = $geplatformdesign_aref;
}


=head2 accessors get_geplatformdbxref_rows, set_geplatformdbxref_rows

  Usage: my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();
         $self->set_geplatformdbxref_rows(\@geplatformdbxref_rows);

  Desc: Get or set a list of geplatformdbxref rows object into an
        platform object

  Ret:   Get => @geplatformdbxref_row_object, a list of row objects
                (CXGN::GEM::Schema::GePlatformDbxref).
         Set => none

  Args:  Get => none
         Set => \@geplatformdbxref_row_object, an array ref of row objects
                (CXGN::GEM::Schema::GePlatformDbxref).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();
           $self->set_geplatformdbxref_rows(\@geplatformdbxref_rows);

=cut

sub get_geplatformdbxref_rows {
  my $self = shift;

  return @{$self->{geplatformdbxref_rows}};
}

sub set_geplatformdbxref_rows {
  my $self = shift;
  my $geplatformdbxref_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR:None geplatformdbxref_row array ref was supplied for $self->set_geplatformdbxref_rows().\n");

  if (ref($geplatformdbxref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $geplatformdbxref_row_aref isn't an array reference for $self->set_geplatformdbxref_rows().\n");
  }
  else {
      foreach my $geplatformdbxref_row (@{$geplatformdbxref_row_aref}) {
          if (ref($geplatformdbxref_row) ne 'CXGN::GEM::Schema::GePlatformDbxref') {
              croak("SET ARGUMENT ERROR:$geplatformdbxref_row isn't geplatformdbxref_row obj.\n");
          }
      }
  }
  $self->{geplatformdbxref_rows} = $geplatformdbxref_row_aref;
}

=head2 accessors get_geplatformpub_rows, set_geplatformpub_rows

  Usage: my @geplatformpub_rows = $self->get_geplatformpub_rows();
         $self->set_geplatformpub_rows(\@geplatformpub_rows);

  Desc: Get or set a list of geplatformpub rows object into an
        platform object

  Ret:   Get => @geplatformpub_row_object, a list of row objects
                (CXGN::GEM::Schema::GePlatformPub).
         Set => none

  Args:  Get => none
         Set => \@geplatformpub_row_object, an array ref of row objects
                (CXGN::GEM::Schema::GePlatformPub).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @geplatformpub_rows = $self->get_geplatformpub_rows();
           $self->set_geplatformpub_rows(\@geplatformpub_rows);

=cut

sub get_geplatformpub_rows {
  my $self = shift;

  return @{$self->{geplatformpub_rows}};
}

sub set_geplatformpub_rows {
  my $self = shift;
  my $geplatformpub_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR:None geplatformpub_row array ref was supplied for $self->set_geplatformpub_rows().\n");

  if (ref($geplatformpub_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $geplatformpub_row_aref isn't an array reference for $self->set_geplatformpub_rows().\n");
  }
  else {
      foreach my $geplatformpub_row (@{$geplatformpub_row_aref}) {
          if (ref($geplatformpub_row) ne 'CXGN::GEM::Schema::GePlatformPub') {
              croak("SET ARGUMENT ERROR:$geplatformpub_row isn't geplatformpub_row obj.\n");
          }
      }
  }
  $self->{geplatformpub_rows} = $geplatformpub_row_aref;
}

###################################
### DATA ACCESSORS FOR PLATFORM ###
###################################

=head2 get_platform_id, force_set_platform_id

  Usage: my $platform_id = $platform->get_platform_id();
         $platform->force_set_platform_id($platform_id);

  Desc: get or set a platform_id in a platform object.
        set method should be USED WITH PRECAUTION
        If you want set a platform_id that do not exists into the
        database you should consider that when you store this object you
        CAN STORE a experiment_id that do not follow the
        gem.ge_platform_platform_id_seq

  Ret:  get=> $platform_id, a scalar.
        set=> none

  Args: get=> none
        set=> $platform_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $platform_id = $platform->get_platform_id();

=cut

sub get_platform_id {
  my $self = shift;
  return $self->get_geplatform_row->get_column('platform_id');
}

sub force_set_platform_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None platform_id was supplied for force_set_platform_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The platform_id ($data) for $self->force_set_platform_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geplatform_row()
       ->set_column( platform_id => $data );

}

=head2 accessors get_platform_name, set_platform_name

  Usage: my $platform_name = $platform->get_platform_name();
         $platform->set_platform_name($platform_name);

  Desc: Get or set the platform_name from platform object.

  Ret:  get=> $platform_name, a scalar
        set=> none

  Args: get=> none
        set=> $platform_name, a scalar

  Side_Effects: none

  Example: my $platform_name = $platform->get_platform_name();
           $platform->set_platform_name($new_name);
=cut

sub get_platform_name {
  my $self = shift;
  return $self->get_geplatform_row->get_column('platform_name');
}

sub set_platform_name {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_platform_name function.\n");

  $self->get_geplatform_row()
       ->set_column( platform_name => $data );
}

=head2 accessors get_technology_type_id, set_technology_type_id

  Usage: my $technology_type_id = $platform->get_technology_type_id();
         $platform->set_technology_type_id($technology_type_id);

  Desc: Get or set technology_type_id from a platform object.

  Ret:  get=> $technology_type_id, a scalar
        set=> none

  Args: get=> none
        set=> $technology_type_id, a scalar

  Side_Effects: For the set accessor, die if the technology_type_id don't
                exists into the database

  Example: my $technology_type_id = $platform->get_technology_type_id();
           $platform->set_technology_type_id($technology_type_id);
=cut

sub get_technology_type_id {
  my $self = shift;
  return $self->get_geplatform_row->get_column('technology_type_id');
}

sub set_technology_type_id {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_technology_type function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The technology_type_id ($data) for $self->set_technology_type_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geplatform_row()
       ->set_column( technology_type_id => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $platform->get_description();
         $platform->set_description($description);

  Desc: Get or set description from a platform object.

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: None

  Example: my $description = $platform->get_description();
           $platform->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_geplatform_row->get_column('description');
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_geplatform_row()
       ->set_column( description => $data );
}

=head2 get_contact_id, set_contact_id

  Usage: my $contact_id = $platform->get_contact_id();
         $platform->set_contact_id($contact_id);

  Desc: get or set a contact_id in a platform object.

  Ret:  get=> $contact_id, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_id, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact_id = $platform->get_contact_id();

=cut

sub get_contact_id {
  my $self = shift;
  return $self->get_geplatform_row->get_column('contact_id');
}

sub set_contact_id {
  my $self = shift;
  my $data = shift;

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The contact_id ($data) for $self->set_contact_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geplatform_row()
       ->set_column( contact_id => $data );

}

=head2 get_contact_by_username, set_contact_by_username

  Usage: my $contact_username = $platform->get_contact_by_username();
         $platform->set_contact_by_username($contact_username);

  Desc: get or set a contact_id in a platform object using username

  Ret:  get=> $contact_username, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_username, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact = $platform->get_contact_by_username();

=cut

sub get_contact_by_username {
  my $self = shift;

  my $contact_id = $self->get_geplatform_row
                        ->get_column('contact_id');

  if (defined $contact_id) {

      ## This is a temp simple SQL query. It should be replaced by DBIx::Class search when the person module will be developed

      my $query = "SELECT username FROM sgn_people.sp_person WHERE sp_person_id = ?";
      my ($username) = $self->get_schema()
                            ->storage()
                            ->dbh()
                            ->selectrow_array($query, undef, $contact_id);

      unless (defined $username) {
          croak("DATABASE INTEGRITY ERROR: sp_person_id=$contact_id defined in gem.ge_platform don't exists in sp_person table.\n")
      }
      else {
          return $username
      }
  }
}

sub set_contact_by_username {
  my $self = shift;
  my $data = shift ||
      croak("SET ARGUMENT ERROR: None argument was supplied to the $self->set_contact_by_username function.\n");

  my $query = "SELECT sp_person_id FROM sgn_people.sp_person WHERE username = ?";
  my ($contact_id) = $self->get_schema()
                          ->storage()
                          ->dbh()
                          ->selectrow_array($query, undef, $data);

  unless (defined $contact_id) {
      croak("DATABASE COHERENCE ERROR: username=$data supplied to function set_contact_by_username don't exists in sp_person table.\n");
  }
  else {
      $self->get_geplatform_row()
           ->set_column( contact_id => $contact_id );
  }

}




##########################################
### DATA ACCESSORS FOR PLATFORM DESIGN ###
##########################################

=head2 add_platform_design

  Usage: $platform->add_platform_design( $sample_name );

  Desc: Add a new platform design element to the platform object

  Ret: None

  Args: A scalar with the sample_name

  Side_Effects: Die if the sample_name don't exists into the database

  Example: $platform->add_platform_design('tomato_unigene_dataset');

=cut

sub add_platform_design {
    my $self = shift;
    my $scalar = shift ||
        croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->add_platform_design function.\n");

    my $platformdesign_row;

    ## Search in the database a sample name (biosource tables) and get the sample_id. Die if don't find anything.

    my ($sample_row) = $self->get_schema()
	                    ->resultset('BsSample')
			    ->search( { sample_name => $scalar } );
    if (defined $sample_row) {
        my $sample_id = $sample_row->get_column('sample_id');

	$platformdesign_row = $self->get_schema()
                                   ->resultset('GePlatformDesign')
                                   ->new({ sample_id => $sample_id});

	if (defined $self->get_platform_id() ) {
	    $platformdesign_row->set_column( platform_id => $self->get_platform_id() );
	}
    }
    else {
	croak("DATABASE COHERENCE ERROR for add_platform_design: Sample_name ($scalar) don't exists in database.\n");
    }

    my @platformdesign_rows = $self->get_geplatformdesign_rows();
    push @platformdesign_rows, $platformdesign_row;
    $self->set_geplatformdesign_rows(\@platformdesign_rows);
}

=head2 get_design_list

  Usage: my @design_list_id = $platform->get_design_list();

  Desc: Get a list of sample_names associated to this platform.

  Ret: An array of scalars (sample_id by default)

  Args: None or a column to get ('sample_name').

  Side_Effects: None

  Example: my @sample_id_list = $platform->get_design_list();
           my @sample_name_list = $platform->get_design_list('sample_name');

=cut

sub get_design_list {
    my $self = shift;
    my $field = shift;

    my @design_list = ();

    my @platformdesign_rows = $self->get_geplatformdesign_rows();
    foreach my $platformdesign_row (@platformdesign_rows) {
        my $sample_id = $platformdesign_row->get_column('sample_id');

	if (defined $field && $field =~ m/sample_name/i) {
	    my ($sample_row) = $self->get_schema()
	                            ->resultset('BsSample')
			            ->search( { sample_id => $sample_id } );
	    if (defined $sample_row) {
		my $sample_name = $sample_row->get_column('sample_name');
		push @design_list, $sample_name;
	    }
	}
	else {
	    push @design_list, $sample_id;
	}
    }

    return @design_list;
}


##########################################
### DATA ACCESSORS FOR PLATFORM DBXREF ###
##########################################

=head2 add_dbxref

  Usage: $platform->add_dbxref($dbxref_id);

  Desc: Add a dbxref to the dbxref_ids associated to sample
        object using dbxref_id or accesion + database_name

  Ret:  None

  Args: $dbxref_id, a dbxref id.
        To use with accession and dbxname:
          $platform->add_dbxref(
                               {
                                 accession => $accesssion,
                                 dbxname   => $dbxname,
			       }
                             );

  Side_Effects: die if the parameter is not an hash reference

  Example: $platform->add_dbxref($dbxref_id);
           $platform->add_dbxref(
                                {
                                  accession => 'GSE3380',
                                  dbxname   => 'GEO Accession Display',
                                }
                              );
=cut

sub add_dbxref {
    my $self = shift;
    my $dbxref = shift ||
        croak("FUNCTION PARAMETER ERROR: None dbxref data was supplied for $self->add_dbxref function.\n");

    my $dbxref_id;

    ## If the imput parameter is an integer, treat it as id, if not do it as hash reference

    if ($dbxref =~ m/^\d+$/) {
        $dbxref_id = $dbxref;
    }
    elsif (ref($dbxref) eq 'HASH') {
        if (exists $dbxref->{'dbxname'}) {
            my ($db_row) = $self->get_schema()
                                 ->resultset('General::Db')
                                 ->search( { name => $dbxref->{'dbxname'} });
	    if (defined $db_row) {
		my $db_id = $db_row->get_column('db_id');

		my ($dbxref_row) = $self->get_schema()
		                        ->resultset('General::Dbxref')
					->search(
		                                   {
                                                      accession => $dbxref->{'accession'},
						      db_id     => $db_id,
                                                   }
                                                );
		if (defined $dbxref_row) {
		    $dbxref_id = $dbxref_row->get_column('dbxref_id');
		}
		else {
		    croak("DATABASE ARGUMENT ERROR: accession specified as argument in function $self->add_dbxref dont exists in db.\n");
		}
	    }
	    else {
		croak("DATABASE ARGUMENT ERROR: dbxname specified as argument in function $self->add_dbxref dont exists in db.\n");
	    }
	}
	else {
	    croak("INPUT ARGUMENT ERROR: None dbxname was supplied as hash ref. argument in the function $self->add_dbxref.\n ");
	}
    }
    else {
        croak("SET ARGUMENT ERROR: The dbxref ($dbxref) isn't a dbxref_id, or hash ref. with accession and dbxname keys.\n");
    }

    my $platformdbxref_row = $self->get_schema()
                                ->resultset('GePlatformDbxref')
                                ->new({ dbxref_id => $dbxref_id});

    if (defined $self->get_platform_id() ) {
        $platformdbxref_row->set_column( platform_id => $self->get_platform_id() );
    }

    my @platformdbxref_rows = $self->get_geplatformdbxref_rows();
    push @platformdbxref_rows, $platformdbxref_row;
    $self->set_geplatformdbxref_rows(\@platformdbxref_rows);
}

=head2 get_dbxref_list

  Usage: my @dbxref_list_id = $platform->get_publication_list();

  Desc: Get a list of dbxref_id associated to this platform.

  Ret: An array of dbxref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbxref_id_list = $platform->get_dbxref_list();

=cut

sub get_dbxref_list {
    my $self = shift;

    my @dbxref_list = ();

    my @platformdbxref_rows = $self->get_geplatformdbxref_rows();
    foreach my $platformdbxref_row (@platformdbxref_rows) {
        my $dbxref_id = $platformdbxref_row->get_column('dbxref_id');
	push @dbxref_list, $dbxref_id;
    }

    return @dbxref_list;
}

#########################################
### DATA ACCESSORS FOR PLATFORMS PUBS ###
#########################################

=head2 add_publication

  Usage: $platform->add_publication($pub_id);

  Desc: Add a publication to the pub_ids associated to platform
        object using different arguments as pub_id, title or dbxref_accession

  Ret:  None

  Args: $pub_id, a publication id.
        To use with $pub_id:
          $platform->add_publication($pub_id);
        To use with $pub_title
          $platform->add_publication({ title => $pub_title } );
        To use with pubmed accession
          $platform->add_publication({ dbxref_accession => $accesssion});

  Side_Effects: die if the parameter is not an object

  Example: $platform->add_publication($pub_id);

=cut

sub add_publication {
    my $self = shift;
    my $pub = shift ||
        croak("FUNCTION PARAMETER ERROR: None pub was supplied for $self->add_publication function.\n");

    my $pub_id;
    if ($pub =~ m/^\d+$/) {
        $pub_id = $pub;
    }
    elsif (ref($pub) eq 'HASH') {
        my $pub_row;
        if (exists $pub->{'title'}) {
            ($pub_row) = $self->get_schema()
                              ->resultset('Pub::Pub')
                              ->search( {title => { 'ilike', '%' . $pub->{'title'} . '%' } });
        }
        elsif (exists $pub->{'dbxref_accession'}) {
                ($pub_row) = $self->get_schema()
                              ->resultset('Pub::Pub')
                              ->search(
                                        { 'dbxref.accession' => $pub->{'dbxref_accession'} },
                                        { join => { 'pub_dbxrefs' => 'dbxref' } },
                                      );

        }

        unless (defined $pub_row) {
            croak("DATABASE ARGUMENT ERROR: Publication data used as argument for $self->add_publication function don't exists in DB.\n");
        }
        $pub_id = $pub_row->get_column('pub_id');

    }
    else {
        croak("SET ARGUMENT ERROR: The publication ($pub) isn't a pub_id, or hash with title or dbxref_accession keys.\n");
    }
    my $geplatformpub_row = $self->get_schema()
                                 ->resultset('GePlatformPub')
                                 ->new({ pub_id => $pub_id});

    if (defined $self->get_platform_id() ) {
        $geplatformpub_row->set_column( platform_id => $self->get_platform_id() );
    }

    my @geplatformpub_rows = $self->get_geplatformpub_rows();
    push @geplatformpub_rows, $geplatformpub_row;
    $self->set_geplatformpub_rows(\@geplatformpub_rows);
}

=head2 get_publication_list

  Usage: my @pub_list = $platform->get_publication_list();

  Desc: Get a list of publications associated to this experimental design.

  Ret: An array of pub_ids by default, but can be titles
       or accessions using an argument 'title' or 'dbxref.accession'

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @pub_id_list = $platform->get_publication_list();
           my @pub_title_list = $platform->get_publication_list('title');
           my @pub_title_accs = $platform->get_publication_list('dbxref.accession');


=cut

sub get_publication_list {
    my $self = shift;
    my $field = shift;

    my @pub_list = ();

    my @platformpub_rows = $self->get_geplatformpub_rows();
    foreach my $platformpub_row (@platformpub_rows) {
        my $pub_id = $platformpub_row->get_column('pub_id');
        my ($pub_row) = $self->get_schema()
                             ->resultset('Pub::Pub')
                             ->search(
                                       { 'me.pub_id' => $pub_id },
                                       {
                                         '+select' => ['dbxref.accession'],
                                         '+as'     => ['accession'],
                                         join => { 'pub_dbxrefs' => 'dbxref' },
                                       }
                                     );

        if (defined $field) {
            push @pub_list, $pub_row->get_column($field);
        }
        else {
            push @pub_list, $pub_row->get_column('pub_id');
        }
    }

    return @pub_list;
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_platform_metadbdata

  Usage: my $metadbdata = $platform->get_platform_metadbdata();

  Desc: Get metadata object associated to platform data
        (see CXGN::Metadata::Metadbdata).

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $platform->get_platform_metadbdata();
           my $metadbdata = $platform->get_platform_metadbdata($metadbdata);

=cut

sub get_platform_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my $metadbdata;
  my $metadata_id = $self->get_geplatform_row
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
      my $platform_id = $self->get_platform_id();
      if (defined $platform_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the platform_id=$platform_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any platform_id. Probably it hasn't been stored yet.\n");
      }
  }

  return $metadbdata;
}

=head2 is_platform_obsolete

  Usage: $platform->is_platform_obsolete();

  Desc: Get obsolete field form metadata object associated to
        protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: none

  Side_Effects: none

  Example: unless ($platform->is_experiment_obsolete()) {
                   ## do something
           }

=cut

sub is_platform_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_platform_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();

  if (defined $obsolete) {
      return $obsolete;
  }
  else {
      return 0;
  }
}

=head2 accessors get_platform_design_metadbdata

  Usage: my %metadbdata = $platform->get_platform_design_metadbdata();

  Desc: Get metadata object associated to platform row
        (see CXGN::Metadata::Metadbdata).

  Ret:  A hash with key=sample_name and value=metadbdata object
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $platform->get_platform_design_metadbdata();
           my %metadbdata = $platform->get_platform_design_metadbdata($metadbdata);
           my $metadbdata_1 = $metadbdata{'sample_name1'};

=cut

sub get_platform_design_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @platformdesign_rows = $self->get_geplatformdesign_rows();

  my $platform_id = $self->get_platform_id();
  unless (defined $platform_id) {
      croak("OBJECT MANIPULATION ERROR: The object $self haven't any platform_id associated. Probably it hasn't been stored\n");
  }

  foreach my $platformdesign_row (@platformdesign_rows) {
      my $metadbdata;
      my $metadata_id = $platformdesign_row->get_column('metadata_id');
      my $sample_id = $platformdesign_row->get_column('sample_id');

      unless (defined $sample_id) {
	  croak("OBJECT COHERENCE ERROR: The GePlatformDesign row for the get_platform_design_metadbdata() haven't any sample_id.\n");
      }

      my $sample_name;

      my ($sample) = $self->get_schema()
	                  ->resultset('BsSample')
			  ->search({ sample_id => $sample_id });


      if (defined $sample) {
	  $sample_name = $sample->get_column('sample_name');
      }
      else {
	  croak("DATABASE COHERENCE ERROR: The sample_id=$sample_id from the platform_design row doesn't exists into the database.");
      }

      if (defined $metadata_id) {
          $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
          if (defined $metadata_obj_base) {

              ## This will transfer the creation data from the base object to the new one
              $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
              $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
          }
          $metadbdata{$sample_name} = $metadbdata;
      }
      else {
	  croak("DATABASE INTEGRITY ERROR: metadata_id for sample_name=$sample_name (sample_id=$sample_id) is undefined.\n");
      }
  }

  return %metadbdata;
}

=head2 is_platform_design_obsolete

  Usage: $platform->is_platform_design_obsolete($element_name);

  Desc: Get obsolete field form metadata object associated to
        platform data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $element_name, a scalar, the name for the platform element in the
        object

  Side_Effects: none

  Example: unless ($platform->is_platform_design_obsolete($element_name)) {
                ## do something
           };

=cut

sub is_platform_design_obsolete {
  my $self = shift;
  my $element_name = shift;


  if (defined $element_name) {
      my %metadbdata = $self->get_platform_design_metadbdata();
      my $obsolete = $metadbdata{$element_name}->get_obsolete();

      if (defined $obsolete) {
	  return $obsolete;
      }
      else {
	  return 0;
      }
  }
  else {
      return 0;
  }
}

=head2 accessors get_platform_dbxref_metadbdata

  Usage: my %metadbdata = $platform->get_platform_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data
        (see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=dbxref_id and values=metadbdata object
        (CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $platform->get_platform_dbxref_metadbdata();
           my %metadbdata =
              $platform->get_platform_dbxref_metadbdata($metadbdata);

=cut

sub get_platform_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();

  foreach my $geplatformdbxref_row (@geplatformdbxref_rows) {
      my $dbxref_id = $geplatformdbxref_row->get_column('dbxref_id');
      my $metadata_id = $geplatformdbxref_row->get_column('metadata_id');

      if (defined $metadata_id) {
          my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
          if (defined $metadata_obj_base) {

              ## This will transfer the creation data from the base object to the new one
              $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
              $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
          }
          $metadbdata{$dbxref_id} = $metadbdata;
      }
      else {
          my $platform_dbxref_id = $geplatformdbxref_row->get_column('platform_dbxref_id');
	  unless (defined $platform_dbxref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any platform_dbxref_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the platform_dbxref_id=$platform_dbxref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_platform_dbxref_obsolete

  Usage: $platform->is_platform_dbxref_obsolete($dbxref_id);

  Desc: Get obsolete field form metadata object associated to
        protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $dbxref_id, a dbxref_id

  Side_Effects: none

  Example: unless ($platform->is_platform_dbxref_obsolete($dbxref_id)){
                ## do something
           }

=cut

sub is_platform_dbxref_obsolete {
  my $self = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_platform_dbxref_metadbdata();
  my $metadbdata = $metadbdata{$dbxref_id};

  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}

=head2 accessors get_platform_pub_metadbdata

  Usage: my %metadbdata = $platform->get_platform_pub_metadbdata();

  Desc: Get metadata object associated to tool data
        (see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=pub_id and values=metadbdata object
        (CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $platform->get_platform_pub_metadbdata();
           my %metadbdata = $platform->get_platform_pub_metadbdata($metadbdata);

=cut

sub get_platform_pub_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @geplatformpub_rows = $self->get_geplatformpub_rows();

  foreach my $geplatformpub_row (@geplatformpub_rows) {
      my $pub_id = $geplatformpub_row->get_column('pub_id');
      my $metadata_id = $geplatformpub_row->get_column('metadata_id');

      if (defined $metadata_id) {
          my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
          if (defined $metadata_obj_base) {

              ## This will transfer the creation data from the base object to the new one
              $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
              $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
          }
          $metadbdata{$pub_id} = $metadbdata;
      }
      else {
          my $platform_pub_id = $geplatformpub_row->get_column('platform_pub_id');
	  unless (defined $platform_pub_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any platform_pub_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the platform_pub_id=$platform_pub_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_platform_pub_obsolete

  Usage: $platform->is_platform_dbxref_obsolete($pub_id);

  Desc: Get obsolete field form metadata object associated to
        protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $pub_id, a pub_id

  Side_Effects: none

  Example: unless ($platform->is_platform_pub_obsolete($pub_id)){
                ## do something
           }

=cut

sub is_platform_pub_obsolete {
  my $self = shift;
  my $pub_id = shift;

  my %metadbdata = $self->get_platform_pub_metadbdata();
  my $metadbdata = $metadbdata{$pub_id};

  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}



#######################
### STORING METHODS ###
#######################


=head2 store

  Usage: $platform->store($metadbdata);

  Desc: Store in the database the all platform data for the
        platform object.
        See the methods store_platform, store_platform_design,
        store_dbxref_associations and store_pub_associations for more details

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

    $self->store_platform($metadata);
    $self->store_platform_designs($metadata);
    $self->store_dbxref_associations($metadata);
    $self->store_pub_associations($metadata);
}


=head2 store_platform

  Usage: $platform->store_platform($metadata);

  Desc: Store in the database the platform data for the platform
        object (Only the geplatform row, don't store any
        platform_dbxref or platform_design data)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata
                   object

  Example: $platform->store_platform($metadata);

=cut

sub store_platform {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_platform().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_platform() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not platform_id.
    ##   if exists platform_id         => update
    ##   if do not exists platform_id  => insert

    my $geplatform_row = $self->get_geplatform_row();
    my $platform_id = $geplatform_row->get_column('platform_id');

    unless (defined $platform_id) {                                   ## NEW INSERT and DISCARD CHANGES

	$metadata->store();
	my $metadata_id = $metadata->get_metadata_id();

	$geplatform_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column

	$geplatform_row->insert()
                       ->discard_changes();                           ## It will set the row with the updated row

	## Now we set the platform_id value for all the rows that depends of it

	my @geplatformdesign_rows = $self->get_geplatformdesign_rows();
	foreach my $geplatformdesign_row (@geplatformdesign_rows) {
	    $geplatformdesign_row->set_column( platform_id => $geplatform_row->get_column('platform_id'));
	}

	my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();
	foreach my $geplatformdbxref_row (@geplatformdbxref_rows) {
	    $geplatformdbxref_row->set_column( platform_id => $geplatform_row->get_column('platform_id'));
	}

	my @geplatformpub_rows = $self->get_geplatformpub_rows();
	foreach my $geplatformpub_row (@geplatformpub_rows) {
	    $geplatformpub_row->set_column( platform_id => $geplatform_row->get_column('platform_id'));
	}


    }
    else {                                                            ## UPDATE IF SOMETHING has change

        my @columns_changed = $geplatform_row->is_changed();

        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }

            my $modification_note = join ', ', @modification_note_list;

	    my $mod_metadata = $self->get_platform_metadbdata($metadata);
	    $mod_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id();

	    $geplatform_row->set_column( metadata_id => $mod_metadata_id );

	    $geplatform_row->update()
                           ->discard_changes();
	}
    }
}


=head2 obsolete_platform

  Usage: $platform->obsolete_platform($metadata, $note, 'REVERT');

  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $platform->obsolete_platform($metadata, 'change to obsolete test');

=cut

sub obsolete_platform {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_platform().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_platform isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_platform().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata = $self->get_platform_metadbdata($metadata);
    $mod_metadata->store( { modification_note => $modification_note,
			    obsolete          => $obsolete,
			    obsolete_note     => $obsolete_note } );
    my $mod_metadata_id = $mod_metadata->get_metadata_id();

    ## Modify the group row in the database

    my $geplatform_row = $self->get_geplatform_row();

    $geplatform_row->set_column( metadata_id => $mod_metadata_id );

    $geplatform_row->update()
	           ->discard_changes();
}

=head2 store_platform_designs

  Usage: my $platform = $platform->store_platform_designs($metadata);

  Desc: Store in the database platform_designs associated to a platform

  Ret: None.

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata
                   object

  Example: my $platform = $platform->store_platform_designs($metadata);

=cut

sub store_platform_designs {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_platform_designs().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_platform_designs() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not platform_designs_id.
    ##   if exists platform_designs_id         => update
    ##   if do not exists platform_designs_id  => insert

    my $platform_id = $self->get_platform_id();

    unless (defined $platform_id) {
	croak("STORE ERROR: Don't exist platform_id associated to this step.Use store_platform before use store_platform_designs.\n");
    }

    my @geplatformdesigns_rows = $self->get_geplatformdesign_rows();

    foreach my $geplatformdesign_row (@geplatformdesigns_rows) {
        my $platform_design_id = $geplatformdesign_row->get_column('platform_design_id');

        unless (defined $platform_design_id) {                                  ## NEW INSERT and DISCARD CHANGES

            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $geplatformdesign_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column

            $geplatformdesign_row->insert()
                                 ->discard_changes();                           ## It will set the row with the updated row
        }
        else {                                                                 ## UPDATE IF SOMETHING has change

	    my @columns_changed = $geplatformdesign_row->is_changed();

            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }

                my $modification_note = join ', ', @modification_note_list;

		my %se_metadata = $self->get_platform_design_metadbdata($metadata);
		my $element_name = $geplatformdesign_row->get_column('platform_design_name');
                my $mod_metadata_id = $se_metadata{$element_name}->store({ modification_note => $modification_note })
                                                                 ->get_metadata_id();

                $geplatformdesign_row->set_column( metadata_id => $mod_metadata_id );

                $geplatformdesign_row->update()
                                    ->discard_changes();
            }
        }
    }
}

=head2 obsolete_platform_design

  Usage: my $platform = $platform->obsolete_platform_design( $metadata,
                                                        $note,
                                                        $element_name,
                                                        'REVERT'
                                                      );

  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will
        be reverted to 0 (false)

  Ret: none.

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $element_name, the sample_element_name that identify this sample_element
        optional, 'REVERT'.

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: my $platform = $platform->obsolete_platform_design( $metadata,
                                                          change to obsolete',
                                                          $element_name );

=cut

sub obsolete_platform_design {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
        || croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_platform_design().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_platform_design is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
        || croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_platform_design().\n");

    my $element_name = shift
        || croak("OBSOLETE ERROR: None platform_design_name was supplied to $self->obsolete_platform_design().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
        $obsolete = 0;
        $modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %platform_design_metadata = $self->get_platform_design_metadbdata($metadata);
    my $mod_metadata_id = $platform_design_metadata{$element_name}->store( {
	                                                                    modification_note => $modification_note,
									    obsolete          => $obsolete,
									    obsolete_note     => $obsolete_note
                                                                          } )
                                                                 ->get_metadata_id();

    ## Modify the group row in the database

    my @geplatformdesign_rows = $self->get_geplatformdesign_rows();

    foreach my $geplatformdesign_row (@geplatformdesign_rows) {
	my $sample_name;
	my $sample_id = $geplatformdesign_row->get_column('sample_id');
	if (defined $sample_id) {
	    my ($sample) = $self->get_schema()
		                ->resultset('BsSample')
			        ->search({ sample_id => $sample_id });

	    if (defined $sample) {
		$sample_name = $sample->get_column('sample_name');
	    }
	}
	if ($sample_name eq $element_name) {
	    $geplatformdesign_row->set_column( metadata_id => $mod_metadata_id );
	    $geplatformdesign_row->update()
	                         ->discard_changes();
	}
    }
}


=head2 store_dbxref_associations

  Usage: $platform->store_dbxref_associations($metadata);

  Desc: Store in the database the dbxref association for the platform
        object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata
                   object

  Example: $platform->store_dbxref_associations($metadata);

=cut

sub store_dbxref_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_dbxref_associations().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_dbxref_associations() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not platform_dbxref_id.
    ##   if exists platform_dbxref_id         => update
    ##   if do not exists platform_dbxref_id  => insert

    my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();

    foreach my $geplatformdbxref_row (@geplatformdbxref_rows) {

        my $platform_dbxref_id = $geplatformdbxref_row->get_column('platform_dbxref_id');
	my $dbxref_id = $geplatformdbxref_row->get_column('dbxref_id');

        unless (defined $platform_dbxref_id) {                                ## NEW INSERT and DISCARD CHANGES

            $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

            $geplatformdbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

            $geplatformdbxref_row->insert()
                                 ->discard_changes();                            ## It will set the row with the updated row

        }
        else {                                                                    ## UPDATE IF SOMETHING has change

            my @columns_changed = $geplatformdbxref_row->is_changed();

            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }

                my $modification_note = join ', ', @modification_note_list;

		my %asdbxref_metadata = $self->get_platform_dbxref_metadbdata($metadata);
		my $mod_metadata = $asdbxref_metadata{$dbxref_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

                $geplatformdbxref_row->set_column( metadata_id => $mod_metadata_id );

                $geplatformdbxref_row->update()
                                   ->discard_changes();
            }
        }
    }
}

=head2 obsolete_dbxref_association

  Usage: $platform->obsolete_dbxref_association($metadata, $note, $dbxref_id, 'REVERT');

  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $dbxref_id, a dbxref id
        optional, 'REVERT'.

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $platform->obsolete_dbxref_association($metadata,
                                                    'change to obsolete test',
                                                    $dbxref_id );

=cut

sub obsolete_dbxref_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_dbxref_association().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_dbxref_association is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_dbxref_association().\n");

    my $dbxref_id = shift
	|| croak("OBSOLETE ERROR: None dbxref_id was supplied to $self->obsolete_dbxref_association().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %asdbxref_metadata = $self->get_platform_dbxref_metadbdata($metadata);
    my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store( { modification_note => $modification_note,
						     	           obsolete          => $obsolete,
							           obsolete_note     => $obsolete_note } )
                                                        ->get_metadata_id();

    ## Modify the group row in the database

    my @geplatformdbxref_rows = $self->get_geplatformdbxref_rows();
    foreach my $geplatformdbxref_row (@geplatformdbxref_rows) {
	if ($geplatformdbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $geplatformdbxref_row->set_column( metadata_id => $mod_metadata_id );

	    $geplatformdbxref_row->update()
	                       ->discard_changes();
	}
    }
}

=head2 store_pub_associations

  Usage: $platform->store_pub_associations($metadata);

  Desc: Store in the database the pub association for the platform
        object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata
                   object

  Example: $platform->store_pub_associations($metadata);

=cut

sub store_pub_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_dbxref_associations().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_dbxref_associations() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not platform_dbxref_id.
    ##   if exists platform_pub_id         => update
    ##   if do not exists platform_pub_id  => insert

    my @geplatformpub_rows = $self->get_geplatformpub_rows();

    foreach my $geplatformpub_row (@geplatformpub_rows) {

        my $platform_pub_id = $geplatformpub_row->get_column('platform_pub_id');
	my $pub_id = $geplatformpub_row->get_column('pub_id');

        unless (defined $platform_pub_id) {                                ## NEW INSERT and DISCARD CHANGES

            $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

            $geplatformpub_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

            $geplatformpub_row->insert()
                                 ->discard_changes();                            ## It will set the row with the updated row

        }
        else {                                                                    ## UPDATE IF SOMETHING has change

            my @columns_changed = $geplatformpub_row->is_changed();

            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }

                my $modification_note = join ', ', @modification_note_list;

		my %aspub_metadata = $self->get_platform_pub_metadbdata($metadata);
		my $mod_metadata = $aspub_metadata{$pub_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

                $geplatformpub_row->set_column( metadata_id => $mod_metadata_id );

                $geplatformpub_row->update()
                                  ->discard_changes();
            }
        }
    }
}

=head2 obsolete_pub_association

  Usage: $platform->obsolete_pub_association($metadata, $note, $pub_id, 'REVERT');

  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $pub_id, a pub_id
        optional, 'REVERT'.

  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $platform->obsolete_pub_association($metadata,
                                               'change to obsolete test',
                                               $pub_id );

=cut

sub obsolete_pub_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_pub_association().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_pub_association is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_pub_association().\n");

    my $pub_id = shift
	|| croak("OBSOLETE ERROR: None pub_id was supplied to $self->obsolete_pub_association().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %aspub_metadata = $self->get_platform_pub_metadbdata($metadata);
    my $mod_metadata_id = $aspub_metadata{$pub_id}->store( { modification_note => $modification_note,
		      	    		       	             obsolete          => $obsolete,
						             obsolete_note     => $obsolete_note } )
                                                  ->get_metadata_id();

    ## Modify the group row in the database

    my @geplatformpub_rows = $self->get_geplatformpub_rows();
    foreach my $geplatformpub_row (@geplatformpub_rows) {
	if ($geplatformpub_row->get_column('pub_id') == $pub_id) {

	    $geplatformpub_row->set_column( metadata_id => $mod_metadata_id );

	    $geplatformpub_row->update()
	                      ->discard_changes();
	}
    }
}



#####################
### OTHER METHODS ###
#####################

=head2 get_technology_type

  Usage: my $technologytype = $platform->get_technology_type();

  Desc: Get a CXGN::GEM::TechnologyType object.

  Ret:  A CXGN::GEM::TechnologyType object.

  Args: none

  Side_Effects: die if the platform object have not any
                technology_type_id

  Example: my $technologytype = $platform->get_technology_type();

=cut

sub get_technology_type {
   my $self = shift;

   my $technology_type_id = $self->get_technology_type_id();

   unless (defined $technology_type_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any technology_type_id. Probably it hasn't store yet.\n");
   }

   my $techtype = CXGN::GEM::TechnologyType->new($self->get_schema(), $technology_type_id);

   return $techtype;
}


=head2 get_template_list

  Usage: my @templates = $platform->get_template_list();

  Desc: Get a list of CXGN::GEM::Template objects.

  Ret:  An array of CXGN::GEM::Templates objects.

  Args: none

  Side_Effects: die if the platform object have not any
                platform_id

  Example: my @templates = $platform->get_template_list();

=cut

sub get_template_list {
   my $self = shift;

   my @templates = ();

   my $platform_id = $self->get_platform_id();

   unless (defined $platform_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any platform_id. Probably it hasn't store yet.\n");
   }

   my @getemplate_rows = $self->get_schema()
                              ->resultset('GeTemplate')
			      ->search( { platform_id => $platform_id } );

   foreach my $getemplate_row (@getemplate_rows) {

       my $template = CXGN::GEM::Template->new($self->get_schema(), $getemplate_row->get_column('template_id') );

       push @templates, $template;
   }

   return @templates;
}

=head2 count_templates

  Usage: my $template_count = $platform->count_templates();

  Desc: Count how many templates has associated this platform

  Ret:  $templates_n, a scalar

  Args: none

  Side_Effects: return undef if the platform has not platform_id

  Example: my $templates_n = $platform->count_templates();

=cut

sub count_templates {
    my $self = shift;

    my $templates_count;

    my $platform_id = $self->get_platform_id();

    if (defined $platform_id) {
	$templates_count = $self->get_schema()
	                        ->resultset('GeTemplate')
				->search({ platform_id => $platform_id })
				->count();
    }

    return $templates_count;
}

=head2 count_probes

  Usage: my $probe_count = $platform->count_probes();

  Desc: Count how many probes has associated this platform

  Ret:  $probes_count, a scalar

  Args: none

  Side_Effects: return undef if the platform has not platform_id

  Example: my $probes_n = $platform->count_probes();

=cut

sub count_probes {
    my $self = shift;

    my $probes_count;

    my $platform_id = $self->get_platform_id();

    if (defined $platform_id) {
	$probes_count = $self->get_schema()
	                     ->resultset('GeProbe')
			     ->search({ platform_id => $platform_id })
			     ->count();
    }

    return $probes_count;
}

####
1;##
####
