#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

# tests for Orthologger Module/
use Test::More tests => 10;

#use lib '/home/tomfy/cxgn/cxgn-corelibs/lib';
#use lib '/home/tomfy/Orthologger/lib';

use CXGN::Phylo::Parser;
use CXGN::Phylo::Orthologger;


# This is family 2830, with 25 genes in 13 taxa.
my $gene_tree_newick =
'(((Solyc03g121130.2.1[species=tomato]:0.03887,(((POPTR_0014s08830.1[species=poplar]:0.0001,POPTR_0014s08830.2[species=poplar]:0.0001):0.05550,(X_30131.m006857[species=castorbean]:0.01095,X_30131.m007044[species=castorbean]:0.00016):0.02176):0.04630,(evm.model.supercontig_184.11[species=papaya]:0.04198,(AT2G46230.1[species=arabidopsis]:0.01153,AT2G46230.2[species=arabidopsis]:0.07275):0.15150):0.02371):0.01878):0.01095,((GSVIVT01026915001[species=grape]:0.0001,GSVIVT01027024001[species=grape]:0.0001):0.07067,(((Glyma12g31740.1[species=soybean]:0.0001,Glyma13g38690.1[species=soybean]:0.0001):0.0001,(Glyma13g38690.2[species=soybean]:0.0001,Glyma13g38690.3[species=soybean]:0.0001):0.0001):0.01992,(IMGA_Medtr6g086290.1[species=medicago]:0.02191,IMGA_Medtr7g116720.1[species=medicago]:0.00015):0.06024):0.05419):0.01302):0.0148619097222222,((Bradi1g48740.1[species=brachypodium]:0.03551,(((Sb10g004030.1[species=sorghum]:0.0001,GRMZM2G140689_P02[species=maize]:0.0001):0.00015,(GRMZM2G016330_P01[species=maize]:0.0001,GRMZM2G016330_P03[species=maize]:0.0001):0.00536):0.02677,(LOC_Os06g06410.1[species=rice]:0.01662,LOC_Os06g06410.2[species=rice]:0.00015):0.00288):0.02333):0.08447,(jgi_Selmo1_91292[species=selaginella]:0.00532,jgi_Selmo1_158231[species=selaginella]:0.00016):0.13724):0.00183809027777778)';

# $gene_tree_newick =~ s/\s*//g; # remove whitespace

my $species_tree_newick =
'(Selaginella[species=Selaginella]:1,(((sorghum[species=Sorghum_bicolor]:1,maize[species=Zea_mays]:1):1,(rice[species=Oryza_sativa]:1,brachypodium[species=Brachypodium_distachyon]:1):1):1,(tomato[species=Solanum_lycopersicum]:1,(grape[species=Vitis_vinifera]:1,((papaya[species=Carica_papaya]:1,arabidopsis[species=Arabidopsis_thaliana]:1):1,((soy[species=Glycine_max]:1,medicago[species=Medicago_truncatula]:1):1,(castorbean[species=Ricinus_communis]:1,Poplar[species=Populus_trichocarpa]:1):1):1):1):1):1):1)';

