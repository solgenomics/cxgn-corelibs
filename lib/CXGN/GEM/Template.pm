package CXGN::GEM::Template;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::Metadata::Dbiref;
use CXGN::Metadata::Dbipath;
use CXGN::GEM::Platform;

use Carp qw| croak cluck carp |;



###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::Template
a class to manipulate a template data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::Template;

 ## Constructor

  my $template = CXGN::GEM::Template->new($schema, $template_id);
  my $template = CXGN::GEM::Template->new_by_name($schema, $template_id);

 ## Simple accessors (template_name, template_type, platform_id, )

  my $template_name = $template->get_template_name();
  $template->set_template_name($template_name);

 ## Extended accessors (dbxref, dbiref)

  my @dbxref_list_id = $template->get_dbxref_list();
  $template->add_dbxref($dbxref_id);

 ## Metadata functions (aplicable to extended data as dbxref or target_element)

  my $metadbdata = $template->get_template_metadbdata();
  unless ($template->is_template_obsolete()) {
		   ## do something
	   }

 ## Store functions (aplicable to extended data as dbxref or target_element)

  $template->store($metadata);
  $template->obsolete_template($metadata, $note, 'REVERT');

 ## Functions related with other objects

  my $platform = $template->get_platform();
  my @dbirefs = $template->get_dbiref_obj_list();

