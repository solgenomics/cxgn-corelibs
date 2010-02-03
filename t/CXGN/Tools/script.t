#!/usr/bin/perl
use strict;
use warnings;
use English;

use Test::More tests => 3;

BEGIN {
  use_ok(  'CXGN::Tools::Script'  )
    or BAIL_OUT('could not include the module being tested');
}

use CXGN::Tools::Script qw/out_fh in_fh lock_script unlock_script/;

ok(out_fh() == \*STDOUT, 'out_fh returns STDOUT with no arguments');
ok(in_fh() == \*STDIN, 'out_fh returns STDIN with no arguments');


