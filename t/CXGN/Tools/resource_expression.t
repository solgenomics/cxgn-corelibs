use strict;
use warnings;

use File::Temp 'tempfile';
use File::Slurp 'slurp';

use CXGN::Tools::Wget::ResourceExpression qw/ fetch_expression test_fetch_expression /;

use Test::More;

my ( undef, $tempfile ) = tempfile();
fetch_expression( 'cat( http://google.com, http://solgenomics.net )' => $tempfile );
cmp_ok( -s $tempfile, '>=', 5000, 'got at least 5kb from concat of google and solgenomics' );

{ # test the cxgn-resource unzip() operation
    CXGN::Tools::Wget::ResourceExpression::op_unzip( $tempfile, 0, 't/data/test_zipfile.txt.zip' );

    is slurp( $tempfile ), <<'', 'got the right unzipped contents';
This is a test zipfile!

}

done_testing;
