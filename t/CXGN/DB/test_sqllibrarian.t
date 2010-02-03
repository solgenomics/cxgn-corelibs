#!/usr/bin/perl -w
use strict;
use Test::More 'no_plan';
use Test::Exception;

package MyPackage;
sub new {
  my ($class) = @_;
  my $self = {};
  bless ($self, $class);
  return ($self);
}

package MySubPackage;
use base ("MyPackage");

package MyOtherPackage;
sub new {
  my ($class) = @_;
  my $self = {};
  bless ($self, $class);
  return ($self);
}

package main;
use CXGN::DB::SQLLibrarian;

{
  my $librarian = SQLLibrarian->new;
  $librarian->load("test-sqllib");
  my $p  = MyPackage->new;
  my $np = MySubPackage->new;
  my $op = MyOtherPackage->new;

  ok($librarian->lookup("fooq", $p), 'looked up query for class');
  ok($librarian->lookup("fooq", $np), 'looked up query for subclass');
  ok($librarian->lookup("barq", $op), 'looked up query for other class');
  dies_ok { $librarian->lookup("barq", $p) } 'failed to look up query';
  print STDERR "$@";
}

# Same, but use a fancier library name.
{
  my $librarian = SQLLibrarian->new;
  $librarian->load("CXGN::DB::t::test-sqllib");
  my $p  = MyPackage->new;
  my $np = MySubPackage->new;
  my $op = MyOtherPackage->new;

  ok($librarian->lookup("fooq", $p), 'looked up query for class');
  ok($librarian->lookup("fooq", $np), 'looked up query for subclass');
  ok($librarian->lookup("barq", $op), 'looked up query for other class');
  dies_ok { $librarian->lookup("barq", $p) } 'failed to look up query';
  print STDERR "$@";
}

# See if the librarian hands out queries for the current program name.
{
  my $librarian = SQLLibrarian->new;
  $librarian->load("CXGN::DB::t::test-sqllib");

  # This should fail
  dies_ok { $librarian->lookup("fooq")} 'could not look up query for program name';
  dies_ok { $librarian->lookup("barq")} 'could not look up query for program name';
  ok(print ">>".$librarian->lookup("bazq")."\n", 'looked up query for program name');
  print STDERR "$@";
}

# Make the librarian die, in several ways.
{
  my $librarian = SQLLibrarian->new;
  dies_ok {$librarian->load("zzzzzzzzzz")} 'bogus library name';
  print STDERR "$@";
}

{
  my $librarian = SQLLibrarian->new;
  use File::Temp;
  my $tn = File::Temp::tempnam(".", "sqllibrarian-");
  $tn =~ s|\./||;
  my $fn = "$tn.sqllib";
  system ("touch $fn; chmod 000 $fn");
  dies_ok {$librarian->load("$tn")} 'unopenable library name';
  print STDERR "$@";
  unlink $fn;
}
## FIXME: need lots of tests of the query library parsing.
