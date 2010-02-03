
=head1 NAME

CXGN::Biosource::ProtocolTool
a class to manipulate a biosource tool data.

Version: 0.1

=head1 SYNOPSIS

  use CXGN::Biosource::ProtocolTool;

  my $tool = CXGN::Biosource::ProtocolTool->new($schema, $tool_id);

  $tool->set_tool_data(%tool_data);
  my %tool_data = $tool->get_tool_data();

  if ($tool->is_obsolete()) {
    print "This is obsolete tool";
  }

  $tool->store($metadbdata);
  $tool->obsolete($metadbdata, 'testing obsolete');

  ## Associated publications methods 

  $tool->add_publication($pub_id);
  my @pub_list = $tool->get_publication_list();

  unless ( $tool->is_tool_pub_obsolete($pub_id) ) {
      print "The pub association with pub_id=$pub_id is obsolete.\n";
  }

  my $tool = $tool->store_pub_associations($metadbdata);    
  my $tool = $tool->obsolete_pub_association($metadata, $note, $pub_id);  

=head1 DESCRIPTION

 This object manage the protocol information of the database
 from the tables:
  
   + biosource.bs_tool
   + biosource.bs_tool_pub

 This data is stored inside this object as dbic rows objects.


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 

use strict;
use warnings;

package CXGN::Biosource::ProtocolTool;

use base qw | CXGN::DB::Object |;
use File::Basename;
use CXGN::Biosource::Schema;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use Bio::Chado::Schema;
use Carp qw| croak cluck |;


############################
### GENERAL CONSTRUCTORS ###
############################

=head2 constructor new

  Usage: my $tool = CXGN::Biosource::ProtocolTool->new($schema, $tool_id);

  Desc: Create a new tool (protocoltool) object

  Ret: a CXGN::Biosource::ProtocolTool object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $tool_id, if $tool_id is omitted, an empty tool object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $tool = CXGN::Biosource::ProtocolTool->new($schema, $tool_id);

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
    ### this row in the database and after that get the data for tool. 
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $tool;
    my @tool_pub_rows;

    if (defined $id) {
	unless ($id =~ m/^\d+$/) {  ## The id can be only an integer... so it is better if we detect this fail before.
            
	    croak("\nDATA TYPE ERROR: The tool_id ($id) for $class->new() IS NOT AN INTEGER.\n\n");
	}
	($tool) = $schema->resultset('BsTool')
	                   ->search({ tool_id => $id });
	
	unless (defined $tool) {  ## If tool_id don't exists into the  db, it will warning with cluck and create an empty object
                
	    cluck("\nDATABASE WARNING: Tool_id ($id) for $class->new() DON'T EXISTS INTO THE DB.\nIt'll be created an empty obj.\n" );
	    
	    $tool = $schema->resultset('BsTool')
		              ->new({});
	}
	else {   ## If exists tool_id in the database will get pub associated to them

	    @tool_pub_rows = $schema->resultset('BsToolPub')
		                    ->search({ tool_id => $id });

	}
    } 
    else {
	$tool = $schema->resultset('BsTool')
	                  ->new({});                              ### Create an empty object;
    }

    ## Finally it will load the dbiref_row and dbipath_row into the object.
    $self->set_bstool_row($tool);
    $self->set_bstoolpub_rows(\@tool_pub_rows);

    return $self;
}

=head2 constructor new_by_name

  Usage: my $tool = CXGN::Biosource::ProtocolTool->new_by_name($schema, $tool_name);
 
  Desc: Create a new Tool (ProtocolTool) object using protocol_name
 
  Ret: a CXGN::Biosource::ProtocolTool object
 
  Args: a $schema a schema object, preferentially created using:
        CXGN::Biosource::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $tool_name, a scalar
 
  Side_Effects: accesses the database,
                return a warning if the protocol name do not exists into the db
 
  Example: my $tool = CXGN::Biosource::ProtocolTool->new_by_name( $schema, $name);

=cut

