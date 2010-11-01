package CXGN::GEM::Expression;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::GEM::Template;

use Math::BigFloat;
use Chart::Clicker;
use Chart::Clicker::Data::Series;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series::HighLow;
use Chart::Clicker::Renderer::Bar;
use Chart::Clicker::Renderer::CandleStick;
use Chart::Clicker::Decoration::Legend::Tabular;


use Carp qw| croak cluck carp |;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Expression
a class to manipulate expression data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Expression;

 ## Constructor

  my $expression = CXGN::GEM::Expression->new($schema, $template_id);

 ## Accessors

  my %expression_by_experiment = $expression->get_experiment();
  my %expression_by_hybridization = $expression->get_hybridization();

  $expression->set_experiment({ experiment_id   => $experiment_id,
                                replicates_used => $rep,
                                mean            => $mean });

  $expression->set_hybridization({ hybridization_id     => $experiment_id,
                                   template_signal      => $value,
                                   template_signal_type => $type });


 ## Accessors hashref keys for experiment:
 ## (experiment_id, template_id, replicates_used, mean, median
 ## standard_desviation, coefficient_of_variance)

  my $median = $expression_by_experiment{'MyExperiment'}->{'median'}

 ## Accessors hashref keys for hybridization:
 ## (hybridization_id, template_id, template_signal, template_signal_type,
 ## statistical_value, statistical_value_type, flag)

  my $flag = $expression_by_hybridization{'MyHybridization'}->{'flag'}


=head1 DESCRIPTION

 This object take expression data from ge_expression_by_experiment and
 ge_template_expression from GEM component. This object only get data.
 Usually to insert data into the database it use a loading script.

 Also it has some functions to create graphs with this data.



=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut


############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $expression = CXGN::GEM::Expression->new($schema, $template_id);

  Desc: Create a new expression object

  Ret: a CXGN::GEM::Expression object

  Args: a $schema a schema object, preferentially created using:
	CXGN::GEM::Schema->connect(
		   sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
		   %other_parameters );
	A $template_id, a scalar.
	If $template_id is omitted, an empty template object is created.

  Side_Effects: access to database, check if exists the database columns that
		 this object use.  die if the id is not an integer.

  Example: my $expression = CXGN::GEM::Expression->new($schema, $template_id);

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
    ### this row in the database and after that get the data for template_expression and
    ### expression by experiment.
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my @template_experiment_rows = ();
    my @template_hybridization_rows = ();

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.

	    croak("\nDATA TYPE ERROR: The template_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_template_row object using a search based in the template_id

	@template_experiment_rows = $schema->resultset('GeExpressionByExperiment')
			                   ->search( { template_id => $id } );

	@template_hybridization_rows = $schema->resultset('GeTemplateExpression')
			                      ->search( { template_id => $id } );

    }

    ## Finally it will load the rows into the object.
    $self->set_getemplateexperiment_row(\@template_experiment_rows);
    $self->set_getemplatehybridization_row(\@template_hybridization_rows);

    return $self;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_getemplateexperiment_row, set_getemplateexperiment_row

  Usage: my @template_experiment_rows = $expression->get_getemplateexperiment_row();
         $expression->set_getemplateexperiment_row(\@template_experiment_rows);

  Desc: Get or set an array reference of GeExpressionByExperiment object into
        a expression object

  Ret:   Get => array of $getemplate_experiment_row object, a row object
		(CXGN::GEM::Schema::GeExpressionByExperiment).
	 Set => none

  Args:  Get => none
	 Set => array ref. of $getemplate_experiment_row object, a row object
		(CXGN::GEM::Schema::GeExpressionByExperiment).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @template_experiment_rows = $expression->get_getemplateexperiment_row();
           $expression->set_getemplateexperiment_row(\@template_experiment_rows);

=cut

sub get_getemplateexperiment_row {
  my $self = shift;

  return @{$self->{getemplateexperiment_row}};
}

