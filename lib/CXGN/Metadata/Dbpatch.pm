=head1 NAME

CXGN::Metadata::Dbpatch

=head1 SYNOPSIS

my $dbpatch = CXGN::Metadata::Dbpatch->new()

=head1 DESCRIPTION

This should be a parent class of all cxgn db patches.
This class takes care of storing a new Metadata and Dbversion objects,
which help us keep track of running db patches on the database.

  Options:
    -D <dbname> (mandatory)
    dbname to load into

    -H <dbhost> (mandatory)
    dbhost to load into

    -u <script_executor_user> (mandatory)
    username to run the script

    -F force to run this script and don't stop it by
    missing previous db_patches

    -t test run. Rollback the transaction.

  Note: If the first time that you run this script, obviously
    you have no previous dbversion row in the md_dbversion
    table, so you need to force the execution of this script
    using -F


This class has to be sub-classed by a dbpatch script.  The subclass
script has to be named exactly the same as the package name

=head2 Example MyDbpatch.pm

  package MyDbpatch;

  use Moose;
  extends 'CXGN::Metadata::Dbpatch';


  #now override init_patch() and patch()
   sub init_patch  {
      my $self=shift;
      # You can name your patch any way you want,
      # but it is easiest just to name it with the package name:
      #
      my $name=__PACKAGE__;
      my $description = 'my dbpatch description';
      my @prev_patches = (); # list any prerequisites of other patches

      # now set the  above 3 params
      $self->name($name);
      $self->description($description);
      $self->prereq(\@prev_patches);
  }


  sub patch {
      my $self=shift;
      ### Now you can insert the data using different options:

      ##  1- By sql queryes using $dbh->do(<<EOSQL); and detailing in the tag the queries
      ##
      ##  2- Using objects with the store function
      ##
      ##  3- Using DBIx::Class first level objects
      ##
  }

  1;


Now you can run the db patch from the command line like this:

mx-run MyDbpatch -H dbhost -D dbname -u username

=head1 AUTHORS

 Naama Menda<nm249@cornell.edu>
 Lukas Mueller<lam87@cornell.edu>
 Aureliano Bombarely<ab782@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut


package CXGN::Metadata::Dbpatch;

use strict;
use warnings;

use CXGN::DB::InsertDBH;
use CXGN::Metadata::Schema;
use CXGN::Metadata::Dbversion;
use Moose;

with 'MooseX::Getopt';
with 'MooseX::Runnable';

has "md_schema" => (
    is       => 'rw',
    isa      => 'Ref',
    required => 0,
    traits   => ['NoGetopt'],
);

has "dbh" => (
    is       => 'rw',
    isa      => 'Ref',
    traits   => ['NoGetopt'],
    required => 0,
);

has "dbhost" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    cmd_aliases   => 'H',
    documentation => 'required, database host',
);

has "dbname" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    documentation => 'required, database name',
    cmd_aliases   => 'D',
);

has "dbuser" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    traits        => ['Getopt'],
    documentation => 'not required (prompted), database user name',
    cmd_aliases   => 'U',
    );

has "dbpass" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    traits        => ['Getopt'],
    documentation => 'not required (prompted), database password',
    cmd_aliases   => 'P',
    );

has "name" => (
    is       => 'rw',
    isa      => 'Str',
    traits   => ['NoGetopt'],
    default  => sub { ref shift },
);

has "description" => (
    is       => 'rw',
    isa      => 'Str',
    default  => '(no description)',
    traits   => ['NoGetopt'],
);

has "username" => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    traits        => ['Getopt'],
    documentation => 'required, your SGN site login name',
    cmd_aliases   => 'u'
);

has "prereq" => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 0,
    traits   => ['NoGetopt'],
    default  => sub { [] }

);

has 'force' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 0,
    default     => 0,
    traits      => ['Getopt'],
    cmd_aliases => 'F',
    documentation =>
      'force apply, ignoring prereqs and possible duplicate application',
);

has 'trial' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 0,
    default     => 0,
    traits      => ['Getopt'],
    cmd_aliases => 't',
    documentation =>
      'Test run. Rollback the transaction.',
);

sub run {
    my $self = shift;

    ##override this in the parent class
    $self->init_patch;
    ###

    my $cxgn_db_connection =  CXGN::DB::InsertDBH->new(
	{
	    dbname =>$self->dbname,
	    dbhost => $self->dbhost,
	});


    $self->dbpass($cxgn_db_connection->dbpass());
    $self->dbuser($cxgn_db_connection->dbuser());

    my $dbh = $cxgn_db_connection->get_actual_dbh();

    $dbh->{AutoCommit} = 1;

    $self->dbh($dbh);

    my $metadata_schema = CXGN::Metadata::Schema->connect(
	sub { $dbh->clone() },
	{ on_connect_do => ['SET search_path TO metadata;'] },
	);
    $self->md_schema($metadata_schema);
    ### Now it will check if you have runned this patch or the previous patches

    my $dbversion = CXGN::Metadata::Dbversion->new($metadata_schema)
	->complete_checking( {
	    patch_name  => $self->name,
	    patch_descr => $self->description,
	    prepatch => $self->prereq,
	    force => $self->force
			     }
	);


    #CREATE A METADATA OBJECT and a new metadata_id in the database for this data

    my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $self->username);

    #Get a new metadata_id (if you are using store function you only need to supply $metadbdata object)

    #override this in the sub-class
    my $error = $self->patch;
    if ($error ne '1') {
	print "Failed! Rolling back! \n $error \n ";
	exit();
    } elsif ( $self->trial) {
        print "Trial mode! Not storing new metadata and dbversion rows\n";
    } else {
        $metadata->get_dbh->do('set search_path to metadata');
        my $metadata_id = $metadata->store()->get_metadata_id();
        $dbversion->store($metadata);
    }
}

sub init_patch {
    my $self = shift;
    print  "Patch name:\n  " .   $self->name . ".\n\nDescription:\n  ".  $self->description . "\nExecuted by:\n  " .  $self->username . "\n\n";

}

has 'sql' => ( is => 'ro', isa => 'Str' );
sub patch {
    my $self = shift;
    local $self->dbh->{AutoCommit} = 0;
    $self->dbh->do( $self->sql );
    print "Done.\n";
}

###
1;#
###