sub new_by_name {
    my $class = shift;
    my $schema = shift || 
	croak("PARAMETER ERROR: None schema object was supplied to the $class->new_by_name() function.\n");
    my $name = shift;

    ### It will search the protocol_id for this name and it will get the protocol_id for that using the new
    ### method to create a new object. If the name don't exists into the database it will create a empty object and
    ### it will set the protocol_name for it
  
    my $tool;

    if (defined $name) {
	my ($tool_row) = $schema->resultset('BsTool')
	                            ->find({ tool_name => $name });

	unless (defined $tool_row) {                     ## If tool_row don't exists into the  db, it will warning with cluck 
                                                         ## and it will create an object with this name 
                
	    cluck("\nDATABASE WARNING: Tool_name ($name) for $class->new() DON'T EXISTS INTO THE DB.\n" );
	    
	    $tool = $class->new($schema);
	    $tool->set_tool_name($name);
	}
	else {
	    $tool = $class->new($schema, $tool_row->get_column('tool_id'));
	}
    } 
    else {
	$tool = $class->new($schema);                              ### Create an empty object;
    }
 
    return $tool;
}

##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_bstool_row, set_bstool_row

  Usage: my $bstool_row_object = $self->get_bstool_row();
         $self->set_bstool_row($bstool_row_object);

  Desc: Get or set a bstool row object into a tool object
 
  Ret:   Get => $bstool_row_object, a row object 
                (CXGN::Biosource::Schema::BsTool).
         Set => none
 
  Args:  Get => none
         Set => $bstool_row_object, a row object 
                (CXGN::Biosource::Schema::BsTool).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my $bstool_row_object = $self->get_bstool_row();
           $self->set_bstool_row($bstool_row_object);

=cut

sub get_bstool_row {
  my $self = shift;
 
  return $self->{bstool_row}; 
}

sub set_bstool_row {
  my $self = shift;
  my $bstool_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None bstool_row object was supplied for set_bstool_row function.\n");
 
  if (ref($bstool_row) ne 'CXGN::Biosource::Schema::BsTool') {
      croak("SET ARGUMENT ERROR: $bstool_row isn't a bstool_row obj. (CXGN::Biosource::Schema::BsTool).\n");
  }
  $self->{bstool_row} = $bstool_row;
}


=head2 accessors get_bstoolpub_rows, set_bstoolpub_rows

  Usage: my @bstoolpub_rows = $self->get_bstoolpub_rows();
         $self->set_bstoolpub_rows(\@bstoolpub_rows);

  Desc: Get or set a list of bstoolpub rows object into a tool object
 
  Ret:   Get => @bstoolpub_row_object, a list of row objects 
                (CXGN::Biosource::Schema::BsTool).
         Set => none
 
  Args:  Get => none
         Set => @bstoolpub_row_object, an array ref of row objects 
                (CXGN::Biosource::Schema::BsTool).
 
  Side_Effects: With set check if the argument is a row object. If fail, dies.
 
  Example: my @bstoolpub_rows = $self->get_bstoolpub_rows();
           $self->set_bstoolpub_rows(\@bstoolpub_rows);

=cut

sub get_bstoolpub_rows {
  my $self = shift;
 
  return @{$self->{bstoolpub_rows}}; 
}

sub set_bstoolpub_rows {
  my $self = shift;
  my $bstoolpub_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None bstoolpub_row array ref was supplied for set_bstoolpub_rows function.\n");
 
  if (ref($bstoolpub_row_aref) ne 'ARRAY') {
      croak("SET ARGUMENT ERROR: $bstoolpub_row_aref isn't an array reference.\n");
  }
  else {
      foreach my $bstoolpub_row (@{$bstoolpub_row_aref}) {  
	  if (ref($bstoolpub_row) ne 'CXGN::Biosource::Schema::BsToolPub') {
	      croak("SET ARGUMENT ERROR: $bstoolpub_row isn't a bstoolpub_row obj. (CXGN::Biosource::Schema::BsToolPub).\n");
	  }
      }
  }
  $self->{bstoolpub_rows} = $bstoolpub_row_aref;
}


######################
### DATA ACCESSORS ###
######################

=head2 get_tool_id, force_set_tool_id
  
  Usage: my $tool_id = $tool->get_tool_id();
         $tool->force_set_tool_id($tool_id);

  Desc: get or set a tool_id in a tool object. 
        set method should be USED WITH PRECAUTION
        If you want set a tool_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        tool_id that do not follow the biosource.bs_tool_tool_id_seq

  Ret:  get=> $tool_id, a scalar.
        set=> none

  Args: get=> none
        set=> $tool_id, a scalar (constraint: it must be an integer)

  Side_Effects: none

  Example: my $tool_id = $tool->get_tool_id(); 

=cut

