
package CXGN::Metadata::Groups;

use strict;
use warnings;

use base qw | CXGN::DB::Object |;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Metadbdata;
use CXGN::Metadata::Dbiref;
use Carp qw | croak cluck |;


###############
### PERLDOC ###
###############

=head1 NAME

CXGN::Metadata::Groups 
a class to manipulate a database groups.

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

   use CXGN::Metadata::Groups;
   use CXGN::Metadata::Metadbdata; ## To store functions

   my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $username);

 ## Create a new group object.

   my $group = CXGN::Metadata::Groups->new($schema, $group_id);

 ## Alternatively it can be created by group name or members

   my $alt_group = CXGN::Metadata::Groups->new_by_group_name($schema, $groupname);

   my $alt_group2 = CXGN::Metadata::Groups->new_by_members($schema, 
                                                      [$dbiref_id1, $dbiref_id2]);


 ## To get group_id, group_name, group_type or group_description 

   my $group_id = $group->get_group_id();
   my $group_name = $group->get_group_name();
   my $group_type = $group->get_group_type();
   my $group_description = $group->get_group_description();

 ## To set some of these variables (except group_id)

   $group->set_group_name($group_name);
   $group->set_group_type($group_type);
   $group->set_group_description($group_description);

 ## To get members as dbirefs objects

   my @members_as_dbirefs = $group->get_members();

 ## To get as dbiref_id's

   my @member_ids = $group->get_member_ids();

 ## To add a member

   $group->add_member($dbiref_id3);


 ## Get members can use obsolete and non_obsolete tags
 ## to get a members obsolete or non obsoletes

   my @obsolete_members = $group->get_members('OBSOLETE');
   my @non_obsolete_members = $group->get_members('NON OBSOLETE');

 ## To ask if there are obsolete.
  ## For groups

    if ($group->is_obsolete()) {
    
      ## Do something

    }

  ## For members

    if ($group->is_obsolete_member($dbiref_id)) {
    
      ## Do something...

    }


 ## To store all ...

   $group->store($metadbdata);

 ## ... or some parts

   $group->store_group($metadbdata);
   $store->store_members($metadbdata);

 ## To obsolete

   $group->obsolete($metadbdata, $obsolete_note);
   $group->obsolete_member($metadbdata, $dbiref_id, $obsolete_note);


=head1 DESCRIPTION

 The metadata schema can store groups of any db data based in dbirefs
 (see perldoc CXGN::Metadata::Dbiref)

  The object structure is:
  + An schema object (CXGN::Metadata::Schema) store using the base module 
    (CXGN::DB::Object).
  + A row object CXGN::Metadata::Schema::MdGroups row
  + A array of rows of CXGN::Metadata::Schema::MdGroupMembers


=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



###########################
### GENERAL CONSTRUCTOR ###
###########################


=head2 constructor new

  Usage: my $groups = CXGN::Metadata::Groups->new($schema, $group_id);

  Desc: Create a new groups object

  Ret: a CXGN::Metadata::groups object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $group_id, if $group_id is omitted, an empty metadata object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $groups = CXGN::Metadata::Groups->new($schema, $group_id);

=cut

sub new {
    my $class = shift;
    my $schema = shift ||
	croak("CONSTRUCTOR INPUT ERROR: None schema object was supplied to CXGN::Metadata::Groups->new() method.\n");;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into de object 
    ### (set_schema comes from CXGN::DB::Object).

    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);                                   

    ### Second, check that ID is an integer. If it is right go and get all the data.
    ### If don't find any, create an empty oject.
    ### If it is not an integer, die

    my $group_row;
    my @member_rows = ();                                   ## Empty array for members

    if (defined $id) {

	unless ($id =~ m/^\d+$/) {  

            ## The id can be only an integer... so it is better if we detect this fail before.
      
	    croak("\nDATA TYPE ERROR: The dbiref_id ($id) for CXGN::Metadata::Groups->new() IS NOT AN INTEGER.\n\n");
	}

	$group_row = $schema->resultset('MdGroups')
	                    ->find({ group_id => $id });

	unless (defined $group_row) {    
            
            ## If group_id don't exists into the  db, it will warning with cluck and create an empty object

	    cluck("DATABASE COHERENCE ERROR: The dbref_id ($id) don't exists into the db. It will be created an empty Group object.\n"); 

	    $group_row = $schema->resultset('MdGroups')
		                ->new({});

	    ## The empty object will set mdmember_rows with an empty array;
	    
	}
	else {
	    
	    ## It will take the members

	    @member_rows = $schema->resultset('MdGroupmembers')
		                  ->search( { group_id => $id } );
	}
    } 
    else {

	$group_row = $schema->resultset('MdGroups')
                            ->new({});                ### Create an empty object;
    }

    ## Finally it will load the group_row and the members into the object.

    $self->set_mdgroup_row($group_row);
    $self->set_mdmember_rows(\@member_rows);

    return $self;
}

