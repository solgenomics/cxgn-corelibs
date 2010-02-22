
package CXGN::Biosource::Sample;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use Bio::Chado::Schema;
use CXGN::Biosource::Schema;
use CXGN::Biosource::Protocol;
use CXGN::Metadata::Metadbdata;

use Carp qw| croak cluck |;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Biosource::Sample
a class to manipulate a sample data from the biosource schema.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use CXGN::Biosource::Sample;

  ## Constructor

  my $sample = CXGN::Biosource::Sample->new($schema, $sample_id);

  ## Basic Accessors

  my $sample_name = $sample->get_sample_name();
  $sample->set_sample_type($new_type);

  ## Extended accessors

  $sample->add_sample_element(
                                {
                                  sample_element_name => 'Nt_Root',
                                  description         => 'Tobacco root ...',
                                  organism_name       => 'Nicotiana tabacum',
                                  protocol_name       => 'Root mRNA extraction',
                                }
                             );

  $sample->add_publication($pub_id);
  $sample->add_dbxref_to_sample_element($step, $dbxref_id);
  $sample->add_dbxref_to_sample_element($step, $cvterm_id);

  my %sample_elements = $sample->get_sample_elements();
  my $element_description = $sample_element{'Nt_Root'}->{description};

  my @pub_list = $sample->get_publication_list();

  my %sample_element_dbxref = $sample->get_dbxref_from_sample_element();
  my @element_dbxrefs = @{$sample_element_dbxref{'Nt_Root'}};

  ## Store function

  $sample->store($metadbdata);

  ## Obsolete functions

  unless ($sample->is_element_dbxref_obsolete('Nt_Root', $dbxref_id) ) {
    $sample->obsolete_element_dbxref_association( $metadbdata,
                                                  $note,
                                                  'Nt_Root',
                                                   $dbxref_id );
  }
 


=head1 DESCRIPTION

 This object manage the protocol information of the database
 from the tables:
  
   + biosource.bs_sample
   + biosource.bs_sample_pub
   + biosource.bs_sample_element
   + biosource.bs_sample_element_dbxref
   + biosource.bs_sample_element_cvterm
   + biosource.bs_sample_element_file
   + biosource.bs_sample_element_relation

 This data is stored inside this object as dbic rows objects with the 
 following structure:

  %Sample_Object = ( 
    
       bs_sample_row    => BsSample_row, 
                     
       bs_samplepub_row => [ @BsSamplePub_rows ], 
 
       bs_sampleelement_row => { 

             $sample_element_name => BsSampleElement_row,

                               }

       bs_sampleelelementdbxref_row => {

             $sample_element_name => [ @BsSampleElementDbxref_rows ],

                                       }

       bs_sampleelelementcvterm_row => {

             $sample_element_name => [ @BsSampleElementCvterm_rows ],

                                       }

      bs_sampleelelementfile_row => {

             $sample_element_name => [ @BsSampleElementFile_rows ],

                                       }

      bs_sampleelelementrelation_source_row => {

             $sample_element_name => [ @BsSampleElementRelation_rows ],

                                       }
      bs_sampleelelementrelation_result_row => {

             $sample_element_name => [ @BsSampleElementRelation_rows ],

                                       }

    
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

  Usage: my $sample = CXGN::Biosource::Sample->new($schema, $sample_id);

  Desc: Create a new Sample object

  Ret: a CXGN::Biosource::Sample object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        A $sample_id, a scalar.
        If $sample_id is omitted, an empty sample object is created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $sample = CXGN::Biosource::Sample->new($schema, $sample_id);

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

    my $sample;
    my @sample_pubs = (); 
    my %sample_elements = ();
    my %sample_element_dbxrefs = ();
    my %sample_element_cvterms = ();
    my %sample_element_files = ();
    my %sample_element_source_relations = ();    
    my %sample_element_result_relations = ();  

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The sample_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}

	## Get the bs_sample_row object using a search based in the sample_id 

	($sample) = $schema->resultset('BsSample')
   	                   ->search( { sample_id => $id } );
	
	## Search sample_pub associations (bs_sample_pub_row objects) based in the sample_id

	@sample_pubs = $schema->resultset('BsSamplePub')
	                      ->search( { sample_id => $id } );
       
	## Search the sample_elements (bs_sample_element_rows objects) based in the sample_id

	my @sample_element_rows = $schema->resultset('BsSampleElement')
	                                 ->search( { sample_id => $id } ); 

	foreach my $sample_element_row (@sample_element_rows) {
	    my $sample_element_name = $sample_element_row->get_column('sample_element_name');
	    my $sample_element_id = $sample_element_row->get_column('sample_element_id');

	    unless (defined $sample_element_name) {
		croak("DATABASE COHERENCE ERROR: sample_element_id=$sample_element_id has undefined value for sample_element_name.\n");
	    }
	    else {
		unless (exists $sample_elements{$sample_element_name}) {
		    $sample_elements{$sample_element_name} = $sample_element_row;

		    ## If is defined a sample element can be defined all the elements related with it as dbxref or cvterm 

		    my $element_dbxref_rs = $schema->resultset('BsSampleElementDbxref')
	 		                           ->search({ sample_element_id => $sample_element_id });
       
		    ## If the count return more than zero get all the rows and put as array ref inside the object

		    if ($element_dbxref_rs->count() > 0) {
			my @element_dbxref_rows = $element_dbxref_rs->all();
			$sample_element_dbxrefs{$sample_element_name} = \@element_dbxref_rows;
		    }

		    ## It will the same thing for cvterms
		    
		     my $element_cvterm_rs = $schema->resultset('BsSampleElementCvterm')
	 		                            ->search({ sample_element_id => $sample_element_id });

		    if ($element_cvterm_rs->count() > 0) {
			my @element_cvterm_rows = $element_cvterm_rs->all();
			$sample_element_cvterms{$sample_element_name} = \@element_cvterm_rows;
		    }

		    ## And with files

		    my $element_file_rs = $schema->resultset('BsSampleElementFile')
	 		                            ->search({ sample_element_id => $sample_element_id });

		    if ($element_file_rs->count() > 0) {
			my @element_file_rows = $element_file_rs->all();
			$sample_element_files{$sample_element_name} = \@element_file_rows;
		    }

		    ## And with relations

		    my $element_relation_source_rs = $schema->resultset('BsSampleElementRelation')
			                                    ->search({ sample_element_id_a => $sample_element_id });

		    if ($element_relation_source_rs->count() > 0) {
			my @element_relation_source_rows = $element_relation_source_rs->all();
			$sample_element_source_relations{$sample_element_name} = \@element_relation_source_rows;
		    }
		    
		    my $element_relation_result_rs = $schema->resultset('BsSampleElementRelation')
			                                    ->search({ sample_element_id_b => $sample_element_id });

		    if ($element_relation_result_rs->count() > 0) {
			my @element_relation_result_rows = $element_relation_result_rs->all();
			$sample_element_result_relations{$sample_element_name} = \@element_relation_result_rows;
		    }

		    
		    

		}
		else {

		    ## Die if there are more than two sample elements with the same name for the same sample_id
		    
		    my $a = $sample_elements{$sample_element_name}->get_column('sample_element_id') . ' and ' . $sample_element_id;
		    croak("DATABASE COHERENCE ERROR:There are more than one sample_element_id ($a) with the same sample_element_name.\n");
		}
	    }
	}

	unless (defined $sample) {  ## If dbiref_id don't exists into the  db, it will warning with cluck and create an empty object
                
	    cluck("\nDATABASE WARNING: Sample_id ($id) for $class->new() DON'T EXISTS INTO THE DB.\nIt'll be created an empty obj.\n" );
	    
	    $sample = $schema->resultset('BsSample')
		             ->new({});
	}
    } 
    else {
	$sample = $schema->resultset('BsSample')
	                 ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_bssample_row($sample);
    $self->set_bssamplepub_rows(\@sample_pubs);
    $self->set_bssampleelement_rows(\%sample_elements);
    $self->set_bssampleelementdbxref_rows(\%sample_element_dbxrefs);
    $self->set_bssampleelementcvterm_rows(\%sample_element_cvterms);   
    $self->set_bssampleelementfile_rows(\%sample_element_files);  
    $self->set_bssampleelementrelation_source_rows(\%sample_element_source_relations);  
    $self->set_bssampleelementrelation_result_rows(\%sample_element_result_relations); 

    return $self;
}

=head2 constructor new_by_name

  Usage: my $sample = CXGN::Biosource::Sample->new_by_name($schema, $sample_name);
 
  Desc: Create a new Sample object using sample_name
 
  Ret: a CXGN::Biosource::Sample object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $sample_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the protocol name do not exists into the db
 
  Example: my $sample = CXGN::Biosource::Sample->new_by_name( $schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the protocol_id for this name and it will get the protocol_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the protocol_name for it
  
    my $sample;

    if (defined $name) {
	my ($sample_row) = $schema->resultset('BsSample')
	                          ->search({ sample_name => $name });

	unless (defined $sample_row) {                

	    cluck("\nDATABASE WARNING: sample_name ($name) for $class->new() DON'T EXISTS INTO THE DB.\n" );
	    
	    ## If do not exists any sample with this sample name, it will return a warning and it will create an empty
            ## object with the sample name set in it.

	    $sample = $class->new($schema);
	    $sample->set_sample_name($name);
	}
	else {
	    $sample = $class->new( $schema, $sample_row->get_column('sample_id') ); ## if exists it will take the sample_id to create
                                                                                    ## the object with the new constructor
	}
    } 
    else {
	$sample = $class->new($schema);                              ### Create an empty object;
    }
   
    return $sample;
}

=head2 constructor new_by_elements

  Usage: my $sample = CXGN::Biosource::Sample->new_by_elements($schema, 
                                                               \@sampleelements);
 
  Desc: Create a new Sample object using a list of a sample_elements_names
 
  Ret: a CXGN::Biosource::Sample object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a \@sample_elements, an array reference with a list of sample element 
        names
 
  Side_Effects: accesses the database,
                return a warning if the protocol name do not exists into the db
 
  Example: my $sample = CXGN::Biosource::Sample->new_by_elements( $schema, 
                                                                  [$e1, $e2]);

=cut

sub new_by_elements {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $elements_aref = shift;

    ### It will search the sample_id for the list of these elements. If find a sample_id it will create a new object with it.
    ### if not, it will create an empty object and it will add all the elements over the empty object using the add_element_by_name
    ### function (it will search a element in the database and it will add it to the sample)
  
    my $sample;

    if (defined $elements_aref) {
	if (ref($elements_aref) ne 'ARRAY') {
	    croak("PARAMETER ERROR: The element array reference supplied to $class->new_by_elements() method IS NOT AN ARRAY REF.\n");
	}
	else {
	    my $elements_n = scalar(@{$elements_aref});

	    ## Dbix::Class search to get an id in a group using the elements of the group

	    my @bssample_element_rows = $schema->resultset('BsSampleElement')
                                               ->search( undef,
                                                          { 
                                                            columns  => ['sample_id'],
                                                            where    => { sample_element_name => { -in  => $elements_aref } },
							    group_by => [ qw/sample_id/ ], 
							    having   => { 'count(sample_element_id)' => { '=', $elements_n } } 
                                                          }          
                                                        );
	    ## This search will return all the platform_design that contains the elements specified, it will filter 
            ## by the number of element to take only the rows where have all these elements

            my $bssample_element_row;
            foreach my $row (@bssample_element_rows) {
                my $count = $schema->resultset('BsSampleElement')
                                   ->search( sample_id => $row->get_column('sample_id') )
                                   ->count();
                if ($count == $elements_n) {
                    $bssample_element_row = $row;
                }
            }



	    unless (defined $bssample_element_row) {    
		
		## If sample_id don't exists into the  db, it will warning with cluck and create an empty object
		
		cluck("DATABASE COHERENCE ERROR: Elements specified haven't a Sample. It'll be created a sample without sample_id.\n"); 
		
		$sample = $class->new($schema);
            
		foreach my $element_name (@{$elements_aref}) {
		    $sample->add_element_by_name($element_name);
		}
	    }
	    else {
            
		$sample = $class->new( $schema, $bssample_element_row->get_column('sample_id') );
	    }
	}
	
    }
    else {
	    $sample = $class->new($schema);                              ### Create an empty object;
    }

    return $sample;
}


##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_bssample_row, set_bssample_row

  Usage: my $bssample_row = $self->get_bssample_row();
         $self->set_bssample_row($bssample_row_object);

  Desc: Get or set a bssample row object into a sample object
 
  Ret:   Get => $bssample_row_object, a row object 
                (CXGN::Biosource::Schema::BsSample).
         Set => none
 
  Args:  Get => none
         Set => $bssample_row_object, a row object 
                (CXGN::Biosource::Schema::BsSample).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $bssample_row = $self->get_bssample_row();
           $self->set_bssample_row($bssample_row);

=cut

sub get_bssample_row {
  my $self = shift;
 
  return $self->{bssample_row}; 
}

sub set_bssample_row {
  my $self = shift;
  my $bssample_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssample_row object was supplied for $self->set_bsprotocol_row function.\n");
 
  if (ref($bssample_row) ne 'CXGN::Biosource::Schema::BsSample') {
      croak("SET ARGUMENT ERROR: $bssample_row isn't a bssample_row obj. (CXGN::Biosource::Schema::BsSample).\n");
  }
  $self->{bssample_row} = $bssample_row;
}



=head2 accessors get_bssamplepub_rows, set_bssamplepub_rows

  Usage: my @bssamplepub_rows = $self->get_bssamplepub_rows();
         $self->set_bssamplepub_rows(\@bssamplepub_rows);

  Desc: Get or set a list of bssamplepub rows object into a sample object
 
  Ret:   Get => @bssamplepub_row_object, a list of row objects 
                (CXGN::Biosource::Schema::BsSamplePub).
         Set => none
 
  Args:  Get => none
         Set => @bssamplepub_row_object, an array ref of row objects 
                (CXGN::Biosource::Schema::BsSamplePub).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @bssamplepub_rows = $self->get_bssamplepub_rows();
           $self->set_bssamplepub_rows(\@bssamplepub_rows);

=cut

sub get_bssamplepub_rows {
  my $self = shift;
 
  return @{$self->{bssamplepub_rows}}; 
}

