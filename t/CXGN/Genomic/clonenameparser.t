#!/usr/bin/env perl
use strict;
no strict 'refs';
#use UNIVERSAL qw/isa/;

BEGIN {
  our %tests = ( clone_name_with_chromosome => [
					       [ 'SGN12H032K07',
						 { lib       => 'LE_HBa',
						   plate     => 32,
						   chr       => 12,
						   row       => 'K',
						   col       => 7,
						   clonetype => 'bac',
						   match     => 'SGN12H032K07',
						   version   => undef,
                                                   fragment  => undef,
						 },
					       ],
					       [ 'C11HBa119D16',
						 { lib       => 'LE_HBa',
						   plate     => 119,
						   chr       => 11,
						   row       => 'D',
						   col       => 16,
						   clonetype => 'bac',
						   match     => 'C11HBa119D16',
						   version   => undef,
						   fragment  => undef,
						 },
					       ],
					       [ 'C02HBa0155C04',
						 { lib       => 'LE_HBa',
						   plate     => 155,
						   chr       => 2,
						   row       => 'C',
						   col       => 4,
						   clonetype => 'bac',
						   match     => 'C02HBa0155C04',
						   version   => undef,
						   fragment  => undef,
						 },
					       ],
					       [ 'C02HBa0155C04.3-87',
						 { lib       => 'LE_HBa',
						   plate     => 155,
						   chr       => 2,
						   row       => 'C',
						   col       => 4,
						   clonetype => 'bac',
						   match     => 'C02HBa0155C04.3-87',
						   version   => 3,
						   fragment  => 87,
						 },
					       ],
					       [ 'C02HBa0155C04-87',
						 undef,
					       ],

					       [ 'LE_HBa0034B23',
						 undef,
					       ],
					       [ '002C17',
						 undef,
					       ],
					      ],
		seqwright_bac_chromat_file => [
					       [ 'tomato_genome/bac_ends/Le-HBa001_A01-T7.ab1.gz',
						 { lib       => 'LE_HBa',
						   plate     => 1,
						   row       => 'A',
						   col       => 1,
						   clonetype => 'bac',
						   path      => 'tomato_genome/bac_ends/',
						   suffix    => '.ab1.gz',
						   primer    => 'T7',
						   filename  => 'Le-HBa001_A01-T7',
						   match     => 'Le-HBa001_A01-T7',
						 },
					       ],
					       [ '/bac_ends/SL_MboI_1_A05-SP6.g',
						 { lib       => 'SL_MboI',
						   plate     => 1,
						   col       => 5,
						   row       => 'A',
						   clonetype => 'bac',
						   path      => '/bac_ends/',
						   suffix    => '',
						   primer    => 'SP6',
						   filename  => 'SL_MboI_1_A05-SP6.g',
						   match     => 'SL_MboI_1_A05-SP6',
						 },
					       ],
					      ],
		 genbank_accession         => [
					       [ 'CT990638.3' =>
						 {
						  lib       => 'LE_HBa',
						  plate     => 6,
						  row       => 'E',
						  col       => 18,
						  clonetype => 'bac',
						  match     => 'CT990638',
						 }
					       ],
					       [ 'CT990624' =>
						 {
						  lib       => 'LE_HBa',
						  plate     => 27,
						  row       => 'G',
						  col       => 19,
						  clonetype => 'bac',
						  match     => 'CT990624',
						 }
					       ],
					       [ CT990637 =>
						 {
						  lib       => 'LE_HBa',
						  plate     => 36,
						  row       => 'C',
						  col       => 23,
						  clonetype => 'bac',
						  match     => 'CT990637',
						 }
					       ],
					       #[ NE999999 => undef ],
					      ],
	      );
}
use Test::More qw/no_plan/;

use_ok('CXGN::Genomic::CloneNameParser');

my $parser = CXGN::Genomic::CloneNameParser->new;
isa_ok($parser,'CXGN::Genomic::CloneNameParser' ,'CloneNameParser constructor works');

#test each clone name parser function jimmy
foreach my $funcname (keys our %tests) {
  foreach my $test (@{$tests{$funcname}}) {
    #pretty-print the expected return value
    my $exp_str = hashref_to_str($test->[1]);

    my $ret = $parser->$funcname( $test->[0] );

    ok( eq_hash( $ret, $test->[1] ),"$funcname('$test->[0]')")
      or diag "expected $exp_str\ngot      ".hashref_to_str($ret)."\n";
  }
}

sub hashref_to_str {
  my $ref = shift;

  if ( defined($ref) ) {
    ref $ref eq 'HASH' or die 'not a hash ref';

    my @strs;
    foreach my $key (sort keys %$ref) {
      my $val = $ref->{$key};
      $val = 'undef' unless defined($val);
      push @strs, "$key => $val";
    }
    return join(', ',@strs);
  } else {
    return 'undef';
  }
}