=head2 constructor new_by_group_name

  Usage: my $groups = CXGN::Metadata::Groups->new_by_group_name($schema, 
                                                                  $group_name);

  Desc: Create a new Groups object based in a group_name.
        Group_name has a UNIQUE constraint in the database

  Ret: a CXGN::Metadata::Groups object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a $group_name, if $group_name is omitted, an empty metadata object is 
        created.

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $groups = CXGN::Metadata::Groups->new_by_group_name($schema, 
                                                                  $group_name);

=cut

sub new_by_group_name {
    my $class = shift;
    my $schema = shift ||
	croak("CONSTRUCTOR INPUT ERROR: None schema object was supplied to CXGN::Metadata::Groups->new_by_group_name() method.\n");;
    my $name = shift;

    ## It will use the constructor new after search a group_id based in the group_name

    my $self;

    if (defined $name) {

	my $group_row = $schema->resultset('MdGroups')
	                       ->find({ group_name => $name });

	unless (defined $group_row) {    
            
            ## If group_id don't exists into the  db, it will warning with cluck and create an empty object

	    cluck("DATABASE COHERENCE ERROR: The group_name ($name) don't exist into the db. It'll be created an empty group object.\n"); 

	    $self = $class->new($schema);
	}
	else {
	    
	    $self = $class->new( $schema, $group_row->get_column('group_id') );
	}
    } 
    else {

	$self = $class->new($schema);
    }

    return $self;
}


=head2 constructor new_by_members

  Usage: my $Groups = CXGN::Metadata::Groups->new_by_members($schema, 
                                                               \@dbiref_id);

  Desc: Create a new Groups object based in a list of members

  Ret: a CXGN::Metadata::Group object

  Args: a $schema a schema object, preferentially created using:
        CXGN::Metadata::Schema->connect(
                   sub{ CXGN::DB::Connection->new()->get_actual_dbh()}, 
                   %other_parameters );
        a array reference (\@dbiref_id) with the members as dbiref_id's

  Side_Effects: accesses the database, check if exists the database columns that
                 this object use.  die if the id is not an integer.

  Example: my $groups = CXGN::Metadata::Groups->new_by_members($schema, 
                                                               [ $dbiref_id1, 
							         $dbiref_id2 ]);

=cut

sub new_by_members {
    my $class = shift;
    my $schema = shift ||
	croak("CONSTRUCTOR INPUT ERROR: None schema object was supplied to CXGN::Metadata::Groups->new_by_members() method.\n");;
    my $members_aref = shift;

    ## It will use the constructor new after search a group_id based in the group_name

    my $self;

    if (defined $members_aref) {

	unless ( ref($members_aref) eq 'ARRAY') {
	    croak("CONSTRUCTOR INPUT ERROR: Members array ref. supplied to CXGN::Metadata::Groups->new_by_members() isn't array ref.\n");
	} 

	my $members_n = scalar(@{$members_aref});

	my @groupmember_rows = $schema->resultset('MdGroupmembers')
	                              ->search( undef,
				                { 
					  	  columns  => ['group_id'],
						  where    => { group_id => { -in  => $members_aref } },
						  group_by => [ qw/group_id/ ], 
						  having   => { 'count(dbiref_id)' => { '=', $members_n } } 
					        } 
				               );

	## This search will return all the platform_design that contains the elements specified, it will filter 
	## by the number of element to take only the rows where have all these elements

	my $groupmember_row;
	foreach my $row (@groupmember_rows) {
	    my $count = $schema->resultset('MdGroupmembers')
	                       ->search( group_id => $row->get_column('group_id') )
		               ->count();
	    if ($count == $members_n) {
		$groupmember_row = $row;
	    }
	}


	unless (defined $groupmember_row) {    
            
            ## If group_id don't exists into the  db, it will warning with cluck and create an empty object

	    cluck("DATABASE COHERENCE ERROR: Members specified haven't a common group. It'll be created a group without group_id.\n"); 

	    $self = $class->new($schema);
	    
	    foreach my $member_id (@{$members_aref}) {
		$self->add_member($member_id);
	    }
	}
	else {
	    
	    $self = $class->new( $schema, $groupmember_row->get_column('group_id') );
	}
    } 
    else {

	$self = $class->new($schema);
    }

    return $self;
}



