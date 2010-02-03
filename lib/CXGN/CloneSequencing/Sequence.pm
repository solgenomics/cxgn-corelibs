package CXGN::CloneSequencing::Sequence;
use Moose::Role;

use English;
use Carp;

=head1 NAME

CXGN::CloneSequencing::Sequence - Role for a sequence in a BAC-by-BAC
sequencing project

=head1 SYNOPSIS

=head1 ATTRIBUTES

Attributes are r/w unless otherwise noted.

  is_finished  - get boolean whether this seq is finished (htgs 3)

=cut

sub is_finished {
  my $self = shift;
  my $h = $self->htgs_phase;
  return unless defined $h;
  return $h == 3
      ? 1
      : 0;
}

=head1 REQUIREMENTS

=pod

  htgs_phase   - get integer HTGS phase, (0,1,2,3, or undef)

=cut

requires 'htgs_phase';

=pod

  name         - get string 'official name' of the sequence

=cut

requires 'name';

=pod

  aliases      - get array of [dbname,accession] aliases for this sequence,
                 example: ['DB:Genbank', 'AC12345.1']

=cut

requires 'aliases';

=pod

  clone        - get CXGN::Genomic::Clone object

=cut

requires 'clone';

=head1 METHODS

none yet

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
