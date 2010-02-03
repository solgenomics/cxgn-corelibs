#!/usr/bin/env perl
use strict;
use warnings;
use UNIVERSAL qw/isa/;

use CXGN::CDBI::Class::DBI::TestSampler;

BEGIN {
  our %config = ( packagename => 'CXGN::Genomic::Library',
		  test_repeats => 3,
		  numtests     => 14,
		);

  our $numtests = $config{numtests}*$config{test_repeats};
};
use Test::More tests => our $numtests;
use CXGN::Genomic::Library;
use CXGN::CDBI::SGN::Accession;
use CXGN::CDBI::SGN::Organism;

our %config;

sub test {
  my $dbh = shift;
  my $id = shift;

  #test that we can retrieve it
  my $lib = $config{packagename}->retrieve($id);
  isa_ok($lib,$config{packagename})
    or warn "Could not retrieve with ID $id";

  #test has_a
  isa_ok($lib->clone_type_id,'CXGN::Genomic::CloneType');
  isa_ok($lib->accession_id,'CXGN::CDBI::SGN::Accession');

  #clone_type_object
  is($lib->clone_type_id->clone_type_id,
     $lib->clone_type_object->clone_type_id,
     'clone_type_object works');

  #accession_name
  my $acc_obj = $lib->accession_id;
  isa_ok($acc_obj,'CXGN::CDBI::SGN::Accession');
  my $org_obj = CXGN::CDBI::SGN::Organism->retrieve($acc_obj->organism_id);
  isa_ok($org_obj,'CXGN::CDBI::SGN::Organism');
  my ($a,$o,$ac) = $lib->accession_name;
  is($acc_obj->accession_name,$lib->accession_name,'accession names match');
  is($a,$acc_obj->accession_name,'accession names still match');
  is($o,$org_obj->organism_name,'organism names match');
  is($ac,$acc_obj->common_name,'common names match');

  #count number of blastdb objects that AREN'T what they should be, that
  #number should be 0
  #for each of the blast db accessors
  foreach my $methodname (qw/annotation_blast_dbs contamination_blast_dbs all_blast_dbs/) {
    no strict 'refs'; #these are symbolic refs
    is(scalar(grep {! isa($_,'CXGN::BlastDB')} $lib->$methodname),0,'all blastdb objects are ok');
  }

  #clone_count
  ok(defined($lib->clone_count),'clone_count is valid');

  ##gss_count
  #ok(defined($lib->gss_count),'gss_count is valid');

##############################################################################
}

#now run the actual sampled test
CXGN::CDBI::Class::DBI::TestSampler->new->test_class($config{packagename},
						     $config{test_repeats},
						     \&test);





