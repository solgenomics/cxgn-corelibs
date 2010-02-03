package Bio::GMOD::Blast::Graph::BaseObj;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------


###############################################################
sub new {
###############################################################
    my( $class, @args ) = @_;

    my( $self ) = {};
    bless( $self, $class );
    $self->init( @args );

    return( $self );
}

###############################################################
sub init {
###############################################################
    my( $self ) = shift;

}
###############################################################
1;
###############################################################
