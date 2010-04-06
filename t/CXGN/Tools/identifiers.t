#!/usr/bin/perl
use strict;
use Data::Dumper;

BEGIN {
  #tests for namespace detection

  #TO ADD A TEST FOR A NEW NAMESPACE, JUST ADD ANOTHER ENTRY IN THE %tests HASH BELOW.  THAT IS ALL.

  our %tests =
    (
     'potato_sgnlocusID_2206_Am_040153' => ['sgn_locus_sequence', 'Potato_SGNlocusID_2206_Am_040153', qr/locus_display\.pl/, {id => 2206, species => 'Potato', ext_id => 'Am_040153' }],
     'TG72-F_alignment_1' => [undef,undef,undef],
     '-'            => [undef,undef,undef,undef],
     'gnl|CDD|34868' => ['genbank_cdd','gnl|CDD|34868',qr/ncbi\.nlm\./, { id => 34868 } ],
     'sgn-u123442'  => ['sgn_u', 'SGN-U123442', qr/unigene\.pl/, { id => 123442 }],
     'SGNU1231'     => ['sgn_u', 'SGN-U1231',   qr/unigene\.pl/, { id => 1231 }],
     'CGN-U1234'    => ['cgn_u', 'CGN-U1234', undef, {id => 1234}],
     'CGNU1231'     => ['cgn_u', 'CGN-U1231',   undef, {id => 1231}],
     'CGN-U125230'  => ['cgn_u', 'CGN-U125230', qr/unigene\.pl/, {id => 125230}],
     'CGNU125230'   => ['cgn_u', 'CGN-U125230', qr/unigene\.pl/, {id => 125230}],
     'SGN-E123215'  => ['sgn_e', 'SGN-E123215', qr/est\.pl/, {id => 123215} ],
     'sgn|E123215'  => ['sgn_e', 'SGN-E123215', qr/est\.pl/, {id => 123215} ],
     'SGN-M1232'  => ['sgn_m', 'SGN-M1232', qr/markerinfo/, {id => 1232}],
     'SGN-T123401'  => ['sgn_t', 'SGN-T123401', qr/est\.pl/, {id => 123401}],
     'GO:0000000021344'     => ['go_term', 'GO:0021344', qr/geneontology/, {id => 21344}],
     'GO2344'     => ['go_term', 'GO:0002344', qr/geneontology/, {id => 2344}],
     'SGN-T75301'   => ['sgn_t', 'SGN-T75301',  qr/est\.pl/, {id => 75301}],
     'SGNS1231'     => ['sgn_s','SGN-S1231',qr/est\.pl/, {id => 1231} ],
     'SGN-M1091'    => ['sgn_m', 'SGN-M1091', qr/markerinfo.pl/, {id=>1091} ],
     'SGN-M1091-FPRIMER' =>['sgn_m', 'SGN-M1091', qr/markerinfo.pl/, {id=>1091} ],
     'gi|108883260|GB|EAT47485.1|[108883260]' => ['genbank_accession','gi|108883260|gb|EAT47485.1|',qr/ncbi.nlm.nih.gov/, { gi => 108883260, accession => 'EAT47485', version => 1 }],
     'gi|108883260|GB|EAT47485.1|' => ['genbank_accession','gi|108883260|gb|EAT47485.1|',qr/ncbi.nlm.nih.gov/, { gi => 108883260, accession => 'EAT47485', version => 1 }],
     'gi|108883260|GB|EAT47485.1' => ['genbank_accession','gi|108883260|gb|EAT47485.1',qr/ncbi.nlm.nih.gov/, { gi => 108883260, accession => 'EAT47485', version => 1 }],
     'GB|EAT47485.1' => ['genbank_accession','gb|EAT47485.1',qr/ncbi.nlm.nih.gov/, { accession => 'EAT47485', version => 1 }],
     'GI|108883260' => ['genbank_gi','gi|108883260|',qr/ncbi.nlm.nih.gov/, { gi => 108883260 }],
     'gi|108883260|'=> ['genbank_gi','gi|108883260|',qr/ncbi.nlm.nih.gov/, { gi => 108883260 }],
     'GI:108883260' => ['genbank_gi','gi|108883260|',qr/ncbi.nlm.nih.gov/, { gi => 108883260 }],
     'pir||G96509' => ['genbank_accession','pir||G96509',qr/ncbi.nlm.nih.gov/, { pir => 'G96509' } ],
     'PIR||G96509.1|' => ['genbank_accession','pir||G96509.1|',qr/ncbi.nlm.nih.gov/, { PIR => 'G96509.1' } ],
     'gb|AAQ14263.1|AF250397_1' => ['genbank_accession','gb|AAQ14263.1|AF250397_1',qr/ncbi.nlm.nih.gov/, { accession => 'AAQ14263', version => 1, locus => 'AF250397_1' }],
     'BT013141'    => ['genbank_accession','BT013141',qr/ncbi.nlm.nih.gov/, {accession => 'BT013141'}],
     'L24060'    => ['genbank_accession','L24060',qr/ncbi.nlm.nih.gov/, { accession => 'L24060' }],
     '1-1-1.2.3.4'  => ['microarray_spot','1-1-1.2.3.4', qr/est\.pl/],
     '1--1.2.3.4'   => [undef, undef, undef],
     'LE_HBa0123A21'=> ['bac', 'LE_HBa0123A21', qr/clone_info\.pl/, { clonetype => 'bac', lib => 'LE_HBa', plate => 123, row => 'A', col => 21, match =>  'LE_HBa0123A21'} ],
     'LE_HBa123A21' => ['bac', 'LE_HBa0123A21', qr/clone_info\.pl/, { clonetype => 'bac', lib => 'LE_HBa', plate => 123, row => 'A', col => 21, match =>  'LE_HBa123A21'} ],
     'LE_HBa12A2'   => ['bac', 'LE_HBa0012A02', qr/clone_info\.pl/, { clonetype => 'bac', lib => 'LE_HBa', plate => 12, row => 'A', col => 2, match =>  'LE_HBa12A2'} ],
     'bTH12A2'      => ['bac', 'LE_HBa0012A02', qr/clone_info\.pl/, { clonetype => 'bac', lib => 'LE_HBa', plate => 12, row => 'A', col => 2, match =>  'bTH12A2'} ],
     'LE_HBa0024E01_SP6_134965' =>  [ 'bac_end','LE_HBa0024E01_SP6_134965',qr/clone_read_info\.pl/,
				      { clonetype => 'bac', lib => 'LE_HBa', plate => 24, row => 'E', col => 1,
					primer => 'SP6', chromat_id => 134965, version => 1,
					clone_name => 'LE_HBa0024E01',
					end => 'right',
					match => 'LE_HBa0024E01_SP6_134965',
				      },
				    ],
     'LE_HBa1C14_SP6_123' =>  ['bac_end', 'LE_HBa0001C14_SP6_123', qr/clone_read_info\.pl/,
			       { clonetype => 'bac', lib => 'LE_HBa', plate => 1, row => 'C', col => 14, primer => 'SP6', chromat_id => 123, version => 1, end => 'right', clone_name => 'LE_HBa0001C14',
				 match => 'LE_HBa1C14_SP6_123',
			       },
			      ],
     'LE_HBa0221C08_SP6_397124' => ['bac_end', 'LE_HBa0221C08_SP6_397124', qr/clone_read_info\.pl/,
				    { clonetype => 'bac', lib => 'LE_HBa', plate => 221, row => 'C', col => 8, primer => 'SP6', chromat_id => 397124, version => 1,
				      match => 'LE_HBa0221C08_SP6_397124',
				      end => 'right',
				      clone_name => 'LE_HBa0221C08',
				    },
				   ],
     'LE_HBa0008G21_T7_3401' => ['bac_end', 'LE_HBa0008G21_T7_3401', qr/clone_read_info\.pl/,
				 { clonetype => 'bac', end => 'left', lib => 'LE_HBa', plate => 8, row => 'G', col => 21, primer => 'T7', chromat_id => 3401, version => 1,
				   match => 'LE_HBa0008G21_T7_3401',
				   end => 'left',
				   clone_name => 'LE_HBa0008G21',
				 },
				],
     'lehba004J16_T7_1231' => ['bac_end', 'LE_HBa0004J16_T7_1231', qr/clone_read_info\.pl/,
			       { clonetype => 'bac', lib => 'LE_HBa', plate => 4, row => 'J', col => 16, primer => 'T7', chromat_id => 1231, version => 1,
				 end => 'left',
				 clone_name => 'LE_HBa0004J16',
				 match => 'lehba004J16_T7_1231',
			       },
			      ],
     'le_hba0004J16' =>  ['bac', 'LE_HBa0004J16', qr/clone_info\.pl/,
			  { clonetype => 'bac', lib => 'LE_HBa', plate => 4, row => 'J', col => 16,
			    match => 'le_hba0004J16',
			  },
			 ],
     'LE_HBa12A2'      => ['bac','LE_HBa0012A02',qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'LE_HBa', plate => 12, row => 'A', col => 2,
			     match => 'LE_HBa12A2',
			   },
			  ],
     'LE_H12A2'        => [undef,undef,undef,undef],
     'SL_MboI12A2'     => ['bac','SL_MboI0012A02',qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'SL_MboI', plate => 12, row => 'A', col => 2,
			     match => 'SL_MboI12A2'
			   },
			  ],
     'SL_MboI2A122'    => [undef, undef, undef, undef], #nonexistent ones are cleaned away
     'MboI12A2'        => ['bac','SL_MboI0012A02',qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'SL_MboI', plate => 12, row => 'A', col => 2,
			     match => 'MboI12A2',
			   },
			  ],
     'C04HBa0077O05'   => ['bac', 'C04HBa0077O05', qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'LE_HBa', plate => 77, row => 'O', col => 5, chr => 4, match => 'C04HBa0077O05',
			     match => 'C04HBa0077O05',
			   },
			  ],
     'C04HBa0077O05-4' => [undef,undef,undef,undef],
     'C04HBa77O05.1-4' => ['bac_fragment', 'C04HBa0077O05.1-4', qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'LE_HBa', plate => 77, row => 'O', col => 5, chr => 4, match => 'C04HBa77O05.1-4',
			     version => 1, fragment => 4, clone_name => 'C04HBa77O05',
			   },
			  ],
     'C04HBa0077O05.1' => ['bac_sequence', 'C04HBa0077O05.1', qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'LE_HBa', plate => 77, row => 'O', col => 5, chr => 4, match => 'C04HBa0077O05.1',
			     clone_name => 'C04HBa0077O05',
			     version => 1,
			   },
			  ],
     'C10SLe0045H11'   => ['bac', 'C10SLe0045H11', qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'SL_EcoRI', plate => 45, row => 'H', col => 11, chr => 10, match => 'C10SLe0045H11',
			   },
			  ],
     'C08SLm0119I05'   => ['bac', 'C08SLm0119I05', qr/clone_info\.pl/,
			   { clonetype => 'bac', lib => 'SL_MboI', plate => 119, row => 'I', col => 5, chr => 8, match => 'C08SLm0119I05',
			   },
			  ],
     'C04HBa0077O05-4a'=> [undef,undef,undef,undef],
     'qwerty'          => [undef,undef,undef,undef],
     'At1g67700.1'     => ['tair_gene_model','At1g67700.1',qr/arabidopsis\.org/],
