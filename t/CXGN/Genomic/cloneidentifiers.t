#!/usr/bin/perl
use strict;
use warnings;
use English;

use Text::Glob qw/ match_glob /;

BEGIN {
  our @parse_tests = (
		      [ C11HBa119D16 =>
			agi_bac_with_chrom =>
			{ lib       => 'LE_HBa',
			  plate     => 119,
			  chr       => 11,
			  row       => 'D',
			  col       => 16,
			  clonetype => 'bac',
			  match     => 'C11HBa119D16',
			},
			'C11HBa0119D16',
		      ],
                      [ 'RH202M11.1',
                        versioned_bac_seq_no_chrom =>
			{ lib       => 'RH',
			  plate     => 202,
			  row       => 'M',
			  col       => 11,
			  clonetype => 'bac',
			  match     => 'RH202M11.1',
			  clone_name => 'RH202M11',
			  version   => 1,
			},
                        'RH202M11.1',
                      ],
		      [ 'LpenBAC100A20' =>
			agi_bac =>
			{
			 lib => 'LpenBAC',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'LpenBAC100A20',
			},
			'LpenBAC0100A20',
		      ],
		      [ 'rhpotkey0100A20' =>
			agi_bac =>
			{
			 lib => 'RH',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'rhpotkey0100A20',
			},
			'RH100A20',
		      ],
		      [ 'RHPOTKEY0100A20' =>
			agi_bac =>
			{
			 lib => 'RH',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'RHPOTKEY0100A20',
			},
			'RH100A20',
		      ],
		      [ 'RH0100A20' =>
			agi_bac =>
			{
			 lib => 'RH',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'RH0100A20',
			},
			'RH100A20',
		      ],
		      [ 'RHPOTKEY0100A20' =>
			agi_bac =>
			{
			 lib => 'RH',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'RHPOTKEY0100A20',
			},
			'RH100A20',
		      ],
		      [ 'SL_s01A01' =>
			agi_bac =>
			{
			 lib => 'SL_s',
			 plate => 1,
			 row => 'A',
			 col => 1,
			 clonetype => 'bac',
			 match => 'SL_s01A01',
			},
			'SL_s0001A01',
		      ],
		      [ 'RHpotKEY0100A20' =>
			agi_bac =>
			{
			 lib => 'RH',
			 plate => 100,
			 row => 'A',
			 col => 20,
			 clonetype => 'bac',
			 match => 'RHpotKEY0100A20',
			},
			'RH100A20',
		      ],
		      [ 'LE_HBa-36C23' =>
			intl_clone =>
			{ lib       => 'LE_HBa',
			  plate     => 36,
			  row       => 'C',
			  col       => 23,
			  clonetype => 'bac',
			  match     => 'LE_HBa-36C23',
			},
			'hba-36c23',
		      ],
		      [ 'SL_fos-36C23' =>
			intl_clone =>
			{ lib       => 'SL_FOS',
			  plate     => 36,
			  row       => 'C',
			  col       => 23,
			  clonetype => 'fosmid',
			  match     => 'SL_fos-36C23',
			},
			'slf-36c23',
		      ],
		      [ 'C02HBa0155c04',
			agi_bac_with_chrom =>
			{ lib       => 'LE_HBa',
			  plate     => 155,
			  chr       => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'C02HBa0155c04',
			},
			'C02HBa0155C04',
		      ],
		      [ 'C00HBa0155C04',
			agi_bac_with_chrom =>
			{ lib       => 'LE_HBa',
			  plate     => 155,
			  chr       => 'unmapped',
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'C00HBa0155C04',
			},
			'C00HBa0155C04',
		      ],
		      [ 'C2slf0155C04',
			agi_bac_with_chrom =>
			{ lib       => 'SL_FOS',
			  plate     => 155,
			  chr       => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'fosmid',
			  match     => 'C2slf0155C04',
			},
			'C02SLf0155C04',
		      ],
		      [ 'bTH155C4',
			sanger_bac =>
			{ lib       => 'LE_HBa',
			  plate     => 155,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'bTH155C4',
			},
			'bTH155C4',
		      ],
		      [ 'bTM2C4',
			sanger_bac =>
			{ lib       => 'SL_MboI',
			  plate     => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'bTM2C4',
			},
			'bTM2C4',
		      ],
		      [ 'C02HBa0155C04.3',
			versioned_bac_seq =>
			{ lib       => 'LE_HBa',
			  plate     => 155,
			  chr       => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'C02HBa0155C04.3',
			  clone_name => 'C02HBa0155C04',
			  version   => 3,
			},
			'C02HBa0155C04.3',
		      ],
		      [ 'C02HBa0155C04.3-87',
			versioned_bac_seq =>
			{ lib       => 'LE_HBa',
			  plate     => 155,
			  chr       => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'C02HBa0155C04.3-87',
			  clone_name => 'C02HBa0155C04',
			  version   => 3,
			  fragment  => 87,
			},
			'C02HBa0155C04.3-87',
		      ],
		      [ 'C02SLe0155C04.3-87',
			versioned_bac_seq =>
			{ lib       => 'SL_EcoRI',
			  plate     => 155,
			  chr       => 2,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'C02SLe0155C04.3-87',
			  clone_name => 'C02SLe0155C04',
			  version   => 3,
			  fragment  => 87,
			},
			'C02SLe0155C04.3-87',
		      ],
		      [ 'SL_Eco0155C04.3-87',
			versioned_bac_seq_no_chrom =>
			{ lib       => 'SL_EcoRI',
			  plate     => 155,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'SL_Eco0155C04.3-87',
			  clone_name => 'SL_Eco0155C04',
			  version   => 3,
			  fragment  => 87,
			},
			'SL_EcoRI0155C04.3-87',
		      ],
		      [ 'RH0155C04.3-87',
			versioned_bac_seq_no_chrom =>
			{ lib       => 'RH',
			  plate     => 155,
			  row       => 'C',
			  col       => 4,
			  clonetype => 'bac',
			  match     => 'RH0155C04.3-87',
			  clone_name => 'RH0155C04',
			  version   => 3,
			  fragment  => 87,
			},
			'RH155C04.3-87',
		      ],
		      [ 'C02HBa0155C04-87',
			undef,
			undef,
			undef,
		      ],
		      [ 'LE_HBa0034B23',
			'agi_bac',
			{ lib       => 'LE_HBa',
			  plate     => 34,
			  row       => 'B',
			  col       => 23,
			  clonetype => 'bac',
			  match     => 'LE_HBa0034B23',
			},
			'LE_HBa0034B23',
		      ],
		      [ '002C17',
			undef,
			undef,
			undef,
		      ],
# 		      [ 'CT990638.4' =>
# 			'versioned_genbank',
# 			{
# 			 lib       => 'LE_HBa',
# 			 plate     => 6,
# 			 row       => 'E',
# 			 col       => 18,
# 			 clonetype => 'bac',
# 			 match     => 'CT990638.4',
# 			},
# 			'not implemented',
# 		      ],
# 		      [ 'CT990624' =>
# 			'genbank',
# 			{
# 			 lib       => 'LE_HBa',
# 			 plate     => 27,
# 			 row       => 'G',
# 			 col       => 19,
# 			 clonetype => 'bac',
# 			 match     => 'CT990624',
# 			},
# 			'not implemented',
# 		      ],
# 		      [ CT990637 =>
# 			'genbank',
# 			{
# 			 lib       => 'LE_HBa',
# 			 plate     => 36,
# 			 row       => 'C',
# 			 col       => 23,
# 			 clonetype => 'bac',
# 			 match     => 'CT990637',
# 			},
# 			'not implemented',
# 		      ],
# 		      [ NE999999 =>
# 			undef,
# 			undef,
# 			undef,
# 		      ],
		      [ LE_HBa24E01_sp6_134965 =>
			'bac_end',
			{
			 lib       => 'LE_HBa',
			 plate     => 24,
			 row       => 'E',
			 col       => 1,
			 primer    => 'SP6',
			 clone_name => 'LE_HBa0024E01',
			 end       => 'right',
			 version   => 1,
			 chromat_id => 134965,
			 clonetype => 'bac',
			 match     => 'LE_HBa24E01_sp6_134965',
			},
			'LE_HBa0024E01_SP6_134965'
		      ],
		      [ 'lpcos14j15_m13r_0',
			bac_end =>
			{
			 lib       => 'LpenCOS',
			 plate     => 14,
			 row       => 'J',
			 col       => 15,
			 primer    => 'M13R',
			 end       => 'right',
			 version   => 1,
			 chromat_id => 0,
			 clone_name => 'LpenCOS0014J15',
			 clonetype => 'bac',
			 match     => 'lpcos14j15_m13r_0',
			},
			'LpenCOS0014J15_M13R_0',
		      ],
		      [ 'LpenCOS0065B14_M13F_0',
			bac_end =>
			{
			 lib       => 'LpenCOS',
			 plate     => 65,
			 row       => 'B',
			 col       => 14,
			 primer    => 'M13F',
			 end       => 'left',
			 version   => 1,
			 clone_name => 'LpenCOS0065B14',
			 chromat_id => 0,
			 clonetype => 'bac',
			 match     => 'LpenCOS0065B14_M13F_0',
			},
			'LpenCOS0065B14_M13F_0',
		      ],			
		     );

}