##################################
### DBIX::CLASS ROWS ACCESSORS ###
##################################

=head2 accessors get_mdgroup_row, set_mdgroup_row

  Usage: my $group_row_object = $self->get_mdgroup_row();
         $self->set_mdgroup_row($group_row_object);

  Desc: Get or set a group row object into a group object

  Ret:   Get => $group_row_object, a row object 
               (CXGN::Metadata::Schema::MdGroup).
         Set => none

  Args:  Get => none
         Set => $group_row_object, a row object 
               (CXGN::Metadata::Schema::MdGroups).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my $group_row_object = $self->get_mdgroup_row();
           $self->set_mdgroup_row($group_row_object);

=cut

sub get_mdgroup_row {
  my $self = shift;

  return $self->{mdgroup_row}; 
}

sub set_mdgroup_row {
  my $self = shift;
  my $group_row = shift 
      || croak("FUNCTION PARAMETER ERROR: None group_row object was supplied for set_mdgroup_row function.\n");
 
  if (ref($group_row) ne 'CXGN::Metadata::Schema::MdGroups') {

      croak("ARGUMENT ERROR: group row object: $group_row isn't an group_row object (CXGN::Metadata::Schema::MdGroups).\n");
  }
  $self->{mdgroup_row} = $group_row;
}

=head2 accessors get_mdmember_rows, set_mdmember_rows

  Usage: my @member_row_object = $self->get_mdmember_rows();
         $self->set_mdmember_rows(\@member_row_object);

  Desc: Get or set a group row object into a group object

  Ret:   Get => An array, @member_row_object, row objects 
               (CXGN::Metadata::Schema::MdGroup).
         Set => none

  Args:  Get => none
         Set => An array reference of \@member_row_objects, row objects 
               (CXGN::Metadata::Schema::MdGroups).

  Side_Effects: With set check if the argument is a row object. If fail, dies.

  Example: my @member_rows = $self->get_mdmember_rows();
           $self->set_mdmember_rows(\@member_row_objects);

=cut

sub get_mdmember_rows {
  my $self = shift;

  return @{$self->{mdmember_rows}}; 
}

sub set_mdmember_rows {
  my $self = shift;
  my $member_row_aref = shift 
      || croak("FUNCTION PARAMETER ERROR: None array reference of member_rows was supplied for set_mdmember_rows function.\n");
 
  if (ref($member_row_aref) ne 'ARRAY') {

      croak("ARGUMENT ERROR: member rows array reference: $member_row_aref isn't an array reference.\n");
  }
  else {
      
      ## It will check if the array is composed by CXGN::Metadata::Schema::MdGroupMembers objects
      
      foreach my $row (@{$member_row_aref}) {
	  if (ref($row) ne 'CXGN::Metadata::Schema::MdGroupmembers') {

	      croak("ARGUMENT ERROR: member row object: $row isn't a groupmember_row object (CXGN::Metadata::Schema::MdGroupmembers).\n");
	  }
      }
  }

  $self->{mdmember_rows} = $member_row_aref;
}



############################
### GROUP DATA ACCESSORS ###
############################

