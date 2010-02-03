package CXGN::IndexedLog;
use strict;
use warnings;
use English;
use Carp;
use FindBin;

#use Data::Dumper;

=head1 NAME

CXGN::IndexedLog - a simple logging interface designed for efficient
reading and searching of the log, as well as writing

=head1 SYNOPSIS

  my $log = CXGN::IndexedLog->open(File => 'myfile.log');
  $log->append('I am the egg man');

  my %entry = $log->lookup(content => 'I am');
  #entry is now something like
  # %entry = ( content   => 'I am the egg man',
  #            timestamp => "Oct 17 13:19:24",
  #            progname  => 'myprogram.pl',
  #            pid       => 24601,
  #            host      => 'scopolamine',
  # 	     );

=head1 DESCRIPTION

An indexed log is a time series of entries holding a timestamp, the
host, program, and process making the entry, and some entry content.
It's designed to be written to and read from concurrently by multiple
scripts running on multiple machines.

Currently, the log is implemented as a flat file in a format similar
to a system log, designed to be easily readable by a human as well as
by this module.  Concurrency is achieved with file locking over NFS
using L<File::NFSLock>.  Currently, reading from the log is only done
once, on the first lookup made from the log.  After that, the relevant
log contents are cached in memory until the program exits.  This means
that writes made by other programs will not be noticed by another
running program unless that program creates another log object, which
will then reread the log.

If more functionality is needed later, the implementation of this
object may be changed to use a database backend instead of a flat file
over NFS.  This should require few or no changes to the interface.

=head1 CLASS METHODS

=cut

=head2 open

  Usage: my $log = CXGN::IndexedLog->open( File => 'filename');
  Desc : open a new handle on a processing log file
  Ret  : a new log object
  Args : ( the storage engine name (currently there is only 'File'),
           the info needed to initialize the datastore (File takes just a filename),
         )
  Side Effects: creates the log file if it does not exist, dies on
                failure

=cut

sub open {
  my ($package,$backend,@args) = @_;
  $backend or croak 'must pass storage backend name to open()';
  my $self = bless {}, $package.'::'.$backend;
  $self->init(@args);
  return $self;
}

=head1 OBJECT METHODS

=head2 lookup

  Usage: my %entry = $log->lookup( content =>
                                   "$firstword $secondword"
                                 );
  Desc : search the log for the _most_recent_ entry matching the given
         criteria and return it
         Currently, only exact searching on the first two words of the
         content field is supported.
  Ret  : a hash-style list as:
           ( content   => 'line contents',
             timestamp => unixtime when the line was written,
    	     progname  => 'basename of the program that wrote the line',
	     pid       => PID of the program that wrote the line,
	     host      => 'hostname of the program that wrote the line',
             user      => UNIX username of the user that wrote the line,
           )
         or nothing if no matching entry was found
  Args : hash-style list of search criteria.  Currently, only a search
         on the content field is supported.
  Side Effects: dies on failure to parse the log if
                $CXGN::IndexedLog::RaiseParseError = 1.
                It defaults to 0.

=cut

sub lookup {
  die "abstract method lookup must be implemented in subclass!";
}


=head2 is_writable

  Usage: $log->is_writable or die "can't write to it!"
  Desc : return true if an append() will work, false if not
  Args : none
  Ret  : true if the log is writable, false otherwise
  Side Effects: may attempt to write to the log, then
                undo the write if it was successful

=cut

sub is_writable {
  die 'is_writable must be implemented by subclasses';
}

=head2 append

  Usage: $log->append('Charles Darwin has a posse');
  Desc : add an entry to the end of the log.  a timestamp, hostname, pid,
         and script name are added automatically.
  Ret  : nothing meaningful
  Args : list of strings, which will be chomped and join()ed by spaces
         before being written to the log.
  Side Effects: dies on failure
  Example:

=cut

our ($hostname) = `hostname -s`;
our ($whoami) = `whoami`;
chomp $hostname;
chomp $whoami;
$hostname ||= 'unknown_host';
sub append {
  my ($self,@data) = @_;
  chomp @data;
  $self->_write(
		 sysuser => $whoami,
		 host    => $hostname,
		 script  => $FindBin::Script,
		 pid     => $PID,
		 text    => \@data,
	       );

}

=head2 reset

  Usage: $log->reset
  Desc : reset the log to an empty state, either obsoleting or
         deleting old entries
  Ret  : nothing meaningful
  Args : none
  Side Effects: dies on failure
  Example:

=cut

sub reset {
  die "reset method not implemented in superclass";
}

=head1 AUTHOR(S)