sub set_bssamplepub_rows {
  my $self = shift;
  my $bssamplepub_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssamplepub_row array ref was supplied for set_bssamplepub_rows function.\n");
 
  if (ref($bssamplepub_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $bssamplepub_row_aref isn't an array reference.\n");
  }
  else {
      foreach my $bssamplepub_row (@{$bssamplepub_row_aref}) {  
          if (ref($bssamplepub_row) ne 'CXGN::Biosource::Schema::BsSamplePub') {
              croak("SET ARGUMENT ERROR: $bssamplepub_row isn't a bssamplepub_row obj. (CXGN::Biosource::Schema::BsSamplePub).\n");
          }
      }
  }
  $self->{bssamplepub_rows} = $bssamplepub_row_aref;
}


=head2 accessors get_bssampleelement_rows, set_bssampleelements_rows

  Usage: my %bssampleelement_rows = $self->get_bssampleelement_rows();
         $self->set_bssampleelement_rows(\%bssampleelement_rows);

  Desc: Get or set a bssampleelement row object into a sample object
        as hash reference where keys = step and value = row object
 
  Ret:   Get => A hash where key=step and value=row object
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=row object
                (CXGN::Biosource::Schema::BsSampleElement).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelement_rows = $self->get_bssampleelement_rows();
            $self->set_bssampleelement_rows(\%bssampleelement_rows);

=cut

sub get_bssampleelement_rows {
  my $self = shift;
  
  return %{$self->{bssampleelement_rows}}; 
}

sub set_bssampleelement_rows {
  my $self = shift;
  my $bssampleelement_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bs_sample_element_row hash ref. was supplied for set_bssampleelement_row function.\n"); 

  if (ref($bssampleelement_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelement_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelement = %{$bssampleelement_href};
      
      foreach my $element_name (keys %bssampleelement) {
	  unless (ref($bssampleelement{$element_name}) eq 'CXGN::Biosource::Schema::BsSampleElement') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelement{$element_name} isn't a row obj. (BsSampleElement).\n");
	  }
      }
  }
  $self->{bssampleelement_rows} = $bssampleelement_href;
}


=head2 accessors get_bssampleelementdbxref_rows, set_bssampleelementdbxref_rows

  Usage: my %bssamplelementdbxref_rows = $self->get_bssampleelementdbxref_rows()
         $self->set_bssamplelementdbxref_rows(\%bssampleelementdbxref_rows);

  Desc: Get or set a bssampleelementdbxref row object into a sample object
        as hash reference where keys = element_name and value = an array 
        reference with row objects 
        (CXGN::Biosource::Schema::BsSampleElementDbxref)
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsSampleElementDbxref).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelementdbxref_rows = $self->get_bssampleelementdbxref_rows();
            $self->set_bssampleelementdbxref_rows(\%bssampleelementdbxref_rows);

=cut

sub get_bssampleelementdbxref_rows {
  my $self = shift;

  return %{$self->{bssampleelementdbxref_rows}}; 
}

sub set_bssampleelementdbxref_rows {
  my $self = shift;
  my $bssampleelementdbxref_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssampleelementdbxref_row hash ref. was supplied for set_bssampleelementdbxref_row.\n"); 

  if (ref($bssampleelementdbxref_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelementdbxref_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelementdbxref = %{$bssampleelementdbxref_href};
      
      foreach my $element_name (keys %bssampleelementdbxref) {
	  unless (ref($bssampleelementdbxref{$element_name}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelementdbxref{$element_name} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bssampleelementdbxref{$element_name}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsSampleElementDbxref') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsSampleElementDbxref).\n");
		  }
	      }
	  }
      }
  }
  $self->{bssampleelementdbxref_rows} = $bssampleelementdbxref_href;
}


=head2 accessors get_bssampleelementcvterm_rows, set_bssampleelementcvterm_rows

  Usage: my %bssamplelementcvterm_rows = $self->get_bssampleelementcvterm_rows()
         $self->set_bssamplelementcvterm_rows(\%bssampleelementcvterm_rows);

  Desc: Get or set a bssampleelementcvterm row object into a sample object
        as hash reference where keys = element_name and value = an array 
        reference with row objects 
        (CXGN::Biosource::Schema::BsSampleElementCvterm)
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsSampleElementCvterm).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelementcvterm_rows = $self->get_bssampleelementcvterm_rows();
            $self->set_bssampleelementcvterm_rows(\%bssampleelementcvterm_rows);

=cut

sub get_bssampleelementcvterm_rows {
  my $self = shift;

  return %{$self->{bssampleelementcvterm_rows}}; 
}

sub set_bssampleelementcvterm_rows {
  my $self = shift;
  my $bssampleelementcvterm_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssampleelementcvterm_row hash ref. was supplied for set_bssampleelementcvterm_row.\n"); 

  if (ref($bssampleelementcvterm_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelementcvterm_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelementcvterm = %{$bssampleelementcvterm_href};
      
      foreach my $element_name (keys %bssampleelementcvterm) {
	  unless (ref($bssampleelementcvterm{$element_name}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelementcvterm{$element_name} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bssampleelementcvterm{$element_name}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsSampleElementCvterm') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsSampleElementCvterm).\n");
		  }
	      }
	  }
      }
  }
  $self->{bssampleelementcvterm_rows} = $bssampleelementcvterm_href;
}


=head2 accessors get_bssampleelementfile_rows, set_bssampleelementfile_rows

  Usage: my %bssamplelementfile_rows = $self->get_bssampleelementfile_rows()
         $self->set_bssamplelementfile_rows(\%bssampleelementfile_rows);

  Desc: Get or set a bssampleelementfile row object into a sample object
        as hash reference where keys = element_name and value = an array 
        reference with row objects 
        (CXGN::Biosource::Schema::BsSampleElementFile)
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsSampleElementFile).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelementfile_rows = $self->get_bssampleelementfile_rows();
            $self->set_bssampleelementfile_rows(\%bssampleelementfile_rows);

=cut

sub get_bssampleelementfile_rows {
  my $self = shift;

  return %{$self->{bssampleelementfile_rows}}; 
}

sub set_bssampleelementfile_rows {
  my $self = shift;
  my $bssampleelementfile_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssampleelementfile_row hash ref. was supplied for set_bssampleelementfile_row.\n"); 

  if (ref($bssampleelementfile_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelementfile_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelementfile = %{$bssampleelementfile_href};
      
      foreach my $element_name (keys %bssampleelementfile) {
	  unless (ref($bssampleelementfile{$element_name}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelementfile{$element_name} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bssampleelementfile{$element_name}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsSampleElementFile') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsSampleElementFile).\n");
		  }
	      }
	  }
      }
  }
  $self->{bssampleelementfile_rows} = $bssampleelementfile_href;
}


=head2 accessors get_bssampleelementrelation_source_rows, set_bssampleelementrelation_source_rows

  Usage: my %bssamplelementrelation_source_rows = $self->get_bssampleelementrelation_source_rows()
         $self->set_bssamplelementrelation_source_rows(\%bssampleelementrelation_source_rows);

  Desc: Get or set a bssampleelementrelation row object into a sample object
        as hash reference where keys = element_name and value = an array 
        reference with row objects 
        (CXGN::Biosource::Schema::BsSampleElementRelation)

        Source relations are these relations between two sample_elements where the sample_element_name
        contained in the object is the sample_element_id_A in the sample_element_relation row 
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsSampleElementRelation).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelementrelation_source_rows = $self->get_bssampleelementrelation_source_rows();
            $self->set_bssampleelementrelation_source_rows(\%bssampleelementrelation_source_rows);

=cut

sub get_bssampleelementrelation_source_rows {
  my $self = shift;

  return %{$self->{bssampleelementrelation_source_rows}}; 
}

sub set_bssampleelementrelation_source_rows {
  my $self = shift;
  my $bssampleelementrelation_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssampleelementrelation_source_row hash ref was supplied\n"); 

  if (ref($bssampleelementrelation_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelementrelation_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelementrelation = %{$bssampleelementrelation_href};
      
      foreach my $element_name (keys %bssampleelementrelation) {
	  unless (ref($bssampleelementrelation{$element_name}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelementrelation{$element_name} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bssampleelementrelation{$element_name}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsSampleElementRelation') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsSampleElementRelation).\n");
		  }
	      }
	  }
      }
  }
  $self->{bssampleelementrelation_source_rows} = $bssampleelementrelation_href;
}


=head2 accessors get_bssampleelementrelation_result_rows, set_bssampleelementrelation_result_rows

  Usage: my %bssamplelementrelation_result_rows = $self->get_bssampleelementrelation_result_rows()
         $self->set_bssamplelementrelation_result_rows(\%bssampleelementrelation_result_rows);

  Desc: Get or set a bssampleelementrelation row object into a sample object
        as hash reference where keys = element_name and value = an array 
        reference with row objects 
        (CXGN::Biosource::Schema::BsSampleElementRelation)

        Result relations are these relations between two sample_elements where the sample_element_name
        contained in the object is the sample_element_id_A in the sample_element_relation row 
 
  Ret:   Get => A hash where key=step and value=array reference with 
                row objects.
         Set => none
 
  Args:  Get => none
         Set => A hash reference where key=step and value=and array reference
                with row objects (CXGN::Biosource::Schema::BsSampleElementRelation).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example:  my %bssampleelementrelation_result_rows = $self->get_bssampleelementrelation_result_rows();
            $self->set_bssampleelementrelation_result_rows(\%bssampleelementrelation_result_rows);

=cut

sub get_bssampleelementrelation_result_rows {
  my $self = shift;

  return %{$self->{bssampleelementrelation_result_rows}}; 
}

sub set_bssampleelementrelation_result_rows {
  my $self = shift;
  my $bssampleelementrelation_href = shift 
      || croak("FUNCTION PARAMETER ERROR: None bssampleelementrelation_result_row hash ref was supplied\n"); 

  if (ref($bssampleelementrelation_href) ne 'HASH') {
      croak("SET ARGUMENT ERROR: hash ref. = $bssampleelementrelation_href isn't an hash reference.\n");
  }
  else {
      my %bssampleelementrelation = %{$bssampleelementrelation_href};
      
      foreach my $element_name (keys %bssampleelementrelation) {
	  unless (ref($bssampleelementrelation{$element_name}) eq 'ARRAY') {
	       croak("SET ARGUMENT ERROR: row obj = $bssampleelementrelation{$element_name} isn't an ARRAY REFERENCE.\n");
	  }
	  else {
	      my @rows = @{$bssampleelementrelation{$element_name}};
	      foreach my $row (@rows) {
		  unless (ref($row) eq 'CXGN::Biosource::Schema::BsSampleElementRelation') {
		      croak("SET ARGUMENT ERROR: row obj = $row isn't a row obj.(CXGN::Biosource::Schema::BsSampleElementRelation).\n");
		  }
	      }
	  }
      }
  }
  $self->{bssampleelementrelation_result_rows} = $bssampleelementrelation_href;
}



#################################
### DATA ACCESSORS FOR SAMPLE ###
#################################

=head2 get_sample_id, force_set_sample_id
  
  Usage: my $sample_id = $sample->get_sample_id();
         $sample->force_set_sample_id($sample_id);

  Desc: get or set a sample_id in a sample object. 
        set method should be USED WITH PRECAUTION
        If you want set a sample_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        sample_id that do not follow the biosource.bs_sample_sample_id_seq

  Ret:  get=> $sample_id, a scalar.
        set=> none

  Args: get=> none
        set=> $sample_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $sample_id = $sample->get_sample_id(); 

=cut

sub get_sample_id {
  my $self = shift;
  return $self->get_bssample_row->get_column('sample_id');
}

sub force_set_sample_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None sample_id was supplied for force_set_sample_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The sample_id ($data) for $self->force_set_sample_id() ISN'T AN INTEGER.\n");
  }

  $self->get_bssample_row()
       ->set_column( sample_id => $data );
 
}

=head2 accessors get_sample_name, set_sample_name

  Usage: my $sample_name = $sample->get_sample_name();
         $sample->set_sample_name($sample_name);

  Desc: Get or set the sample_name from sample object. 

  Ret:  get=> $sample_name, a scalar
        set=> none

  Args: get=> none
        set=> $sample_name, a scalar

  Side_Effects: none

  Example: my $sample_name = $sample->get_sample_name();
           $sample->set_sample_name($new_name);
=cut

sub get_sample_name {
  my $self = shift;
  return $self->get_bssample_row->get_column('sample_name'); 
}

sub set_sample_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_sample_name function.\n");

  $self->get_bssample_row()
       ->set_column( sample_name => $data );
}

=head2 accessors get_sample_type, set_sample_type

  Usage: my $sample_type = $sample->get_sample_type();
         $sample->set_sample_type($sample_type);
 
  Desc: Get or set sample_type from a sample object. 
 
  Ret:  get=> $sample_type, a scalar
        set=> none
 
  Args: get=> none
        set=> $sample_type, a scalar
 
  Side_Effects: none
 
  Example: my $sample_type = $sample->get_sample_type();

=cut

sub get_sample_type {
  my $self = shift;
  return $self->get_bssample_row->get_column('sample_type'); 
}

sub set_sample_type {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->set_sample_type function.\n");

  $self->get_bssample_row()
       ->set_column( sample_type => $data );
}

=head2 accessors get_description, set_description

  Usage: my $description = $sample->get_description();
         $sample->set_description($description);

  Desc: Get or set the description from a sample object 

  Ret:  get=> $description, a scalar
        set=> none

  Args: get=> none
        set=> $description, a scalar

  Side_Effects: none

  Example: my $description = $sample->get_description();
           $sample->set_description($description);
=cut

sub get_description {
  my $self = shift;
  return $self->get_bssample_row->get_column('description'); 
}

sub set_description {
  my $self = shift;
  my $data = shift;

  $self->get_bssample_row()
       ->set_column( description => $data );
}

=head2 get_contact_id, set_contact_id
  
  Usage: my $contact_id = $sample->get_contact_id();
         $sample->set_contact_id($contact_id);

  Desc: get or set a contact_id in a sample object. 

  Ret:  get=> $contact_id, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_id, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact_id = $sample->get_contact_id(); 

=cut

