#!/usr/bin/perl
use strict;
use Carp;
use Test::More tests=> 2;
use CXGN::Apache::Spoof;

use CXGN::Page::DeveloperSettings;
use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0);

$CXGN::Page::DeveloperSettings::ID = 768;

my $ds = CXGN::Page::DeveloperSettings->new();
is( $ds->{globals}->{id}, 600, 'Global ID Set Properly');
is( $ds->{globals}->{db_table}, 'sp_person', 'Table is "sp_person"' );


