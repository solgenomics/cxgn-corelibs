
=head1 NAME

CXGN::Cluster::Object

=head1 DESCRIPTION

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

package CXGN::Cluster::Object;

=head2 new()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $args = {};
    my $self = bless $args, $class;
    return $self;
}

=head2 get_debug()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_debug {
  my $self=shift;
  return $self->{debug};

}

=head2 set_debug()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_debug {
  my $self=shift;
  $self->{debug}=shift;
}

sub debug { 
    my $self = shift;
    my $message = shift;
    if ($self->get_debug()) {
	print STDERR "$message";
    }
}

return 1;