Robert Buels

=cut


package CXGN::IndexedLog::File;
use Carp;
use English;
use POSIX;

use Fcntl qw/LOCK_EX LOCK_NB/;
use File::NFSLock;

use base qw/Class::Accessor CXGN::IndexedLog/;
__PACKAGE__->mk_accessors('_filename');

sub init {
  my ($self,$filename) = @_;

  local $Carp::CarpLevel = 2;
  $filename or croak 'need filename';
  unless(-f $filename) { #create the file if it doesn't exist
    CORE::open my $fh,">$filename"
      or croak "Could not create log file '$filename': $!";
  }

  $self->_filename($filename);
}

sub lookup {
  my ($self,%criteria) = @_;
  my @keys = keys %criteria;
  @keys == 1 and $keys[0] eq 'content'
    or croak "only searches by content are currently supported";
  my $index = $self->_log_index;
  #warn "got index:\n", Dumper($index);
  my @words = split /\s+/,$criteria{content};
  @words >= 2
    or croak "must specify at least two search words for content";
  my $line = $self->_log_index->{$words[0]}{$words[1]}
    or return ();
  return %$line;
}

sub is_writable {
  return -w shift->_filename;
}

sub reset {
  my ($self) = @_;
  $self->_write("RESET\n");
}

#lock our log file, open it, append the given line of text to it,
#and close it.  we don't keep it open in order to minimize any
#possibly lock contention from multiple hosts
sub _write {
  my ($self,%args) = @_;
  my @text = @{$args{text}};

  s/\n/\\n/g for @text; #make sure there are no newlines

  my $lock = $self->_get_lock;
#  warn 'writing to '.$self->_filename;
  CORE::open(my $fh, '>>'.$self->_filename)
    or croak "Could not open '".$self->_filename."' for appending: $!";
  #  warn 'wrote';
  print $fh join(' ',
		 $self->_timestring,
		 $args{sysuser}.'@'.$args{host},
		 $args{script}.'['.$args{pid}.']:',
		 @text,
		)."\n";

  #add this entry to the index if it has been generated
  if($self->{index}) {
    my @words = map {split /s+/,$_} @text;
    if(@words >= 2) {
      $self->{index}->{$words[0]}{$words[1]} = { content =>  join(' ',@text),
						 host => $hostname,
						 pid => $PID,
						 progname => $FindBin::Script,
						 timestamp => $args{timestamp}, #pretty close to what we wrote, anyway
					       };
    }
  }
}
sub _timestring {
  strftime "%b %e %H:%M:%S", localtime
}

our $RaiseParseError = 0;
sub _error(@) {
  if($RaiseParseError) {
    croak @_;
  } else {
    carp @_;
  }
}

#obtain a lock on our log file
sub _get_lock {
  my $self = shift;
  my $lock = File::NFSLock->new( { file      => $self->_filename,
				   lock_type => LOCK_EX,
				   blocking_timeout => 10,
				   stale_lock_timeout => 10*60, #10 mins
				 })
    or croak "Could not lock processing log file ".$self->_filename;
  return $lock;
  #NOTE that the release of this lock happens automatically when
  #it goes out of scope
}


