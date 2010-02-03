#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 41;
use Test::Warn;

use CXGN::DB::Connection;
use CXGN::Config;

$ENV{TESTING_CXGN_DB_CONNECTION} = 1; #<turn off deprecation warning

my $conf = CXGN::Config->load;

{
    my $dbh = CXGN::DB::Connection->new({ config => $conf });
    isa_ok($dbh, 'CXGN::DB::Connection');

    my $realdbh = $dbh->get_actual_dbh();
    ok( $realdbh->ping, 'got a live db handle from get_actual_dbh' );

    $dbh = undef;
    ok( $realdbh->ping, 'real db handle is still live after its encapsulating dbh is destroyed' );
    $realdbh->disconnect;
}



{
  my $dbconn = CXGN::DB::Connection->new({config => $conf});
  isa_ok($dbconn,'CXGN::DB::Connection','constructor');
  my ($eightysix) = $dbconn->selectrow_array('SELECT 86');
  is($eightysix,86,'basic query');

  #dbtype is only allowed to return either 'Pg' or 'mysql'
  ok($dbconn->_dbtype eq 'Pg' || $dbconn->_dbtype eq 'mysql','valid db type');

  my ($ninetytwo) = $dbconn->selectrow_array('SELECT 92');
  is($ninetytwo,92,'dbh() accessor');
  $dbconn->disconnect;

  #test a first-generation subclass
  my $subclass = TestSubclass->new({ config => $conf });
  isa_ok($subclass,'TestSubclass','testsubclass constructor');
  my ($twelve) = $subclass->selectrow_array('SELECT 12');
  is($twelve,12,'basic query using subclass');
  $subclass->disconnect;

  #test a second-generation subclass
  my $subclass2 = TestSubclass2->new({ config => $conf });
  isa_ok($subclass2,'TestSubclass2','testsubclass2 constructor');

  my ($fortytwo) = $subclass2->selectrow_array('SELECT 42');
  is($fortytwo,42,'basic query using second subclass');
  my ($twentyfour) = $subclass2->selectrow_array('SELECT 24');
  is($twentyfour,24,'basic query using second subclass dbh() method');

  is($subclass2->{bogovalue},'bogo bogo bogo!','autoloading');
  ok($subclass2->nonexistent_method,'autoloading 2');
  $subclass2->disconnect;
}
{
  # test merging of DBI handle args with defaults
  my $dbconn = CXGN::DB::Connection->new({ config => $conf, dbargs => { private_mergeme => 'gumby dammit' } });

  is(ref($dbconn->_dbargs),'HASH','dbargs are set');
  is($dbconn->_dbargs->{private_mergeme},'gumby dammit','given dbarg was taken');
  ok(exists($dbconn->_dbargs->{AutoCommit}),'AutoCommit was set by the connection object');
  ok(exists($dbconn->_dbargs->{RaiseError}),'RaiseError was set by the connection object');
  $dbconn->disconnect;
}

{
  # Test things related to schema qualification.
  # These test are a little silly, since the point of qualify_schema is to
  # munge things so that we don't know how dbschema relates to the
  # qualified schema names.  If you change the munging in Connection.pm
  # you'll need to change these tests.

#  print "Testing qualify_schema method.\n";
  # Test constructing a DB::Connection without specifying dbbranch (so getting branch 
  # settings from the conf object).
  my $dbconn = CXGN::DB::Connection->new({ config => $conf, });
  isa_ok($dbconn,'CXGN::DB::Connection','constructor');

  warning_like {
      is($dbconn->qualify_schema("foo"),"foo",'qualified schema is equal to regular schema');
  } qr/deprecated/, 'got deprecation warning for qualify_schema';
  $dbconn->disconnect;
}

{
  local $ENV{DBHOST};
  local $ENV{DBPORT};
  local $ENV{DBUSER};
  local $ENV{DBPASS};
  # Test constructing a DB::Connection without specifying dbbranch (so getting branch 
  # settings from the conf object).
  my $dbconn = CXGN::DB::Connection->new_no_connect({ config => $conf });
  isa_ok($dbconn,'CXGN::DB::Connection','constructor');
  is($dbconn->_dbtype,'Pg','correct default dbtype');
  my $host = $conf->{'dbhost'} || 'hyoscine';
  is($dbconn->_dbhost,$host,'correct default dbhost');
  my $name = $conf->{'dbname'} || 'sandbox';
  is($dbconn->_dbname,$name,'correct default dbname 1');
  is($dbconn->dbname,$name,'correct default dbname 2');
  my $branch = $conf->{'production_server'} ? 'production' : 'devel';
  is($dbconn->_dbbranch, $branch, 'correct default dbbranch');
  is($dbconn->_dbuser, 'web_usr', 'correct default dbuser');
  is($dbconn->_dbpass, $conf->{dbpass}, 'correct default dbpass');
}