=head1 DESCRIPTION

 This object manage the target information of the database
 from the tables:

   + gem.ge_template
   + gem.ge_template_dbxref
   + gem.ge_template_dbiref

 This data is stored inside this object as dbic rows objects with the
 following structure:

  %Template_Object = (

       ge_template_row        => GeTemplate_row,

       ge_template_dbxref_row => [ @GeTemplateDbxref_rows],

       ge_template_dbiref_row => [ @GeTemplateDbiref_rows],

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

  Usage: my $template = CXGN::GEM::Template->new($schema, $template_id);

  Desc: Create a new template object

  Ret: a CXGN::GEM::Template object

  Args: a $schema a schema object, preferentially created using:
	CXGN::GEM::Schema->connect(
		   sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
		   %other_parameters );
	A $template_id, a scalar.
	If $template_id is omitted, an empty template object is created.

  Side_Effects: access to database, check if exists the database columns that
		 this object use.  die if the id is not an integer.

  Example: my $template = CXGN::GEM::Template->new($schema, $template_id);

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
    ### this row in the database and after that get the data for template
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $template;
    my @template_dbxrefs = ();
    my @template_dbirefs = ();

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.

	    croak("\nDATA TYPE ERROR: The template_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_template_row object using a search based in the template_id

	($template) = $schema->resultset('GeTemplate')
			     ->search( { template_id => $id } );

	if (defined $template) {

	    ## Search template_dbxref associations

	    @template_dbxrefs = $schema->resultset('GeTemplateDbxref')
				       ->search( { template_id => $id } );

	    ## Search template_dbxref associations

	    @template_dbirefs = $schema->resultset('GeTemplateDbiref')
				       ->search( { template_id => $id } );
	}
	else {
		$template = $schema->resultset('GeTemplate')
			   ->new({});                              ### Create an empty object;
	}
    }
    else {
	$template = $schema->resultset('GeTemplate')
			   ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the rows into the object.
    $self->set_getemplate_row($template);
    $self->set_getemplatedbxref_rows(\@template_dbxrefs);
    $self->set_getemplatedbiref_rows(\@template_dbirefs);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $template = CXGN::GEM::Template->new_by_name($schema, $name);

  Desc: Create a new Experiment object using template_name

  Ret: a CXGN::GEM::Template object

  Args: a $schema a schema object, preferentially created using:
	CXGN::GEM::Schema->connect(
		   sub{ CXGN::DB::Connection->new()->get_actual_dbh()},
		   %other_parameters );
	a $template_name, a scalar

  Side_Effects: accesses the database,
		return a warning if the experiment name do not exists
		into the db

  Example: my $template = CXGN::GEM::Template->new_by_name($schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift ||
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the template_id for this name and it will get the template_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the template_name for it

    my $template;
    my @templates;
    if (defined $name) {
	my @template_rows = $schema->resultset('GeTemplate')
				    ->search({ template_name => $name });

	if (scalar(@template_rows) == 0) {
	    warn("DATABASE OUTPUT WARNING: template_name ($name) for $class->new_by_name() DOES NOT EXIST IN THE DB.\n");

	    ## If do not exists any template with this name, it will return a warning and it will create an empty
	    ## object with the template name set in it.

	    $template = $class->new($schema);
	    $template->set_template_name($name);
	}
	else {
	   
	    ## if exists it will take the template_id to create the object with the new constructor
	    foreach my $t (@template_rows) { 
		push @templates, $class->new( $schema, $t->get_column('template_id') );
	    }
	    $template = $templates[0];
	}
    }
    else {
	$template = $class->new($schema);                              ### Create an empty object;
    }

    if (wantarray) { 
	return @templates;
    }
    else { 
	return $template;
    }
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_getemplate_row, set_getemplate_row

  Usage: my $getemplate_row = $self->get_getemplate_row();
	 $self->set_getemplate_row($getemplate_row_object);

  Desc: Get or set a getemplate row object into a template
	object

  Ret:   Get => $getemplate_row_object, a row object
		(CXGN::GEM::Schema::GeTemplate).
	 Set => none

  Args:  Get => none
	 Set => $getemplate_row_object, a row object
		(CXGN::GEM::Schema::GeTemplate).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my $getemplate_row = $self->get_getemplate_row();
	   $self->set_getemplate_row($getemplate_row);

=cut

sub get_getemplate_row {
  my $self = shift;

  return $self->{getemplate_row};
}

sub set_getemplate_row {
  my $self = shift;
  my $getemplate_row = shift
      || croak("FUNCTION PARAMETER ERROR: None getemplate_row object was supplied for $self->set_getemplate_row function.\n");

  if (ref($getemplate_row) ne 'CXGN::GEM::Schema::GeTemplate') {
      croak("SET ARGUMENT ERROR: $getemplate_row isn't a getemplate_row obj. (CXGN::GEM::Schema::GeTemplate).\n");
  }
  $self->{getemplate_row} = $getemplate_row;
}


=head2 accessors get_getemplatedbxref_rows, set_getemplatedbxref_rows

  Usage: my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();
	 $self->set_getemplatedbxref_rows(\@getemplatedbxref_rows);

  Desc: Get or set a list of getemplatedbxref rows object into an
	template object

  Ret:   Get => @getemplatedbxref_row_object, a list of row objects
		(CXGN::GEM::Schema::GeTemplateDbxref).
	 Set => none

  Args:  Get => none
	 Set => \@getemplatedbxref_row_object, an array ref of row objects
		(CXGN::GEM::Schema::GeTemplateDbxref).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();
	   $self->set_getemplatedbxref_rows(\@getemplatedbxref_rows);

=cut

sub get_getemplatedbxref_rows {
  my $self = shift;

  return @{$self->{getemplatedbxref_rows}};
}

sub set_getemplatedbxref_rows {
  my $self = shift;
  my $getemplatedbxref_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR:None getemplatedbxref_row array ref was supplied for $self->set_getemplatedbxref_rows().\n");

  if (ref($getemplatedbxref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $getemplatedbxref_row_aref isn't an array reference for $self->set_getemplatedbxref_rows().\n");
  }
  else {
      foreach my $getemplatedbxref_row (@{$getemplatedbxref_row_aref}) {
	  if (ref($getemplatedbxref_row) ne 'CXGN::GEM::Schema::GeTemplateDbxref') {
	      croak("SET ARGUMENT ERROR:$getemplatedbxref_row isn't getemplatedbxref_row obj.\n");
	  }
      }
  }
  $self->{getemplatedbxref_rows} = $getemplatedbxref_row_aref;
}


=head2 accessors get_getemplatedbiref_rows, set_getemplatedbiref_rows

  Usage: my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();
	 $self->set_getemplatedbiref_rows(\@getemplatedbiref_rows);

  Desc: Get or set a list of getemplatedbiref rows object into an
	template object

  Ret:   Get => @getemplatedbiref_row_object, a list of row objects
		(CXGN::GEM::Schema::GeTemplateDbiref).
	 Set => none

  Args:  Get => none
	 Set => \@getemplatedbxref_row_object, an array ref of row objects
		(CXGN::GEM::Schema::GeTemplateDbiref).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();
	   $self->set_getemplatedbiref_rows(\@getemplatedbiref_rows);

=cut

sub get_getemplatedbiref_rows {
  my $self = shift;

  return @{$self->{getemplatedbiref_rows}};
}

sub set_getemplatedbiref_rows {
  my $self = shift;
  my $getemplatedbiref_row_aref = shift
      || croak("FUNCTION PARAMETER ERROR:None getemplatedbiref_row array ref was supplied for $self->set_getemplatedbiref_rows().\n");

  if (ref($getemplatedbiref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $getemplatedbiref_row_aref isn't an array reference for $self->set_getemplatedbiref_rows().\n");
  }
  else {
      foreach my $getemplatedbiref_row (@{$getemplatedbiref_row_aref}) {
	  if (ref($getemplatedbiref_row) ne 'CXGN::GEM::Schema::GeTemplateDbiref') {
	      croak("SET ARGUMENT ERROR:$getemplatedbiref_row isn't getemplatedbiref_row obj.\n");
	  }
      }
  }
  $self->{getemplatedbiref_rows} = $getemplatedbiref_row_aref;
}


###################################
### DATA ACCESSORS FOR TEMPLATE ###
###################################

=head2 get_template_id, force_set_template_id

  Usage: my $template_id = $template->get_template_id();
	 $template->force_set_template_id($template_id);

  Desc: get or set a template_id in a template object.
	set method should be USED WITH PRECAUTION
	If you want set a template_id that do not exists into the
	database you should consider that when you store this object you
	CAN STORE a experiment_id that do not follow the
	gem.ge_template_template_id_seq

  Ret:  get=> $template_id, a scalar.
	set=> none

  Args: get=> none
	set=> $template_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $template_id = $template->get_template_id();

=cut

sub get_template_id {
  my $self = shift;
  return $self->get_getemplate_row->get_column('template_id');
}

sub force_set_template_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None template_id was supplied for force_set_template_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The template_id ($data) for $self->force_set_template_id() ISN'T AN INTEGER.\n");
  }

  $self->get_getemplate_row()
       ->set_column( template_id => $data );

}

=head2 accessors get_template_name, set_template_name

  Usage: my $template_name = $template->get_template_name();
	 $template->set_template_name($template_name);

  Desc: Get or set the template_name from template object.

  Ret:  get=> $template_name, a scalar
	set=> none

  Args: get=> none
	set=> $template_name, a scalar

  Side_Effects: none

  Example: my $template_name = $template->get_template_name();
	   $template->set_template_name($new_name);
=cut

sub get_template_name {
  my $self = shift;
  return $self->get_getemplate_row->get_column('template_name');
}

sub set_template_name {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_template_name function.\n");

  $self->get_getemplate_row()
       ->set_column( template_name => $data );
}


=head2 accessors get_template_type, set_template_type

  Usage: my $template_type = $template->get_template_type();
	 $template->set_template_type($template_type);

  Desc: Get or set the template_type from template object.

  Ret:  get=> $template_type, a scalar
	set=> none

  Args: get=> none
	set=> $template_type, a scalar

  Side_Effects: none

  Example: my $template_type = $template->get_template_type();
	   $template->set_template_type($type);
=cut

sub get_template_type {
  my $self = shift;
  return $self->get_getemplate_row->get_column('template_type');
}

sub set_template_type {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_template_type function.\n");

  $self->get_getemplate_row()
       ->set_column( template_type => $data );
}


=head2 accessors get_platform_id, set_platform_id

  Usage: my $platform_id = $template->get_platform_id();
	 $template->set_platform_id($platform_id);

  Desc: Get or set platform_id from a template object.

  Ret:  get=> $platform_id, a scalar
	set=> none

  Args: get=> none
	set=> $platform_id, a scalar

  Side_Effects: For the set accessor, die if the platform_id don't
		exists into the database

  Example: my $platform_id = $template->get_platform_id();
	   $template->set_platform_id($platform_id);
=cut

sub get_platform_id {
  my $self = shift;
  return $self->get_getemplate_row->get_column('platform_id');
}

sub set_platform_id {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_platform_id function.\n");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The experiment_id ($data) for $self->set_experiment_id() ISN'T AN INTEGER.\n");
  }

  $self->get_getemplate_row()
       ->set_column( platform_id => $data );
}


##########################################
### DATA ACCESSORS FOR TEMPLATE DBXREF ###
##########################################

=head2 add_dbxref

  Usage: $template->add_dbxref($dbxref_id);

  Desc: Add a dbxref to the dbxref_ids associated to sample
	object using dbxref_id or accesion + database_name

  Ret:  None

  Args: $dbxref_id, a dbxref id.
	To use with accession and dbxname:
	  $template->add_dbxref(
			       {
				 accession => $accesssion,
				 dbxname   => $dbxname,
			       }
			     );

  Side_Effects: die if the parameter is not an hash reference

  Example: $template->add_dbxref($dbxref_id);
	   $template->add_dbxref(
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

    my $templatedbxref_row = $self->get_schema()
				->resultset('GeTemplateDbxref')
				->new({ dbxref_id => $dbxref_id});

    if (defined $self->get_template_id() ) {
	$templatedbxref_row->set_column( template_id => $self->get_template_id() );
    }

    my @templatedbxref_rows = $self->get_getemplatedbxref_rows();
    push @templatedbxref_rows, $templatedbxref_row;
    $self->set_getemplatedbxref_rows(\@templatedbxref_rows);
}

=head2 get_dbxref_list

  Usage: my @dbxref_list_id = $template->get_dbxref_list();

  Desc: Get a list of dbxref_id associated to this template.

  Ret: An array of dbxref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbxref_id_list = $template->get_dbxref_list();

=cut

sub get_dbxref_list {
    my $self = shift;

    my @dbxref_list = ();

    my @templatedbxref_rows = $self->get_getemplatedbxref_rows();
    foreach my $templatedbxref_row (@templatedbxref_rows) {
	my $dbxref_id = $templatedbxref_row->get_column('dbxref_id');
	push @dbxref_list, $dbxref_id;
    }

    return @dbxref_list;
}


##########################################
### DATA ACCESSORS FOR TEMPLATE DBIREF ###
##########################################

=head2 add_dbiref

  Usage: $template->add_dbiref($dbiref_id);

  Desc: Add a dbiref to the dbiref_ids associated to sample
	object using dbiref_id or accesion + internal_path

  Ret:  None

  Args: $dbiref_id, a dbiref id.
	To use with accession and dbxname:
	  $template->add_dbiref(
			       {
				 accession => $accesssion,
				 dbipath   => $dbipath,
			       }
			     );

  Side_Effects: die if the parameter is not an hash reference

  Example: $template->add_dbiref($dbiref_id);
	   $template->add_dbiref(
				{
				  accession => '450000,
				  dbipath   => 'sgn.unigene.unigene_id',
				}
			      );
=cut

sub add_dbiref {
    my $self = shift;
    my $dbiref = shift ||
	croak("FUNCTION PARAMETER ERROR: None dbiref data was supplied for $self->add_dbiref function.\n");

    my $dbiref_id;

    ## If the imput parameter is an integer, treat it as id, if not do it as hash reference

    if ($dbiref =~ m/^\d+$/) {
	$dbiref_id = $dbiref;
    }
    elsif (ref($dbiref) eq 'HASH') {
	my $aref_dbipath = $dbiref->{'dbipath'} ||
	    croak("INPUT ARGUMENT ERROR: None dbipath aref was specified as argument for $self->add_dbiref() function.\n");
	my $accession = $dbiref->{'accession'} ||
	    croak("INPUT ARGUMENT ERROR: None accession was specified as argument for $self->add_dbiref() function.\n");

	## Check if the aref_dbipath is an array reference.

	my $dbipath;
	unless (ref($aref_dbipath) eq 'ARRAY') {
	    croak("TYPE ARGUMENT ERROR: Dbipath array reference supplied to $self->add_dbiref() is not an array reference.\n");
	}
	else {
	    $dbipath = join('.', @{$aref_dbipath});
	}

	## Now it will get the dbiref data using a constructor

	my $dbiref_obj = CXGN::Metadata::Dbiref->new_by_accession($self->get_schema, $accession, $aref_dbipath);

	$dbiref_id = $dbiref_obj->get_dbiref_id() ||
	    croak("DATABASE INPUT ERROR: Do not exists any dbiref_id with accession=$accession and dbipath=$dbipath.\n");
    }
    else {
	croak("INPUT ARGUMENT ERROR: The parameters supplied to $self->add_dbiref() function have wrong format.\n");
    }

    ## Finally, it will add the dbiref_id to the row

    my $templatedbiref_row = $self->get_schema()
				  ->resultset('GeTemplateDbiref')
				  ->new({ dbiref_id => $dbiref_id});

    if (defined $self->get_template_id() ) {
	$templatedbiref_row->set_column( template_id => $self->get_template_id() );
    }

    my @templatedbiref_rows = $self->get_getemplatedbiref_rows();
    push @templatedbiref_rows, $templatedbiref_row;
    $self->set_getemplatedbiref_rows(\@templatedbiref_rows);
}

=head2 get_dbiref_list

  Usage: my @dbiref_list_id = $template->get_dbiref_list();

  Desc: Get a list of dbiref_id associated to this template.

  Ret: An array of dbiref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbiref_list = $template->get_dbiref_list();

=cut

sub get_dbiref_list {
    my $self = shift;

    my @dbiref_list = ();

    my @templatedbiref_rows = $self->get_getemplatedbiref_rows();
    foreach my $templatedbiref_row (@templatedbiref_rows) {
	my $dbiref_id = $templatedbiref_row->get_column('dbiref_id');
	push @dbiref_list, $dbiref_id;
    }

    return @dbiref_list;
}



#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_template_metadbdata

  Usage: my $metadbdata = $template->get_template_metadbdata();

  Desc: Get metadata object associated to template data
	(see CXGN::Metadata::Metadbdata).

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $template->get_template_metadbdata();
	   my $metadbdata = $template->get_template_metadbdata($metadbdata);

=cut

sub get_template_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my $metadbdata;
  my $metadata_id = $self->get_getemplate_row
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
      my $template_id = $self->get_template_id();
      if (defined $template_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the template_id=$template_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any template_id. Probably it hasn't been stored yet.\n");
      }
  }

  return $metadbdata;
}

