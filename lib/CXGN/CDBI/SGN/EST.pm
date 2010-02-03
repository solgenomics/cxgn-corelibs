package CXGN::CDBI::SGN::EST;
use strict;


=head1 DATA FIELDS

  Primary Keys:
      est_id

  Columns:
      est_id
      read_id
      version
      basecaller
      seq
      qscore
      call_positions
      status
      flags
      date

  Sequence:
      (sgn base schema).est_est_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.est');

our @primary_key_names =
    qw/
      est_id
      /;

our @column_names =
    qw/
      est_id
      read_id
      version
      basecaller
      seq
      qscore
      call_positions
      status
      flags
      date
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.est_est_id_seq' );


__PACKAGE__->has_many(qc_reports => 'CXGN::CDBI::SGN::QCReport');

sub qc_report_object {
  my $this = shift;
  my @qcs = $this->qc_reports;
  return $qcs[0];
}

sub trimmed_seq {
  my $this = shift;

  return '' unless $this->seq;

  if( $this->qc_report_object ) {
    return  substr($this->seq,
		   $this->qc_report_object->hqi_start,
		   $this->qc_report_object->hqi_length,
		  );
  } else {
    return $this->seq;
  }

}

###
1;#do not remove
###
