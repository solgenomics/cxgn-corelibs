
package CXGN::GEM::ExperimentalDesign;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::GEM::Experiment;
use CXGN::GEM::Target;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Metadbdata;

use Carp qw| croak cluck |;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::GEM::ExperimentalDesign
a class to manipulate a experimental design data from the gem schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

 use CXGN::GEM::ExperimentalDesign;

 ## Constructor

 my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema, $expdesign_id); 

 ## Simple accessors

 my $expdesign_name = $expdesign->get_experimental_design_name();
 $expdesign->set_experimental_design_name($new_name);

 ## Extended accessors

 my @pub_id_list = $expdesign->get_publication_list();
 $expdesign->add_publication($pub_id); 

 my @dbxref_id_list = $expdesign->get_dbxref_list();
 $expdesign->add_dbxref($dbxref_id);

 ## Metadata functions (aplicable to extended data as pub or dbxref)

 my $metadbdata = $expdesign->get_experimental_design_metadbdata();

 if ($expdesign->is_experimental_design_obsolete()) {
    ## Do something
 }

 ## Store functions (aplicable to extended data as pub or dbxref)

 $expdesign->store($metadbdata);

 $expdesign->obsolete_experimental_design($metadata, 'change to obsolete test');


=head1 DESCRIPTION

 This object manage the experimental design information of the database
 from the tables:
  
   + gem.ge_experimental_design
   + gem.ge_experimental_design_dbxref
   + gem.ge_experimental_design_pub

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %ExperimentalDesign_Object = ( 
    
       ge_expdesign_row        => GeExperimentalDesign_row, 
                     
       ge_expdesign_dbxref_row => [ @GeExperimentalDesignDbxref_rows], 
 
       ge_expdesign_pub_row    => [ @GeExperimentalDesignPub_rows],
    
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

  Usage: my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema, 
                                                            $expdesign_id);

  Desc: Create a new experimentla design object

  Ret: a CXGN::GEM::ExperimentalDesign object

  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        A $expdesign, a scalar.
        If $expdesign_id is omitted, an empty experimental design object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $sample = CXGN::GEM::ExperimentalDesign->new($schema, 
                                                           $expdesign_id);

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
    ### this row in the database and after that get the data for expdesign. 
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $expdesign;
    my @expdesign_pubs = (); 
    my @expdesign_dbxrefs = ();
 
    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The experimental_design_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the ge_expdesign_row object using a search based in the expdesign_id 

	($expdesign) = $schema->resultset('GeExperimentalDesign')
	                      ->search( { experimental_design_id => $id } );
	

	## If is not defined the $expdesign (the id does not exist in the db), it will create an empty object

	if (defined $expdesign) {

	    ## Search experimenatl_design_pub associations (ge_experimental_design_pub_row objects) based in the expdesign_id
	
	    @expdesign_pubs = $schema->resultset('GeExperimentalDesignPub')
	                             ->search( { experimental_design_id => $id } );
	
	    ## Search experimental_design_dbxref associations
	
	    @expdesign_dbxrefs = $schema->resultset('GeExperimentalDesignDbxref')
	                                ->search( { experimental_design_id => $id } );
	}
	else {
	    $expdesign = $schema->resultset('GeExperimentalDesign')
	                        ->new({});                              ### Create an empty object;
	}
    }
    else {
	$expdesign = $schema->resultset('GeExperimentalDesign')
	                    ->new({});                              ### Create an empty object;
    }

	## Finally it will load the rows into the object.
	$self->set_geexpdesign_row($expdesign);
	$self->set_geexpdesignpub_rows(\@expdesign_pubs);
	$self->set_geexpdesigndbxref_rows(\@expdesign_dbxrefs);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $expdesign = CXGN::GEM::ExperimentalDesign->new_by_name($schema, 
                                                                    $name);
 
  Desc: Create a new ExperimentalDesign object using experimental_design_name
 
  Ret: a CXGN::GEM::ExperimentalDesign object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::GEM::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $experimental_design_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the experimental design name do not exists 
                into the db
 
  Example: my $expdesign = CXGN::GEM::ExperimentalDesign->new_by_name( $schema, 
                                                                       $name  );

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the experimental_design_id for this name and it will get the experimental_design_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the experimental_design_name for it
  
    my $expdesign;

    if (defined $name) {
	my ($expdesign_row) = $schema->resultset('GeExperimentalDesign')
	                             ->search({ experimental_design_name => $name });

	unless (defined $expdesign_row) {                

	    cluck("\nDATABASE OUTPUT WARNING: experimental_design_name ($name) for $class->new_by_name() DON'T EXISTS INTO THE DB.\n" );
	    
	    ## If do not exists any experimental design with this name, it will return a warning and it will create an empty
            ## object with the exprimental design name set in it.

	    $expdesign = $class->new($schema);
	    $expdesign->set_experimental_design_name($name);
	}
	else {

	    ## if exists it will take the experimental_design_id to create the object with the new constructor
	    $expdesign = $class->new( $schema, $expdesign_row->get_column('experimental_design_id') ); 
	}
    } 
    else {
	$expdesign = $class->new($schema);                              ### Create an empty object;
    }
   
    return $expdesign;
}



