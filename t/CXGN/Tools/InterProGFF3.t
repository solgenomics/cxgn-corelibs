use strict;
use warnings;
use base 'Test::Class';
use Test::More tests => 6;
use File::Slurp qw/slurp/;

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
    ok(-s 't/data/interpro.gff3','GFF3 file is not empty');
    my $file = slurp 't/data/interpro.gff3';
    like($file, qr/^##gff-version 3/, 'GFF3 version string');
    like($file, qr/^##feature ontology /m, 'GFF3 feature ontology directive');
}

Test::Class->runtests;