sub get_tool_id {
  my $self = shift;
  return $self->get_bstool_row->get_column('tool_id');
}

sub force_set_tool_id {
  my $self = shift;
  my $data = shift ||
      croak("FUNCTION PARAMETER ERROR: None tool_id was supplied for force_set_tool_id function");

  unless ($data =~ m/^\d+$/) {
      croak("DATA TYPE ERROR: The tool_id ($data) for $self->force_set_tool_id() ISN'T AN INTEGER.\n");
  }

  $self->get_bstool_row()
       ->set_column( tool_id => $data );
 
}

=head2 accessors get_tool_name, set_tool_name

  Usage: my $tool_name = $tool->get_tool_name();
         $tool->set_tool_name($tool_name);

  Desc: Get or set the tool_name from tool object. 

  Ret:  get=> $tool_name, a scalar
        set=> none

  Args: get=> none
        set=> $tool_name, a scalar

  Side_Effects: none

  Example: my $tool_name = $tool->get_tool_name();
           $tool->set_tool_name($new_name);
=cut

sub get_tool_name {
  my $self = shift;
  return $self->get_bstool_row->get_column('tool_name'); 
}

sub set_tool_name {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_tool_name function to CXGN::Biosource::ProtocolTool.\n");

  $self->get_bstool_row()
       ->set_column( tool_name => $data );
}

=head2 accessors get_tool_type, set_tool_type

  Usage: my $tool_type = $tool->get_tool_type();
         $tool->set_tool_type($tool_type);
 
  Desc: Get or set tool_type from a tool object. 
 
  Ret:  get=> $tool_type, a scalar
        set=> none
 
  Args: get=> none
        set=> $tool_type, a scalar
 
  Side_Effects: none
 
  Example: my $tool_type = $tool->get_tool_type();
           $tool->set_tool_type($tool_type);

=cut

sub get_tool_type {
  my $self = shift;
  return $self->get_bstool_row->get_column('tool_type'); 
}

sub set_tool_type {
  my $self = shift;
  my $data = shift 
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_tool_type function to CXGN::Biosource::ProtocolTool.\n");

  $self->get_bstool_row()
       ->set_column( tool_type => $data );
}

=head2 accessors get_tool_description, set_tool_description

  Usage: my $tool_description = $tool->get_tool_description();
         $tool->set_tool_description($tool_description);

  Desc: Get or set the tool_description from a tool object 

  Ret:  get=> $tool_description, a scalar
        set=> none

  Args: get=> none
        set=> $tool_description, a scalar

  Side_Effects: none

  Example: my $tool_description = $tool->get_tool_description();
           $protocol->set_tool_description($tool_description);
=cut

sub get_tool_description {
  my $self = shift;
  return $self->get_bstool_row->get_column('tool_description'); 
}

sub set_tool_description {
  my $self = shift;
  my $data = shift;

  $self->get_bstool_row()
       ->set_column( tool_description => $data );
}

=head2 accessors get_tool_weblink, set_tool_weblink

  Usage: my $tool_weblink = $tool->get_tool_weblink();
         $tool->set_tool_weblink($tool_weblink);

  Desc: Get or set the tool_weblink from a tool object 

  Ret:  get=> $tool_weblink, a scalar
        set=> none

  Args: get=> none
        set=> $tool_weblink, a scalar

  Side_Effects: none

  Example: my $tool_weblink = $tool->get_tool_weblink();
           $protocol->set_tool_weblink($tool_weblink);
=cut

sub get_tool_weblink {
  my $self = shift;
  return $self->get_bstool_row->get_column('tool_weblink'); 
}

sub set_tool_weblink {
  my $self = shift;
  my $data = shift;

  $self->get_bstool_row()
       ->set_column( tool_weblink => $data );
}

=head2 accessors get_file_id, set_file_id

  Usage: my $file_id = $tool->get_file_id();
         $tool->set_file_id($file_id);

  Desc: Get or set the file_id from a tool object 

  Ret:  get=> $file_id, a scalar, an integer
        set=> none

  Args: get=> none
        set=> $file_id, a scalar, an integer

  Side_Effects: For set, die if the $file_id is not an integer

  Example: my $file_id = $tool->get_file_id();
           $protocol->set_file_id($file_id);
=cut

sub get_file_id {
  my $self = shift;
  return $self->get_bstool_row->get_column('file_id'); 
}