sub get_contact_id {
  my $self = shift;
  return $self->get_bssample_row->get_column('contact_id');
}

sub set_contact_id {
  my $self = shift;
  my $data = shift;

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The contact_id ($data) for $self->set_contact_id() ISN'T AN INTEGER.\n");
  }

  $self->get_bssample_row()
       ->set_column( contact_id => $data );
 
}

=head2 get_contact_by_username, set_contact_by_username
  
  Usage: my $contact_username = $sample->get_contact_by_username();
         $sample->set_contact_by_username($contact_username);

  Desc: get or set a contact_id in a sample object using username 

  Ret:  get=> $contact_username, a scalar.
        set=> none

  Args: get=> none
        set=> $contact_username, a scalar (constraint: it must be an integer)

  Side_Effects: die if the argument supplied is not an integer

  Example: my $contact = $sample->get_contact_by_username(); 

=cut

sub get_contact_by_username {
  my $self = shift;

  my $contact_id = $self->get_bssample_row
                        ->get_column('contact_id');

  if (defined $contact_id) {

      ## This is a temp simple SQL query. It should be replaced by DBIx::Class search when the person module will be developed 

      my $query = "SELECT username FROM sgn_people.sp_person WHERE sp_person_id = ?";
      my ($username) = $self->get_schema()
	                    ->storage()
			    ->dbh()
			    ->selectrow_array($query, undef, $contact_id);

      unless (defined $username) {
	  croak("DATABASE INTEGRITY ERROR: sp_person_id=$contact_id defined in biosource.bs_sample don't exists in sp_person table.\n")
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
      $self->get_bssample_row()
	   ->set_column( contact_id => $contact_id );
  }
 
}


######################################
### DATA ACCESSORS FOR SAMPLE PUBS ###
######################################

=head2 add_publication

  Usage: $sample->add_publication($pub_id);

  Desc: Add a publication to the pub_ids associated to sample object
        using different arguments as pub_id, title or dbxref_accession 

  Ret:  None

  Args: $pub_id, a publication id. 
        To use with $pub_id: 
          $sample->add_publication($pub_id);
        To use with $pub_title
          $sample->add_publication({ title => $pub_title } );
        To use with pubmed accession
          $sample->add_publication({ dbxref_accession => $accesssion});
          
  Side_Effects: die if the parameter is not an object

  Example: $sample->add_publication($pub_id);

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
	    my $title = $pub->{'title'};
            ($pub_row) = $self->get_schema()
                              ->resultset('Pub::Pub')
                              ->search( {title => { 'ilike', '%'.$title.'%' } });
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
    my $samplepub_row = $self->get_schema()
                             ->resultset('BsSamplePub')
                             ->new({ pub_id => $pub_id});
    
    if (defined $self->get_sample_id() ) {
        $samplepub_row->set_column( sample_id => $self->get_sample_id() );
    }

    my @samplepub_rows = $self->get_bssamplepub_rows();
    push @samplepub_rows, $samplepub_row;
    $self->set_bssamplepub_rows(\@samplepub_rows);
}

=head2 get_publication_list

  Usage: my @pub_list = $sample->get_publication_list();

  Desc: Get a list of publications associated to this sample

  Ret: An array of pub_ids by default, but can be titles
       or accessions using an argument

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @pub_id_list = $sample->get_publication_list();
           my @pub_title_list = $sample->get_publication_list('title');
           my @pub_title_accs = $sample->get_publication_list('dbxref.accession');


=cut

sub get_publication_list {
    my $self = shift;
    my $field = shift;

    my @pub_list = ();

    my @samplepub_rows = $self->get_bssamplepub_rows();
    foreach my $samplepub_row (@samplepub_rows) {
        my $pub_id = $samplepub_row->get_column('pub_id');
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



##########################################
### DATA ACCESSORS FOR SAMPLE ELEMENTS ###
##########################################

=head2 add_sample_element

  Usage: $sample->add_sample_element( $parameters_hash_ref );

  Desc: Add a new sample element to the sample object 

  Ret: None

  Args: A hash reference with key=sample_element_parameter and value=value
        The protocol_step parameters and the type are:
          - sample_element_name => varchar(250)
          - alternative_name    => text 
          - description         => text
          - organism_name       => text (or organism_id => integer)
          - stock_name          => text (or stock_id => integer)
          - protocol_name       => text (or protocol_id => integer)

          * Note: Stock is not currently supported (2009-11-12)

  Side_Effects: none

  Example: $sample->add_sample_element( 
                                         { 
                                           sample_element_name   => 'mRNA tobacco leaves', 
                                           description => 'leaves samples used in the TobEA',
                                           organism_name => 'Nicotiana tabacum'
                                         }
                                       );

=cut

sub add_sample_element {
    my $self = shift;
    my $param_hashref = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for $self->add_sample_element function.\n");

    if (ref($param_hashref) ne 'HASH') {
	 croak("DATA TYPE ERROR: The parameter hash ref. for $self->add_sample_element() ISN'T A HASH REFERENCE.\n");
    }

    my %param = %{$param_hashref};
    
    
    ## Search in the database a organism name (chado tables) and get the organism_id. Die if don't find anything.

    if (exists $param{'organism_name'}) {
	my $organism_name = delete($param{'organism_name'});
	my ($organism_row) = $self->get_schema()
	                          ->resultset('Organism::Organism')
				  ->search({ species => $organism_name });

	if (defined $organism_row) {
	    my $organism_id = $organism_row->get_column('organism_id');

	    unless (exists $param{'organism_id'}) {
		$param{'organism_id'} = $organism_id;
	    }
	}
	else {
	    croak("DATABASE COHERENCE ERROR for add_sample_element function: Organism_name=$organism_name don't exists in database.\n");
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
	    croak("DATABASE COHERENCE ERROR for add_sample_element: Protocol_name=$protocol_name don't exists in database.\n");
	}
    }

    ## For now the stock do not exists into CXGN database so it will be possible use any part of these code. It only will 
    ## remove the stock name from the parameters

    if (exists $param{'stock_name'}) {
 	my $stock_name = delete($param{'stock_name'});
    # 	my ($stock_row) = $self->get_schema()
    # 	                       ->resultset('Stock::Stock')
    # 	      		       ->search({ name => $stock_name });
	
    # 	if (defined $stock_row) {
    # 	    my $stock_id = $stock_row->get_column('stock_id');
	    
    # 	    unless (exists $param{'stock_id'}) {
    # 		$param{'stock_id'} = $stock_id;
    # 	    }
	    
    # 	    ## By default, if do not exists organism_id in the parameters, it will take from the stock table
	    
    # 	    my $stock_organism_id = $stock_row->get_column('organism_id');
    #  	    unless (exists $param{'organism_id'}) {
    # 		$param{'organism_id'} = $stock_organism_id;
    #  	    }
    # 	}
    # 	else {
    # 	    croak("DATABASE COHERENCE ERROR for add_sample_element function: Stock_name=$stock_name don't exists in database.\n");
    # 	}
    }

    
    my $sample_id = $self->get_sample_id();
    if (defined $sample_id) {
	$param{'sample_id'} = $sample_id;
    }

    my $new_sample_element_row = $self->get_schema()
	                              ->resultset('BsSampleElement')
				      ->new(\%param);

    my %bssamplelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssamplelement_rows{$param{'sample_element_name'}} ) {
	$bssamplelement_rows{$param{'sample_element_name'}} = $new_sample_element_row;
    } 
    else {
	croak("FUNCTION ERROR: Sample_element_name=$param{'sample_element_name'} exists sample obj. It only can be edited using edit.\n");
    }

    $self->set_bssampleelement_rows(\%bssamplelement_rows);
}

=head2 get_sample_elements

  Usage: my %sample_elements = $sample->get_sample_elements();

  Desc: Get the sample elements from a sample object, 
        to get all the data from the row use get_columns function

  Ret: %sample elements, where: keys = sample_element_name 
                                value = a hash reference with:
                                   keys  = column_name
                                   value = value
  Args: none

  Side_Effects: none

  Example: my %sample_elements = $sample->get_sample_elements();
           my $first_description = $sample_elements{'first'}->{description};

=cut

sub get_sample_elements {
    my $self = shift;

    my %sample_elements_by_data;
    
    my %bssampleelements_rows = $self->get_bssampleelement_rows();
    foreach my $sample_element_name ( keys %bssampleelements_rows ) {
	my %data_hash = $bssampleelements_rows{$sample_element_name}->get_columns();


	## It will add organism name and protocol name to the data hash

	if (defined $data_hash{'organism_id'}) {
	    my ($organism_row) = $self->get_schema()
		                      ->resultset('Organism::Organism')
				      ->search( { organism_id => $data_hash{'organism_id'} } );

	    if (defined $organism_row) {
		my $organism_name = $organism_row->get_column('species');

		unless (exists $data_hash{'organism_name'}) {
		    $data_hash{'organism_name'} = $organism_name;
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
	
	$sample_elements_by_data{$sample_element_name} = \%data_hash;
    }
    return %sample_elements_by_data;
}

=head2 edit_sample_element

  Usage: $sample->edit_sample_element($element_name, $parameters_hash_ref);

  Desc: Edit a sample element in the sample object. 
        It can not edit the sample_element_name. 
        To add a new element use add_sample_element.
        To obsolete a element use obsolete_sample_element.

  Ret: None

  Args: $element, a scalar, an sample_element_name,
        $parameters_hash_ref, a hash reference with 
        key=sample_element_parameter and value=value
        The sample_element parameters and the type are:
          - alternative_name    => text 
          - description         => text
          - organism_name       => text (or organism_id => integer)
          - stock_name          => text (or stock_id => integer)
          - protocol_name       => text (or protocol_id => integer)

  Side_Effects: none

  Example: $sample->edit_sample_element( $sample_element_1 
                                         { 
                                           description => 'another description', 
                                           organism_name => 'Nicotiana sylvestris', 
                                         }
                                       );

=cut

sub edit_sample_element {
    my $self = shift;
    my $element_name = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for edit_sample_element function to $self.\n");
    
    my $param_hashref = shift ||
	croak("FUNCTION PARAMETER ERROR: None parameter hash reference was supplied for edit_sample_element function to $self.\n");

    if (ref($param_hashref) ne 'HASH') {
	 croak("DATA TYPE ERROR: The parameter hash ref. for $self->edit_sample_element() ISN'T A HASH REFERENCE.\n");
    }

    ## In the same way that it changed organism_name, protocol_name and stock_name in add_sample_element function, it will
    ## do for edit_sample_element

    ## Search in the database a organism name (chado tables) and get the organism_id. Die if don't find anything.

    my %param = %{$param_hashref};
    if (exists $param{'organism_name'}) {
	my $organism_name = delete($param{'organism_name'});
	my ($organism_row) = $self->get_schema()
	                          ->resultset('Organism::Organism')
				  ->search({ species => $organism_name });

	if (defined $organism_row) {
	    my $organism_id = $organism_row->get_column('organism_id');

	    unless (exists $param{'organism_id'}) {
		$param{'organism_id'} = $organism_id;
	    }
	}
	else {
	    croak("DATABASE COHERENCE ERROR for edit_sample_element function: Organism_name=$organism_name don't exists in database.\n");
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
	    croak("DATABASE COHERENCE ERROR for edit_sample_element: Protocol_name=$protocol_name don't exists in database.\n");
	}
    }

    ## For now the stock do not exists into CXGN database so it will be possible use any part of these code. It only will 
    ## remove the stock name from the parameters

    if (exists $param{'stock_name'}) {
 	my $stock_name = delete($param{'stock_name'});
    # 	my ($stock_row) = $self->get_schema()
    # 	                       ->resultset('Stock::Stock')
    # 	      		       ->search({ name => $stock_name });
	
    # 	if (defined $stock_row) {
    # 	    my $stock_id = $stock_row->get_column('stock_id');
	    
    # 	    unless (exists $param{'stock_id'}) {
    # 		$param{'stock_id'} = $stock_id;
    # 	    }
	    
    # 	    ## By default, if do not exists organism_id in the parameters, it will take from the stock table
	    
    # 	    my $stock_organism_id = $stock_row->get_column('organism_id');
    #  	    unless (exists $param{'organism_id'}) {
    # 		$param{'organism_id'} = $stock_organism_id;
    #  	    }
    # 	}
    # 	else {
    # 	    croak("DATABASE COHERENCE ERROR for add_sample_element function: Stock_name=$stock_name don't exists in database.\n");
    # 	}
    }
    
    ## This should not change sample_element_name or sample_element_id
    delete($param{'sample_element_name'});
    delete($param{'sample_element_id'});
    
    
    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name} ) {
	croak("FUNCTION ERROR: Sample_element_name=$element_name don't exists sample obj. Use add_sample_element to add a new one.\n");
    } 
    else {
	$bssampleelement_rows{$element_name}->set_columns(\%param);
    }

    $self->set_bssampleelement_rows(\%bssampleelement_rows);
}


###############################################
## DATA ACCESSORS FOR SAMPLE_ELEMENT_DBXREFs ##
###############################################

=head2 add_dbxref_to_sample_element

  Usage: $sample->add_dbxref_to_sample_element($element_name, $dbxref_id);

  Desc: Add a new sample_element_dbxref_row to the sample object
        to associate a new dbxref to a sample element (for example
        ontology terms). 

  Ret: None

  Args: $element_name, a scalar
        $dbxref_id, a scalar, an integer

  Side_Effects: check if exists the dbxref_id in the db, if it don't
                exists, die.

  Example: $sample->add_dbxref_to_sample_element($element_name, $dbxref_id);

=cut

sub add_dbxref_to_sample_element {
    my $self = shift;

    ## Checking variables

    my $element_name = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_dbxref_to_sample_element() function to $self.\n");
    
     my $dbxref_id = shift ||
	croak("FUNCTION PARAMETER ERROR: None dbxref_id was supplied for add_dbxref_to_sample_element function to $self.\n");

    unless ($dbxref_id =~ m/^\d+$/) {
	 croak("DATA TYPE ERROR: Dbxref_id parameter for $self->add_dbxref_to_sample_element() ISN'T AN INTEGER.\n");
    }
    else {
	my $dbxref_id_count = $self->get_schema()
	                           ->resultset('General::Dbxref')
			           ->search({ dbxref_id => $dbxref_id })
			           ->count();
	if ($dbxref_id_count == 0) {
	    croak("DATABASE COHERENCE ERROR: Dbxref_id parameter for $self->add_dbxref_to_sample_element() don't exists in the db.\n");
	}
    }

    ## It will create new row using parameter hash

    my %params = ( dbxref_id => $dbxref_id );

    ## It will add the sample_element_id if exists into the row object

    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name}) {
	croak("DATA OBJECT COHERENCE ERROR: Element_sample_name=$element_name do not exists into the $self object\n");
    }

    my $sample_element_id = $bssampleelement_rows{$element_name}->get_column('sample_element_id');

    if (defined $sample_element_id) {
	$params{sample_element_id} = $sample_element_id;
    }

    my $new_elementdbxref_row = $self->get_schema()
	                             ->resultset('BsSampleElementDbxref')
				     ->new(\%params);

    my %bselementdbxref_rows = $self->get_bssampleelementdbxref_rows();
     
    
    unless (exists $bselementdbxref_rows{$element_name} ) {
	$bselementdbxref_rows{$element_name} = [$new_elementdbxref_row];
    } 
    else {
	push @{$bselementdbxref_rows{$element_name}}, $new_elementdbxref_row;
    }

    $self->set_bssampleelementdbxref_rows(\%bselementdbxref_rows);
}


