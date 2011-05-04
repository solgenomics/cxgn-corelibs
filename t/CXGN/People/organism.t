
use Modern::Perl;

use Test::Most;
use CXGN::DB::Connection;
use CXGN::People::Organism;
use autodie qw/:all/;

plan tests => 1;

my $dbh = CXGN::DB::Connection->new();

my $o = CXGN::People::Organism->new($dbh);
$o->set_organism_name("Test test");
my $id = $o->store();


my $p = CXGN::People::Organism->new($dbh, $id);
is($p->get_organism_name(), "Test test", "organism name test");

$dbh->rollback();
