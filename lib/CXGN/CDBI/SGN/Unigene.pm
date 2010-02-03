package CXGN::CDBI::SGN::Unigene;
use strict;

=head1 DATA FIELDS

  Primary Keys:
      unigene_id

  Columns:
      unigene_id
      unigene_build_id
      consensi_id
      cluster_no
      contig_no
      nr_members
      database_name
      sequence_name

  Sequence:
      (sgn base schema).unigene_unigene_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.unigene');

our @primary_key_names =
    qw/
      unigene_id
      /;

our @column_names =
    qw/
      unigene_id
      unigene_build_id
      consensi_id
      cluster_no
      contig_no
      nr_members
      database_name
      sequence_name
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->SUPER::sequence( __PACKAGE__->base_schema('sgn').'.unigene_unigene_id_seq' );


__PACKAGE__->has_a(unigene_build_id => 'CXGN::CDBI::SGN::UnigeneBuild');
__PACKAGE__->has_a(consensi_id => 'CXGN::CDBI::SGN::UnigeneConsensi');
__PACKAGE__->has_many(members => 'CXGN::CDBI::SGN::UnigeneMember');

sub build_object {
  shift->unigene_build_id(@_);
}

sub consensus_object {
  shift->consensi_id(@_);
}

sub seq {
  my $this = shift;

  if(my $c = $this->consensi_id) {
    return $c->seq;
  } else {
    my @members = $this->members;
    @members > 1 and
      die 'Unigene ID ',$this->unigene_id,' has '.$this->members.' members, but no consensus sequence!';
    @members < 1 and
      die 'Unigene ID ',$this->unigene_id,' has no members!';
    use Data::Dumper;
    return $members[0]->est_object->trimmed_seq;
  }
}

sub external_identifier {
  'SGN-U'.shift->unigene_id
}

sub info_page_href {
  my $this = shift;
  my $infopage = '/search/unigene.pl?unigene_id='.$this->external_identifier
}

sub species_name {
  my $this = shift;

  die 'not yet implemented.  wanna do it?';
}



###
1;#do not remove
###
