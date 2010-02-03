
use strict;
use Getopt::Std;
use CXGN::DB::InsertDBH;
use CXGN::SNP;

our ($opt_H, $opt_D);

getopts('H:D:');

my $dbh = CXGN::DB::InsertDBH->new( { dbname=>$opt_D,
				       dbhost=>$opt_H,
				       dbuser=>"postgres"});

print STDERR "Creating SNP schemas... ";
CXGN::SNP->create_schema($dbh);

print STDERR "Done.\n";