sub set_getemplateexperiment_row {
  my $self = shift;
  my $getemplateexperiment_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR: None getemplate_experiment_row array reference was supplied for $self->set_getemplateexperiment_row function.\n");

  if (ref($getemplateexperiment_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $getemplateexperiment_row_aref isn't an array reference with CXGN::GEM::Schema::GeExpressionByExperiment objects.\n");
  }
  else {
      my @getemplateexperiment_rows = @{$getemplateexperiment_row_aref};
      foreach my $getemplateexperiment (@getemplateexperiment_rows) {
	  if (ref($getemplateexperiment) ne 'CXGN::GEM::Schema::GeExpressionByExperiment') {
	      croak("SET ARGUMENT ERROR: $getemplateexperiment isn't a getemplate_experiment_row obj. (CXGN::GEM::Schema::GeExpressionByExperiment).\n");
	  }
      }
      $self->{getemplateexperiment_row} = $getemplateexperiment_row_aref;
  }
}

=head2 accessors get_getemplatehybridization_row, set_getemplatehybridization_row

  Usage: my @template_hybridization_rows = $expression->get_getemplatehybridization_row();
         $expression->set_getemplatehybridization_row(\@template_hybridization_rows);

  Desc: Get or set an array reference of GeTemplateExpression object into
        a expression object

  Ret:   Get => array of $getemplate_hybridization_row object, a row object
		(CXGN::GEM::Schema::GeTemplateExpression).
	 Set => none

  Args:  Get => none
	 Set => array ref. of $getemplate_hybridization_row object, a row object
		(CXGN::GEM::Schema::GeTemplateExpression).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @template_hybridization_rows = $expression->get_getemplatehybridization_row();
           $expression->set_getemplatehybridization_row(\@template_hybridization_rows);

=cut

sub get_getemplatehybridization_row {
  my $self = shift;

  return @{$self->{getemplatehybridization_row}};
}

sub set_getemplatehybridization_row {
  my $self = shift;
  my $getemplatehybridization_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR: None getemplate_hybridization_row array reference was supplied for $self->set_getemplatehybridization_row function.\n");

  if (ref($getemplatehybridization_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $getemplatehybridization_row_aref isn't an array reference with CXGN::GEM::Schema::GeTemplateExpression objects.\n");
  }
  else {
      my @getemplatehybridization_rows = @{$getemplatehybridization_row_aref};
      foreach my $getemplatehybridization (@getemplatehybridization_rows) {
	  if (ref($getemplatehybridization) ne 'CXGN::GEM::Schema::GeTemplateExpression') {
	      croak("SET ARGUMENT ERROR: $getemplatehybridization isn't a getemplate_hybridization_row obj. (CXGN::GEM::Schema::GeTemplateExpression).\n");
	  }
      }
      $self->{getemplatehybridization_row} = $getemplatehybridization_row_aref;
  }
}

###################################
### DATA ACCESSORS FOR TEMPLATE ###
###################################

=head2 get_template_id, force_set_template_id

  Usage: my $template_id = $expression->get_template_id();
	 $expression->force_set_template_id($template_id);

  Desc: get or set a template_id in an expression object.
	set method change the template_id for
        CXGN::GEM::Schema::GeTemplateExpression and
	CXGN::GEM::Schema::GeExpressionByExperiment rows
        stored in the expression object.

  Ret:  get=> $template_id, a scalar.
	set=> none

  Args: get=> none
	set=> $template_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $template_id = $template->get_template_id();

=cut

sub get_template_id {
  my $self = shift;

  my $row;
  my @template_hybridization_rows = $self->get_getemplatehybridization_row();
  my @template_experiment_rows = $self->get_getemplateexperiment_row();

  if (scalar(@template_hybridization_rows) > 0) {
      $row = $template_hybridization_rows[0];
  }
  elsif (scalar(@template_experiment_rows) > 0) {
      $row = $template_experiment_rows[0];
  }

  if (defined $row) {
      return $row->get_column('template_id');
  }
  else {
      return undef;
  }
}

sub force_set_template_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None template_id was supplied for force_set_template_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The template_id ($data) for $self->force_set_template_id() ISN'T AN INTEGER.\n");
  }

  my @template_hybridization_rows = $self->get_getemplatehybridization_row();
  foreach my $template_hybridization_row (@template_hybridization_rows) {
      $template_hybridization_row->set_column( template_id => $data );
  }

  my @template_experiment_rows = $self->get_getemplateexperiment_row();
  foreach my $template_experiment_row (@template_experiment_rows) {
      $template_experiment_row->set_column( template_id => $data );
  }
}

=head2 get_experiment, set_experiment

  Usage: my %experiment = $expression->get_experiment();
	 $expression->set_experiment($experiment_data_href);

  Desc: get or set a expression data in an expression object.
	set method change some variables for
	CXGN::GEM::Schema::GeExpressionByExperiment row
        and set template_id for them. If it does not exist
        an row object with the parameters set, it will add
        a new one. If exists an object with the experiment_id
        it will edit the other parameters.

  Ret:  get=> %experiment, a hash with KEYS=experiment_id
              and VALUES=hash reference with keys=data_type
              and values=data_value.
              data_types are: experiment_id, replicates_used,
              mean, median, standard_desviation, coefficient_of_variance
              and dataset_id
	set=> none

  Args: get=> none
	set=> \%experiment, a hash ref. with KEYS=experiment_id
              and VALUES=hash reference with keys=data_type
              and values=data_value.
              data_types are: experiment_id, replicates_used,
              mean, median, standard_desviation, coefficient_of_variance
              and dataset_id.

  Side_Effects: Die if the argument is not a hash reference or if it do not have
                experiment_id

  Example: my %experiment = $expression->get_experiment();
	   $expression->set_experiment({
                                        experiment_id       => $id,
                                        replicates_used     => 3,
                                        mean                => 10,
                                        median              => 10.5,
                                        standard_desviation => 0.5,
                                       });

=cut

sub get_experiment {
     my $self = shift;

     my %experiment = ();

     my @template_experiment_rows = $self->get_getemplateexperiment_row();

     foreach my $template_exp_row (@template_experiment_rows) {
	 my %template_exp_col = $template_exp_row->get_columns();

	 $experiment{$template_exp_col{'experiment_id'}} = \%template_exp_col;
     }
     return %experiment;
}

