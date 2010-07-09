use strict;
use warnings;
use autodie;

use Test::More tests=>18;
use CXGN::Debug;

my $debug = 0;

my $d = CXGN::Debug->new();
$d->set_debug($debug);

BEGIN {
    use_ok("CXGN::DB::Connection");
    use_ok("CXGN::People::Person");
};

my $dbh = CXGN::DB::Connection->new();

$d->d("Creating test Person object");
my $p = CXGN::People::Person->new($dbh);

$p->set_salutation("Mr.");
$p->set_first_name("Charles");
$p->set_last_name("Darwin");
$p->set_contact_email("cd1\@cornell.edu");
$p->set_address("Tower Rd, Ithaca, NY 14853");
$p->set_country("USA");
$p->set_webpage("http://sgn.cornell.edu");
$p->set_organization("BTI");

$d->d("Storing Person object...");
my $person_id = $p->store();

$d->d("Retrieving Person object...");
my $q = CXGN::People::Person->new($dbh, $person_id);

is($q->get_salutation(), "Mr.", "salutation test");
is($q->get_first_name(), "Charles", "first name test");
is($q->get_last_name(), "Darwin", "last name test");
is($q->get_contact_email(), "cd1\@cornell.edu", "contact email test");
is($q->get_address(), "Tower Rd, Ithaca, NY 14853", "address test");
is($q->get_country(), "USA", "country test");
is($q->get_webpage(), "http://sgn.cornell.edu", "webpage test");
is($q->get_organization(), "BTI", "organization test");
is($q->get_user_type(), "user", "user type test");

my @projects = $q->get_projects_associated_with_person();
is($projects[0], 14, "projects associated with person test"); # is only associated with unmapped project
is($q->is_person_associated_with_project(1), 0, "person associated with chromosome project");
is($q->is_person_associated_with_project(14), 1, "person associated with unmapped project test");

my $login = CXGN::People::Login->new($dbh, $person_id);
$login->set_username("charles_darwin");
$login->set_password("galapagos");

$login->store();

my $cd_person_id = CXGN::People::Person->get_person_by_username($dbh,"charles_darwin");

is($cd_person_id, $person_id , "get_person_by_username test");
my $c = CXGN::People::Person->new($dbh, $cd_person_id);
$c->set_user_type("curator");
is($c->get_username(), "charles_darwin", "username test");
is($c->get_user_type(), "curator", "curator usertype test");
@projects = $c->get_projects_associated_with_person();
is(scalar(@projects), 13, "projects associated with curator test"); # should return all 12 chr + unmapped

$dbh->rollback();
