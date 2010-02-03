
use strict;

use Test::More qw / no_plan /;

use CXGN::DB::InsertDBH;
use CXGN::DB::Connection;
use CXGN::Chado::Phenotype;

my $dbh = CXGN::DB::Connection->new({ dbargs => { AutoCommit => 0 }});

my $phenotype = CXGN::Chado::Phenotype->new($dbh);

diag("Inserting a new phenotype object...");
$phenotype->set_unique_name("test-xyz");
$phenotype->set_observable_id(23015);
$phenotype->set_attr_id(1);
$phenotype->set_value(5);
$phenotype->set_cvalue_id(1);
$phenotype->set_assay_id(undef);

my $id = $phenotype->store();

diag("Checking the phenotype object in the database");
my $dbphenotype = CXGN::Chado::Phenotype->new($dbh, $id);

is($dbphenotype->get_observable_id(), 23015, "observable id test");
is($dbphenotype->get_attr_id(), 1, "attribute id test");
is($dbphenotype->get_value(), 5, "value test");
is($dbphenotype->get_cvalue_id(), 1, "cvalue id test");
is($dbphenotype->get_assay_id(), undef, "assay id test");

$dbh->rollback();


