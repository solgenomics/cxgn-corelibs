


=head1 NAME

CXGN::People::UserMap - a class that manages the database end for user defined maps on SGN.      
     
=head1 SYNOPSYS

         
=head1 DESCRIPTION



=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 VERSION

1e-100
 
=head1 FUNCTIONS

This class implements the following functions:

=cut


use strict;

package CXGN::People::UserMap;

use CXGN::DB::ModifiableI; 
use CXGN::Marker;
use CXGN::People::UserMapData;

use base qw | CXGN::DB::ModifiableI |;



=head2 function new()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self= $class->SUPER::new($dbh);
    $self->set_sql();
    $self->set_user_map_id($id);
    
    if ($id) { 
	$self->fetch(); 
	
	# check if the map id supplied was legal...
	if (!$self->get_user_map_id()) { 
	    print STDERR "UserMap: An illegal ID was passed to the constructor.\n";
	    return undef; 
	}
	else { 
	    print STDERR "Returning map with id: ".$self->get_user_map_id()."\n";
	}
    }
    return $self;
}

=head2 function fetch()
    
  Synopsis:	
  Arguments:	none
  Returns:	
  Side_effects:	
  Description:	populates the object from the database

=cut

sub fetch {
    my $self = shift;
    my $sth = $self->get_sql('fetch');
    $sth->execute($self->database_id($self->get_user_map_id()));
    while (my ($user_map_id, $short_name, $long_name, $abstract, $is_public, $parent1, $parent2, $sp_person_id, $obsolete, $modified_date, $create_date) = $sth->fetchrow_array()) { 
	$self->set_user_map_id($user_map_id);
	$self->set_short_name($short_name);
	$self->set_long_name($long_name);
	$self->set_abstract($abstract);
	$self->set_is_public($is_public);
	$self->set_parent1($parent1);
	$self->set_parent2($parent2);
	$self->set_sp_person_id($sp_person_id);
	$self->set_obsolete($obsolete);
	$self->set_modification_date($modified_date);
	$self->set_create_date($create_date);
    }
}

=head2 function store()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub store {
    my $self = shift;
    
    # adjust is public for database use

    if ($self->get_user_map_id()) { 

		my $sth = $self->get_sql("update");
		$sth->execute( 
		       $self->get_short_name(),
		       $self->get_long_name(),
		       $self->get_abstract(),
		       ($self->get_is_public() ? 1 : 0),
		       $self->get_parent1(),
		       $self->get_parent2(),
		       $self->get_sp_person_id(),
		       $self->get_obsolete(),
		       $self->database_id($self->get_user_map_id())
		);
		return $self->get_user_map_id();
    }
    else { 
		my $sth = $self->get_sql('insert');
		$sth->execute(
		      $self->get_short_name(),
		      $self->get_long_name(),
		      $self->get_abstract(),
		      ($self->get_is_public() ? "t" : "f"), 
		      $self->get_parent1(),
		      $self->get_parent2(),
		      $self->get_sp_person_id(),
		      $self->get_obsolete()
		);
		$sth = $self->get_sql('currval');
		$sth->execute();
		my ($id) = $sth->fetchrow_array();
		$self->set_user_map_id("u".$id);
		print STDERR "New user_map_id = ".$self->get_user_map_id()."\n";
		return $self->get_user_map_id();
    }
}

=head2 function delete

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub delete {
    my $self = shift;
    print STDERR " *** DELETING map ".$self->get_user_map_id()."\n";
    # obsolete the user_map entry
    my $sth = $self->get_sql('delete_map');
    $sth->execute($self->database_id($self->get_user_map_id()));
    # obsolete the user_map_data entries
    my $sth2 = $self->get_sql('delete_map_data');
    $sth2->execute($self->database_id($self->get_user_map_id()));
    
}

=head2 accessors set_user_map_id(), get_user_map_id()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_user_map_id { 
    my $self=shift;
    return $self->{user_map_id};
}

sub set_user_map_id { 
    my $self=shift;
    $self->{user_map_id}=shift;
}

=head2 accessors set_parent1(), get_parent1()

  Property:	the name of parent1 [string]
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_parent1 { 
    my $self=shift;
    return $self->{parent1};
}

