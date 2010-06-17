use strict;
use warnings;

use Test::More tests => 3;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Relationship;
use CXGN::Chado::Dbxref;

my $dbh = CXGN::DB::Connection->new();

eval {
    diag("Creating an empty object and populating it...\n");
    my $r = CXGN::Chado::Relationship->new($dbh);
    my $subject_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "Mitochondrion");
    diag("subject term = " .$subject_term->get_dbxref()->get_cv_name() );
    my $object_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "Plastid");
    my $predicate_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "similar_to");

    $r->subject_term($subject_term);
    $r->object_term($object_term);
    $r->predicate_term($predicate_term);

    diag("storing the object...");
    my $r_id = $r->store();
    diag("Relationship ID = $r_id");

    $r = undef;

    diag("reading the object again...");

    $r = CXGN::Chado::Relationship->new($dbh, $r_id);
    is($r->subject_term()->name(), "mitochondrion", "subject term check");
    is($r->object_term()->name(), "plastid", "object term check");
    is($r->predicate_term()->name(), "similar_to", "predicate term check");

    diag("Done");
};

if ($@) { print "Errors: $@\n"; }
$dbh->rollback();
