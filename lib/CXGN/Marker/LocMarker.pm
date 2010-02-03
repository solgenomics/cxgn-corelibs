package CXGN::Marker::LocMarker;

# this subclass of CXGN::Marker represents a marker that only 
# knows about one of its locations. It is read-only.

use base ('CXGN::Marker');

sub new {

  my ($class, $dbh, $marker_id, $locargs) = @_;

#  warn "+++ $class $marker_id $location_id\n";

  my $self = $class->SUPER::new($dbh,$marker_id);
  $self->{loc} = $locargs;
  return $self;

}

################################################
### first, the location stuff - simple accessors

sub location_id {
  my ($self) = @_;
  return $self->{loc}{location_id};
}

sub lg_name {
  my ($self) = @_;
  return $self->{loc}{lg_name};
}

# same thing, easier to remember
sub chr {
  my ($self) = @_;
  return $self->{loc}{lg_name};
}

sub position {
  my ($self) = @_;
  return $self->{loc}{position};
}

sub subscript {
  my ($self) = @_;
  return $self->{loc}{subscript};
}

sub confidence {
  my ($self) = @_;
  return $self->{loc}{confidence_name} if $self->{loc}{confidence_name};
  $self->{loc}{confidence_name} = $self->{dbh}->selectrow_array("select confidence_name from marker_confidence where confidence_id = $self->{loc}{confidence_id}");

  return $self->{loc}{confidence_name};
}

sub map_version {
  my ($self) = @_;
  return $self->{loc}{map_version_id};
}

sub map_id {
  my ($self) = @_;
  return $self->{map_id} if $self->{map_id};

  # we only know the map version, so query to get the map
  my $q = $self->{dbh}->prepare("SELECT map_id FROM map_version WHERE map_version_id=?");

  $q->execute($self->{loc}{map_version_id});
  #there can only be one result
  my ($answer) = $q->fetchrow_array();
  $self->{map_id} = $answer;

  return $answer;
  
}



####################################################
### slightly more complicated accessors for slightly
### more indirect questions

sub _get_parents {

  my ($self) = @_;

  my $map = $self->map_id();
  my $q = $self->{dbh}->prepare("SELECT accession_name, organism_name, common_name FROM plants INNER JOIN map ON(map.parent_1=accession_id OR map.parent_2=accession_id) WHERE map_id = ?");

  $q->execute();
  $self->{parents} = $q->fetchall_arrayref([0]);

#  use Data::Dumper;
#  print Dumper $self->{parents};
  

}

sub accessions {
  my ($self) = @_;


}

sub organisms {
  my ($self) = @_;
#  return $self->{loc}{};
}

sub species {
  my ($self) = @_;
#  return $self->{loc}{lg_name};
}

sub experiment_protocol {
  my ($self) = @_;
#  return $self->{loc}{lg_name};
}

sub plausible_overgo {
  my ($self) = @_;
#  return $self->{loc}{lg_name};
}


1;