#read the log file and index it in memory.
#only do this once for each object
sub _log_index {
  my $self = shift;
  return $self->{index} ||= do {
    my $logfile_name = $self->_filename;
    my $file_lock = $self->_get_lock;
    my %index;
    CORE::open(my $record_fh,$logfile_name)
      or croak "Could not open log file '$logfile_name' for reading: $!";
    eval {
      while (<$record_fh>) {
	chomp;
	if ($_ eq "RESET") {
	  %index = ();
	} elsif(/\S/) { #if the line isn't whitespace
	  my ($tsmonth,$tsday,$tstime,$userhost,$progpid,$content) = split /\s+/,$_,6
	    or do{ _error "can't parse line '$_'"; next};
	  my ($user,$host) = split /@/,$userhost
	    or do{ _error("can't parse userhost '$userhost'"); next};
	  my @content = split /\s+/,$content;
	  if(@content >= 2) {
# 	    my $unixtime = str2time("$tsmonth $tsday $tstime")
# 	      or do{ _error "Could not parse date '$tsmonth $tsday $tstime'"; next};
	    my ($prog,$pid) = $progpid =~ /([^\[]+)\[(\d+)\]/
	      or do{ _error "Could not parse program/pid entry '$progpid'"; next};
	    $index{shift @content}{shift @content} = { content   => $content,
						       timestamp => "$tsmonth $tsday $tstime",
						       progname  => $prog,
						       pid       => $pid,
						       host      => $host,
						       user      => $user,
						     };
	  }
	  #just skip lines with fewer than two words
	}
      }
    }; if($EVAL_ERROR) {
      croak "Error reading bac processing log file\n: $EVAL_ERROR\n (file '$logfile_name', line $.)\n";
    }
    \%index;
  };
}


###### DB STORAGE BACKEND

package CXGN::IndexedLog::DB;

use Carp;
use English;

use base qw/Class::Accessor CXGN::IndexedLog/;
__PACKAGE__->mk_accessors(qw/_table _dbh/);

sub init {
  my ($self,$dbh,$table) = @_;
  croak "must pass a database handle" unless $dbh && $dbh->can('selectall_arrayref');
  croak "must pass a table name to open" unless $table && ! ref $table;
  $self->_table($table);
  $self->_dbh($dbh);
  $self->_create_if_not_exists; #<make sure our table exists
}

sub lookup {
  my ($self,%criteria) = @_;
  $self->_create_if_not_exists; #<make sure our table exists

  #check the search criteria
  { my @k = keys %criteria; @k == 1 && $k[0] eq 'content'
      or croak __PACKAGE__.": currently, only lookup by content is supported by IndexedLog DB backend";
    $criteria{content} =~ /\S/ or croak __PACKAGE__.": cannot search with empty content '$criteria{content}'";
  }

  my $search_key = $self->_make_search_key($criteria{content});
  my $table = $self->_table;
  my $row = $self->_dbh->selectrow_arrayref(<<EOSQL,undef,$search_key);
select extract('epoch' from timestamp) as timestamp, uname, host, progname, pid, message
from public.$table
where deleted = false
  and search_key = ?
order by timestamp desc
limit 1
EOSQL

  return unless $row && @$row;

  my %ret;
  @ret{qw/timestamp user host progname pid content/} = @$row;
  return %ret;
}

sub is_writable {
  my ($self) = @_;

  $self->_dbh->dbh_param( AutoCommit => 0 );
  my $table = $self->_table;
  eval {
    $self->_dbh->do("insert into public.$table (deleted,uname,host,progname,pid) values (true,'idxltest','idxltest','idxltest',0)");
  };
  if( $EVAL_ERROR ) {
    return 0;
  }
  $self->_dbh->rollback;
  $self->_dbh->dbh_param( AutoCommit => 1 );
  return 1;
}

#extracts the first two words, lower-cased, with whitespace normalized to one space
sub _make_search_key {
  return join(' ',(split /\s+/,$_[1])[0,1]);
}

sub _write {
  my ($self,%data) = @_;
  $self->_create_if_not_exists; #<make sure our table exists

  $data{host} =~ /\./
    and die "host $data{host} has dots in it.  it should be just one word, e.g. 'solanine'";

  chomp @{$data{text}}; #< no final newlines in the log text
  $data{text} = join ' ',@{$data{text}};

  $data{search_key} = $self->_make_search_key($data{text});

  my $table = $self->_table;

  $self->_dbh->do(<<EOSQL,undef,@data{qw/sysuser host script pid search_key text/});
insert into public.$table
( uname, host, progname, pid, search_key, message ) values
( ?,     ?,    ?,        ?,   ?,          ?       )
EOSQL

}

sub reset {
  my ($self) = @_;
  $self->_create_if_not_exists; #<make sure our table exists

  my $table = $self->_table;
  $self->_dbh->do(<<EOSQL);
update public.$table set deleted = true where deleted = false
EOSQL
}


sub _create_if_not_exists {
  my ($self) = @_;
  my $table = $self->_table;

  die 'log tables in schemas not supported' if $table =~ /\./;

  # return if the table exists.  note that this check is only going to
  # be run once for each table
  our %exists;
  return if $exists{$table} ||=
    $self->_dbh->selectrow_array("select tablename from pg_catalog.pg_tables where tablename=? and schemaname = 'public'",
			   undef,
			   $table
			  );
  #otherwise, try to create it.  this will die if there is are no permissions to get it
  $self->_dbh->do(<<EOS);
create table public.$table (
  id serial NOT NULL,
  deleted boolean NOT NULL default false,
  timestamp timestamp without time zone DEFAULT now() NOT NULL,
  uname varchar(40) NOT NULL,
  host varchar(40) not null,
  progname varchar(80) not null,
  pid integer not null,
  search_key varchar(200),
  message text
)
EOS
  #index by its text key
  $self->_dbh->do(<<EOS);
create index ${table}_key on public.$table (search_key,deleted)
EOS
}

###
1;#do not remove
###