=head2 get_group_id, force_set_group_id
  
  Usage: my $group_id = $group->get_group_id();
         $group->force_set_group_id($group_id);

  Desc: get or set a group_id in a group object. 
        set method should be USED WITH PRECAUTION
        If you want set a group_id that do not exists into the database you 
        should consider that when you store this object you CAN STORE a 
        group_id that do not follow the metadata.md_group_group_id_seq
 
  Ret:  get=> $group_id, a scalar.
        set=> none
  
  Args: get=> none
        set=> $group_id, a scalar (constraint: it must be an integer)
  
  Side_Effects: For force_set_group_id die if some of the parameter 
                is wrong.
                It doesn't change the group_id for the group_member
                elements.
  
  Example: my $group_id = $group->get_group_id(); 

=cut

sub get_group_id {
  my $self = shift;

  return $self->get_mdgroup_row->get_column('group_id');
}

sub force_set_group_id {
  my $self = shift;
  my $data = shift;

  if (defined $data) {

      unless ($data =~ m/^\d+$/) {
	  croak("DATA TYPE ERROR: The group_id ($data) for CXGN::Metadata::Group->force_set_group_id() IS NOT AN INTEGER.\n");
      }

      $self->get_mdgroup_row()
	   ->set_column( group_id => $data );

  } 
  else {
      croak("FUNCTION PARAMETER ERROR: The dbiref_id was not supplied for force_set_dbiref_id function");
  }
}

=head2 accessors get_group_name, set_group_name

  Usage: my $group_name = $group->get_group_name();
         $group->set_group_name($group_name);

  Desc: Get or set the group_name for a group object from the database. 

  Ret:  get=> $group_name, a scalar
        set=> none

  Args: get=> none
        set=> $group_name, a scalar

  Side_Effects:  For set function, die if none variable is supplied

  Example: my $group_name = $group->get_group_name();

=cut

sub get_group_name {
  my $self = shift;

  return $self->get_mdgroup_row->get_column('group_name'); 
}

sub set_group_name {
  my $self = shift;
  my $data = shift 
       || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_group_name function");

  $self->get_mdgroup_row()
       ->set_column( group_name => $data ); 
}

=head2 accessors get_group_type, set_group_type

  Usage: my $group_type = $group->get_group_type();
         $group->set_group_type($group_type);

  Desc: Get or set the group_type for a group object from the database. 

  Ret:  get=> $group_type, a scalar
        set=> none

  Args: get=> none
        set=> $group_type, a scalar

  Side_Effects: For set function, die if none variable is supplied

  Example: my $group_type = $group->get_group_type();

=cut

sub get_group_type {
  my $self = shift;

  return $self->get_mdgroup_row->get_column('group_type'); 
}

sub set_group_type {
  my $self = shift;
  my $data = shift 
       || croak("FUNCTION PARAMETER ERROR: None data was supplied for set_group_type function");

  $self->get_mdgroup_row()
       ->set_column( group_type => $data ); 
}

=head2 accessors get_group_description, set_group_description

  Usage: my $group_description = $group->get_group_description();
         $group->set_group_description($group_description);

  Desc: Get or set the group_description for a group object from the database. 

  Ret:  get=> $group_description, a scalar
        set=> none

  Args: get=> none
        set=> $group_description, a scalar

  Side_Effects: none

  Example: my $group_description = $group->get_group_description();

=cut

sub get_group_description {
  my $self = shift;

  return $self->get_mdgroup_row->get_column('group_description'); 
}

sub set_group_description {
  my $self = shift;
  my $data = shift;

  $self->get_mdgroup_row()
       ->set_column( group_description => $data ); 
}

#############################
### MEMBER DATA ACCESSORS ###
#############################

=head2 get_member_ids, set_member_ids
  
  Usage: my @member_ids = $group->get_member_ids();
         $group->set_member_ids(\@member_ids);

  Desc: get or set a member_ids in a group object. 
 
  Ret:  get=> @member_id, an array with member_id (dbiref_ids).
        set=> none
  
  Args: get=> $obsolete_tag, to get only the obsolete or non obsolete members
        set=> \@member_id, an array reference with member_id (dbiref_ids).
  
  Side_Effects: For set_member_ids die if some of the parameter 
                is wrong.
                Die if the dbiref_id used to set the object do not exists
                into the database
                For get sort the dbiref_ids before return the array
                
  Example: my @member_ids = $group->get_member_ids(); 

