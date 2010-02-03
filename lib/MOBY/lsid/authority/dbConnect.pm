#$Id: dbConnect.pm,v 1.2 2004/01/15 21:15:01 mwilkinson Exp $
package MOBY::lsid::authority::dbConnect;

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    dbConnect
    );
%EXPORT_TAGS =(all => [qw(
    dbConnect
    )]);


sub dbConnect {
	use DBI;
	use DBD::mysql;
	my ($db) = @_;
	my $pass = $db->{pass};
	my $user = $db->{user};
	my $host = $db->{host};
	my $dbname = $db->{dbname};
	my $port = $db->{port};
	my ($dsn) = "DBI:mysql:$dbname:$host:$port";
	my $dbh = DBI->connect($dsn, $user, $pass, {RaiseError => 1}) or die "can't connect to database";
	
	return ($dbh);
}

1;