package CXGN::FileRepository::FileClass;
use Moose::Role;

use English;
use Carp;

use File::Spec;

=head1 NAME

CXGN::FileRepository::FileClass - a role for a certain class of files in the repository

=head1 SYNOPSIS

  -f $class->get_vf($clone,'other_data')->current_file

=head1 ATTRIBUTES

repository - the FileRepository this belongs to

=cut

has 'repository',
    ( is => 'ro',
      isa => 'CXGN::FileRepository',
      required => 1,
    );

=head1 REQUIRES

=head2 search_vfs

  Method, takes an optional hash of metadata, and returns a
  possibly-empty list of matching CXGN::FileRepository::VersionedFile
  objects that have already been published.

=cut

requires 'search_vfs';

=head2 get_vf

  Method, takes an optional hash of metadata, and returns a
  single CXGN::FileRepository::VersionedFile objects.  Dies
  if the metadata are not sufficiently specific to narrow it
  to one versionedfile.

=cut

requires 'get_vf';

=head1 METHODS

=head2 vf

  $fileclass->vf('foo','bar','baz.txt');
  #returns a VersionedFile for $repos_root/foo/bar/baz.txt

Get a L<CXGN::FileRepository::VersionedFile> object for the given file
path.

=cut

sub vf {
    my ($self, @name) = @_;

    return CXGN::FileRepository::VersionedFile
        ->new( $self, $self->repository->basedir->file( @name ))

}

=head2 vfs_by_glob

  $repos->vfs_by_glob( 'bar','*','baz.*' );

Just like file(), but does a glob() on the passed file path if it looks
like a glob expression, and returns a list of
L<CXGN::FileRepository::VersionedFile> objects.

=cut

# if the file path is not specific, run glob on it and then run
# publishing history on the results.  this will not pick up obsolete
# vfs that may be there.
sub vfs_by_glob {
    my $self = shift;
    my $str = File::Spec->catfile(@_);

    if( $str =~ /[ \* \[ \] { } ]/x ) { 
        # looks like a glob, search vfs and make versionedfile
        # objects for them
        return map {CXGN::FileRepository::VersionedFile->new($self,$_)} glob($self->repository->basedir->file($str)->stringify)
    } else {
        # just make a versionedfile object for it
        return $self->file($str);
    }
}

=head2 vfs_by_rule

  $repos->vfs_by_rule( File::Find::Rule->file->named(qr/bar\.txt/);

Use a L<File::Find::Rule>, run in() the repository's root directory,
to find matching vfs.

=cut

sub vfs_by_rule {
  my ( $self, $rule ) = @_;

  $rule->can('in')
      or croak "must pass a File::Find::Rule or equivalent object";

  return
      map CXGN::FileRepository::VersionedFile->new($self,$_),
      $rule->in( $self->repository->basedir->stringify );
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
no Moose::Role;
1;
###