{
  # Test constructing a DB::Connection without specifying dbbranch (so getting branch 
  # settings from the conf object).
#  print "Testing last_insert_id method.\n";
  my $dbconn = CXGN::DB::Connection->new({ config => $conf });
  isa_ok($dbconn,'CXGN::DB::Connection','constructor');
  is($dbconn->_dbtype,'Pg','correct default dbtype');
 SKIP: {
    #skip these tests if we don't have insert permissions
    skip 'because we have no insert permissions on database connection',3 unless $dbconn->_dbuser ne 'web_usr';

    $dbconn->begin_work;
    $dbconn->do("CREATE TABLE last_insert_id_test_t (t_id SERIAL PRIMARY KEY, t_data varchar(10))");
    $dbconn->do("INSERT INTO  last_insert_id_test_t (t_data) VALUES ('foo')");
    my ($id0) = $dbconn->selectrow_array("SELECT t_id FROM last_insert_id_test_t WHERE t_data='foo'");
    my $id1 = $dbconn->last_insert_id("last_insert_id_test_t");
    my ($id2) = $dbconn->selectrow_array("SELECT max(t_id) FROM last_insert_id_test_t");
    my $id3 = $dbconn->last_insert_id("last_insert_id_test_t", "sgn");
    is($id0,$id1, 'liid 1');
    is($id0,$id2, 'liid 2');
    is($id0,$id3, 'liid 3');
    $dbconn->rollback;
  }
  $dbconn->disconnect;
}

{
  # Test the search_path method.
  my $dbconn = CXGN::DB::Connection->new({ config => $conf });
  isa_ok($dbconn,'CXGN::DB::Connection','constructor');

  my $default_search_path_str = join(', ',@{$conf->{dbsearchpath}});
  is( $dbconn->search_path, $default_search_path_str, 'correct default search path');

  $dbconn->disconnect;

  warnings_like {
      $dbconn = CXGN::DB::Connection->new("annotation", { config => $conf });
      isa_ok($dbconn,'CXGN::DB::Connection','constructor worked');
  } qr/ignored/i, 'got warning for using dbschema argument in legacy position';

  $dbconn->disconnect;

  warnings_like {
      $dbconn = CXGN::DB::Connection->new({ dbschema => 'annotation', config => $conf });
      isa_ok($dbconn,'CXGN::DB::Connection','constructor worked');
  } qr/ignored/i, 'got warning for using dbschema argument in normal position';

  is($dbconn->search_path, $default_search_path_str ,'search path did not change from dbschema arg');
  $dbconn->disconnect;
}

# {
#   #test what happens when you fork it all up
#   #fork and give handle to parent
#   my $conn = CXGN::DB::Connection->new( { config => $conf });
#   ok($conn->ping,'have a connection before fork');
#   if(my $pid = fork) {
#     ok($conn->ping,'parent connection alive right after fork'); 
#     sleep 1;
#     ok($conn->ping,'parent connection still alive after fork');
#     waitpid $pid, 0;
#   } else {
#     $conn->dbh_param(InactiveDestroy => 1);
#     exit;a
#   }
#   $conn->disconnect;
# }
# {
#   #fork and give handle to child
#   my $conn2 = CXGN::DB::Connection->new({ config => $conf });
#   if(my $pid = fork) {
#     $conn2->dbh_param(InactiveDestroy => 1);
#     waitpid $pid, 0;
#   } else {
#     # NOTE: that these tests are not being monitored by the parent
#     # test process, but will be monitored by any test harness this
#     # test script runs under
#     ok($conn2->ping,'child connection alive after fork');
#     sleep 1;
#     ok($conn2->ping,'child connection still alive after fork');
#     $conn2->disconnect;
#     exit;
#   }
# }

exit 0;

## test subclass of CXGN::DB::Connection
package TestSubclass;
use base qw/CXGN::DB::Connection/;

sub AUTOLOAD {
  return 'autoloaded monkeys!';
}

###second-generation test subclass
package TestSubclass2;

use base qw/TestSubclass/;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{bogovalue} = 'bogo bogo bogo!';
  return $self;
}