##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_geexpdesign_row, set_geexpdesign_row

  Usage: my $geexpdesign_row = $self->get_geexpdesign_row();
         $self->set_geexpdesign_row($geexpdesign_row_object);

  Desc: Get or set a geexpdesign row object into a experimental
        design object
 
  Ret:   Get => $geexpdesign_row_object, a row object 
                (CXGN::GEM::Schema::GeExperimentalDesign).
         Set => none
 
  Args:  Get => none
         Set => $geexpdesign_row_object, a row object 
                (CXGN::GEM::Schema::GeExperimentalDesign).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $geexpdesign_row = $self->get_geexpdesign_row();
           $self->set_geexpdesign_row($geexpdesign_row);

=cut

sub get_geexpdesign_row {
  my $self = shift;
 
  return $self->{geexpdesign_row}; 
}

sub set_geexpdesign_row {
  my $self = shift;
  my $geexpdesign_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None geexpdesign_row object was supplied for $self->set_geexpdesign_row function.\n");
 
  if (ref($geexpdesign_row) ne 'CXGN::GEM::Schema::GeExperimentalDesign') {
      croak("SET ARGUMENT ERROR: $geexpdesign_row isn't a geexpdesign_row obj. (CXGN::GEM::Schema::GeExperimentalDesign).\n");
  }
  $self->{geexpdesign_row} = $geexpdesign_row;
}



=head2 accessors get_geexpdesignpub_rows, set_geexpdesignpub_rows

  Usage: my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();
         $self->set_geexpdesignpub_rows(\@geexpdesignpub_rows);

  Desc: Get or set a list of geexpdesignpub rows object into an
        experimental design object
 
  Ret:   Get => @geexpdesignpub_row_object, a list of row objects 
                (CXGN::GEM::Schema::GeExperimentalDesignPub).
         Set => none
 
  Args:  Get => none
         Set => \@gexpdesignpub_row_object, an array ref of row objects 
                (CXGN::GEM::Schema::GeExperimentalDesignPub).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();
           $self->set_geexpdesignpub_rows(\@geexpdesignpub_rows);

=cut

sub get_geexpdesignpub_rows {
  my $self = shift;
 
  return @{$self->{geexpdesignpub_rows}}; 
}

sub set_geexpdesignpub_rows {
  my $self = shift;
  my $geexpdesignpub_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None geexpdesignpub_row array ref was supplied for $self->set_geexpdesignpub_rows function.\n");
 
  if (ref($geexpdesignpub_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $geexpdesignpub_row_aref isn't an array reference for $self->set_geexpdesignpub_rows function.\n");
  }
  else {
      foreach my $geexpdesignpub_row (@{$geexpdesignpub_row_aref}) {  
          if (ref($geexpdesignpub_row) ne 'CXGN::GEM::Schema::GeExperimentalDesignPub') {
              croak("SET ARGUMENT ERROR:$geexpdesignpub_row isn't geexpdesignpub_row obj(CXGN::GEM::Schema::GeExperimentalDesignPub).\n");
          }
      }
  }
  $self->{geexpdesignpub_rows} = $geexpdesignpub_row_aref;
}


=head2 accessors get_geexpdesigndbxref_rows, set_geexpdesigndbxref_rows

  Usage: my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
         $self->set_geexpdesigndbxref_rows(\@geexpdesigndbxref_rows);

  Desc: Get or set a list of geexpdesigndbxref rows object into an
        experimental design object
 
  Ret:   Get => @geexpdesigndbxref_row_object, a list of row objects 
                (CXGN::GEM::Schema::GeExperimentalDesignDbxref).
         Set => none
 
  Args:  Get => none
         Set => \@gexpdesigndbxref_row_object, an array ref of row objects 
                (CXGN::GEM::Schema::GeExperimentalDesignDbxref).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
           $self->set_geexpdesigndbxref_rows(\@geexpdesigndbxref_rows);

=cut

sub get_geexpdesigndbxref_rows {
  my $self = shift;
 
  return @{$self->{geexpdesigndbxref_rows}}; 
}

sub set_geexpdesigndbxref_rows {
  my $self = shift;
  my $geexpdesigndbxref_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None geexpdesigndbxref_row array ref was supplied for $self->set_geexpdesigndbxref_rows().\n");
 
  if (ref($geexpdesigndbxref_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $geexpdesigndbxref_row_aref isn't an array reference for $self->set_geexpdesigndbxref_rows function.\n");
  }
  else {
      foreach my $geexpdesigndbxref_row (@{$geexpdesigndbxref_row_aref}) {  
          if (ref($geexpdesigndbxref_row) ne 'CXGN::GEM::Schema::GeExperimentalDesignDbxref') {
              croak("SET ARGUMENT ERROR:$geexpdesigndbxref_row isn't geexpdesigndbxref_row obj.\n");
          }
      }
  }
  $self->{geexpdesigndbxref_rows} = $geexpdesigndbxref_row_aref;
}



##############################################
### DATA ACCESSORS FOR EXPERIMENTAL DESIGN ###
##############################################

=head2 get_experimental_design_id, force_set_experimental_design_id
  
  Usage: my $expdesign_id = $expdesign->get_experimental_design_id();
         $expdesign->force_set_experimental_design_id($expdesign_id);

  Desc: get or set a experimental_design_id in a experimental design object. 
        set method should be USED WITH PRECAUTION
        If you want set a experimental_design_id that do not exists into the 
        database you should consider that when you store this object you 
        CAN STORE a experimental_design_id that do not follow the 
        gem.ge_experimental_design_experimental_design_id_seq

  Ret:  get=> $expdesign_id, a scalar.
        set=> none

  Args: get=> none
        set=> $expdesign_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $expdesign_id = $expdesign->get_experimental_design_id(); 

=cut

sub get_experimental_design_id {
  my $self = shift;
  return $self->get_geexpdesign_row->get_column('experimental_design_id');
}

sub force_set_experimental_design_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None experimental_design_id was supplied for force_set_experimental_design_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The experimental_design_id ($data) for $self->force_set_experimental_design_id() ISN'T AN INTEGER.\n");
  }

  $self->get_geexpdesign_row()
       ->set_column( experimental_design_id => $data );
 
}