$species_tree_newick =
'( chlamydomonas[species=Chlamydomonas_reinhardtii]:1, ( physcomitrella[species=Physcomitrella_patens]:1, ( selaginella[species=Selaginella_moellendorffii]:1, ( loblolly_pine[species=Pinus_taeda]:1, ( amborella[species=Amborella_trichopoda]:1, ( ( date_palm[species=Phoenix_dactylifera]:1, ( ( foxtail_millet[species=Setaria_italica]:1, ( sorghum[species=Sorghum_bicolor]:1, maize[species=Zea_mays]:1 ):1 ):1, ( rice[species=Oryza_sativa]:1, ( brachypodium[species=Brachypodium_distachyon]:1, ( wheat[species=Triticum_aestivum]:1, barley[species=Hordeum_vulgare]:1 ):1 ):1 ):1 ):1 ):1, ( columbine[species=Aquilegia_coerulea]:1, ( ( ( ( ( ( ( ( ( ( tomato[species=Solanum_lycopersicum]:1, potato[species=Solanum_tuberosum]:1 ):1, eggplant[species=Solanum_melongena]:1 ):1, pepper[species=Capsicum_annuum]:1 ):1, tobacco[species=Nicotiana_tabacum]:1 ):1, petunia[species=Petunia]:1 ):1, sweet_potato[species=Ipomoea_batatas]:1 ):1, ( arabica_coffee[species=Coffea_arabica]:1, robusta_coffee[species=Coffea_canephora]:1 ):1 ):1, snapdragon[species=Antirrhinum]:1 ):1, ( ( sunflower[species=Helianthus_annuus]:1, lettuce[species=Lactuca_sativa]:1 ):1, carrot[species=Daucus_carota]:1 ):1 ):1, ( grape[species=Vitis_vinifera]:1, ( ( eucalyptus[species=Eucalyptus_grandis]:1, ( ( orange[species=Citrus_sinensis]:1, clementine[species=Citrus_clementina]:1 ):1, ( ( cacao[species=Theobroma_cacao]:1, cotton[species=Gossypium_raimondii]:1 ):1, ( papaya[species=Carica_papaya]:1, ( turnip[species=Brassica_rapa]:1, ( salt_cress[species=Thellungiella_parvula]:1, ( red_shepherds_purse[species=Capsella_rubella]:1, ( arabidopsis_thaliana[species=Arabidopsis_thaliana]:1, arabidopsis_lyrata[species=Arabidopsis_lyrata]:1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1, ( ( ( peanut[species=Arachis_hypogaea]:1, ( ( soy[species=Glycine_max]:1, pigeon_pea[species=Cajanus_cajan]:1 ):1, ( medicago[species=Medicago_truncatula]:1, lotus[species=Lotus_japonicus]:1 ):1 ):1 ):1, ( hemp[species=Cannabis_sativa]:1, ( ( ( apple[species=Malus_domestica]:1, peach[species=Prunus_persica]:1 ):1, woodland_strawberry[species=Fragaria_vesca]:1 ):1, cucumber[species=Cucumis_sativus]:1 ):1 ):1 ):1, ( ( castorbean[species=Ricinus_communis]:1, cassava[species=Manihot_esculenta]:1 ):1, ( poplar[species=Populus_trichocarpa]:1, flax[species=Linum_usitatissimum]:1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ):1 ) :1';

# $species_tree_newick =~ s/\s*//g; # remove whitespace

my $gt_parser = CXGN::Phylo::Parse_newick->new($gene_tree_newick);
my $gene_tree = $gt_parser->parse();

my $st_parser    = CXGN::Phylo::Parse_newick->new($species_tree_newick);
my $species_tree = $st_parser->parse();

#********* test Orthologger->new returns Orthologger obj. **********
my $Orthologger_obj =
  CXGN::Phylo::Orthologger->new( { 'gene_tree' => $gene_tree, 'species_tree' => $species_tree, 'reroot_method' => 'mindl' } );
ok( defined $Orthologger_obj, 'new() returned something.' );
isa_ok( $Orthologger_obj, 'CXGN::Phylo::Orthologger' );

#********* test mindl rerooting of tree ***************
$Orthologger_obj->get_gene_tree()->show_newick_attribute('species');
my $got_rerooted_tree = $Orthologger_obj->get_gene_tree()->generate_newick();

my $expected_rerooted_tree =
'((jgi_Selmo1_91292[species=Selaginella_moellendorffii]:0.00532,jgi_Selmo1_158231[species=Selaginella_moellendorffii]:0.00016)[speciation=0]:0.06862,((Bradi1g48740.1[species=Brachypodium_distachyon]:0.03551,(((Sb10g004030.1[species=Sorghum_bicolor]:0.0001,GRMZM2G140689_P02[species=Zea_mays]:0.0001)[speciation=1]:0.00015,(GRMZM2G016330_P01[species=Zea_mays]:0.0001,GRMZM2G016330_P03[species=Zea_mays]:0.0001)[speciation=0]:0.00536)[speciation=0]:0.02677,(LOC_Os06g06410.1[species=Oryza_sativa]:0.01662,LOC_Os06g06410.2[species=Oryza_sativa]:0.00015)[speciation=0]:0.00288)[speciation=1]:0.02333)[speciation=0]:0.08447,((Solyc03g121130.2.1[species=Solanum_lycopersicum]:0.03887,(((POPTR_0014s08830.1[species=Populus_trichocarpa]:0.0001,POPTR_0014s08830.2[species=Populus_trichocarpa]:0.0001)[speciation=0]:0.05550,(X_30131.m006857[species=Ricinus_communis]:0.01095,X_30131.m007044[species=Ricinus_communis]:0.00016)[speciation=0]:0.02176)[speciation=1]:0.04630,(evm.model.supercontig_184.11[species=Carica_papaya]:0.04198,(AT2G46230.1[species=Arabidopsis_thaliana]:0.01153,AT2G46230.2[species=Arabidopsis_thaliana]:0.07275)[speciation=0]:0.15150)[speciation=1]:0.02371)[speciation=1]:0.01878)[speciation=1]:0.01095,((GSVIVT01026915001[species=Vitis_vinifera]:0.0001,GSVIVT01027024001[species=Vitis_vinifera]:0.0001)[speciation=0]:0.07067,(((Glyma12g31740.1[species=Glycine_max]:0.0001,Glyma13g38690.1[species=Glycine_max]:0.0001)[speciation=0]:0.0001,(Glyma13g38690.2[species=Glycine_max]:0.0001,Glyma13g38690.3[species=Glycine_max]:0.0001)[speciation=0]:0.0001)[speciation=0]:0.01992,(IMGA_Medtr6g086290.1[species=Medicago_truncatula]:0.02191,IMGA_Medtr7g116720.1[species=Medicago_truncatula]:0.00015)[speciation=0]:0.06024)[speciation=1]:0.05419)[speciation=1]:0.01302)[speciation=0]:0.0167)[speciation=1]:0.06862)';

