package CXGN::DB::Object;

=head1 NAME

CXGN::DB::Object - a parent class for all objects needing a database handle accessor
 
=head1 DESCRIPTION

This is an "abstract class", meaning that this class is not intended to be used by itself, but rather it should be sub-classed. 

For example, a class using CXGN::DB::Object should declare:

 package CXGN::SomeObject;
 
 sub new { 
   my $class = shift;
   my $dbh = shift;
   return $self = $class->SUPER::new($dbh);
 }

Note that it is assumed that these database objects are always fed with a $dbh from somewhere outside the class, which allows better control on the number of open database connections. These $dbh should preferably be created with L<CXGN::DB::Connection>, which respects server configurations and accesses the correct database according to configuration settings.

When working with DBIx::Class (recommended) this class can be used as a parent class and provides the accessors get_schema() and set_schema() to work with schema objects.


=head2 Debugging

CXGN::DB::Object inherits from L<CXGN::Debug>, which should be used for all debugging messages. Use $self->d('debug message here\n');

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

use Carp qw/cluck/;
use CXGN::Debug;

use base qw /CXGN::Debug /;

=head2 function new

  Synopsis:	my $o = CXGN::DB::Object->new($dbh)
  Arguments:	a database handle or a DBIx::Class schema object
  Returns:	a CXGN::DB::Object
  Side effects:	if a dbh was supplied, calls set_dbh; if a schema
                is supplied, calls set_schema and sets the dbh
                to the $schema->storage()->dbh().

=cut

sub new {
    my $class = shift;
    my $param = shift;

    my $self = $class->SUPER::new();
    if ( ref($param) ) {
        if ( $param->can('prepare') && $param->can('selectall_arrayref') )
        {    # it's a DBI handle of some sort
            $self->d("Received a dbh and setting the dbh...\n");
            $self->set_dbh($param);
        }
        elsif ( $param->isa("DBIx::Class::Schema") ) {
            $self->set_schema($param);
            $self->set_dbh( $param->storage->dbh );
            $self->d("Received a Schema class and setting the schema...\n");
        }
        else {
            cluck
"WARNING! Need either a dbh or a schema in CXGN::DB::Object constructor (got $param)";
        }
    }
    else {
        cluck "A parameter is required in CXGN::DB::Object constructor";

    }
    return $self;
}

=head2 accessors set_dbh, get_dbh

  Property:     my $dbh = $dbobj->get_dbh()
  Description:  gets/sets the database handle of this
                object. The setter is called in the constructor,
                using the database handle supplied as a parameter.

=cut

sub get_dbh {
    my $self = shift;
    return $self->{dbh};
}

sub set_dbh {
    my $self = shift;
    $self->{dbh} = shift;
}

=head2 accessors get_schema, set_schema

 Usage:        my $s = $dbobj->get_schema()
 Desc:         gets a schema object. Useful when implementing
               DBIx::Class based modules: one can still inherit
               from CXGN::DB::Object and store the schema in this
               property.

=cut

sub get_schema {
    my $self = shift;
    return $self->{schema};
}

sub set_schema {
    my $self = shift;
    $self->{schema} = shift;
}

=head2 function get_currval

  Synopsis:	$currval = $dbobj->get_currval($my_table_id_seq);
  Arguments:	returns the current value of the sequence $my_table_id_seq
                useful when a row was inserted (returns the new value of 
                the sequence.
  Returns:	and int.

=cut

sub get_currval {
    my $self        = shift;
    my $serial_name = shift;
    my $sth         = $self->get_dbh()->prepare("SELECT CURRVAL(?)");
    $sth->execute($serial_name);
    my ($currval) = $sth->fetchrow_array();
    return $currval;
}

1;