=cut

sub get_member_ids {
  my $self = shift;
  
  my $obsolete_tag = shift;
 
  my @dbiref_ids = ();

  my @rows = $self->get_mdmember_rows();
  foreach my $row (@rows) {
      my $dbiref_id = $row->get_column('dbiref_id');
      
      if (defined $obsolete_tag) {
	  $obsolete_tag =~ s/\s+/_/g;
	  if ($obsolete_tag =~ m/^obs/i) {
	      if ($self->is_obsolete_member($dbiref_id) ) {
		  push @dbiref_ids, $dbiref_id;
	      }
	  }
	  elsif ($obsolete_tag =~ m/^non_obs/i) {
	      unless ($self->is_obsolete_member($dbiref_id) ) {
		  push @dbiref_ids, $dbiref_id;
	      }
	  }
	  else {
	      push @dbiref_ids, $dbiref_id;
	  }
      }
      else {
	  push @dbiref_ids, $dbiref_id;
      }
  }
      
  ## Sort the dbiref_ids for a better managent
  my @dbiref_ids_f = sort {$a <=> $b} @dbiref_ids;

  return @dbiref_ids_f;
}

sub set_member_ids {
  my $self = shift;
  my $data = shift;

  my @member_rows =();
  my $group_id = $self->get_group_id();

  if (defined $data) {

      if (ref($data) ne 'ARRAY') {
	  croak("DATA TYPE ERROR: Members array reference ($data) for CXGN::Metadata::Group->set_member_ids() IS NOT AN ARRAY REF.\n");
      }
      else {

	  ## Check if exists the dbiref supplied in the dbiref table
 
	  foreach my $dbiref_id (@{$data}) {
	      my $rs = $self->get_schema()
		            ->resultset('MdDbiref')
			    ->search( { dbiref_id => $dbiref_id });
	      
	      unless (defined $rs) {
		  croak("DATA COHERENCE ERROR: The dbiref_id=$dbiref_id set as member in set_member_ids method, don't exists in DB.\n");
	      }
	      else {
		  my $member_row = $self->get_schema()
		                        ->resultset('MdGroupmembers')
					->find_or_new( 
		                                       { 
							 group_id => $group_id, 
							 dbiref_id => $dbiref_id 
						       } 
					             );
		  push @member_rows, $member_row;
	      }
		  
	  }

	  $self->set_mdmember_rows(\@member_rows);
      }
  } 
  else {
      croak("FUNCTION PARAMETER ERROR: None members array reference was supplied for set_member_ids function");
  }
}


=head2 get_members
  
  Usage: my @members = $group->get_members($obsolete_tag);

  Desc: get or set a members in a group object. 
        It can be use a obsolete tag to take only the obsolete
        or non obsolete members
 
  Ret:  @members, an array with dbiref objects
  
  Args: $obsolete_tag, it can be 'OBSOLETE' or 'NON OBSOLETE'
  
  Side_Effects: none
                
  Example: my @members = $group->get_members(); 

           my @obs_members = $group->get_members('OBSOLETE');

=cut

sub get_members {
  my $self = shift;
  my $obsolete_tag = shift;

  my @dbirefs = ();
  my @dbiref_ids = $self->get_member_ids($obsolete_tag);

  ## This method use get_member_ids and it will create an dbiref object
  ## per dbiref_id

  foreach my $dbiref_id (@dbiref_ids) {
      my $dbiref = CXGN::Metadata::Dbiref->new($self->get_schema, $dbiref_id);
      
      push @dbirefs, $dbiref;
  }
      
  return @dbirefs;
}

=head2 add_member
  
  Usage: $group->add_member($dbiref_id);

  Desc: add a member to the group object. 
 
  Ret:  $group, a group object
  
  Args: $dbiref_id, a scalar dbiref_id
  
  Side_Effects: none
                
  Example: $group->add_member($dbiref_id); 

=cut