sub set_experiment {
    my $self = shift;

    my $data_href = shift ||
      croak("FUNCTION PARAMETER ERROR: None experiment data hash ref. was supplied for set_experiment function.\n");

    unless (ref($data_href) eq 'HASH') {
	croak("DATA TYPE ERROR: The experiment data ($data_href) for $self->set_experiment() IS NOT A HASH REFERENCE.\n");
    }
    unless (exists $data_href->{'experiment_id'}) {
	croak("MANDATORY ARGUMENT ERROR: Experiment data used with $self->set_experiment() function has not any experiment_id.\n")
    }

    ## Get the template_id

    my $template_id = $self->get_template_id();

    ## Now it will check that the keys are right

    my %right_keys = ('experiment_id'           => 1,
		      'template_id'             => 1,
		      'replicates_used'         => 1,
		      'mean'                    => 1,
		      'median'                  => 1,
		      'standard_desviation'     => 1,
		      'coefficient_of_variance' => 1,
		      'dataset_id'              => 1
	             );

    my @keys = keys %{$data_href};

    foreach my $key (@keys) {
	if ($key eq 'template_id' && defined $template_id) {
	    carp("\nWARNING: template_id argument will be overwrite by the object's template_id.\n");
	}
	elsif ($key eq 'metadata_id') {
	    carp("\nWARNING: metadata_id argument will be ignore. It will be overwrite by the store function\n")
	}

	unless (exists $right_keys{$key}) {
	    carp("\nWARNING: $key is not a valid parameter. It will be ignore.\n");
	}
    }

    ## It will check if exists a row inside the object where experiment_id are the same.

    my $match = 'none';

    my @template_experiment_rows = $self->get_getemplateexperiment_row();

    foreach my $template_exp_row (@template_experiment_rows) {
	my %template_exp_col = $template_exp_row->get_columns();

	if ($template_exp_col{'experiment_id'} == $data_href->{'experiment_id'}) {
	    $match = $template_exp_row;
	}
    }

    ## Now it will overwrite the template_id (metadata_id will be overwrite with store function)

    if (defined $template_id) {
	$data_href->{'template_id'} = $template_id;
    }

    ## And set the row

    if ($match eq 'none') { ## Then it will add a new row

	my $new_row = $self->get_schema()
                           ->resultset('GeExpressionByExperiment')
	                   ->new($data_href);

	push @template_experiment_rows, $new_row;
    }
    else {  ## Then it will modify only the fields that are different
	my %row_data = $match->get_columns();
	foreach my $data_key (keys %row_data) {

	    if (defined $row_data{$data_key}) {
		if ($row_data{$data_key} =~ m/^\d+\.?\d*/) {
		    if (exists $data_href->{$data_key} && $row_data{$data_key} != $data_href->{$data_key}) {
			$match->set_column( $data_key => $data_href->{$data_key} );
		    }
		}
		else {
		    if (exists $data_href->{$data_key} && $row_data{$data_key} ne $data_href->{$data_key}) {
			$match->set_column( $data_key => $data_href->{$data_key} );
		    }
		}
	    }
	}
    }

    $self->set_getemplateexperiment_row(\@template_experiment_rows);
}


=head2 get_hybridization, set_hybridization

  Usage: my %hybridization = $hybridization->get_hybridization();
	 $expression->set_hybridization($hybridization_data_href);

  Desc: get or set a expression data in an expression object.
	set method change some variables for
	CXGN::GEM::Schema::GeTemplateExpression row
        and set template_id for them. If it does not exist
        an row object with the parameters set, it will add
        a new one. If exists an object with the hybridization_id
        it will edit the other parameters.

  Ret:  get=> %hybridization, a hash with KEYS=hybridization_id
              and VALUES=hash reference with keys=data_type
              and values=data_value.
              data_types are: hybridization_id, template_signal,
              template_signal_type, statistical_value, statistical_value_type,
              flag and dataset_id
	set=> none

  Args: get=> none
	set=> \%hybridization, a hash ref. with KEYS=hybridization_id
              and VALUES=hash reference with keys=data_type
              and values=data_value.
              data_types are: hybridization_id, template_signal,
              template_signal_type, statistical_value, statistical_value_type,
              flag and dataset_id

  Side_Effects: Die if the argument is not a hash reference or if it do not have
                hybridization_id

  Example: my %hybridization = $hybridization->get_hybridization();
	   $expression->set_hybridization({
                                            hybridization_id       => $id,
                                            template_signal        => 200,
                                            template_signal_type   => 'normalized fluorescence'
                                            statistical_value      => 0.0001,
                                            statistical_value_type => 'P-value'
                                          });

=cut

sub get_hybridization {
     my $self = shift;

     my %hybridization = ();

     my @template_hybridization_rows = $self->get_getemplatehybridization_row();

     foreach my $template_hyb_row (@template_hybridization_rows) {
	 my %template_hyb_col = $template_hyb_row->get_columns();

	 $hybridization{$template_hyb_col{'hybridization_id'}} = \%template_hyb_col;
     }
     return %hybridization;
}

sub set_hybridization {
    my $self = shift;

    my $data_href = shift ||
      croak("FUNCTION PARAMETER ERROR: No hybridization data hash ref. was supplied for set_hybridization function.\n");

    unless (ref($data_href) eq 'HASH') {
	croak("DATA TYPE ERROR: Hybridization data ($data_href) for $self->set_hybridization() IS NOT A HASH REFERENCE.\n");
    }
    unless (exists $data_href->{'hybridization_id'}) {
	croak("MANDATORY ARGUMENT ERROR: Hybridization data used with $self->set_hybridization() function has not any hybridization_id.\n")
    }

    ## Get the template_id

    my $template_id = $self->get_template_id();

    ## Now it will check that the keys are right

    my %right_keys = ('hybridization_id'       => 1,
		      'template_id'            => 1,
		      'template_signal'        => 1,
		      'template_signal_type'   => 1,
		      'statistical_value'      => 1,
		      'statistical_value_type' => 1,
		      'flag'                   => 1,
		      'dataset_id'             => 1
	             );

    my @keys = keys %{$data_href};

    foreach my $key (@keys) {
	if ($key eq 'template_id' && defined $template_id) {
	    carp("\nWARNING: template_id argument will be overwrite by the object's template_id.\n");
	}
	elsif ($key eq 'metadata_id') {
	    carp("\nWARNING: metadata_id argument will be ignore. It will be overwrite by the store function\n")
	}

	unless (exists $right_keys{$key}) {
	    carp("\nWARNING: $key is not a valid parameter. It will be ignore.\n");
	}
    }

    ## It will check if exists a row inside the object where experiment_id are the same.

    my $match = 'none';

    my @template_hybridization_rows = $self->get_getemplatehybridization_row();

    foreach my $template_hyb_row (@template_hybridization_rows) {
	my %template_hyb_col = $template_hyb_row->get_columns();

	if ($template_hyb_col{'hybridization_id'} == $data_href->{'hybridization_id'}) {
	    $match = $template_hyb_row;
	}
    }

    ## Now it will overwrite the template_id (metadata_id will be overwrite with store function)

    if (defined $template_id) {
	$data_href->{'template_id'} = $template_id;
    }

    ## And set the row

    if ($match eq 'none') { ## Then it will add a new row

	my $new_row = $self->get_schema()
	                   ->resultset('GeTemplateExpression')
	                   ->new($data_href);

	push @template_hybridization_rows, $new_row;
    }
    else {  ## Then it will modify only the fields that are different
	my %row_data = $match->get_columns();

	foreach my $data_key (keys %row_data) {

	    if (defined $row_data{$data_key}) {
		if ($row_data{$data_key} =~ m/^\d+\.?\d*/) {
		    if (exists $data_href->{$data_key} && $row_data{$data_key} != $data_href->{$data_key}) {
			$match->set_column( $data_key => $data_href->{$data_key} );
		    }
		}
		else {
		    if (exists $data_href->{$data_key} && $row_data{$data_key} ne $data_href->{$data_key}) {
			$match->set_column( $data_key => $data_href->{$data_key} );
		    }
		}
	    }
	}
    }
    $self->set_getemplatehybridization_row(\@template_hybridization_rows);
}



