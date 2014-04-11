# Generic CXGN subclass of Class::DBI.
# This is basically a superclass to contain the database handle.
package CXGN::CDBI::Class::DBI;
use strict;
use English;
use Carp;
#use CXGN::Config;
use CXGN::DB::Connection;
use base qw/Class::DBI Class::Data::Inheritable/;
use Data::Dumper;

__PACKAGE__->mk_classdata('cxgn_db_connection');
__PACKAGE__->mk_classdata('cxgn_nonconnected_db_connection');
__PACKAGE__->mk_classdata('cxgn_db_connection_args' => undef );
__PACKAGE__->mk_classdata('cxgn_db_owner_pid' => $PID);

sub db_Main {
  my $class = shift;

  #make a new cxgn_db_connection if we don't have one
  unless( $class->cxgn_db_connection
	  && $class->cxgn_db_owner_pid == $PID
	  && $class->cxgn_ping()
	) {
    #    warn "$class!\n";
    __PACKAGE__->_make_args unless $class->cxgn_db_connection_args;
    if ( $class->cxgn_db_connection && ! ($class->cxgn_db_owner_pid == $PID) ) {
      #set inactivedestroy on the old handle if we're a child process and need to reconnect
      $class->cxgn_db_connection->dbh_param(InactiveDestroy => 1);
    }
    #make a new connection and remember that we are its owner
    __PACKAGE__->cxgn_db_connection( CXGN::DB::Connection->new( $class->cxgn_db_connection_args ) );
    __PACKAGE__->cxgn_db_owner_pid($PID);
  }
  return $class->cxgn_db_connection;
}

#ping at most every 30 seconds
sub cxgn_ping {
  my ($class) = @_;
  our $lastping ||= time;
  if(time - $lastping > 30) {
    $lastping = time;
    return $class->cxgn_db_connection->ping;
  } else {
    return 1;
  }
}

#this method lets us 'use' this module and give it arguments
sub import {
  shift->_make_args(@_);
}

#take some CXGN::DB::Connection args, merge them into the defaults
#from Class::DBI, then store them in this objects
#later, they will be given to CXGN::DB::Connection, which will
#merge them with other stuff internally
sub _make_args {
  my $class = shift;

  return if $class->cxgn_db_connection;

  #get any argument attributes

  #my %attrs = $class->_default_attributes;  #produces an error

  #### the above statement produces an error (many times),
  #### probably because a the function _default_attributes requires a connection.
  #### so we need the default attributes to make a connection but can't get the attributes without a connection
  #### a chicken or the egg sort of problem
  #### thus setting the attributes directly here
  my %attrs;
  %attrs=(
	  FetchHashKeyName => 'NAME_lc',
    	  RaiseError => 1,
    	  AutoCommit => 1,
    	  PrintError => 0,
   	  ShowErrorStatement => 1,
    	  Taint      => 1,
   	  ChopBlanks => 1,
    	  RootClass  => "DBIx::ContextualFetch"
    	 );
  #print Dumper(%attrs); #this is where the above attrs were obtained


  #### EDIT THE ATTRIBUTES THAT WE SET ON CLASS::DBI OBJECTS HERE ####
  delete( $attrs{AutoCommit} ); #we will ignore whatever Class::DBI think we should do for AutoCommit

  if(@_) {
    ref($_[0]) eq 'HASH'
      or croak "Can only pass a hash ref as argument to use()\n";
    #merge in the requested dbargs
    if( $_[0]->{dbargs} ) {
      while( my( $key,$val ) = each %{$_[0]->{dbargs}} ) {
	$attrs{$key} = $val;
      }
    }
  }
  $_[0]->{dbargs} = \%attrs;
  #$_[0]->{config} = CXGN::Config->load;

  __PACKAGE__->cxgn_db_connection_args( $_[0] );
}

=head2 search_ilike

  Desc : just like L<Class::DBI> search_like, except using
         postgres's ILIKE

=cut

sub search_ilike {
  shift->_do_search(ILIKE => @_)
}


=head2 qualify_schema

  Usage: my $schemaname = __PACKAGE__->qualify_schema('sgn');
  Desc : wrapper for CXGN::DB::Connection::qualify_schema() that
         keeps a cached no_connect DB handle for schema qualifying
         purposes.  Mostly implemented so you don't have to connect
         to the DB just to compile your scripts.
  Ret  : a qualified schema name
  Args : a non-qualified schema name
  Side Effects: might make a non-connected L<CXGN::DB::Connection>

=cut

sub qualify_schema {
    my ($class,$schema) = @_;

    return $schema;
}

sub base_schema {
    my ($class, $schema) = @_;
    return $schema;
}

###
1;#do not remove
###


=head1 NAME

  CXGN::CDBI::Class::DBI - CXGN-wide parent class for all Class::DBI-based objects

=head1 DESCRIPTION

Common superclass to be used by all Class::DBI objects in CXGN.  Uses
L<CXGN::DB::Connection> to set up the database connection parameters for all
our objects.

=head1 BASE CLASSES

L<Class::DBI>, L<Class::Data::Inheritable>

=head1 AUTHORS

Mostly Marty, modified a bit by Rob.

=cut