=head2 is_template_obsolete

  Usage: $template->is_template_obsolete();

  Desc: Get obsolete field form metadata object associated to
	protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: none

  Side_Effects: none

  Example: unless ($template->is_template_obsolete()) {
		   ## do something
	   }

=cut

sub is_template_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_template_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();

  if (defined $obsolete) {
      return $obsolete;
  }
  else {
      return 0;
  }
}


=head2 accessors get_template_dbxref_metadbdata

  Usage: my %metadbdata = $template->get_template_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data
	(see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=dbxref_id and values=metadbdata object
	(CXGN::Metadata::Metadbdata) for dbxref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $template->get_template_dbxref_metadbdata();
	   my %metadbdata =
	      $template->get_template_dbxref_metadbdata($metadbdata);

=cut

sub get_template_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();

  foreach my $getemplatedbxref_row (@getemplatedbxref_rows) {
      my $dbxref_id = $getemplatedbxref_row->get_column('dbxref_id');
      my $metadata_id = $getemplatedbxref_row->get_column('metadata_id');

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
	  my $template_dbxref_id = $getemplatedbxref_row->get_column('template_dbxref_id');
	  unless (defined $template_dbxref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any template_dbxref_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the template_dbxref_id=$template_dbxref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_template_dbxref_obsolete

  Usage: $template->is_template_dbxref_obsolete($dbxref_id);

  Desc: Get obsolete field form metadata object associated to
	protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $dbxref_id, a dbxref_id

  Side_Effects: none

  Example: unless ($template->is_template_dbxref_obsolete($dbxref_id)){
		## do something
	   }

=cut

sub is_template_dbxref_obsolete {
  my $self = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_template_dbxref_metadbdata();
  my $metadbdata = $metadbdata{$dbxref_id};

  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}


=head2 accessors get_template_dbiref_metadbdata

  Usage: my %metadbdata = $template->get_template_dbiref_metadbdata();

  Desc: Get metadata object associated to tool data
	(see CXGN::Metadata::Metadbdata).

  Ret:  A hash with keys=dbiref_id and values=metadbdata object
	(CXGN::Metadata::Metadbdata) for dbiref relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $template->get_template_dbiref_metadbdata();
	   my %metadbdata =
	      $template->get_template_dbiref_metadbdata($metadbdata);

=cut

sub get_template_dbiref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata;
  my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();

  foreach my $getemplatedbiref_row (@getemplatedbiref_rows) {
      my $dbiref_id = $getemplatedbiref_row->get_column('dbiref_id');
      my $metadata_id = $getemplatedbiref_row->get_column('metadata_id');

      if (defined $metadata_id) {
	  my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	  if (defined $metadata_obj_base) {

	      ## This will transfer the creation data from the base object to the new one
	      $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
	      $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	  }
	  $metadbdata{$dbiref_id} = $metadbdata;
      }
      else {
	  my $template_dbiref_id = $getemplatedbiref_row->get_column('template_dbiref_id');
	  unless (defined $template_dbiref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any template_dbiref_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the template_dbiref_id=$template_dbiref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_template_dbiref_obsolete

  Usage: $template->is_template_dbiref_obsolete($dbxref_id);

  Desc: Get obsolete field form metadata object associated to
	protocol data (see CXGN::Metadata::Metadbdata).

  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)

  Args: $dbiref_id, a dbiref_id

  Side_Effects: none

  Example: unless ($template->is_template_dbiref_obsolete($dbiref_id)){
		## do something
	   }

=cut

sub is_template_dbiref_obsolete {
  my $self = shift;
  my $dbiref_id = shift;

  my %metadbdata = $self->get_template_dbiref_metadbdata();
  my $metadbdata = $metadbdata{$dbiref_id};

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

  Usage: $template->store($metadbdata);

  Desc: Store in the database the all template data for the
	template object.
	See the methods store_template, store_dbxref_associations and
	store_dbiref_associations for more details

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $template->store($metadata);

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

    $self->store_template($metadata);
    $self->store_dbxref_associations($metadata);
    $self->store_dbiref_associations($metadata);

}


=head2 store_template

  Usage: $template->store_template($metadata);

  Desc: Store in the database the template data for the template
	object (Only the getemplate row, don't store any
	template_dbxref or template_dbiref data)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $template->store_template($metadata);

=cut

sub store_template {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_template().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_template() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not template_id.
    ##   if exists template_id         => update
    ##   if do not exists template_id  => insert

    my $getemplate_row = $self->get_getemplate_row();
    my $template_id = $getemplate_row->get_column('template_id');

    unless (defined $template_id) {                                   ## NEW INSERT and DISCARD CHANGES

	$metadata->store();
	my $metadata_id = $metadata->get_metadata_id();

	$getemplate_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column

	$getemplate_row->insert()
		       ->discard_changes();                           ## It will set the row with the updated row

	## Now we set the template_id value for all the rows that depends of it

	my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();
	foreach my $getemplatedbxref_row (@getemplatedbxref_rows) {
	    $getemplatedbxref_row->set_column( template_id => $getemplate_row->get_column('template_id'));
	}

	my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();
	foreach my $getemplatedbiref_row (@getemplatedbiref_rows) {
	    $getemplatedbiref_row->set_column( template_id => $getemplate_row->get_column('template_id'));
	}


    }
    else {                                                            ## UPDATE IF SOMETHING has change

	my @columns_changed = $getemplate_row->is_changed();

	if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

	    my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }

	    my $modification_note = join ', ', @modification_note_list;

	    my $mod_metadata = $self->get_template_metadbdata($metadata);
	    $mod_metadata->store({ modification_note => $modification_note });
	    my $mod_metadata_id = $mod_metadata->get_metadata_id();

	    $getemplate_row->set_column( metadata_id => $mod_metadata_id );

	    $getemplate_row->update()
			 ->discard_changes();
	}
    }
}


=head2 obsolete_template

  Usage: $template->obsolete_template($metadata, $note, 'REVERT');

  Desc: Change the status of a data to obsolete.
	If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
	$note, a note to explain the cause of make this data obsolete
	optional, 'REVERT'.

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $template->obsolete_template($metadata, 'change to obsolete test');

=cut

sub obsolete_template {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_template().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_template isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_template().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata = $self->get_template_metadbdata($metadata);
    $mod_metadata->store( { modification_note => $modification_note,
			    obsolete          => $obsolete,
			    obsolete_note     => $obsolete_note } );
    my $mod_metadata_id = $mod_metadata->get_metadata_id();

    ## Modify the group row in the database

    my $getemplate_row = $self->get_getemplate_row();

    $getemplate_row->set_column( metadata_id => $mod_metadata_id );

    $getemplate_row->update()
		 ->discard_changes();
}


=head2 store_dbxref_associations

  Usage: $template->store_dbxref_associations($metadata);

  Desc: Store in the database the dbxref association for the template
	object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $template->store_dbxref_associations($metadata);

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

    ## SECOND, check if exists or not template_dbxref_id.
    ##   if exists template_dbxref_id         => update
    ##   if do not exists template_dbxref_id  => insert

    my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();

    foreach my $getemplatedbxref_row (@getemplatedbxref_rows) {

	my $template_dbxref_id = $getemplatedbxref_row->get_column('template_dbxref_id');
	my $dbxref_id = $getemplatedbxref_row->get_column('dbxref_id');

	unless (defined $template_dbxref_id) {                                ## NEW INSERT and DISCARD CHANGES

	    $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

	    $getemplatedbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

	    $getemplatedbxref_row->insert()
			       ->discard_changes();                            ## It will set the row with the updated row

	}
	else {                                                                    ## UPDATE IF SOMETHING has change

	    my @columns_changed = $getemplatedbxref_row->is_changed();

	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}

		my $modification_note = join ', ', @modification_note_list;

		my %asdbxref_metadata = $self->get_template_dbxref_metadbdata($metadata);
		my $mod_metadata = $asdbxref_metadata{$dbxref_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

		$getemplatedbxref_row->set_column( metadata_id => $mod_metadata_id );

		$getemplatedbxref_row->update()
				   ->discard_changes();
	    }
	}
    }
}

=head2 obsolete_dbxref_association

  Usage: $template->obsolete_dbxref_association($metadata, $note, $dbxref_id, 'REVERT');

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

  Example: $template->obsolete_dbxref_association($metadata,
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

    my %asdbxref_metadata = $self->get_template_dbxref_metadbdata($metadata);
    my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store( { modification_note => $modification_note,
								   obsolete          => $obsolete,
								   obsolete_note     => $obsolete_note } )
							->get_metadata_id();

    ## Modify the group row in the database

    my @getemplatedbxref_rows = $self->get_getemplatedbxref_rows();
    foreach my $getemplatedbxref_row (@getemplatedbxref_rows) {
	if ($getemplatedbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $getemplatedbxref_row->set_column( metadata_id => $mod_metadata_id );

	    $getemplatedbxref_row->update()
			       ->discard_changes();
	}
    }
}


=head2 store_dbiref_associations

  Usage: $template->store_dbiref_associations($metadata);

  Desc: Store in the database the dbiref association for the template
	object

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata
		   object

  Example: $template->store_dbiref_associations($metadata);

=cut

sub store_dbiref_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_dbxref_associations().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_dbxref_associations() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not template_dbiref_id.
    ##   if exists template_dbiref_id         => update
    ##   if do not exists template_dbiref_id  => insert

    my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();

    foreach my $getemplatedbiref_row (@getemplatedbiref_rows) {

	my $template_dbiref_id = $getemplatedbiref_row->get_column('template_dbiref_id');
	my $dbiref_id = $getemplatedbiref_row->get_column('dbiref_id');

	unless (defined $template_dbiref_id) {                                ## NEW INSERT and DISCARD CHANGES

	    $metadata->store();
	    my $metadata_id = $metadata->get_metadata_id();

	    $getemplatedbiref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column

	    $getemplatedbiref_row->insert()
				 ->discard_changes();                            ## It will set the row with the updated row

	}
	else {                                                                    ## UPDATE IF SOMETHING has change

	    my @columns_changed = $getemplatedbiref_row->is_changed();

	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take

		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}

		my $modification_note = join ', ', @modification_note_list;

		my %asdbiref_metadata = $self->get_template_dbiref_metadbdata($metadata);
		my $mod_metadata = $asdbiref_metadata{$dbiref_id}->store({ modification_note => $modification_note });
		my $mod_metadata_id = $mod_metadata->get_metadata_id();

		$getemplatedbiref_row->set_column( metadata_id => $mod_metadata_id );

		$getemplatedbiref_row->update()
				     ->discard_changes();
	    }
	}
    }
}

