#!/usr/bin/perl

use strict;

use Test::More tests=>1;

use CXGN::Apache::Spoof;
use CXGN::Page::UserPrefs;
use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0);

$CXGN::Page::UserPrefs::ID = 768;

my $up = CXGN::Page::UserPrefs->new( CXGN::DB::Connection->new );

is( $up->{globals}->{id}, 768, 'Global ID set properly');



