=head1 NAME

CXGN::Config - L<Config::Any>-based implementation of cascading config files

=head1 SYNOPSIS

  my $cfg = MyProj::MyConfig->load_locked;
  print "the basepath variable is $cfg->{basepath}\n";

=head1 DESCRIPTION

Implementation of cascading config files.

To use:

=over

=head2 1. Subclass CXGN::Config for your project's configuration

       package MyProj::MyConfig;
       use base 'CXGN::Config';
       my $defaults = {

          foo => 'bar',
          baz => 'quux',
          # and so on

       };
       sub defaults { shift->SUPER::defaults( $defaults, @_ )}
       1;

=head2 2. That's all!

When users call

      my $cfg = MyProj::MyConfig->load_locked;

they will get a locked hashref of config values from the following
cascading sources, merged with later sources taking precedence:

=over

=item defaults in CXGN::Config

=item defaults in any intermediate classes between CXGN::Config and MyProj::MyConfig

=item defaults in MyProj::MyConfig

=item values in /etc/cxgn/Global.conf

=item values in /etc/cxgn/MyProj.conf

=back

load() also takes some optional arguments which can be used to tweak
which sources are used for configuration, etc.

=cut

package CXGN::Config;
use strict;

use Carp;
use Cwd ();
use File::Spec;
use FindBin;
use Hash::Merge ();

use Memoize ();

use Config::Any;

our @search_path = $ENV{CXGN_CONF_DIR}
    ? ( $ENV{CXGN_CONF_DIR} )
    : map Cwd::realpath(File::Spec->rel2abs(File::Spec->catdir(@$_))),
      (
       [ File::Spec->rootdir, 'etc', 'cxgn' ], # /etc/cxgn
      );

=head1 CLASS METHODS

=head2 load

  Status  : public
  Usage   : my $cfg = MyProj::MyConfig->load();
  Returns : hashref of merged config values
  Args    : optional hash-style list of options as:

              name => conf file basename to load
                      default: first portion of class name, e.g.
                         'CXGN' for CXGN::Config
                      if 'undef' is passed, searches only Global.conf

              add_vals => hashref of additional config values to
                          include, overriding any loaded ones


              the following options are planned but not yet
              implemented:

              add_files => arrayref of additional config files to
                           merge in, which will take precedence over
                           ones automatically discovered by this
                           module

  Side Eff: none

Loads and merged multiple cascading config files.  L<Config::Any> is
used for parsing each one.

Merge order (values in later files take precedence):

    defaults in CXGN::Config
    defaults in any intermediate classes between CXGN::Config and MyProj::MyConfig
    defaults in MyProj::MyConfig
    /etc/cxgn/Global.conf
    /etc/cxgn/<name>.conf

B<NOTE:> For an additional layer of protection, consider using
L<"load_locked"> rather than C<load>.

=cut

sub load {
    my ( $class, %args ) = @_;

    my @search_files = $class->_search_files( %args );

    my @found_files = grep -f, @search_files;

    my $cfg = $class->defaults;
    foreach my $file ( @found_files ) {
        my $c = Config::Any
                  ->load_files({ files => [$file],
                                 override => 1,
                                 use_ext => 0,
                               });
        $c && @$c or die "could not parse config file '$file'";

        $class->_merge_hashes($cfg, $c->[0]->{$file});
    }

    if( my $v = $args{add_vals} ) {
        ref $v eq 'HASH' or croak 'add_vals must be a hashref';
        $class->_merge_hashes($cfg, $v);
    }

    return $cfg;
}

=head2 load_locked

Same as load() above, but locks the hash with lock_hash() from
L<Hash::Util> before returning it.

This means that an error will be thrown if code tries to access a
configuration variable that is not set or change a configuration
variable, which provides a useful layer of error checking in many
situations.

Using this also provides a performance benefit, since the return value
of C<load_locked> is cached, while C<load> is not.

Most users of CXGN::Config-based modules will want to use
C<load_locked> rather than L<"load">.

=cut

Memoize::memoize 'load_locked',
    # normalize the args by adding the modification time of each file,
    # so that the result will continue to be cached as long as the
    # modification times of each of the files stays the same
    NORMALIZER => sub {
        my $class = shift;
        my @search_files = $class->_search_files( @_ );
        return join ',', ( $class, @_, map { $_ => (stat $_)[9] } @search_files );
    },
    ;

