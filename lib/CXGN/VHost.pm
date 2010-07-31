=head1 NAME

CXGN::VHost - backwards-compatible context object to help smooth our
transition to Catalyst

=head1 SYNOPSIS

  my $vhost = CXGN::VHost->new;

  # Catalyst-compatible
  print "my_conf_variable is ".$vhost->config->{my_conf_variable};

  # old-SGN compatible
  print "my_conf_variable is ".$vhost->get_conf('my_conf_variable');

=head1 OBJECT METHODS

=cut

package CXGN::VHost;
use Moose;
use namespace::autoclean;
use Carp;
extends 'SGN::Context';

carp <<EOM;
CXGN::VHost is deprecated, please remove this use.

For most modules, all database connections, paths, etc that are now
being read from CXGN::VHost should be passed in via mandatory
arguments to new(), or similar.
EOM

after 'new' => sub { croak <<EOM unless $ENV{MOD_PERL} || $ENV{CATALYST_ENGINE} || $ENV{GATEWAY_INTERFACE} };
CXGN::VHost is not available for use outside of code running under the SGN website.
EOM

# backwards-compatibility methods
around 'get_conf' => sub {
    my $orig = shift;
    my $self = shift;
    my $val = eval{ $self->$orig(@_) };
    $val = undef if $@;
    return $val->[0] if ref $val eq 'ARRAY';
    return $val;
};

sub get_conf_arrayref {
    shift->config->{+shift}
}


### some of this might be useful someday for build tests, so keep
### them here commented out where they are more greppable

# sub test_config {
#     my $self = shift;

#     #check for presence of required settings
#     foreach my $key (qw/ project_name
# 			 servername
# 			 basepath
# 			 perllib_path
# 			 production_server
# 			 /
# 		     ) {

# 	unless ( defined $self->{vhost_config}->{$key} ) {
# 	    $self->print_warning("No $key given; unable to create vhost object.");
# 	    return 0;
# 	}
#     }

#     #make sure we can create a configuration object
#     my $conf = $self;

#     #now run any test we can think of which might catch a problem before it happens.

#     # check basepath
#     my $basepath = $self->{basepath};
#     unless ( -d ($basepath) ) {
#         $self->print_warning("Basepath '$basepath' not found.");
#         return 0;
#     }

#     # check perllib path
#     my $perllib_path = $self->{perllib_path};
#     unless ( -d ($perllib_path) ) {
#         $self->print_warning("Perllib path '$perllib_path' not found.");
#         return 0;
#     }

#     # check document root
#     my $docroot = $conf->get_conf('document_root_subdir');
#     unless ( -d ( $basepath . $docroot ) ) {
#         $self->print_warning("Document root '$basepath$docroot' not found.");
#         return 0;
#     }

#     # check executables subdir
#     my $executable_subdir = $conf->get_conf('executable_subdir');
#     if ($executable_subdir) {
#         unless ( -d ( $basepath . $executable_subdir ) ) {
#             $self->print_warning(
#                 "Executable directory '$basepath$executable_subdir' not found."
#             );
#             return 0;
#         }
#     }

#     my $data_shared_website_path = $conf->get_conf('data_shared_website_path');
#     if ($data_shared_website_path) {
#         unless ( -d ($data_shared_website_path) ) {
#             $self->print_warning(
# "Data shared website path '$data_shared_website_path' not found. Attempting configuration anyway."
#             );
#         }
#     }

#     my $rewrite_log = $conf->get_conf('rewrite_log');
#     if ($rewrite_log) {
#         unless ( -f ( $basepath . $rewrite_log ) ) {
#             $self->print_warning(
# "Rewrite log file '$basepath$rewrite_log' not found. Apache will attempt to create this file. If apache cannot create this file, it WILL FAIL TO START."
#             );
#         }
#     }

#     return 1;    #all tests passed
# }


###
1;#do not remove
###