=head2 obsolete_dbiref_association

  Usage: $template->obsolete_dbiref_association($metadata, $note, $dbiref_id, 'REVERT');

  Desc: Change the status of a data to obsolete.
	If revert tag is used the obsolete status will be reverted to 0 (false)

  Ret: None

  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
	$note, a note to explain the cause of make this data obsolete
	$dbiref_id, a dbiref id
	optional, 'REVERT'.

  Side_Effects: Die if:
		1- None metadata object is supplied.
		2- The metadata supplied is not a CXGN::Metadata::Metadbdata

  Example: $template->obsolete_dbxref_association($metadata,
						    'change to obsolete test',
						    $dbiref_id );

=cut

sub obsolete_dbiref_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter

    my $metadata = shift
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_dbiref_association().\n");

    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_dbiref_association is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_dbiref_association().\n");

    my $dbiref_id = shift
	|| croak("OBSOLETE ERROR: None dbiref_id was supplied to $self->obsolete_dbiref_association().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %asdbiref_metadata = $self->get_template_dbiref_metadbdata($metadata);
    my $mod_metadata_id = $asdbiref_metadata{$dbiref_id}->store( { modification_note => $modification_note,
								   obsolete          => $obsolete,
								   obsolete_note     => $obsolete_note } )
							->get_metadata_id();

    ## Modify the group row in the database

    my @getemplatedbiref_rows = $self->get_getemplatedbiref_rows();
    foreach my $getemplatedbiref_row (@getemplatedbiref_rows) {
	if ($getemplatedbiref_row->get_column('dbiref_id') == $dbiref_id) {

	    $getemplatedbiref_row->set_column( metadata_id => $mod_metadata_id );

	    $getemplatedbiref_row->update()
			       ->discard_changes();
	}
    }
}


