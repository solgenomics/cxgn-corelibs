#!/usr/bin/perl

=head1 NAME

  cvterm.t
  A test for  CXGN::Chado::Cvterm class

=cut

=head1 SYNOPSIS

 perl cvterm.t



=head1 DESCRIPTION

=cut

use strict;

use Test::More qw/no_plan/;
use CXGN::DB::Connection;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Ontology;
use Data::Dumper;

my $dbh = CXGN::DB::Connection->new();  

my @term_list =();

my @root_namespaces = CXGN::Chado::Cvterm::get_namespaces($dbh);

ok(@root_namespaces>0, "get_namespaces");
 
my @new_roots = CXGN::Chado::Cvterm::get_roots($dbh, "GO");
ok (@new_roots ==3, "GO namespace get_roots");



my $cv_term = undef;

my $cv_accession = "GO:0009536";

$cv_term = CXGN::Chado::Cvterm->new_with_accession($dbh, $cv_accession);

print STDERR "accession: ".$cv_term->get_cvterm_name()."\n";

is ($cv_term->get_cvterm_name(), "plastid", "get_cvterm_name function");
is ($cv_term->get_cv_name(), "cellular_component", "get_cv_name");
is ($cv_term->get_accession(), "0009536");
@term_list = $cv_term->get_children();
print "children count = ".scalar(@term_list)."\n";
ok(@term_list == 11, "get_children");
	
@term_list = $cv_term->get_parents();
print "parent count = ".scalar(@term_list)."\n";
ok (@term_list == 2, "get_parents");
is ($term_list[0]->[0]->identifier(), "0044444", "get_parents check 1");
is ($term_list[1]->[0]->identifier(), "0043231", "get_parents check 2");

# make a new cterm and store it, all in a transaction. 
# then rollback to leave db content intact.
#
eval { 
    my $ontology = CXGN::Chado::Ontology->new_with_name($dbh, "biological_process");
    print STDERR "CV ID: ".($ontology->get_cv_id())."\n";
    
    my $new_t = CXGN::Chado::Cvterm->new($dbh);

    my $identifier = "0000001";
    $new_t->identifier($identifier);
    $new_t->set_obsolete(0);

    my $name = "a test term";
    $new_t->name($name);

    my $definition = "a term to be used with test definitions and other tests, as well as testing";
    $new_t->definition($definition);
#    $new_t->version("?");
    $new_t->ontology($ontology);
    $new_t->set_db_name("GO");
    $new_t->set_cv_id($ontology->get_cv_id());
    my $id = $new_t->store();

    print STDERR "new cvterm_id = $id\n";
    $new_t = undef;

    my $re_read_t = CXGN::Chado::Cvterm->new($dbh, $id);
    
    is($re_read_t->name(), $name, "name test");
    is($re_read_t->definition(), $definition, "definition test");
    is($re_read_t->identifier(), $identifier, "identifier test");

};
if ($@) { 
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();


my @slim_terms = qw | GO:0016787 GO:0016301 GO:0016740 GO:0003824 GO:0003700 GO:0003677 GO:0003676  GO:000016 GO:0005515 GO:0005554 GO:0006810 GO:0007165 GO:0016043 GO:0009987 GO:0006259 GO:0006403 GO:0019538 GO:0006118  GO:0006091 GO:0006350 GO:0008152 GO:0009628 GO:0009607 GO:0006950 GO:0032502  GO:0007582 GO:0008150 GO:0003674 GO:0032501|;

my $go_term = CXGN::Chado::Cvterm->new_with_accession($dbh, "GO:0003832");

my @matches = $go_term->map_to_slim(@slim_terms);

foreach my $c (@matches) { 
    print $c."\n";
}

my $go2 = CXGN::Chado::Cvterm->new_with_accession($dbh, "GO:0048507");

my @matches2 = $go2->map_to_slim(@slim_terms);

foreach my $c (@matches2) { 
    print "Matches2: $c\n";
}


my @parent_info = $go_term->get_parents();
is(@parent_info, 1, "go term one parent test");

my $other_term = CXGN::Chado::Cvterm->new_with_accession($dbh, "GO:0019538");

my @other_parent_info = $other_term->get_parents();
is(@other_parent_info, 2, "go term two parent test");

@matches =  $other_term->map_to_slim(@slim_terms);
foreach my $c(@matches) { 
    print $c."\n";
}

my $p_term = CXGN::Chado::Cvterm->new_with_accession($dbh, "GO:$matches[0]");
@parent_info = $p_term->get_parents();
is(@parent_info, 1, "parent of parent test");

