#!/usr/bin/perl

package Foo;
use CXGN::Class::MethodMaker [
	scalar => [qw/
		these
		are
		scalarish
		/,
		{-default => "3"},
		'methods',
		{-type => "CXGN::DB::Connection",
		 -forward => [qw/prepare execute/]
		 },
		'dbh',
		qw/ -static static_var /,
	]
];

sub new { bless {}, shift }
1;


use Test::More tests => 13;

ok(defined(&Foo::these), "Foo method these() created");
my $foo = new Foo;
$foo->these(1);
ok($foo->these(), "Setter for these() works");
ok($foo->these_isset(), "these_isset() is correct");
$foo->these_reset();
ok(!$foo->these_isset(), "these_reset() affects these_isset() properly");
ok(!defined($foo->these()), "these_reset() also delete value properly");
$foo->these(1);
ok($foo->these_isset(), "these_isset() works after setting");
is($foo->methods(), 3, "Default option worked");

use CXGN::DB::Connection { verbose => 0 };
my $dbh = CXGN::DB::Connection->new();
my $grub = new Foo;
eval {
	$foo->dbh($grub);
};
diag("Expected error: ". $@);
ok($@, "Setting dbh() to non-CXGN::DB::Connection type failed, as it should");

eval {
	$foo->dbh($dbh);
};
ok(!$@, "Setting dbh to CXGN::DB::Connection object successful");

ok(defined(&Foo::prepare), "Method prepare() exists on Foo");

my $sql = "SELECT COUNT(*) FROM sgn_people.sp_person";
diag("Preparing SQL: ". $sql);
my $sth = $foo->prepare($sql);
$sth->execute();
my ($count) = $sth->fetchrow_array();

ok($count, "Foo correctly forwards prepare() to its dbh() and gets a result: $count");

$foo->static_var(3);
is(Foo->static_var(), 3, "Static scalar set, tested on package");
my $foo2 = new Foo;
is($foo2->static_var(), 3, "Static scalar set, tested on different instance");


