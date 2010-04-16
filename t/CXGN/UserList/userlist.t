#!/usr/bin/perl

use Test::More;
use CXGN::DB::Connection;
use CXGN::UserList::Handle;

my $dbh;
BEGIN {
    eval {
        $dbh = CXGN::DB::Connection->new("sgn_people");
    };
    if ($@ =~ m/DBI connect/){
        plan skip_all => "Could not connect to database";
    }
    die $@ if $@;
    plan tests => 3;
}
my $handle = CXGN::UserList::Handle->new($dbh, 768);
ok(defined $handle, '$handle is defined');
my $hotlist = $handle->get_hotlist();
ok(defined $hotlist, "get_hotlist()");
ok(defined $hotlist->get_list_size, "hotlist size");