is( $got_rerooted_tree, $expected_rerooted_tree, "Check rerooted tree newick is as expected." );

#*********** test ortholog result string is as expected **********
my $ortholog_result_string = $Orthologger_obj->ortholog_result_string();
my $expected_ortholog_result_string =
'orthologs of jgi_Selmo1_91292:  AT2G46230.1 AT2G46230.2 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 LOC_Os06g06410.1 LOC_Os06g06410.2 POPTR_0014s08830.1 POPTR_0014s08830.2 Sb10g004030.1 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11
orthologs of jgi_Selmo1_158231:  AT2G46230.1 AT2G46230.2 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 LOC_Os06g06410.1 LOC_Os06g06410.2 POPTR_0014s08830.1 POPTR_0014s08830.2 Sb10g004030.1 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11
orthologs of Bradi1g48740.1:  AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Sb10g004030.1:  GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of GRMZM2G140689_P02:  Sb10g004030.1 LOC_Os06g06410.1 LOC_Os06g06410.2 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of GRMZM2G016330_P01:  LOC_Os06g06410.1 LOC_Os06g06410.2 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of GRMZM2G016330_P03:  LOC_Os06g06410.1 LOC_Os06g06410.2 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of LOC_Os06g06410.1:  GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 Sb10g004030.1 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of LOC_Os06g06410.2:  GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 Sb10g004030.1 AT2G46230.1 AT2G46230.2 GSVIVT01026915001 GSVIVT01027024001 Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 POPTR_0014s08830.1 POPTR_0014s08830.2 Solyc03g121130.2.1 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Solyc03g121130.2.1:  AT2G46230.1 AT2G46230.2 POPTR_0014s08830.1 POPTR_0014s08830.2 X_30131.m006857 X_30131.m007044 evm.model.supercontig_184.11 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of POPTR_0014s08830.1:  X_30131.m006857 X_30131.m007044 AT2G46230.1 AT2G46230.2 evm.model.supercontig_184.11 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of POPTR_0014s08830.2:  X_30131.m006857 X_30131.m007044 AT2G46230.1 AT2G46230.2 evm.model.supercontig_184.11 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of X_30131.m006857:  POPTR_0014s08830.1 POPTR_0014s08830.2 AT2G46230.1 AT2G46230.2 evm.model.supercontig_184.11 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of X_30131.m007044:  POPTR_0014s08830.1 POPTR_0014s08830.2 AT2G46230.1 AT2G46230.2 evm.model.supercontig_184.11 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of evm.model.supercontig_184.11:  AT2G46230.1 AT2G46230.2 POPTR_0014s08830.1 POPTR_0014s08830.2 X_30131.m006857 X_30131.m007044 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of AT2G46230.1:  evm.model.supercontig_184.11 POPTR_0014s08830.1 POPTR_0014s08830.2 X_30131.m006857 X_30131.m007044 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of AT2G46230.2:  evm.model.supercontig_184.11 POPTR_0014s08830.1 POPTR_0014s08830.2 X_30131.m006857 X_30131.m007044 Solyc03g121130.2.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of GSVIVT01026915001:  Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of GSVIVT01027024001:  Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Glyma12g31740.1:  IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Glyma13g38690.1:  IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Glyma13g38690.2:  IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of Glyma13g38690.3:  IMGA_Medtr6g086290.1 IMGA_Medtr7g116720.1 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of IMGA_Medtr6g086290.1:  Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
orthologs of IMGA_Medtr7g116720.1:  Glyma12g31740.1 Glyma13g38690.1 Glyma13g38690.2 Glyma13g38690.3 GSVIVT01026915001 GSVIVT01027024001 Bradi1g48740.1 GRMZM2G016330_P01 GRMZM2G016330_P03 GRMZM2G140689_P02 LOC_Os06g06410.1 LOC_Os06g06410.2 Sb10g004030.1 jgi_Selmo1_158231 jgi_Selmo1_91292
Leaves not in species tree: ';

