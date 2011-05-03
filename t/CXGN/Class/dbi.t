package Foo;
use base qw/CXGN::Class::DBI/;
CXGN::Class::DBI->verbose(0);
Foo->required_search_paths(qw/sgn_people/);
Foo->set_sql("test", "SELECT COUNT(*) FROM sp_person");
Foo->set_sql("test_with_arg", 
    "SELECT sp_person_id FROM sp_person
        WHERE sp_person_id > ?
        ORDER BY \$_[0] \$_[1]
    ");
1;


use Test::More tests => 14;
use CXGN::DB::Connection { verbose => 0 };
use Modern::Perl;
my $foo = new Foo;
my $sth;

{
    no warnings 'once';
    ok(!$Foo::DBH, "DBH should not be made until first call to get_sql()");
}
ok($sth = $foo->get_sql("test"), "Can get statement from handle");
ok($sth = Foo->get_sql("test"), "Can get statement from class");
ok($sth->execute(), "Can execute statement");
my $count;
diag("Result for query '" . Foo->get_definition("test") . "': $count");
ok(($count) = $sth->fetchrow_array(), "Fetched result");

eval {
    $sth = $foo->get_sql("test_with_arg", "sp_person_id");
};
{
    my $err = $@;
    my @err = split "\n", $err;
    diag("Expected Error: " . $err[0]);
    ok($@, "SQL with arguments should fail when too few arguments are sent");
}
eval {
    $sth = $foo->get_sql("test_with_arg", "sp_person_id", "DESC", "SayWHaaaat!?");
};
{
    my $err = $@;
    my @err = split "\n", $err;
    diag("Expected Error: " . $err[0]);
    ok($@, "SQL with arguments should fail when too many arguments are sent");
}
{
    my $sth = $foo->get_sql("test_with_arg", "sp_person_id", "ASC");
    $sth->execute(5);
    my ($first) = $sth->fetchrow_array();
    is($first, 6, "First row should be 6 when id's are ascending and minimum is 6");
}

my $global= $foo->get_sql('test');

my $foo2 = new Foo;
my $also = $foo2->get_sql('test');
ok($global == $also, "Two global existing prepared statements are the same reference");

$foo2->{dbh} = CXGN::DB::Connection->new();
my $instance= $foo2->get_sql('test');
ok($global != $instance, "Instance sth should differ");
my $instance2 = $foo2->get_sql('test', {global=>1});
ok($global == $instance2, "Instance sth should be global if option set");
ok($instance2 != $instance, "And a global sth should not be the same as the instance sth");

my $unique = $foo2->get_sql('test', {no_cache=>1});
my $global_unique = $foo->get_sql('test', {no_cache=>1}); #no local {dbh}

ok((($unique != $instance) and ($unique != $global) and ($unique != $instance2) and ($unique != $global_unique)), "no_cache creates a unique sth on instances with {dbh}");

ok((($global_unique != $instance) and ($global_unique != $global) and ($global_unique != $instance2) and ($global_unique != $unique)), "no_cache creates a unique sth on when global statements are used");



