package Chado::LoadDBI;

use strict;
use lib '/lib';
use Chado::AutoDBI;

sub init
{
  Chado::DBI->set_db('Main',
    "dbi:Pg:dbname=fake_chado_db_name;port=fake_chado_db_port;host=fake_chado_db_host", 
    "fake_chado_db_username",
    "fake_chado_db_password",
    {
      AutoCommit => 0
    }
  );
}

1;