my @ortholog_lines          = split( "\n", $ortholog_result_string );
my @expected_ortholog_lines = split( "\n", $expected_ortholog_result_string );
my ( $nlines, $nxlines ) = ( scalar @ortholog_lines, scalar @expected_ortholog_lines );
is( $nlines, $nxlines, "Check number of output lines agrees with expectation: $nlines, $nxlines." );

my @sorted_ortholog_lines          = sort @ortholog_lines;
my @sorted_expected_ortholog_lines = sort @expected_ortholog_lines;
$ortholog_result_string          = join( "\n", @sorted_ortholog_lines );
$expected_ortholog_result_string = join( "\n", @sorted_expected_ortholog_lines );

#$ortholog_result_string =~ s/ +/ /g;
#$ortholog_result_string =~ s/ *\n */\n/g;
#$expected_ortholog_result_string =~ s/ +/ /g;
#$expected_ortholog_result_string =~ s/ *\n */\n/g;
is( $ortholog_result_string, $expected_ortholog_result_string,
    'Check ortholog result string agrees with expectation.' );

$gene_tree_newick =
'((foxtail_millet[species=Setaria_italica]:1,(sorghum[species=Sorghum_bicolor]:1,maize[species=Zea_mays_x]:1):1):1,(rice[species=Oryza_sativa]:1,brachypodium[species=Brachypodium_distachyon]:1):1)';

# the following is a misrooted tree
$gene_tree_newick = '(
    (
       foxtail_millet_1[species=Setaria_italica]:1,
       (
          rice_1[species=Oryza_sativa]:1,
          brachypodium_1[species=Brachypodium_distachyon]:1
       ):1
    ):0.5,
    (
        sorghum_1[species=Sorghum_bicolor]:1,
        maize_1[species=Zea_mays_x]:1
    ):0.5
)';

$gt_parser = CXGN::Phylo::Parse_newick->new($gene_tree_newick);
$gene_tree = $gt_parser->parse();

$st_parser    = CXGN::Phylo::Parse_newick->new($species_tree_newick);
$species_tree = $st_parser->parse();

#********* test Orthologger->new returns Orthologger obj. **********
$Orthologger_obj =
  CXGN::Phylo::Orthologger->new( { 'gene_tree' => $gene_tree, 'species_tree' => $species_tree, 'reroot_method' => 'mindl' } );
ok( defined $Orthologger_obj, 'new() returned something.' );
isa_ok( $Orthologger_obj, 'CXGN::Phylo::Orthologger' );

#********* test mindl rerooting of tree ***************
$Orthologger_obj->get_gene_tree()->show_newick_attribute('species');
$got_rerooted_tree = $Orthologger_obj->get_gene_tree()->generate_newick();
$expected_rerooted_tree =
'((rice_1[species=Oryza_sativa]:1,brachypodium_1[species=Brachypodium_distachyon]:1)[speciation=1]:0.5,(foxtail_millet_1[species=Setaria_italica]:1,(sorghum_1[species=Sorghum_bicolor]:1,maize_1[species=Zea_mays_x]:1)[speciation=0]:1)[speciation=1]:0.5)';
is( $got_rerooted_tree, $expected_rerooted_tree, "Check rerooted tree newick is as expected." );
$ortholog_result_string = $Orthologger_obj->ortholog_result_string();

$expected_ortholog_result_string = 'orthologs of rice_1:  brachypodium_1 foxtail_millet_1 sorghum_1
orthologs of brachypodium_1:  rice_1 foxtail_millet_1 sorghum_1
orthologs of foxtail_millet_1:  sorghum_1 brachypodium_1 rice_1
orthologs of sorghum_1:  foxtail_millet_1 brachypodium_1 rice_1
Leaves not in species tree: maize_1';

@ortholog_lines          = split( "\n", $ortholog_result_string );
@expected_ortholog_lines = split( "\n", $expected_ortholog_result_string );
( $nlines, $nxlines ) = ( scalar @ortholog_lines, scalar @expected_ortholog_lines );
is( $nlines, $nxlines, "Check number of output lines agrees with expectation: $nlines, $nxlines." );

@sorted_ortholog_lines           = sort @ortholog_lines;
@sorted_expected_ortholog_lines  = sort @expected_ortholog_lines;
$ortholog_result_string          = join( "\n", @sorted_ortholog_lines );
$expected_ortholog_result_string = join( "\n", @sorted_expected_ortholog_lines );

is( $ortholog_result_string, $expected_ortholog_result_string,
    'Check ortholog result string agrees with expectation.' );