=head2 get_dbxref_from_sample_elements

  Usage: my %sampleelementdbxref = $sample->get_dbxref_from_sample_elements();

  Desc: Get the dbxref_id associated to a sample elements in a sample object.

  Ret: %sample_elements, where: keys = sample_element_name 
                                value = a array reference with a list of 
                                        dbxref_ids
  Args: none

  Side_Effects: none

  Example: my %samplelementsdbxref = $sample->get_dbxref_from_sample_elements();
           my @first_dbxrefs = @{$samplelementsdbxref{'first'}};

=cut

sub get_dbxref_from_sample_elements {
    my $self = shift;

    my %dbxref_by_elements;
    
    my %bselementdbxref_rows = $self->get_bssampleelementdbxref_rows();

    foreach my $element_name ( keys %bselementdbxref_rows ) {
	my @dbxref_id_list = ();
	my @rows = @{$bselementdbxref_rows{$element_name}};
	foreach my $row (@rows) {
	    push @dbxref_id_list, $row->get_column('dbxref_id');
	}
	$dbxref_by_elements{$element_name} = \@dbxref_id_list;
    }
    return %dbxref_by_elements;
}


###############################################
## DATA ACCESSORS FOR SAMPLE_ELEMENT_CVTERMs ##
###############################################

=head2 add_cvterm_to_sample_element

  Usage: $sample->add_cvterm_to_sample_element($element_name, $cvterm_id);

  Desc: Add a new sample_element_cvterm_row to the sample object
        to associate a new cvterm to a sample element (for example
        normalized). 

  Ret: None

  Args: $element_name, a scalar
        $cvterm_id, a scalar, an integer

  Side_Effects: check if exists the cvterm_id in the db, if it don't
                exists, die.

  Example: $sample->add_cvterm_to_sample_element($element_name, $cvterm_id);

=cut

sub add_cvterm_to_sample_element {
    my $self = shift;

    ## Checking variables

    my $element_name = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_cvterm_to_sample_element() function to $self.\n");
    
     my $cvterm_id = shift ||
	croak("FUNCTION PARAMETER ERROR: None cvterm_id was supplied for add_cvterm_to_sample_element function to $self.\n");

    unless ($cvterm_id =~ m/^\d+$/) {
	 croak("DATA TYPE ERROR: Cvterm_id parameter for $self->add_cvterm_to_sample_element() ISN'T AN INTEGER.\n");
    }
    else {
	my $cvterm_id_count = $self->get_schema()
	                           ->resultset('Cv::Cvterm')
			           ->search({ cvterm_id => $cvterm_id })
			           ->count();
	if ($cvterm_id_count == 0) {
	    croak("DATABASE COHERENCE ERROR: Cvterm_id parameter for $self->add_cvterm_to_sample_element() don't exists in the db.\n");
	}
    }

    ## It will create new row using parameter hash

    my %params = ( cvterm_id => $cvterm_id );

    ## It will add the protocol_step_id if exists into the row object

    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name}) {
	croak("DATA OBJECT COHERENCE ERROR: Element_sample_name=$element_name do not exists into the $self object\n");
    }

    my $sample_element_id = $bssampleelement_rows{$element_name}->get_column('sample_element_id');

    if (defined $sample_element_id) {
	$params{sample_element_id} = $sample_element_id;
    }

    my $new_elementcvterm_row = $self->get_schema()
	                             ->resultset('BsSampleElementCvterm')
				     ->new(\%params);

    my %bselementcvterm_rows = $self->get_bssampleelementcvterm_rows();
     
    
    unless (exists $bselementcvterm_rows{$element_name} ) {
	$bselementcvterm_rows{$element_name} = [$new_elementcvterm_row];
    } 
    else {
	push @{$bselementcvterm_rows{$element_name}}, $new_elementcvterm_row;
    }

    $self->set_bssampleelementcvterm_rows(\%bselementcvterm_rows);
}


=head2 get_cvterm_from_sample_elements

  Usage: my %sampleelementcvterm = $sample->get_cvterm_from_sample_elements();

  Desc: Get the cvterm_id associated to a sample elements in a sample object.

  Ret: %sample_elements, where: keys = sample_element_name 
                                value = a array reference with a list of 
                                        cvterm_ids
  Args: none

  Side_Effects: none

  Example: my %samplelementscvterm = $sample->get_cvterm_from_sample_elements();
           my @first_cvterms = @{$samplelementscvterm{'first'}};

=cut

sub get_cvterm_from_sample_elements {
    my $self = shift;

    my %cvterm_by_elements;
    
    my %bselementcvterm_rows = $self->get_bssampleelementcvterm_rows();

    foreach my $element_name ( keys %bselementcvterm_rows ) {
	my @cvterm_id_list = ();
	my @rows = @{$bselementcvterm_rows{$element_name}};
	foreach my $row (@rows) {
	    push @cvterm_id_list, $row->get_column('cvterm_id');
	}
	$cvterm_by_elements{$element_name} = \@cvterm_id_list;
    }
    return %cvterm_by_elements;
}

###############################################
## DATA ACCESSORS FOR SAMPLE_ELEMENT_FILEs ##
###############################################

=head2 add_file_to_sample_element

  Usage: $sample->add_file_to_sample_element($element_name, $file_id);
         $sample->add_file_to_sample_element($element_name, 
                                            { $mdfilecolumn => $data});

  Desc: Add a new sample_element_file_row to the sample object
        to associate a new file to a sample element. 

  Ret: None

  Args: $element_name, a scalar
        $file_id, a scalar, an integer or hash reference with 
        key = column_name in md_files table and value=value
        (note: die when this return more than one row)

  Side_Effects: check if exists the file_id in the db, if it don't
                exists, die.

  Example: $sample->add_file_to_sample_element($element_name, $file_id);
           $sample->add_file_to_sample_element($element_name, 
                                              { basename => $file_name});
=cut

sub add_file_to_sample_element {
    my $self = shift;

    ## Checking variables

    my $element_name = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_file_to_sample_element() function to $self.\n");
    
     my $file = shift ||
	croak("FUNCTION PARAMETER ERROR: None file_id was supplied for add_file_to_sample_element function to $self.\n");

    my $file_id;
    unless (ref($file) ) {
	unless ($file =~ m/^\d+$/) {
	    croak("DATA TYPE ERROR: File_id parameter for $self->add_file_to_sample_element() ISN'T AN INTEGER.\n");
	}
	else {
	    $file_id = $file;
	}
    } 
    else { 
	if (ref($file) eq 'HASH') {
	    my @file_rows = $self->get_schema()
		               ->resultset('MdFiles')
			       ->search($file);
 
	    if (scalar(@file_rows) == 0) {
		croak("DATABASE COHERENCE ERROR: Doesnt exist any file with param. supplied to $self->add_file_to_sample_element().\n");
	    }
	    else {
		
		if (scalar(@file_rows) != 1) {
		    croak("INPUT PARAMETER ERROR: Parameter supplied to $self->add_file_to_sample_element return more than one row.\n");
		}
		else {
		    $file_id = $file_rows[0]->get_column('file_id');
		}
	    }
	}
	else {
	    croak("TYPE PARAMETER ERROR: Parameter supplied to $self->add_file_to_sample_element IS NOT A SCALAR OR HASH REFERENCE");
	}
    }
    my $file_id_count = $self->get_schema()
	                     ->resultset('MdFiles')
			     ->search({ file_id => $file_id })
		             ->count();
    if ($file_id_count == 0) {
	croak("DATABASE COHERENCE ERROR: File_id parameter for $self->add_file_to_sample_element() don't exists in the db.\n");
    }
    

    ## It will create new row using parameter hash

    my %params = ( file_id => $file_id );

    ## It will add the protocol_step_id if exists into the row object

    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name}) {
	croak("DATA OBJECT COHERENCE ERROR: Element_sample_name=$element_name do not exists into the $self object\n");
    }

    my $sample_element_id = $bssampleelement_rows{$element_name}->get_column('sample_element_id');

    if (defined $sample_element_id) {
	$params{sample_element_id} = $sample_element_id;
    }

    my $new_elementfile_row = $self->get_schema()
	                           ->resultset('BsSampleElementFile')
		      	           ->new(\%params);

    my %bselementfile_rows = $self->get_bssampleelementfile_rows();
     
    
    unless (exists $bselementfile_rows{$element_name} ) {
	$bselementfile_rows{$element_name} = [$new_elementfile_row];
    } 
    else {
	push @{$bselementfile_rows{$element_name}}, $new_elementfile_row;
    }

    $self->set_bssampleelementfile_rows(\%bselementfile_rows);
}


=head2 get_file_from_sample_elements

  Usage: my %sampleelementfile = $sample->get_file_from_sample_elements();

  Desc: Get the file_id associated to a sample elements in a sample object.

  Ret: %sample_elements, where: keys = sample_element_name 
                                value = a array reference with a list of 
                                        file_ids
  Args: none

  Side_Effects: none

  Example: my %samplelementsfile = $sample->get_file_from_sample_elements();
           my @first_files = @{$samplelementsfile{'first'}};

=cut

sub get_file_from_sample_elements {
    my $self = shift;

    my %file_by_elements;
    
    my %bselementfile_rows = $self->get_bssampleelementfile_rows();

    foreach my $element_name ( keys %bselementfile_rows ) {
	my @file_id_list = ();
	my @rows = @{$bselementfile_rows{$element_name}};
	foreach my $row (@rows) {
	    push @file_id_list, $row->get_column('file_id');
	}
	$file_by_elements{$element_name} = \@file_id_list;
    }
    return %file_by_elements;
}


#################################################
## DATA ACCESSORS FOR SAMPLE_ELEMENT_RELATIONS ##
#################################################

=head2 add_source_relation_to_sample_element

  Usage: $sample->add_source_relation_to_sample_element($element_name_A, 
                                                        $element_name_B, 
                                                        $relation_type );

  Desc: Add a new sample_element_relation_row to the sample object
        to associate a new file to a sample element. 

  Ret: None

  Args: $element_name_A, a scalar, element contained in the object
        $element_name_B, a scalar, element to do a new relation 
        $relation_type, a scalar that describes the type of the relation

  Side_Effects: check if exists the element_name in the db, if it don't
                exists, die.

  Example: $sample->add_source_relation_to_sample_element($element_name_A, 
                                                          $element_name_B, 
                                                          $relation_type );

=cut

sub add_source_relation_to_sample_element {
    my $self = shift;

    ## Checking variables

    my $element_name_A = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_source_relation_to_sample_element() function to $self.\n");
    
    my $element_name_B = shift ||
	croak("FUNCTION PARAMETER ERROR: None element_name_B was supplied for $self->add_source_relation_to_sample_element function.\n");

     my $relation_type = shift ||
	croak("FUNCTION PARAMETER ERROR: None relation_type was supplied for $self->add_source_relation_to_sample_element function.\n");

    my ($element_A_id, $element_B_id);

    ## Checking if the element_name_A exists into the object and if it have a sample_element_id
    
    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name_A}) {
	croak("DATA OBJECT COHERENCE ERROR: Element_sample_name=$element_name_A do not exists into the $self object\n");
    }
    else {
	$element_A_id = $bssampleelement_rows{$element_name_A}->get_column('sample_element_id');
	unless (defined $element_A_id) {
	    croak("OBJECT MANIPULATION ERROR: $element_name_A have not any sample_element_id. Probably it hasn't been stored yet\n");
	}
    }

    ## Checking for the element B

    my ($row_B) = $self->get_schema()
	               ->resultset('BsSampleElement')
		       ->search({ sample_element_name => $element_name_B });

    unless (defined($row_B) ) {
	croak("DATABASE COHERENCE ERROR: Sample_element_B parameter for $self->add_file_to_sample_element() do not exist in the db.\n");
    } 
    else {
	$element_B_id = $row_B->get_column('sample_element_id');
    }
  
     ## Checking if exists a row with this data inside the object

    my $is_new = 1;
    my %bselement_source_relation_rows = $self->get_bssampleelementrelation_source_rows();
    
    foreach my $old_elementrelation_row (@{ $bselement_source_relation_rows{$element_name_A} } ) { 	
	my %old_data = $old_elementrelation_row->get_columns();
	if ($old_data{'sample_element_id_a'} == $element_A_id && $old_data{'sample_element_id_b'} == $element_B_id) {

	    $is_new = 0;
	    
	    ## Means that the object exists into the object, so it will check now if the relation_type is the same,
	    ## if not, it will change the relation type (add == edit)
	    
	    unless ($old_data{'relation_type'} eq $relation_type) {

		## It edit it
		$old_elementrelation_row->set_column( relation_type => $relation_type );
	    }
	}
    }

    ## Create the new row with these data if the relation is new
  
    if ($is_new == 1) {

	my $new_elementrelation_row = $self->get_schema()
	                                   ->resultset('BsSampleElementRelation')
		         	           ->new( 
	                                          {
						      sample_element_id_a => $element_A_id,
						      sample_element_id_b => $element_B_id, 
						      relation_type       => $relation_type,
                                                  }
                                                );

	unless (exists $bselement_source_relation_rows{$element_name_A} ) {
	    $bselement_source_relation_rows{$element_name_A} = [$new_elementrelation_row];
	} 
	else {
	    push @{$bselement_source_relation_rows{$element_name_A}}, $new_elementrelation_row;
	}
    }

    $self->set_bssampleelementrelation_source_rows(\%bselement_source_relation_rows);
}


