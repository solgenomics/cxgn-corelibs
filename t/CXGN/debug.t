#!/usr/bin/perl
use strict;
use warnings;
use English;

use CXGN::Config;
use Test::More tests => 7;
use Test::Warn;

BEGIN {
  use_ok(  'CXGN::Debug'  )
    or BAIL_OUT('could not include the module being tested');
}


my $conf_debug = CXGN::Config->load->{'debug'};

{
    local $ENV{CXGN_DEBUG} = 1;
    my $d = CXGN::Debug->new;
    warning_like {
        $d->debug('this is a test debug message');
    } qr/this is a test debug message/, 'debug() emits when CXGN_DEBUG is set to 1';
    warning_like {
        $d->d('this is a test debug message');
    } qr/this is a test debug message/, 'same thing with d()';
}


# NOTE: since currently there is no programmatic way to alter the
# VHost conf vars at runtime, have to settle for less-than complete
# testing of CXGN::Debug's response to the debug conf variable

SKIP: {
    skip 'debug conf var is set, cannot test silence of Debug in absence of either set variable', 2
        if $conf_debug;

    local $ENV{CXGN_DEBUG};
    delete $ENV{CXGN_DEBUG};

    my $d = CXGN::Debug->new;
    warning_is {
        $d->debug('this is a test debug message');
    } undef, "debug() does not emit when both conf debug and CXGN_DEBUG env var are false";
    warning_like {
        $d->d('this is a test debug message');
    } undef, 'same thing with d()';
}


{
    local $ENV{CXGN_DEBUG} = 0;
    my $d = CXGN::Debug->new;
    warning_is {
        $d->debug('this is a test debug message');
    } undef, "debug() does not emit when CXGN_DEBUG is set to 0";
    warning_like {
        $d->d('this is a test debug message');
    } undef, 'same thing with d()';
}
