package CXGN::CDBI::Auto::SGN::FishResultComposite;
# This class is autogenerated by cdbigen.pl.  Any modification
# by you will be fruitless.

=head1 DESCRIPTION

CXGN::CDBI::Auto::SGN::FishResultComposite - object abstraction for rows in the sgn.fish_result_composite table.

Autogenerated by cdbigen.pl.

=head1 DATA FIELDS

  Primary Keys:
      fish_result_id

  Columns:
      fish_result_id
      map_id
      fish_experimenter_id
      experiment_name
      clone_id
      chromo_num
      chromo_arm
      percent_from_centromere
      het_or_eu
      um_from_centromere
      um_from_arm_end
      um_from_arm_border
      mbp_from_arm_end
      mbp_from_centromere
      mbp_from_arm_border
      experiment_group

  Sequence:
      none

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table( 'sgn.fish_result_composite' );

our @primary_key_names =
    qw/
      fish_result_id
      /;

our @column_names =
    qw/
      fish_result_id
      map_id
      fish_experimenter_id
      experiment_name
      clone_id
      chromo_num
      chromo_arm
      percent_from_centromere
      het_or_eu
      um_from_centromere
      um_from_arm_end
      um_from_arm_border
      mbp_from_arm_end
      mbp_from_centromere
      mbp_from_arm_border
      experiment_group
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );


=head1 AUTHOR

cdbigen.pl

=cut

###
1;#do not remove
###