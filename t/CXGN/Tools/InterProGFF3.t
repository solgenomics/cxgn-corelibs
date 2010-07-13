use strict;
use warnings;
use base 'Test::Class';
use Test::More tests => 3;

BEGIN { use_ok("CXGN::Tools::InterProGFF3") }

sub make_fixture : Test(setup) {
    my $self = shift;
}

sub teardown : Test(teardown) {
    unlink 't/data/interpro.gff3';
}

sub TEST_BASIC : Tests {
    my $converter = CXGN::Tools::InterProGFF3->new(
        filename => 't/data/interpro_sample.xml',
        output   => 't/data/interpro.gff3',
    );
    isa_ok($converter, 'CXGN::Tools::InterProGFF3');
    $converter->run;
    ok(-e 't/data/interpro.gff3','GFF3 file is created');

}
Test::Class->runtests;
