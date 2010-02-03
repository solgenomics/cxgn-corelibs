package CXGN::FileRepository;
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

use English;
use Carp;

use File::Path;
use Path::Class;

use CXGN::FileRepository::VersionedFile;

=head1 NAME

CXGN::FileRepository - versioned file repository

=head1 SYNOPSIS

  # open a repository that contains versioned files
  my $repos = CXGN::FileRepository
                 ->new( '/some/directory/somewhere/' );


  # get a certain CXGN::FileRepository::VersionedFile for the file in
  # FileClass 'MyFoo' that has metadata bar => 'baz', boo => 'blorg'
  # DIES if the given attributes are not specific enough
  my $versionedfile = $repos->get_vf( class => 'MyFoo',
                                      bar => 'baz',
                                      boo => 'blorg',
                                    );

  # same as get_vf, but returns a Path::Class::File object for the
  # current version of the specified file, or nothing if there is no
  # current version
  my $file = $repos->get_file( metadata... )

  # function to search for VersionedFiles matching some attributes
  my @versionedfiles = $repos->search_vfs( class => 'MyBar',
                                           something => 'something',
                                         );

  # same as above, but returns Path::Class::File objects for current
  # versions
  my @files = $repos->search_vfs( same... )

  # publish a new version of the MyFoo in $versionedfile, and
  # remove/unpublish all the files in @versionedfiles, all in one
  # CXGN::Publish transaction

  $repos->publish(  $versionedfile->publish_new_version( '/foo/bar.txt' ),
                    map $_->publish_remove, @versionedfiles
                 );


=head1 DESCRIPTION

Representation of a file repository of clone sequences, annotations,
and other data

=head1 ROLES

none

=head1 BASE CLASS(ES)

none

=head1 SUBCLASSES

none

=head1 ATTRIBUTES

Attributes are read only unless otherwise noted.

  basedir - (Path::Class::Dir) base directory for this file repository.

  create - boolean, whether this repos is set to create its own base
           dir

  publisher - CXGN::Publish object to use for publishing files to this
              repository

=cut

# and define the basedir attribute
has basedir =>
    ( is => 'ro',
      isa => 'Path::Class::Dir',
    );

has create =>
    ( is => 'ro',
      isa => 'Bool',
    );

has publisher =>
    ( is => 'ro',
      isa => 'CXGN::Publish',
      required => 1,
      default => sub {
          my $p = CXGN::Publish->new;
          $p->make_dirs(1);
          return $p;
      },
      handles => ['publish'],
    );

=head1 METHODS

=head2 new

  Usage: my $repos =
            CXGN::FileRepository
              ->new( '/data/prod/public/foo' )
  Desc : open an existing file repository, dies if does
         not exist and create => 1 not passed
  Args : basedir => string dirname or Path::Class::Dir,
         create => 1, #< will create dir and parent dirs if not
                      #  present
         # OR single argument
         string dirname or Path::Class::Dir, interpreted
         as the basedir you want
  Ret  : FileRepository object

=cut

sub BUILDARGS {
    my $class = shift;

    my %args = @_ == 1 ? (basedir => @_) : @_;

    # check required basedir
    defined $args{basedir}
        or croak "no 'basedir' argument passed, and it is required";

    # coerce basedir to Path::Class::Dir
    unless( ref $args{basedir} && $args{basedir}->can('stringify') ) {
        $args{basedir} = Path::Class::Dir->new( "$args{basedir}" );
    }

    # create our basedir if create was passed
    my $d = $args{basedir}->stringify;
    unless( -d $d ) {
        $args{create}
            or croak "basedir '$d' does not exist, maybe you want to specify create => 1 to create it?\n";
        mkpath( $d )
          or croak "$! creating '$d'";
        -d $d or die 'sanity check failed';
    }

    return $class->SUPER::BUILDARGS( %args );
}


