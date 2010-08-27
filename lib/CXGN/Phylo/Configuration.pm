package CXGN::Phylo::Configuration;

=head1 NAME

CXGN::Phylo::Configuration -- configuration information for the Phylo package

=head1 DESCRIPTION

The idea of this class is to abstract the SGN configuration so that this wonderful piece of software can be run independently of the SGN system. 

People wishing to use the software have to fill in the function of the module with the appropriate values for their site.

=cut

use strict;
use warnings;
use SGN::Context;

sub new { 
    my $class = shift;
    my $args = {};
    my $self = bless $args, $class;
    return $self;
}

=head2 function get_temp_dir()

  Synopsis:	$temp_file_dir = $configuration->get_temp_file_dir()
  Arguments:	none
  Returns:	the fully qualified path of the temp file directory
                This needs to be writable by the Apache user (nobody, www-data,
                or whatever it is).
  Side effects:	the temporary files created by tree browser will be stored 
                there. The directory will need to be cleaned from time to time 
                by something like a cron job.
  Description:	

=cut

sub get_temp_dir {
    my $self = shift;
    my $vhost = SGN::Context->new;
    $self->{temp_dir} = $vhost->get_conf("basepath").$vhost->get_conf("tempfiles_subdir")."/tree_browser";
}
1;
