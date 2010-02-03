#!/usr/bin/perl


use Test::Simple tests => 3;
use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0);
use CXGN::UserList::Handle;

my $dbh = CXGN::DB::Connection->new("sgn_people");
my $handle = CXGN::UserList::Handle->new($dbh, 768);
ok(defined $handle, "\$handle is defined");
my $hotlist = $handle->get_hotlist();
ok(defined $hotlist, "get_hotlist()");
ok(defined $hotlist->get_list_size, "hotlist size");
