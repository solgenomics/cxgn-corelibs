#!/usr/bin/env perl

use strict;
use warnings;
use UNIVERSAL qw/isa/;

use CXGN::Tools::List qw/all/;

use CXGN::MOBY::XML::Generator;
use CXGN::MOBY::LocalServices;

use Data::Dumper;
no strict 'refs'; #using a lot of symbolic refs

####################### CONFIGURATION #########################
BEGIN {
  our $localservices_module = 'CXGN::MOBY::LocalServices';
  our @services = #fully-qualified list of all MOBY services
    map {"${localservices_module}::$_"} @CXGN::MOBY::LocalServices::servicenames;
}
our $localservices_module;
our @services;

#useful xpath fragments for delving into moby responses
our $moby_doc_xpath = "moby:MOBY/moby:mobyContent/moby:mobyData";
our $moby_collection_xpath = 'moby:Collection/moby:Simple';
####################### /CONFIGURATION ########################

use Test::More qw(no_plan);
use Test::XML::Simple;

#check that the XML generator at least compiles and blesses
our $x = CXGN::MOBY::XML::Generator->new( pretty => 2);
isa_ok($x,'CXGN::MOBY::XML::Generator',"CXGN::MOBY::XML::Generator constructor works");


#run all our tests
test_empty_input();
test_GetAvailableBlastDBs();
#performblast is on hold
#test_PerformBLAST();

sub test_empty_input {

  diag "testing that all services return empty moby docs for empty input...\n";

  my $empty_moby = $x->moby_container();
  #check that all services return well-formed xml in response to a request with no queries
  foreach my $servicename (@services) {
    my $shortname = (split /::/,$servicename)[-1];
    my $response = $servicename->(undef,$empty_moby);
    xml_valid($response,
	      "$shortname returns valid XML for empty input");

    my $xp = XML::XPath->new( xml=> $response);

    my $found = $xp->find("/moby:MOBY/moby:mobyContent");
    is($found->size, 1,"$shortname returns a single, correctly-formed response");

    $found = $xp->find("/moby:MOBY/moby:mobyContent/*");
    is($found->size,0,"$shortname response is empty")
      or diag "response was:\n$response";
  }
}


sub test_GetAvailableBlastDBs {

  diag "testing GetAvailableBlastDBs...\n";

  my $input_xml = $x->moby_document( one =>
				     $x->Simple($x->article('Object','testparam',1))
				   );
  my $result_xml = "${localservices_module}::GetAvailableBlastDBs"->(undef,$input_xml);
#  diag "got result xml:\n",$result_xml;

  xml_valid($result_xml,'results are valid XML');

  #make an XPath object for poking around in the returned XML
  my $xp = XML::XPath->new( xml=>$result_xml); 
  my $found; #stash XPath find results here

  $found = $xp->find("/$moby_doc_xpath");
  is($found->size,1,
     'one moby data response was returned');

  $found = $xp->find(qq|/${moby_doc_xpath}[\@moby:queryID="one"]|);
  is($found->size,1,
     'that response had the correct queryID');

  #test that the moby::mobyData contains only a moby::Collection
  $found = $xp->find("/$moby_doc_xpath/*");
  is($found->size,1,
     'moby data has one child node');

  is(($found->get_nodelist)[0]->getName,'moby:Collection',
     'that node is a moby:Collection');

  $found = $xp->find("/$moby_doc_xpath/moby:Collection/*");
  ok(all( map {$_->getName eq 'moby:Simple'} $found->get_nodelist),
     'all children of moby:Collection nodes are moby:Simple nodes');

  $found = $xp->find("/$moby_doc_xpath/$moby_collection_xpath/*");
  is($found->size,scalar(grep {$_->files_are_complete} CXGN::BlastDB->retrieve_all),
     'correct number of blast dbs returned');

  ok(all( map {$_->getName eq 'moby:NCBI_Blast_Database'} $found->get_nodelist),
     'all elements of collection are of type moby:NCBI_Blast_Database');

  sub test_blastdb_contents {
    my $result_xml = shift;
    my $type = shift;
    my $attrname = shift;
    my $regexp = shift;
    xml_like($result_xml,
	     qq|/$moby_doc_xpath/$moby_collection_xpath/moby:NCBI_Blast_Database/moby:${type}[\@moby:articleName="$attrname"]|,
	     $regexp,
	     "valid $attrname attribute"
	    );
  }

  test_blastdb_contents($result_xml,'String',  'title',               qr/.+/                     );
  test_blastdb_contents($result_xml,'Integer', 'idNumber',            qr/\d+/                    );
  test_blastdb_contents($result_xml,'String',  'proteinOrNucleotide', qr/^protein$|^nucleotide$/ );
  test_blastdb_contents($result_xml,'String',  'fileBasename',        qr/\S+/                    );
  test_blastdb_contents($result_xml,'Integer', 'numSequences',        qr/\d+/                    );
  test_blastdb_contents($result_xml,'Integer', 'unixTimestamp',       qr/\d{10,}/                );
  test_blastdb_contents($result_xml,'String',  'comment',             qr/.*/                     );
}

sub test_PerformBLAST {
  diag "testing PerformBLAST...";

  my $input_xml = $x->moby_document( one => [ $x->Collection($x->object('Sequence',{id=>'mungeme'},
								      $x->article('Integer','Length',638),
								      $x->article('String','SequenceString',<<EOSEQ),
AGCTTGTGACCCACAAATTCTCCCTCTAACCAAAACTCTCAAAGCCATTAAGACTACATTGTAGATGTTGATTAACTTAGAAGGAACATGCCTCTATTTA
TAGAGTCCTAAACCTTTTATTACAAGAAGAGGATTAGTCAATCCAAAACCTTTTCCTACAAGGAAAACCTATTTATGGTAAGAAATTCAGGGCAAAAAAA
CCCAAACAAATCGCCCCCTTGGCATGAATTTCTGACAAAATAAATTTGCCCACCTTCTTGACTTAATGTTCAACAACTTGTTTCTCCTCTCCATAATATC
CTTTGCAAAATTTATGTGCCAACACAAAGAATCTCTCTGAAAAAATTTCTCCAACAAAATCTTCATTACTGTAAAAAAGGTTACTGTTAGAACTACACCG
CCAAGATGAACACATCTTTCTAACCTGGTTCCCTCATCGATTATCAAACCACTAAACCTTACTCCGTCAATGAATTTGGCTCTGATACCACTTGTTAGAA
TTGAAATAAGCAGGTGTAAATGCAGAAGCTAACAATGAAAACCTCAAACCACCCCGTAAGAAGAAAATGAGAAATATACCAAAACACACAACACCCAAAC
GTGGTTCGGTCAATTGACCTACGTCCACAAAGGAGATG
EOSEQ
								     )
							  ),
					      $x->parameter('p','blastn'),
					      $x->parameter('e',1e-10),
					      $x->parameter('dbid',2),
					    ],
				   );

  my $response_xml = "${localservices_module}::PerformBLAST"->(undef,$input_xml);

  diag "BLAST response was:\n$response_xml\n";
}