#####################
### OTHER METHODS ###
#####################

=head2 get_platform

  Usage: my $platform = $template->get_platform();

  Desc: Get a CXGN::GEM::PLatform object associate with
	the temnplate

  Ret:  A CXGN::GEM::Platform object.

  Args: none

  Side_Effects: die if the template object have not any
		experiment_id

  Example: my $platform = $template->get_platform();

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

=head2 get_dbiref_obj_list

  Usage: my @dbirefs = $template->get_dbiref_obj_list();

  Desc: Get a list CXGN::GEM::Dbiref object associated with the
	template_id

  Ret: An array with a list of CXGN::Metadata::Dbiref objects.

  Args: none

  Side_Effects: die if the template_object have not any
		template_id

  Example: my @dbirefs = $platform->get_dbiref_obj_list();

=cut

sub get_dbiref_obj_list {
   my $self = shift;

   my @dbirefs = ();

   my $template_id = $self->get_template_id();

   unless (defined $template_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any template_id. Probably it hasn't store yet.\n");
   }

   my @dbiref_ids = $self->get_dbiref_list();

   foreach my $dbiref_id (@dbiref_ids) {
       my $dbiref = CXGN::Metadata::Dbiref->new($self->get_schema(), $dbiref_id);

       push @dbirefs, $dbiref;
   }

   return @dbirefs;

}

=head2 get_internal_accessions

  Usage: my @iref_accessions = $template->get_internal_accession($type);

  Desc: Get a list of internal accessions for the specified type

  Ret: An array with a list of accessions

  Args: $type, an scalar to match with dbipath associated with
	dbiref (for example unigene will match with sgn.unigene.unigene_id)

  Side_Effects: if type does not match, it will return an empty object
		die if the object has not any template_id
		if $type is undef, it will return everything that match
		with \w+

  Example: my @iref_accessions = $template->get_internal_accession('unigene');

=cut

sub get_internal_accessions {
   my $self = shift;
   my $type = shift || '\w+';

   my @iref_accessions = ();

   my $template_id = $self->get_template_id();

   unless (defined $template_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any template_id. Probably it hasn't store yet.\n");
   }

   my @dbirefs = $self->get_dbiref_obj_list();

   foreach my $dbiref (@dbirefs) {
       my $iref_accession = $dbiref->get_accession();
       my @dbipath = $dbiref->get_dbipath_obj()
			    ->get_dbipath();

       my $dbipath = join('.', @dbipath);
       if ($dbipath =~ m/$type/) {
	   push @iref_accessions, $iref_accession;
       }
   }

   return @iref_accessions;

}


####
1;##
####
