#!/usr/bin/perl
# and Term::ReadKey, included below


=head1 NAME

  CXGN::DB::InsertDBH - prompts user for password, then invokes CXGN::DB::Connection

=head1 SYNOPSIS

Really, it's just like CXGN::DB::Connection, except it'll override
any password you give it.

  use CXGN::DB::InsertDBH;

  my $dbh = CXGN::DB::InsertDBH->new({
                                      dbname => 'sandbox',
                                      dbhost => 'scopolamine',
                                      dbschema => 'public',
                                      dbargs => {AutoCommit => 0,
                                                 RaiseError => 1}
                                     });

=head1 DESCRIPTION

Prompts the user for a username and password; and then, asks
DB::Connection for a $dbh. You should use this so you don't have to
encode a password anywhere.

=head2 Methods

=over 12

=item new()

Provide the same arguments you would give to
CXGN::DB::Connection->new().  However, providing dbuser or dbpass is
useless, since those will be overwritten.

=item commit_prompt($prompt_message, $yes_regexp, $no_regexp, $stern_message)

Print $prompt_message to STDOUT, then read one line of response from
the user.  If the line matches $yes_regexp, try to commit; if it
sssssssssmatches $no_regexp, try to rollback; if it matches neither print
$stern_message.  Do this until either commit or rollback is performed.

=back

=head1 AUTHOR

Beth, mostly.

=head1 SEE ALSO

CXGN::DB::Connection

=cut

package CXGN::DB::InsertDBH;
use strict;
use CXGN::DB::Connection;
use Carp;

sub _dbargs {
  my $class = shift;

  # connects with CXGN::DB::Connection, prompting you for
  # a username and password.
  my ($dbargs) = @_;

  ######################################################
  # we will prompt the user for a username and password.
  #  my $un = $ENV{"USER"};

  open (my $TTY, '>', '/dev/tty') or die "what the heck - no TTY??\n";

  my $un = "postgres";
  print $TTY "Database username for write access (default \"$un\"): ";

  use Term::ReadKey;
  ReadMode 'normal';
  my $ln = ReadLine(0);
  chomp $ln;
  if ($ln) {
    $un = $ln;
  }

  $dbargs->{dbuser} = $un;

  print $TTY 'Password: ';

  use Term::ReadKey;
  ReadMode 'noecho';
  $dbargs->{dbpass} = ReadLine(0);
  ReadMode 'normal';
  chomp $dbargs->{dbpass};
  print $TTY "\n"; #newline to let the user know the password was entered
  # done with username/password
  close $TTY;

  ###############################################
  # make some default parameters for ease of use, and for safety's sake
  #
  # the default behavior will be to modify the sandbox database, which is always harmless.
  # you must explicitly specify when you want your script to run on the real database.
  # this is another layer of protection, in addition to the devel/production distinction
  # and in addition to transactions.
  unless(defined($dbargs->{dbname}))
  {
      $dbargs->{dbname}='sandbox';
  }
  # make darn sure autocommit defaults to off. this is redundant but redundant safety is good.
  unless(defined($dbargs->{dbargs}->{AutoCommit}))
  {
      $dbargs->{dbargs}->{AutoCommit}=0;
  }
  # make darn sure raiseerror defaults to on. this is redundant but redundant safety is good.
  unless(defined($dbargs->{dbargs}->{RaiseError}))
  {
      $dbargs->{dbargs}->{RaiseError}=1;
  }
  ###############################################

  return $dbargs;
}

=head2 connect

 Desc: connect() method for InsertDBH is deprecated, do not use it in new code
       use new();

=cut

sub connect {
    carp "connect() method for InsertDBH is deprecated, do not use it in new code";
    return __PACKAGE__->new(@_);
}

=head2 new_no_connect

  Desc: Create a new Connection object without connect with the database,
        but with all the db parameters
        dbuser and dbpass will be overwritten by prompt

  Args: optional parameters hash ref as
        ({  dbname   => name of the database; defaults to 'cxgn'; unused for MySQL
            dbschema => name of schema you want to connect to; defaults to 'sgn'
            dbtype   => type of database - 'Pg' or 'mysql'; defaults to 'Pg'
            dbargs   => DBI connection params, merged with the default
            dbhost   => host to connect to, default 'db.sgn.cornell.edu',
            dbbranch => the database "branch" to use, default 'devel' unless 
                        you are configured as a production website, in which 
                        case it would default to 'production'
         })
        all parameters in the hash are optional as well

  Ret: new CXGN::DB::Connection object without connection

  Side Effects: sets up the internal state of the CXGN::DB::Connection object

  Example:
     my $dbh = CXGN::DB::InsertDBH->new_no_connect();

  Note: See CXGN::DB::Connection for more information

=cut

sub new_no_connect {
    my $class = shift;
    my $dbargs = $class->_dbargs(@_);
    return  CXGN::DB::Connection->new_no_connect($dbargs); # returns a dbh
}

=head2 new

  Desc: Connects to the database and returns a new Connection object
        dbuser and dbpass will be overwritten by prompt

  Args: optional parameters hash ref as
        ({  dbname   => name of the database; defaults to 'cxgn'; unused for MySQL
            dbschema => name of schema you want to connect to; defaults to 'sgn'
            dbtype   => type of database - 'Pg' or 'mysql'; defaults to 'Pg'
            dbargs   => DBI connection params, merged with the default
            dbhost   => host to connect to, default 'db.sgn.cornell.edu',
            dbbranch => the database "branch" to use, default 'devel' unless 
                        you are configured as a production website, in which 
                        case it would default to 'production'
         })
        all parameters in the hash are optional as well

  Ret: new CXGN::DB::Connection object

  Side Effects: sets up the internal state of the CXGN::DB::Connection object

  Example:
     my $dbh = CXGN::DB::InsertDBH->new();

  Note: See CXGN::DB::Connection for more information

=cut

sub new {
    my $class = shift;
    my $dbargs = $class->_dbargs(@_);
    return  CXGN::DB::Connection->new($dbargs); # returns a dbh
}

=head2

 Desc: Print a message to get an answer and based in this answer
       (yes/not) commit or rollback

 Args: $dbh, a database connection object
       $prompt_message, a message to print in the screen
       $yes_regexp and $no_regexp, regexp to match the answer yes and not
       $sten_message, if the answer is not yes/not print something

 Ret: None

 Side_Effects: Die if something is wrong

 Example: commit_prompt($dbh);
 
  

=cut

sub commit_prompt {
  my ($dbh, $prompt_message, $yes_regexp, $no_regexp, $stern_message) = @_;
  unless ($prompt_message) {
    $prompt_message = "Commit?\n(yes|no, default no)> ";
    $yes_regexp = "^y(es)\$"; #"
    $no_regexp = "^n(o)\$"; #"
    $stern_message = "Please enter \"yes\" or \"no\"";
  }
  if (-t *STDIN) {
    print $prompt_message;
    while (<STDIN>) {
      if ($_ =~ m|$yes_regexp|i) {
	print "Committing...";
	$dbh->commit;
	print "okay.\n";
	last;
      } elsif ($_ =~ m|$no_regexp|i) {
	print "Rolling back...";
	$dbh->rollback;
	print "done.\n";
	last;
      } else {
	print "$stern_message\n";
      }
    }
  } else {
    die ("commit_prompt called when STDIN isn't a tty.  That shouldn't happen.\n");
  }
}

###
1 #
###