=head2 accessors get_experimental_design_name, set_experimental_design_name

  Usage: my $expdesign_name = $expdesign->get_experimental_design_name();
         $expdesign->set_experimental_design_name($expdesign_name);

  Desc: Get or set the experimental_design_name from experimental design object. 

  Ret:  get=> $experimental_design_name, a scalar
        set=> none

  Args: get=> none
        set=> $experimental_design_name, a scalar

  Side_Effects: none

  Example: my $expdesign_name = $sample->get_experimental_design_name();
           $expdesign->set_experimental_design_name($new_name);
=cut

sub get_experimental_design_name {
  my $self = shift;
  return $self->get_geexpdesign_row->get_column('experimental_design_name'); 
}

sub set_experimental_design_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_experimental_design_name function.\n");

  $self->get_geexpdesign_row()
       ->set_column( experimental_design_name => $data );
}

=head2 accessors get_design_type, set_design_type

  Usage: my $expdesign_type = $expdesign->get_design_type();
         $expdesign->set_design_type($expdesign_type);
 
  Desc: Get or set design_type from a experimental design object. 
 
  Ret:  get=> $expdesign_type, a scalar
        set=> none
 
  Args: get=> none
        set=> $expdesign_type, a scalar
 
  Side_Effects: none
 
  Example: my $expdesign_type = $expdesign->get_design_type();

=cut

sub get_design_type {
  my $self = shift;
  return $self->get_geexpdesign_row->get_column('design_type'); 
}

sub set_design_type {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_design_type function.\n");

  $self->get_geexpdesign_row()
       ->set_column( design_type => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $expdesign->get_description();
         $expdesign->set_description($description);

  Desc: Get or set the description from an experimental design object 

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: none

  Example: my $description = $expdesign->get_description();
           $expdesign->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_geexpdesign_row->get_column('description'); 
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_geexpdesign_row()
       ->set_column( description => $data );
}


###################################################
### DATA ACCESSORS FOR EXPERIMENTAL DESIGN PUBS ###
###################################################

=head2 add_publication

  Usage: $expdesign->add_publication($pub_id);

  Desc: Add a publication to the pub_ids associated to experimental design 
        object using different arguments as pub_id, title or dbxref_accession 

  Ret:  None

  Args: $pub_id, a publication id. 
        To use with $pub_id: 
          $expdesign->add_publication($pub_id);
        To use with $pub_title
          $expdesign->add_publication({ title => $pub_title } );
        To use with pubmed accession
          $expdesign->add_publication({ dbxref_accession => $accesssion});
          
  Side_Effects: die if the parameter is not an object

  Example: $expdesign->add_publication($pub_id);

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
    my $expdesignpub_row = $self->get_schema()
                                ->resultset('GeExperimentalDesignPub')
                                ->new({ pub_id => $pub_id});
    
    if (defined $self->get_experimental_design_id() ) {
        $expdesignpub_row->set_column( experimental_design_id => $self->get_experimental_design_id() );
    }

    my @expdesignpub_rows = $self->get_geexpdesignpub_rows();
    push @expdesignpub_rows, $expdesignpub_row;
    $self->set_geexpdesignpub_rows(\@expdesignpub_rows);
}

