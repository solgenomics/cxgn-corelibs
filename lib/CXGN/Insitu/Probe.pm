
=head1 NAME


=cut

##
  
use strict;

package CXGN::Insitu::Probe;

use CXGN::Insitu::Experiment;

use base qw / CXGN::Insitu::DB /;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;

    my $self = $class->SUPER::new($dbh);
    
    if ($id) { 
	$self->set_probe_id($id);
	$self->fetch_probe();
    }
    
    return $self;
}

=head2 fetch_probe

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch_probe {
    my $self = shift;
    my $query = "SELECT probe_id,
                        name,
                        sequence,
                        clone,
                        link_desc,
                        link,
                        dbxref_type_id,
                        identifier,
                        primer1,
                        primer1_seq,
                        primer2,
                        primer2_seq,
                        user_id
                   FROM insitu.probe
                  WHERE insitu.probe.probe_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_probe_id());
    my ($probe_id, $name, $sequence, $clone, $link_desc, $link, $dbxref_type_id, $identifier, $primer1, 
        $primer1_seq, $primer2, $primer2_seq, $user_id) = 
	    $sth->fetchrow_array();
    $self->set_probe_id($probe_id);
    $self->set_name($name);
    $self->set_sequence($sequence);
    $self->set_clone($clone);
    $self->set_link_desc($link_desc);
    $self->set_link($link);
    $self->set_dbxref_type_id($dbxref_type_id);
    $self->set_identifier($identifier);
    $self->set_primer1($primer1);
    $self->set_primer1_seq($primer1_seq);
    $self->set_primer2($primer2);
    $self->set_primer2_seq($primer2_seq);
    $self->set_user_id($user_id);
}

sub store { 
    my $self = shift;
    if ($self->get_probe_id()) {
	my $query = "UPDATE insitu.probe SET
                        name=?,
                        sequence=?,
                        clone=?,
                        link_desc=?,
                        link=?,
                        dbxref_type_id=?,
                        identifier =?,
                        primer1 = ?,
                        primer1_seq = ?,
                        primer2 = ?,
                        primer2_seq = ?,             
                        user_id=?
                     WHERE 
                        probe_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(),
		      $self->get_sequence(),
		      $self->get_clone(),
		      $self->get_link_desc(),
		      $self->get_link(),
		      $self->get_dbxref_type_id(),
		      $self->get_identifier(),
		      $self->get_primer1(),
		      $self->get_primer1_seq(),
		      $self->get_primer2(),
		      $self->get_primer2_seq(),
		      $self->get_user_id(),
		      $self->get_probe_id()
		      );
	return $self->get_probe_id();
    }
    else { 
	my $query = "INSERT INTO insitu.probe (
                       name, sequence, clone, link_desc, link, dbxref_type_id, identifier, primer1, primer1_seq, primer2, primer2_seq, user_id
                     ) VALUES (
                       ?, ?, ?, ?, ?, ?, ?,?,?,?,?,?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_name(),
		      $self->get_sequence(),
		      $self->get_clone(),
		      $self->get_link_desc(),
		      $self->get_link(),
		      $self->get_dbxref_type_id(),
		      $self->get_identifier(),
		      $self->get_primer1(),
		      $self->get_primer1_seq(),
		      $self->get_primer2(),
		      $self->get_primer2_seq(),
		      $self->get_user_id(),
		      );
	return $self->get_dbh()->last_insert_id("probe");
    }                    
}

sub delete { 
    my $self = shift;
    
    if (!$self->get_probe_id()) { # can't delete if not in db 
	return 1;
    }
    if ($self->get_experiments()) { # can't delete if has experiments
	return 2;
    }
    my $query = "UPDATE insitu.probe SET 
                        obsolete='t'
                  WHERE probe.probe_id =?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_probe_id());
    
    return 0;
}

=head2 get_probe_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_probe_id {
  my $self=shift;
  return $self->{probe_id};

}

=head2 set_probe_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_probe_id {
  my $self=shift;
  $self->{probe_id}=shift;
}



=head2 get_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name {
  my $self=shift;
  return $self->{name};

}

=head2 set_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_name {
  my $self=shift;
  $self->{name}=shift;
}