sub set_file_id {
  my $self = shift;
  my $data = shift;

  unless ($data =~ m/^\d+$/) {
       croak("DATA TYPE ERROR: The file_id ($data) for $self->set_file_id() ISN'T AN INTEGER.\n");
  }

  $self->get_bstool_row()
       ->set_column( file_id => $data );
}


=head2 accessors get_file_name, set_file_id_by_name

  Usage: my $file_name = $tool->get_file_name();
         $tool->set_file_id_by_name($file_name);

  Desc: Get the file name associated to a file_id in the tool object 
        Set the file_id in the tool object using file_name
        IMPORTANT: The schema used in the object creation must contains
                   the metadata classes

  Ret:  get=> $file_name, a scalar
        set=> none

  Args: get=> none
        set=> $file_name, a scalar

  Side_Effects: For set, die if the $file_name is not in the db

  Example: my $file_name = $tool->get_file_name();
           $protocol->set_file_id_by_name($file_name);
=cut

sub get_file_name {
  my $self = shift;
  my $file_id = $self->get_file_id();

  my $filename;
  if (defined $file_id) {
      my ($file_row) = $self->get_schema()
	                    ->resultset('MdFiles')
			    ->search({ file_id => $file_id });
      
      if (defined $file_row) {
	  $filename = $file_row->get_column('dirname') . $file_row->get_column('basename');
      }
  }
  return $filename; 
}

sub set_file_id_by_name {
  my $self = shift;
  my $data = shift
      || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_file_id_by__name function to CXGN::Biosource::ProtocolTool.\n");

  my ($basename, $dirname) = fileparse($data); 

  my ($file_row) = $self->get_schema()
                        ->resultset('MdFiles')
			->search( { basename => $basename,
			            dirname  => $dirname   } );
      
  if (defined $file_row) {
      $self->set_file_id( $file_row->get_column('file_id') );
  }      
  else {
      croak("DATABASE ASSOCIATED ERROR: The file ($data) don't exists in the metadata.md_files table.\n");
  }
}

=head2 accessors get_tool_data, set_tool_data

  Usage: my %tool_data = $tool->get_tool_data();
         $tool->set_tool_data(%tool_data);

  Desc: Get or set tool data table from a tool object
        as hash with key=column_name and value=data 

  Ret:  get=> %tool_data, a hash with key=column_name and
              value=data
        set=> none

  Args: get=> none
        set=> \%tool_data, a hash reference with key=column_name 
              and value=data

  Side_Effects: For set, die if \%tool_data is not an hash 
                reference

  Example:  my %tool_data = $tool->get_tool_data();
            $tool->set_tool_data(%tool_data);
=cut

sub get_tool_data {
  my $self = shift;
  return $self->get_bstool_row->get_columns(); 
}

sub set_tool_data {
  my $self = shift;
  my $data_href = shift ||
      croak("FUNCTION PARAMETER ERROR: None hash ref. was supplied for set_tool_data function to CXGN::Biosource::ProtocolTool.\n");

  if (ref($data_href) ne 'HASH') {
       croak("DATA TYPE ERROR: The hash ref ($data_href) for $self->set_file_id() ISN'T AN HASH REFERENCE.\n");
  }

  $self->get_bstool_row()
       ->set_columns($data_href);
}


#####################################
### PUBLICATION RELATED FUNCTIONS ###
#####################################

=head2 add_publication

  Usage: $tool->add_publication($pub_id);

  Desc: Add a publication to the pub_ids associated to tool object 

  Ret:  None

  Args: $pub_row, a publication row object. 
        To use with $pub_id: 
          $tool->add_publication($pub_id);
        To use with $pub_title
           $tool->add_publication({ title => $pub_title } );
        To use with pubmed accession
            $tool->add_publication({ dbxref_accession => $accesssion});
          
  Side_Effects: die if the parameter is not an object

  Example: $tool->add_publication($pub_id);

=cut

