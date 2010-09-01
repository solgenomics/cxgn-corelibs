package CXGN::GEM::Target;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Biosource::Sample;
use CXGN::Biosource::Protocol;
use CXGN::Metadata::Metadbdata;
use CXGN::GEM::Experiment;
use CXGN::GEM::ExperimentalDesign;

use Carp qw| croak cluck carp |;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Target
a class to manipulate a target data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Target;

 ## Constructor

 my $target = CXGN::GEM::Target->new($schema, $target_id); 

 ## Simple accessors

 my $target_name = $target->get_target_name();
 $target->set_target_name($new_name);

 ## Extended accessors 

 my %target_elements = $target->get_target_elements();
 $target->add_target_element( 
                              { 
                                target_element_name => $element, 
                                sample_name         => $sample,
                                dye                 => $dye,
                              }
                            );

 my @dbxref_id_list = $target->get_dbxref_list();
 $target->add_dbxref($dbxref_id);

 ## Metadata functions (aplicable to extended data as dbxref or target_element)

 my $metadbdata = $target->get_target_metadbdata();

 if ($target->is_target_obsolete()) {
    ## Do something
 }

 ## Store functions (aplicable to extended data as dbxref or target_element)

 $target->store($metadbdata);

 $target->obsolete_experiment($metadata, 'change to obsolete test');
 


=head1 DESCRIPTION

 This object manage the target information of the database
 from the tables:
  
   + gem.ge_target
   + gem.ge_target_element
   + gem.ge_target_dbxref

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %Target_Object = ( 
    
       ge_target_row        => GeTarget_row,
    
       ge_target_element    => { 

             $target_element_name => GeTargetElement_row,

                               }

                     
       ge_target_dbxref_row => [ @GeTargetDbxref_rows],
    
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

  Usage: my $target = CXGN::GEM::Target->new($schema, $target_id);

  Desc: Create a new target object

  Ret: a CXGN::GEM::Target object

  Args: a $dbh
        A $target_id, a scalar.
        If $target_id is omitted, an empty target object is created.

  Side_Effects: access to database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $target = CXGN::GEM::Target->new($dbh, $target_id);

=cut

sub new {
    my ($class,$dbh,$id) = @_;
	croak("PARAMETER ERROR: No schema object was supplied to the $class->new() function.\n") unless $dbh;

    ### First, bless the class to create the object and set the schema into de object 

    my $self = $class->SUPER::new($dbh);
    $self->set_dbh($dbh);
    my $schema = CXGN::DB::DBICFactory->open_schema(
        'CXGN::GEM::Schema',
         search_path => [qw/gem biosource metadata public/],
    );

    ### Second, check that ID is an integer. If it is right go and get all the data for 
    ### this row in the database and after that get the data for target
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $target;
    my %target_elements = ();
    my @target_dbxrefs = ();
 
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The target_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}


	## Get the ge_target_row object using a search based in the target_id 
	($target) = $schema->resultset('GeTarget')
	                   ->search( { target_id => $id } );
	
	if (defined $target) {

	    ## Search also the target elements associated to this target

	    my @target_element_rows = $schema->resultset('GeTargetElement')
	                                    ->search( { target_id => $id } );
	
	    foreach my $target_element_row (@target_element_rows) {
		my $target_element_name = $target_element_row->get_column('target_element_name');
		my $target_element_id = $target_element_row->get_column('target_element_id');

		unless (defined $target_element_name) {
		    croak("DATABASE COHERENCE ERROR: target_element_id=$target_element_id has undef value for target_element_name.\n");
		}
		else {
		    unless (exists $target_elements{$target_element_name}) {
			$target_elements{$target_element_name} = $target_element_row;                    
		    }
		    else {
		    
			## Die if there are more than two target elements with the same name for the same sample_id
                    
			my $a = $target_elements{$target_element_name}->get_column('target_element_id') . ' and ' . $target_element_id;
			croak("DATABASE COHERENCE ERROR:There are more than one target_element_id ($a) with same target_element_name.\n");
		    }
		}
	    }
	
	    ## Search target_dbxref associations
	
	    @target_dbxrefs = $schema->resultset('GeTargetDbxref')
	                             ->search( { target_id => $id } );
	}
	else {
	    ## If do not exists the target_id, it will create an empty target object
	    $target = $schema->resultset('GeTarget')
	                     ->new({});
	}       
    }
    else {
	$target = $schema->resultset('GeTarget')
	                ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_getarget_row($target);
    $self->set_getargetelement_rows(\%target_elements);
    $self->set_getargetdbxref_rows(\@target_dbxrefs);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $target = CXGN::GEM::Target->new_by_name($schema, $name);
 
  Desc: Create a new Experiment object using target_name
 
  Ret: a CXGN::GEM::Target object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $target_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the experiment name do not exists 
                into the db
 
  Example: my $target = CXGN::GEM::Target->new_by_name($schema, $name);

=cut

sub new_by_name {
    my ($class,$dbh,$name) = @_;
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n") unless $dbh;

    ### It will search the target_id for this name and it will get the target_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the target_name for it
  
    my $target;
    my $schema = CXGN::DB::DBICFactory->open_schema(
        'CXGN::GEM::Schema',
         search_path => [qw/gem biosource metadata public/],
    );

    if (defined $name) {
	my ($target_row) = $schema->resultset('GeTarget')
	                          ->search({ target_name => $name });
  
	unless (defined $target_row) {                
	    warn("DATABASE OUTPUT WARNING: target_name ($name) for $class->new_by_name() DON'T EXISTS INTO THE DB.\n");

	    ## If do not exists any target with this name, it will return a warning and it will create an empty
            ## object with the target name set in it.

	    $target = $class->new($schema);
	    $target->set_target_name($name);
	}
	else {

	    ## if exists it will take the target_id to create the object with the new constructor
	    $target = $class->new( $schema, $target_row->get_column('target_id') ); 
	}
    } 
    else {
	$target = $class->new($schema);                              ### Create an empty object;
    }
   
    return $target;
}

=head2 constructor new_by_elements

  Usage: my $target = CXGN::GEM::Target->new_by_elements($schema, 
                                                               \@targetelements);
 
  Desc: Create a new Target object using a list of a target_elements_names
 
  Ret: a CXGN::GEM::Target object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                     sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                     %other_parameters );
        a \@target_elements, an array reference with a list of target element 
        names
 
  Side_Effects: accesses the database,
                return a warning if the target name do not exists into the db
 
  Example: my $sample = CXGN::GEM::Target->new_by_elements( $schema, 
                                                                  [$e1, $e2]);