=head2 add_result_relation_to_sample_element

  Usage: $sample->add_result_relation_to_sample_element($element_name_B, 
                                                        $element_name_A, 
                                                        $relation_type );

  Desc: Add a new sample_element_relation_row to the sample object
        to associate a new file to a sample element.
        Also can edit the relation type if exists the relation in the 
        object

  Ret: None

  Args: $element_name_B, a scalar, element contained in the object
        $element_name_A, a scalar, element to do a new relation 
        $relation_type, a scalar that describes the type of the relation

  Side_Effects: check if exists the element_name in the db, if it don't
                exists, die.
                check if exists the relation in the object. If exists check
                if it have the same relation_type, if not, change it (edit)
    

  Example: $sample->add_result_relation_to_sample_element($element_name_B, 
                                                          $element_name_A, 
                                                          $relation_type );

=cut

sub add_result_relation_to_sample_element {
    my $self = shift;

    ## Checking variables

    my $element_name_B = shift ||
	croak("FUNCTION PARAMETER ERROR: None data was supplied for add_result_relation_to_sample_element() function to $self.\n");
    
    my $element_name_A = shift ||
	croak("FUNCTION PARAMETER ERROR: None element_name_A was supplied for $self->add_result_relation_to_sample_element function.\n");

     my $relation_type = shift ||
	croak("FUNCTION PARAMETER ERROR: None relation_type was supplied for $self->add_result_relation_to_sample_element function.\n");

    my ($element_A_id, $element_B_id);

    ## Checking if the element_name_B exists into the object and if it have a sample_element_id
    
    my %bssampleelement_rows = $self->get_bssampleelement_rows();
    
    unless (exists $bssampleelement_rows{$element_name_B}) {
	croak("DATA OBJECT COHERENCE ERROR: Element_sample_name=$element_name_B do not exists into the $self object\n");
    }
    else {
	$element_B_id = $bssampleelement_rows{$element_name_B}->get_column('sample_element_id');
	unless (defined $element_B_id) {
	    croak("OBJECT MANIPULATION ERROR: $element_name_B have not any sample_element_id. Probably it hasn't been stored yet\n");
	}
    }

    ## Checking for the element A

    my ($row_A) = $self->get_schema()
	               ->resultset('BsSampleElement')
		       ->search({ sample_element_name => $element_name_A });

    unless (defined($row_A) ) {
	croak("DATABASE COHERENCE ERROR: Sample_element_A parameter for $self->add_file_to_sample_element() do not exist in the db.\n");
    } 
    else {
	$element_A_id = $row_A->get_column('sample_element_id');
    }

    ## Checking if exists a row with this data inside the object

    my $is_new = 1;
    my %bselement_result_relation_rows = $self->get_bssampleelementrelation_result_rows();
    
     foreach my $old_elementrelation_row_aref (values %bselement_result_relation_rows) {
	foreach my $old_elementrelation_row (@{$old_elementrelation_row_aref}) {
	    my %old_data = $old_elementrelation_row->get_columns();
	    if ($old_data{'sample_element_id_a'} == $element_A_id && $old_data{'sample_element_id_b'} == $element_B_id) {

		$is_new = 0;

		## Means that the object exists into the object, so it will check now if the relation_type is the same,
		## if not, it will change the relation type (add == edit)

		unless ($old_data{'relation_type'} eq $relation_type) {
		    
		    ## It edit it
		    $old_elementrelation_row->set_column( relation_type => $relation_type );
		}
	    }
	}
    }

    ## Create the new row with these data if the relation is new
  
    if ($is_new == 1) {
	my $new_elementrelation_row = $self->get_schema()
	                                   ->resultset('BsSampleElementRelation')
		          	           ->new( 
	                                          {
						     sample_element_id_a => $element_A_id,
						     sample_element_id_b => $element_B_id, 
						     relation_type       => $relation_type,
                                                   }
                                                 );
         
	unless (exists $bselement_result_relation_rows{$element_name_B} ) {
	    $bselement_result_relation_rows{$element_name_B} = [$new_elementrelation_row];
	} 
	else {
	    push @{$bselement_result_relation_rows{$element_name_B}}, $new_elementrelation_row;
	}
    }

    $self->set_bssampleelementrelation_result_rows(\%bselement_result_relation_rows);
}



=head2 get_relations_from_sample_elements

  Usage: my ($source_relations_href, $result_relations_href) = 
             $sample->get_relations_from_sample_elements();

  Desc: Get the relations associated to a sample elements in a sample object.

  Ret: Two hash %source_relations and %result_relations with:
       keys = sample_element_name from the sample_object
       values = array reference with hash references with keys: data_type
                                                          value: value

       (data_type can be: sample_element_id, relation_type and sample_element_name).

  Args: none

  Side_Effects: none

  Example: my ($source_relations_href, $result_relations_href) = 
               $sample->get_relations_from_sample_elements();
           my @sourcerelation_element1 = @{$source_relations_href->{'element1'}};
           foreach my $source_relation (@sourcerelation_element1) {
               my $element_name = $source_relation->{'sample_element_name'};
               my $relation_type = $source_relation->{'relation_type'};
           }

           my $element1_rel = $source_relations_href->{'element1'}
                                                    ->[0]
                                                    ->{'sample_element_name'};
                                                    

=cut

sub get_relations_from_sample_elements {
    my $self = shift;

    my (%source_relations, %result_relations);
    
    my %source_rows = $self->get_bssampleelementrelation_source_rows();
    my %result_rows = $self->get_bssampleelementrelation_result_rows();
    
    my %results = (
                    source_row => \%source_rows,
                    result_row => \%result_rows,
	          );

    foreach my $result (keys %results) {
	my %bselementresult_rows =  %{$results{$result}};
	foreach my $element_name ( keys  %bselementresult_rows ) {
	    my @relation_data;
	    my @rows = @{ $bselementresult_rows{$element_name} };
	    foreach my $row (@rows) {
		my $sample_element_type;
		if ($result eq 'source_row') {
		    $sample_element_type = 'sample_element_id_b';
		}
		else {
		    $sample_element_type = 'sample_element_id_a';
		}
		my $sample_element_id =  $row->get_column($sample_element_type);
		my $relation_type = $row->get_column('relation_type');
		my ($row_sample_element) = $self->get_schema() 
	                	                ->resultset('BsSampleElement')
			    	 	        ->search({ sample_element_id => $sample_element_id });
		my $sample_element_name = $row_sample_element->get_column('sample_element_name');

		my $hashref = { 
		                sample_element_id   => $sample_element_id ,
	                        sample_element_name => $sample_element_name, 
	                        relation_type       => $relation_type, 
		              };

		push @relation_data, $hashref;
	
	    }
	    if ($result eq 'source_row') {
		$source_relations{$element_name} = \@relation_data;
	    }
	    else {
		$result_relations{$element_name} = \@relation_data;
	    }
	}
    }
    

    return (\%source_relations, \%result_relations);
}



#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_sample_metadbdata

  Usage: my $metadbdata = $sample->get_sample_metadbdata();

  Desc: Get metadata object associated to protocol data (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $sample->get_sample_metadbdata();
           my $metadbdata = $sample->get_sample_metadbdata($metadbdata);

=cut

sub get_sample_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_bssample_row
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
      my $sample_id = $self->get_sample_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the sample_id=$sample_id is undefined.\n");
  }
  
  return $metadbdata;
}

=head2 is_sample_obsolete

  Usage: $sample->is_sample_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($sample->is_sample_obsolete()) { ## do something }

=cut

sub is_sample_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_sample_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}


=head2 accessors get_sample_pub_metadbdata

  Usage: my %metadbdata = $sample->get_sample_pub_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=pub_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata) for pub relation

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $sample->get_sample_pub_metadbdata();
           my %metadbdata = $sample->get_sample_pub_metadbdata($metadbdata);

=cut

sub get_sample_pub_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @bssamplepub_rows = $self->get_bssamplepub_rows();

  foreach my $bssamplepub_row (@bssamplepub_rows) {
      my $pub_id = $bssamplepub_row->get_column('pub_id');
      my $metadata_id = $bssamplepub_row->get_column('metadata_id');

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
          my $sample_pub_id = $bssamplepub_row->get_column('sample_pub_id');
	  unless (defined $sample_pub_id) {
	      croak("OBJECT MANIPULATION ERROR: Object $self haven't any sample_pub_id associated. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: The metadata_id for the sample_pub_id=$sample_pub_id is undefined.\n");
	  }
      }
  }
  return %metadbdata;
}

