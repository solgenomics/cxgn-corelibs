
=head1 NAME

CXGN::Biosource::Protocol
a class to manipulate a protocol data.

Version: 0.1

=head1 SYNOPSIS

 use CXGN::Biosource::Protocol;

 ## Constructor

 my $protocol = CXGN::Biosource::Protocol->new($schema, $protocol_id);

 ## Basic Accessors

 my $protocol_name = $protocol->get_protocol_name();
 $protocol->set_protocol_type($new_type);

 ## Extended accessors

 $protocol->add_protocol_step( 
                               { 
                                 step      => $step,
                                 action    => $action_step, 
                                 execution => $execution_step, 
                               }
                             );

 $protocol->add_publication($pub_id);
 $protocol->add_dbxref_to_protocol_step($step, $dbxref_id);

 my %protocol_steps = $protocol->get_protocol_steps();
 my $action_step = $protocol_steps{$step}->{action};
  
 my @pub_list = $protocol->get_publication_list(); 

 my %protocol_step_dbxref = $protocol->get_dbxref_from_protocol_steps();
 my @step_dbxrefs = @{$protocol_steps_dbxref{$step}}; 

 ## Store function

 $protocol->store($metadbdata);

 ## Obsolete functions

 unless ($protocol->is_step_dbxref_obsolete($step, $dbxref_id) ) {
    $protocol->obsolete_step_dbxref_association( $metadbdata,
                                                 $note,
                                                 $step,
                                                 $dbxref_id );
 }



=head1 DESCRIPTION

 This object manage the protocol information of the database
 from the tables:
  
   + biosource.bs_protocol
   + biosource.bs_protocol_pub
   + biosource.bs_protocol_step
   + biosource.bs_protocol_step_dbxref

 This data is stored inside this object as dbic rows objects with the 
 following structure:

   * biosource.bs_protocol, simple hash reference object (SHRO)
   * biosource.bs_protocol_pub, array reference inside SHRO.  
   * biosource.bs_protocol_step, hash reference inside SHRO with
                                 key=step and value=bs_protocol_step_row
   * biosource.bs_protocol_step_dbxref, hash reference inside SHRO with
                                        key=step and value=array reference with
                                        a list of bs_protocol_step_dbxref rows 


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 

use strict;
use warnings;

package CXGN::Biosource::Protocol;

use base qw | CXGN::DB::Object |;
use CXGN::Biosource::Schema;
use CXGN::Biosource::ProtocolTool;
use CXGN::Metadata::Metadbdata;

use Carp qw| croak cluck |;


############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $protocol = CXGN::Biosource::Protocol->new($schema, $protocol_id);

  Desc: Create a new Protocol object

  Ret: a CXGN::Biosource::Protocol object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $protocol_id, if $protocol_id is omitted, an empty protocol object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $protocol = CXGN::Biosource::Protocol->new($schema, $protocol_id);

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
    ### this row in the database and after that get the data for dbipath. 
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $protocol;
    my %protocol_steps = ();
    my @protocol_pubs = ();
    my %steps_dbxref = ();

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The protocol_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}
	($protocol) = $schema->resultset('BsProtocol')
   	                     ->search({ protocol_id => $id });
	
	## It will get the protocol steps rows and put in a hash

	my @protocolsteps = $schema->resultset('BsProtocolStep')
	                           ->search({ protocol_id => $id });
       
	foreach my $protocol_step_row (@protocolsteps) {
	    my $step = $protocol_step_row->get_column('step');
	    my $protocol_step_id = $protocol_step_row->get_column('protocol_step_id');

	    unless (defined $step) {
		croak("DATABASE COHERENCE ERROR: The protocol_step_id=$protocol_step_id has undefined value for step field.\n");
	    }
	    else {
		unless (exists $protocol_steps{$step}) {
		    $protocol_steps{$step} = $protocol_step_row;

		    ## If is defined step it will get the protocol_steps_dbxref rows 

		    my @stepsdbxref = $schema->resultset('BsProtocolStepDbxref')
			                     ->search({ protocol_step_id => $protocol_step_id });
       
		    if (scalar(@stepsdbxref) > 0) {
			
			$steps_dbxref{$step} = \@stepsdbxref;
		    } 
		}
		else {
		    my $a = $protocol_steps{$step}->get_column('protocol_step_id') . ' and ' . $protocol_step_id;
		    croak("DATABASE COHERENCE ERROR:There are more than one protocol_step_id ($a) with the same step and protocol_id.\n");
		}
	    }
	}

	## It will get all the publications associated to the protocol

	@protocol_pubs = $schema->resultset('BsProtocolPub')
	                        ->search({ protocol_id => $id });

	unless (defined $protocol) {  ## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object
                
	    cluck("\nDATABASE WARNING: Protocol_id ($id) for $class->new() DON'T EXISTS INTO THE DB.\nIt'll be created an empty obj.\n" );
	    
	    $protocol = $schema->resultset('BsProtocol')
		               ->new({});
	}
    } 
    else {
	$protocol = $schema->resultset('BsProtocol')
	                   ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_bsprotocol_row($protocol);
    $self->set_bsprotocolstep_rows(\%protocol_steps);
    $self->set_bsprotocolpub_rows(\@protocol_pubs);
    $self->set_bsstepdbxref_rows(\%steps_dbxref);
    return $self;
}

