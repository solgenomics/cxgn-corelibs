=head1 NAME

t/CXGN/People/login_sql.t - tests for the account queries in CXGN::People::Login

=head1 DESCRIPTION

Checks that passwords and confirm codes are passed to the database as
bind values, that the email lookup is an exact (case-insensitive) match,
that fetching a login keeps the organization, and that account secrets
are not written to STDERR.

Needs a database with the sgn_people schema (for example the sgn test
fixture). Connection parameters are read by CXGN::DB::Connection, for
example from DBHOST, DBNAME, DBUSER and DBPASS. All changes are rolled
back at the end.

=cut

use strict;
use warnings;

use Test::More tests => 16;

BEGIN {
    use_ok('CXGN::DB::Connection');
    use_ok('CXGN::People::Login');
}

my $dbh = CXGN::DB::Connection->new();

# run $code in a savepoint so that a failing statement does not abort
# the rest of the test transaction. Returns the error (if any) and the
# return value of $code.
#
sub run_in_savepoint {
    my $code = shift;
    $dbh->do("SAVEPOINT login_sql_test");
    my $result = eval { $code->() };
    my $error = $@;
    if ($error) {
        $dbh->do("ROLLBACK TO SAVEPOINT login_sql_test");
    }
    $dbh->do("RELEASE SAVEPOINT login_sql_test");
    return ($error, $result);
}

# returns everything $code prints to STDERR
#
sub stderr_of {
    my $code = shift;
    my $output = '';
    {
        local *STDERR;
        open(STDERR, '>', \$output) or die "Can't capture STDERR";
        $code->();
        close(STDERR);
    }
    return $output;
}

sub new_login {
    my ($username, $email, $organization) = @_;
    my $login = CXGN::People::Login->new($dbh);
    $login->set_username($username);
    $login->set_private_email($email);
    $login->set_password("initial-password");
    $login->set_organization($organization);
    return $login->store();
}

my $id_a = new_login("login_sql_test_a", 'login.sql.a@example.org', "Test Organization");
my $id_b = new_login("login_sql_test_b", 'login.sql.b@example.org', undef);

# fetch() and store() must keep the organization
#
my $login = CXGN::People::Login->new($dbh, $id_a);
is($login->get_organization(), "Test Organization", "organization is fetched");

$login->set_username("login_sql_test_a2");
$login->store();
my ($organization) = $dbh->selectrow_array("SELECT organization FROM sgn_people.sp_person WHERE sp_person_id=?", undef, $id_a);
is($organization, "Test Organization", "store() of a fetched login keeps the organization");

# passwords are bind values
#
my $password = "it's a new password";
my ($error, $result) = run_in_savepoint(sub { $login->update_password($password) });
is($error, '', "update_password with a quote in the password does not die");
is($result, $id_a, "update_password returns the sp_person_id");
is($login->verify_password($password), 1, "the new password verifies");
is($login->verify_password("initial-password"), 0, "the old password no longer verifies");

# confirm codes are bind values
#
my $confirm_code = "code'with'quotes";
($error, $result) = run_in_savepoint(sub { $login->update_confirm_code($confirm_code) });
is($error, '', "update_confirm_code with a quote in the code does not die");
is(CXGN::People::Login->new($dbh, $id_a)->get_confirm_code(), $confirm_code, "confirm code is stored as given");

# email lookup is exact but case-insensitive
#
is_deeply([ CXGN::People::Login->get_login_by_email($dbh, 'LOGIN.SQL.B@Example.ORG') ], [ $id_b ], "email match ignores case");
is_deeply([ CXGN::People::Login->get_login_by_email($dbh, 'login_sql_b@example.org') ], [ ], "underscore in an email is not a wildcard");
is_deeply([ CXGN::People::Login->get_login_by_email($dbh, 'login.sql.%') ], [ ], "percent sign in an email is not a wildcard");

# account secrets are not logged
#
my $log = stderr_of(sub {
    $login->verify_password($password);
    $login->update_confirm_code("confirm-code-1234");
    CXGN::People::Login->get_login_by_email($dbh, 'login.sql.b@example.org');
});
unlike($log, qr/\Q$password\E/, "verify_password does not log the password");
unlike($log, qr/confirm-code-1234/, "update_confirm_code does not log the code");
unlike($log, qr/login\.sql\.b\@example\.org/, "get_login_by_email does not log the email address");

$dbh->rollback();