=cut

sub new_by_elements {
    my $class = shift;
    my $schema = shift || 
        croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $elements_aref = shift;

    ### It will search the target_id for the list of these elements. If find a target_id it will create a new object with it.
    ### if not, it will create an empty object and it will add all the elements over the empty object using the add_element_by_name
    ### function (it will search a element in the database and it will add it to the target)

    my $target;

    if (defined $elements_aref) {
        if (ref($elements_aref) ne 'ARRAY') {
            croak("PARAMETER ERROR: The element array reference supplied to $class->new_by_elements() method IS NOT AN ARRAY REF.\n");
        }
        else {
            my $elements_n = scalar(@{$elements_aref});

            ## Dbix::Class search to get an id in a group using the elements of the group

            my @getarget_element_rows = $schema->resultset('GeTargetElement')
                                               ->search( undef,
                                                          { 
                                                            columns  => ['target_id'],
                                                            where    => { target_element_name => { -in  => $elements_aref } },
                                                            group_by => [ qw/target_id/ ], 
                                                            having   => { 'count(target_element_id)' => { '=', $elements_n } } 
                                                          }          
                                                        );

	    ## This search will return all the platform_design that contains the elements specified, it will filter 
	    ## by the number of element to take only the rows where have all these elements

	    my $getarget_element_row;
	    foreach my $row (@getarget_element_rows) {
		my $count = $schema->resultset('GeTargetElement')
		                   ->search( target_id => $row->get_column('target_id') )
				   ->count();
		if ($count == $elements_n) {
		    $getarget_element_row = $row;
		}
	    }


            unless (defined $getarget_element_row) {    
                
                ## If target_id don't exists into the  db, it will warning with carp and create an empty object
                warn("DATABASE OUTPUT WARNING: Elements specified haven't a Target. It'll be created an empty target object.\n"); 
                $target = $class->new($schema);
            
                foreach my $element_name (@{$elements_aref}) {
                    $target->add_target_element( { target_element_name => $element_name } );
                }
            }
            else {            
                $target = $class->new( $schema, $getarget_element_row->get_column('target_id') );
            }
        }
        
    }
    else {
            $target = $class->new($schema);                              ### Create an empty object;
    }

    return $target;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_getarget_row, set_getarget_row

  Usage: my $getarget_row = $self->get_getarget_row();
         $self->set_getarget_row($getarget_row_object);

  Desc: Get or set a getarget row object into a target
        object
 
  Ret:   Get => $getarget_row_object, a row object 
                (CXGN::GEM::Schema::GeTarget).
         Set => none
 
  Args:  Get => none
         Set => $getarget_row_object, a row object 
                (CXGN::GEM::Schema::GeTarget).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $getarget_row = $self->get_getarget_row();
           $self->set_getarget_row($getarget_row);

=cut

sub get_getarget_row {
  my $self = shift;
 
  return $self->{getarget_row}; 
}

sub set_getarget_row {
  my $self = shift;
  my $getarget_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None getarget_row object was supplied for $self->set_getarget_row function.\n");
 
  if (ref($getarget_row) ne 'CXGN::GEM::Schema::GeTarget') {
      croak("SET ARGUMENT ERROR: $getarget_row isn't a getarget_row obj. (CXGN::GEM::Schema::GeTarget).\n");
  }
  $self->{getarget_row} = $getarget_row;
}

=head2 accessors get_getargetelement_rows, set_getargetelement_rows

  Usage: my %getargetelement_rows = $self->get_getargetelement_rows();
         $self->set_getargetelement_rows(\%getargetelement_rows);

  Desc: Get or set a getargetelement row object into a target object
        as hash reference where keys = name and value = row object
 
  Ret:   Get => A hash where key=name and value=row object
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=name and value=row object
                (CXGN::GEM::Schema::GeTargetElement).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %getargetelement_rows = $self->get_getargetelement_rows();
            $self->set_getargetelement_rows(\%getargetelement_rows);

=cut

sub get_getargetelement_rows {
  my $self = shift;
  
  return %{$self->{getargetelement_rows}}; 
}

sub set_getargetelement_rows {
  my $self = shift;
  my $getargetelement_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None ge_target_element_row hash ref. was supplied for set_getargetelement_row function.\n"); 

  if (ref($getargetelement_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $getargetelement_href isn't an hash reference.\n");
  }
  else {
      my %getargetelement = %{$getargetelement_href};
      
      foreach my $element_name (keys %getargetelement) {
          unless (ref($getargetelement{$element_name}) eq 'CXGN::GEM::Schema::GeTargetElement') {
               croak("SET ARGUMENT ERROR: row obj = $getargetelement{$element_name} isn't a row obj. (GeTargetElement).\n");
          }
      }
  }
  $self->{getargetelement_rows} = $getargetelement_href;
}


=head2 accessors get_getargetdbxref_rows, set_getargetdbxref_rows

  Usage: my @getargetdbxref_rows = $self->get_getargetdbxref_rows();
         $self->set_getargetdbxref_rows(\@getargetdbxref_rows);

  Desc: Get or set a list of getargetdbxref rows object into an
        target object
 
  Ret:   Get => @getargetdbxref_row_object, a list of row objects 
                (CXGN::GEM::Schema::GeTargetDbxref).
         Set => none
 
  Args:  Get => none
         Set => \@getargetdbxref_row_object, an array ref of row objects 
                (CXGN::GEM::Schema::GeTargetDbxref).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @getargetdbxref_rows = $self->get_getargetdbxref_rows();
           $self->set_getargetdbxref_rows(\@getargetdbxref_rows);

=cut

sub get_getargetdbxref_rows {
  my $self = shift;
 
  return @{$self->{getargetdbxref_rows}}; 
}

sub set_getargetdbxref_rows {
  my $self = shift;
  my $getargetdbxref_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR:None getargetdbxref_row array ref was supplied for $self->set_getargetdbxref_rows().\n");
 
  if (ref($getargetdbxref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $getargetdbxref_row_aref isn't an array reference for $self->set_getargetdbxref_rows().\n");
  }
  else {
      foreach my $getargetdbxref_row (@{$getargetdbxref_row_aref}) {  
          if (ref($getargetdbxref_row) ne 'CXGN::GEM::Schema::GeTargetDbxref') {
              croak("SET ARGUMENT ERROR:$getargetdbxref_row isn't getargetdbxref_row obj.\n");
          }
      }
  }
  $self->{getargetdbxref_rows} = $getargetdbxref_row_aref;
}



#################################
### DATA ACCESSORS FOR TARGET ###
#################################

=head2 get_target_id, force_set_target_id
  
  Usage: my $target_id = $target->get_target_id();
         $target->force_set_target_id($target_id);

  Desc: get or set a target_id in a target object. 
        set method should be USED WITH PRECAUTION
        If you want set a target_id that do not exists into the 
        database you should consider that when you store this object you 
        CAN STORE a experiment_id that do not follow the 
        gem.ge_target_target_id_seq

  Ret:  get=> $target_id, a scalar.
        set=> none

  Args: get=> none
        set=> $target_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $target_id = $target->get_target_id(); 

=cut

sub get_target_id {
  my $self = shift;
  return $self->get_getarget_row->get_column('target_id');
}

sub force_set_target_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None target_id was supplied for force_set_target_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The target_id ($data) for $self->force_set_target_id() ISN'T AN INTEGER.\n");
  }

  $self->get_getarget_row()
       ->set_column( target_id => $data );
 
}

=head2 accessors get_target_name, set_target_name

  Usage: my $target_name = $target->get_target_name();
         $target->set_target_name($target_name);

  Desc: Get or set the target_name from target object. 

  Ret:  get=> $target_name, a scalar
        set=> none

  Args: get=> none
        set=> $target_name, a scalar

  Side_Effects: none

  Example: my $target_name = $target->get_target_name();
           $target->set_target_name($new_name);
=cut

sub get_target_name {
  my $self = shift;
  return $self->get_getarget_row->get_column('target_name'); 
}

sub set_target_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_target_name function.\n");

  $self->get_getarget_row()
       ->set_column( target_name => $data );
}

