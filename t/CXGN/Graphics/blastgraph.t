#!/usr/bin/env perl
use strict;
use warnings;

use File::Temp;

use FindBin;
use Path::Class;

use Test::More tests => 3;

BEGIN {
  use_ok(  'CXGN::Graphics::BlastGraph'  )
    or BAIL_OUT('could not include the module being tested');
}

my $tempfile = File::Temp->new;
my $raw_report_file = file( $FindBin::RealBin, 'blast_report_2.txt' );

my $graph2 = CXGN::Graphics::BlastGraph->new( blast_outfile => $raw_report_file,
					      graph_outfile => $tempfile,
					     );

my $errstr = $graph2->write_img();
is( $errstr, '', 'no error' );
cmp_ok( -s $tempfile, '>', 1_000,
	'blast graphic looks like it has some data in it',
       )
    or system 'display', $tempfile;