=head2 constructor new_by_name

  Usage: my $protocol = CXGN::Biosource::Protocol->new_by_name($schema, $protocol_name);
 
  Desc: Create a new Protocol object using protocol_name
 
  Ret: a CXGN::Biosource::Protocol object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $protocol_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the protocol name do not exists into the db
 
  Example: my $protocol = CXGN::Biosource::Protocol->new_by_name( $schema, name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the protocol_id for this name and it will get the protocol_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the protocol_name for it
  
    my $protocol;

    if (defined $name) {
	my ($protocol_row) = $schema->resultset('BsProtocol')
	                            ->find({ protocol_name => $name });

	unless (defined $protocol_row) {                 ## If dbiref_id don't exists into the  db, it will warning with cluck 
                                                         ## and it will create an object with this name 
                
	    cluck("\nDATABASE WARNING: Protocol_name ($name) for $class->new() DON'T EXISTS INTO THE DB.\n" );
	    
	    $protocol = $class->new($schema);
	    $protocol->set_protocol_name($name);
	}
	else {
	    $protocol = $class->new($schema, $protocol_row->get_column('protocol_id'));
	}
    } 
    else {
	$protocol = $class->new($schema);                              ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
   
    return $protocol;
}

##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_bsprotocol_row, set_bsprotocol_row

  Usage: my $bsprotocol_row_object = $self->get_bsprotocol_row();
         $self->set_bsprotocol_row($bsprotocol_row_object);

  Desc: Get or set a bsprotocol row object into a protocol object
 
  Ret:   Get => $bsprotocol_row_object, a row object 
                (CXGN::Biosource::Schema::BsProtocol).
         Set => none
 
  Args:  Get => none
         Set => $bsprotocol_row_object, a row object 
                (CXGN::Biosource::Schema::BsProtocol).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $bsprotocol_row_object = $self->get_bsprotocol_row();
           $self->set_bsprotocol_row($bsprotocol_row_object);

=cut

sub get_bsprotocol_row {
  my $self = shift;
 
  return $self->{bsprotocol_row}; 
}

sub set_bsprotocol_row {
  my $self = shift;
  my $bsprotocol_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None bsprotocol_row object was supplied for set_bsprotocol_row function.\n");
 
  if (ref($bsprotocol_row) ne 'CXGN::Biosource::Schema::BsProtocol') {
      croak("SET ARGUMENT ERROR: $bsprotocol_row isn't a bsprotocol_row obj. (CXGN::Biosource::Schema::BsProtocol).\n");
  }
  $self->{bsprotocol_row} = $bsprotocol_row;
}


=head2 accessors get_bsprotocolstep_rows, set_bsprotocolsteps_rows

  Usage: my %bsprotocolsteps_rows = $self->get_bsprotocolstep_rows();
         $self->set_bsprotocolstep_rows(\%bsprotocolsteps_rows);

  Desc: Get or set a bsprotocolsteps row object into a protocol object
        as hash reference where keys = step and value = row object
 
  Ret:   Get => A hash where key=step and value=row object
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=row object
                (CXGN::Biosource::Schema::BsProtocol).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bsprotocolsteps_rows = $self->get_bsprotocolstep_rows();
            $self->set_bsprotocolstep_rows(\%bsprotocolsteps_rows);

=cut

sub get_bsprotocolstep_rows {
  my $self = shift;
  
  return %{$self->{bsprotocolstep_rows}}; 
}

sub set_bsprotocolstep_rows {
  my $self = shift;
  my $bsprotocolstep_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bsprotocolstep_row hash reference was supplied for set_bsprotocolstep_row function.\n"); 

  if (ref($bsprotocolstep_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bsprotocolstep_href isn't an hash reference.\n");
  }
  else {
      my %bsprotocolstep = %{$bsprotocolstep_href};
      
      foreach my $step (keys %bsprotocolstep) {
	  unless (ref($bsprotocolstep{$step}) eq 'CXGN::Biosource::Schema::BsProtocolStep') {
	       croak("SET ARGUMENT ERROR: row obj = $bsprotocolstep{$step} isn't a row obj.(CXGN::Biosource::Schema::BsProtocolStep).\n");
	  }
      }
  }
  $self->{bsprotocolstep_rows} = $bsprotocolstep_href;
}

=head2 accessors get_bsprotocolpub_rows, set_bsprotocolpub_rows

  Usage: my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();
         $self->set_bsprotocolpub_rows(\@bsprotocolpub_rows);

  Desc: Get or set a list of bstoolpub rows object into a tool object
 
  Ret:   Get => @bsprotocolpub_row_object, a list of row objects 
                (CXGN::Biosource::Schema::BsProtocolPub).
         Set => none
 
  Args:  Get => none
         Set => @bsprotocolpub_row_object, an array ref of row objects 
                (CXGN::Biosource::Schema::BsProtocolPub).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();
           $self->set_bsprotocolpub_rows(\@bsprotocolpub_rows);

=cut

sub get_bsprotocolpub_rows {
  my $self = shift;
 
  return @{$self->{bsprotocolpub_rows}}; 
}

sub set_bsprotocolpub_rows {
  my $self = shift;
  my $bsprotocolpub_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None bsprotocolpub_row array ref was supplied for set_bsprotocolpub_rows function.\n");
 
  if (ref($bsprotocolpub_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $bsprotocolpub_row_aref isn't an array reference.\n");
  }
  else {
      foreach my $bsprotocolpub_row (@{$bsprotocolpub_row_aref}) {  
          if (ref($bsprotocolpub_row) ne 'CXGN::Biosource::Schema::BsProtocolPub') {
              croak("SET ARGUMENT ERROR: $bsprotocolpub_row isn't a bsprotocolpub_row obj. (CXGN::Biosource::Schema::BsProtocolPub).\n");
          }
      }
  }
  $self->{bsprotocolpub_rows} = $bsprotocolpub_row_aref;
}

=head2 accessors get_bsstepdbxref_rows, set_bsstepdbxref_rows

  Usage: my %bsstepdbxref_rows = $self->get_bsstepdbxref_rows();
         $self->set_bsstepdbxref_rows(\%bsstepdbxref_rows);

  Desc: Get or set a bsstepdbxref row object into a protocol object
        as hash reference where keys = step and value = an array reference
        with row objects (CXGN::Biosource::Schema::BsProtocolStepDbxref)
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsProtocolStepDbxref).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bsstepdbxref_rows = $self->get_bsstepdbxref_rows();
            $self->set_bsstepdbxref_rows(\%bsstepdbxref_rows);

=cut

sub get_bsstepdbxref_rows {
  my $self = shift;

  return %{$self->{bsstepdbxref_rows}}; 
}

sub set_bsstepdbxref_rows {
  my $self = shift;
  my $bsstepdbxref_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bsstepdbxref_row hash reference was supplied for set_bsstepdbxref_row function.\n"); 

  if (ref($bsstepdbxref_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bsstepdbxref_href isn't an hash reference.\n");
  }
  else {
      my %bsstepdbxref = %{$bsstepdbxref_href};
      
      foreach my $step (keys %bsstepdbxref) {
	  unless (ref($bsstepdbxref{$step}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bsstepdbxref{$step} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bsstepdbxref{$step}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsProtocolStepDbxref') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsProtocolStepDbxref).\n");
		  }
	      }
	  }
      }
  }

  $self->{bsstepdbxref_rows} = $bsstepdbxref_href;
}



###################################
### DATA ACCESSORS FOR PROTOCOL ###
###################################

=head2 get_protocol_id, force_set_protocol_id
  
  Usage: my $protocol_id = $protocol->get_protocol_id();
         $protocol->force_set_protocol_id($protocol_id);

  Desc: get or set a protocol_id in a protocol object. 
        set method should be USED WITH PRECAUTION
        If you want set a protocol_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        protocol_id that do not follow the biosource.bs_protocol_protocol_id_seq

  Ret:  get=> $protocol_id, a scalar.
        set=> none

  Args: get=> none
        set=> $protocol_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $protocol_id = $protocol->get_protocol_id(); 

=cut

sub get_protocol_id {
  my $self = shift;
  return $self->get_bsprotocol_row->get_column('protocol_id');
}

sub force_set_protocol_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None protocol_id was supplied for force_set_protocol_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The protocol_id ($data) for $self->force_set_protocol_id() ISN'T AN INTEGER.\n");
  }

  $self->get_bsprotocol_row()
       ->set_column( protocol_id => $data );
 
}