sub add_member {
  my $self = shift;

  my $dbiref_id = shift || 
      croak("FUNCTION PARAMETER ERROR: None dbiref_id was supplied for CXGN::Metadata::Groups->add_member() function.\n");
  unless ($dbiref_id =~ m/^\d+$/) {
      croak("FUNCTION PARAMETER ERROR: dbiref_id supplied to CXGN::Metadata::Groups->add_member() function isn't an integer\n");
  }

  ## Create a new row with this new dbiref_id

  my $mdmember_row = $self->get_schema()
                          ->resultset('MdGroupmembers')
			  ->new({ dbiref_id => $dbiref_id });
 
  ## Get the group_id, if exists it will set the group_id for this row

  my $group_id = $self->get_group_id();
  if (defined $group_id) {
      $mdmember_row->set_column( group_id => $group_id );
  }

  ## Now, add a new element to the array ref that stores the md_member_rows

  my @member_rows = $self->get_mdmember_rows();
  
  push @member_rows, $mdmember_row;

  $self->set_mdmember_rows(\@member_rows);

  return $self;
}




#####################################
### METADBDATA ASSOCIATED METHODS ###
#####################################

=head2 accessors get_metadbdata

  Usage: my $metadbdata = $group->get_metadbdata();
  
  Desc: Get metadata object associated to group data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  A metadbdata object (CXGN::Metadata::Metadbdata)
  
  Args: none
  
  Side_Effects: none
  
  Example: my $metadbdata = $group->get_metadbdata();

=cut

sub get_metadbdata {
  my $self = shift;
  my $metadata_obj_base = shift;

  my $metadbdata; 
  my $metadata_id = $self->get_mdgroup_row
                         ->get_column('metadata_id');

  if (defined $metadata_id) {
      $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), 
                                                    undef, 
                                                    $metadata_id);
      if (defined $metadata_obj_base) {

	  ## This will transfer the creation data from the base object to the new one
	  $metadbdata->set_object_creation_date( $metadata_obj_base->get_object_creation_date() );
	  $metadbdata->set_object_creation_user( $metadata_obj_base->get_object_creation_user() );
      }	  
  } 
  else {
      
      my $dbiref_id = $self->get_group_id();
      croak("DATABASE INTEGRITY ERROR: The metadata_id for the dbiref=$dbiref_id is undefined.\n");
  }
  return $metadbdata;
}

=head2 is_obsolete

  Usage: $group->is_obsolete();
  
  Desc: Get obsolete field form metadata object associated to dbiref data (see CXGN::Metadata::Metadbdata). 
  
  Ret:  0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
  
  Args: none
  
  Side_Effects: none
  
  Example: unless ($group->is_obsolete()) { ## do something }

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

=head2 accessors get_metadbdata_for_members

  Usage: my %metadbdata_members = $group->get_metadbdata_for_members();
  
  Desc: Get metadata object associated to group member data 
        (see CXGN::Metadata::Metadbdata). 
  
  Ret:  A hash with key = dbiref_id and value = metadbdata object 
        (CXGN::Metadata::Metadbdata)
  
  Args: $metadbdata, optional to transfer the metadata creation data
        $dbiref_id, optional, to get a single metadbdata object
  
  Side_Effects: die if is used an integer instead a $metadbdata
  
  Example:
      my %metadbdata_members = $group->get_metadbdata_for_members($metadbdata);

=cut

sub get_metadbdata_for_members {
  my $self = shift;
  my $metadata_obj_base = shift;

  my %metadbdata; 
  my @member_rows = $self->get_mdmember_rows();

  foreach my $member_row (@member_rows) {

      my %member_data = $member_row->get_columns();
      my $metadata_id = $member_data{'metadata_id'};
      my $dbiref_id = $member_data{'dbiref_id'};

      if (defined $metadata_id) {
	  my $metadbdata = CXGN::Metadata::Metadbdata->new($self->get_schema(), 
							undef, 
							$metadata_id);
	  if (defined $metadata_obj_base) {

	      ## This will transfer the creation data from the base object to the new one
	      $metadbdata->set_object_creation_date( $metadata_obj_base->get_object_creation_date() );
	      $metadbdata->set_object_creation_user( $metadata_obj_base->get_object_creation_user() );
	  }
	  $metadbdata{$dbiref_id} = $metadbdata;
      }
      else {
	  
	  my $dbiref_id = $self->get_group_id();
	  croak("DATABASE INTEGRITY ERROR: The metadata_id for the dbiref=$dbiref_id is undefined.\n");
      }
  }
  return %metadbdata;
}

=head2 is_obsolete_member

  Usage: $group->is_obsolete_member();
  
  Desc: Get obsolete field form metadata object associated to dbiref data 
        (see CXGN::Metadata::Metadbdata). 
  
  Ret:  A scalar: 0 -> false (it is not obsolete) or 1 -> true (it is obsolete)
      
  Args: none of dbiref_id, a scalar
  
  Side_Effects: none
  
  Example: if ($group->is_obsolete_member()) { 
               ## do something 
           }

=cut

sub is_obsolete_member {
  my $self = shift;
  my $dbiref_id = shift;

  my %metadbdata = $self->get_metadbdata_for_members();
  
  if (defined $dbiref_id && exists $metadbdata{$dbiref_id}) {
      my $obsolete = $metadbdata{$dbiref_id}->get_obsolete() || 0;
      return $obsolete;
  }   
}



#######################
### STORING METHODS ###
#######################

=head2 store

  Usage: my $group = $group->store($metadata);
 
  Desc: Store in the database the data of the metadata object.
        Store group and groupmember. To store only one of them
        see the methods store_group and store_members
 
  Ret: $group, the group object updated with the db data.
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $group = $group->store($metadata);

=cut

sub store {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbiref->store().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to CXGN::Metadata::Dbiref->store() is not CXGN::Metadata::Metadbdata object.\n");
    }


    ## This method use store_group and store_members at the same time.

    $self->store_group($metadata)
  	 ->store_members($metadata);

    return  $self;
}


