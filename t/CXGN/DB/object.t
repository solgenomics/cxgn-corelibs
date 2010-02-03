
=head1 NAME

object.t - a test script for the CXGN::DB::Object class.

=head1 AUTHOR

Lukas Mueller

=cut

use strict;

use Test::More tests => 9;
use Test::Warn;

BEGIN {

    use_ok("CXGN::DB::Connection");
    use_ok("CXGN::DB::Object");

}

my $dbh = CXGN::DB::Connection->new();

my $dbo = CXGN::DB::Object->new($dbh);
isnt( $dbo,          undef, "object not undef check" );
isnt( $dbo->get_dbh, undef, "dbh in object not undef check" );
can_ok( $dbo->get_dbh, 'selectall_arrayref', 'prepare' );

warning_is {
    CXGN::DB::Object->new( $dbh->get_actual_dbh )
} undef, 'does not warn for an actual dbh';

my $tdbo = TestDBObject->new($dbh);
isa_ok( $tdbo->get_dbh, "CXGN::DB::Connection" );

my $so = DBIxSchemaObject->connect(
    sub { return CXGN::DB::Connection->new()->get_actual_dbh(); } );

my $tso = TestSchemaObject->new($so);

ok( $tso->get_schema()->isa("DBIx::Class"),
    "Test schema object accessor test" );

is( $tso->get_dbh()->isa("DBI::db"), 1,
    "Test schema object dbh accessor test" );

package TestDBObject;

use base qw | CXGN::DB::Object |;

sub new {
    my $class = shift;
    my $dbh   = shift;

    my $self = $class->SUPER::new($dbh);

    return $self;
}

package TestSchemaObject;

use base qw | CXGN::DB::Object |;

sub new {
    my $class  = shift;
    my $schema = shift;

    my $self = $class->SUPER::new($schema);

    return $self;
}

package DBIxSchemaObject;

use base qw | DBIx::Class::Schema |;

__PACKAGE__->load_components( "PK::Auto", "Core" );