=head2 accessors get_experiment_id, set_experiment_id

  Usage: my $experiment_id = $target->get_experiment_id();
         $target->set_experiment_id($experiment_id);
 
  Desc: Get or set experiment_id from a target object. 
 
  Ret:  get=> $experiment_id, a scalar
        set=> none
 
  Args: get=> none
        set=> $experiment_id, a scalar
 
  Side_Effects: For the set accessor, die if the experiment_id don't
                exists into the database
 
  Example: my $experiment_id = $target->get_experiment_id();
           $target->set_experiment_id($experiment_id);
=cut

sub get_experiment_id {
  my $self = shift;
  return $self->get_getarget_row->get_column('experiment_id'); 
}

sub set_experiment_id {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_experiment function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The experiment_id ($data) for $self->set_experiment_id() ISN'T AN INTEGER.\n");
  }

  $self->get_getarget_row()
       ->set_column( experiment_id => $data );
}

##########################################
### DATA ACCESSORS FOR TARGET ELEMENTS ###
##########################################

=head2 add_target_element

  Usage: $sample->add_target_element( $parameters_hash_ref );

  Desc: Add a new target element to the target object 

  Ret: None

  Args: A hash reference with key=target_element_parameter and value=value
        The target element parameters and the type are:
          - target_element_name => varchar(250) 
          - sample_name         => text (or sample_id => integer)
          - protocol_name       => text (or protocol_id => integer)
          - dye                 => text

  Side_Effects: Die if the sample_name (or sample_id) or protocol_name 
                (or protocol_id) don't exists into the database

  Example: $target->add_target_element( 
                         { 
                           target_element_name   => 'Atlas76', 
                           sample_name => 'ExpressionAtlas_01_seed_03',
                           dye => 'streptavidin phycoerythrin conjugate',
                         }
                                      );

