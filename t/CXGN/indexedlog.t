#!/usr/bin/perl
use strict;
#use warnings;
use English;
use FindBin;

use File::Spec;
use File::Copy;
use File::Temp qw/tempfile/;

use Test::More tests => 31;

BEGIN {
  use_ok(  'CXGN::IndexedLog'  );
}

########### File backend

{
  my $testlog_name = File::Spec->catfile($FindBin::Bin,'data','indexedlog.testlog.1');
  my (undef,$tempfile) = tempfile(UNLINK=>1);
  copy($testlog_name,$tempfile) or die "Could not copy $testlog_name to '$tempfile': $!";

  #open a test log file
  my $log = CXGN::IndexedLog->open(File => $tempfile);
  isa_ok($log,'CXGN::IndexedLog');

  $log->append(qw/monkey in the middle/);
  $log->append(qw/this is yet another test log message/);
  ok(`tail -1 $tempfile | grep 'yet another test log message'`,'append probably works')
    or diag "Logfile contents are:\n",`cat $tempfile`;

  ok( $log->is_writable, 'this file-based log should be writable' );
  chmod 0, $tempfile;
  ok( ! $log->is_writable, 'and now file-based log should not be writable' );
  chmod 0600, $tempfile;
  ok( $log->is_writable, 'and now it should be again' );

  #diag `cat $tempfile`;

  #test lookup on both the existing handle and a new handle
  foreach my $log2 ($log, CXGN::IndexedLog->open(File => $tempfile)) {
    my %logrecord = $log2->lookup(content => 'monkey in');
    my ($hostname) = `hostname -s`;
    my $username = getpwuid($UID);
    chomp $hostname;
    is($logrecord{host},$hostname,'lookup gets correct hostname');
    is($logrecord{user},$username,'lookup gets correct username');
    is($logrecord{progname},$FindBin::Script,'lookup gets correct program name');
    is($logrecord{pid},$PID,'lookup gets correct PID');
    is($logrecord{content},'monkey in the middle','lookup gets correct content');

  }
}


############ DB backend

SKIP: {
  skip ', set IDXL_DB_TEST=1 to test IndexedLog DB backend', 15 unless $ENV{IDXL_DB_TEST};

  require CXGN::DB::Connection;
  my $dbh = CXGN::DB::Connection->new;
  #open a test log db.  this will probably 
  my $log = CXGN::IndexedLog->open('DB', $dbh, 'cxgn_indexedlog_test_feel_free_to_delete_me');
  isa_ok($log,'CXGN::IndexedLog');
  ok( $log->is_writable, 'db table should be writable' );

  $log->append(qw/monkey in the middle/);
  $log->append(qw/this is yet another test log message/);

  #test lookup on both the existing handle and a new handle
  foreach my $log2 ($log, CXGN::IndexedLog->open('DB', $dbh, 'cxgn_indexedlog_test_feel_free_to_delete_me')) {
    my %logrecord = $log2->lookup(content => 'monkey in');
    my ($hostname) = `hostname -s`;
    my $username = getpwuid($UID);
    chomp $hostname;
    is($logrecord{host},$hostname,'lookup gets correct hostname');
    is($logrecord{user},$username,'lookup gets correct username');
    is($logrecord{progname},$FindBin::Script,'lookup gets correct program name');
    is($logrecord{pid},$PID,'lookup gets correct PID');
    is($logrecord{content},'monkey in the middle','lookup gets correct content');

    ok( $log2->is_writable, 'db table should be writable' );
  }

  #test reset
  $log->reset;
  is($log->lookup(content => 'monkey in'),undef,'reset deletes everything');


  $dbh->disconnect;
};

