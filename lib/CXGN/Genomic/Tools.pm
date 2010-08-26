package CXGN::Genomic::Tools;
use strict;
use warnings;

use Storable qw/freeze thaw/;
use Cache::File;

=head1 NAME

CXGN::Genomic::Tools - bundle of miscellaneous useful functions for working
with the genomic database.

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 FUNCTIONS

All of the functions below are EXPORT_OK.

=cut

BEGIN {
  our @EXPORT_OK = qw/
		      sequences_count_by_library
		      cached_sequences_count_by_library
		      clone_annotation_sequence
		      clone_id_from_clone_name
		      /;
}
use base qw/Exporter/;
our @EXPORT_OK;

=head2 sequences_count_by_library

  Desc:	get a summary of the number of sequences present in each library
        of a given clone type
  Args:	clone type shortname, e.g. 'bac'
  Ret :	array of (['Library long title',number of gss objects in that lib   ],
		  ['Library 2 long title', number of gss object in library 2],
		  ...
		 )
  Side Effects:	none
  Example:

   use CXGN::Genomic::Tools qw/sequences_count_by_library/;
   my @counts = sequences_count_by_library('bac');
   print "$_->[0]: contains $->[1] sequences\n" foreach @counts;

=cut

sub sequences_count_by_library {
    my @libs = CXGN::Genomic::Library->search_by_clone_type_shortname('bac');
    return map {[$_->name,$_->gss_count]} @libs;
}

=head2 cached_sequences_count_by_library

  Same as above, except cache the result and return the same thing
  every subsequent time you call it.

=cut

sub cached_sequences_count_by_library {
  my $conf = SGN::Context->new;
  my $tempdir = $conf->get_conf('basepath').$conf->get_conf('tempfiles_subdir') || '/tmp';
  tie my %cache, 'Cache::File', { cache_root => $tempdir, default_expires => '24 hours' };

  my $counts = $cache{'sequences_count_by_library'} ||= freeze([sequences_count_by_library(shift)]);
  return @{thaw($counts)};
}


=head2 clone_annotation_sequence

  Example: my $sequence = clone_annotation_sequence($clone_id);
  Desc : retrieve a sequence from the annotation database for a clone id
  Ret  : a sequence or undef
  Args : clone id
  Side Effects: none

=cut

sub clone_annotation_sequence {
  my $clone = CXGN::Genomic::Clone->retrieve(shift)
    or return undef;
  return $clone->seq;
}

=head2 clone_id_from_clone_name

  Usage: my $clone_id = clone_id_from_clone_name($name);
  Desc : retrieve a clone id from its name
  Ret  : a clone id, or undef if no clones matched
  Args : clone name
  Side Effects: none
  Example: my $clone_id=CXGN::Genomic::Clone->clone_id_from_clone_name($name);

=cut

sub clone_id_from_clone_name {
    my $class_dbi_object=CXGN::Genomic::Clone->retrieve_from_clone_name(@_)
      or return;
    return $class_dbi_object->clone_id();
}

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