=cut

sub add_target_element {
    my $self = shift;
    my $param_hashref = shift ||
        croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->add_target_element function.\n");

    if (ref($param_hashref) ne 'HASH') {
         croak("DATA TYPE ERROR: The parameter hash ref. for $self->add_target_element() ISN'T A HASH REFERENCE.\n");
    }

    my %param = %{$param_hashref};
    
    
    ## Search in the database a sample name (biosource tables) and get the sample_id. Die if don't find anything.

    my $sample;
    if (exists $param{'sample_name'}) {
        my $sample_name = delete($param{'sample_name'});
        $sample = CXGN::Biosource::Sample->new_by_name($self->get_schema(), $sample_name);
    }
    elsif (exists $param{'sample_id'}){
        $sample = CXGN::Biosource::Sample->new($self->get_schema(), $param{'sample_id'});
    }
    if (defined $sample) {
        my $sample_id = $sample->get_sample_id();
        if (defined $sample_id) {
            unless (exists $param{'sample_id'}) {
                $param{'sample_id'} = $sample_id;
            }
        }
        else {
            croak("DATABASE COHERENCE ERROR for add_target_element: Sample_name or sample_id don't exists in database.\n");
        }
    }

    ## Search in the database a protocol name (biosource tables) and get the protocol_id. Die if don't find anything.

    my $protocol;
    if (exists $param{'protocol_name'}) {
        my $protocol_name = delete($param{'protocol_name'});
        $protocol = CXGN::Biosource::Protocol->new_by_name($self->get_schema(), $protocol_name);
    }
    elsif (exists $param{'protocol_id'}) {
	$protocol = CXGN::Biosource::Protocol->new($self->get_schema(), $param{'protocol_id'});
    }
    if (defined $protocol) {
        my $protocol_id = $protocol->get_protocol_id();
        if (defined $protocol_id) {
            unless (exists $param{'protocol_id'}) {
                $param{'protocol_id'} = $protocol_id;
            }
        }
        else {
            croak("DATABASE COHERENCE ERROR for add_target_element: Protocol_name or protocol_id don't exists in database.\n");
        }
    }

    my $target_id = $self->get_target_id();
    if (defined $target_id) {
        $param{'target_id'} = $target_id;
    }

    my $new_target_element_row = $self->get_schema()
                                      ->resultset('GeTargetElement')
                                      ->new(\%param);

    my %getargetelement_rows = $self->get_getargetelement_rows();
    
    unless (exists $getargetelement_rows{$param{'target_element_name'}} ) {
        $getargetelement_rows{$param{'target_element_name'}} = $new_target_element_row;
    } 
    else {
        croak("FUNCTION ERROR: Target_element_name=$param{'target_element_name'} exists sample obj. It only can be edited using edit.\n");
    }

    $self->set_getargetelement_rows(\%getargetelement_rows);
}

=head2 get_target_elements

  Usage: my %target_elements = $target->get_target_elements();

  Desc: Get the target elements from a target object, 
        to get all the data from the row use get_columns function

  Ret: %target elements, where: keys = target_element_name 
                                value = a hash reference with:
                                   keys  = column_name
                                   value = value
  Args: none

  Side_Effects: none

  Example: my %target_elements = $target->get_target_elements();
           my $sample_id_a = $target_elements{'target_a'}->{sample_id};

=cut