sub load_locked {
    my $class = shift;
    my $cfg = $class->load(@_);
    { no warnings;
      require Hash::Util;
      Hash::Util::lock_hashref( $cfg );
    }
    return $cfg;
}

# class method, takes the config name (like 'SGN'), and returns the
# list of full paths of files to search for
my %_search_files_cache;
sub _search_files {
    my $result = $_search_files_cache{ join ',', @_ } ||= [ shift->__search_files(@_) ];
    return @$result;
}
sub __search_files {
    my ($class, %args) = @_;

    #set defaults
    my $cfg_name = exists $args{name}
        ? $args{name}
        : $class->_conf_name;

    my @conf_basenames = ('Global', defined $cfg_name ? $cfg_name : () );

    return map {
        my $path = $_;
        map File::Spec->catfile($path, "$_.conf" ), @conf_basenames;
    } @search_path;
}

# e.g.  Foo::Conf::Baz->_conf_name returns 'Foo'
sub _conf_name {
    my $classname = shift;
    return if $classname eq __PACKAGE__; # don't search for CXGN.conf
    my ($cn) = $classname =~ /^(?:CXGN::)?([^:]+)/
        or die "error parsing class name $classname";

    return $cn;
}

# merge all the other hashes into the first hash, modifying the first
# hash in place
sub _merge_hashes {
    my $class = shift;
    my $h1 = shift;
    for my $h2 (@_) {
        for ( keys %$h2 ) {
            $h1->{$_} = $h2->{$_};
        }
    }
    return $h1;
}

=head2 defaults

  Status  : public
  Usage   : CXGN::Config::MyConfig->merge_defaults({ foo => bar })
  Returns : hashref of this class's default values merged with any
            hashrefs that it is passed
  Args    : optional hashrefs of default values to merge in,
            with the rightmost hash taking precedence
  Side Eff: none
   Examples:
     # recommended implementation in a CXGN::Config subclass:
     my $defaults = {
         foo => 'bar',
         baz => 'boo',
         ...
     };
     sub defaults {
         # pass this class's defaults to the superclass, which will
         # merge them into its own defaults and return the result
         shift->SUPER::defaults( $defaults, @_ )
     }

=cut

our $defaults; #< this hashref is filled below
sub defaults {
    #operate on a shallow copy of our defaults
    return shift->_merge_hashes({%$defaults}, @_ );
}

$defaults =
    {
     #who to contact, these addresses will be used by modules which send us emails, among other things
     email                    => 'sgn-feedback@solgenomics.net',

     #default database to connect to and how to connect to it
     dbhost                   => 'db.sgn.cornell.edu',
     dbname                   => 'cxgn',
     dbuser                   => 'web_usr',
     #dbpass                   => undef,
     dbsearchpath             => [qw[
                                     sgn
                                     public
                                     annotation
                                     genomic
                                     insitu
                                     metadata
                                     pheno_population
                                     phenome
                                     physical
                                     tomato_gff
                                 ]],

     cview_db_backend         => 'cxgn',

     # path for cxgn core perllib
     cxgn_core_perllib        => '/data/local/cxgn/core/cxgn-corelibs/lib',

     #how to find blast stuff
     blast_path               => '',
     blast_db_path            => '/data/shared/blast/databases/current',

     #the shared temp directory used by cluster nodes
     cluster_shared_tempdir   => '/data/prod/tmp',

     #R qtl tempfiles (must be cluster accessible)
     r_qtl_temp_path          => '/data/prod/tmp/r_qtl',

     #how verbose we want the warnings to be in the apache error log
     verbose_warnings         => 1,

     # Insitu file locations
     insitu_fullsize_dir      => '/data/prod/public/images/insitu/processed',
     insitu_fullsize_url      => '/data/images/insitu/processed',
     insitu_display_dir       => '/data/prod/public/images/insitu/display',
     insitu_display_url       => '/data/images/insitu/display',
     insitu_input_dir         => '/data/prod/public/images/insitu/incoming',

     #path to our production ftp site
     ftpsite_root             => '/data/prod/public',
     ftpsite_url              => 'ftp://ftp.solgenomics.net',

     #path to the pucebaboon temperature sensor file:
     pucebaboon_file	      => '/data/prod/public/digitemp.out',

     #gbrowse stuff
     bacs_bio_db_gff_dbname   => 'bio_db_gff',

    };

###
1;#do not remove
###

=head1 AUTHOR

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 The Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