#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_template_experiment_metadbdata

  Usage: my %metadbdata = $expression->get_template_experiment_metadbdata();

  Desc: Get metadata object associated to tool data
	(see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=experiment_id and values=metadbdata object
	(CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $expression->get_template_experiment_metadbdata();
	   my %metadbdata =
	      $expression->get_template_experiment_metadbdata($metadbdata);

=cut

sub get_template_experiment_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @getemplateexperiment_rows = $self->get_getemplateexperiment_row();

  foreach my $getemplateexperiment_row (@getemplateexperiment_rows) {
      my $experiment_id = $getemplateexperiment_row->get_column('experiment_id');
      my $metadata_id = $getemplateexperiment_row->get_column('metadata_id');

      if (defined $metadata_id) {
	  my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	  if (defined $metadata_obj_base) {

	      ## This will transfer the creation data from the base object to the new one
	      $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	      $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	  }
	  $metadbdata{$experiment_id} = $metadbdata;
      }
      else {
	  my $template_experiment_id = $getemplateexperiment_row->get_column('expression_by_experiment_id');
	  unless (defined $template_experiment_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any expression_by_experiment_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the expression_by_experiment_id=$template_experiment_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_template_experiment_obsolete

  Usage: $expression->is_template_experiment_obsolete($experiment_id);

  Desc: Get obsolete field form metadata object associated to
	protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $experiment_id, a scalar, experiment_id

  Side_Effects: none

  Example: unless ($expression->is_template_experiment_obsolete($experiment_id)){
		## do something
	   }

=cut

sub is_template_experiment_obsolete {
  my $self = shift;
  my $experiment_id = shift;

  my %metadbdata = $self->get_template_experiment_metadbdata();
  my $metadbdata = $metadbdata{$experiment_id};

  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}

=head2 accessors get_template_hybridization_metadbdata

  Usage: my %metadbdata = $expression->get_template_hybridization_metadbdata();

  Desc: Get metadata object associated to tool data
	(see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=experiment_id and values=metadbdata object
	(CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $expression->get_template_hybridization_metadbdata();
	   my %metadbdata =
	      $expression->get_template_hybridization_metadbdata($metadbdata);

=cut

sub get_template_hybridization_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @getemplatehybridization_rows = $self->get_getemplatehybridization_row();

  foreach my $getemplatehybridization_row (@getemplatehybridization_rows) {
      my $hybridization_id = $getemplatehybridization_row->get_column('hybridization_id');
      my $metadata_id = $getemplatehybridization_row->get_column('metadata_id');

      if (defined $metadata_id) {
	  my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	  if (defined $metadata_obj_base) {

	      ## This will transfer the creation data from the base object to the new one
	      $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	      $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	  }
	  $metadbdata{$hybridization_id} = $metadbdata;
      }
      else {
	  my $template_hybridization_id = $getemplatehybridization_row->get_column('template_expression_id');
	  unless (defined $template_hybridization_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any template_expression_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the template_expression_id=$template_hybridization_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_template_hybridization_obsolete

  Usage: $expression->is_template_hybridization_obsolete($hybridization_id);

  Desc: Get obsolete field form metadata object associated to
	protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $hybridization_id, a scalar, hybridization_id

  Side_Effects: none

  Example: unless ($expression->is_template_hybridization_obsolete($hybridization_id)){
		## do something
	   }

=cut

sub is_template_hybridization_obsolete {
  my $self = shift;
  my $hybridization_id = shift;

  my %metadbdata = $self->get_template_hybridization_metadbdata();
  my $metadbdata = $metadbdata{$hybridization_id};

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

  Usage: $expression->store($metadbdata);

  Desc: Store in the database the all expression data for the
	expression object.
	See the methods store_template_experiment and
        store_template_hybridization for more details

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $expression->store($metadata);

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

    $self->store_template_experiment($metadata);
    $self->store_template_hybridization($metadata);

}


=head2 store_template_experiment

  Usage: $expression->store_template_experiment($metadata);

  Desc: Store in the database the expression experiment data
        for an expression object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $expression->store_template_experiment($metadata);

=cut

sub store_template_experiment {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_template_experiment().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_template_experiment() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not expression_by_experiment_id.
    ##   if exists expression_by_experiment_id         => update
    ##   if do not exists expression_by_experiment_id  => insert

    my @getemplateexperiment_rows = $self->get_getemplateexperiment_row();

    foreach my $getemplateexperiment_row (@getemplateexperiment_rows) {

	my $template_experiment_id = $getemplateexperiment_row->get_column('expression_by_experiment_id');
	my $experiment_id = $getemplateexperiment_row->get_column('experiment_id');

	unless (defined $template_experiment_id) {                                ## NEW INSERT and DISCARD CHANGES

	    $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

	    $getemplateexperiment_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

	    $getemplateexperiment_row->insert()
			             ->discard_changes();                            ## It will set the row with the updated row

	}
	else {                                                                    ## UPDATE IF SOMETHING has change

	    my @columns_changed = $getemplateexperiment_row->is_changed();

	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}

		my $modification_note = join ', ', @modification_note_list;

		my %astempexp_metadata = $self->get_template_experiment_metadbdata($metadata);
		my $mod_metadata = $astempexp_metadata{$experiment_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

		$getemplateexperiment_row->set_column( metadata_id => $mod_metadata_id );

		$getemplateexperiment_row->update()
		                         ->discard_changes();
	    }
	}
    }
}

=head2 obsolete_template_experiment

  Usage: $expression->obsolete_template_experiment($metadata, $note, $experiment_id, 'REVERT');

  Desc: Change the status of a data to obsolete.
	If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
	$note, a note to explain the cause of make this data obsolete
	$experiment_id, a experiment id
	optional, 'REVERT'.

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $expression->obsolete_template_experiment($metadata,
						     'change to obsolete test',
					             $experiment_id );

=cut

sub obsolete_template_experiment {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_template_experiment().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_template_experiment is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_template_experiment().\n");

    my $experiment_id = shift
	|| croak("OBSOLETE ERROR: None experiment_id was supplied to $self->obsolete_template_experiment().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id;

    my %astempexper_metadata = $self->get_template_experiment_metadbdata($metadata);
    if (exists $astempexper_metadata{$experiment_id}) {
	$mod_metadata_id = $astempexper_metadata{$experiment_id}->store( { modification_note => $modification_note,
								              obsolete          => $obsolete,
								              obsolete_note     => $obsolete_note } )
							           ->get_metadata_id();
	## Modify the group row in the database

	my @getemplateexperiment_rows = $self->get_getemplateexperiment_row();
	foreach my $getemplateexperiment_row (@getemplateexperiment_rows) {
	    if ($getemplateexperiment_row->get_column('experiment_id') == $experiment_id) {

		$getemplateexperiment_row->set_column( metadata_id => $mod_metadata_id );

		$getemplateexperiment_row->update()
			                 ->discard_changes();
	    }
	}
    }
    else {
	 croak("OBSOLETE ERROR: Experiment_id ($experiment_id) supplied to $self->obsolete_template_experiment() does not exist for this expression object.\n");
    }
}

=head2 store_template_hybridization

  Usage: $expression->store_template_hybridization($metadata);

  Desc: Store in the database the expression experiment data
        for an expression object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $expression->store_template_hybridization($metadata);

=cut

sub store_template_hybridization {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_template_hybridization().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_template_hybridization() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not template_expression_id.
    ##   if exists template_expression_id         => update
    ##   if do not exists template_expression_id  => insert

    my @getemplatehybridization_rows = $self->get_getemplatehybridization_row();

    foreach my $getemplatehybridization_row (@getemplatehybridization_rows) {

	my $template_hybridization_id = $getemplatehybridization_row->get_column('template_expression_id');
	my $hybridization_id = $getemplatehybridization_row->get_column('hybridization_id');

	unless (defined $template_hybridization_id) {                                ## NEW INSERT and DISCARD CHANGES

	    $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

	    $getemplatehybridization_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

	    $getemplatehybridization_row->insert()
			                ->discard_changes();                            ## It will set the row with the updated row

	}
	else {                                                                    ## UPDATE IF SOMETHING has change

	    my @columns_changed = $getemplatehybridization_row->is_changed();

	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}

		my $modification_note = join ', ', @modification_note_list;

		my %astemphyb_metadata = $self->get_template_hybridization_metadbdata($metadata);
		my $mod_metadata = $astemphyb_metadata{$hybridization_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

		$getemplatehybridization_row->set_column( metadata_id => $mod_metadata_id );

		$getemplatehybridization_row->update()
				            ->discard_changes();
	    }
	}
    }
}

=head2 obsolete_template_hybridization

  Usage: $expression->obsolete_template_hybridization($metadata, $note, $hybridization_id, 'REVERT');

  Desc: Change the status of a data to obsolete.
	If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
	$note, a note to explain the cause of make this data obsolete
	$hybridization_id, a hybridization id
	optional, 'REVERT'.

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $expression->obsolete_template_hybridization($metadata,
						        'change to obsolete test',
						        $experiment_id );

=cut

sub obsolete_template_hybridization {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_template_hybridization().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_template_hybridization is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_template_hybridization().\n");

    my $hybridization_id = shift
	|| croak("OBSOLETE ERROR: None hybridization_id was supplied to $self->obsolete_template_hybridization().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %astemphyb_metadata = $self->get_template_hybridization_metadbdata($metadata);
    if (exists $astemphyb_metadata{$hybridization_id}) {
	my $mod_metadata_id = $astemphyb_metadata{$hybridization_id}->store( { modification_note => $modification_note,
							                       obsolete          => $obsolete,
								               obsolete_note     => $obsolete_note } )
							            ->get_metadata_id();

	## Modify the group row in the database

	my @getemplatehybridization_rows = $self->get_getemplatehybridization_row();
	foreach my $getemplatehybridization_row (@getemplatehybridization_rows) {
	    if ($getemplatehybridization_row->get_column('hybridization_id') == $hybridization_id) {

		$getemplatehybridization_row->set_column( metadata_id => $mod_metadata_id );

		$getemplatehybridization_row->update()
			                    ->discard_changes();
	    }
	}
    }
    else {
	 croak("OBSOLETE ERROR: Hybridization_id ($hybridization_id) supplied to $self->obsolete_template_hybridization() does not exist for this expression object.\n");
    }


}



#####################
### OTHER METHODS ###
#####################

=head2 get_experiment_object

  Usage: my @experiments = $expression->get_experiment_object();
         my $experiment = $expression->get_experiment_object($experiment_id)

  Desc: Get one CXGN::GEM::Experiment object associate with
	the expression. If no experiment_id is used as argument, a list
        of experiment objects will be returned

  Ret:  A CXGN::GEM::Experiment object.

  Args: none

  Side_Effects: undef is returned if it is used a experiment_id
                that does not exist in the object.

  Example: my @experiments = $expression->get_experiment_object();
           my $experiment = $expression->get_experiment_object($experiment_id)

=cut

sub get_experiment_object {
   my $self = shift;
   my $experiment_id = shift;

   my %experiments = $self->get_experiment();
   unless (defined $experiment_id) {
       my @experiment_objs = ();
       foreach my $exp_id (keys %experiments) {
	   my $experiment_obj = CXGN::GEM::Experiment->new($self->get_schema(), $exp_id);
	   push @experiment_objs, $experiment_obj;
       }
       return @experiment_objs;
   }
   else {
       if (exists $experiments{$experiment_id}) {
	   my $experiment_obj = CXGN::GEM::Experiment->new($self->get_schema(), $experiment_id);
	   return $experiment_obj;
       }
       else {
	   return undef;
       }
   }
}

=head2 get_hybridization_object

  Usage: my @hybridizations = $expression->get_hybridization_object();
         my $hybridization = $expression->get_hybridization_object($hybridization_id)

  Desc: Get one CXGN::GEM::Hybridization object associate with
	the expression. If no experiment_id is used as argument, a list
        of hybridization objects will be returned

  Ret:  A CXGN::GEM::Hybridization object.

  Args: none

  Side_Effects: undef is returned if it is used a hybridization_id
                that does not exist in the object.

  Example: my @hybridizations = $expression->get_hybridization_object();
           my $hybridization = $expression->get_hybridization_object($hybridization_id)

=cut

sub get_hybridization_object {
   my $self = shift;
   my $hybridization_id = shift;

   my %hybridizations = $self->get_hybridization();
   unless (defined $hybridization_id) {
       my @hybridization_objs = ();
       foreach my $hyb_id (keys %hybridizations) {
	   my $hybridization_obj = CXGN::GEM::Hybridization->new($self->get_schema(), $hyb_id);
	   push @hybridization_objs, $hybridization_obj;
       }
       return @hybridization_objs;
   }
   else {
       if (exists $hybridizations{$hybridization_id}) {
	   my $hybridization_obj = CXGN::GEM::Hybridization->new($self->get_schema(), $hybridization_id);
	   return $hybridization_obj;
       }
       else {
	   return undef;
       }
   }
}



###################
## Graph Methods ##
###################



=head2 get_experiment_graph

  Usage: my $graph_object = $expression->get_experiment_graph()

  Desc: Create a graph object with the expression data for
        experiments

  Ret:  A Chart::Clicker object

  Args: $arg_href, a hash reference with different options.
        x_axis_sort => 'PO' (alphabetical by default)
        bar_color   => { red   => 35 / 255,
                         green => 35 / 255,
                         blue  => 142 / 255,
                         alpha => 1 } ## By default (blue)
        errorbar_color => { red   => 0 / 255,
                            green => 0 / 255,
                            blue  => 0 / 255,
                            alpha => 1 } ## By default (black)

  Side_Effects: none

  Example: my $graph_object = $expression->get_experiment_graph()

=cut

sub get_experiment_graph {
   my $self = shift;
   my $args_href = shift;

   ## Arguments handle by this function
   ## * 'x_axis_sort', a scalar (PO or undef) (undef by default)
   ## * 'bar_color', a hash reference with color ({ red => $int, green => $int, blue => $int, alpha => $int})(blue color by default)
   ## * 'errorbar_color', same than bar_color (black by default)
   ## * 'title', a scalar, the title of the graph ($experimental_design_name by default)
   ## * 'x_axis_label', a scalar, the title for the x axis ('Experiment' by default)
   ## * 'y_axis_label', a scalar, the title for the y axis ('Expression_Units_(Fluorescence_Intensity)')

   my $x_axis_sort    = $args_href->{'x_axis_sort'};
   my $bar_color_href = $args_href->{'bar_color'}
       || {
           red   =>  75 / 255,
           green =>  70 / 255,
           blue  => 179 / 255,
           alpha => 1,
          };
   my $errorbar_color_href = $args_href->{'errorbar_color'}
      || {
          red   => 0 / 255,
          green => 0 / 255,
          blue  => 0 / 255,
          alpha => 1,
         };
   my $title = $args_href->{'title'};
   my $x_axis_label =
       $args_href->{'x_axis_label'} || 'Experiment';
   my $y_axis_label =
       $args_href->{'y_axis_label'} || 'Expression_(Fluor._Intensity)';
   my $graph_width = $args_href->{'graph_width'} || 600;
   my $graph_height = $args_href->{'graph_height'} || 600;


   ## First, get the arrays with the data

   my ( $expdesign_name,
        $x_values_aref,
	$x_errorvals_aref,
	$x_tags_aref,
	$y_values_aref,
	$y_high_errorvals_aref,
	$y_low_errorvals_aref,
      ) = $self->expression_input_graph({ sort => $x_axis_sort});

   $title = $expdesign_name unless defined $title;

   ## Second, cut the prefix in the experiment_names (shorter = most easy to show)

   my $root_name = $self->get_prefix_name($x_tags_aref);

   if (defined $root_name) {
       $root_name .= '_';
       my @formated_names = ();
       foreach my $names (@{$x_tags_aref}) {
	   $names =~ s/$root_name//;
	   push @formated_names, ucfirst($names);
       }
       $x_tags_aref = \@formated_names;
   }

   ## Third, get the highest range value for Y-axis and define the graph ranges.

   my $y_max_range = $self->get_ymax_range($y_high_errorvals_aref);

   my @max_sort_exp = sort({$b <=> $a} @{$x_values_aref});
   my @min_sort_exp = sort({$a <=> $b} @{$x_values_aref});

   my $range_h = Chart::Clicker::Data::Range->new({ lower => $min_sort_exp[0] - 1, upper => $max_sort_exp[0] + 1 });
   my $range_v = Chart::Clicker::Data::Range->new({ lower => 0, upper => $y_max_range });

   ## Forth, the graph will composed by three parts, the base chart made with Bars, using the default context
   ## in the Chart::Clicker, and two CandleSticks rendered charts overlapped with the base chart. This two
   ## CandleStick graphs are used to draw the error bars.

   ## 1) Create the basic chart object

   my $chart = Chart::Clicker->new(width => $graph_width, height => $graph_height);

   $chart->title->text($title);
   $chart->title->font->size(15);
   $chart->title->padding->bottom(10);
   $chart->title->padding->top(10);

   $chart->legend->visible(0);  ## Switch off the legend.

   ## 2) Create the series (base, error_high and error_low)

   my $series_base = Chart::Clicker::Data::Series->new( keys   => $x_values_aref,
						        values => $y_values_aref,
                                                      );

   ## The CandleStick series are moved 0.5 to the left, to correct that the keys used
   ## have +0.5

   my $series_error_up = Chart::Clicker::Data::Series::HighLow->new( keys   => $x_errorvals_aref,
								     values => $y_high_errorvals_aref,
								     opens  => $y_high_errorvals_aref,
								     highs  => $y_high_errorvals_aref,
								     lows   => $y_values_aref,
                                                                   );

   my $series_error_down = Chart::Clicker::Data::Series::HighLow->new( keys   => $x_errorvals_aref,
								       values => $y_low_errorvals_aref,
								       opens  => $y_low_errorvals_aref,
								       highs  => $y_low_errorvals_aref,
								       lows   => $y_values_aref,
                                                                      );

   ## 3) Define the colors, bars blue and errobars black

   if ($args_href->{'bar_color'}) {
       unless (ref($args_href->{'bar_color'}) eq 'HASH') {
	   carp("WARNING: 'bar_color' argument is not a hash reference with keys = ('red', 'green', 'blue', 'alpha'). Ignoring argument.\n");
       }
   }
   my %bar_colordata = %{$bar_color_href};

   if ($args_href->{'errorbar_color'}) {
       unless (ref($args_href->{'errorbar_color'}) eq 'HASH') {
	   carp("WARNING: 'errorbar_color' argument is not a hash reference with keys = ('red', 'green', 'blue', 'alpha'). Ignoring argument.\n");
       }
   }
   my %errorbar_colordata = %{$errorbar_color_href};


   my $bar_color = Graphics::Color::RGB->new(%bar_colordata);
   my $errorbar_color = Graphics::Color::RGB->new(%errorbar_colordata);
   $chart->color_allocator->colors([ $bar_color, $errorbar_color, $errorbar_color]);

   ## 4) Define the three datasets (base, error_high and error_low)

   my $ds0 = Chart::Clicker::Data::DataSet->new(series => [$series_base]);
   my $ds1 = Chart::Clicker::Data::DataSet->new(series => [$series_error_up]);
   my $ds2 = Chart::Clicker::Data::DataSet->new(series => [$series_error_down]);

   ## 5) Add the base dataset to the chart under 'default' context

   $chart->add_to_datasets($ds0);

   my $def = $chart->get_context('default');
   $ds0->context('default');

   ## 6) Create two new context for the error bars and add to them the datasets
   ##    sharing the axis with the default context

   my $error_up_context = Chart::Clicker::Context->new( name => 'errorbars_up');
   $error_up_context->share_axes_with($def);

   $ds1->context('errorbars_up');
   $chart->add_to_contexts($error_up_context);

   $chart->add_to_datasets($ds1);

   my $error_down_context = Chart::Clicker::Context->new( name => 'errorbars_down');
   $error_down_context->share_axes_with($def);

   $ds2->context('errorbars_down');
   $chart->add_to_contexts($error_down_context);

   $chart->add_to_datasets($ds2);

   ## 7) Create the base chart with the ranged defined before and some titles

   my $bar = Chart::Clicker::Renderer::Bar->new( bar_padding => 8 );
   $def->renderer($bar);
   $def->range_axis->range($range_v);
   $def->range_axis->label($y_axis_label);
   $def->range_axis->format('%d');
   $def->domain_axis->range($range_h);
   $def->domain_axis->label($x_axis_label);
   $def->domain_axis->tick_values($x_values_aref);
   $def->domain_axis->format('%d');
   $def->domain_axis->tick_labels($x_tags_aref);
   $def->domain_axis->tick_font->size(9);
   $def->domain_axis->tick_label_angle(1.57);

   ## 8) Add the CandleStick Rendered to the error contexts

   my $barerror_up = Chart::Clicker::Renderer::CandleStick->new();
   $barerror_up->brush->width(1);
   $error_up_context->renderer($barerror_up);

   my $barerror_down = Chart::Clicker::Renderer::CandleStick->new();
   $barerror_down->brush->width(1);
   $error_down_context->renderer($barerror_down);

   return $chart;
}

=head2 expression_input_graph

  Usage: my @data = $expression->expression_input_graph()

  Desc: Generate an array with the following array refs:
         + $x_values (experiment_id),
         + $x_error (experiment_id+0.5),
         + $x_tags (experiment_names);
         + $y_values (mean)
         + $y_high_error (mean + SD)
         + $y_low_error (mean - SD)

        And the following scalar:
         + $expdesign_name (experimental_design_name)

  Ret:  An array with 6 array refernces

  Args: $parameter_href, a parameter hash reference with the
        following keys:
         + sort (values PO, alphabetical by default)

  Side_Effects: Replace the spaces in the experiment_name with
                underlines

  Example: my @data = $expression->expression_input_graph()

=cut

sub expression_input_graph {
    my $self = shift;
    my $param_href = shift;

    ## Define the arrays

    my @x_values = ();
    my @x_errorvals = ();
    my @x_tags = ();
    my @y_values = ();
    my @y_high_errorvals = ();
    my @y_low_errorvals = ();

    my %experiment = $self->get_experiment();

    ## First get all the possible experiment_designs

    my %expdesign = ();
    foreach my $exp_id (keys %experiment) {
	my $exp = CXGN::GEM::Experiment->new($self->get_schema(), $exp_id);
	my $expdesign_id = $exp->get_experimental_design_id();
	$expdesign{$expdesign_id} = 1;
    }

    my @experiments_ordered = ();

    if (defined $param_href->{'sort'} && $param_href->{'sort'} eq 'PO') {
	my @exp_from_expdesign = ();
	foreach my $expdsg_id (keys %expdesign) {
	    my $expdesign_obj = CXGN::GEM::ExperimentalDesign->new($self->get_schema(), $expdsg_id);
	    my @explist_ordered = $expdesign_obj->get_po_sorted_experiment_list();

	    ## Now it will add only the experiments from the expression object
	    foreach my $expobj (@explist_ordered) {
		my $exp_po_id = $expobj->get_experiment_id();
		if (exists $experiment{$exp_po_id}) {
		    push @experiments_ordered, $exp_po_id;
		}
	    }
	}
    }
    else {
	@experiments_ordered = keys %experiment;
    }

    my $expdesign_name;

    my $n = 1;
    my $x = 1;
    foreach my $experiment_id (@experiments_ordered) {

	## Get expression data

	my $mean = $experiment{$experiment_id}->{'mean'} || 0;
	my $sd = $experiment{$experiment_id}->{'standard_desviation'} || 0;

	## Get experiment data and experimental design data

	my $experiment = CXGN::GEM::Experiment->new($self->get_schema(), $experiment_id);
	my $experiment_name = $experiment->get_experiment_name();
	my $expdesign = $experiment->get_experimental_design();
	$expdesign_name = $expdesign->get_experimental_design_name();

	## Chart::Cliker give problems to draw names with spaces, this function
	## replace with underlines (_)

	$experiment_name =~ s/\s+/_/g;

	## Put the data into the arrays

	push @x_values, $x;
	push @x_errorvals, $x + 0.5;
	push @x_tags, $experiment_name;
	push @y_values, $mean;
	push @y_high_errorvals, $mean+$sd;
	push @y_low_errorvals, $mean-$sd;
	$x++;
    }

    ## Create the array ref.

    my @data = ($expdesign_name, \@x_values, \@x_errorvals, \@x_tags, \@y_values, \@y_high_errorvals, \@y_low_errorvals);

    return @data;
}


=head2 get_prefix_name

  Usage: my $root_name = $expression->get_prefix_name($array_ref)

  Desc: Extract the root of an array of names

  Ret:  $root_name, a scalar or undef

  Args: $array_ref, an array of references

  Side_Effects: none

  Example: my $root_name = $expression->get_prefix_name($array_ref)

=cut

sub get_prefix_name {
    my $self = shift;
    my $aref = shift;

    my @root = ();

    my @data = @{$aref};
    my $element_names_n = scalar(@data);

    my %element;

    foreach my $name (@data) {
	my @name_elements = split(/_/, $name);
	foreach my $el (@name_elements) {
	    if (exists $element{$el}) {
		$element{$el}++;
	    }
	    else {
		$element{$el} = 1;
	    }
	    if ($element{$el} == $element_names_n) {
		push @root, $el;
	    }
	}
    }
    if (scalar(@root) > 0) {
	my $root_name = join('_', @root);
	return $root_name;
    }
    else {
	return undef;
    }
}

=head2 get_ymax_range

  Usage: my $ymax_range = $expression->get_ymax_range($number_aref)

  Desc: Calculate the high range for a chart, based in the next rounded
        value of a list of values, for example:
        [23, 45, 60, 32, 81], the $y_max_range will be 90
        (highest value = 81, rounded = 80, next rounded = 90)

  Ret:  $y_max_range, a scalar

  Args: None

  Side_Effects: None

  Example: my $y_max_range = $expression->get_ymax_range($number_aref)

=cut

sub get_ymax_range {
    my $self = shift;
    my $data_aref = shift
	|| croak('DATA ARGUMENT ERROR: No data array reference was supplied to $self->get_ymax_range() function.\n');

    if (ref($data_aref) ne 'ARRAY') {
	croak('DATA ARGUMENT ERROR: The array reference supplied to $self->get_ymax_range() function IS NOT AN ARRAY REFERENCE.\n');
    }

    ## Order from highest to lowest and take the first element (highest)

    my @max_sort = sort({$b <=> $a} @{$data_aref});
    my $x = Math::BigFloat->new($max_sort[0]);

    ## Round

    $x->bceil();

    ## Calculate the magnitude order and round highest value with it

    my $xl = $x->length();
    if ($xl > 1) {
	$xl -= 1;
    }
    $x->bfround($xl);
    my $max_rounded = $x->bstr();

    ## Calculate the unit for that magnitude order and sum to the max.

    my $unit = 1;
    my $dec = 1;
    if ($max_rounded < $max_sort[0]) {
	while ($dec < $xl) {
	    $unit .= 0;
	    $dec++;
	}
	$max_rounded += $unit;
    }

    return $max_rounded;
}

####
1;##
####