=head2 accessors get_protocol_name, set_protocol_name

  Usage: my $protocol_name = $protocol->get_protocol_name();
         $protocol->set_protocol_name($protocol_name);

  Desc: Get or set the protocol_name from protocol object. 

  Ret:  get=> $protocol_name, a scalar
        set=> none

  Args: get=> none
        set=> $protocol_name, a scalar

  Side_Effects: none

  Example: my $protocol_name = $protocol->get_protocol_name();
           $protocol->set_protocol_name($new_name);
=cut

sub get_protocol_name {
  my $self = shift;
  return $self->get_bsprotocol_row->get_column('protocol_name'); 
}

sub set_protocol_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_protocol_name function to CXGN::Biosource::Protocol.\n");

  $self->get_bsprotocol_row()
       ->set_column( protocol_name => $data );
}

=head2 accessors get_protocol_type, set_protocol_type

  Usage: my $protocol_type = $protocol->get_protocol_type();
         $protocol->set_protocol_type($protocol_type);
 
  Desc: Get or set protocol_type from a protocol object. 
 
  Ret:  get=> $protocol_type, a scalar
        set=> none
 
  Args: get=> none
        set=> $protocol_type, a scalar
 
  Side_Effects: none
 
  Example: my $protocol_type = $protocol->get_protocol_type();

=cut

sub get_protocol_type {
  my $self = shift;
  return $self->get_bsprotocol_row->get_column('protocol_type'); 
}