=head2 publish

  Usage: $repos->publish( [op], [op] )
  Desc : do a publish operation using this repo's publisher object
  Args : publish operation arrayrefs,
         same as L<CXGN::Publish> publish()
  Ret  : nothing meaningful
  Side Effects: does publish operations

=cut

# this method created by 'handles' delegation on publisher attribute

=head2 search_files

  Usage: my @files = $repo->search_files( %args );
  Desc : search for files present in their current versions in the
         repository
  Args : search criteria as a hash-list
  Ret : list of matching files as Path::Class::File objects (possibly
        empty), in no particular order
  Side Effects:
  Example:

     # get a list of files in the current version of the repo that are
     # CloneSequence files, of type fasta, belonging to the given
     # clone object
     my @files = $repo->search_files( class => 'CloneSequence',
                                      type  => 'fasta',
                                      clone => $clone,
                                    );


=cut

sub search_files {
    my $self = shift;

    # return the current_file, for those VFs that have them
    map $_->current_file || (), $self->search_vfs( @_ );
}

=head2 search_vfs

  Same as search_files, but returns CXGN::FileRepository::VersionedFile
  objects for all matching files that have already been published.

=cut

sub search_vfs {
    my ($self, %conditions) = @_;

    my $fileclass_condition = delete $conditions{class};
    my @classes =  $fileclass_condition
        ? ($self->_find_class_or_die($fileclass_condition))
        : $self->file_classes;

    return map { $_->search_vfs( %conditions ) }
           @classes
}


=head2 get_file

  Same as search_files, but returns just one Path::Class::File, or
  nothing if no such file currently exists.  Dies if the search
  conditions are not specific enough to specify exactly one file.

=cut

sub get_file {
    my $self = shift;

    my $r = $self->get_vf(@_);

    return $r->current_file if $r;

    return;
}

=head2 get_vf

  Same as search_files, but returns just one VersionedFile, regardless
  of whether a file currently exists for it.

=cut

sub get_vf {
    my $self = shift;

    my %conditions = @_;

    my $class = delete $conditions{class}
        or croak "must specify a class in call to get_vf";

    my $fileclass_obj = $self->_find_class_or_die($class);

    return $fileclass_obj->get_vf( %conditions );
}


sub _find_class_or_die {
    my ( $self, $classname ) = @_;

    my $class = ref $self;
    my @search_classes =
        ( $classname,
          "${class}::FileClass::$classname",
        );

    foreach my $class ( @search_classes ) {
        unless( Class::MOP::is_class_loaded($class) ) {
            #it is not loaded, try to load it
            eval { Class::MOP::load_class( $class ) };
            next if $@;
        }

        return $class->new( repository => $self );
    }

    confess "could not find file class matching '$classname', searched for ".join(',',@search_classes);
}


=head2 file_classes

  Usage: my @classes = $repos->file_classes
  Desc : list all the file classes present in the repos
  Args : none
  Ret  : list of file class objects for this repos

=cut

# makes a method _fileslots() that instantiates a list of all FileSlot
# objects in this namespace, except those which end with Base
use Module::Pluggable::Object ();
use Devel::InnerPackage ();

sub file_classes {
    my $self = shift;
    my $class = ref $self;

    my $exclude_pat    = qr/Base$/; #< exclude all packages ending in Base
    my $fileclass_base = $class."::FileClass";

    my $finder =
        Module::Pluggable::Object
              ->new( exclude     => $exclude_pat,
                     search_path => $fileclass_base,
                     require => 1,
                   );

    $finder->plugins( );

    my @fileclasses =
        grep {$_ !~ $exclude_pat}
        Devel::InnerPackage::list_packages($fileclass_base);

    #warn "$class got file classes: ".join ', ', @fileclasses;

    return sort map {$_->new( repository => $self ) } @fileclasses;
}


=head1 MAINTAINER

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 AUTHOR

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

####
__PACKAGE__->meta->make_immutable;
no Moose;
1;
###
