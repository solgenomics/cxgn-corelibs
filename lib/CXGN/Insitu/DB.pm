

use strict;

package CXGN::Insitu::DB;

sub new { 
    my $class = shift;
    my $dbh = shift;
    
    if (!$dbh) { 
	die "CXGN::Insitu::DB: need a database handle";
    }
    if (ref($dbh) ne "CXGN::DB::Connection") { 
	die "Need a database handle as argument!\n";
    }
    my $self = bless {}, $class;

    $self->set_dbh($dbh);

    return $self;
}

=head2 get_dbh, set_dbh

 Usage:        Accessors for the dbh property
 Desc:         the database handle is set in the 
               constructor and it should never be 
               necessary to call the setter. Always use
               the getter to obtain a database handle,
               do not try to cache it in some cheesy variable.
 Ret:          setter: database handle (fresh!)
 Args:         getter: a valid database handle, preferably
               in the form of a CXGN::DB::Connection object. 
 Side Effects: this database handle is used in all database
               transactions of this object.
 Example:

=cut

sub get_dbh {
  my $self=shift;
  return $self->{dbh};

}

sub set_dbh {
  my $self=shift;
  $self->{dbh}=shift;
}

=head2 stats

  Synopsis:	my ($exp_count, $image_count, $tag_count)
                    = $insitu ->stats();
  Arguments:	none
  Returns:	a list of three values, representing the 
                number of experiments, images and counts 
                associated with the insitu database.
  Side effects:	none
  Description:	

=cut

sub stats { 
    my $self = shift;
    
    my $e_count_q = "SELECT count(*) FROM insitu.experiment";
    my $eh = $self->get_dbh()->prepare($e_count_q);
    $eh->execute();
    my ($e_count) = $eh->fetchrow_array();

my $i_count_q = "SELECT count(*) FROM metadata.md_image join insitu.experiment_image using (image_id)";
    my $ih = $self->get_dbh()->prepare($i_count_q);
    $ih->execute();
    my ($i_count) = $ih->fetchrow_array();

    my $t_count_q = "SELECT count(*) FROM metadata.md_tag join insitu.experiment_tag using (tag_id)";
    my $th = $self->get_dbh()->prepare($t_count_q);
    $th->execute();
    my ($t_count) = $th->fetchrow_array();
    
    return ($e_count, $i_count, $t_count);
}

return 1;
