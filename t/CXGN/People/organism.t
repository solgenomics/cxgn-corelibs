
use strict;

use Test::More qw | no_plan |;
use CXGN::DB::Connection;
use CXGN::People::Organism;

# turn off annoying DB connection messages...
#
CXGN::DB::Connection->verbose(0);

my $dbh = CXGN::DB::Connection->new();

eval {
    my $o = CXGN::People::Organism->new($dbh);
    $o->set_organism_name("Test test");
    my $id = $o->store();


    my $p = CXGN::People::Organism->new($dbh, $id);
    is($p->get_organism_name(), "Test test", "organism name test");
};

if ($@) { 
    die "An error occurred: $@\n";
}

$dbh->rollback();