=head2 is_sample_pub_obsolete

  Usage: $sample->is_sample_pub_obsolete($pub_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $pub_id, a publication_id
  
  Side_Effects: none
  
  Example: unless ( $sample->is_sample_pub_obsolete($pub_id) ) { ## do something }

=cut

sub is_sample_pub_obsolete {
  my $self = shift;
  my $pub_id = shift;

  my %metadbdata = $self->get_sample_pub_metadbdata();
  my $metadbdata = $metadbdata{$pub_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}



=head2 accessors get_sample_element_metadbdata

  Usage: my $metadbdata = $sample->get_sample_element_metadbdata();

  Desc: Get metadata object associated to sample_element row 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with key=element_name and value=metadbdata object 
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $sample->get_sample_element_metadbdata();
           my %metadbdata = $sample->get_sample_element_metadbdata($metadbdata);

=cut

sub get_sample_element_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my %sample_elements = $self->get_sample_elements();

  foreach my $element_name (keys %sample_elements) {
      my $metadbdata;
      my $metadata_id = $sample_elements{$element_name}->{'metadata_id'};

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
	  my $sample_id = $self->get_sample_id();
	  unless (defined $sample_id) {
	      croak("OBJECT MANIPULATION ERROR: The object $self haven't any sample_id associated. Probably it hasn't been stored\n");
	  }
	  else {
	      croak("DATABASE INTEGRITY ERROR: metadata_id for sample_element_name=$element_name is undefined.\n");
	  }
      }
  }
  
  return %metadbdata;
}


=head2 is_sample_element_obsolete

  Usage: $sample->is_sample_element_obsolete($element_name);
  
  Desc: Get obsolete field form metadata object associated to 
        sample data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the name for the sample element in the
        object
  
  Side_Effects: none
  
  Example: unless ($sample->is_sample_element_obsolete($element_name)) { ## do something }

=cut

sub is_sample_element_obsolete {
  my $self = shift;
  my $element_name = shift;
  

  if (defined $element_name) {
      my %metadbdata = $self->get_sample_element_metadbdata();
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


=head2 accessors get_element_dbxref_metadbdata

  Usage: my %metadbdata = $sample->get_element_dbxref_metadbdata();

  Desc: Get metadata object associated to sample element data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=sample_element_name
                    values=hash reference with:
                        keys=dbxref_id
                        values=metadbdata object
                        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $sample->get_element_dbxref_metadbdata();
           my %metadbdata = $sample->get_element_dbxref_metadbdata($metadbdata);

=cut


sub get_element_dbxref_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata = (); 
  my %bselementdbxref_rows = $self->get_bssampleelementdbxref_rows();

  foreach my $element_name (keys %bselementdbxref_rows) {
      
      my @bselementdbxref_rows = @{$bselementdbxref_rows{$element_name}}; 
      my %dbxref_metadbdata_relation = ();

      foreach my $bselementdbxref_row (@bselementdbxref_rows) {
	  my $metadata_id = $bselementdbxref_row->get_column('metadata_id');
	  my $dbxref_id = $bselementdbxref_row->get_column('dbxref_id');

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
	      my $element_dbxref_id = $bselementdbxref_row->get_column('sample_element_dbxref_id');
	      unless (defined $element_dbxref_id) {
		  croak("OBJECT MANIPULATION ERROR:It haven't any sample_element_dbxref_id associated. Probably it hasn't been stored\n");
	      }
	      else {
		  croak("DATABASE INTEGRITY ERROR: Metadata_id for sample_element_dbxref_id=$element_dbxref_id is undefined.\n");
	      }
	  }
      }
      $metadbdata{$element_name} = \%dbxref_metadbdata_relation;
  }
  return %metadbdata;
}

=head2 is_element_dbxref_obsolete

  Usage: $protocol->is_element_dbxref_obsolete($element_name, $dbxref_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the element that have associated 
        the dbxref relation
        $dbxref_id, another integer with the dbxref_id of the relation
  
  Side_Effects: none
  
  Example: unless ($protocol->is_element_dbxref_obsolete($name, $dbxref_id)) {
                     ## do something 
                   }

=cut

sub is_element_dbxref_obsolete {
  my $self = shift;
  my $element_name = shift;
  my $dbxref_id = shift;

  my %metadbdata = $self->get_element_dbxref_metadbdata();
  my $metadbdata = $metadbdata{$element_name}->{$dbxref_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}


=head2 accessors get_element_cvterm_metadbdata

  Usage: my %metadbdata = $sample->get_element_cvterm_metadbdata();

  Desc: Get metadata object associated to sample element data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=sample_element_name
                    values=hash reference with:
                        keys=cvterm_id
                        values=metadbdata object
                        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $sample->get_element_cvterm_metadbdata();
           my %metadbdata = $sample->get_element_cvterm_metadbdata($metadbdata);

=cut


sub get_element_cvterm_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata = (); 
  my %bselementcvterm_rows = $self->get_bssampleelementcvterm_rows();

  foreach my $element_name (keys %bselementcvterm_rows) {
      
      my @bselementcvterm_rows = @{$bselementcvterm_rows{$element_name}}; 
      my %cvterm_metadbdata_relation = ();

      foreach my $bselementcvterm_row (@bselementcvterm_rows) {
	  my $metadata_id = $bselementcvterm_row->get_column('metadata_id');
	  my $cvterm_id = $bselementcvterm_row->get_column('cvterm_id');

	  if (defined $metadata_id) {
	      my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	      if (defined $metadata_obj_base) {

		  ## This will transfer the creation data from the base object to the new one
		  $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
		  $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	      }
	 
	      $cvterm_metadbdata_relation{$cvterm_id} = $metadbdata;
	  } 
	  else {
	      my $element_cvterm_id = $bselementcvterm_row->get_column('sample_element_cvterm_id');
	      unless (defined $element_cvterm_id) {
		  croak("OBJECT MANIPULATION ERROR:It haven't any sample_element_cvterm_id associated. Probably it hasn't been stored\n");
	      }
	      else {
		  croak("DATABASE INTEGRITY ERROR: Metadata_id for sample_element_cvterm_id=$element_cvterm_id is undefined.\n");
	      }
	  }
      }
      $metadbdata{$element_name} = \%cvterm_metadbdata_relation;
  }
  return %metadbdata;
}

=head2 is_element_cvterm_obsolete

  Usage: $protocol->is_element_cvterm_obsolete($element_name, $cvterm_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the element that have associated 
        the cvterm relation
        $cvterm_id, another integer with the cvterm_id of the relation
  
  Side_Effects: none
  
  Example: unless ($protocol->is_element_cvterm_obsolete($name, $cvterm_id)) {
                     ## do something 
                   }

=cut

sub is_element_cvterm_obsolete {
  my $self = shift;
  my $element_name = shift;
  my $cvterm_id = shift;

  my %metadbdata = $self->get_element_cvterm_metadbdata();
  my $metadbdata = $metadbdata{$element_name}->{$cvterm_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}


=head2 accessors get_element_file_metadbdata

  Usage: my %metadbdata = $sample->get_element_file_metadbdata();

  Desc: Get metadata object associated to sample element data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=sample_element_name
                    values=hash reference with:
                        keys=file_id
                        values=metadbdata object
                        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $sample->get_element_file_metadbdata();
           my %metadbdata = $sample->get_element_file_metadbdata($metadbdata);

=cut


sub get_element_file_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata = (); 
  my %bselementfile_rows = $self->get_bssampleelementfile_rows();

  foreach my $element_name (keys %bselementfile_rows) {
      
      my @bselementfile_rows = @{$bselementfile_rows{$element_name}}; 
      my %file_metadbdata_relation = ();

      foreach my $bselementfile_row (@bselementfile_rows) {
	  my $metadata_id = $bselementfile_row->get_column('metadata_id');
	  my $file_id = $bselementfile_row->get_column('file_id');
	  

	  if (defined $metadata_id) {
	      my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
	      if (defined $metadata_obj_base) {

		  ## This will transfer the creation data from the base object to the new one
		  $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
		  $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
	      }
	      $file_metadbdata_relation{$file_id} = $metadbdata;
	  } 
	  else {
	      my $element_file_id = $bselementfile_row->get_column('sample_element_file_id');
	      unless (defined $element_file_id) {
		  croak("OBJECT MANIPULATION ERROR:It haven't any sample_element_file_id associated. Probably it hasn't been stored\n");
	      }
	      else {
		  croak("DATABASE INTEGRITY ERROR: Metadata_id for sample_element_file_id=$element_file_id is undefined.\n");
	      }
	  }
      }
      $metadbdata{$element_name} = \%file_metadbdata_relation;
  }
  return %metadbdata;
}

=head2 is_element_file_obsolete

  Usage: $protocol->is_element_file_obsolete($element_name, $file_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the element that have associated 
        the file relation
        $file_id, another integer with the file_id of the relation
  
  Side_Effects: none
  
  Example: unless ($protocol->is_element_file_obsolete($name, $file_id)) {
                     ## do something 
                   }

=cut

sub is_element_file_obsolete {
  my $self = shift;
  my $element_name = shift;
  my $file_id = shift;

  my %metadbdata = $self->get_element_file_metadbdata();
  my $metadbdata = $metadbdata{$element_name}->{$file_id};
  
  my $obsolete = 0;
  if (defined $metadbdata) {
      $obsolete = $metadbdata->get_obsolete() || 0;
  }
  return $obsolete;
}

=head2 accessors get_element_relation_metadbdata

  Usage: my ($mtdb_source_href, $mtdb_result_href) = 
                        $sample->get_element_relation_metadbdata();
        
         my ($mtdb_source_href, $mtdb_result_href) = 
                        $sample->get_element_relation_metadbdata($metadbdata);

         my %mtdb_source = 
               $sample->get_element_relation_metadbdata($metadbdata, 'source');

         my %mtdb_result = 
               $sample->get_element_relation_metadbdata($metadbdata, 'result');


  Desc: Get metadata object associated to sample element data 
        (see CXGN::Metadata::Metadbdata). 

  Ret: In the normal context (without tag use):
         A hash with keys=sample_element_name
                     values=hash reference with:
                        keys=sample_element_id related
                        values=metadbdata object
                        (CXGN::Metadata::Metadbdata)

       With a specified tag as second argument, an array with two hash references
       with the same structure: keys=sample_element_name
                                values=hash reference with:
                                   keys=sample_element_id related
                                   values=metadbdata object
                                   (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables
        Optional, a tag 'source' or 'result' to get only the metadbdata for this 
        relation type in a hash context

  Side_Effects: none

  Example:  my ($mtdb_source_href, $mtdb_result_href) = 
                        $sample->get_element_relation_metadbdata();
        
            my ($mtdb_source_href, $mtdb_result_href) = 
                        $sample->get_element_relation_metadbdata($metadbdata);

            my %mtdb_source = 
               $sample->get_element_relation_metadbdata($metadbdata, 'source');

            my %mtdb_result = 
               $sample->get_element_relation_metadbdata($metadbdata, 'result');

=cut


sub get_element_relation_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  my $relation_type = shift;

  my (%metadbdata_source, %metadbdata_result);
  
  my %bselementrelation_source_rows = $self->get_bssampleelementrelation_source_rows();
  my %bselementrelation_result_rows = $self->get_bssampleelementrelation_result_rows();

  my %relation_rows = (
                          source => \%bselementrelation_source_rows,
	                  result => \%bselementrelation_result_rows,
	                );
    
  foreach my $relation_kind (keys %relation_rows) {

      my %bselementrelation_aref = %{$relation_rows{$relation_kind}};

      foreach my $element_name (keys %bselementrelation_aref) {
 
	  my @bselementrelation_rows = @{$bselementrelation_aref{$element_name}}; 
	  my %relation_metadbdata_relation = ();
	  
	  foreach my $bselementrelation_row (@bselementrelation_rows) {
	      my $metadata_id = $bselementrelation_row->get_column('metadata_id');

	      my $sample_element_related_id;
	      if ($relation_kind eq 'source') {
		  $sample_element_related_id = $bselementrelation_row->get_column('sample_element_id_b');
	      }
	      else {
		  $sample_element_related_id = $bselementrelation_row->get_column('sample_element_id_a');
	      }

	      my ($sample_element_row) = $self->get_schema()
		                              ->resultset('BsSampleElement')
		                              ->search( { sample_element_id => $sample_element_related_id } );
	      
	      my $sample_element_related_name = $sample_element_row->get_column('sample_element_name');

	      if (defined $metadata_id) {
		  my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), undef, $metadata_id);
		  if (defined $metadata_obj_base && ref($metadata_obj_base) eq 'CXGN::Metadata::Metadbdata') {
		      
		      ## This will transfer the creation data from the base object to the new one
		      $metadbdata->set_object_creation_date($metadata_obj_base->get_object_creation_date());
		      $metadbdata->set_object_creation_user($metadata_obj_base->get_object_creation_user());
		  }
		  $relation_metadbdata_relation{$sample_element_related_name} = $metadbdata;
	      } 
	      else {
		  my $element_relation_id = $bselementrelation_row->get_column('sample_element_relation_id');
		  unless (defined $element_relation_id) {
		      croak("OBJECT MANIPULATION ERROR:It haven't any sample_element_relation_id associated. It hasn't been stored\n");
		  }
		  else {
		      croak("DATABASE INTEGRITY ERROR: Metadata_id for sample_element_relation_id=$element_relation_id undef.\n");
		  }
	      }
	  }
	  if ($relation_kind eq 'source') {
	      $metadbdata_source{$element_name} = \%relation_metadbdata_relation;
	  }
	  elsif ($relation_kind eq 'result') {
	      $metadbdata_result{$element_name} = \%relation_metadbdata_relation;
	  }
      }
  }
  if (defined $relation_type && $relation_type =~ m/^source$/i) {
	  return %metadbdata_source;
      }
      elsif (defined $relation_type && $relation_type =~ m/^result$/i) {
	  return %metadbdata_result;
      }
  else {
      return (\%metadbdata_source, \%metadbdata_result);
  }
}

=head2 is_element_relation_obsolete

  Usage: $protocol->is_element_relation_obsolete( $element_name, 
                                                         $related_element_name);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $element_name, a scalar, the element that have associated 
        the file relation
        $file_id, another integer with the file_id of the relation
  
  Side_Effects: none
  
  Example: unless ($protocol->is_element_relation_obsolete($name, $rel_name)){
                     ## do something 
                   }

=cut

sub is_element_relation_obsolete {
  my $self = shift;
  my $element_name = shift;
  my $related_element_name = shift;
  
  my $metadbdata;
  
  my @metadbdata_href = $self->get_element_relation_metadbdata();
  
  foreach my $metadbdata_reltype (@metadbdata_href) {
      if (defined $metadbdata_reltype->{$element_name}) {
	  if (defined $metadbdata_reltype->{$element_name}->{$related_element_name}) {
	      $metadbdata = $metadbdata_reltype->{$element_name}->{$related_element_name};	  
	  }
      }
  }
  
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

  Usage: my $sample = $sample->store($metadbdata);
 
  Desc: Store in the database the all sample data for the sample object
       (sample, sample_element, sample_pub, sample_element_dbxref 
        and sample_element_cvterm rows)
       See the methods store_sample, store_sample_elements 
       store_pub_associations, store_element_dbxref_associations, 
       and store_cvterm_associations.

  Ret: $sample, the sample object
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store($metadata);

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

    $self->store_sample($metadata)
	 ->store_sample_elements($metadata)
	 ->store_pub_associations($metadata)
	 ->store_element_dbxref_associations($metadata)
         ->store_element_cvterm_associations($metadata);

    return $self;
}



=head2 store_sample

  Usage: my $sample = $sample->store_sample($metadata);
 
  Desc: Store in the database the sample data for the sample object
       (Only the bssample row, don't store any sample_element or 
        sample_pub data)
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_sample($metadata);

=cut

sub store_sample {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store_sample().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store_sample() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_id. 
    ##   if exists sample_id         => update
    ##   if do not exists sample_id  => insert

    my $bssample_row = $self->get_bssample_row();
    my $sample_id = $bssample_row->get_column('sample_id');

    unless (defined $sample_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$bssample_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$bssample_row->insert()
                     ->discard_changes();                           ## It will set the row with the updated row
	
	## Now we set the sample_id value for all the rows that depends of it as sample_element rows

	my %bssampleelement_rows = $self->get_bssampleelement_rows();
	foreach my $bssampleelement_row (values %bssampleelement_rows) {
	    $bssampleelement_row->set_column( sample_id => $bssample_row->get_column('sample_id'));
	}

	my @bssamplepub_rows = $self->get_bssamplepub_rows();
	foreach my $bssamplepub_row (@bssamplepub_rows) {
	    $bssamplepub_row->set_column( sample_id => $bssample_row->get_column('sample_id'));
	}
                    
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $bssample_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_sample_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $bssample_row->set_column( metadata_id => $mod_metadata_id );

	    $bssample_row->update()
                         ->discard_changes();
	}
    }
    return $self;    
}


=head2 obsolete_sample

  Usage: my $sample = $sample->obsolete_sample($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_sample($metadata, 'change to obsolete test');

=cut

sub obsolete_sample {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_sample().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_sample is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_sample().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_sample_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $bssample_row = $self->get_bssample_row();

    $bssample_row->set_column( metadata_id => $mod_metadata_id );
         
    $bssample_row->update()
	           ->discard_changes();

    return $self;
}


=head2 store_pub_associations

  Usage: my $sample = $sample->store_pub_associations($metadata);
 
  Desc: Store in the database the pub association for the sample object
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_pub_associations($metadata);

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

    ## SECOND, check if exists or not sample_pub_id. 
    ##   if exists sample_pub_id         => update
    ##   if do not exists sample_pub_id  => insert

    my @bssamplepub_rows = $self->get_bssamplepub_rows();
    
    foreach my $bssamplepub_row (@bssamplepub_rows) {
        
        my $sample_pub_id = $bssamplepub_row->get_column('sample_pub_id');
	my $pub_id = $bssamplepub_row->get_column('pub_id');

        unless (defined $sample_pub_id) {                                   ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $bssamplepub_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
            $bssamplepub_row->insert()
                            ->discard_changes();                            ## It will set the row with the updated row
                            
        } 
        else {                                                                ## UPDATE IF SOMETHING has change
        
            my @columns_changed = $bssamplepub_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %aspub_metadata = $self->get_sample_pub_metadbdata($metadata);
		my $mod_metadata_id = $aspub_metadata{$pub_id}->store({ modification_note => $modification_note })
                                                              ->get_metadata_id(); 

                $bssamplepub_row->set_column( metadata_id => $mod_metadata_id );

                $bssamplepub_row->update()
                                  ->discard_changes();
            }
        }
    }
    return $self;    
}

=head2 obsolete_pub_association

  Usage: my $sample = $sample->obsolete_pub_association($metadata, $note, $pub_id, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $pub_id, a publication id associated to this tool
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_pub_association($metadata, 
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
    
    my %aspub_metadata = $self->get_sample_pub_metadbdata($metadata);
    my $mod_metadata_id = $aspub_metadata{$pub_id}->store( { modification_note => $modification_note,
							     obsolete          => $obsolete, 
							     obsolete_note     => $obsolete_note } )
                                                  ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @bssamplepub_rows = $self->get_bssamplepub_rows();
    foreach my $bssamplepub_row (@bssamplepub_rows) {
	if ($bssamplepub_row->get_column('pub_id') == $pub_id) {

	    $bssamplepub_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bssamplepub_row->update()
	                    ->discard_changes();
	}
    }
    return $self;
}


=head2 store_sample_elements

  Usage: my $sample = $sample->store_sample_elements($metadata);
 
  Desc: Store in the database sample_elements associated to a sample
 
  Ret: $sample, a sample object (CXGN::Biosource::Sample)
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_sample_elements($metadata);

=cut

sub store_sample_elements {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_sample_elements().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_sample_elements() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_elements_id. 
    ##   if exists sample_elements_id         => update
    ##   if do not exists sample_elements_id  => insert

    my %bssampleelements_rows = $self->get_bssampleelement_rows();
    
    foreach my $bssampleelement_row (values %bssampleelements_rows) {
        my $sample_element_id = $bssampleelement_row->get_column('sample_element_id');
	my $sample_id =  $bssampleelement_row->get_column('sample_id');

	unless (defined $sample_id) {
	    croak("STORE ERROR: Don't exist sample_id associated to this step. Use store_sample before use store_sample_elements.\n");
	}

        unless (defined $sample_element_id) {                                  ## NEW INSERT and DISCARD CHANGES
        
            my $metadata_id = $metadata->store()
                                       ->get_metadata_id();

            $bssampleelement_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
            $bssampleelement_row->insert()
                                ->discard_changes();                           ## It will set the row with the updated row


	    ## Now it will set the sample_element_id value for all the rows that depends of it as sample_element_dbxref or
            ## sample_element_cvterm
	    
	    my %bssampleelementdbxref_rows = $self->get_bssampleelementdbxref_rows();
	    foreach my $bselementdbxref_row_aref (values %bssampleelementdbxref_rows) {
		foreach my $bselementdbxref_row (@{$bselementdbxref_row_aref}) {
		    $bselementdbxref_row->set_column( sample_element_id => $bssampleelement_row->get_column('sample_element_id'));
		}
	    }

	    my %bssampleelementcvterm_rows = $self->get_bssampleelementcvterm_rows();
	    foreach my $bselementcvterm_row_aref (values %bssampleelementcvterm_rows) {
		foreach my $bselementcvterm_row (@{$bselementcvterm_row_aref}) {
		    $bselementcvterm_row->set_column( sample_element_id => $bssampleelement_row->get_column('sample_element_id'));
		}  
	    }
        }  
        else {                                                                 ## UPDATE IF SOMETHING has change
       
            my @columns_changed = $bssampleelement_row->is_changed();
        
            if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
           
                my @modification_note_list;                             ## the changes and the old metadata object for
                foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
                    push @modification_note_list, "set value in $col_changed column";
                }
                
                my $modification_note = join ', ', @modification_note_list;
           
		my %se_metadata = $self->get_sample_element_metadbdata($metadata);
		my $element_name = $bssampleelement_row->get_column('sample_element_name');
                my $mod_metadata_id = $se_metadata{$element_name}->store({ modification_note => $modification_note })
                                                                 ->get_metadata_id(); 

                $bssampleelement_row->set_column( metadata_id => $mod_metadata_id );

                $bssampleelement_row->update()
                                    ->discard_changes();
            }
        }
    }
    return $self;    
}


