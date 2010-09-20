
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
    
  Note: If the first time that you run this script, obviously
    you have no previous dbversion row in the md_dbversion
    table, so you need to force the execution of this script 
    using -F
    

This class has to be sub-classed by a dbpatch script.
    The subclass script has to be named exactly the same as the package name
    
    example: MyDbpatch.pm

    package MyDbpatch;

use Moose;
extends 'CXGN::Metadata::Dbpatch';


#now override init_patch() and patch()
 sub init_patch  {
    my $self=shift;
    #your patch name has to be in the following format:
    #number_name
    my $name='00001_my_dbpatch_name;
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


has "md_schema" => ( is=>'rw',
		     isa=>'CXGN::Metadata::Schema',
		     required=>0,
    );

has "dbh" => ( is => 'rw',
	       isa => 'Ref',
	       required => 0,
    );

has "dbhost" => ( is => 'rw',
		  isa => 'Str',
		  required => 1,
		  traits => ['Getopt'], 
		  cmd_aliases => 'H'
    );

has "dbname" => ( is => 'rw',
		  isa => 'Str',
		  required => 1,
		  traits => ['Getopt'], 
		  cmd_aliases => 'D',
    );


has "name" => ( is => 'rw',
		isa => 'Str',
		required => 0,
    );


has "description" => (is=>'rw',
		      isa=>'Str',
		      required=>0,
    );

has "username" => (is=>'rw',
		   isa=>'Str',
		   required=>1,
		   traits=> ['Getopt'], 
		   cmd_aliases => 'u'
    );

has "prereq" => (is => 'rw',
		 isa => 'ArrayRef',
		 required => 0,
		 default => sub { [] }
		 
    );

has 'force' => (is=>'rw',
		isa=>'Bool',
		required=>0,
		default=>0,
		traits => ['Getopt'],
		cmd_aliases => 'F'
    );

sub run {
    my $self = shift;
    
    ##override this in the parent class
    $self->init_patch;
    ###
    
    my $dbh =  CXGN::DB::InsertDBH->new(
	{ 
	    dbname =>$self->dbname, 
	    dbhost => $self->dbhost, 
	}
	)->get_actual_dbh();
    
    $self->dbh($dbh);
    
    print STDOUT "\nCreating the Metadata Schema object.\n";
    
    my $metadata_schema = CXGN::Metadata::Schema->connect(   
	sub { $dbh },
	{ on_connect_do => ['SET search_path TO metadata;'] },
	);
    
    ### Now it will check if you have runned this patch or the previous patches
    
    my $dbversion = CXGN::Metadata::Dbversion->new($metadata_schema)
	->complete_checking( { 
	    patch_name  => $self->name,
	    patch_descr => $self->description, 
	    prepatch_req => $self->prereq,
	    force => $self->force 
			     } 
	);
    
    
    #CREATE A METADATA OBJECT and a new metadata_id in the database for this data
    
    my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema, $self->username);
    
    #Get a new metadata_id (if you are using store function you only need to supply $metadbdata object)
    
    my $metadata_id = $metadata->store()->get_metadata_id();
    
    #override this in the sub-class
    $self->patch;
    ##
    
    $dbversion->store($metadata);
    
    print STDOUT "DONE!\n";
    
    $dbh->commit;
    
}



sub init_patch {
    my $self=shift;
    warn "You have to override init_patch in your sub-class!";
    
}

sub patch {
    my $self=shift;
    warn "You have to override patch in your sub-class!";
}
 
###
1;#
###
