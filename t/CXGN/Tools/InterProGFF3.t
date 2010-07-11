use strict;
use warnings;
use base 'Test::Class';
use Test::More tests => 2;

BEGIN { use_ok("CXGN::Tools::InterProGFF3") }

sub make_fixture : Test(setup) {
    my $self = shift;
}

sub teardown : Test(teardown) {
}

sub TEST_BASIC : Tests {
    my $converter = CXGN::Tools::InterProGFF3->new( file => 't/data/interpro.xml' );
    isa_ok($converter, 'CXGN::Tools::InterProGFF3');

}
Test::Class->runtests;