sub set_parent1 { 
    my $self=shift;
    $self->{parent1}=shift;
}

=head2 accessors set_parent2(), get_parent2()

  Property:	the name of parent2 [string]
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_parent2 { 
    my $self=shift;
    return $self->{parent2};
}

sub set_parent2 { 
    my $self=shift;
    $self->{parent2}=shift;
}

=head2 accessors set_short_name(), get_short_name()

  Property:	the short name of the map.
  Side Effects:	
  Description:	

=cut

sub get_short_name { 
    my $self=shift;
    return $self->{short_name};
}

sub set_short_name { 
    my $self=shift;
    $self->{short_name}=shift;
}

=head2 accessors set_long_name(), get_long_name()

  Property:	the long name of the map.
  Side Effects:	
  Description:	

=cut

sub get_long_name { 
    my $self=shift;
    return $self->{long_name};
}

sub set_long_name { 
    my $self=shift;
    $self->{long_name}=shift;
}

=head2 accessors set_abstract(), get_abstract()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_abstract { 
    my $self=shift;
    return $self->{abstract};
}

sub set_abstract { 
    my $self=shift;
    $self->{abstract}=shift;
}

=head2 accessors set_is_public(), get_is_public()

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_is_public { 
    my $self=shift;
    if (!exists($self->{is_public}) || !defined($self->{is_public}) || !$self->{is_public} || $self->{is_public} eq "f") { 
	$self->{is_public}=0;
    }
    else {  
	$self->{is_public}=1; 
    }
    
    return $self->{is_public};
}

sub set_is_public { 
    my $self=shift;
    my $is_public = shift;
    print STDERR "set_is_public: $is_public ...";
    if ($is_public eq "t") { $is_public=1; }
    if ($is_public eq "f" || !$is_public) { $is_public=0; }
    
    print STDERR " set to $is_public!\n";
    $self->{is_public}=$is_public;
}