sub set_protocol_type {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_protocol_type function to CXGN::Biosource::Protocol.\n");

  $self->get_bsprotocol_row()
       ->set_column( protocol_type => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $protocol->get_description();
         $protocol->set_description($description);

  Desc: Get or set the description from a protocol object 

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: none

  Example: my $description = $protocol->get_description();
           $protocol->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_bsprotocol_row->get_column('description'); 
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_bsprotocol_row()
       ->set_column( description => $data );
}


#########################################
### DATA ACCESSORS FOR PROTOCOL STEPS ###
#########################################

=head2 add_protocol_step

  Usage: $protocol->add_protocol_step( $parameters_hash_ref );

  Desc: Add a new protocol step to the protocol object 

  Ret: None

  Args: A hash reference with key=protocol_step_parameter and value=value
        The protocol_step parameters and the type are:
          - step       => integer
          - action     => text 
          - execution  => text
          - tool_name  => text (or tool_id => integer)
          - begin_date => timestamp
          - end_date   => timestamp
          - location   => text

  Side_Effects: none

  Example: $protocol->add_protocol_step( 
                                         { 
                                           step   => 1,
                                           action => 'growth', 
                                           execution => 'during 30 days at 25C', 
                                         }
                                       );

=cut

sub add_protocol_step {
    my $self = shift;
    my $param_hashref = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_protocol_step function to $self.\n");

    if (ref($param_hashref) ne 'HASH') {
	 croak("DATA TYPE ERROR: The parameter hash ref. for $self->add_protocol_step() ISN'T A HASH REFERENCE.\n");
    }

    my %param = %{$param_hashref};
    if (exists $param{'tool_name'}) {
	my $tool = CXGN::Biosource::ProtocolTool->new_by_name($self->get_schema, delete($param{'tool_name'}) );
	my $tool_id = $tool->get_tool_id();
	if (defined $tool_id) {
	    unless (exists $param{'tool_id'}) {
		$param{'tool_id'} = $tool_id;
	    }
	}
    }

    my $protocol_id = $self->get_protocol_id();
    if (defined $protocol_id) {
	$param{'protocol_id'} = $protocol_id;
    }

    my $new_protocol_step_row = $self->get_schema()
	                             ->resultset('BsProtocolStep')
				     ->new(\%param);

    my %bsprotocolsteps_rows = $self->get_bsprotocolstep_rows();
    
    unless (exists $bsprotocolsteps_rows{$param{'step'}} ) {
	$bsprotocolsteps_rows{$param{'step'}} = $new_protocol_step_row;
    } 
    else {
	croak("FUNCTION ERROR: The step=$param{'step'} exists protocol obj. It can't be readded. Use edit_protocol_step to edit it.\n");
    }

    $self->set_bsprotocolstep_rows(\%bsprotocolsteps_rows);
}

=head2 get_protocol_steps

  Usage: my %protocol_steps = $protocol->get_protocol_steps();

  Desc: Get the protocol steps from a protocol object, 
        to get all the data from the row use get_columns function

  Ret: %protocol_steps, where: keys = step 
                               value = a hash reference with:
                                   keys  = column_name
                                   value = value
  Args: none

  Side_Effects: none

  Example: my %protocol_steps = $protocol->get_protocol_steps();
           my $first_action = $protocol_steps{1}->{action};

=cut

sub get_protocol_steps {
    my $self = shift;

    my %steps_by_data;
    
    my %bsprotocolsteps_rows = $self->get_bsprotocolstep_rows();
    foreach my $step ( keys %bsprotocolsteps_rows ) {
	my %data_hash = $bsprotocolsteps_rows{$step}->get_columns();
	$steps_by_data{$step} = \%data_hash;
    }
    return %steps_by_data;
}

=head2 edit_protocol_step

  Usage: $protocol->edit_protocol_step($step, $parameters_hash_ref);

  Desc: Edit a protocol step in the protocol object. 
        It can not edit the step. 
        To add a new step use add_protocol_step.
        To obsolete a step use obsolete_protocol_step.

  Ret: None

  Args: $step, a scalar, an integer,
        $parameters_hash_ref, a hash reference with 
        key=protocol_step_parameter and value=value
        The protocol_step parameters and the type are:
          - action     => text 
          - execution  => text
          - tool_name  => text (or tool_id => integer)
          - begin_date => timestamp
          - end_date   => timestamp
          - location   => text

  Side_Effects: none

  Example: $protocol->edit_protocol_step( 
                                         { 
                                           step   => 1,
                                           action => 'growth', 
                                           execution => 'during 30 days at 25C', 
                                         }
                                       );

=cut

sub edit_protocol_step {
    my $self = shift;
    my $step = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for edit_protocol_step function to $self.\n");
    
    unless ($step =~ m/^\d+$/) {
	croak("DATA TYPE ERROR: The step argument for $self->edit_protocol_step() ISN'T AN INTEGER.\n");
    }

    my $param_hashref = shift ||
	croak("FUNCTION PARAMETER ERROR: None parameter hash reference was supplied for edit_protocol_step function to $self.\n");


    if (ref($param_hashref) ne 'HASH') {
	 croak("DATA TYPE ERROR: The parameter hash ref. for $self->edit_protocol_step() ISN'T A HASH REFERENCE.\n");
    }

    ## Change tool_name for tool_id and delete tool name from the parameter hash

    my %param = %{$param_hashref};
    if (exists $param{'tool_name'}) {
	my $tool = CXGN::Biosource::ProtocolTool->new_by_name($self->get_schema, delete($param{'tool_name'}) );
	my $tool_id = $tool->get_tool_id();
	if (defined $tool_id) {
	    unless (exists $param{'tool_id'}) {
		$param{'tool_id'} = $tool_id;
	    }
	}
    }
    
    ## This should not change step or protocol_step_id
    delete($param{'step'});
    delete($param{'protocol_step_id'});
    

    my %bsprotocolsteps_rows = $self->get_bsprotocolstep_rows();
    
    unless (exists $bsprotocolsteps_rows{$step} ) {
	croak("FUNCTION ERROR: The step=$param{'step'} don't exists protocol obj. Use add_protocol_step to add a new one.\n");
    } 
    else {
	$bsprotocolsteps_rows{$step}->set_columns(\%param);
    }

    $self->set_bsprotocolstep_rows(\%bsprotocolsteps_rows);
}

########################################
### DATA ACCESSORS FOR PROTOCOL PUBS ###
########################################

=head2 add_publication

  Usage: $protocol->add_publication($pub_id);

  Desc: Add a publication to the pub_ids associated to protocol object 

  Ret:  None

  Args: $pub_row, a publication row object. 
        To use with $pub_id: 
          $protocol->add_publication($pub_id);
        To use with $pub_title
          $protocol->add_publication({ title => $pub_title } );
        To use with pubmed accession
          $protocol->add_publication({ dbxref_accession => $accesssion});
          
  Side_Effects: die if the parameter is not an object

  Example: $protocol->add_publication($pub_id);

=cut

sub add_publication {
    my $self = shift;
    my $pub = shift ||
        croak("FUNCTION PARAMETER ERROR: None pub was supplied for $$self->add_publication function to CXGN::Biosource::Protocol.\n");

    my $pub_id;
    if ($pub =~ m/^\d+$/) {
        $pub_id = $pub;
    }
    elsif (ref($pub) eq 'HASH') {
        my $pub_row; 
        if (exists $pub->{'title'}) {
            ($pub_row) = $self->get_schema()
                              ->resultset('Pub::Pub')
                              ->search( {title => $pub->{'title'} });
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
    my $protocolpub_row = $self->get_schema()
                               ->resultset('BsProtocolPub')
                               ->new({ pub_id => $pub_id});
    
    if (defined $self->get_protocol_id() ) {
        $protocolpub_row->set_column( protocol_id => $self->get_protocol_id() );
    }

    my @protocolpub_rows = $self->get_bsprotocolpub_rows();
    push @protocolpub_rows, $protocolpub_row;
    $self->set_bsprotocolpub_rows(\@protocolpub_rows);
}

=head2 get_publication_list

  Usage: my @pub_list = $protocol->get_publication_list();

  Desc: Get a list of publications associated to this tool

  Ret: An array of pub_ids by default, but can be titles
       or accessions using an argument

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @pub_id_list = $protocol->get_publication_list();
           my @pub_title_list = $protocol->get_publication_list('title');
           my @pub_title_accs = $protocol->get_publication_list('dbxref.accession');


=cut

sub get_publication_list {
    my $self = shift;
    my $field = shift;

    my @pub_list = ();

    my @protocolpub_rows = $self->get_bsprotocolpub_rows();
    foreach my $protocolpub_row (@protocolpub_rows) {
        my $pub_id = $protocolpub_row->get_column('pub_id');
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


##############################################
## DATA ACCESSORS FOR PROTOCOL_STEP_DBXREFs ##
##############################################

=head2 add_dbxref_to_protocol_step

  Usage: $protocol->add_dbxref_to_protocol_step($step, $dbxref_id);

  Desc: Add a new protocol_step_dbxref_row to the protocol object 

  Ret: None

  Args: $step, a scalar, an integer
        $dbxref_id, a scalar, an integer

  Side_Effects: check if exists the dbxref_id in the db, if it don't
                exists, die.

  Example: $protocol->add_dbxref_to_protocol_step($step, $dbxref_id)

=cut

sub add_dbxref_to_protocol_step {
    my $self = shift;

    ## Checking variables

    my $step = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_dbxref_to_protocol_step function to $self.\n");

    unless ($step =~ m/^\d+$/) {
	 croak("DATA TYPE ERROR: The step parameter for $self->add_dbxref_to_protocol_step() ISN'T AN INTEGER.\n");
    }
    
     my $dbxref_id = shift ||
	croak("FUNCTION PARAMETER ERROR: None dbxref_id was supplied for add_dbxref_to_protocol_step function to $self.\n");

    unless ($dbxref_id =~ m/^\d+$/) {
	 croak("DATA TYPE ERROR: The dbxref_id parameter for $self->add_dbxref_to_protocol_step() ISN'T AN INTEGER.\n");
    }
    else {
	my $dbxref_id_count = $self->get_schema()
	                           ->resultset('General::Dbxref')
			           ->search({ dbxref_id => $dbxref_id })
			           ->count();
	if ($dbxref_id_count == 0) {
	    croak("DATABASE COHERENCE ERROR: The dbxref_id parameter for $self->add_dbxref_to_protocol_step() don't exists in the db.\n");
	}
    }

    ## It will create new row using parameter hash

    my %params = ( dbxref_id => $dbxref_id );

    ## It will add the protocol_step_id if exists into the row object

    my %bsprotocolstep_rows = $self->get_bsprotocolstep_rows();
    my $protocol_step_id = $bsprotocolstep_rows{$step}->get_column('protocol_step_id');

    if (defined $protocol_step_id) {
	$params{protocol_step_id} = $protocol_step_id;
    }

    my $new_stepdbxref_row = $self->get_schema()
	                          ->resultset('BsProtocolStepDbxref')
				  ->new(\%params);

    my %bsstepdbxref_rows = $self->get_bsstepdbxref_rows();
     
    
    unless (exists $bsstepdbxref_rows{$step} ) {
	$bsstepdbxref_rows{$step} = [$new_stepdbxref_row];
    } 
    else {
	push @{$bsstepdbxref_rows{$step}}, $new_stepdbxref_row;
    }

    $self->set_bsstepdbxref_rows(\%bsstepdbxref_rows);
}


=head2 get_dbxref_from_protocol_steps

  Usage: my %protocolstepdbxref = $protocol->get_dbxref_from_protocol_steps();

  Desc: Get the dbxref_id associated to a protocol steps in a protocol object, 

  Ret: %protocol_steps, where: keys = step 
                               value = a array reference with a list of dbxref_ids
  Args: none

  Side_Effects: none

  Example: my %protocolstepdbxref = $protocol->get_dbxref_from_protocol_steps();
           my @first_dbxrefs = @{$protocolstepsdbxref{1}};

=cut

sub get_dbxref_from_protocol_steps {
    my $self = shift;

    my %dbxref_by_steps;
    
    my %bsstepdbxref_rows = $self->get_bsstepdbxref_rows();

    foreach my $step ( keys %bsstepdbxref_rows ) {
	my @dbxref_id_list = ();
	my @rows = @{$bsstepdbxref_rows{$step}};
	foreach my $row (@rows) {
	    push @dbxref_id_list, $row->get_column('dbxref_id');
	}
	$dbxref_by_steps{$step} = \@dbxref_id_list;
    }
    return %dbxref_by_steps;
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_protocol_metadbdata

  Usage: my $metadbdata = $protocol->get_protocol_metadbdata();

  Desc: Get metadata object associated to protocol data (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $protocol->get_protocol_metadbdata();
           my $metadbdata = $protocol->get_protocol_metadbdata($metadbdata);

=cut

sub get_protocol_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_bsprotocol_row
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
      my $protocol_id = $self->get_protocol_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the protocol_id=$protocol_id is undefined.\n");
  }
  
  return $metadbdata;
}

=head2 is_protocol_obsolete

  Usage: $protocol->is_protocol_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($protocol->is_protocol_obsolete()) { ## do something }

=cut

sub is_protocol_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_protocol_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}


=head2 accessors get_protocol_step_metadbdata

  Usage: my $metadbdata = $protocol->get_protocol_step_metadbdata();

  Desc: Get metadata object associated to protocol_step row 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with key=step and value=metadbdata object 
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $protocol->get_protocol_step_metadbdata();
           my %metadbdata = $protocol->get_protocol_step_metadbdata($metadbdata);

=cut

sub get_protocol_step_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my %protocol_steps = $self->get_protocol_steps();

  foreach my $step (keys %protocol_steps) {
      my $metadbdata;
      my $metadata_id = $protocol_steps{$step}->{'metadata_id'};

      if (defined $metadata_id) {
	  $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	  if (defined $metadata_obj_base) {

	      ## This will transfer the creation data from the base object to the new one
	      $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	      $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	  }
	  $metadbdata{$step} = $metadbdata;
      } 
      else {
	  my $protocol_id = $self->get_protocol_id();
	  unless (defined $protocol_id) {
	      croak("OBJECT MANIPULATION ERROR: The object $self haven't any protocol_id associated. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for protocol_step: protocol_id=$protocol_id and step=$step is undefined.\n");
	  }
      }
  }
  
  return %metadbdata;
}

=head2 is_protocol_step_obsolete

  Usage: $protocol->is_protocol_step_obsolete($step);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $step, a scalar, a protocol_step step
  
  Side_Effects: none
  
  Example: unless ($protocol->is_protocol_step_obsolete($step)) { ## do something }

=cut

sub is_protocol_step_obsolete {
  my $self = shift;
  my $step = shift;
  

  if (defined $step) {
      my %metadbdata = $self->get_protocol_step_metadbdata();
      my $obsolete = $metadbdata{$step}->get_obsolete();
      
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

=head2 accessors get_protocol_pub_metadbdata

  Usage: my %metadbdata = $protocol->get_protocol_pub_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=pub_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $protocol->get_protocol_pub_metadbdata();
           my %metadbdata = $protocol->get_protocol_pub_metadbdata($metadbdata);

=cut

sub get_protocol_pub_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();

  foreach my $bsprotocolpub_row (@bsprotocolpub_rows) {
      my $pub_id = $bsprotocolpub_row->get_column('pub_id');
      my $metadata_id = $bsprotocolpub_row->get_column('metadata_id');

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
          my $protocol_pub_id = $bsprotocolpub_row->get_column('protocol_pub_id');
	  unless (defined $protocol_pub_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any protocol_pub_id associated. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: The metadata_id for the protocol_pub_id=$protocol_pub_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_protocol_pub_obsolete

  Usage: $protocol->is_protocol_pub_obsolete($pub_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $pub_id, a publication_id
  
  Side_Effects: none
  
  Example: unless ( $protocol->is_protocol_pub_obsolete($pub_id) ) { ## do something }

=cut

sub is_protocol_pub_obsolete {
  my $self = shift;
  my $pub_id = shift;

  my %metadbdata = $self->get_protocol_pub_metadbdata();
  my $metadbdata = $metadbdata{$pub_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}


=head2 accessors get_step_dbxref_metadbdata

  Usage: my %metadbdata = $protocol->get_step_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=step
                    values=hash reference with:
                        keys=dbxref_id
                        values=metadbdata object
                        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $protocol->get_step_dbxref_metadbdata();
           my %metadbdata = $protocol->get_step_dbxref_metadbdata($metadbdata);

=cut

sub get_step_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata = (); 
  my %bsstepdbxref_rows = $self->get_bsstepdbxref_rows();

  foreach my $step (keys %bsstepdbxref_rows) {
      
      my @bsstepdbxref_rows = @{$bsstepdbxref_rows{$step}}; 
      my %dbxref_metadbdata_relation = ();

      foreach my $bsstepdbxref_row (@bsstepdbxref_rows) {
	  my $metadata_id = $bsstepdbxref_row->get_column('metadata_id');
	  my $dbxref_id = $bsstepdbxref_row->get_column('dbxref_id');

	  if (defined $metadata_id) {
	      my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	      if (defined $metadata_obj_base) {

		  ## This will transfer the creation data from the base object to the new one
		  $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
		  $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	      }
	 
	      $dbxref_metadbdata_relation{$dbxref_id} = $metadbdata;
	  } 
	  else {
	      my $step_dbxref_id = $bsstepdbxref_row->get_column('protocol_step_dbxref_id');
	      unless (defined $step_dbxref_id) {
		  croak("OBJECT MANIPULATION ERROR: It haven't any protocol_step_dbxref_id associated. Probably it hasn't been stored\n");
	      }
	      else {
		  croak("DATABASE INTEGRITY ERROR: Metadata_id for protocol_step_dbxref_id=$step_dbxref_id (step=$step) is undefined.\n");
	      }
	  }
      }
      $metadbdata{$step} = \%dbxref_metadbdata_relation;
  }
  return %metadbdata;
}

=head2 is_step_dbxref_obsolete

  Usage: $protocol->is_step_dbxref_obsolete($step, $dbxref_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $step, an integer, the step that have associated the dbxref relation
        $dbxref_id, another integer with the dbxref_id of the relation
  
  Side_Effects: none
  
  Example: unless ($protocol->is_step_dbxref_obsolete($step, $dbxref_id)) { 
                     ## do something 
                   }

=cut

sub is_step_dbxref_obsolete {
  my $self = shift;
  my $step = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_step_dbxref_metadbdata();
  my $metadbdata = $metadbdata{$step}->{$dbxref_id};
  
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

  Usage: my $protocol = $protocol->store($metadata);
 
  Desc: Store in the database the all protocol data for the protocol object
       (protocol, protocol_step, protocol_pub and protocol_step_dbxref rows)
       See the methods store_protocol, store_protocol_steps, 
       store_pub_associations and store_step_dbxref_associations

  Ret: $protocol, the protocol object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $protocol = $protocol->store($metadata);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store() is not CXGN::Metadata::Metadbdata object.\n");
    }

    $self->store_protocol($metadata)
	 ->store_protocol_steps($metadata)
	 ->store_pub_associations($metadata)
	 ->store_step_dbxref_associations($metadata);

    return $self;
}



=head2 store_protocol

  Usage: my $protocol = $protocol->store_protocol($metadata);
 
  Desc: Store in the database the protocol data for the protocol object
       (Only the bsprotocol row, don't store any protocol_step data)
 
  Ret: $protocol, the protocol object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $protocol = $protocol->store_protocol($metadata);

=cut

sub store_protocol {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_protocol().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_protocol() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not protocol_id. 
    ##   if exists protocol_id         => update
    ##   if do not exists protocol_id  => insert

    my $bsprotocol_row = $self->get_bsprotocol_row();
    my $protocol_id = $bsprotocol_row->get_column('protocol_id');

    unless (defined $protocol_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$bsprotocol_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$bsprotocol_row->insert()
                       ->discard_changes();                           ## It will set the row with the updated row
	
	## Now we set the protocol_id value for all the rows that depends of it as protocol_step rows or protocol_pub

	my %bsprotocolstep_rows = $self->get_bsprotocolstep_rows();
	foreach my $bsprotocolstep_row (values %bsprotocolstep_rows) {
	    $bsprotocolstep_row->set_column( protocol_id => $bsprotocol_row->get_column('protocol_id'));
	}

	my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();
	foreach my $bsprotocolpub_row (@bsprotocolpub_rows) {
	    $bsprotocolpub_row->set_column( protocol_id => $bsprotocol_row->get_column('protocol_id'));
	}
                    
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $bsprotocol_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_protocol_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $bsprotocol_row->set_column( metadata_id => $mod_metadata_id );

	    $bsprotocol_row->update()
                           ->discard_changes();
	}
    }
    return $self;    
}


=head2 obsolete_protocol

  Usage: my $protocol = $protocol->obsolete_protocol($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $protocol, the protocol object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $protocol = $protocol->store_protocol($metadata, 'change to obsolete test');

=cut

sub obsolete_protocol {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_protocol().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_protocol is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_protocol().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_protocol_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $bsprotocol_row = $self->get_bsprotocol_row();

    $bsprotocol_row->set_column( metadata_id => $mod_metadata_id );
         
    $bsprotocol_row->update()
	           ->discard_changes();

    return $self;
}

=head2 store_protocol_steps

  Usage: my $protocol = $protocol->store_protocol_steps($metadata);
 
  Desc: Store in the database protocol_steps associated to a protocol
 
  Ret: $protocol, a protocol object (CXGN::Biosource::Protocol)
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $protocol = $protocol->store_protocol_steps($metadata);

=cut

sub store_protocol_steps {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_protocol_steps().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_protocol_steps() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not protocol_step_id. 
    ##   if exists protocol_step_id         => update
    ##   if do not exists protocol_step_id  => insert

    my %bsprotocolstep_rows = $self->get_bsprotocolstep_rows();
    
    foreach my $bsprotocolstep_row (values %bsprotocolstep_rows) {
        my $protocol_step_id = $bsprotocolstep_row->get_column('protocol_step_id');
	my $protocol_id =  $bsprotocolstep_row->get_column('protocol_id');

	unless (defined $protocol_id) {
	    croak("STORE ERROR: Don't exist protocol_id associated to this step. Use store_protocol before use store_protocol_steps.\n");
	}

        unless (defined $protocol_step_id) {                                  ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $bsprotocolstep_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
            $bsprotocolstep_row->insert()
                               ->discard_changes();                           ## It will set the row with the updated row
	    
            ## Now it will set the protocol_step_id value for all the rows that depends of it as protocol_step_dbxref
	    
	    my %bsprotocolstepdbxref_rows = $self->get_bsstepdbxref_rows();
	    foreach my $bsprotocolstepdbxref_row_aref (values %bsprotocolstepdbxref_rows) {
		foreach my $bsprotocolstepdbxref_row (@{$bsprotocolstepdbxref_row_aref}) {
		    $bsprotocolstepdbxref_row->set_column( protocol_step_id => $bsprotocolstep_row->get_column('protocol_step_id'));
		}
	    }

        } 
        else {                                                                ## UPDATE IF SOMETHING has change
       
            my @columns_changed = $bsprotocolstep_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %ps_metadata = $self->get_protocol_step_metadbdata($metadata);
		my $step = $bsprotocolstep_row->get_column('step');
                my $mod_metadata_id = $ps_metadata{$step}->store({ modification_note => $modification_note })
                                                         ->get_metadata_id(); 

                $bsprotocolstep_row->set_column( metadata_id => $mod_metadata_id );

                $bsprotocolstep_row->update()
                                   ->discard_changes();
            }
        }
    }
    return $self;    
}


=head2 obsolete_protocol_step

  Usage: my $protocol = $protocol->obsolete_protocol_step( $metadata, 
                                                           $note, 
                                                           $step, 
                                                           'REVERT'
                                                         );
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will 
        be reverted to 0 (false)
 
  Ret: $protocol, the protocol object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $step, the step that identify this protocol_step
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $protocol = $protocol->obsolete_protocol_step( $metadata, 
                                                             change to obsolete', 
                                                             $step );

=cut

sub obsolete_protocol_step {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
        || croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_protocol_step().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_protocol_step is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
        || croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_protocol_step().\n");

    my $step = shift 
        || croak("OBSOLETE ERROR: None step was supplied to $self->obsolete_protocol_step().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
        $obsolete = 0;
        $modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %protocol_step_metadata = $self->get_protocol_step_metadbdata($metadata);
    my $mod_metadata_id = $protocol_step_metadata{$step}->store( { 
	                                                           modification_note => $modification_note,
                                                                   obsolete          => $obsolete, 
                                                                   obsolete_note     => $obsolete_note 
                                                                } )
                                                        ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bsprotocolstep_rows = $self->get_bsprotocolstep_rows();
       
    $bsprotocolstep_rows{$step}->set_column( metadata_id => $mod_metadata_id );
    
    $bsprotocolstep_rows{$step}->update()
	                      ->discard_changes();
    
    return $self;
}


=head2 store_pub_associations

  Usage: my $protocol = $protocol->store_pub_associations($metadata);
 
  Desc: Store in the database the pub association for the protocol object
 
  Ret: $protocol, the protocol object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $protocol = $protocol->store_pub_associations($metadata);

=cut

sub store_pub_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_pub_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_pub_associations() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not protocol_pub_id. 
    ##   if exists protocol_pub_id         => update
    ##   if do not exists protocol_pub_id  => insert

    my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();
    
    foreach my $bsprotocolpub_row (@bsprotocolpub_rows) {
        
        my $protocol_pub_id = $bsprotocolpub_row->get_column('protocol_pub_id');
	my $pub_id = $bsprotocolpub_row->get_column('pub_id');

        unless (defined $protocol_pub_id) {                                   ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $bsprotocolpub_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $bsprotocolpub_row->insert()
                              ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $bsprotocolpub_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %aspub_metadata = $self->get_protocol_pub_metadbdata($metadata);
		my $mod_metadata_id = $aspub_metadata{$pub_id}->store({ modification_note => $modification_note })
                                                              ->get_metadata_id(); 

                $bsprotocolpub_row->set_column( metadata_id => $mod_metadata_id );

                $bsprotocolpub_row->update()
                                  ->discard_changes();
            }
        }
    }
    return $self;    
}

=head2 obsolete_pub_association

  Usage: my $protocol = $protocol->obsolete_pub_association($metadata, $note, $pub_id, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $protocol, the protocol object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $pub_id, a publication id associated to this tool
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $protocol = $protocol->obsolete_pub_association($metadata, 
                                                      'change to obsolete test', 
                                                      $pub_id );

=cut

sub obsolete_pub_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_pub_association().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_pub_association is not CXGN::Metadata::Metadbdata obj.\n");
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
    
    my %aspub_metadata = $self->get_protocol_pub_metadbdata($metadata);
    my $mod_metadata_id = $aspub_metadata{$pub_id}->store( { modification_note => $modification_note,
							     obsolete          => $obsolete, 
							     obsolete_note     => $obsolete_note } )
                                                  ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @bsprotocolpub_rows = $self->get_bsprotocolpub_rows();
    foreach my $bsprotocolpub_row (@bsprotocolpub_rows) {
	if ($bsprotocolpub_row->get_column('pub_id') == $pub_id) {

	    $bsprotocolpub_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bsprotocolpub_row->update()
	                  ->discard_changes();
	}
    }
    return $self;
}


=head2 store_step_dbxref_associations

  Usage: my $protocol = $protocol->store_step_dbxref_associations($metadata);
 
  Desc: Store in the database the step dbxref association 
        for the protocol object
 
  Ret: $protocol, the protocol object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $protocol = $protocol->store_step_dbxref_associations($metadata);

=cut

sub store_step_dbxref_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_step_dbxref_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_step_dbxref_associations() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not protocol_step_dbxref_id. 
    ##   if exists protocol_step_dbxref_id         => update
    ##   if do not exists protocol_step_dbxref_id  => insert

    my %bsstepdbxref_rows_aref = $self->get_bsstepdbxref_rows();
    
    foreach my $step (keys %bsstepdbxref_rows_aref) {
        
	my @bsstepdbxref_rows = @{$bsstepdbxref_rows_aref{$step}};

	foreach my $bsstepdbxref_row (@bsstepdbxref_rows) {

	    my $protocol_step_dbxref_id = $bsstepdbxref_row->get_column('protocol_step_dbxref_id');
	    my $dbxref_id = $bsstepdbxref_row->get_column('dbxref_id');

	    unless (defined $protocol_step_dbxref_id) {                          ## NEW INSERT and DISCARD CHANGES
        
		my $metadata_id = $metadata->store()
		                           ->get_metadata_id();

		$bsstepdbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
		$bsstepdbxref_row->insert()
		                 ->discard_changes();                            ## It will set the row with the updated row
                            
	    } 
	    else {                                                               ## UPDATE IF SOMETHING has change
        
		my @columns_changed = $bsstepdbxref_row->is_changed();
        
		if (scalar(@columns_changed) > 0) {                              ## ...something has change, it will take
           
		    my @modification_note_list;                             ## the changes and the old metadata object for
		    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
			push @modification_note_list, "set value in $col_changed column";
		    }
                
		    my $modification_note = join ', ', @modification_note_list;
           
		    my %stepdbxref_metadata = $self->get_step_dbxref_metadbdata($metadata);
		    my $mod_metadata_id = $stepdbxref_metadata{$step}->{$dbxref_id}
                                                                     ->store({ modification_note => $modification_note })
                                                                     ->get_metadata_id(); 

		    $bsstepdbxref_row->set_column( metadata_id => $mod_metadata_id );

		    $bsstepdbxref_row->update()
			             ->discard_changes();
		}
            }
        }
    }
    return $self;    
}

=head2 obsolete_step_dbxref_association

  Usage: my $protocol = $protocol->obsolete_step_dbxref_association($metadata, 
                                                                    $note, 
                                                                    $step, 
                                                                    $dbxref_id, 
                                                                    'REVERT');
 
  Desc: Change the status of a data association to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $protocol, the protocol object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $step, the protocol step that have associated the dbxref_id
        $dbxref_id, the external reference associated to protocol_step 
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $protocol = $protocol->obsolete_step_dbxref_association(
                                                      $metadata,
                                                      'change to obsolete',
                                                      $step,
                                                      $dbxref_id,
                                                      );

=cut

sub obsolete_step_dbxref_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_step_dbxref_association().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_step_dbxref_association isn't CXGN::Metadata::Metadbdata.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_step_dbxref_association().\n");

    my $step = shift 
	|| croak("OBSOLETE ERROR: None step was supplied to $self->obsolete_step_dbxref_association().\n");

    my $dbxref_id = shift 
	|| croak("OBSOLETE ERROR: None dbxref_id was supplied to $self->obsolete_step_dbxref_association().\n");


    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag
    
    my %stepdbxref_metadata = $self->get_step_dbxref_metadbdata($metadata);
    my $metadbdata = $stepdbxref_metadata{$step}->{$dbxref_id};
    unless (defined $metadbdata) {
	croak("DATA COHERENCE ERROR: Don't exists any step_dbxref relation with step=$step and dbxref_id=$dbxref_id inside $self obj.\n")
    }
    my $mod_metadata_id = $metadbdata->store( { 
	                                        modification_note => $modification_note,
						obsolete          => $obsolete, 
						obsolete_note     => $obsolete_note 
                                             } )
                                             ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bsstepdbxref_rows_aref = $self->get_bsstepdbxref_rows();
    my @bsstepdbxref_rows = @{$bsstepdbxref_rows_aref{$step}};

    foreach my $bsstepdbxref_row (@bsstepdbxref_rows) {
	if ($bsstepdbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $bsstepdbxref_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bsstepdbxref_row->update()
	                     ->discard_changes();
	}
    }
    return $self;
}


####
1;##
####
