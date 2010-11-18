#!/usr/bin/perl

=head1 NAME

t/CXGN/Chadoo/Stock.t - Tests for CXGN::Chado::Stock

=cut

=head1 SYNOPSIS

 prove t/CXGN/Chado/Stock.t

=cut

use Modern::Perl;
# This is why SGN::Test::Data needs to become Bio::Chado::Schema::Test::Data
use lib '../sgn/t/lib';
use SGN::Test::Data qw/create_test/;
use Test::Most tests => 3;

use CXGN::DB::Connection;
use Bio::Chado::Schema;
use CXGN::Chado::Stock;

use Data::Dumper;
use Carp::Always;

my $schema = SGN::Context->new->dbic_schema('Bio::Chado::Schema', 'sgn_test');

{
    my $cvterm = create_test('Cv::Cvterm',{ });
    my $stock  = create_test('Stock::Stock',{
        name    => "Mr Potato Head",
        type_id => $cvterm->cvterm_id,
    });
    my $rs = $schema->resultset('Stock::Stock')
        ->search({
            type_id => $stock->type->cvterm_id,
    });
    my $stock2 = $rs->single;
    isa_ok($stock2, 'Bio::Chado::Schema::Stock::Stock');
    is($stock2->name,'Mr Potato Head','Stock has correct name');
    is($rs->count,1,'a single stock was found');

}
