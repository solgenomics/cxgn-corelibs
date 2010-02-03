#!/usr/bin/perl

=head1 NAME

  organism.t
  A test for  CXGN::Chado::Organism class

=cut

=head1 SYNOPSIS

 perl organism.t



=head1 DESCRIPTION


=head2 Author

Naama Menda <n249@cornell.edu>


=cut

use strict;

use Test::More qw / no_plan / ; # tests=>6; 
use CXGN::DB::Connection;
use Bio::Chado::Schema;
use CXGN::Chado::Organism;

use Data::Dumper;

BEGIN {
    use_ok('Bio::Chado::Schema');
    use_ok('Bio::Chado::Schema::Organism::Organism');
}

#if we cannot load the CXGN::SEDM::Schema module, no point in continuing
Bio::Chado::Schema->can('connect')
    or BAIL_OUT('could not load the Chado::Schema  module');


my $schema=  Bio::Chado::Schema->connect( sub{ CXGN::DB::Connection->new()->get_actual_dbh()} ,  { on_connect_do => ['SET search_path TO public;'], }
    );
my $dbh= $schema->storage()->dbh();

my $last_organism_id= $schema->resultset('Organism::Organism')->get_column('organism_id')->max; 

#my $q= "SELECT max (organism_id) FROM organism";
#my $sth=$dbh->prepare($q);
#$sth->execute();
#my ($last_organism_id) = $sth->fetchrow_array();

# make a new organism and store it, all in a transaction. 
# then rollback to leave db content intact.

eval {
    #my $row=$schema->resultset('Organism::Organism')->create();

    my $o = CXGN::Chado::Organism->new($schema);
    
    my $species= "Solanum";
    my $genus= "testii";
    my $common_name= "test solanum";
    my $abbreviation= "S. testii";
    my $comment= "this is a test";
    
    my $dbix_o=$o->get_schema()->resultset('Organism::Organism')->new({species=>$species, genus=>$genus});
    #$o->get_schema()->resultset('Organism::Organism')species($species);
    $o->set_species($species);
    $o->set_genus($genus);
    $o->set_abbreviation($abbreviation);
    $o->set_comment($comment);
    $o->set_common_name($common_name);
    
    my $o_id= $o->store();
    
    
    #now store some dbxref info 
    #phylonode... 
    # 
    
    # my $re_o= CXGN::Chado::Organism->new($schema, $o_id);
    # is($re_o->get_genum(), $genus, "genus test");
    # is($re_o->get_species(), $species, "species test");
    # is($re_o->get_common_name(), $common_name, "common_name test");
    # is($re_o->get_abbreviation(), $abbreviation, "abbreviation test");
    # is($re_o->get_comment(), $comment, "comment test");
};

######ok (@term_list == 2, "get_parents");

if ($@) { 
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();

#reset table sequence
$dbh->do("SELECT setval ('organism_organism_id_seq', $last_organism_id, true)");