=head2 obsolete_sample_element

  Usage: my $sample = $sample->obsolete_sample_element( $metadata, 
                                                        $note, 
                                                        $element_name, 
                                                        'REVERT'
                                                      );
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will 
        be reverted to 0 (false)
 
  Ret: $target, the target object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $element_name, the sample_element_name that identify this sample_element
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_sample_element( $metadata, 
                                                          change to obsolete', 
                                                          $element_name );

=cut

sub obsolete_sample_element {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
        || croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_sample_element().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_sample_element is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
        || croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_sample_element().\n");

    my $element_name = shift 
        || croak("OBSOLETE ERROR: None sample_element_name was supplied to $self->obsolete_sample_element().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
        $obsolete = 0;
        $modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my %sample_element_metadata = $self->get_sample_element_metadbdata($metadata);
    my $mod_metadata_id = $sample_element_metadata{$element_name}->store( { 
	                                                                    modification_note => $modification_note,
									    obsolete          => $obsolete, 
									    obsolete_note     => $obsolete_note 
                                                                          } )
                                                                 ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bssampleelement_rows = $self->get_bssampleelement_rows();
       
    $bssampleelement_rows{$element_name}->set_column( metadata_id => $mod_metadata_id );
    
    $bssampleelement_rows{$element_name}->update()
	                                ->discard_changes();
    
    return $self;
}


=head2 store_element_dbxref_associations

  Usage: my $sample = $sample->store_element_dbxref_associations($metadata);
 
  Desc: Store in the database the element dbxref association 
        for the sample object
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_element_dbxref_associations($metadata);

=cut

sub store_element_dbxref_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_element_dbxref_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_element_dbxref_associations() is not CXGN::Metadata::Metadbdata obj.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_element_dbxref_id. 
    ##   if exists sample_element_dbxref_id         => update
    ##   if do not exists sample_element_dbxref_id  => insert

    my %bselementdbxref_rows_aref = $self->get_bssampleelementdbxref_rows();
    
    foreach my $element_name (keys %bselementdbxref_rows_aref) {
        
	my @bselementdbxref_rows = @{$bselementdbxref_rows_aref{$element_name}};

	foreach my $bselementdbxref_row (@bselementdbxref_rows) {

	    my $sample_element_dbxref_id = $bselementdbxref_row->get_column('sample_element_dbxref_id');
	    my $dbxref_id = $bselementdbxref_row->get_column('dbxref_id');

	    unless (defined $sample_element_dbxref_id) {                          ## NEW INSERT and DISCARD CHANGES
        
		my $metadata_id = $metadata->store()
		                           ->get_metadata_id();

		$bselementdbxref_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
		$bselementdbxref_row->insert()
		                    ->discard_changes();                            ## It will set the row with the updated row
                            
	    } 
	    else {                                                               ## UPDATE IF SOMETHING has change
        
		my @columns_changed = $bselementdbxref_row->is_changed();
        
		if (scalar(@columns_changed) > 0) {                              ## ...something has change, it will take
           
		    my @modification_note_list;                             ## the changes and the old metadata object for
		    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
			push @modification_note_list, "set value in $col_changed column";
		    }
                
		    my $modification_note = join ', ', @modification_note_list;
           
		    my %elementdbxref_metadata = $self->get_element_dbxref_metadbdata($metadata);
		    my $mod_metadata_id = $elementdbxref_metadata{$element_name}->{$dbxref_id}
                                                                                ->store({ modification_note => $modification_note })
                                                                                ->get_metadata_id(); 

		    $bselementdbxref_row->set_column( metadata_id => $mod_metadata_id );

		    $bselementdbxref_row->update()
			                ->discard_changes();
		}
            }
        }
    }
    return $self;    
}

=head2 obsolete_element_dbxref_association

  Usage: my $sample = $sample->obsolete_element_dbxref_association($metadata, 
                                                                   $note, 
                                                                   $elementname, 
                                                                   $dbxref_id, 
                                                                   'REVERT');
 
  Desc: Change the status of a data association to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $elementname, the sample_element_name that have associated the dbxref_id
        $dbxref_id, the external reference associated to sample_element 
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_element_dbxref_association(
                                                      $metadata,
                                                      'change to obsolete',
                                                      $element_name,
                                                      $dbxref_id,
                                                      );

=cut

sub obsolete_element_dbxref_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_element_dbxref_association().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied $self->obsolete_element_dbxref_association isn't CXGN::Metadata::Metadbdata.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_element_dbxref_association().\n");

    my $element_name = shift 
	|| croak("OBSOLETE ERROR: None element_name was supplied to $self->obsolete_element_dbxref_association().\n");

    my $dbxref_id = shift 
	|| croak("OBSOLETE ERROR: None dbxref_id was supplied to $self->obsolete_element_dbxref_association().\n");


    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag
    
    my %elementdbxref_metadata = $self->get_element_dbxref_metadbdata($metadata);
    my $metadbdata = $elementdbxref_metadata{$element_name}->{$dbxref_id};
    unless (defined $metadbdata) {
	croak("DATA COHERENCE ERROR: Don't exists any element_dbxref relation with $element_name and $dbxref_id inside $self obj.\n")
    }
    my $mod_metadata_id = $metadbdata->store( { 
	                                        modification_note => $modification_note,
						obsolete          => $obsolete, 
						obsolete_note     => $obsolete_note 
                                             } )
                                             ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bselementdbxref_rows_aref = $self->get_bssampleelementdbxref_rows();
    my @bselementdbxref_rows = @{$bselementdbxref_rows_aref{$element_name}};

    foreach my $bselementdbxref_row (@bselementdbxref_rows) {
	if ($bselementdbxref_row->get_column('dbxref_id') == $dbxref_id) {

	    $bselementdbxref_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bselementdbxref_row->update()
	                        ->discard_changes();
	}
    }
    return $self;
}


=head2 store_element_cvterm_associations

  Usage: my $sample = $sample->store_element_cvterm_associations($metadata);
 
  Desc: Store in the database the element cvterm association 
        for the sample object
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_element_cvterm_associations($metadata);

=cut

sub store_element_cvterm_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_element_cvterm_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_element_cvterm_associations() is not CXGN::Metadata::Metadbdata obj.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_element_cvterm_id. 
    ##   if exists sample_element_cvterm_id         => update
    ##   if do not exists sample_element_cvterm_id  => insert

    my %bselementcvterm_rows_aref = $self->get_bssampleelementcvterm_rows();
    
    foreach my $element_name (keys %bselementcvterm_rows_aref) {
        
	my @bselementcvterm_rows = @{$bselementcvterm_rows_aref{$element_name}};

	foreach my $bselementcvterm_row (@bselementcvterm_rows) {

	    my $sample_element_cvterm_id = $bselementcvterm_row->get_column('sample_element_cvterm_id');
	    my $cvterm_id = $bselementcvterm_row->get_column('cvterm_id');

	    unless (defined $sample_element_cvterm_id) {                          ## NEW INSERT and DISCARD CHANGES
        
		my $metadata_id = $metadata->store()
		                           ->get_metadata_id();

		$bselementcvterm_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
		$bselementcvterm_row->insert()
		                    ->discard_changes();                            ## It will set the row with the updated row
                            
	    } 
	    else {                                                               ## UPDATE IF SOMETHING has change
        
		my @columns_changed = $bselementcvterm_row->is_changed();
        
		if (scalar(@columns_changed) > 0) {                              ## ...something has change, it will take
           
		    my @modification_note_list;                             ## the changes and the old metadata object for
		    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
			push @modification_note_list, "set value in $col_changed column";
		    }
                
		    my $modification_note = join ', ', @modification_note_list;
           
		    my %elementcvterm_metadata = $self->get_element_cvterm_metadbdata($metadata);
		    my $mod_metadata_id = $elementcvterm_metadata{$element_name}->{$cvterm_id}
                                                                                ->store({ modification_note => $modification_note })
                                                                                ->get_metadata_id(); 

		    $bselementcvterm_row->set_column( metadata_id => $mod_metadata_id );

		    $bselementcvterm_row->update()
			                ->discard_changes();
		}
            }
        }
    }
    return $self;    
}


=head2 obsolete_element_cvterm_association

  Usage: my $sample = $sample->obsolete_element_cvterm_association($metadata, 
                                                                   $note, 
                                                                   $elementname, 
                                                                   $cvterm_id, 
                                                                   'REVERT');
 
  Desc: Change the status of a data association to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $elementname, the sample_element_name that have associated the cvterm_id
        $cvterm_id, the cvterm_id associated to sample_element 
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_element_cvterm_association(
                                                      $metadata,
                                                      'change to obsolete',
                                                      $element_name,
                                                      $cvterm_id,
                                                      );

=cut

sub obsolete_element_cvterm_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_element_cvterm_association().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied $self->obsolete_element_cvterm_association isn't CXGN::Metadata::Metadbdata.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_element_cvterm_association().\n");

    my $element_name = shift 
	|| croak("OBSOLETE ERROR: None element_name was supplied to $self->obsolete_element_cvterm_association().\n");

    my $cvterm_id = shift 
	|| croak("OBSOLETE ERROR: None cvterm_id was supplied to $self->obsolete_element_cvterm_association().\n");


    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag
    
    my %elementcvterm_metadata = $self->get_element_cvterm_metadbdata($metadata);
    my $metadbdata = $elementcvterm_metadata{$element_name}->{$cvterm_id};
    unless (defined $metadbdata) {
	croak("DATA COHERENCE ERROR: Don't exists any element_cvterm relation with $element_name and $cvterm_id inside $self obj.\n")
    }
    my $mod_metadata_id = $metadbdata->store( { 
	                                        modification_note => $modification_note,
						obsolete          => $obsolete, 
						obsolete_note     => $obsolete_note 
                                             } )
                                             ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bselementcvterm_rows_aref = $self->get_bssampleelementcvterm_rows();
    my @bselementcvterm_rows = @{$bselementcvterm_rows_aref{$element_name}};

    foreach my $bselementcvterm_row (@bselementcvterm_rows) {
	if ($bselementcvterm_row->get_column('cvterm_id') == $cvterm_id) {

	    $bselementcvterm_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bselementcvterm_row->update()
	                        ->discard_changes();
	}
    }
    return $self;
}


=head2 store_element_file_associations

  Usage: my $sample = $sample->store_element_file_associations($metadata);
 
  Desc: Store in the database the element file association 
        for the sample object
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_element_file_associations($metadata);

=cut