sub get_target_elements {
    my $self = shift;

    my %target_elements_by_data;
    
    my %getargetelements_rows = $self->get_getargetelement_rows();
    foreach my $target_element_name ( keys %getargetelements_rows ) {
        my %data_hash = $getargetelements_rows{$target_element_name}->get_columns();

        ## It will add sample name and protocol name to the data hash

        if (exists $data_hash{'sample_id'}) {
            my $sample = CXGN::Biosource::Sample->new($self->get_schema(), $data_hash{'sample_id'});
            my $sample_name = $sample->get_sample_name();
            if (defined $sample_name) {
                unless (exists $data_hash{'sample_name'}) {
                    $data_hash{'sample_name'} = $sample_name;
                }
            }
        }

        if (exists $data_hash{'protocol_id'}) {
            my $protocol = CXGN::Biosource::Protocol->new($self->get_schema(), $data_hash{'protocol_id'});
            my $protocol_name = $protocol->get_protocol_name();
            if (defined $protocol_name) {
                unless (exists $data_hash{'protocol_name'}) {
                    $data_hash{'protocol_name'} = $protocol_name;
                }
            }
        }
        
        $target_elements_by_data{$target_element_name} = \%data_hash;
 }
    return %target_elements_by_data;
}

=head2 edit_target_element

  Usage: $target->edit_target_element($element_name, $parameters_hash_ref);

  Desc: Edit a target element in the target object. 
        It can not edit the target_element_name or the target_id 
        To add a new element use add_target_element.
        To obsolete an element use obsolete_target_element.

  Ret: None

  Args: $element, a scalar, an target_element_name,
        $parameters_hash_ref, a hash reference with 
        key=target_element_parameter and value=value
        The target_element parameters and the type are:
          - dye                 => text
          - sample_name         => text (or sample_id   => integer)
          - protocol_name       => text (or protocol_id => integer)

  Side_Effects: Die if the sample_name or the protocol_name suplied are
                not in the database 

  Example: $target->edit_target_element( $target_element_1 
                                         { 
                                           dye => 'another dye', 
                                         }
                                       );

=cut

sub edit_target_element {
    my $self = shift;
    my $element_name = shift ||
        croak("FUNCTION PARAMETER ERROR: None data was supplied for edit_target_element function to $self.\n");
    
    my $param_hashref = shift ||
        croak("FUNCTION PARAMETER ERROR: None parameter hash reference was supplied for edit_target_element function to $self.\n");

    if (ref($param_hashref) ne 'HASH') {
         croak("DATA TYPE ERROR: The parameter hash ref. for $self->edit_target_element() ISN'T A HASH REFERENCE.\n");
    }

    my %param = %{$param_hashref};

    ## In the same way that it changed sample_name or protocol_name, it will do for edit_target_element

    ## Search in the database a protocol name (biosource tables) and get the protocol_id. Die if don't find anything.

    if (exists $param{'sample_name'}) {
        my $sample_name = delete($param{'sample_name'});
        my $sample = CXGN::Biosource::Sample->new_by_name($self->get_schema(), $sample_name);
        my $sample_id = $sample->get_sample_id();
        if (defined $sample_id) {
            unless (exists $param{'sample_id'}) {
                $param{'sample_id'} = $sample_id;
            }
        }
        else {
            croak("DATABASE COHERENCE ERROR for edit_target_element: Sample_name=$sample_name don't exists in database.\n");
        }
    }

    
 ## Search in the database a protocol name (biosource tables) and get the protocol_id. Die if don't find anything.

    if (exists $param{'protocol_name'}) {
        my $protocol_name = delete($param{'protocol_name'});
        my $protocol = CXGN::Biosource::Protocol->new_by_name($self->get_schema(), $protocol_name);
        my $protocol_id = $protocol->get_protocol_id();
        if (defined $protocol_id) {
            unless (exists $param{'protocol_id'}) {
                $param{'protocol_id'} = $protocol_id;
            }
        }
        else {
            croak("DATABASE COHERENCE ERROR for edit_target_element: Protocol_name=$protocol_name don't exists in database.\n");
        }
    }

    ## This should not change target_element_name, target_element_id or target_id
    delete($param{'target_element_name'});
    delete($param{'target_element_id'});
    delete($param{'target_id'});
    
    
    my %getargetelement_rows = $self->get_getargetelement_rows();
    
    unless (exists $getargetelement_rows{$element_name} ) {
        croak("FUNCTION ERROR: Target_element_name=$element_name don't exists target obj. Use add_target_element to add a new one.\n");
    } 
    else {
        $getargetelement_rows{$element_name}->set_columns(\%param);
    }

    $self->set_getargetelement_rows(\%getargetelement_rows);
}


########################################
### DATA ACCESSORS FOR TARGET DBXREF ###
########################################

