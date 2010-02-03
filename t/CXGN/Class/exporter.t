package Foo;
use strict;
use base qw/CXGN::Class::Exporter/;
our $EXCHANGE_DBH = 1;
our $OPTION = undef;
our $ALIASED = undef;
BEGIN {
	our @EXPORT_OK = qw/will allow these/;
	our @EXPORT = qw/forced exported/;
}
our (@EXPORT_OK, @EXPORT);
foreach(qw/will allow these forced exported/){
	no strict 'refs';
	*{$_} = sub { return "Exported.\n" };
}
sub renamed { my $class = shift; $ALIASED = shift; }
1;

package Bar;
use CXGN::DB::Connection { verbose => 0 };
use base qw/CXGN::Class::Exporter/;
BEGIN { our $DBH = CXGN::DB::Connection->new(); }
our $EXPORT_DBH = 1;
our $EXCHANGE_DBH = 1;
our $DBH;
import Foo qw/allow/, { OPTION => "beesley", renamed => "hiya" };
sub new { my $class = shift; my $self = bless {}, $class }
1;

package Baz;
import Bar;
1;

package Goober;
use base qw/CXGN::Class::Exporter/;
BEGIN { our @EXPORT = qw/$IMPORT_DBH @ARRAY %HASH *GLOB_THING &syntax_check *try_this/ }
our @EXPORT;
our $IMPORT_DBH = 1;
our %HASH = (a=>'b');
our @ARRAY = (1,2,3);
our $GLOB_THING = 1;
our @GLOB_THING = (1,2);
sub syntax_check { print "Whateva" }
sub try_this { print "Hey-la" }
1;

package Snicker;
BEGIN { our $DBH = CXGN::DB::Connection->new() }
our $DBH;
import Goober;
1;


use Test::More tests => 14;
use CXGN::Class::Exporter ();
my $bar = new Bar;
my $lld = sub { return CXGN::Class::Exporter->looks_like_DBH(@_);};
ok($bar->can("allow"), "EXPORT_OK passed sub allow()");
ok(!$bar->can("these"), "EXPORT_OK correctly did not pass these()");
ok($bar->can("forced"), "EXPORT passed forced()");
ok($Foo::OPTION, "Foo imported 'OPTION':" . $Foo::OPTION);
ok($Foo::ALIASED, "Foo imported 'ALIASED' via renamed(): " . $Foo::ALIASED);
ok($lld->($Foo::DBH), "Foo imported valid global database handle using EXCHANGE_DBH");
ok($lld->($Baz::DBH), "Bar pushed its DBH to Baz using EXPORT_DBH");
ok($lld->($Goober::DBH), "Goober pulled its DBH from Snicker using IMPORT_DBH");
ok(defined($Snicker::IMPORT_DBH), "Goober exported a package scaler to Snicker");
ok(%Snicker::HASH, "Goober exported a package hash to Snicker");
ok(@Snicker::ARRAY, "Goober exported a package array to Snicker");
ok($Snicker::GLOB_THING && @Snicker::GLOB_THING, "Goober exported glob to Snicker");
ok(defined(&Snicker::syntax_check), "Goober exported explicit sub to Snicker");
ok(defined(&Snicker::try_this), "Goober exported sub via typeglob");