use Test::More;

BEGIN {
  use_ok(  'CXGN::Genomic::CloneIdentifiers',
           qw(
              assemble_clone_ident
              parse_clone_ident
              guess_clone_ident_type
              clean_clone_ident
              clone_ident_glob
              clone_ident_regex
             )
        )
    or BAIL_OUT('could not include the module being tested');
}

#now do some test on the clone name parsing methods in
#CXGN::Genomic::Clone

foreach my $test (our @parse_tests) {
  my ($name,$type,$parsed,$assembled) = @$test;
  my $typestr = $type || '';
  is(guess_clone_ident_type($name),$type,"clone name '$name' is of type '$typestr'");
  if(defined $parsed) {
    is_deeply(parse_clone_ident($name),$parsed,"'$name' is parsed correctly");
  } else {
    ok(! defined parse_clone_ident($name),"'$name' is parsed correctly");
  }
  if(defined $assembled) {
  SKIP: {
      skip 'assembly not implemented for this type', 2 if $assembled eq 'not implemented';
      is(assemble_clone_ident($type,$parsed),$assembled,"assemble produces '$assembled'");
      my $clean = clean_clone_ident($name);
      is($clean,$assembled,"clean_clone_ident also produces '$assembled'");


      my $regex = eval { clone_ident_regex($type) };
      if( $@ ) {
          ok( $@ =~ /no regex defined/i, "no regex for $type" );
      } else {
          like( $clean, qr/$regex/, 'clone_ident_regex matches the clean identifier' );
      }

      my $glob = eval { clone_ident_glob($type) };
      if( $@ ) {
          ok( $@ =~ /no glob defined/i, "no glob for $type" );
      } else {
          ok( match_glob( $glob, $clean), 'clone_ident_glob matches the clean identifier' )
              or diag "type: '$type'  ident: '$clean'  glob: '$glob'";
      }

    }
  } else {
    eval{ assemble_clone_ident($type,$parsed) };
    ok($@,"for $name, assemble crashes");
    ok(1,'dummy test');
  }
}


#test clone_ident_glob
ok(clone_ident_glob('agi_bac_with_chrom'),'clone_ident_glob exists for agi_bac_with_chrom');
eval{ clone_ident_glob('nonexistentthing') };
ok($EVAL_ERROR,'clone_ident_glob dies for nonexistent name type');

done_testing;
