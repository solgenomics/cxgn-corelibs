package CXGN::Publish::VersionedFile;
use Moose;
use Moose::Util::TypeConstraints;

use Carp qw/cluck croak/;

use Path::Class ();

use CXGN::Publish;

=head1 NAME

CXGN::Publish::VersionedFile - class representing
a file path versioned with CXGN::Publish

=head1 SYNOPSIS

  my $vl = CXGN::CloneSequencing::FileRepository
                ->open($somedir)
                ->get_file_location('CloneSequence',$clone);

  $vl = CXGN::Publish::VersionedFile->from_path( $path );

=head1 ROLES

none

=head1 BASE CLASS(ES)

=head1 SUBCLASSES

=head1 ATTRIBUTES

Attributes are read-only unless otherwise specified.

current_file      - Path::Class::File for the current version of the file in this slot, if present

=cut

has 'current_file',
    ( is => 'ro',
    );

=pod

current_version   - current version number that is present

=cut

has 'current_version',
    ( is => 'ro',
    );

=pod

previous_versions - hash of  <version_num> => Path::Class::File, for previous versions that are present

=cut

has 'previous_versions',
    ( is => 'ro',
      isa => 'HashRef',
      auto_deref => 1,
    );

=pod

unversioned_path - unversioned path to this file, used to publish to this location

=cut

has 'unversioned_path',
    ( is => 'ro',
      isa => 'Str',
    );

=head1 METHODS

=head2 new

  Usage: my $vl = CXGN::Publish::VersionedFile->new( '/data/shared/foo.txt' );
  Desc : create a new VersionedFile object for the given
         file path or publishing history
  Args : publishing history path as returned by
         CXGN::Publish::publishing_history

         OR

         filesystem path (string),
         (optional) CXGN::Publish object to use to fetch
         that path's history
  Ret  : new VersionedFile object
  Side Effects: none

=cut

sub BUILDARGS {
    my $class = shift;
    my $pa = shift;

    unless( ref $pa eq 'HASH') {
        defined $pa or confess "must give a path to VersionedFile->new()";
        $pa = "$pa"; #< stringify in case it's a Path::Class::File
        #cluck "pa is $pa\n";
        my $publisher = shift || CXGN::Publish->new;
        ref $publisher && $publisher->isa('CXGN::Publish')
            or croak "second argument must be a publisher object, if passed";
        $pa = $publisher->publishing_history($pa);
    }

    my $previous_versions =
        {
         map { $_->{version} => Path::Class::File->new( $_->{fullpath} ) }
         @{$pa->{ancestors}}
        };


    #use Data::Dumper;
    #warn Dumper $pa;

    if( $pa->{obsolete_timestamp} ) {
        $previous_versions->{$pa->{version}} = Path::Class::File->new( $pa->{fullpath} );
        $class->SUPER::BUILDARGS( current_file => undef,
                                  current_version => undef,
                                  unversioned_path => $pa->{fullpath_unversioned},
                                  previous_versions => $previous_versions,
                                );

    } else {
        $class->SUPER::BUILDARGS( current_file => $pa->{fullpath} ? Path::Class::File->new( $pa->{fullpath} ) : undef,
                                  current_version => $pa->{version},
                                  unversioned_path => $pa->{fullpath_unversioned},
                                  previous_versions => $previous_versions,
                                );
    }
}

=head2 publish_new_version

  Usage: my $pub_cmd = $file->publish_new_version( $newfile )
  Desc : creates a command for CXGN::Publish that will copy the given
         filename into place as a new version of this versionedfile
  Args : filename or Path::Class::File
  Ret  : command suitable for passing to CXGN::Publish
  Side Effects:
  Example:

    $publisher->publish( $file->publish_new_version( $my_new_file ) )

=cut

sub publish_new_version {
  my ( $self, $newfile ) = @_;

  return [ cp => $newfile => $self->unversioned_path ];
}


=head2 publish_remove

  Usage: my $pub_cmd = $file->publish_new_version( $newfile )
  Desc : creates a command for CXGN::Publish that will remove the 
  Args : filename or Path::Class::File
  Ret  : command suitable for passing to CXGN::Publish
  Side Effects:
  Example:

    $publisher->publish( $file->publish_remove )

=cut

sub publish_remove {
  my ( $self ) = @_;

  return unless $self->current_file;

  return [ rm => $self->unversioned_path ];
}

=head1 MAINTAINER

Robert Buels

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
