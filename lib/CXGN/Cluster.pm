
=head1 NAME

CXGN::Cluster classes

=head1 DESCRIPTION

The CXGN::Cluster classes help keep track of clusters of sequences, assemble new clusters from data such as blast reports, and output clusters in multi-fasta files etc.

'use'ing this file will pull in CXGN::Cluster::Object, CXGN::Cluster::Precluster, and CXGN::Cluster::ClusterSet.

=head2 Notes on the classes:

=over 5

=item L<CXGN::Cluster::Object>

the base object of the CXGN::Cluster classes. Essentially contains the set_debug and debug functions, which are inherited by all classes.

=item L<CXGN::Cluster::ClusterSet>

represents a set of preclusters.

=item L<CXGN::Cluster::Precluster>

represents a cluster composed of sequence members. Only the IDs are stored.


=back

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

use CXGN::Cluster::Object;
use CXGN::Cluster::Precluster;
use CXGN::Cluster::ClusterSet;




return 1;