sub add_publication {
    my $self = shift;
    my $pub = shift ||
	croak("FUNCTION PARAMETER ERROR: None pub was supplied for add_publication function to CXGN::Biosource::ProtocolTool.\n");

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
	    croak("DATABASE ARGUMENT ERROR: Publication data used as argument for add_publication function don't exists in the DB.\n");
	}
	$pub_id = $pub_row->get_column('pub_id');
	
    }
    else {
	croak("SET ARGUMENT ERROR: The publication ($pub) isn't a pub_id, or hash with title or dbxref_accession keys.\n");
    }
    
    my $toolpub_row = $self->get_schema()
	                   ->resultset('BsToolPub')
			   ->new({ pub_id => $pub_id});
    
    if (defined $self->get_tool_id() ) {
	$toolpub_row->set_column( tool_id => $self->get_tool_id() );
    }

    my @toolpub_rows = $self->get_bstoolpub_rows();
    push @toolpub_rows, $toolpub_row;
    $self->set_bstoolpub_rows(\@toolpub_rows);
}

=head2 get_publication_list

  Usage: my @pub_list = $tool->get_publication_list();

  Desc: Get a list of publications associated to this tool

  Ret: An array of pub_ids by default, but can be titles
       or accessions using an argument

  Args: None or a column to get.

  Side_Effects: die if the parameter is not an object

  Example: my @pub_id_list = $tool->get_publication_list();
           my @pub_title_list = $tool->get_publication_list('title');
           my @pub_title_accs = $tool->get_publication_list('dbxref.accession');


=cut

sub get_publication_list {
    my $self = shift;
    my $field = shift;

    my @pub_list = ();

    my @toolpub_rows = $self->get_bstoolpub_rows();
    foreach my $toolpub_row (@toolpub_rows) {
	my $pub_id = $toolpub_row->get_column('pub_id');
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

=head2 accessors get_metadbdata

  Usage: my $metadbdata = $tool->get_metadbdata();

  Desc: Get metadata object associated to tool data (see CXGN::Metadata::Metadbdata). 

  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my $metadbdata = $tool->get_metadbdata();
           my $metadbdata = $tool->get_metadbdata($metadbdata);

=cut

sub get_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my $metadbdata; 
  my $metadata_id = $self->get_bstool_row
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
      my $tool_id = $self->get_tool_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the tool_id=$tool_id is undefined.\n");
  }
  
  return $metadbdata;
}

=head2 is_obsolete

  Usage: $tool->is_obsolete();
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($tool->is_obsolete()) { ## do something }

=cut

sub is_obsolete {
  my $self = shift;

  my $metadbdata = $self->get_metadbdata();
  my $obsolete = $metadbdata->get_obsolete();
  
  if (defined $obsolete) {
      return $obsolete;
  } 
  else {
      return 0;
  }
}


=head2 accessors get_tool_pub_metadbdata

  Usage: my %metadbdata = $tool->get_tool_pub_metadbdata();

  Desc: Get metadata object associated to tool data 
        (see CXGN::Metadata::Metadbdata). 

  Ret:  A hash with keys=pub_id and values=metadbdata object 
        (CXGN::Metadata::Metadbdata)

  Args: Optional, a metadbdata object to transfer metadata creation variables

  Side_Effects: none

  Example: my %metadbdata = $tool->get_tool_metadbdata();
           my %metadbdata = $tool->get_tool_metadbdata($metadbdata);

=cut

sub get_tool_pub_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;
  
  my %metadbdata; 
  my @bstoolpub_rows = $self->get_bstoolpub_rows();

  foreach my $bstoolpub_row (@bstoolpub_rows) {
      my $pub_id = $bstoolpub_row->get_column('pub_id');
      my $metadata_id = $bstoolpub_row->get_column('metadata_id');

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
	  my $tool_pub_id = $bstoolpub_row->get_column('tool_pub_id');
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the tool_pub_id=$tool_pub_id is undefined.\n");
      }
  }
  return %metadbdata;
}

=head2 is_tool_pub_obsolete

  Usage: $tool->is_tool_pub_obsolete($pub_id);
  
  Desc: Get obsolete field form metadata object associated to 
        protocol data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: $pub_id, a publication_id
  
  Side_Effects: none
  
  Example: unless ( $tool->is_tool_pub_obsolete($pub_id) ) { ## do something }

=cut

sub is_tool_pub_obsolete {
  my $self = shift;
  my $pub_id = shift;

  my %metadbdata = $self->get_tool_pub_metadbdata();
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

  Usage: my $tool = $tool->store($metadata);
 
  Desc: Store in the database the tool data for the tool object
 
  Ret: $tool, the tool object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $tool = $tool->store($metadata);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to $self->store().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to $self->store() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not group_id. 
    ##   if exists group_id         => update
    ##   if do not exists group_id  => insert

    my $bstool_row = $self->get_bstool_row();
    my $tool_id = $bstool_row->get_column('tool_id');

    unless (defined $tool_id) {                                       ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$bstool_row->set_column( metadata_id => $metadata_id );       ## Set the metadata_id column
        
	$bstool_row->insert()
                   ->discard_changes();                               ## It will set the row with the updated row
	                    
    } 
    else {                                                            ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $bstool_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $bstool_row->set_column( metadata_id => $mod_metadata_id );

	    $bstool_row->update()
                       ->discard_changes();
	}
    }
    return $self;    
}


