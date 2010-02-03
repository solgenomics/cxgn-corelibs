package CXGN::DB::GFF::Versioned;
use strict;
use warnings;
use English;
use Carp;

use Data::Dumper;

use Hash::Util qw/lock_keys/;

use Bio::DB::GFF;

use CXGN::DB::Connection;

=head1 NAME

CXGN::DB::GFF::Versioned - wrapper for Bio::DB::GFF with a Postgres
backend, providing versioned loading and cleanup of Bio::DB::GFF
databases

=head1 SYNOPSIS

  # open a handle on the versioned series of databases
  # named my_db_base_name.1, my_db_base_name.2, ...
  my $db = CXGN::DB::GFF::Versioned->new( -db => 'my_db_base_name' );

  # load a new version of this DB with the given seq and gff3 file
  # will make my_db_base_name.(n+1) where n is the largest version of
  # my_db_base_name currently present.
  $db->load_new($seq_file,$gff3_file);

  # get a Bio::DB::GFF object opened to this most recent db
  my $bdb = $db->bdb;

  # get a Bio::DB::GFF object opened to version 2 of this db.  if
  # there is no version 2, $bdb will be undef
  my $bdb = $db->bdb(2);


=head1 FUNCTIONS

=cut

=head2 new

  Usage: my $dbgff = CXGN::DB::GFF::Versioned->new( -db => 'bio_db_gff' );
  Desc : opens the most recent version of the given database
  Args : hash-style list as:
           -db   => base name of database,
           -user => (optional) username to connect as, defaults to
                    whatever CXGN::DB::Connection defaults to,
           -pass => (optional) password to use for connecting, defaults to null
  Ret  : new object
  Side Effects:
  Example:

=cut

sub new {
  my ($class,%args) = @_;
  my $self = bless {}, $class;

  $args{-db} or croak "-db argument required for new()";

  $self->{control_dbh} = CXGN::DB::Connection->new
    ({ defined $args{-user} ? (dbuser => $args{-user}) : (),
       defined $args{-pass} ? (dbpass => $args{-pass}) : (),
       dbargs => {AutoCommit => 1}
     });

  if($args{-db} =~ /^cxgn_conf:(.+)$/) {
    $self->{dbname_root} = CXGN::VHost->new->get_conf($1)
      or die "CXGN configuration var '$1' not set\n";
  } else {
    $self->{dbname_root} = $args{-db};
  }

  $self->{version} = $self->_highest_db_version();

  lock_keys(%$self);

  return $self;
}


=head2 dbname

  Usage: my $n = $obj->dbname;
  Desc : get the (versioned) name of the database being used,
         e.g. 'bio_db_gff.2' for version 2 of the bio_db_gff
         database
  Args : optional version number, defaults to the latest
         version
  Ret  : text string, or nothing if no version number passed and
         no current database exists
  Side Effects: none

  If you pass an explicit version number, does not check whether that
  database actually exists.

=cut

sub dbname {
  my ($self,$version) = @_;
  $version ||= $self->_highest_db_version
    or return;
  $version =~ /\D/ && $version ne 'tmp' and confess "invalid version '$version'";
  $self->{dbname_root} or confess "no dbname_root defined";
  return "$self->{dbname_root}.$version";
}

=head2 bdb

  Usage: my $bdb = $obj->bdb
  Desc : get a Bio::DB::GFF handle for one of the versions of the database
  Args : optional numerical version to open, defaults to most recent
  Ret  : Bio::DB::GFF object at the requested version
         or nothing if it does not exist
  Side Effects: may open a new database connection
  Example:

=cut

sub bdb {
  my ($self,$version) = @_;
  $version = $self->_highest_db_version() unless defined $version;
  return unless $version;
  #warn "bdb with version $version\n";

  return $self->_open_bdb($version);
}

#open a bdb with the given database name, and possibly make it writable
sub _open_bdb {
  my ($self,$version,$new) = @_;

  my $dbname = $self->dbname($version);

  my ($dsn,$user,$pass,$dbargs) = $self->{control_dbh}->get_connection_parameters;
  $dsn =~ s/dbname=[^;]+/dbname=$dbname/i;

  my $bdb= Bio::DB::GFF->new(-adaptor=> 'dbi::pg',
			     -dsn => $dsn,
			     $new ? (-write =>1,-create => 1) : (),
			     -user => $user,
			     -pass => $pass,
			    )
    or die "Can't open Bio::DB::GFF $dbname database: ",Bio::DB::GFF->error,"\n";

  return $bdb;
}


=head2 load_new

  Usage: $obj->load_new([$seq_file,$seq_file2,...],[$gff3_file, $gff3_file2, ...]);
  Desc : loads the given sequence and gff3 file into a new version of
         the database, and updates this handle to point to the new version
  Args : base name,
         arrayref of seq files or single seq file,
         arrayref of GFF3 files or single GFF3 file
  Ret  : new handle
  Side Effects: creates new databases, loads data into them, dies on
                load errors

=cut

