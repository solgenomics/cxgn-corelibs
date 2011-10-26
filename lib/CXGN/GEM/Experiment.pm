
package CXGN::GEM::Experiment;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::GEM::ExperimentalDesign;
use CXGN::GEM::Target;

use Carp qw| croak cluck |;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Experiment
a class to manipulate a experiment data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Experiment;

 ## Constructor

 my $experiment = CXGN::GEM::Experiment->new($schema, $exp_id); 

 ## Simple accessors

 my $exp_name = $experiment->get_experiment_name();
 $experiment->set_experiment_name($new_name);

 ## Extended accessors 

 my @dbxref_id_list = $experiment->get_dbxref_list();
 $experiment->add_dbxref($dbxref_id);

 ## Metadata functions (aplicable to extended data as dbxref)

 my $metadbdata = $experiment->get_experiment_metadbdata();

 if ($experiment->is_experiment_obsolete()) {
    ## Do something
 }

 ## Store functions (aplicable to extended data as dbxref)

 $experiment->store($metadbdata);

 $experiment->obsolete_experiment($metadata, 'change to obsolete test');



=head1 DESCRIPTION

 This object manage the experiment information of the database
 from the tables:
  
   + gem.ge_experiment
   + gem.ge_experiment_dbxref

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %Experiment_Object = ( 
    
       ge_experiment_row        => GeExperiment_row, 
                     
       ge_experiment_dbxref_row => [ @GeExperimentDbxref_rows],
    
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

  Usage: my $experiment = CXGN::GEM::Experiment->new($schema, $experiment_id);

  Desc: Create a new experiment object

  Ret: a CXGN::GEM::Experiment object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        A $experiment_id, a scalar.
        If $experiment_id is omitted, an empty experimental design object is 
        created.

  Side_Effects: access to database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $experiment = CXGN::GEM::Experiment->new($schema,$exp_id);

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
    ### this row in the database and after that get the data for experiment
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $exper;
    my @exper_dbxrefs = ();
 
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The experiment_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_experiment_row object using a search based in the experiment_id 

	($exper) = $schema->resultset('GeExperiment')
	                  ->search( { experiment_id => $id } );

	if (defined $exper) {
	
	    ## Search experiment_dbxref associations
	
	    @exper_dbxrefs = $schema->resultset('GeExperimentDbxref')
	                            ->search( { experiment_id => $id } );
	}
	else {
	    $exper = $schema->resultset('GeExperiment')
	                    ->new({});  
	}
	
    }
    else {
	$exper = $schema->resultset('GeExperiment')
	                ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_geexperiment_row($exper);
    $self->set_geexperimentdbxref_rows(\@exper_dbxrefs);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $experiment = CXGN::GEM::Experiment->new_by_name($schema, $name);
 
  Desc: Create a new Experiment object using experiment_name
 
  Ret: a CXGN::GEM::Experiment object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $experiment_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the experiment name do not exists 
                into the db
 
  Example: my $experiment = CXGN::GEM::Experiment->new_by_name($schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the experiment_id for this name and it will get the experiment_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the experiment_name for it
  
    my $exper;

    if (defined $name) {
	my ($exper_row) = $schema->resultset('GeExperiment')
	                         ->search({ experiment_name => $name });

	unless (defined $exper_row) {                

	    warn("\nWARNING: experiment_name ($name) for $class->new_by_name() does not exist in the database.\n" );
	    
	    ## If do not exists any experimental design with this name, it will return a warning and it will create an empty
            ## object with the exprimental design name set in it.

	    $exper = $class->new($schema);
	    $exper->set_experiment_name($name);
	}
	else {

	    ## if exists it will take the experiment_id to create the object with the new constructor
	    $exper = $class->new( $schema, $exper_row->get_column('experiment_id') ); 
	}
    } 
    else {
	$exper = $class->new($schema);                              ### Create an empty object;
    }
   
    return $exper;
}



##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_geexperiment_row, set_geexperiment_row

  Usage: my $geexperiment_row = $self->get_geexperiment_row();
         $self->set_geexperiment_row($geexperiment_row_object);

  Desc: Get or set a geexperiment row object into a experiment
        object
 
  Ret:   Get => $geexperiment_row_object, a row object 
                (CXGN::GEM::Schema::GeExperriment).
         Set => none
 
  Args:  Get => none
         Set => $geexperiment_row_object, a row object 
                (CXGN::GEM::Schema::GeExperiment).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $geexperiment_row = $self->get_geexperiment_row();
           $self->set_geexperiment_row($geexperiment_row);

=cut

sub get_geexperiment_row {
  my $self = shift;
 
  return $self->{geexperiment_row}; 
}

sub set_geexperiment_row {
  my $self = shift;
  my $geexperiment_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None geexperiment_row object was supplied for $self->set_geexperiment_row function.\n");
 
  if (ref($geexperiment_row) ne 'CXGN::GEM::Schema::GeExperiment') {
      croak("SET ARGUMENT ERROR: $geexperiment_row isn't a geexperiment_row obj. (CXGN::GEM::Schema::GeExperiment).\n");
  }
  $self->{geexperiment_row} = $geexperiment_row;
}



=head2 accessors get_geexperimentdbxref_rows, set_geexperimentdbxref_rows

  Usage: my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();
         $self->set_geexperimentdbxref_rows(\@geexperimentdbxref_rows);

  Desc: Get or set a list of geexperimentdbxref rows object into an
        experiment object
 
  Ret:   Get => @geexperimentdbxref_row_object, a list of row objects 
                (CXGN::GEM::Schema::GeExperimentDbxref).
         Set => none
 
  Args:  Get => none
         Set => \@gexperimentdbxref_row_object, an array ref of row objects 
                (CXGN::GEM::Schema::GeExperimentDbxref).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();
           $self->set_geexperimentdbxref_rows(\@geexperimentdbxref_rows);

=cut

sub get_geexperimentdbxref_rows {
  my $self = shift;
 
  return @{$self->{geexperimentdbxref_rows}}; 
}

sub set_geexperimentdbxref_rows {
  my $self = shift;
  my $geexperimentdbxref_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR:None geexperimentdbxref_row array ref was supplied for $self->set_geexperimentdbxref_rows().\n");
 
  if (ref($geexperimentdbxref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $geexperimentdbxref_row_aref isn't an array reference for $self->set_geexperimentdbxref_rows().\n");
  }
  else {
      foreach my $geexperimentdbxref_row (@{$geexperimentdbxref_row_aref}) {  
          if (ref($geexperimentdbxref_row) ne 'CXGN::GEM::Schema::GeExperimentDbxref') {
              croak("SET ARGUMENT ERROR:$geexperimentdbxref_row isn't geexperimentdbxref_row obj.\n");
          }
      }
  }
  $self->{geexperimentdbxref_rows} = $geexperimentdbxref_row_aref;
}



#####################################
### DATA ACCESSORS FOR EXPERIMENT ###
#####################################

=head2 get_experiment_id, force_set_experiment_id
  
  Usage: my $experiment_id = $experiment->get_experiment_id();
         $experiment->force_set_experiment_id($experiment_id);

  Desc: get or set a experiment_id in a experiment object. 
        set method should be USED WITH PRECAUTION
        If you want set a experiment_id that do not exists into the 
        database you should consider that when you store this object you 
        CAN STORE a experiment_id that do not follow the 
        gem.ge_experiment_experiment_id_seq

  Ret:  get=> $experiment_id, a scalar.
        set=> none

  Args: get=> none
        set=> $experiment_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $experiment_id = $experiment->get_experiment_id(); 

=cut

sub get_experiment_id {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('experiment_id');
}

sub force_set_experiment_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None experiment_id was supplied for force_set_experiment_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The experiment_id ($data) for $self->force_set_experiment_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geexperiment_row()
       ->set_column( experiment_id => $data );
 
}

=head2 accessors get_experiment_name, set_experiment_name

  Usage: my $experiment_name = $experiment->get_experimental_name();
         $experiment->set_experiment_name($experiment_name);

  Desc: Get or set the experiment_name from experiment object. 

  Ret:  get=> $experiment_name, a scalar
        set=> none

  Args: get=> none
        set=> $experiment_name, a scalar

  Side_Effects: none

  Example: my $experiment_name = $sample->get_experiment_name();
           $experiment->set_experiment_name($new_name);
=cut

sub get_experiment_name {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('experiment_name'); 
}

sub set_experiment_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_experiment_name function.\n");

  $self->get_geexperiment_row()
       ->set_column( experiment_name => $data );
}

