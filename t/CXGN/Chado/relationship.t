use strict;
use warnings;

use Test::More tests => 3;
use CXGN::DB::Connection;
use CXGN::Chado::CV;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Relationship;

my $dbh = CXGN::DB::Connection->new();

eval {
    diag "Creating an empty object and populating it...\n";
    my $r = CXGN::Chado::Relationship->new($dbh);

    my $go_cv = CXGN::Chado::CV->new_with_name($dbh, "cellular_component");
    my $rel_cv = CXGN::Chado::CV->new_with_name($dbh, "relationship");

    my $subject_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "Mitochondrion", $go_cv->get_cv_id());
    diag "subject term = ".($subject_term->get_cvterm_name())."\n";
    my $object_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "Plastid", $go_cv->get_cv_id());
    diag "object term = ".($object_term->get_cvterm_name())."\n";

    my $predicate_term = CXGN::Chado::Cvterm->new_with_term_name($dbh, "instance_of", $rel_cv->get_cv_id());
    diag "predicate term = ".($predicate_term->get_cvterm_name())."\n";

    $r->subject_term($subject_term);
    $r->object_term($object_term);
    $r->predicate_term($predicate_term);

    diag "storing the object...";
    my $r_id = $r->store();
    diag "Relationship ID = $r_id\n";

    $r = undef;

    diag "reading the object again...\n";

    $r = CXGN::Chado::Relationship->new($dbh, $r_id);
    is($r->subject_term()->name(), "mitochondrion", "subject term check");
    is($r->object_term()->name(), "plastid", "object term check");
    is($r->predicate_term()->name(), "instance_of", "predicate term check");
};

if ($@) { print "Errors: $@\n"; }
$dbh->rollback();
