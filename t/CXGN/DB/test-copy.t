#!/usr/bin/perl

use strict;
use CXGN::DB::Connection;
use CXGN::DB::Copy;
{
  my $dbh = CXGN::DB::Connection->new({dbname=>"sandbox",
				       dbhost=>"scopolamine",
				       dbschema=>"sgn"});
  $dbh->copy (
	      fromtable => "fish_result",
	      tofile    => \*STDOUT
	     );
  $dbh->copy (
	      fromtable => "fish_result",
	      tofile    => "/tmp/fish_result.txt"
	     );
  system "cat /tmp/fish_result.txt; rm /tmp/fish_result.txt";
}


{
  my $dbh = CXGN::DB::Connection->new({dbname=>"sandbox",
				       dbhost=>"scopolamine",
				       dbschema=>"sgn"});
  $dbh->do("create temporary table passwd (name text, passwd text, uid text, gid text,
            gecos text, homedir text, shell text)");
  $dbh->copy (
	      totable => "passwd",
	      fromfile    => "/etc/passwd",
	      delimiter => ":",
	      null => "",
	      # Upcase the username on the way into the database.
	      munge => sub { return (uc(shift), @_); }
	     );
  $dbh->copy (
	      fromtable => "passwd",
	      tofile => \*STDOUT,
	      # Print everyting except the uid as in the table; take
	      # the sqrt of the uid.
	      munge => sub { return (shift,shift,sqrt(shift), @_); }
	     );
  $dbh->copy (
	      fromtable => "passwd",
	      tofile => \*STDOUT,
	      delimiter => "",
	      null => "",
	     );
}