#     'C2_At5g60990'    => ['sgn_marker','C2_At5g60990',qr/markerinfo\.pl/],
     'At5g60990'       => ['tair_locus','At5g60990',qr/arabidopsis\.org/],
     'aT1g67700.1'     => ['tair_gene_model','At1g67700.1',qr/arabidopsis.org/],
     'Monkey monkeyus' => ['species_binomial','Monkey monkeyus',qr/wikipedia/,
			  { genus => 'Monkey',
			   species => 'monkeyus',
			  }],
     'sgnu1231'        => ['sgn_u','SGN-U1231',qr/unigene\.pl.+SGN-U1231/,
			   { id => 1231 },
			  ],
     'sgn-s1010'        =>['sgn_s', 'SGN-S1010', qr/est\.pl/, { id=>1010 }],
     'SGNE1231'        => ['sgn_e','SGN-E1231',qr/est\.pl/,
			   { id => 1231 },
			  ],
     'E42'             => [undef,undef,undef],
     'monkeys'         => [undef,undef,undef],
     'TUS-1-A9'        => ['est','TUS-1-A9',qr/est\.pl/],
     'tus1A9'          => ['est','TUS-1-A9',qr/est\.pl/],
     'cLEC-1-E23'      => ['est','cLEC-1-E23',qr/est\.pl/],
     'clec1E23'        => ['est','cLEC-1-E23',qr/est\.pl/],
     'apple   of sodom ' => ['species_common','Apple of Sodom',qr/wikipedia/,{ common_name => 'apple   of sodom'}],
     '   peTunIa  '    => ['species_common','Petunia',qr/wikipedia/, { common_name => 'peTunIa'}],
     'L. esculentum'   => ['species_binomial','L. esculentum',qr/wikipedia/, { genus => 'L', species => 'esculentum' }],
     'S. lycopersicum' => ['species_binomial','S. lycopersicum',qr/wikipedia/, { genus => 'S', species => 'lycopersicum'}],
     's.Lycopersicum'  => ['species_binomial','S. lycopersicum',qr/wikipedia/, { genus => 's', species => 'Lycopersicum'}],
     's.  Lycopersicum'=> ['species_binomial','S. lycopersicum',qr/wikipedia/, { genus => 's', species => 'Lycopersicum'}],

