


=head1 NAME

BACMarkerAssoc - find BACs associated with markers and vice versa.           
           
=head1 SYNOPSYS

 my $bma = CXGN::Genomic::BACMarkerAssoc->new();
 my @markers = $bma->get_markers_with_clone_id( $clone_id );
 my @clones = $bma -> get_BACs_with_marker_id( $marker_id );
         
 # the returned arrays of hashrefs with the keys marker_id and type
 # giving the type of the association) or clone_id and type.

=head1 DESCRIPTION


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

package CXGN::Genomic::BACMarkerAssoc; 

use CXGN::DB::Object;
use base qw | CXGN::DB::Object |;


=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $self = $class->SUPER::new($dbh);
    return $self;
}

=head2 function get_markers_with_clone_id

  Synopsis:	
  Arguments:	a clone_id
  Returns:	an array of hashrefs. Keys are 
                marker_id, marker_name and association_type
  Side effects:	
  Description:	

=cut

sub get_markers_with_clone_id {
    my $self = shift;
    my $clone_id = shift;
    my $query = "SELECT marker_id, marker_alias.alias as marker_name, association_type FROM physical.bac_marker_matches join sgn.marker_alias using(marker_id) WHERE bac_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($clone_id);
    my @marker_info = ();
    while (my ($marker_id, $marker_name, $type) = $sth->fetchrow_array())  { 
	push @marker_info, { marker_id=>$marker_id, marker_name=>$marker_name, association_type=>$type };
    }
    return @marker_info;
	
}

=head2 function get_BACs_with_marker_id

  Synopsis:	
  Arguments:	a marker_id
  Returns:	a list of hashrefs, with the keys:
                clone_id and association_type. The association_type
                can either be overgo, computational, or manual.
  Side effects:	
  Description:	

=cut

sub get_BACs_with_marker_id {
    my $self = shift;
    my $marker_id = shift;
    
    my $query = "SELECT bac_id, association_type FROM physical.bac_marker_matches WHERE marker_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($marker_id);
    my @clone_info = ();
    while (my ($clone_id, $type) = $sth->fetchrow_array())  { 
	push @clone_info, { clone_id=>$clone_id, association_type=>$type };
    }
    return @clone_info;
    
}

1;