=head2 add_dbxref

  Usage: $target->add_dbxref($dbxref_id);

  Desc: Add a dbxref to the dbxref_ids associated to sample
        object using dbxref_id or accesion + database_name 

  Ret:  None

  Args: $dbxref_id, a dbxref id. 
        To use with accession and dbxname:
          $target->add_dbxref( 
                               { 
                                 accession => $accesssion,
                                 dbxname   => $dbxname,
			       }
                             );
          
  Side_Effects: die if the parameter is not an hash reference

  Example: $target->add_dbxref($dbxref_id);
           $target->add_dbxref( 
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

    my $targetdbxref_row = $self->get_schema()
                                ->resultset('GeTargetDbxref')
                                ->new({ dbxref_id => $dbxref_id});
    
    if (defined $self->get_target_id() ) {
        $targetdbxref_row->set_column( target_id => $self->get_target_id() );
    }

    my @targetdbxref_rows = $self->get_getargetdbxref_rows();
    push @targetdbxref_rows, $targetdbxref_row;
    $self->set_getargetdbxref_rows(\@targetdbxref_rows);
}

=head2 get_dbxref_list

  Usage: my @dbxref_list_id = $target->get_publication_list();

  Desc: Get a list of dbxref_id associated to this target.

  Ret: An array of dbxref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbxref_id_list = $target->get_dbxref_list();

=cut

sub get_dbxref_list {
    my $self = shift;

    my @dbxref_list = ();

    my @targetdbxref_rows = $self->get_getargetdbxref_rows();
    foreach my $targetdbxref_row (@targetdbxref_rows) {
        my $dbxref_id = $targetdbxref_row->get_column('dbxref_id');
	push @dbxref_list, $dbxref_id;
    }
    
    return @dbxref_list;                  
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_target_metadbdata

  Usage: my $metadbdata = $target->get_target_metadbdata();

  Desc: Get metadata object associated to target data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $target->get_target_metadbdata();
           my $metadbdata = $target->get_target_metadbdata($metadbdata);

=cut

sub get_target_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_getarget_row
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
      my $target_id = $self->get_target_id();
      if (defined $target_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the target_id=$target_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any target_id. Probably it hasn't been stored yet.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_target_obsolete

  Usage: $target->is_target_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($target->is_experiment_obsolete()) { 
                   ## do something 
           }

=cut

sub is_target_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_target_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}

=head2 accessors get_target_element_metadbdata

  Usage: my $metadbdata = $target->get_target_element_metadbdata();

  Desc: Get metadata object associated to target row 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with key=element_name and value=metadbdata object 
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $target->get_target_element_metadbdata();
           my %metadbdata = $target->get_target_element_metadbdata($metadbdata);

=cut

sub get_target_element_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my %target_elements = $self->get_target_elements();

 foreach my $element_name (keys %target_elements) {
      my $metadbdata;
      my $metadata_id = $target_elements{$element_name}->{'metadata_id'};

      if (defined $metadata_id) {
          $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
          if (defined $metadata_obj_base) {

              ## This will transfer the creation data from the base object to the new one
              $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
              $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
          }
          $metadbdata{$element_name} = $metadbdata;
      } 
      else {
          my $target_id = $self->get_target_id();
          unless (defined $target_id) {
              croak("OBJECT MANIPULATION ERROR: The object $self haven't any target_id associated. Probably it hasn't been stored\n");
          }
          else {
              croak("DATABASE INTEGRITY ERROR: metadata_id for target_element_name=$element_name is undefined.\n");
          }
      }
  }
  
  return %metadbdata;
}

=head2 is_target_element_obsolete

  Usage: $target->is_target_element_obsolete($element_name);
  
  Desc: Get obsolete field form metadata object associated to 
        target data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the name for the target element in the
        object
  
  Side_Effects: none
  
  Example: unless ($target->is_target_element_obsolete($element_name)) { 
                ## do something 
           };

=cut

