#!/usr/bin/perl

=head1 NAME

  stock.t
  A test for  CXGN::Chado::Stock class

=cut

=head1 SYNOPSIS

 prove stock.t



=head1 DESCRIPTION


=head2 Author

Naama Menda <n249@cornell.edu>


=cut

use strict;

use Test::More  tests => 6;
use CXGN::DB::Connection;
use Bio::Chado::Schema;
use CXGN::Chado::Stock;

use Data::Dumper;

BEGIN {
    use_ok('Bio::Chado::Schema');
    use_ok('Bio::Chado::Schema::Stock::Stock');
}

#if we cannot load BCS, no point in continuing
Bio::Chado::Schema->can('connect')
    or BAIL_OUT('could not load the Bio::Chado::Schema  module');


my $schema=  Bio::Chado::Schema->connect( sub{ CXGN::DB::Connection->new()->get_actual_dbh()} ,  { on_connect_do => ['SET search_path TO public;'], }
    );
my $dbh= $schema->storage()->dbh();

my $last_stock_id= $schema->resultset('Stock::Stock')->get_column('stock_id')->max;

# make a new stock and store it, all in a transaction.
# then rollback to leave db content intact.

eval {

    my $stock = CXGN::Chado::Stock->new($schema);
    my $accession = $schema->resultset("Cv::Cvterm")->create_with(
        { name   => 'accession',
          cv     => 'stock type',
          db     => 'null',
          dbxref => 'accession',
        });

    my $name = 'test stock';
    my $uniquename = 'Uniquename for test stock';

    $stock->set_name($name);
    $stock->set_uniquename($uniquename);
    $stock->set_type_id( $accession->cvterm_id );

    my $s_id= $stock->store();

    my $re_s= CXGN::Chado::Stock->new($schema, $s_id);
    is($re_s->get_name(), $name, "name test");
    is($re_s->get_uniquename(), $uniquename, "uniquename test");
    is($re_s->get_type->name, 'accession', "Accession stock type test");

    my ($bcs_stock)=$schema->resultset('Stock::Stock')->search(
        {
             name => $name,
             uniquename => $uniquename,
             type_id => $accession->cvterm_id,
         });
    is( $bcs_stock->stock_id , $stock->get_stock_id , 'Store new stock test');
};


if ($@) {
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();

#reset table sequence
$dbh->do("SELECT setval ('stock_stock_id_seq', $last_stock_id, true)");


