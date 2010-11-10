#!/usr/bin/perl

=head1 NAME

  cvterm.t - Tests for CXGN::Chado::Cvterm 

=cut

=head1 SYNOPSIS

 prove -v t/CXGN/Chado/cvterm.t

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use autodie;

use Test::More  tests => 17;
use CXGN::DB::Connection;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Ontology;

my $dbh = CXGN::DB::Connection->new();

my @term_list = ();

my @root_namespaces = CXGN::Chado::Cvterm::get_namespaces($dbh);

ok( @root_namespaces > 0, "get_namespaces" );

my @new_roots = CXGN::Chado::Cvterm::get_roots( $dbh, "GO" );
ok( @new_roots == 3, "GO namespace get_roots" );

my $cvterm = undef;

my $cv_accession = "GO:0009536";

$cvterm = CXGN::Chado::Cvterm->new_with_accession( $dbh, $cv_accession );

is( $cvterm->get_cvterm_name(), "plastid", "get_cvterm_name function" );
is( $cvterm->get_cv_name(), "cellular_component", "get_cv_name" );
is( $cvterm->get_accession(), "0009536", 'get_accession' );
@term_list = $cvterm->get_children();
#count direct children
cmp_ok( scalar @term_list, '=', 12, "get_children" );

@term_list = $cvterm->get_parents();
ok( @term_list == 2, "get_parents" );
my @parent_names = sort ( map ($_->[0]->identifier , @term_list) ) ;
is( $parent_names[0], "0043231", "get_parents check 1" );
is( $parent_names[1], "0044444", "get_parents check 2" );

# now look at the recursive children and parents
my @recursive_children = $cvterm->get_recursive_children;
is( @recursive_children , 121 , "get_recursive_children");

my @recursive_parents = $cvterm->get_recursive_parents;
is( @recursive_parents , 11 , "get_recursive_parents");

# make a new cterm and store it, all in a transaction.
# then rollback to leave db content intact.
#
SKIP : {
    my $ontology = CXGN::Chado::Ontology->new_with_name( $dbh, "biological_process" );
    my $new_t = CXGN::Chado::Cvterm->new($dbh);

    my $identifier = "1111111";
    $new_t->identifier($identifier);
    $new_t->set_obsolete(0);

    my $name = "a test term";
    $new_t->name($name);

    my $definition = "a term to be used with test definitions and other tests, as well as testing";
    $new_t->definition($definition);

    $new_t->ontology($ontology);
    $new_t->set_db_name("GO");
    $new_t->set_cv_id( $ontology->get_cv_id() );
    my $id;
    eval {
        $id = $new_t->store();
    };
    if ($@) {
        skip "Can't create new cvterms", 8;
    }

    my $re_read_t = CXGN::Chado::Cvterm->new( $dbh, $id );

    is( $re_read_t->name(),       $name,       "name test" );
    is( $re_read_t->definition(), $definition, "definition test" );
    is( $re_read_t->identifier(), $identifier, "identifier test" );

    my @slim_terms =
    qw | GO:0016787 GO:0016301 GO:0016740 GO:0003824 GO:0003700 GO:0003677 GO:0003676  GO:000016 GO:0005515 GO:0005554 GO:0006810 GO:0007165 GO:0016043 GO:0009987 GO:0006259 GO:0006403 GO:0019538 GO:0006118  GO:0006091 GO:0006350 GO:0008152 GO:0009628 GO:0009607 GO:0006950 GO:0032502  GO:0007582 GO:0008150 GO:0003674 GO:0032501|;

    my $go_term = CXGN::Chado::Cvterm->new_with_accession( $dbh, "GO:0003832" );

    my @matches = $go_term->map_to_slim(@slim_terms);

    my $go2 = CXGN::Chado::Cvterm->new_with_accession( $dbh, "GO:0048507" );

    my @matches2 = $go2->map_to_slim(@slim_terms);

    my @parent_info = $go_term->get_parents();
    is( @parent_info, 1, "go term one parent test" );

    my $other_term = CXGN::Chado::Cvterm->new_with_accession( $dbh, "GO:0019538" );

    my @other_parent_info = $other_term->get_parents();
    is( @other_parent_info, 2, "go term two parent test" );

    @matches = $other_term->map_to_slim(@slim_terms);
    print "term match = " . $matches[0] . "\n";
    my $p_term = CXGN::Chado::Cvterm->new_with_accession( $dbh, "GO:$matches[0]" );
    @parent_info = $p_term->get_parents();
    is( @parent_info, 1, "parent of parent test" );
}
$dbh->rollback();