sub is_target_element_obsolete {
  my $self = shift;
  my $element_name = shift;
  

  if (defined $element_name) {
      my %metadbdata = $self->get_target_element_metadbdata();
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

=head2 accessors get_target_dbxref_metadbdata

  Usage: my %metadbdata = $target->get_target_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=dbxref_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $target->get_target_dbxref_metadbdata();
           my %metadbdata = 
              $target->get_target_dbxref_metadbdata($metadbdata);

=cut

sub get_target_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @getargetdbxref_rows = $self->get_getargetdbxref_rows();

  foreach my $getargetdbxref_row (@getargetdbxref_rows) {
      my $dbxref_id = $getargetdbxref_row->get_column('dbxref_id');
      my $metadata_id = $getargetdbxref_row->get_column('metadata_id');

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
          my $target_dbxref_id = $getargetdbxref_row->get_column('target_dbxref_id');
	  unless (defined $target_dbxref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any target_dbxref_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the target_dbxref_id=$target_dbxref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_target_dbxref_obsolete

  Usage: $target->is_target_dbxref_obsolete($dbxref_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $dbxref_id, a dbxref_id
  
  Side_Effects: none
  
  Example: unless ($target->is_target_dbxref_obsolete($dbxref_id)){
                ## do something 
           }

=cut

sub is_target_dbxref_obsolete {
  my $self = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_target_dbxref_metadbdata();
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

  Usage: $target->store($metadbdata);
 
  Desc: Store in the database the all target data for the 
        target object.
        See the methods store_target, store_target_element, and 
        store_dbxref_associations for more details

  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $target->store($metadata);

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

    $self->store_target($metadata);
    $self->store_target_elements($metadata);
    $self->store_dbxref_associations($metadata);
}


=head2 store_target

  Usage: $target->store_target($metadata);
 
  Desc: Store in the database the target data for the target
        object (Only the getarget row, don't store any 
        target_dbxref or target_element data)
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $target->store_target($metadata);

=cut

sub store_target {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_target().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_target() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not target_id. 
    ##   if exists target_id         => update
    ##   if do not exists target_id  => insert

    my $getarget_row = $self->get_getarget_row();
    my $target_id = $getarget_row->get_column('target_id');

    unless (defined $target_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	$metadata->store();
	my $metadata_id = $metadata->get_metadata_id();

	$getarget_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$getarget_row->insert()
                     ->discard_changes();                           ## It will set the row with the updated row
	
	## Now we set the target_id value for all the rows that depends of it
	
	my %getargetelement_rows = $self->get_getargetelement_rows();
	foreach my $targetelement (keys %getargetelement_rows) {
	    my $getargetelement_row = $getargetelement_rows{$targetelement};
	    $getargetelement_row->set_column( target_id => $getarget_row->get_column('target_id'));
	}

	my @getargetdbxref_rows = $self->get_getargetdbxref_rows();
	foreach my $getargetdbxref_row (@getargetdbxref_rows) {
	    $getargetdbxref_row->set_column( target_id => $getarget_row->get_column('target_id'));
	}

	          
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $getarget_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata = $self->get_target_metadbdata($metadata);
	    $mod_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id(); 

	    $getarget_row->set_column( metadata_id => $mod_metadata_id );

	    $getarget_row->update()
                         ->discard_changes();
	}
    }
}


=head2 obsolete_target

  Usage: $target->obsolete_target($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $target->obsolete_target($metadata, 'change to obsolete test');

=cut

sub obsolete_target {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_target().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_target isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_target().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata = $self->get_target_metadbdata($metadata);
    $mod_metadata->store( { modification_note => $modification_note,
			    obsolete          => $obsolete, 
			    obsolete_note     => $obsolete_note } );
    my $mod_metadata_id = $mod_metadata->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $getarget_row = $self->get_getarget_row();

    $getarget_row->set_column( metadata_id => $mod_metadata_id );
         
    $getarget_row->update()
	         ->discard_changes();
}

=head2 store_target_elements

  Usage: my $target = $target->store_target_elements($metadata);
 
  Desc: Store in the database target_elements associated to a target
 
  Ret: None.
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $target = $target->store_target_elements($metadata);

=cut

sub store_target_elements {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_target_elements().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_target_elements() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not target_elements_id. 
    ##   if exists target_elements_id         => update
    ##   if do not exists target_elements_id  => insert

    my %getargetelements_rows = $self->get_getargetelement_rows();
    
    foreach my $getargetelement_row (values %getargetelements_rows) {
        my $target_element_id = $getargetelement_row->get_column('target_element_id');
	my $target_id = $getargetelement_row->get_column('target_id');

	unless (defined $target_id) {
	    croak("STORE ERROR: Don't exist target_id associated to this step. Use store_target before use store_target_elements.\n");
	}

        unless (defined $target_element_id) {                                  ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $getargetelement_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
	    
            $getargetelement_row->insert()
                                ->discard_changes();                           ## It will set the row with the updated row
        }  
        else {                                                                 ## UPDATE IF SOMETHING has change

	    my @columns_changed = $getargetelement_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %se_metadata = $self->get_target_element_metadbdata($metadata);
		my $element_name = $getargetelement_row->get_column('target_element_name');
                my $mod_metadata_id = $se_metadata{$element_name}->store({ modification_note => $modification_note })
                                                                 ->get_metadata_id(); 

                $getargetelement_row->set_column( metadata_id => $mod_metadata_id );

                $getargetelement_row->update()
                                    ->discard_changes();
            }
        }
    }
}

=head2 obsolete_target_element

  Usage: my $target = $target->obsolete_target_element( $metadata, 
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
  
  Example: my $target = $target->obsolete_target_element( $metadata, 
                                                          change to obsolete', 
                                                          $element_name );

=cut

sub obsolete_target_element {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
        || croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_target_element().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_target_element is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
        || croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_target_element().\n");

    my $element_name = shift 
        || croak("OBSOLETE ERROR: None target_element_name was supplied to $self->obsolete_target_element().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
        $obsolete = 0;
        $modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %target_element_metadata = $self->get_target_element_metadbdata($metadata);
    my $mod_metadata_id = $target_element_metadata{$element_name}->store( { 
	                                                                    modification_note => $modification_note,
									    obsolete          => $obsolete, 
									    obsolete_note     => $obsolete_note 
                                                                          } )
                                                                 ->get_metadata_id();
     
    ## Modify the group row in the database

     my %getargetelement_rows = $self->get_getargetelement_rows();
       
    $getargetelement_rows{$element_name}->set_column( metadata_id => $mod_metadata_id );
    
    $getargetelement_rows{$element_name}->update()
	                                ->discard_changes();
}


=head2 store_dbxref_associations

  Usage: $target->store_dbxref_associations($metadata);
 
  Desc: Store in the database the dbxref association for the target
        object
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $target->store_dbxref_associations($metadata);

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

    ## SECOND, check if exists or not target_dbxref_id. 
    ##   if exists target_dbxref_id         => update
    ##   if do not exists target_dbxref_id  => insert

    my @getargetdbxref_rows = $self->get_getargetdbxref_rows();
    
    foreach my $getargetdbxref_row (@getargetdbxref_rows) {
        
        my $target_dbxref_id = $getargetdbxref_row->get_column('target_dbxref_id');
	my $dbxref_id = $getargetdbxref_row->get_column('dbxref_id');

        unless (defined $target_dbxref_id) {                                ## NEW INSERT and DISCARD CHANGES
        
            $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

            $getargetdbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $getargetdbxref_row->insert()
                               ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                    ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $getargetdbxref_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %asdbxref_metadata = $self->get_target_dbxref_metadbdata($metadata);
		my $mod_metadata = $asdbxref_metadata{$dbxref_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id(); 

                $getargetdbxref_row->set_column( metadata_id => $mod_metadata_id );

                $getargetdbxref_row->update()
                                   ->discard_changes();
            }
        }
    }
}

=head2 obsolete_dbxref_association

  Usage: $target->obsolete_dbxref_association($metadata, $note, $dbxref_id, 'REVERT');
 
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
  
  Example: $target->obsolete_dbxref_association($metadata, 
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
    
    my %asdbxref_metadata = $self->get_target_dbxref_metadbdata($metadata);
    my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store( { modification_note => $modification_note,
						     	           obsolete          => $obsolete, 
							           obsolete_note     => $obsolete_note } )
                                                        ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @getargetdbxref_rows = $self->get_getargetdbxref_rows();
    foreach my $getargetdbxref_row (@getargetdbxref_rows) {
	if ($getargetdbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $getargetdbxref_row->set_column( metadata_id => $mod_metadata_id );
         
	    $getargetdbxref_row->update()
	                       ->discard_changes();
	}
    }
}

#####################
### OTHER METHODS ###
#####################

=head2 get_experiment

  Usage: my $experiment = $target->get_experiment();
  
  Desc: Get a CXGN::GEM::Experiment object.
  
  Ret:  A CXGN::GEM::Experiment object.
  
  Args: none
  
  Side_Effects: die if the target object have not any 
                experiment_id
  
  Example: my $experiment = $target->get_experiment();

=cut

sub get_experiment {
   my $self = shift;
   
   my $experiment_id = $self->get_experiment_id();
   
   unless (defined $experiment_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experiment_id. Probably it hasn't store yet.\n");
   }

   my $experiment = CXGN::GEM::Experiment->new($self->get_schema(), $experiment_id);
  
   return $experiment;
}

=head2 get_experimental_design

  Usage: my $experimental_design = $target->get_experimental_design();
  
  Desc: Get a CXGN::GEM::ExperimentalDesign object.
  
  Ret:  A CXGN::GEM::ExperimentalDesign object.
  
  Args: none
  
  Side_Effects: die if the target_object have not any 
                experiment_id and if the experiment object have not
                any expdesign_id
  
  Example: my $expdesign = $experiment->get_experimental_design();

=cut

sub get_experimental_design {
   my $self = shift;
   
   my $experiment = $self->get_experiment();
   my $experimental_design_id = $experiment->get_experimental_design_id();

   unless (defined $experimental_design_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experimental_design_id. Probably it hasn't store yet.\n");
   }

   my $expdesign = CXGN::GEM::ExperimentalDesign->new($self->get_schema(), $experimental_design_id);
  
   return $expdesign;
}

=head2 get_sample_list

  Usage: my @sample_list = $target->get_sample_list();
  
  Desc: Get a list of CXGN::Biosource::Sample objects.
  
  Ret:  An array of CXGN::Biosource::Sample object.
  
  Args: none
  
  Side_Effects: die if the target_object have not any 
                experiment_id and if the experiment object have not
                any expdesign_id
  
  Example: my @sample_list = $target->get_sample_list();

=cut

sub get_sample_list {
   my $self = shift;
   
   my @samples = ();

   my %target_elements = $self->get_target_elements();

   foreach my $target_el (keys %target_elements) {
       my $sample_id = $target_elements{$target_el}->{'sample_id'};

       my $sample = CXGN::Biosource::Sample->new($self->get_schema(), $sample_id);
       push @samples, $sample;
   }
   return @samples;
}




####
1;##
####
