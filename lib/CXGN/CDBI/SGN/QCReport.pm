package CXGN::CDBI::SGN::QCReport;


=head1 DATA FIELDS

  Primary Keys:
      qc_id

  Columns:
      qc_id
      est_id
      basecaller
      qc_status
      vs_status
      qstart
      qend
      istart
      iend
      hqi_start
      hqi_length
      entropy
      expected_error
      quality_trim_threshold
      vector_tokens

  Sequence:
      (sgn base schema).qc_report_qc_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table(__PACKAGE__->qualify_schema('sgn') . '.qc_report');

our @primary_key_names =
    qw/
      qc_id
      /;

our @column_names =
    qw/
      qc_id
      est_id
      basecaller
      qc_status
      vs_status
      qstart
      qend
      istart
      iend
      hqi_start
      hqi_length
      entropy
      expected_error
      quality_trim_threshold
      vector_tokens
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('sgn').'.qc_report_qc_id_seq' );


__PACKAGE__->has_a(est_id => 'CXGN::CDBI::SGN::EST');

sub est_object {
  shift->est_id(@_);
}

###
1;#do not remove
###
