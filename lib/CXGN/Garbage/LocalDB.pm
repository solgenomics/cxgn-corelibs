#!/usr/bin/perl
use strict;
use DBI;
# and Term::ReadKey, included below

###############################################
###           DOCUMENTATION ALERT           ###
# 
# This module has POD! In this directory, 
# or having this directory in your PERLLIB,
# just do: 
#
#    perldoc LocalDB
#
# and you will get a manpage with description,
# synopses, function usage, etc.
#
###        END OF DOCUMENTATION ALERT       ###
###############################################


package LocalDB;


sub connect {
    # connects to the sgn db. Optionally takes a different db name
    # as an argument. 
    # usage: my $dbh = basic_db::connect();
    #        my $dbh = basic_db::connect('physical');

    my $dbname = shift || 'sgn';    
    return
	DBI->connect("dbi:mysql:host=localhost;database=$dbname",
		     'web_usr',
		     'tomato',
		     { RaiseError => 1 })
  }




sub connect_write {
    # connects to the sgn db. Optionally takes a different db name
    # as an argument. 
    # usage: my $dbh = basic_db::connect_write();
    #        my $dbh = basic_db::connect_write('physical');

##############################################
# write access uses the user 'insert' and a
# password to be specified on the command line.

  print 'Password for write access: ';
  use Term::ReadKey;
  ReadMode 'noecho';
  my $pass = ReadLine(0);
  ReadMode 'normal';
  chomp $pass;
  print "\n"; #newline to let the user know the password was entered

# done with password
###############################################

  my $dbname = shift || 'sgn';    

  return
    DBI->connect("dbi:mysql:host=localhost;database=$dbname",
		 'insert',
		 $pass,
		 { RaiseError => 1 })
  }



=head1 NAME

LocalDB - provides connect functions for your local databases.

=head1 SYNOPSIS

   use LocalDB;

   # connect with read-only access
   my $dbh = LocalDB::connect();           # assumes the sgn db
   my $dbh = LocalDB::connect('physical'); # connect to physical db

   # connect with write access, for loading scripts
   my $dbh = LocalDB::connect_write('physical'); 

=head1 DESCRIPTION

LocalDB provides connection functions for your local database. The goal is
to provide one connection function that will work on all machines, from 
amatxu and zamolxis to your personal laptop. 

=head2 Database setup

Create a read-only account (it must at least have C<SELECT> privileges; 
we recommend you not grant it anything else) with username I<web_usr> 
and password I<tomato>. 

Additionally, create an account with all privileges with the username 
I<insert> and a password of your choosing. B<This password must be entered
at a prompt when the script is run>. 

=head2 Functions

=over 5

=item C<connect($db_name)>

Connects with read access to the I<sgn> database. The optional argument
C<$db_name> indicates a different database to connect to (for example, 
I<physical> or I<sol_people>). 

=item C<connect_write($db_name)>

Identical to C<connect($db_name)> except it uses the I<insert> user, 
who should have write access; the assumption is that this user has
C<ALL> privileges.

=back

=head1 BUGS

what bugs?

=head1 ACKNOWLEDGEMENTS

all you guys <3

=head1 LICENSE

same as everything else here, whatever that is

=head1 AVAILABILITY

the sgn-tools cvs module

=head1 AUTHOR

Beth Skwarecki

=head1 SEE ALSO

DBI, the mysql manual, read the source, rtfm, etc.

=cut



##
1;
##


