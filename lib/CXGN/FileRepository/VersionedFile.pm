package CXGN::FileRepository::VersionedFile;
use Moose;

use English;
use Carp;

=head1 NAME

CXGN::FileRepository::VersionedFile - a specific versioned file in a repository

=head1 SYNOPSIS

  my $vf = $repos->find_file( class => 'AllCloneSequences',
                              format => 'fasta',
                            );

  my $fh = $vf->current_file->open('<'); #< see IO::File::open
  print while <$fh>;

=head1 BASE CLASS(ES)

L<CXGN::Publish::VersionedFile>

=cut

extends 'CXGN::Publish::VersionedFile';

=head1 SUBCLASSES

=head1 ATTRIBUTES

file_class - the FileClass object for this file

repository - the FileRepository this file belongs to

=cut

has 'file_class',
    ( is => 'ro',
      does => 'CXGN::FileRepository::FileClass',
      required => 1,
      handles =>
      [
       repository => 'repository',
      ],
    );

=head1 METHODS

See L<CXGN::Publish::VersionedFile> for most methods.

=head2 new

Takes additional first argument, now called like
File->new( $file_class, $published_path)

=cut

sub BUILDARGS {
    my $class = shift;
    my $fc    = shift;

    return {file_class => $fc,
            %{ $class->SUPER::BUILDARGS( @_, $fc->repository->publisher ) }
           };
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