=head2 obsolete

  Usage: my $tool = $tool->obsolete($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $tool, the tool object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $tool = $tool->obsolete($metadata, 'change to obsolete test');

=cut

sub obsolete {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete().\n");

    my $revert_tag = shift;


    ## If exists the tag revert change obsolete to 0

    my $obsolete = 1;
    my $modification_note = 'change to obsolete';
    if (defined $revert_tag && $revert_tag =~ m/REVERT/i) {
	$obsolete = 0;
	$modification_note = 'revert obsolete';
    }

    ## Create a new metadata with the obsolete tag

    my $mod_metadata_id = $self->get_metadbdata($metadata) 
                               ->store( { modification_note => $modification_note,
		                          obsolete          => $obsolete, 
		                          obsolete_note     => $obsolete_note } )
                               ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my $bstool_row = $self->get_bstool_row();

    $bstool_row->set_column( metadata_id => $mod_metadata_id );
         
    $bstool_row->update()
	           ->discard_changes();

    return $self;
}


=head2 store_pub_associations

  Usage: my $tool = $tool->store_pub_associations($metadata);
 
  Desc: Store in the database the pub association for the tool object
 
  Ret: $tool, the tool object with the data updated
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $tool = $tool->store_pub_associations($metadata);

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

    ## SECOND, check if exists or not group_id. 
    ##   if exists tool_pub_id         => update
    ##   if do not exists tool_pub_id  => insert

    my @bstoolpub_rows = $self->get_bstoolpub_rows();
    
    foreach my $bstoolpub_row (@bstoolpub_rows) {
	
	my $tool_pub_id = $bstoolpub_row->get_column('tool_pub_id');
	my $pub_id = $bstoolpub_row->get_column('pub_id');

	unless (defined $tool_pub_id) {                                       ## NEW INSERT and DISCARD CHANGES
	
	    my $metadata_id = $metadata->store()
	                               ->get_metadata_id();

	    $bstoolpub_row->set_column( metadata_id => $metadata_id );        ## Set the metadata_id column
        
	    $bstoolpub_row->insert()
                          ->discard_changes();                                ## It will set the row with the updated row
	                    
	} 
	else {                                                                ## UPDATE IF SOMETHING has change
	
	    my @columns_changed = $bstoolpub_row->is_changed();
	
	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}
		
		my $modification_note = join ', ', @modification_note_list;
	   

		my %aspub_metadata = $self->get_tool_pub_metadbdata($metadata);
		my $mod_metadata_id = $aspub_metadata{$pub_id}->store({ modification_note => $modification_note })
				                              ->get_metadata_id(); 

		$bstoolpub_row->set_column( metadata_id => $mod_metadata_id );

	        $bstoolpub_row->update()
                             ->discard_changes();
	    }
	}
    }
    return $self;    
}


=head2 obsolete_pub_association

  Usage: my $tool = $tool->obsolete_pub_association($metadata, $note, $pub_id, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $tool, the tool object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        $pub_id, a publication id associated to this tool
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $tool = $tool->obsolete_pub_association($metadata, 
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

    my %aspub_metadata = $self->get_tool_pub_metadbdata($metadata);

    my $mod_metadata_id = $aspub_metadata{$pub_id}->store( { modification_note => $modification_note,
							     obsolete          => $obsolete, 
							     obsolete_note     => $obsolete_note } )
                                                  ->get_metadata_id();
     
    ## Modify the group row in the database
 
    my @bstoolpub_rows = $self->get_bstoolpub_rows();
    foreach my $bstoolpub_row (@bstoolpub_rows) {
	if ($bstoolpub_row->get_column('pub_id') == $pub_id) {

	    $bstoolpub_row->set_column( metadata_id => $mod_metadata_id );
         
	    $bstoolpub_row->update()
	                  ->discard_changes();

	}
    }
    return $self;
}






####
1;##
####