sub load_new {
  my ($self,$seqs,$gff3) = @_;

  $seqs = [$seqs] unless ref $seqs;
  $gff3 = [$gff3] unless ref $gff3;

  # make the .tmp database if necessary
  my $tmp_db = $self->dbname('tmp');
  $self->_make_db($tmp_db) unless $self->_db_exists($tmp_db);

  #open the gff and fasta files at the same time, so they don't get moved out from under us
  my @gff3_fh  = map { open my $f, $_ or die("$! opening $_ for reading\n"); $f } @$gff3;
  my @fasta_fh = map { open my $f, $_ or die("$! opening $_ for reading\n"); $f } @$seqs;

  # open our filehandles to /dev/null to shut up the idiotic warnings
  # and status messages spewed by this bioperl code
  local *STDOUT_SAVE;
  local *STDERR_SAVE;
  open STDOUT_SAVE, ">&STDOUT" or die "$! saving STDOUT";
  open STDERR_SAVE, ">&STDERR" or die "$! saving STDERR";
  open STDOUT, '>/dev/null' or die "$! opening STDOUT to /dev/null";
  open STDERR, '>/dev/null' or die "$! opening STDERR to /dev/null";

  my $bdb = $self->_open_bdb( 'tmp', 'new' );
  $bdb->initialize( -erase=>1 );

  foreach my $f ( @gff3_fh ) { #< non-verbose
    $bdb->do_load_gff($f,0);
    close $f;
  }
  foreach my $f ( @fasta_fh ) { #< non-verbose
    $bdb->load_fasta($f,0);
    close $f;
  }

  #now that we're done with bioperl, we can restore normal error reporting
  open STDERR, ">&STDERR_SAVE" or die "$! restoring STDERR";
  open STDOUT, ">&STDOUT_SAVE" or die "$! restoring STDOUT";

  #now grant web_usr select permissions
  my $bdb_dbh = $bdb->features_db();
  my $tables = $bdb_dbh->selectall_arrayref(<<EOSQL);
select tablename from pg_catalog.pg_tables where schemaname = 'public'
EOSQL
  foreach (@$tables) {
    $bdb_dbh->do(qq|grant select on "$_->[0]" to web_usr|);
  }

  #find the new version number
  my $new_version = $self->_next_db_version();

  undef $bdb; #< close the bdb database connection so we can rename that database

  # rename the .tmp DB to the new version number
  $self->_rename_db($tmp_db,$self->dbname($new_version));

  # and now finally, make sure we don't have too many old versions
  # sitting around
  $self->_clean_up_older_databases();

  #update this object's dbname
  $self->{version} = $self->_highest_db_version();
}


#### HELPER FUNCTIONS

sub _db_exists {
  my ($self,$dbname) = @_;

  my ($exists) = $self->{control_dbh}->selectrow_array(<<EOSQL,undef,$dbname);
select datname from pg_catalog.pg_database where datname = ? limit 1
EOSQL

  return 1 if $exists;
  return 0;
}

sub _make_db {
  my ($self,$dbname) = @_;
  $self->{control_dbh}->do(<<EOSQL);
create database "$dbname"
EOSQL
}

sub _rename_db {
  my ($self, $old_name, $new_name) = @_;

  my $conns = $self->{control_dbh}->selectall_arrayref('select * from pg_stat_activity where datname like ?',undef,$self->{dbname_root}.'%');
  #print "CURRENT CONNECTIONS:\n";
  #print Dumper $conns;
  my $retry_count = my $retries = 5;
  my $success = 0;
  while($retry_count--) {
    my $result = eval {
      $self->{control_dbh}->do(<<EOSQL);
alter database "$old_name" rename to "$new_name"
EOSQL
    };
    unless($EVAL_ERROR) {
      $success = 1;
      last;
    } else {
      warn $EVAL_ERROR;
      die unless $EVAL_ERROR =~ /other users/;
      warn "waiting 5 minutes for $old_name to become free up...\n";
      sleep 300; #< wait 5 minutes for autovacuum to finish
    }
  }
  unless($success) {
    die "db rename $old_name -> $new_name failed, even after $retries tries:\n$EVAL_ERROR\n";
  }
}

#find the next version in line
sub _next_db_version {
  my ($self) = @_;
  my $d = $self->_highest_db_version();
  $d ||= 0;
  return $d+1;
}

#only keep the last couple of database versions
sub _clean_up_older_databases {
  my ($self,$num_to_keep) = @_;

  $num_to_keep ||= 3; #< by default, keep 3 db versions around

  for( my $del = $self->_highest_db_version() - $num_to_keep;
       $self->_db_exists($self->{dbname_root}.'.'.$del);
       $del--
     ) {

    eval { #don't care if the drop fails
      $self->{control_dbh}->do(qq|drop database "$self->{dbname_root}.$del"|);
    }
  }
}

sub _highest_db_version {
  my ($self) = @_;

  my $r = $self->{dbname_root};
  $r =~ s!([\.\$\^])!\\$1!g;
  my ($d) = $self->{control_dbh}->selectrow_array(<<EOSQL,undef,$r,'^'.$r.'\.\d+$');
select regexp_replace(datname, '^' || ? || '\.','')::int as version
from pg_catalog.pg_database
where datname ~ ?
order by version desc
limit 1
EOSQL

   #warn "found highest version '$d'\n";
   return $d;
}


=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