=head2 accessors get_experimental_design_id, set_experimental_design_id

  Usage: my $expdesign_id = $experiment->get_experimental_design_id();
         $experiment->set_experimental_design_id($expdesign_id);
 
  Desc: Get or set experimental_design_id from a experiment object. 
 
  Ret:  get=> $expdesign_id, a scalar
        set=> none
 
  Args: get=> none
        set=> $expdesign_id, a scalar
 
  Side_Effects: For the set accessor, die if the expdesign_id don't
                exists into the database
 
  Example: my $expdesign_id = $experiment->get_experimental_design_id();
           $experiment->set_experimental_design_id($expdesign_id);
=cut

sub get_experimental_design_id {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('experimental_design_id'); 
}

sub set_experimental_design_id {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_experimental_design_id() function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The experimental_design_id ($data) for $self->set_experimental_design_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geexperiment_row()
       ->set_column( experimental_design_id => $data );
}

=head2 accessors get_replicates_nr, set_replicates_nr

  Usage: my $replicates_nr = $experiment->get_replicates_nr();
         $experiment->set_replicates_nr($replicates_nr);

  Desc: Get or set the replicates_nr from an experiment object 

  Ret:  get=> $replicate_nr, a scalar
        set=> none

  Args: get=> none
        set=> $replicate_nr, a scalar

  Side_Effects: none

  Example: my $replicates_nr = $experiment->get_replicates_nr();
           $experiment->set_replicates_nr($replicates);