=head2 store_group

  Usage: my $group = $group->store_group($metadata);
 
  Desc: Store in the database the data of the group object.
 
  Ret: $group, the group object updated with the db data.
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $group = $group->store_group($metadata);

=cut

sub store_group {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Group->store_group().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to CXGN::Metadata::Dbiref->store_group() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not group_id. 
    ##   if exists group_id         => update
    ##   if do not exists group_id  => insert

    my $mdgroup_row = $self->get_mdgroup_row();
    my $group_id = $mdgroup_row->get_column('group_id');

    unless (defined $group_id) {                                   ## NEW INSERT and DISCARD CHANGES
	
	my $metadata_id = $metadata->store()
	                           ->get_metadata_id();

	$mdgroup_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	$mdgroup_row->insert()
                    ->discard_changes();                           ## It will set the row with the updated row
	                    
    } 
    else {                                                        ## UPDATE IF SOMETHING has change
	
        my @columns_changed = $mdgroup_row->is_changed();
	
        if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
            my @modification_note_list;                             ## the changes and the old metadata object for
	    foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		push @modification_note_list, "set value in $col_changed column";
	    }
	   
            my $modification_note = join ', ', @modification_note_list;
	   
	    my $mod_metadata_id = $self->get_metadbdata($metadata)
	                               ->store({ modification_note => $modification_note })
				       ->get_metadata_id(); 

	    $mdgroup_row->set_column( metadata_id => $mod_metadata_id );

	    $mdgroup_row->update()
                        ->discard_changes();
	}
    }
    return $self;    
}

=head2 store_members

  Usage: my $group = $group->store_members($metadata);
 
  Desc: Store in the database the data of the metadata object.
 
  Ret: $group, the group object updated with the db data.
 
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
 
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
                   object
 
  Example: my $group = $group->store_members($metadata);

=cut