#### Note: marker identification only on the basis of SGN-M numbers!
####     'TG123a'          => ['sgn_marker','TG123',qr/markerinfo\.pl/],
####     'TG26-F'          => ['sgn_marker','TG26',qr/markerinfo\.pl/],
####     'P40'             => ['sgn_marker','P40',qr/markerinfo\.pl/],
     'atMG93233'       => ['tair_locus', 'AtMG93233', qr/arabidopsis\.org.*TairObject\?type=locus&name=AtMG93233/],
     'at3G03022.1'     => ['tair_gene_model', 'At3G03022.1', qr/arabidopsis\.org.*TairObject\?type=gene/],
     'cLEX11k1'        => ['est','cLEX-11-K1',qr/est\.pl/],
     'cTOG-5_K15'      => ['est','cTOG-5-K15',qr/est\.pl/],
     'ctog:5:K:15'     => ['est','cTOG-5-K15',qr/est\.pl/],
     'cLED-10_L1'      => ['est','cLED-10-L1',qr/est\.pl/],
     'ipr023339'       => ['interpro_accession', 'IPR023339', qr/www\.ebi\.ac\.uk\/interpro\/IEntry\?ac=IPR023339/],
     'C12.4_contig0'   => ['tomato_bac_contig', 'C12.4_contig0', qr//, { chr => 12, chr_ver => 4, ctg_num => 0, ver => 4 }],
     'c02.42coNTig0'   => ['tomato_bac_contig', 'C02.42_contig0', qr//, { chr => 2, chr_ver => 42, ctg_num => 0, ver => 42 }],
     'scaffold234'     => ['generic_scaffold', 'scaffold234', qr//, { scaffold_num => 234 } ],
     'scaFFOld0'       => ['generic_scaffold', 'scaffold0', qr//, { scaffold_num => 0 } ],
###     'SSR222'          => ['sgn_marker', 'SSR222', qr//],
     'ac186290_17.1'   => ['itag_gene_model', 'AC186290_17.1', qr/gbrowse.+name=gene:AC186290_17.1$/, { index => 17, ver => 1, accession => 'AC186290'}],
     'cds:ac186290_17.1'   => ['itag_coding_sequence', 'CDS:AC186290_17.1', qr/gbrowse.+name=AC186290_17.1$/, { index => 17, ver => 1, accession => 'AC186290'}],
     'sp|Q4U9M9|104K_THEAN' => ['swissprot_accession', 'Q4U9M9', qr/www\.uniprot\.org\/uniprot\/Q4U9M9/],
     'sp|O48626|ZW10_ARATH' => ['swissprot_accession', 'O48626', qr/www\.uniprot\.org\/uniprot\/O48626/],
     'UniRef90_Q4U9M9' => ['uniref_accession', 'Q4U9M9', qr/www\.uniprot\.org\/uniprot\/Q4U9M9/],
     'UniRef100_P15711' => ['uniref_accession', 'P15711', qr/www\.uniprot\.org\/uniprot\/P15711/],
     'UniRef50_Q43495' => ['uniref_accession', 'Q43495', qr/www\.uniprot\.org\/uniprot\/Q43495/],
     'processed_tobacco_genome_sequences_c54565' => [undef, undef, undef],
    );

our %link_tests =
  (
   'SGN-E12313' => qr/^<a.+href=".+est\.pl\?.+".*>SGN-E12313<\/a>/,
   'petunia' => qr/wikipedia/,
   'E42' => undef,
   'tus1A9' => qr/^<a.+href=".+est\.pl\?.+".*>TUS-1-A9<\/a>/,
   'lehba4J16_T7_1231' => qr/^<a.+href=".+clone_read_info\.pl\?.+".*>LE_HBa0004J16_T7_1231<\/a>/,
   'TG72-F_alignment_1' => undef,
   '-' => undef,
  );
  #allow an override for a single test
  if(@ARGV) {
    my ($ident,$ns,$cleaned,$link) = @ARGV;
    %tests = ($ident => [$ns,$cleaned,qr/$link/]);
    %link_tests = ();
  }
}

use Test::More tests=> 1 + 4*scalar(keys our %tests)
  + scalar(keys our %link_tests)
  + 6; #< unique_identifier tests

BEGIN {
 use_ok( 'CXGN::Tools::Identifiers', qw(
					identifier_namespace
					clean_identifier
					identifier_url
					link_identifier
					unique_identifier
					parse_identifier
				       )
       );
}


while( my($ident,$tests) = each our %tests) {
  my ($correct_ns,$cleaned,$urlmatch,$parsed) = @$tests;
  $parsed->{namespace} = $correct_ns if $parsed;
  my $url = identifier_url($ident);
  is(identifier_namespace($ident),$correct_ns,"$ident is in namespace '$correct_ns'");
  is(clean_identifier($ident),$cleaned,"$ident is cleaned to '$cleaned'");
  if($urlmatch) {
    like($url,$urlmatch,"$ident url ($url) matches $urlmatch");
  } else {
    is($url,undef,"$ident has undef for url");
  }
  my $p = parse_identifier($ident,$correct_ns);
  is_deeply($p,$parsed,"$ident was parsed correctly")
    or diag Dumper $p;
}

while(my($ident,$match) = each our %link_tests) {
  if(defined($match)) {
    like(link_identifier($ident),$match,"well-formed link for $ident");
  } else {
    is(link_identifier($ident),undef,"$ident has undef for link");
  }
}


#now test the unique_identifier function
is(unique_identifier('foobar'),'foobar',"unique_identifier doesn't touch an ident it hasn't seen before");
is(unique_identifier('foobar','_'),'foobar_1',"unique_identifier DOES touch one that it has seen before");
is(unique_identifier('foobar'),'foobar_2',"default unique separator is '_'");
my $store = {};
is(unique_identifier('foobar','_',$store),'foobar',"unique_identifier accepts an external data store");
is(unique_identifier('foobar','_',$store),'foobar_1',"unique_identifier really accepts an external data store");

is(unique_identifier('monkeys',undef,undef,1),'monkeys_0','unique_identifier force option works');