=head2 check_file()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub check_file {
    my $self = shift;
    my $filename = shift;

    my ($FILE);
    open($FILE, "<$filename") || die "Can't open the file $filename";
    my $line_count = 1;
    my @error_lines = ();

    # throw away the header line.
    #
    my $header = <$FILE>;

    while (<$FILE>) { 
	chomp;
	if (/^\#/) { next; }  # exclude commented lines
	if (/^$/) { next; }   # exclude empty lines
	
	if (my $error = $self->check_line($_)) { 
	    push @error_lines, [$line_count, $error];
	}
	$line_count++;
    }
    return @error_lines;
}

sub check_line { 
    my $self = shift;
    my $line = shift;
    my ($marker_name, $marker_id, $linkage_group, $position, $confidence, $protocol) = $self->get_fields($line);
    my $error = "";
    if (!$marker_name) {
	$error .= "missing marker name ";
    }
    if (!$linkage_group) { 
	$error .= "missing linkage group ";
    }
    if (!$position) { 
	$error .= "missing position ";
    }
    
    return $error;
}

# this function returns marker_name, marker_id, linkage_group, position, confidence, protol. Can be overridden in subclass to parse other file formats.
#
sub get_fields { 
    my $self = shift;
    my $line = shift;
    return my ($marker_name, $marker_id, $linkage_group, $position, $confidence, $protocol) = split /\t/, $line; 
}

=head2 get_map_stats_from_file()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_map_stats_from_file {
    my $self = shift;
    my $filename = shift;

    my ($FILE);

    open($FILE, "<$filename") || die "Can't open the file $filename";

    my $line_count = 1;
    my @error_lines = ();

    # throw away the header line.
    #
    my $header = <$FILE>;
    my %chr = ();

    while (<$FILE>) { 
	chomp;
	if (/^\#/) { next; }  # exclude commented lines
	if (/^$/) { next; }   # exclude empty lines
	
	my ($marker_name, $marker_id, $linkage_group, $position, $confidence, $protocol) = $self->get_fields($_);
	$chr{$linkage_group}++;
	$line_count++;
    }
    return %chr;

}


=head2 assign_markers()

 Usage:        $map->assign_markers()
 Desc:         tries to find each marker in the user map
               by matching its name against markers in the sgn.marker
               table. Sets the marker_id of the sgn marker in the 
               user_map_data table.
 Ret:          nothing
 Args:         none
 Side Effects: attributes marker_id\'s to markers in the user_map.
 Notes:        not clear how aliases should be handled.
 Example:

=cut

sub assign_markers {
    my $self = shift;
    print STDERR "Assigning markers for user map ".$self->get_user_map_id()."\n";
    
    my $sth = $self->get_sql('select_markers');
    $sth->execute($self->database_id($self->get_user_map_id()));

    my $marker_h = $self->get_sql('select_marker_by_alias');
    my $update_h = $self->get_sql('update_marker');
    while (my ($user_map_data_id, $marker_name) = $sth->fetchrow_array()) { 
	$marker_h->execute($marker_name);
	my ($marker_id) = $marker_h->fetchrow_array();
	if ($marker_id) { 
	    $update_h->execute($marker_id, $user_map_data_id);
	    print STDERR "Associated marker$marker_name with id $marker_id for row $user_map_data_id.\n";
	}
	else { 
	    print STDERR "$marker_name was not found in the SGN database.\n";
	}
    }
    print STDERR "Done assigning markers.\n";
}


=head2 import_map()
    
  Usage:         $usermap->import("/Users/mueller/example.map", 
			$name, $sp_personid)
  Desc:          imports the map given in the file into the 
                 SGN usermap tables
  Ret:           an empty list if successful, an array with line number and the
                 error found otherwise.
  Args:          a filename [string], the name of the map [string],
                 and a userid [int]
                 The file has the following columns, tab-delimited, with 
                 one header line that will be ignored:
                 marker_name [string]
                 marker_id [integer]
                 linkage_group [string]
                 position [cM] [real]
                 confidence 
                 protocol
  Side Effects:  changes the database contents!
  Example:       

=cut

 sub import_map {
     my $self = shift;
     my $filename = shift;
     my $name = shift;
     my $sp_person_id = shift;

     
     #print STDERR "Importing map...\n";
     #$self->set_name($name);
     $self->set_sp_person_id($sp_person_id);
     my $user_map_id = $self->store();
     #print STDERR "********* USER MAP ID = $user_map_id\n\n";
    my ($FILE);
    open($FILE, "<$filename") || die "Can't open the file $filename";
    my $line_count = 1;
     my $header_line = <$FILE>;  #exclude first header line.
    while (<$FILE>) { 
	chomp;
	if (/^\#/) { next; }  # exclude commented lines
	if (/^$/) { next; }   # exclude empty lines
	if (my $error = $self->check_line($_)) { 
	    return ($line_count, $error);
	}
	my ($marker_name, $marker_id, $linkage_group, $position, $confidence, $protocol) = split /\t/;

	my $user_map_db_id = $self->database_id($user_map_id);
	my $map_data = CXGN::People::UserMapData->new($self->get_dbh());
	$map_data->set_marker_name($marker_name);
	$map_data->set_user_map_id($user_map_id);
	$map_data->set_marker_id($marker_id);
	$map_data->set_linkage_group($linkage_group);
	$map_data->set_position($position);
	$map_data->set_confidence($confidence);
	$map_data->set_protocol($protocol);
	$map_data->set_user_map_id($user_map_db_id);
	$map_data->set_sp_person_id($sp_person_id);
	$map_data->set_obsolete('f');
	$map_data->store();
	$line_count++;
    }
    return ();
}




=head2 function create_schema()

  Synopsis:	CXGN::Map::User::create_schema($dbh)
  Arguments:	a valid database handle
  Returns:	nothing
  Side effects:	creates the sgn.user_map and sgn.user_map_data tables
                with appropriate permissions.
  Description:	

=cut

sub create_schema {
	#Didn't convert to CXGN::Class::DBI method due to creation infrequency
    my $dbh = shift;
    eval { 
	my $sgn_base = $dbh->base_schema("sgn");
	$dbh ||= DBH();	
	print STDERR "Generating table sgn_people.user_map...\n";
	my $create_user_map = "CREATE table sgn_people.user_map (
                             user_map_id serial primary key,
                             short_name varchar(40),
                             long_name varchar(100),
                             abstract text,
                             is_public boolean,
                             parent1_accession_id bigint REFERENCES $sgn_base.accession,
                             parent1 varchar(100),
                             parent2_accession_id bigint REFERENCES $sgn_base.accession,
                             parent2 varchar(100),
                             sp_person_id bigint REFERENCES sgn_people.sp_person,
                             obsolete boolean,
                             modified_date timestamp with time zone,
                             create_date timestamp with time zone
                           )";
	$dbh->do($create_user_map);
	print STDERR "adjusting access privileges for table user_map...\n";
	$dbh->do("GRANT select, update, insert ON sgn_people.user_map TO web_usr");
	print STDERR "...\n";
	$dbh->do("GRANT select, update, insert, delete ON sgn_people.user_map_user_map_id_seq TO web_usr");
	
	print STDERR "Generating table sgn_people.user_map_data...\n";
	my $create_user_map_data = 
	    "CREATE table sgn_people.user_map_data (
                             user_map_data_id serial primary key,
                             user_map_id bigint REFERENCES sgn_people.user_map,
                             marker_name varchar(50),
                             protocol varchar(50),
                             marker_id bigint REFERENCES $sgn_base.marker,
                             linkage_group varchar(20),
                             position numeric(20,4),
                             confidence varchar(20),
                             sp_person_id bigint REFERENCES sgn_people.sp_person,
                             obsolete boolean,
                             modified_date timestamp with time zone,
                             create_date timestamp with time zone
                           )";
	$dbh->do($create_user_map_data);
	print STDERR "Adjusting access privileges for table user_map_data...\n";
	$dbh->do("GRANT select, update, insert ON sgn_people.user_map_data TO web_usr");
	$dbh->do("GRANT select, update, insert, delete ON sgn_people.user_map_data_user_map_data_id_seq TO web_usr");
	print STDERR "Done!\n";
    };
    if ($@) { 
	print STDERR "Some frigging error occurred... rolling back...\n"; 
	$dbh->rollback();
    }
    else { 
	$dbh->commit();
	print STDERR "tables are created and committed!\n";
    }
}

sub database_id { 
    my $self =shift;
    my $id = shift;
    if ($id =~/u(\d+)/) { 
	return $1;
    }
    return $id;
}

sub set_sql { 
      my $self =shift;

      
      $self->{queries} = {
		
		fetch =>

		 	"
				SELECT 
					user_map_id, short_name, long_name, abstract, is_public, 
					parent1, parent2, sp_person_id, obsolete, modified_date, 
					create_date 
				FROM 
					sgn_people.user_map 
				WHERE 
					user_map_id=? 
					AND obsolete='f'
			",

		update =>

			"
				UPDATE sgn_people.user_map 
				SET 
					short_name =?,
					long_name =?, 
					abstract =?,
					is_public=?,
					parent1 = ?,
					parent2 = ?,
					sp_person_id=?,
					obsolete=?,
					modified_date=now()
				WHERE 
					user_map_id=?
			",

		insert =>
			
			"
				INSERT INTO sgn_people.user_map
					(short_name, long_name, abstract, is_public, parent1, parent2, 
					sp_person_id, obsolete, modified_date, create_date )
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, now(), now())
			",

		currval =>

			" SELECT currval('sgn_people.user_map_user_map_id_seq') ",

		delete_map =>

			"	
				UPDATE sgn_people.user_map 
				SET 
					obsolete='t' 
				WHERE 
					user_map_id=?
			",


		delete_map_data =>

			"
				UPDATE sgn_people.user_map_data 
				SET 
					obsolete='t' 
				WHERE 
					user_map_id=?
			",

		select_markers =>

 			"
				SELECT 
					user_map_data_id, 
					marker_name 
				FROM 
					sgn_people.user_map_data 
				WHERE 
					user_map_id=? 
					AND obsolete='f'
			",

   		select_marker_by_alias =>

			"
				SELECT 
					marker_id 
				FROM 
					sgn.marker_alias 
				WHERE alias=?
			",
   
   		update_marker =>

			"
				UPDATE 
					sgn_people.user_map_data 
				SET 
					marker_id=? 
				WHERE 
					user_map_data_id=?
			",

	};

	while(my($k,$v)=each%{$self->{queries}}){
		$self->{query_handles}->{$k} = $self->get_dbh()->prepare($v);
	}
}


sub get_sql {
    my $self =shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}


1;