=head2 get_publication_list

  Usage: my @pub_list = $expdesign->get_publication_list();

  Desc: Get a list of publications associated to this experimental design.

  Ret: An array of pub_ids by default, but can be titles
       or accessions using an argument 'title' or 'dbxref.accession'

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @pub_id_list = $expdesign->get_publication_list();
           my @pub_title_list = $expdesign->get_publication_list('title');
           my @pub_title_accs = $expdesign->get_publication_list('dbxref.accession');


=cut

sub get_publication_list {
    my $self = shift;
    my $field = shift;

    my @pub_list = ();

    my @expdesignpub_rows = $self->get_geexpdesignpub_rows();
    foreach my $expdesignpub_row (@expdesignpub_rows) {
        my $pub_id = $expdesignpub_row->get_column('pub_id');
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


#####################################################
### DATA ACCESSORS FOR EXPERIMENTAL DESIGN DBXREF ###
#####################################################

=head2 add_dbxref

  Usage: $expdesign->add_dbxref($dbxref_id);

  Desc: Add a dbxref to the dbxref_ids associated to experimental design 
        object using dbxref_id or accesion + database_name 

  Ret:  None

  Args: $dbxref_id, a dbxref id. 
        To use with accession and dbxname:
          $expdesign->add_dbxref( 
                                   { 
                                      accession => $accesssion,
                                      dbxname   => $dbxname,
                                   }
                                );
          
  Side_Effects: die if the parameter is not an hash reference

  Example: $expdesign->add_dbxref($dbxref_id);
           $expdesign->add_dbxref( 
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

    my $expdesigndbxref_row = $self->get_schema()
                                   ->resultset('GeExperimentalDesignDbxref')
                                   ->new({ dbxref_id => $dbxref_id});
    
    if (defined $self->get_experimental_design_id() ) {
        $expdesigndbxref_row->set_column( experimental_design_id => $self->get_experimental_design_id() );
    }

    my @expdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
    push @expdesigndbxref_rows, $expdesigndbxref_row;
    $self->set_geexpdesigndbxref_rows(\@expdesigndbxref_rows);
}

=head2 get_dbxref_list

  Usage: my @dbxref_id_list = $expdesign->get_dbxref_list();

  Desc: Get a list of dbxref_id associated to this experimental design.

  Ret: An array of dbxref_id

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @dbxref_id_list = $expdesign->get_dbxref_list();

=cut

sub get_dbxref_list {
    my $self = shift;

    my @dbxref_list = ();

    my @expdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
    foreach my $expdesigndbxref_row (@expdesigndbxref_rows) {
        my $dbxref_id = $expdesigndbxref_row->get_column('dbxref_id');
	push @dbxref_list, $dbxref_id;
    }
    
    return @dbxref_list;                  
}


#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_experimental_design_metadbdata

  Usage: my $metadbdata = $expdesign->get_experimental_design_metadbdata();

  Desc: Get metadata object associated to experimental design data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $sample->get_experimental_design_metadbdata();
           my $metadbdata = 
              $sample->get_experimental_design_metadbdata($metadbdata);

=cut

sub get_experimental_design_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_geexpdesign_row
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
      my $experimental_design_id = $self->get_experimental_design_id();
      if (defined $experimental_design_id) {
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the experimental_design_id=$experimental_design_id is undefined.\n");
      }
      else {
	  croak("OBJECT MANAGEMENT ERROR: Object haven't defined any experimental_design_id. Probably it hasn't been stored yet.\n");
      }
  }
  
  return $metadbdata;
}

=head2 is_experimental_design_obsolete

  Usage: $expdesign->is_experimental_design_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($expdesign->is_experimental_design_obsolete()) { 
                   ## do something 
           }

=cut

sub is_experimental_design_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_experimental_design_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}


=head2 accessors get_experimental_design_pub_metadbdata

  Usage: my %metadbdata = $expdesign->get_experimental_design_pub_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=pub_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata) for pub relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $expdesign->get_experimental_design_pub_metadbdata();
           my %metadbdata = 
                 $expdesign->get_experimental_design_pub_metadbdata($metadbdata);

=cut