=cut

sub get_replicates_nr {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('replicates_nr'); 
}

sub set_replicates_nr {
  my $self = shift;
  my $data = shift;

  if ($data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA ARGUMENT ERROR: $data suplied to $self->set_replicate_nr function is not an integer.\n");
      }
  }

  $self->get_geexperiment_row()
       ->set_column( replicates_nr => $data );
}

=head2 accessors get_colour_nr, set_colour_nr

  Usage: my $colour_nr = $experiment->get_colour_nr();
         $experiment->set_colour_nr($colour_nr);

  Desc: Get or set the colour_nr from an experiment object 

  Ret:  get=> $colour_nr, a scalar
        set=> none

  Args: get=> none
        set=> $colour_nr, a scalar

  Side_Effects: none

  Example: my $colour_nr = $experiment->get_colour_nr();
           $experiment->set_colour_nr($colour);
=cut

sub get_colour_nr {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('colour_nr'); 
}

sub set_colour_nr {
  my $self = shift;
  my $data = shift;

  if ($data) {
      unless ($data =~ m/^\d+$/) {
	  croak("DATA ARGUMENT ERROR: $data suplied to $self->set_colour_nr function is not an integer.\n");
      }
  }

  $self->get_geexperiment_row()
       ->set_column( colour_nr => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $experiment->get_description();
         $experiment->set_description($description);

  Desc: Get or set the description from an experiment object 

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: none

  Example: my $description = $experiment->get_description();
           $experiment->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('description'); 
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_geexperiment_row()
       ->set_column( description => $data );
}

=head2 get_contact_id, set_contact_id
  
  Usage: my $contact_id = $experiment->get_contact_id();
         $experiment->set_contact_id($contact_id);

  Desc: get or set a contact_id in a experiment object. 

  Ret:  get=> $contact_id, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_id, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact_id = $experiment->get_contact_id(); 

=cut

sub get_contact_id {
  my $self = shift;
  return $self->get_geexperiment_row->get_column('contact_id');
}

sub set_contact_id {
  my $self = shift;
  my $data = shift;

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The contact_id ($data) for $self->set_contact_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geexperiment_row()
       ->set_column( contact_id => $data );
 
}

=head2 get_contact_by_username, set_contact_by_username
  
  Usage: my $contact_username = $experiment->get_contact_by_username();
         $experiment->set_contact_by_username($contact_username);

  Desc: get or set a contact_id in a experiment object using username 

  Ret:  get=> $contact_username, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_username, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact = $experiment->get_contact_by_username(); 

=cut

sub get_contact_by_username {
  my $self = shift;

  my $contact_id = $self->get_geexperiment_row
                        ->get_column('contact_id');

  if (defined $contact_id) {

      ## This is a temp simple SQL query. It should be replaced by DBIx::Class search when the person module will be developed 

      my $query = "SELECT username FROM sgn_people.sp_person WHERE sp_person_id = ?";
      my ($username) = $self->get_schema()
	                    ->storage()
			    ->dbh()
			    ->selectrow_array($query, undef, $contact_id);

      unless (defined $username) {
	  croak("DATABASE INTEGRITY ERROR: sp_person_id=$contact_id defined in gem.ge_experiment don't exists in sp_person table.\n")
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
      $self->get_geexperiment_row()
	   ->set_column( contact_id => $contact_id );
  }
 
}


############################################
### DATA ACCESSORS FOR EXPERIMENT DBXREF ###
############################################

=head2 add_dbxref

  Usage: $experiment->add_dbxref($dbxref_id);

  Desc: Add a dbxref to the dbxref_ids associated to experiment
        object using dbxref_id or accesion + database_name 

  Ret:  None

  Args: $dbxref_id, a dbxref id. 
        To use with accession and dbxname:
          $experiment->add_dbxref( 
                                   { 
                                      accession => $accesssion,
                                      dbxname   => $dbxname,
                                   }
                                 );
          
  Side_Effects: die if the parameter is not an hash reference

  Example: $experiment->add_dbxref($dbxref_id);
           $experiment->add_dbxref( 
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

    my $experimentdbxref_row = $self->get_schema()
                                    ->resultset('GeExperimentDbxref')
                                    ->new({ dbxref_id => $dbxref_id});
    
    if (defined $self->get_experiment_id() ) {
        $experimentdbxref_row->set_column( experiment_id => $self->get_experiment_id() );
    }

    my @experimentdbxref_rows = $self->get_geexperimentdbxref_rows();
    push @experimentdbxref_rows, $experimentdbxref_row;
    $self->set_geexperimentdbxref_rows(\@experimentdbxref_rows);
}

=head2 get_dbxref_list

  Usage: my @dbxref_list_id = $experiment->get_publication_list();

  Desc: Get a list of dbxref_id associated to this experiment.

  Ret: An array of dbxref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbxref_id_list = $experiment->get_dbxref_list();

=cut

sub get_dbxref_list {
    my $self = shift;

    my @dbxref_list = ();

    my @experimentdbxref_rows = $self->get_geexperimentdbxref_rows();
    foreach my $experimentdbxref_row (@experimentdbxref_rows) {
        my $dbxref_id = $experimentdbxref_row->get_column('dbxref_id');
	push @dbxref_list, $dbxref_id;
    }
    
    return @dbxref_list;                  
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_experiment_metadbdata

  Usage: my $metadbdata = $experiment->get_experiment_metadbdata();

  Desc: Get metadata object associated to experiment data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $target->get_experiment_metadbdata();
           my $metadbdata = $target->get_experiment_metadbdata($metadbdata);

=cut

sub get_experiment_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_geexperiment_row
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
      my $experiment_id = $self->get_experiment_id();
      if (defined $experiment_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the experiment_id=$experiment_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any experiment_id. Probably it hasn't been stored yet.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_experiment_obsolete

  Usage: $experiment->is_experiment_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($experiment->is_experiment_obsolete()) { 
                   ## do something 
           }

=cut

sub is_experiment_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_experiment_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}


=head2 accessors get_experiment_dbxref_metadbdata

  Usage: my %metadbdata = $experiment->get_experiment_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=dbxref_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata) for pub relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $experiment->get_experiment_dbxref_metadbdata();
           my %metadbdata = 
              $experiment->get_experiment_dbxref_metadbdata($metadbdata);

=cut

sub get_experiment_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();

  foreach my $geexperimentdbxref_row (@geexperimentdbxref_rows) {
      my $dbxref_id = $geexperimentdbxref_row->get_column('dbxref_id');
      my $metadata_id = $geexperimentdbxref_row->get_column('metadata_id');

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
          my $experiment_dbxref_id = $geexperimentdbxref_row->get_column('experiment_dbxref_id');
	  unless (defined $experiment_dbxref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any experiment_dbxref_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the experiment_dbxref_id=$experiment_dbxref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_experiment_dbxref_obsolete

  Usage: $experiment->is_experiment_dbxref_obsolete($dbxref_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $dbxref_id, a dbxref_id
  
  Side_Effects: none
  
  Example: unless ($experiment->is_experiment_dbxref_obsolete($dbxref_id)){
                ## do something 
           }

=cut

sub is_experiment_dbxref_obsolete {
  my $self = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_experiment_dbxref_metadbdata();
  my $metadbdata = $metadbdata{$dbxref_id};
  
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

  Usage: $experiment->store($metadbdata);
 
  Desc: Store in the database the all experiment data for the 
        experimental design object.
        See the methods store_experiment and store_dbxref_associations 
        for more details

  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $experiment->store($metadata);

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

    $self->store_experiment($metadata);
    $self->store_dbxref_associations($metadata);
}



=head2 store_experiment

  Usage: $experiment->store_experiment($metadata);
 
  Desc: Store in the database the experiment data for the experiment
        design object (Only the geexpdesign row, don't store any 
        experimental_design_dbxref data)
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $experiment->store_experiment($metadata);

=cut

sub store_experiment {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_experiment().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_experiment() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not experiment_id. 
    ##   if exists experiment_id         => update
    ##   if do not exists experiment_id  => insert

    my $geexperiment_row = $self->get_geexperiment_row();
    my $experiment_id = $geexperiment_row->get_column('experiment_id');

    unless (defined $experiment_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$geexperiment_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$geexperiment_row->insert()
                         ->discard_changes();                           ## It will set the row with the updated row
	
	## Now we set the experiment_id value for all the rows that depends of it
	
	my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();
	foreach my $geexperimentdbxref_row (@geexperimentdbxref_rows) {
	    $geexperimentdbxref_row->set_column( experiment_id => $geexperiment_row->get_column('experiment_id'));
	}

	          
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $geexperiment_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_experiment_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $geexperiment_row->set_column( metadata_id => $mod_metadata_id );

	    $geexperiment_row->update()
                             ->discard_changes();
	}
    }
}


=head2 obsolete_experiment

  Usage: $experiment->obsolete_experiment($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $experiment->obsolete_experiment($metadata, 'change to obsolete test');

=cut

sub obsolete_experiment {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_experiment().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_experiment isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_experiment().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_experiment_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $geexperiment_row = $self->get_geexperiment_row();

    $geexperiment_row->set_column( metadata_id => $mod_metadata_id );
         
    $geexperiment_row->update()
	            ->discard_changes();
}


=head2 store_dbxref_associations

  Usage: $experiment->store_dbxref_associations($metadata);
 
  Desc: Store in the database the dbxref association for the experiment
        object
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $experiment->store_dbxref_associations($metadata);

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

    ## SECOND, check if exists or not experiment_dbxref_id. 
    ##   if exists experiment_dbxref_id         => update
    ##   if do not exists experiment_dbxref_id  => insert

    my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();
    
    foreach my $geexperimentdbxref_row (@geexperimentdbxref_rows) {
        
        my $experiment_dbxref_id = $geexperimentdbxref_row->get_column('experiment_dbxref_id');
	my $dbxref_id = $geexperimentdbxref_row->get_column('dbxref_id');

        unless (defined $experiment_dbxref_id) {                                ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $geexperimentdbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $geexperimentdbxref_row->insert()
                                   ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                    ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $geexperimentdbxref_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %asdbxref_metadata = $self->get_experiment_dbxref_metadbdata($metadata);
		my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store({ modification_note => $modification_note })
                                                                    ->get_metadata_id(); 

                $geexperimentdbxref_row->set_column( metadata_id => $mod_metadata_id );

                $geexperimentdbxref_row->update()
                                       ->discard_changes();
            }
        }
    }
}

=head2 obsolete_dbxref_association

  Usage: $experiment->obsolete_dbxref_association($metadata, $note, $dbxref_id, 'REVERT');
 
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
  
  Example: $experiment->obsolete_dbxref_association($metadata, 
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
    
    my %asdbxref_metadata = $self->get_experiment_dbxref_metadbdata($metadata);
    my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store( { modification_note => $modification_note,
						     	           obsolete          => $obsolete, 
							           obsolete_note     => $obsolete_note } )
                                                        ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @geexperimentdbxref_rows = $self->get_geexperimentdbxref_rows();
    foreach my $geexperimentdbxref_row (@geexperimentdbxref_rows) {
	if ($geexperimentdbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $geexperimentdbxref_row->set_column( metadata_id => $mod_metadata_id );
         
	    $geexperimentdbxref_row->update()
	                           ->discard_changes();
	}
    }
}

#####################
### OTHER METHODS ###
#####################


=head2 get_experimental_design

  Usage: my $experimental_design = $experiment->get_experimental_design();
  
  Desc: Get a CXGN::GEM::ExperimentalDesign object.
  
  Ret:  An array with a list of CXGN::GEM::Experiment objects.
  
  Args: none
  
  Side_Effects: die if the experiment_object have not any 
                experiment_id
  
  Example: my $expdesign = $experiment->get_experimental_design();

=cut

sub get_experimental_design {
   my $self = shift;
   
   my $experimental_design_id = $self->get_experimental_design_id();
   
   unless (defined $experimental_design_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experimental_design_id. Probably it hasn't store yet.\n");
   }

   my $expdesign = CXGN::GEM::ExperimentalDesign->new($self->get_schema(), $experimental_design_id);
  
   return $expdesign;
}

=head2 get_target_list

  Usage: my @targets = $experiment->get_target_list();
  
  Desc: Get a list CXGN::GEM::Target object associated with the
        experiment_id
  
  Ret: An array with a list of CXGN::GEM::Target objects.
  
  Args: none
  
  Side_Effects: die if the experiment_object have not any 
                experiment_id
  
  Example: my @targets = $experiment->get_target_list();

=cut

sub get_target_list {
   my $self = shift;
   
   my @targets = ();
   
   my $experiment_id = $self->get_experiment_id();

   unless (defined $experiment_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experiment_id. Probably it hasn't store yet.\n");
   }
  
   my @target_rows = $self->get_schema()
                          ->resultset('GeTarget')
                          ->search( { experiment_id => $experiment_id } );

   foreach my $target_row (@target_rows) {
       my $target = CXGN::GEM::Target->new($self->get_schema(), $target_row->get_column('target_id'));
      
       push @targets, $target;
   }
   
   return @targets;

}








####
1;##
####
