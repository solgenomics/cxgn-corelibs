=head1 NAME

CXGN::GEM::Test - central object for handling database connections and
dbic connections in the GEM test suite

=head1 SYNOPSIS

  my $gem_test = CXGN::GEM::Test->new;

  my $schema = $gem_test->dbic_schema('CXGN::GEM::Schema');

  my $metaloader_username = $gem_test->metaloader_user;

=cut

package CXGN::GEM::Test;
use Moose;
use namespace::autoclean;
use Test::More;

=head1 ATTRIBUTES

=head2 db_dsn, db_user, db_password, db_attributes

Readonly, the database DSN, user, and password for connecting.
Default to the values of the GEM_TEST_DB(DSN|USER|PASSWORD)
environment variables.

=cut

# gives a db_conn() method and db_* accessors
with 'MooseX::Role::DBIx::Connector';

# set up environment variables as db connection params if we have not
# been passed db_dsn, db_user, db_password
around 'BUILDARGS' => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{db_dsn}      ||= _env( 'DBDSN'  );
    $args->{db_user}     ||= _env( 'DBUSER' );
    $args->{db_password} ||= _env( 'DBPASS' );

    return $args;
};

sub _env {
    my $var = 'GEM_TEST_'.shift;
    $ENV{$var} or plan skip_all => "Environment variable $var not set, aborting";
}

=head2 db_search_path

Readonly. Arrayref of schemas to search.

Defaults to

  [qw[ gem sgn biosource metadata public ]]

=cut

has 'db_search_path' => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { [qw[ gem sgn biosource metadata public ]] },
   );

has 'metaloader_user' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { _env('METALOADER') },
   );


=head1 METHODS

=head2 dbic_schema( "My::Schema" )

Connect to and return the given DBIC schema using the values of the
db_* attributes.

=cut

sub dbic_schema {
    my ( $self, $schema_name ) = @_;

    Class::MOP::load_class( $schema_name );

    return
        $schema_name->connect(
            $self->db_dsn,
            $self->db_user,
            $self->db_password,
            { on_connect_do => 'SET search_path TO '.join ',', @{$self->db_search_path} },
           );
}


1;