sub store_members {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
    my $metadata = shift  
	|| croak("STORE ERROR: None metadbdata object was supplied to CXGN::Metadata::Dbiref->store_member().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("STORE ERROR: Metadbdata supplied to CXGN::Metadata::Dbiref->store_member() is not CXGN::Metadata::Metadbdata object.\n");
    }

    ## It is not necessary check the current user used to store the data because should be the same than the used 
    ## to create a metadata_id. In the medadbdata object, it is checked.

    ## SECOND, check if exists or not group_id. 
    ##   if exists group_id         => update
    ##   if do not exists group_id  => insert

    my @mdmember_rows = $self->get_mdmember_rows();
    foreach my $mdmember_row (@mdmember_rows) {
	
	my $group_member_id = $mdmember_row->get_column('groupmember_id');

	unless (defined $group_member_id) {                             ## NEW INSERT and DISCARD CHANGES
	    
	    my $metadata_id = $metadata->store()
		                       ->get_metadata_id();

	    $mdmember_row->set_column( metadata_id => $metadata_id );   ## Set the metadata_id column
        
	    $mdmember_row->insert()
		         ->discard_changes();                           ## It will set the row with the updated row
	                    
	} 
	else {                                                          ## UPDATE IF SOMETHING has change
	
	    my @columns_changed = $mdmember_row->is_changed();
	
	    if (scalar(@columns_changed) > 0) {                         ## ...something has change, it will take
	   
		my @modification_note_list;                             ## the changes and the old metadata object for
		foreach my $col_changed (@columns_changed) {            ## this dbiref and it will create a new row
		    push @modification_note_list, "set value in $col_changed column";
		}
	   
		my $modification_note = join ', ', @modification_note_list;
	   
		my $mod_metadata_id = $self->get_metadbdata($metadata)
	                                   ->store({ modification_note => $modification_note })
				           ->get_metadata_id(); 

		$mdmember_row->set_column( metadata_id => $mod_metadata_id );

		$mdmember_row->update()
		             ->discard_changes();
	    }
	}
    }
    
    return $self;    
}

=head2 obsolete_group

  Usage: my $group = $group->obsolete_group($metadata, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $group, the group object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $group = $group->store_group($metadata, 'change to obsolete test');

=cut

sub obsolete_group {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_group().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata object supplied to $self->obsolete_group is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_group().\n");

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
 
    my $mdgroup_row = $self->get_mdgroup_row();

    $mdgroup_row->set_column( metadata_id => $mod_metadata_id );
         
    $mdgroup_row->update()
	        ->discard_changes();

    return $self;
}

=head2 obsolete_member

  Usage: my $group = $group->obsolete_member($metadata, $member_id, $note, 'REVERT');
 
  Desc: Change the status of a data to obsolete.
        If revert tag is used the obsolete status will be reverted to 0 (false)
 
  Ret: $dbiref, the dbiref object updated with the db data.
  
  Args: $metadata, a metadata object (CXGN::Metadata::Metadbdata object).
        $member_id (or dbiref_id for this member)
        $note, a note to explain the cause of make this data obsolete
        optional, 'REVERT'.
  
  Side_Effects: Die if:
                1- None metadata object is supplied.
                2- The metadata supplied is not a CXGN::Metadata::Metadbdata 
  
  Example: my $group = $group->obsolete_member($metadata, $member_id, 'change to obsolete test');

=cut

sub obsolete_member {
    my $self = shift;

    ## FIRST, check the metadata_id supplied as parameter
   
    my $metadata = shift  
	|| croak("OBSOLETE ERROR: None metadbdata object was supplied to $self->obsolete_member().\n");
    
    unless (ref($metadata) eq 'CXGN::Metadata::Metadbdata') {
	croak("OBSOLETE ERROR: Metadbdata supplied to $self->obsolete_member is not CXGN::Metadata::Metadbdata obj.\n");
    }

    my $member_id = shift  
	|| croak("OBSOLETE ERROR: None member_id was supplied to $self->obsolete_member().\n");

    my $obsolete_note = shift 
	|| croak("OBSOLETE ERROR: None obsolete note was supplied to $self->obsolete_member().\n");

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
     
    ## Modify the member row in the database. It will take all the member of the object and it will
    ## find the match with the member_id, If it find it, it will set to obsolete.
 
    my @mdmember_rows = $self->get_mdmember_rows();
    foreach my $md_member_row (@mdmember_rows) {
	my $dbiref_id = $md_member_row->get_column('dbiref_id');
	if ($dbiref_id eq $member_id) {

	    $md_member_row->set_column( metadata_id => $mod_metadata_id );
         
	    $md_member_row->update()
	                  ->discard_changes();
	}
    }

    return $self;
}



###########
return 1;##
###########
