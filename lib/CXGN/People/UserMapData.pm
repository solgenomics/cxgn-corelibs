
use strict;

package CXGN::People::UserMapData;

use CXGN::DB::Object;
use CXGN::DB::ModifiableI;

use base qw | CXGN::Class::DBI CXGN::DB::Object CXGN::DB::ModifiableI |;

BEGIN {

	my %q = (
		
		fetch =>

			"
				SELECT 	
					marker_name, user_map_id, protocol, marker_id, 
					linkage_group, position, confidence, sp_person_id, 
					obsolete, modified_date, create_date 
				FROM 
					sgn_people.user_map_data 
				WHERE 
					user_map_data_id=? 
					AND obsolete='f'
			",

		update =>

			"
				UPDATE sgn_people.user_map_data SET
                       marker_name = ?,
                       user_map_id = ?,
                       protocol = ?,
                       marker_id = ?, 
                       linkage_group =?,
                       position = ?, 
                       confidence = ?,
                       sp_person_id = ?,
                       obsolete = ?,
                       modified_date = now()
				WHERE 
					user_map_data_id = ?
			",

		insert =>

			"
				INSERT INTO sgn_people.user_map_data
                     (marker_name, user_map_id, protocol, marker_id, 
					 linkage_group, position, confidence, sp_person_id, 
					 modified_date, create_date, obsolete)
				VALUES 
					(?, ?, ?, ?,
					 ?, ?, ?, ?, 
					 now(), now(), 'f')	
			",

		 currval =>
		 
 	                        " SELECT currval('sgn_people.user_map_user_map_id_seq') ",

		delete =>
			
			"
				UPDATE 
					sgn_people.user_map_date 
				SET 
					obsolete ='f' 
				WHERE 
					user_map_data_id=?
			",


	);

	while(my($k,$v) = each %q){
		__PACKAGE__->set_sql($k,$v);
	}
}

sub new { 
    my $class = shift;
    my $map_id = shift;
    my $self = CXGN::DB::Object->new();
	bless $self, $class;
    $self->set_user_map_id($map_id);
    $self->fetch();
    return $self;   
}

sub fetch { 
    my $self =shift;
    my $sth= $self->get_sql('fetch');
    $sth->execute($self->get_user_map_data_id());
    my ($marker_name, $user_map_id, $protocol, $marker_id, $linkage_group, $position, $confidence, $sp_person_id, $obsolete, $modified_date, $create_date) = $sth->fetchrow_array();
    $self->set_marker_name($marker_name);
    $self->set_user_map_id($user_map_id);
    $self->set_protocol($protocol);
    $self->set_marker_id($marker_id);
    $self->set_linkage_group($linkage_group);
    $self->set_position($position);
    $self->set_confidence($confidence);
    $self->set_sp_person_id($sp_person_id);
    $self->set_obsolete($obsolete);
    $self->set_modification_date($modified_date);
    $self->set_create_date($create_date);
}

=head2 store

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store {
	my $self = shift;
	if ($self->get_user_map_data_id()) { 
	
		my $sth = $self->get_sql('update');
		$sth->execute(
		      $self->get_marker_name(),
		      $self->get_user_map_id(),
		      $self->get_protocol(),
		      $self->get_marker_id(),
		      $self->get_linkage_group(),
		      $self->get_position(),
		      $self->get_confidence(),
		      $self->get_sp_person_id(),
		      $self->get_obsolete(),
		      $self->get_user_map_data_id()
		      );
		return $self->get_user_map_data_id();
    }
	else { 
		print STDERR "MARKER ID: ".$self->get_marker_id()."\n";
		
		my $sth = $self->get_sql("insert");
		$sth->execute(
			$self->get_marker_name(),
			$self->get_user_map_id(),
			$self->get_protocol(),
			$self->get_marker_id(),
			$self->get_linkage_group(),
			$self->get_position(),
			$self->get_confidence(),
			$self->get_sp_person_id(),
		);


		my $user_map_data_id = $self->get_sql("currval");

#		my $dbh = $self->DBH();
#		my ($user_map_data_id) = $dbh->get_currval("sgn_people.user_map_data_user_map_data_id_seq");
		$self->set_user_map_data_id($user_map_data_id);
		return $user_map_data_id;
	}
}

=head2 get_user_map_data_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_map_data_id {
  my $self=shift;
  return $self->{user_map_data_id};

}

=head2 set_user_map_data_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_map_data_id {
  my $self=shift;
  $self->{user_map_data_id}=shift;
}


=head2 accessors set_user_map_id, get_user_map_id

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

=head2 accessors set_marker_name, get_marker_name

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_name { 
my $self=shift;
return $self->{marker_name};
}

sub set_marker_name { 
my $self=shift;
$self->{marker_name}=shift;
}

=head2 accessors set_marker_id, get_marker_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_id { 
my $self=shift;
if (!exists($self->{marker_id}) || !($self->{marker_id})) { 
    $self->{marker_id}=undef;
}
return $self->{marker_id};
}

sub set_marker_id { 
my $self=shift;
$self->{marker_id}=shift;
}

=head2 accessors set_linkage_group, get_linkage_group

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_linkage_group { 
    my $self=shift;
    return $self->{linkage_group};
}

sub set_linkage_group { 
    my $self=shift;
    $self->{linkage_group}=shift;
}

=head2 accessors set_position, get_position

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_position { 
    my $self=shift;
    return $self->{position};
}

sub set_position { 
    my $self=shift;
    $self->{position}=shift;
}

=head2 get_protocol

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_protocol {
    my $self=shift;
    return $self->{protocol};
    
}

=head2 set_protocol

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_protocol {
    my $self=shift;
    $self->{protocol}=shift;
}


=head2 get_confidence

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_confidence {
  my $self=shift;
  return $self->{confidence};

}

=head2 set_confidence

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_confidence {
  my $self=shift;
  $self->{confidence}=shift;
}

=head2 delete

 Usage:
 Desc:         Deletes an entry in the user_map_data table. Note
               that deleting entire maps is dealt with from the
               UserMap object, not here.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self = shift;
    my $sth = $self->get_sql('delete');
    $sth->execute($self->get_user_map_data_id());
}


1;