sub store_element_file_associations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_element_file_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_element_file_associations() is not CXGN::Metadata::Metadbdata obj.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_element_file_id. 
    ##   if exists sample_element_file_id         => update
    ##   if do not exists sample_element_file_id  => insert

    my %bselementfile_rows_aref = $self->get_bssampleelementfile_rows();
    
    foreach my $element_name (keys %bselementfile_rows_aref) {
        
	my @bselementfile_rows = @{$bselementfile_rows_aref{$element_name}};

	foreach my $bselementfile_row (@bselementfile_rows) {

	    my $sample_element_file_id = $bselementfile_row->get_column('sample_element_file_id');
	    my $file_id = $bselementfile_row->get_column('file_id');

	    unless (defined $sample_element_file_id) {                          ## NEW INSERT and DISCARD CHANGES
        
		my $metadata_id = $metadata->store()
		                           ->get_metadata_id();

		$bselementfile_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
		$bselementfile_row->insert()
		                    ->discard_changes();                            ## It will set the row with the updated row
                            
	    } 
	    else {                                                               ## UPDATE IF SOMETHING has change
        
		my @columns_changed = $bselementfile_row->is_changed();
        
		if (scalar(@columns_changed) > 0) {                              ## ...something has change, it will take
           
		    my @modification_note_list;                             ## the changes and the old metadata object for
		    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
			push @modification_note_list, "set value in $col_changed column";
		    }
                
		    my $modification_note = join ', ', @modification_note_list;
           
		    my %elementfile_metadata = $self->get_element_file_metadbdata($metadata);
		    my $mod_metadata_id = $elementfile_metadata{$element_name}->{$file_id}
                                                                                ->store({ modification_note => $modification_note })
                                                                                ->get_metadata_id(); 

		    $bselementfile_row->set_column( metadata_id => $mod_metadata_id );

		    $bselementfile_row->update()
			                ->discard_changes();
		}
            }
        }
    }
    return $self;    
}

=head2 obsolete_element_file_association

  Usage: my $sample = $sample->obsolete_element_file_association($metadata, 
                                                                   $note, 
                                                                   $elementname, 
                                                                   $file_id, 
                                                                   'REVERT');
 
  Desc: Change the status of a data association to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $elementname, the sample_element_name that have associated the file_id
        $file_id, the file_id associated to sample_element 
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_element_file_association(
                                                      $metadata,
                                                      'change to obsolete',
                                                      $element_name,
                                                      $file_id,
                                                      );

=cut

sub obsolete_element_file_association {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_element_file_association().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied $self->obsolete_element_file_association isn't CXGN::Metadata::Metadbdata.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_element_file_association().\n");

    my $element_name = shift 
	|| croak("OBSOLETE ERROR: None element_name was supplied to $self->obsolete_element_file_association().\n");

    my $file_id = shift 
	|| croak("OBSOLETE ERROR: None file_id was supplied to $self->obsolete_element_file_association().\n");


    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag
    
    my %elementfile_metadata = $self->get_element_file_metadbdata($metadata);
    my $metadbdata = $elementfile_metadata{$element_name}->{$file_id};
    unless (defined $metadbdata) {
	croak("DATA COHERENCE ERROR: Don't exists any element_file relation with $element_name and $file_id inside $self obj.\n")
    }
    my $mod_metadata_id = $metadbdata->store( { 
	                                        modification_note => $modification_note,
						obsolete          => $obsolete, 
						obsolete_note     => $obsolete_note 
                                             } )
                                             ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my %bselementfile_rows_aref = $self->get_bssampleelementfile_rows();
    my @bselementfile_rows = @{$bselementfile_rows_aref{$element_name}};

    foreach my $bselementfile_row (@bselementfile_rows) {
	if ($bselementfile_row->get_column('file_id') == $file_id) {

	    $bselementfile_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bselementfile_row->update()
	                        ->discard_changes();
	}
    }
    return $self;
}


=head2 store_element_relations

  Usage: my $sample = $sample->store_element_relations($metadata);
 
  Desc: Store in the database the element relation association 
        for the sample object
 
  Ret: $sample, the sample object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $sample = $sample->store_element_relations($metadata);

=cut

sub store_element_relations {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
        || croak("STORE ERROR: None metadbdata object was supplied to $self->store_element_relation_associations().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
        croak("STORE ERROR: Metadbdata supplied to $self->store_element_relation_associations() isnot CXGN::Metadata::Metadbdata obj.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not sample_element_file_id. 
    ##   if exists sample_element_relation_id         => update
    ##   if do not exists sample_element_relation_id  => insert

    my %bselementrelation_source_rows_aref = $self->get_bssampleelementrelation_source_rows();
    my %bselementrelation_result_rows_aref = $self->get_bssampleelementrelation_result_rows();
    
    my %relation_rows = (
	                  source => \%bselementrelation_source_rows_aref,
	                  result => \%bselementrelation_result_rows_aref,
	                );
    
    foreach my $relation_kind (keys %relation_rows) {

	my $bselementrelation_aref = $relation_rows{$relation_kind};
	
	foreach my $element_name (keys %{$bselementrelation_aref}) {

	    my @bselementrelation_rows = @{$bselementrelation_aref->{$element_name}};
	    my $a_index = 0;
	    foreach my $bselementrelation_row (@bselementrelation_rows) {
		my $sample_element_relation_id = $bselementrelation_row->get_column('sample_element_relation_id');
		my $sample_element_id_a = $bselementrelation_row->get_column('sample_element_id_a');
		my $sample_element_id_b = $bselementrelation_row->get_column('sample_element_id_b');
		my $relation_type = $bselementrelation_row->get_column('relation_type');

		## Get the sample related name to use with the metadbdata function

		my $related_element_name;

		if ($relation_kind eq 'source') {
		    my ($elsample_row_a) = $self->get_schema()
			                        ->resultset('BsSampleElement')
					        ->search({ sample_element_id => $sample_element_id_b });
		    $related_element_name = $elsample_row_a->get_column('sample_element_name');
		}
		elsif ($relation_kind eq 'result') {
		     my ($elsample_row_a) = $self->get_schema()
			                         ->resultset('BsSampleElement')
					         ->search({ sample_element_id => $sample_element_id_a });
		     $related_element_name = $elsample_row_a->get_column('sample_element_name');
		}

		## Check if there are any relation with the same sample_element_id_a and sample_element_id_b 
		## (the relations can be added using source or result way, from this or other object so, this is a way
		## to control the redundancy)

		my ($relation_row) = $self->get_schema()
		                          ->resultset('BsSampleElementRelation')
				          ->search(
		                                    { 
						       sample_element_id_a =>  $sample_element_id_a,
						       sample_element_id_b =>  $sample_element_id_b,
						    }
				                  );
		if (defined $relation_row) {

		    ## get the sample_element_id and metadata_id and transfer to the row
		    $sample_element_relation_id = $relation_row->get_column('sample_element_relation_id');     
		    $relation_row->set_column( relation_type => $relation_type );
		    $bselementrelation_row = $relation_row;

		    ## This new row will replace the old one inside the object
		    $bselementrelation_aref->{$element_name}->[$a_index] = $relation_row;
 		    
		}
	    
		unless (defined $sample_element_relation_id) {                            ## NEW INSERT and DISCARD CHANGES
		    
		    my $metadata_id = $metadata->store()
		                               ->get_metadata_id();

		    $bselementrelation_row->set_column( metadata_id => $metadata_id );    ## Set the metadata_id column
        
		    $bselementrelation_row->insert()
		                          ->discard_changes();                            ## It will set the row with the updated row

                            
		} 
		else {                                                               ## UPDATE IF SOMETHING has change
        
		    my @columns_changed = $bselementrelation_row->is_changed();
 
		    if (scalar(@columns_changed) > 0) {                              ## ...something has change, it will take
		       
			my @modification_note_list;                                  ## the changes and the old metadata object for
			foreach my $col_changed (@columns_changed) {                 ## this dbiref and it will create a new row
			    push @modification_note_list, "set value in $col_changed column";
			}
                
			my $modification_note = join ', ', @modification_note_list;
           
			my %elementrelation_metadata = $self->get_element_relation_metadbdata($metadata, $relation_kind);
			
 			my $mod_metadata_id = $elementrelation_metadata{$element_name}->{$related_element_name}
                                                                                      ->store({ modification_note => $modification_note })
                                                                                      ->get_metadata_id(); 

			$bselementrelation_row->set_column( metadata_id => $mod_metadata_id );

			$bselementrelation_row->update()
			                      ->discard_changes();
		    }
		}
		$a_index++;
	    }
	}
    }
	    
    return $self;    
}

=head2 obsolete_element_relation

  Usage: my $sample = $sample->obsolete_element_relation(
                                $metadata, 
                                $note, 
                                $elementname, 
                                $related_element_name, 
                                'REVERT');
 
  Desc: Change the status of a data association to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $sample, the sample object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $elementname, the sample_element_name that have associated the file_id
        $related_element_name, the sample_element_name associated to sample_element 
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $sample = $sample->obsolete_element_relation(
                                                      $metadata,
                                                      'change to obsolete',
                                                      $element_name,
                                                      $related_element_name,
                                                      );

=cut

sub obsolete_element_relation {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_element__relation().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata obj. supplied $self->obsolete_element_relation isn't CXGN::Metadata::Metadbdata.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_element_relation().\n");

    my $element_name = shift 
	|| croak("OBSOLETE ERROR: None element_name was supplied to $self->obsolete_element_relation().\n");

    my $related_element_name = shift 
	|| croak("OBSOLETE ERROR: None related sample_element_name was supplied to $self->obsolete_element_relation().\n");

    my $revert_tag = shift;

    ## Change the related_element_name for a related_element_id using a search

    my ($bsel_row) = $self->get_schema()
	                  ->resultset('BsSampleElement')
			  ->search({ sample_element_name => $related_element_name });
   
    unless (defined $bsel_row) {
	croak("OBSOLETE PARAMETER ERROR: The related_sample_element_name=$related_element_name do not exist into the db.\n");
    }

    my $related_element_id = $bsel_row->get_column('sample_element_id');

    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $metadbdata;
    
    my @metadbdata_href = $self->get_element_relation_metadbdata($metadata);
    
    foreach my $metadbdata_reltype (@metadbdata_href) {
	if (defined $metadbdata_reltype->{$element_name}) {
	    if (defined $metadbdata_reltype->{$element_name}->{$related_element_name}) {
		$metadbdata = $metadbdata_reltype->{$element_name}->{$related_element_name};	  
	    }
	}
    }
    unless (defined $metadbdata) {
	croak("DATA COHERENCE ERROR: Don't exists any element relation with '$element_name' & '$related_element_name' in $self obj.\n")
    }

    my $mod_metadata_id = $metadbdata->store( { 
	                                        modification_note => $modification_note,
						obsolete          => $obsolete, 
						obsolete_note     => $obsolete_note 
                                             } )
                                             ->get_metadata_id();
     
    ## Modify the sample_element_relation row in the database
 
    my $bselementrelation_row;

    my %bselementrelation_source_rows_aref = $self->get_bssampleelementrelation_source_rows();
    my %bselementrelation_result_rows_aref = $self->get_bssampleelementrelation_result_rows();

    if (defined $bselementrelation_source_rows_aref{$element_name}) {
	
	foreach my $bselementrelation_source_row (@{$bselementrelation_source_rows_aref{$element_name}}) {
	    if ($bselementrelation_source_row->get_column('sample_element_id_b') == $related_element_id) {

		$bselementrelation_row = $bselementrelation_source_row;
	    }
	}
    }
    if (defined $bselementrelation_result_rows_aref{$element_name}) {

	foreach my $bselementrelation_result_row (@{$bselementrelation_result_rows_aref{$element_name}}) {
	    if ($bselementrelation_result_row->get_column('sample_element_id_a') == $related_element_id) {

		$bselementrelation_row = $bselementrelation_result_row;
	    }
	}
    }
    unless (defined $bselementrelation_result_rows_aref{$element_name}){
	croak("OBJECT MANIPULATION ERROR: sample_element_name=$element_name do not exist into the $self object.\n");
    }
    

    $bselementrelation_row->set_column( metadata_id => $mod_metadata_id );
		
    $bselementrelation_row->update()
	                  ->discard_changes();


    return $self;
}


#####################
### Other Methods ###
#####################

=head2 get_dbxref_related

  Usage: my %dbxref_related = $sample->get_dbxref_related();
  
  Desc: Get a hash where keys=dbxref_id and values=hash ref where
           
  
  Ret:  %dbxref_related a HASH with KEYS=$sample_el_name 
                                    VALUE= ARRAY_REF of HASH_REF ( type => value ) and 
        types = (cvterm.cvterm_id, dbxref.dbxref_id, dbxref.accession, db.name, cvterm.name)
  
  Args: $dbname, if dbname is specified it will only get the dbxref associated with this dbname
  
  Side_Effects: none
  
  Example: my %dbxref_related = $sample->get_dbxref_related();
           my %dbxref_po = $sample->get_dbxref_related('PO');

=cut

sub get_dbxref_related {
    my $self = shift;
    my $dbname = shift;

    my %related = ();

    my %samplelementsdbxref = $self->get_dbxref_from_sample_elements();

    foreach my $sample_el_name (keys %samplelementsdbxref) {
	my @dbxref_ids = @{ $samplelementsdbxref{$sample_el_name} };
	
	my @dbxref_rel_el = ();

	foreach my $dbxref_id (@dbxref_ids) {

	    my %related_el = ();
	    
	    my ($dbxref_row) = $self->get_schema()
		                    ->resultset('General::Dbxref')
		                    ->search( { dbxref_id => $dbxref_id } );
	     
	    my %dbxref_data = $dbxref_row->get_columns();
	    
	    my ($cvterm_row) = $self->get_schema
		                    ->resultset('Cv::Cvterm')
		                    ->search( { dbxref_id => $dbxref_id } );

	    if (defined $cvterm_row) {
		my %cvterm_data = $cvterm_row->get_columns();
		     
		my ($db_row) = $self->get_schema()
                                    ->resultset('General::Db')
 		                    ->search( { db_id => $dbxref_data{'db_id'} } );

		my $dbmatch = 1;
		if (defined $dbname) {
		    unless ( $db_row->get_column('name') eq $dbname ) {
			$dbmatch = 0;
		    }
		}
		if ($dbmatch == 1) {
		    $related_el{'dbxref.dbxref_id'} = $dbxref_id;
		    $related_el{'db.name'} = $db_row->get_column('name');
		    $related_el{'dbxref.accession'} = $dbxref_data{'accession'};
		    $related_el{'cvterm.name'} = $cvterm_data{'name'};
		    $related_el{'cvterm.cvterm_id'} = $cvterm_data{'cvterm_id'};
		}
	    }
	    push @dbxref_rel_el, \%related_el;
	}
	$related{$sample_el_name} = \@dbxref_rel_el;	
    }
    return %related;
}




####
1;##
####