sub get_experimental_design_pub_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();

  foreach my $geexpdesignpub_row (@geexpdesignpub_rows) {
      my $pub_id = $geexpdesignpub_row->get_column('pub_id');
      my $metadata_id = $geexpdesignpub_row->get_column('metadata_id');

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
          my $expdesign_pub_id = $geexpdesignpub_row->get_column('experimental_design_pub_id');
	  unless (defined $expdesign_pub_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any experimental_design_pub_id. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: The metadata_id for the experimental_design_pub_id=$expdesign_pub_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_experimental_design_pub_obsolete

  Usage: $expdesign->is_experimental_design_pub_obsolete($pub_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $pub_id, a publication_id
  
  Side_Effects: none
  
  Example: unless ( $expdesign->is_experimental_design_pub_obsolete($pub_id) ) {
                ## do something 
           }

=cut

sub is_experimental_design_pub_obsolete {
  my $self = shift;
  my $pub_id = shift;

  my %metadbdata = $self->get_experimental_design_pub_metadbdata();
  my $metadbdata = $metadbdata{$pub_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}


=head2 accessors get_experimental_design_dbxref_metadbdata

  Usage: my %metadbdata = 
            $expdesign->get_experimental_design_dbxref_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=dbxref_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata) for pub relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = 
              $expdesign->get_experimental_design_dbxref_metadbdata();
           my %metadbdata = 
              $expdesign->get_experimental_design_dbxref_metadbdata($metadbdata);

=cut

sub get_experimental_design_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();

  foreach my $geexpdesigndbxref_row (@geexpdesigndbxref_rows) {
      my $dbxref_id = $geexpdesigndbxref_row->get_column('dbxref_id');
      my $metadata_id = $geexpdesigndbxref_row->get_column('metadata_id');

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
          my $expdesign_dbxref_id = $geexpdesigndbxref_row->get_column('experimental_design_dbxref_id');
	  unless (defined $expdesign_dbxref_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any experimental_design_dbxref_id.Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for the experimental_design_dbxref_id=$expdesign_dbxref_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_experimental_design_dbxref_obsolete

  Usage: $expdesign->is_experimental_design_dbxref_obsolete($dbxref_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $dbxref_id, a dbxref_id
  
  Side_Effects: none
  
  Example: unless ($expdesign->is_experimental_design_dbxref_obsolete($dbxref_id)){
                ## do something 
           }

=cut

sub is_experimental_design_dbxref_obsolete {
  my $self = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_experimental_design_dbxref_metadbdata();
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

  Usage: $expdesign->store($metadbdata);
 
  Desc: Store in the database the all experimental design data for the 
        experimental design object.
        See the methods store_experimental_design, store_pub_associations
        and store_dbxref_associations for more details

  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $expdesign->store($metadata);

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

    $self->store_experimental_design($metadata);
    $self->store_pub_associations($metadata);
    $self->store_dbxref_associations($metadata);
}



=head2 store_experimental_design

  Usage: $expdesign->store_experimental_design($metadata);
 
  Desc: Store in the database the experimental data for the experimental
        design object (Only the geexpdesign row, don't store any 
        experimental_design_pub or experimental_design_dbxref data)
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $expdesign->store_experimental_design($metadata);

=cut

sub store_experimental_design {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_experimental_design().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_experimental_design() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not experimental_design_id. 
    ##   if exists experimental_design_id         => update
    ##   if do not exists experimental_design_id  => insert

    my $geexpdesign_row = $self->get_geexpdesign_row();
    my $expdesign_id = $geexpdesign_row->get_column('experimental_design_id');

    unless (defined $expdesign_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$geexpdesign_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$geexpdesign_row->insert()
                        ->discard_changes();                           ## It will set the row with the updated row
	
	## Now we set the experimental_design_id value for all the rows that depends of it

	my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();
	foreach my $geexpdesignpub_row (@geexpdesignpub_rows) {
	    $geexpdesignpub_row->set_column( experimental_design_id => $geexpdesign_row->get_column('experimental_design_id'));
	}
	
	my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
	foreach my $geexpdesigndbxref_row (@geexpdesigndbxref_rows) {
	    $geexpdesigndbxref_row->set_column( experimental_design_id => $geexpdesign_row->get_column('experimental_design_id'));
	}

	          
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $geexpdesign_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_experimental_design_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $geexpdesign_row->set_column( metadata_id => $mod_metadata_id );

	    $geexpdesign_row->update()
                            ->discard_changes();
	}
    }
}


=head2 obsolete_experimental_design

  Usage: $expdesign->obsolete_experimental_design($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $expdesign->obsolete_experimental_design($metadata, 'change to obsolete test');

=cut

sub obsolete_experimental_design {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_experimental_design().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied to $self->obsolete_experimental_design isn't CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_experimental_design().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_experimental_design_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $geexpdesign_row = $self->get_geexpdesign_row();

    $geexpdesign_row->set_column( metadata_id => $mod_metadata_id );
         
    $geexpdesign_row->update()
	            ->discard_changes();
}


=head2 store_pub_associations

  Usage: $expdesign->store_pub_associations($metadata);
 
  Desc: Store in the database the pub association for the experimental design 
        object
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $expdesign->store_pub_associations($metadata);

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

    ## SECOND, check if exists or not experimental_design_pub_id. 
    ##   if exists experimental_design_pub_id         => update
    ##   if do not exists experimental_design_pub_id  => insert

    my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();
    
    foreach my $geexpdesignpub_row (@geexpdesignpub_rows) {
        
        my $expdesign_pub_id = $geexpdesignpub_row->get_column('experimental_design_pub_id');
	my $pub_id = $geexpdesignpub_row->get_column('pub_id');

        unless (defined $expdesign_pub_id) {                                ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $geexpdesignpub_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $geexpdesignpub_row->insert()
                               ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                 ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $geexpdesignpub_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %aspub_metadata = $self->get_experimental_design_pub_metadbdata($metadata);
		my $mod_metadata_id = $aspub_metadata{$pub_id}->store({ modification_note => $modification_note })
                                                              ->get_metadata_id(); 

                $geexpdesignpub_row->set_column( metadata_id => $mod_metadata_id );

                $geexpdesignpub_row->update()
                                   ->discard_changes();
            }
        }
    }
}

=head2 obsolete_pub_association

  Usage: $expdesign->obsolete_pub_association($metadata, $note, $pub_id, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: None
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $pub_id, a publication id associated to this tool
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: $expdesign->obsolete_pub_association($metadata, 
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
    
    my %aspub_metadata = $self->get_experimental_design_pub_metadbdata($metadata);
    my $mod_metadata_id = $aspub_metadata{$pub_id}->store( { modification_note => $modification_note,
							     obsolete          => $obsolete, 
							     obsolete_note     => $obsolete_note } )
                                                  ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @geexpdesignpub_rows = $self->get_geexpdesignpub_rows();
    foreach my $geexpdesignpub_row (@geexpdesignpub_rows) {
	if ($geexpdesignpub_row->get_column('pub_id') == $pub_id) {

	    $geexpdesignpub_row->set_column( metadata_id => $mod_metadata_id );
         
	    $geexpdesignpub_row->update()
	                       ->discard_changes();
	}
    }
}


=head2 store_dbxref_associations

  Usage: $expdesign->store_dbxref_associations($metadata);
 
  Desc: Store in the database the dbxref association for the experimental design 
        object
 
  Ret: None
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: $expdesign->store_dbxref_associations($metadata);

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

    ## SECOND, check if exists or not experimental_design_dbxref_id. 
    ##   if exists experimental_design_dbxref_id         => update
    ##   if do not exists experimental_design_dbxref_id  => insert

    my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
    
    foreach my $geexpdesigndbxref_row (@geexpdesigndbxref_rows) {
        
        my $expdesign_dbxref_id = $geexpdesigndbxref_row->get_column('experimental_design_dbxref_id');
	my $dbxref_id = $geexpdesigndbxref_row->get_column('dbxref_id');

        unless (defined $expdesign_dbxref_id) {                                ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $geexpdesigndbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $geexpdesigndbxref_row->insert()
                                  ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                    ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $geexpdesigndbxref_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %asdbxref_metadata = $self->get_experimental_design_dbxref_metadbdata($metadata);
		my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store({ modification_note => $modification_note })
                                                                    ->get_metadata_id(); 

                $geexpdesigndbxref_row->set_column( metadata_id => $mod_metadata_id );

                $geexpdesigndbxref_row->update()
                                   ->discard_changes();
            }
        }
    }
}

=head2 obsolete_dbxref_association

  Usage: $expdesign->obsolete_dbxref_association($metadata, $note, $dbxref_id, 'REVERT');
 
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
  
  Example: $expdesign->obsolete_dbxref_association($metadata, 
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
    
    my %asdbxref_metadata = $self->get_experimental_design_dbxref_metadbdata($metadata);
    my $mod_metadata_id = $asdbxref_metadata{$dbxref_id}->store( { modification_note => $modification_note,
						     	           obsolete          => $obsolete, 
							           obsolete_note     => $obsolete_note } )
                                                        ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @geexpdesigndbxref_rows = $self->get_geexpdesigndbxref_rows();
    foreach my $geexpdesigndbxref_row (@geexpdesigndbxref_rows) {
	if ($geexpdesigndbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $geexpdesigndbxref_row->set_column( metadata_id => $mod_metadata_id );
         
	    $geexpdesigndbxref_row->update()
	                          ->discard_changes();
	}
    }
}

#####################
### OTHER METHODS ###
#####################


=head2 get_experiment_list

  Usage: my @experiments = $expdesign->get_experiment_list();
  
  Desc: Get a list of CXGN::GEM::Experiment objects.
  
  Ret:  An array with a list of CXGN::GEM::Experiment objects.
  
  Args: none
  
  Side_Effects: die if the experiment_design_object have not any 
                experimental_design_id
  
  Example: my @experiments = $expdesign->get_experiment_list();

=cut

sub get_experiment_list {
   my $self = shift;

   my @experiments = ();

   my $experimental_design_id = $self->get_experimental_design_id();

   unless (defined $experimental_design_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experimental_design_id. Probably it hasn't store yet.\n");
   }
  
   my @exp_rows = $self->get_schema()
                       ->resultset('GeExperiment')
   		       ->search( { experimental_design_id => $experimental_design_id } );

   foreach my $exp_row (@exp_rows) {
       my $experiment = CXGN::GEM::Experiment->new($self->get_schema(), $exp_row->get_column('experiment_id'));
      
       push @experiments, $experiment;
   }
   
   return @experiments;
}


=head2 get_po_sorted_experiment_list

  Usage: my @experiments = $expdesign->get_po_sorted_experiment_list();
  
  Desc: Get a list of CXGN::GEM::Experiment objects, ordered by its PO
  
  Ret:  An array with a list of CXGN::GEM::Experiment objects.
  
  Args: none
  
  Side_Effects: die if the experiment_design_object have not any 
                experimental_design_id
  
  Example: my @experiments = $expdesign->get_experiment_list();

=cut

sub get_po_sorted_experiment_list {
   my $self = shift;

   my @experiments_sorted = ();
   my @experiments = $self->get_experiment_list();

   ## Define the PO Root accessions (they will be used to define the 
   ## shortest path and to sepparate PO in structure or develop based
   ## in its path)
 
   my $po_structure_root = 'PO:0009011';
   my $po_development_root = 'PO:0009012';
   
   ## First, transfer the PO annotations from sample to experiments

   ## Define the hash that will contain the paths
 
   my %experiment_objs = ();
   my %default_experiment_objs = ();
   my %exp_structure_popath = ();
   my %exp_develop_popath = ();
   my %str_popath_count = ();
   my %dev_popath_count = ();

   foreach my $exp (@experiments) {
       
       my %exp_po = ();
       my @targets = $exp->get_target_list();
       my $experiment_id = $exp->get_experiment_id();
       
       ## Store the experiment objects in a hash with key=experiment_id
       ## to access to them faster after the order

       my $exp_name = $exp->get_experiment_name();
       $experiment_objs{$experiment_id} = $exp;

       ## Store the names to sort alphabetically by default if none dbxref is associated 
       ## with the experiments of this expdesign
       $default_experiment_objs{$exp_name} = $exp;


       foreach my $target (@targets) {
	   
	   my $target_name = $target->get_target_name();
	   my @samples = $target->get_sample_list();
	   
	   foreach my $sample (@samples) {
	       
	       my $sample_name = $sample->get_sample_name();
	       my %dbxref_po = $sample->get_dbxref_related('PO');
	       
	       foreach my $dbxref_id (keys %dbxref_po) {
		   unless (exists $exp_po{$dbxref_id}) {
		       $exp_po{$dbxref_id} = $dbxref_po{$dbxref_id}; 
		   }
	       }
	   }
       }
       
       ## Now it will take the path as PO:XXXXXXXX from each cvterm (PO)
       ## (It will use PO:XXXXXX instead cvterm_id to be able to have the same
       ## order independently from the cvterm load in the database).
       ## The last element will be always the cvterm.name, so after the path
       ## it will be orther by name

       foreach my $dbxrefid (keys %exp_po) {

	   ## Define the path

	   my @path;

	   my $cvterm_id = $exp_po{$dbxrefid}->{'cvterm.cvterm_id'};
	   my $complete_accession = $exp_po{$dbxrefid}->{'db.name'} . ':' . $exp_po{$dbxrefid}->{'dbxref.accession'};

	   ## Last element in the path (first element to be added) will be the cvterm.name

	   push @path, $exp_po{$dbxrefid}->{'cvterm.name'};

	   ## It will take the path for that cvterm (only parents... so pathdistance > 0)

	   my @cvtermpath_rows = $self->get_schema()
	                              ->resultset('Cv::Cvtermpath')
				      ->search(
	                                        { subject_id => $cvterm_id, pathdistance => { '>', 0 }  },
				                { order_by => 'pathdistance',  }
				              );

	   ## This will get all the path for this cvterm, they are redundant so
	   ## it will remove this redundancy using a hash

	   my %parent_po_terms = ();

	   foreach my $cvtermpath_row (@cvtermpath_rows) {
	       
	       my $parent_cvterm_id = $cvtermpath_row->get_column('object_id');
	       my $parent_distance = $cvtermpath_row->get_column('pathdistance');

	       my ($parent_cvterm_row) = $self->get_schema()
		                              ->resultset('Cv::Cvterm')
		                              ->search({'cvterm_id' => $parent_cvterm_id});

	       my ($dbxref_row) = $self->get_schema()
	                                      ->resultset('General::Dbxref')
		 		              ->search({'dbxref_id' => $parent_cvterm_row->get_column('dbxref_id')});

	       my ($db_row) = $self->get_schema()
	                           ->resultset('General::Db')
		  	           ->search({'db_id' => $dbxref_row->get_column('db_id')});
	       
	       ## Now it will add the po_terms from closest to farest... in the array the first element will be the root
	       ## (the farest parent po term)

	       if (defined $dbxref_row && defined $db_row) {

		   my $po_term = $db_row->get_column('name') . ':' . $dbxref_row->get_column('accession');
		   unless (exists $parent_po_terms{$po_term}) {
		       
                       ## The last po_term added should be the roots 'PO:0009011' or 'PO:0009012'
		       
		       my $last = 0;
		       if (defined $path[0]) {
			   if ($path[0] eq $po_structure_root) {
			       $last = 1;
			   }
			   elsif ($path[0] eq $po_development_root) {
			       $last = 1;
			   }
		       }

		       if ($last == 0) {
			   unshift @path, $po_term;
		       }
		       
		       $parent_po_terms{$po_term} = $parent_distance;
		   }
	       }
	   }
	   
	   ## Now it will add the path to two different hashes, po_structure and po_development, corresponding with the two
	   ## different roots for po terms ()

	   ## Each parent-root will be $path[0]
	   ## Define the po_path, and store the count for each po_path. Later, if some po_path_count (by structure) > 0
	   ## it will take a secondary order (by development)
	   	   
	   my $po_path = join(',', @path);
	   
	   if ($path[0] eq $po_structure_root) { ## That means 'plant structure'
	       unless (exists $exp_structure_popath{$experiment_id}) {
		   $exp_structure_popath{$experiment_id} = $po_path;
		   unless (exists $str_popath_count{$po_path}) {
		       $str_popath_count{$po_path} = 1;
		   }
		   else {
		       $str_popath_count{$po_path}++;
		   }
	       }
	   }
	   elsif ($path[0] eq $po_development_root) { ## That means 'plant growth and development stages'
	       unless (exists $exp_develop_popath{$experiment_id}) {
		   $exp_develop_popath{$experiment_id} = $po_path;
		   unless (exists $dev_popath_count{$po_path}) {
		       $dev_popath_count{$po_path} = 1;
		   }
		   else {
		       $dev_popath_count{$po_path}++;
		   }
	       }
	   }
       }
   }
   
   ## Now it will take all the experiments from the object

   my %exp_combined_po;

   foreach my $exp_id (keys %experiment_objs) {
       my $exp_str_po = $exp_structure_popath{$exp_id} || 'Z';
       my $exp_dev_po = $exp_develop_popath{$exp_id} || 'Z';
       
       $exp_combined_po{$exp_id} = $exp_str_po . '-' . $exp_dev_po . '-' . $experiment_objs{$exp_id}->get_experiment_name();
   }

   ## Finally it will be sorted by the values in the exp_combined_po... if there are some dbxref associated with these
   ## experiments, if not, return a list sorted by default by alphabetical name

   if (scalar(keys %exp_structure_popath) > 0 && scalar(keys %exp_develop_popath) > 0) {
       foreach my $sort_exp_id (sort {$exp_combined_po{$a} cmp $exp_combined_po{$b}} keys %exp_combined_po) {
	   push @experiments_sorted, $experiment_objs{$sort_exp_id};
       }
   }
   else {
       foreach my $experim_name (sort keys %default_experiment_objs) {
	   push @experiments_sorted, $default_experiment_objs{$experim_name};
       }
   }
   
   return @experiments_sorted;
}

=head2 get_target_list

  Usage: my @targets = $expdesign->get_target_list();
  
  Desc: Get a list of CXGN::GEM::Target objects.
  
  Ret:  An array with a list of CXGN::GEM::Target objects.
  
  Args: none
  
  Side_Effects: die if the experiment_design_object have not any 
                experimental_design_id
  
  Example: my @targets = $expdesign->get_target_list();

=cut

sub get_target_list {
   my $self = shift;

   my @targets = ();

   my $experimental_design_id = $self->get_experimental_design_id();

   unless (defined $experimental_design_id) {
       croak("OBJECT MANIPULATION ERROR: The $self object haven't any experimental_design_id. Probably it hasn't store yet.\n");
   }
  
   my @exp_rows = $self->get_schema()
                       ->resultset('GeExperiment')
   		       ->search( { experimental_design_id => $experimental_design_id } );

   foreach my $exp_row (@exp_rows) {
       my $experiment_id = $exp_row->get_column('experiment_id');

       my @target_rows = $self->get_schema()
                       ->resultset('GeTarget')
   		       ->search( { experiment_id => $experiment_id } );
       
       foreach my $target_row (@target_rows) {
	   my $target = CXGN::GEM::Target->new($self->get_schema(), $target_row->get_column('target_id') );

	   push @targets, $target;
       }
   }
   
   return @targets;
}








####
1;##
####