=head2 get_sequence

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_sequence {
  my $self=shift;
  return $self->{sequence};

}

=head2 set_sequence

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_sequence {
  my $self=shift;
  $self->{sequence}=shift;
}

=head2 get_clone

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_clone {
  my $self=shift;
  return $self->{clone};

}

=head2 set_clone

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_clone {
  my $self=shift;
  $self->{clone}=shift;
}

=head2 get_link_desc

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_link_desc {
  my $self=shift;
  return $self->{link_desc};

}

=head2 set_link_desc

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_link_desc {
  my $self=shift;
  $self->{link_desc}=shift;
}

=head2 get_link

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_link {
  my $self=shift;
  return $self->{link};

}

=head2 set_link

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_link {
  my $self=shift;
  $self->{link}=shift;
}

=head2 get_dbxref_type_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_type_id {
  my $self=shift;
  return $self->{dbxref_type_id};

}

=head2 set_dbxref_type_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_type_id {
  my $self=shift;
  $self->{dbxref_type_id}=shift;
}


=head2 get_identifier

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_identifier {
  my $self=shift;
  return $self->{identifier};

}

=head2 set_identifier

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_identifier {
  my $self=shift;
  $self->{identifier}=shift;
}

=head2 get_primer1

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_primer1 {
  my $self=shift;
  return $self->{primer1};

}

=head2 set_primer1

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_primer1 {
  my $self=shift;
  $self->{primer1}=shift;
}

=head2 get_primer1_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_primer1_seq {
  my $self=shift;
  return $self->{primer1_seq};

}

=head2 set_primer1_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_primer1_seq {
  my $self=shift;
  $self->{primer1_seq}=shift;
}

=head2 get_primer2

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_primer2 {
  my $self=shift;
  return $self->{primer2};

}

=head2 set_primer2

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_primer2 {
  my $self=shift;
  $self->{primer2}=shift;
}

=head2 get_primer2_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_primer2_seq {
  my $self=shift;
  return $self->{primer2_seq};

}

=head2 set_primer2_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_primer2_seq {
  my $self=shift;
  $self->{primer2_seq}=shift;
}



=head2 get_antibody

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_antibody {
  my $self=shift;
  return $self->{antibody};

}

=head2 set_antibody

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_antibody {
  my $self=shift;
  $self->{antibody}=shift;
}

=head2 get_comments

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_comments {
  my $self=shift;
  return $self->{comments};

}

=head2 set_comments

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_comments {
  my $self=shift;
  $self->{comments}=shift;
}




=head2 get_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_id {
  my $self=shift;
  return $self->{user_id};

}

=head2 set_user_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_id {
  my $self=shift;
  $self->{user_id}=shift;
}

=head2 get_experiments

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_experiments {
    my $self = shift;
    my $query = "SELECT experiment_id 
                   FROM insitu.experiment 
                   JOIN insitu.probe
                  USING (probe_id)
                  WHERE probe.probe_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_probe_id()); 
    my @experiments = ();
    while (my ($experiment_id) = $sth->fetchrow_array()) { 
	print STDERR "Instantiating experiment with id = $experiment_id\n";
	my $experiment = CXGN::Insitu::Experiment->new($self->get_dbh(),$experiment_id);
	push @experiments, $experiment;
	print STDERR "experiment: ".$experiment->get_experiment_id()."\n";
    }
    return @experiments;
}




# =head2 as_html

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub as_html { 
#     my $self = shift;
    
#     print 
# 	"Name: ". $self->get_name() ."<br />".
# 	"Sequence: ".$self->get_sequence()."<br />".
# 	"Link: ".$self->get_link()."<br />\n";

# }

=head2 get_all_probes

 Usage:
 Desc:         static function that retrieves two lists,
               one with probe names and one with probe ids.
 Ret:          ($names_array_ref, $ids_array_ref)
 Args:
 Side Effects: none
 Example:

=cut

sub get_all_probes { 
    my $dbh=shift;
    my $query = "SELECT probe_id, name
                   FROM insitu.probe";
    my $sth = $dbh->prepare($query);

    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my ($probe_id, $name) = $sth->fetchrow_array()) { 
	push @names, $name;
	push @ids, $probe_id;
    }
    return (\@names, \@ids);
}    



return 1;
