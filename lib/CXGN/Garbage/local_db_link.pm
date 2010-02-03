package CXGN::Garbage::local_db_link;

use lib '/usr/lib/perl5/site_perl/5.6.0/i386-linux/';

# Global packages to use
use DBI;
use DBD::mysql ();

my %hosts = ('siren' => {'user' => 'web_usr', 'password' => 'tomato', 'db' => 'Physical2'},
	     'amatxu' => {'user' => 'koni', 'password' => 'bitchbadass', 'db' => 'physical'});

sub auto_configure_settings () {

    my $hostname = 'siren';
    if ($hosts{$hostname}) {
	return $hosts{$hostname};
    } else {
	die "local_db_link ERROR: Auto-configuration information not known for host $hostname.\n";
    }

}


sub connect_db {

    my ($hashref) = @_;
    $hashref ||= &auto_configure_settings() ;
    my %settings = %$hashref;
    if (not defined $settings{'db'}) {$settings{'db'} = 'test';}
    if (defined $settings{'host'}) {
	$settings{'db'} .= ";host=" . $settings{'host'} . ".sgn.cornell.edu";
    }
    if (not defined $settings{'user'}) {$settings{'user'} = 'dbmngr';}
    if (not defined $settings{'password'}) {$settings{'password'} = '';}
    # try to open the database
    my ($dsn, $usr, $pwd) = ("dbi:mysql:$settings{'db'}", 'insert', 'fuckmeharder');

    my $dbh = DBI->connect($dsn, $usr, $pwd, { RaiseError => 1})
	|| die "Can't connect to $dsn: $DBI::erstr";

    # Set larger max buffer size just because Koni does it.
    my $newsize = 20480;
    ($rc = $dbh->{LongReadLen} = $newsize)
	|| die "Error setting LongReadLen to $newsize: $DBI::errstr";

    return $dbh;

}


sub disconnect_db {

    my ($dbh) = @_;
    $rc = $dbh->disconnect || warn DBI::errstr;

}

return 1;
