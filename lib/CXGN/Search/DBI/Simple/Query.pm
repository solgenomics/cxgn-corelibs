package CXGN::Search::DBI::Simple::Query;

use strict;
use DBI qw/ looks_like_number /;
use Carp;
use Storable qw/dclone/;

use CXGN::Tools::List qw/all distinct/;

use base qw/ CXGN::Search::QueryI  Class::Data::Inheritable /;
#Class::Data::Inheritable is used to keep data about this class (rather than individual objects)
#we use this to provide a procedural interface for defining parameters, join paths, etc.

use vars '$AUTOLOAD';

use CXGN::Tools::Class qw/parricide/;

use Class::MethodMaker
  [new      => [qw/ -init new /],
   scalar   => [qw/ page
		    page_size
		    natural_joins
		    debug
	        /],
   hash     => [qw/ param /],
  ];

=head1 NAME

CXGN::Query::DBI::Simple - abstract class that encapsulates a set of query
conditions for a DBI database search.

=head1 DESCRIPTION

CXGN::Query::DBI::Simple is an implementation of the search framework query
that encapsulates a query to a database accessed via the L<DBI>.  Basically,
to implement a new query one defines a set of I<query parameters> which will
be accessible to users of the class, what columns and tables these parameters use,
and how the tables are to be joined together.

Usage synopsis (from a user's point of view) is given in L<CXGN::Search>.

A developer tutorial for using this object, along with its Search and Result companion
objects, is given in L<CXGN::Search::DBI::Simple>.


=head1 SYNOPSIS

coming soon

=head1 BASE CLASSES

L<CXGN::Search::QueryI>
L<Class::Data::Inheritable> (for storing class data)

=head1 SUBCLASSES

L<CXGN::Search::Query::DBI::CDBI>

=head1 DEFINING QUERY PARAMETERS

Use these class methods to specify your query's parameters, and the fields
they use in the database.  Also, you need to specify how all of the tables
are joined together.

=head2 has_parameter

  CLASS METHOD

  Desc: define a parameter used by this type of query
  Args: hash-style list as:
   name      => the name of the parameter you're making
   columns   => string containing a single column name,
                or an array ref of column names if multiple.
                Column names must be fully qualified.
   sqlexpr   => (required for multiple columns, optional for single)
                the SQL expression that gives the value used for comparison
                in searches
   group     => (optional) true if the columns used by this parameter are
                from tables with many rows for each row in the returned data
   aggregate => (optional) true if the value used in comparisons for this parameter
                involves an SQL aggregate function (count(), sum(), etc).
                If true, this causes this parameter to be compared in a HAVING
                clause instead of a WHERE clause in the generated SQL.
   composite => (optional) subroutine ref to run when setting this parameter
  Ret : always true
  Side Effects: defined a parameter inside the class data of this object
  Example:

    use base qw/CXGN::Search::Query::DBI::Simple/;
    __PACKAGE__->has_parameter( name     => 'length',
                                columns  => 'genomic.qc_report.hqi_length',
                              );
    __PACKAGE__->has_parameter( name     => 'cornell_clone_name',
                                columns  => [ 'genomic.clone.platenum',
                                              'genomic.clone.wellrow',
                                              'genomic.clone.wellcol',
                                            ],
                                sqlexpr   => "'P' || genomic.clone.platenum
                                              || genomic.clone.wellrow || genomic.clone.wellcol
                              );


=cut

sub has_parameter {
  my $class = shift;
  ref $class
    and croak "has_parameter is a class method, not an object method";

  #bind arguments
  my (%args) = @_;

  #warn for invalid argument names
  my %valid_keys = map {$_=>1} qw/name columns sqlexpr group aggregate/;
  $valid_keys{$_} || carp "unknown arg '$_'" foreach keys %args;

  #validate the arguments
  croak "Must give at least 'name' and 'columns' to has_parameter"
    unless $args{name} && $args{columns};
  if(my $reftype = ref($args{columns})) {
    croak "Columns must be an ARRAY ref, not a $reftype ref"
      unless $reftype eq 'ARRAY';
    croak "Dude, you can't pass an empty 'columns' list to has_parameter"
      if @{$args{columns}} == 0;
    croak "When specifying multiple columns, you must also provide 'sqlexpr' to show how to combine them"
      if @{$args{columns}} > 1 && ! $args{sqlexpr};
  }

  #create class param origins if necessary
  $class->can('_class_params')
    or $class->mk_classdata(_class_params => {}); #provided by Class::Data::Inheritable

#   #check if this parameter has already been defined
#   $class->_class_params->{$args{name}}
#     and croak "parameter '$args{name}' already defined\n";

  #create the new parameter
  $class->_class_params->{$args{name}} =
   {
    type => 'simple',
    ref( $args{columns} ) ? ( columns   => $args{columns}     )
                          : ( columns   => [ $args{columns} ] )
    ,
    $args{group}          ? ( group     => $args{group}       )
                          : ()
    ,
    $args{aggregate}      ? ( aggregate => $args{aggregate}   )
                          : ()
    ,
    sqlexpr   => _valexpr(\%args),
   };

#  warn "made parameter '$args{name}' via has_parameter: ",Dumper($class->_class_params->{$args{name}});

  return 1;
}


=head2 has_complex_parameter

  Usage: __PACKAGE__->has_complex_parameter( name => 'foo',
                                             uses => ['bar','baz'],
                                             setter => sub {
                                               my ($self,$expr,@bindvals) = @_;
                                               $self->bar($expr,@bindvals);
                                               $self->baz($expr,@bindvals);
                                             }
                                           );
  Desc : define a new complex parameter, which is a parameter
         that's defined in terms of other parameters
  Args : a hash-style list of:
          name => the name of this new complex parameter,
          uses => arrayref of the names of the other params it uses
          setter => a sub ref to an object method that sets the necessary
                    parameters in this object
  Ret  : always true
  Side Effects:
  Example:

=cut

sub has_complex_parameter {
  my ($class,%args) = @_;

  #validate arguments
  ref $class and croak 'has_complex_parameter is a class method, not an object method';
  UNIVERSAL::isa($class,__PACKAGE__)
      or croak '$class must be a subclass of '.__PACKAGE__;
  $args{$_} or croak "must provide a '$_'" foreach qw/name uses setter/;

  ref $args{uses}   eq 'ARRAY' or croak "'uses' must be an arrayref";
  ref $args{setter} eq 'CODE'  or croak "'setter' must be a subroutine ref";

  #create class params if necessary
  $class->can('_class_params')
    or $class->mk_classdata(_class_params => {}); #provided by Class::Data::Inheritable

  #create the new parameter
  $class->_class_params->{$args{name}} =
   {
    type => 'complex',
    map {$_ => $args{$_}} qw/uses setter/
   };

  return 1;
}


=head2 join_root

  Desc: set the root table of the join structure we use for the search
  Args: fully-qualified table name
  Ret : 1
  Side Effects: sets the join root for this class
  Example:

    use base qw/ CXGN::Search::Query::DBI::Simple /;

    __PACKAGE__->join_root('sgn.unigene');

=cut

sub join_root {
  my $class = shift;
  ref $class
    and croak "join_root is a class method, not an object method";

  my @tables = @_;

  #validate params
  @tables == 1 && all( map {!ref($_)} @tables )
    or croak 'invalid parameters to uses_joinpath';

  #create class data if necessary
  $class->can('_class_joinroot')
    or $class->mk_classdata('_class_joinroot'); #provided by Class::Data::Inheritable

#   #check if this parameter has already been defined
#   $class->_class_joinroot
#     and croak "join root already defined\n";

  #create the new join path
  $class->_class_joinroot($tables[0]);

  return 1;
}

=head2 uses_joinpath

  Desc: describe how to join tables together in your database
  Args: join path name,
        [table name, SQL expression for joining to root table],
        [table name, SQL expression for joining to previous table in path],
        [table name, SQL expression for joining to previous table in path],
        ...
  Ret : 1
  Side Effects:
  Example:

    use base qw/ CXGN::Search::Query::DBI::Simple /;

    __PACKAGE__->uses_joinpath(members,['sgn.unigene_members','sgn.unigene_members.unigene_id = sgn.unigene.unigene_id']);

=cut

sub uses_joinpath {
  my $class = shift;
  ref $class
    and croak "uses_joinpath is a class method, not an object method";

  my (@paths) = @_;

  shift @paths unless ref $paths[0]; #get rid of path name if given

  #validate params
  @paths >= 1 && all( map {@$_ == 2} @paths )
    or croak 'invalid parameters to uses_joinpath';

  #create class data if necessary
  $class->can('_class_joinstructure')
    or $class->mk_classdata(_class_joinstructure => []); #provided by Class::Data::Inheritable

#   #check if this parameter has already been defined
#   $class->_class_joinstructure->{$pathname}
#     and croak "join path '$pathname' already defined\n";

  #create the new join path
  push @{$class->_class_joinstructure},\@paths;

  return 1;
}

=head2 selects_data

  Desc: describe what data is returned from SQL queries
  Args: list of parameter names or fully-qualified column name, ...
  Ret : 1
  Side Effects: sets selected columns for this class
  Example:

    use base qw/ CXGN::Search::Query::DBI::Simple /;

    __PACKAGE__->selects_data('sgn.unigene.unigene_id','sgn.unigene.nr_members');

  Note:
     If you will be returning Class::DBI objects, you can use
     selects_class_dbi() below.

=cut

sub selects_data {
  my $class = shift;
  ref $class
    and croak "selects_columns is a class method, not an object method";

  my @columns = @_;

  #validate params
  @columns >= 1 && all( map { !ref } @columns ) && all( map {/.+\..+\..+/ || ! /\./} @columns)
    or croak 'invalid parameters to selects_columns';

  #create class data if necessary
  $class->can('_class_selects_data')
    or $class->mk_classdata('_class_selects_data'); #provided by Class::Data::Inheritable

#   #check if this parameter has already been defined
#   $class->_class_selects_columns
#     and croak "selects_columns has already been set\n";

  $class->_class_selects_data([ @columns ]);

  return 1;
}

=head2 selects_class_dbi

  Desc: sets selected data and join root for this class using the columns
        and table specified in the given Class::DBI class
  Args: Class::DBI package name
  Ret : 1
  Side Effects:
  Example:

    use base qw/ CXGN::Search::Query::DBI::Simple /;

    __PACKAGE__->selects_class_dbi('CXGN::CDBI::SGN::Unigene');

=cut

sub selects_class_dbi {
  my $class = shift;
  my $cdbi_class = shift;
  my $table = $cdbi_class->table;
  $class->selects_data(map {"$table.$_"} $cdbi_class->columns );
  $class->join_root($cdbi_class->table);
}

=head2 same_bindvals_as

  Usage: print 'yep' if $q->same_bindvals_as($q2);
  Desc : return true if the given query has the same set of
         bind values set for its parameters
  Args : another L<CXGN::Search::DBI::Simple::Query> object
  Ret  : true if they have the same bindvals, false otherwise

=cut

sub same_bindvals_as {
  my ($self,$other) = @_;

  return unless $self->param_count == $other->param_count;

  # check if they have the same data item names set
  my @keys = distinct $self->param_keys, $other->param_keys;

  return unless $self->param_count == scalar @keys;

  # now we know they have the same data item names,
  # check that they have the same data values
  return all map {
    $self->param_val($_)->[1] eq $other->param_val($_)->[1]
  } @keys;
}


=head1 RECOMMENDED OVERRIDABLE METHODS

If you're doing something a little more advanced, you can skip the
procedural interface for defining your tables and classes, and
override these methods instead, leaving you free to figure out the
parameters and join paths any way you want, dynamically or however.

=head2 param_def

  Args:  0 or more query parameter names
  Ret :  If 0 parameters,
           returns a reference to a hash of paramname => param definition

         If one parameter,
           returns the param origin for the given param name

         If more than one parameter,
           returns an array of (param origin, param origin, param origin)
           in the same order as the given query param names


     WHAT DO YOU MEAN BY 'PARAMETER ORIGIN'?
         For a Simple (deals with one column in one table) parameter,
           the origin is just a string containing the fully-qualified name of
           the corresponding column in the database (e.g. 'genomic.gss.gss_id')
         For a Complex (derived from multiple columns, possibly in multiple
           tables) parameter, the origin is a reference to a hash of the form
              { columns => [ column name, column name, ...],
                sqlexpr => 'sql expression involving those
                            fully-qualified column names',
                group   => 1 if there are many of these for each of the
                           return types if true, using this param will
                           make the resulting SQL have a GROUP BY clause
                aggregate => 1 if the seqlexpr for this command involves
                             an aggregate function (count(), avg(), and
                             the like).  if this is specified, the sql
                             condition for this parameter is put in the
                             query's HAVING clause

              }
           where columns is a list of (fully-qualified) column
           names that are needed to construct this search term, and
           sqlexpr is the SQL expression used to construct it from
           those columns.  If the columns don't contain all the
           cols used in the sqlexpr, your search will be broken.  If
           the columns contain more columns than are used in the
           SQL expression, your search may be inefficient and/or
           broken.
           I<Implementation note>: it's like this because in order to
                                   generate a properly JOINed query,
                                   we need to construct a list of all
                                   the columns we need

      NAMING CONVENTION: Name your parameters something that reflects
          what they are in relation to the return type object.  If the
          field(s) involved with your parameter are many per return row,
          you should probably make your parameter name plural for clarity.

          If you have a parameter that is only meant to be used as part of
          other parameters (probably methods you will write yourself), name
          it with a leading _underscore.

  Examples:
         param_def('foo') might return 'genomic.gss.foo', a
         fully-qualified column name.

         param_def('foo','bar','baz') might return
         ('genomic.gss.foo','genomic.clone.bar','genomic.gss.baz')

         param_def('myterm','foo') might return
         ( { columns => ['genomic.clone.bar','genomic.clone.baz'],
             sqlexpr    =>
               'concat(genomic.clone.bar,genomic.clone.baz)',
             type => 'simple',
           },
           { type => 'simple',
             columns => ['genomic.gss.foo'],
             sqlexpr =
         )

=cut

sub param_def {
  my $this = shift;

  my $class = ref($this);
#  warn "class is $class, this is $this";

  my $origins = ref($this)->can('_class_params') && ref($this)->_class_params
    or croak "No parameters defined for $class";

  return $origins->{+shift} if(@_ == 1);
  return @{$origins}{@_} if(@_);
  return \%{$origins}; #return a copy of the full thing
}

=head2 joinstructure

  ABSTRACT

  Args: none
  Ret : hash ref describing how tables are to be joined together

  The hash goes as:

  { root      => $gss,
    joinpaths => [
                    [ [$chr, "$gss.chromat_id = $chr.chromat_id"],
		      [$cln, "$cln.clone_id = $chr.clone_id"],
		      [$lib, "$lib.library_id=$cln.library_id"],
		    ],
		    [ [$qcr, "$qcr.gss_id=$gss.gss_id"],
		    ],
		    [ [$gsub, "$gss.gss_id=$gsub.gss_id"],
		      [$sub, "genbank_submission_id"],
		    ],
		 ],
  }

  The names of the join paths (libpath, qcrpath, subpath, etc) are ignored,
  they re only there to keep things a bit more transparent.

  NOTE: currently, this class does not alias tables, so cannot handle joining
        more than once through a given table in the same query.  For example, if you
        join through the GSS table once with (gss.chromat_id=chromat.chromat_id)
        to get some value, then also join through it again with
        (gss.chromat_id=chromat.chromat_id AND length(gss.seq > 100),
        you will get an error from your sql engine.

        Also, don t use USING() in your join conditions.  Just don t.

=cut

sub joinstructure {
  my $this = shift;
  my $class = ref($this);

  #TODO ALIAS ALL TABLES AND UPDATE DOCUMENTATION ABOVE

  #initialize _class_joinstructure if there is none
  $class->can('_class_joinstructure')
    or $class->mk_classdata(_class_joinstructure => []); #provided by Class::Data::Inheritable

  my %jstructure = (root      => $class->_class_joinroot,
		    joinpaths => $class->_class_joinstructure
		   );
  return \%jstructure; #return a copy, not the original
}

=head2 return_data

  Args: none
  Ret : array of parameter names or fully-qualified column names whose values
        should appear in the return data of the query, that is, after the SELECT
        and before the FROM

=cut

sub return_data {
  my $this = shift;
  my $class = ref $this;
  return @{ $class->_class_selects_data };
}

=head1 IMPLEMENTED METHODS

=head2 init

Called by the provided 'new' method with no arguments.
Derived classes might find it useful to override this method
in order to set up default parameters for this object.

This implementation sets the page number to zero, to satisfy
the requirement in L<CXGN::Search::QueryI> that new objects
have their page number initialized to 0.

The terms combining operator ($this->terms_combine_op())
is set to 'AND'

=cut

sub init {
  my $this=shift;
#   $this->{_orderby} = [];
#   $this->{_params} = {};

  $this->page(0);
  $this->terms_combine_op('AND');
}

=head2 debug

  Desc: get/set the debugging level of output from this object.
        level 1 - use warn() to output the data and count SQL queries that are generated
        level 2 - print even more stuff
  Args: (optional) new debugging level
  Ret : new debugging level
  Side Effects: sets the debugging level in the internal state of this object
  Example:

    my $query = $search->new_query;
    $query->debug(1);
    $query->bogoparam('= 42');
    my $result = $search->do_search($query);

    #when do_search is called the $query object will warn() what
    #SQL queries it generated

=cut

#sub debug implemented with class::methodmaker above

=head2 clear

  Clear query object of parameters and resets its page number to 0.
  See documentation in L<CXGN::Search::QueryI>.

=cut

sub clear {
  my $this = shift;

  $this->param_reset;
  $this->page(0);
  delete($this->{_orderby});
  delete($this->{_compounds});

  undef;
}

=head2 sql_quote_literal

Method for quoting values like SQL expects.
In short, if it looks like a number, do not quote.
If it looks like a string, escape any internal ' quotes
and quote it.

=cut

sub sql_quote_literal {  #quote a value like SQL expects
  my ($this,$arg) = @_;

  return $arg if looks_like_number($arg);

  my $q = "'";
  $arg =~ s/$q/$q$q/g;
  return "$q$arg$q";
}

sub param_names {
  shift->param_keys(@_);
  #param_keys is generated by Class::MethodMaker
}
sub param_val {
  shift->param_index(@_);
  #param_index is generated by Class::MethodMaker
}

=head2 AUTOLOAD

This class contains an AUTOLOAD method that lets you work with
your query parameters as if they were object methods.  Croaks if a parameter is not defined.

Example:

    ### sets the parameter 'name' and gives it an SQL mapping
    ### that will match anything containing the string 'jimmy'
    $query->name("LIKE ?",'%jimmy%');
    #or maybe
    $query->name('UPPER(&t) LIKE ?','%JIMMY%');
    # the &t is interpolated to the proper qualified column name or
    # sql expression that gives the value of that parameter

    ### returns the set ['param string', bind vals], or undef if the
    ### parameter 'height' doesn't exist
    $query->height();

=cut

sub AUTOLOAD {
    my $this = shift;
    ref($this) && UNIVERSAL::isa($this,'CXGN::Search::QueryI')
	or confess "Cannot call AUTOLOAD without an object.  Perhaps you are calling a function called '$AUTOLOAD' that is currently undefined?";
    my $value = shift;
    my @bindvals = @_;
    my ($paramname) = $AUTOLOAD =~ /^(?:.+::)?([^:]+)$/;
    ref($value) eq 'CODE'
      and croak "subroutine refs no longer supported for setting parameters, use bindvalues instead";
    ref($value)
      and croak "invalid value setting parameter '$paramname'";

    my $this_po = $this->param_def($paramname)
      or confess "Unknown parameter $paramname, or maybe the $paramname() function is not defined and should be";

    if( $value ) {
      if($this_po->{type} eq 'simple') {
	#check whether this param is being used by a complex parameter
	#that is already set
	foreach my $otherpn (grep {$this->param_val($_)} $this->param_names) {
	  my $other_po = $this->param_def($otherpn);
	  if ( $other_po->{type} eq 'complex'
	       && ! $this->{_calling_setter} eq $otherpn
	       && grep {$paramname eq $_} @{$other_po->{uses}}
	     ) {
	    confess "simple param $paramname is already being set by complex parameter '$otherpn'";
	  }
	}
      }
      else {
	#this must be a complex param.  check if the simple params it
	#uses conflict with any simple or complex params that are
	#already set
	foreach my $otherpn (grep {$this->param_val($_)} $this->param_names) {

	  #check for params in our uses list that are set
	  if( grep {$otherpn eq $_} @{$this_po->{uses}} ) {
	    croak "$paramname uses $otherpn, but it's already set\n";
	  }

	  #check for params in our uses list that are also used by
	  #other complex params that are set
	  my $other_po = $this->param_def($otherpn);
	  if ( $other_po->{type} eq 'complex'
	       && grep {my $ou = $_; grep {$ou eq $_} @{$this_po->{uses}}} @{$other_po->{uses}}
	     ) {
	    confess "complex param $paramname is already being set by complex parameter '$otherpn'";
	  }
	}
      }


      #if all is OK, set this param
      $this->param_set($paramname => [$value,@bindvals]);
    }

    return $this->param_val($paramname);
}

=head2 order_by

 Get/set the expression with which to order the return results.

 Args: OPTIONAL <param name> => <string>, <param name> => <string>
 Ret : the (maybe new) orderby hash as a list

 NOTE:  This function used to be stupidly called orderby.  For backward
        compatibility, that name still works also.

=cut

sub orderby {
  shift->order_by(@_);
}
sub order_by {
  my $this = shift;

  ###check input###
  if(@_) {

    my %ob = @_;

    foreach (values %ob) {
      defined $_ or croak "orderby needs a code ref or string";
      my $r = ref;
      $r and croak "'$r' refs not supported in order_by";
    }

    @{$this->{_orderby}} = @_;
  }

  return @{$this->{_orderby}} if ( ref($this->{_orderby}) eq 'ARRAY' );
  return ();
}

=head2 page

  Get/set the requested page number.

=cut

#NOTE: the page accessor is implemented using Class::MethodMaker

=head2 next_page

  Increment the requested page number by 1, or if no pages have been requested
  yet, set the page number to 0.

=cut

sub next_page {
  my $this = shift;
  if($this->page_isset) {
    $this->page($this->page+1);
  } else {
    $this->page(0);
  }
}



###############################################################
################  SQL QUERY GENERATION  #######################
###############################################################

=head2 to_sql

  Desc:	generate two SQL queries from this Query s parameters,
        a query to return the actual matching database rows,
        and a query to count the total number of matching rows
  Args:	none
  Ret :	array of ( SQL query for data,
                   SQL query for results count,
                   @bind_values_for_queries
                 )

  Note that the data query and count query are assumed to have the
  same bind values

=cut

sub to_sql {
  my $this = shift;

  #operate on a clone of this object, because the setters of complex
  #params will alter this object
#   use Data::Dumper;
#   delete $this->{_conf};
#   print "<pre>".Dumper($this)."</pre>";
  $this = dclone($this); #< dclone() is from Storable.pm

  #run the setters on all our complex params
  foreach my $complex_pn (grep {$this->param_def($_)->{type} eq 'complex'} $this->param_names) {
    local $this->{_calling_setter} = $complex_pn;
    $this->param_def($complex_pn)->{setter}->($this,@{$this->param_val($complex_pn)});
  }

  ### find out which tables we need to join,
  ### and get the list of SQL conditions expressed
  ### by the params object
  my ($tables,$where_conditions,$group,$having_conditions,$bindvals) = $this->_sql_tables_and_conditions;

#   use Data::Dumper;
#   print 'tables ',Dumper($tables);
#   print 'where ',Dumper($where_conditions);
#   print 'having ',Dumper($having_conditions);

  ### build the table joins ###
  my @sql_joins    = $this->_sql_joins($tables);
  my @sql_orderbys = $this->_sql_orderby_expressions;

  #@sql_joins now contains all of the table joins we'll be making, 
  #in the order we'll be making them

  #things that come in externally

  ### assemble the complete (except for limits) SQL queries ###
  my @sql_select_data = map {
    $_ = _term2sql($_) if index($_,'.') == -1; #render it to sql if it is a param name
    $_;
  } $this->return_data;

  #if we have a grouped field, then group by all of our return data fields
  my @groupvals = $group ? @sql_select_data : ();

  return $this->_assemble_sql_queries(\@sql_select_data,
				      \@sql_joins,
				      $where_conditions,
				      \@groupvals,
				      $having_conditions,
				      \@sql_orderbys,
				      $bindvals,
				     );
}

=head2 terms_combine_op

  Desc:	get/set the SQL terms combining operator, operator(s) with which the 
        individual search terms should be combined.  Defaults to 'AND'.
  Args:	string containing a valid SQL binary logical operator ('AND', 'OR', 'XOR', etc)
  Ret :	the current terms combining operator

  Note: no validity checking is done at the time this is set.  If it is not valid
        syntax for the SQL engine, the search will fail.

=cut

sub terms_combine_op {
  my $this = shift;
  $this->{_terms_combine_op} = shift || $this->{_terms_combine_op};
}

=head2 natural_joins

  Desc: If true, SQL generator assumes that it can generate natural joins
        instead of left/right joins.  When dealing with not very smart query
        optimizers (like MySQL's), this can make a huge performance difference.
        However, you can only safely specify this if you are not specifying that
        any of your query parameters have to be null.
  Args: optional new value of natural_joins
  Ret : currently set value of natural_joins

=head2 _sql_tables_and_conditions

  Desc: build a list of tables we need to join for the specified
        search params, and arrays containing the finished top-level
        terms for the SQL WHERE and HAVING clauses, which will be
        joined together in _assemble_sql_queries() below
  Args: none
  Ret : array of ( [ tables we need ],
                   [ WHERE conditions ],
                   true if we need to GROUP BY/false otherwise,
                   [ HAVING conditions ],
                 )

  Internal method.  You probably don't have to touch this.

=cut

sub _sql_tables_and_conditions {
  my $this = shift;

  my %required_tables;
  my @where_conditions;
  my @having_conditions;
  my @bindvals;
  my $do_we_group = 0;

  #in this hash, remember which params we have already rendered
  my %terms_already_rendered;

  #recursively render the SQL for each conditional term that's
  #defined.  Usually, most of these will just be regular search
  #parameters
  my %p = $this->param;
  foreach my $termname ( @{$this->{_compounds}{order}}, keys %p) {
    #but don't render it if it has already been rendered as part of
    #the recursion above
#    warn "processing term $termname\n";
    next if $terms_already_rendered{$termname};

    #also don't render it if it's a complex param.  its setter should
    #have already been run in to_sql() above
    next if $this->param_def($termname) && $this->param_def($termname)->{type} eq 'complex';

    my ($sql,$is_grouped,$is_agg,@bind) =
      $this->_term2sql($termname,
		       \%terms_already_rendered,
		       \%required_tables,
		      );
#    warn "for $termname, got '$sql',$is_grouped,$is_agg\n";

    # store the final SQL clause as part of either our WHERE
    # (pre-grouping) or HAVING (post-grouping) clause
    if($is_agg) {
      push @having_conditions, $sql;
    } else {
      push @where_conditions, $sql;
    }

    $do_we_group ||= $is_grouped;

    #concatenate this term's bind values onto the running array of them
    push @bindvals,@bind;
  }

  ### don't forget to get the right tables for our orderby clauses ###
  my @orderbys = $this->orderby;
  if(@orderbys) {
    while(my ($ob_param,$ob_val) = splice @orderbys,0,2) {
      $required_tables{$_} = 1 foreach $this->_param_needs_tables($ob_param);
    }
  }

  ### and also make sure we get the right tables for the data we will return ###
  foreach my $data_item ($this->return_data) {
    if( index($data_item,'.') != -1 ) { #must be a fully-qualified column name
      my( $schema,$table,$col ) = split /\./,$data_item;
      $required_tables{"$schema.$table"} = 1;
    } else { #must be a parameter name
      $required_tables{$_} = 1 foreach $this->_param_needs_tables($data_item);
    }
  }

  return ( [ keys %required_tables ],
	   \@where_conditions,
	   $do_we_group,
	   \@having_conditions,
	   \@bindvals,
	 );
}


=head2 _term2sql

  Desc: method to recursively render a conditional term (for WHERE or HAVING
        conditions) and its subterms into SQL
  Args: name of term to render,
        (optional) ref to hash in which to record the names of the terms we
          render recursively, so we don't do them twice,
        (optional) ref to hash in which we will record what tables are used
          by the terms we render
  Ret : (parenthesized SQL expression for this conditional term,
         boolean whether this is a grouped term,
         boolean whether this is an aggregate term,
        )
  Side Effects:
        - Sets keys in required_tables hash of all the tables that will be needed
        to provide the data used in this term of SQL
        - Sets keys in the passed already_rendered hash corresponding to all of 
        the terms that this call recursively renders

=cut

sub _term2sql {
  my ($this,$termname,$already_rendered,$required_tables) = @_;
  my $sql = '';
  my @bindvals = ();
  my $is_grouped = 0;
  my $is_aggregate = 0;

  $already_rendered = {} unless defined $already_rendered;
  $required_tables = {} unless defined $required_tables;

  $already_rendered->{$termname} = 1; #remember that we have been here

  #for regular parameter names
  if (my $paramdef = $this->param_def($termname)) {
    my ($param_text,@bind) = @{$this->param_val($termname)};

    ### check off each of the tables we need
    $required_tables->{$_} = 1 foreach $this->_param_needs_tables($termname);

    ### render the SQL condition for this param
    ### with: definition for each parameter
    my $value_expression = _valexpr($paramdef);
    # final WHERE or HAVING condition as it will appear in the generated
    # SQL quer
    $sql = $this->_param_condition_sql($termname);

    # whether this parameter related to a value that comes from a
    # count(*) or sum(bleh) or the like to be put in a HAVING clause
    $is_aggregate = (ref $paramdef) && $paramdef->{aggregate};

    #whether using this term means we need a GROUP BY in our generated
    #SQL
    $is_grouped = (ref $paramdef) && $paramdef->{group};

    @bindvals = @bind;

  } elsif ( my $term = $this->{_compounds}{terms}{$termname} ) {
    #copy the format to avoid destroying it with shift()
    my @fmt = @{$term->{format}};

    #recursively render the term as SQL
    foreach my $subterm (@{$term->{subterms}}) {
      #recursively call this function for each term in the compound
      my ($term_sql,undef,undef,@term_binds) = $this->_term2sql($subterm,$already_rendered,$required_tables);
      $sql .= shift(@fmt).$term_sql;
      push @bindvals,@term_binds;
    }

    $sql .= shift @fmt;

    $is_grouped = $term->{group};
    $is_aggregate = $term->{aggregate};

    @fmt && die "Should have no more format pieces at this point";
  } else {
    croak "Unknown compound term or search parameter '$termname', check your use of compound()";
  }

#  warn "rendered term '$termname' as '$sql'\n";

  if (wantarray) {
    warn "$termname: returning bindvals ",@bindvals,"\n" if $this->debug;
    return ("($sql)",$is_grouped,$is_aggregate,@bindvals);
  } else {
    return "($sql)";
  }
}#end term2sql subroutine

#args: parameters object
#ret : array of SQL expressions we will order by, empty list if none
sub _sql_orderby_expressions {
  my $this = shift;

  ### get the orderby parameter and its expression coderef ###
  my @ob = $this->orderby;
  my @ob_expressions;
  while (my ($ob_param,$ob_val) = splice @ob,0,2) {
  	$ob_val ||= '';
    push @ob_expressions,$this->_param_sql($ob_param,$ob_val);
#     if(ref($ob_val) eq 'CODE') {
#       push @ob_expressions,$ob_val->($fieldexp);
#     } else {
#       $ob_val ||= '';
#       push @ob_expressions,$fieldexp.' '.$ob_val;
#     }
  }

  return @ob_expressions;
}

#converts hashref param definition into the sql expression that will give its value
sub _valexpr {
  my %args = %{shift()};

  return $args{sqlexpr} if $args{sqlexpr};

  return ref $args{columns} ? @{$args{columns}} == 1 ? $args{columns}->[0]
                                                   : croak 'must specify sqlexpr if using multiple columns'
			    : $args{columns},
}

#object method, given param name, return sql expression for its value
sub _param_value_expression_sql {
  my ($self,$paramname) = @_;
  my $o = $self->param_def($paramname);
  return _valexpr($o);
}

#given the parameter name and its text value, render it to SQL
sub _param_sql {
  my ($self,$paramname,$param_text) = @_;
  my $value_expression = $self->_param_value_expression_sql($paramname)
    or confess "cannot generate an SQL expression for parameter '$paramname'";
#  warn " '$value_expression'\n";
  if($param_text =~ s/&t/$value_expression/g) {
    return $param_text;
  } else {
    return $value_expression.' '.($param_text || '');
  }
}
#object method, given paramname, return the full SQL condition based
#on the values that are currently set for the parameter, for use in a
#WHERE or HAVING clause
sub _param_condition_sql {
  my ($self,$paramname) = @_;
  $self->param_val($paramname)
    or confess "Search parameter '$paramname'  not set (improper use of compound()?)";
  my ($param_text) = @{$self->param_val($paramname)};
#  warn "getting value expression for $paramname = \n";
  return $self->_param_sql($paramname,$param_text);
}
=head2 _param_needs_tables

  args: parameter name
  ret : list of tables containing information for that parameter

=cut

sub _param_needs_tables {
  my ($this,$paramname) = @_;
  my $origin = $this->param_def($paramname)
    or croak "Unknown search parameter '$paramname'";

  #gets just the tablename from a fully-qualified field name
  sub tablename { $_[0] =~ /^(.+)\.[^\.]+$/; $1 };

  #ref $origin implies that this parameter is a compound parameter
  #made from several data fields
  return map tablename($_), (ref $origin) ? @{$origin->{columns}} : ($origin);
}

=head2 _sql_joins

  args: array ref of all of the FULLY QUALIFIED table names
        we will need in the join
  ret : ordered array of SQL tables and join statements to come
        after the FROM

=cut 

sub _sql_joins {
  my ($this,$tables) = @_;
  ref $tables eq 'ARRAY'
    or die 'Takes 1 argument, an array ref of fully-qualified table names';

  my @known_tables = 
    map { map {$_->[0]} @$_ } #list of tables in the join path
      @{$this->joinstructure->{joinpaths}}; #for each join path

  push @known_tables,$this->joinstructure->{root}; #don't forget the join root table

  #hash it for easy lookups and to remove duplicates
  my %known_tables = map {$_=>1} @known_tables;

  ### hash the list of needed tables so we can look up from them faster ###
  ### also, while traversing, check that each of the needed tables is   ###
  ### present in the list of known tables from above                    ###
  my %sql_tables = map { $known_tables{$_} or croak "No table $_ defined in join path"; 
			 $_=>1; }
		      @$tables;

  my @sql_joins;  # holds the SQL joins we are going to return
  my %already_joined; #hash of the tables we are joining

  #we start at the join root
  push @sql_joins,$this->joinstructure->{root};


  my $jointype = $this->natural_joins ? 'JOIN' : 'LEFT JOIN';
  foreach my $path (@{$this->joinstructure->{joinpaths}}) {
    #do a linear join down the path of only the tables we need

    #add all of the tables to the join
    my @thesejoins = map {"$jointype $_->[0] ON ($_->[1])"} @$path;

    #trim off the tables we don't need, which are the tables
    #further out along the join than the LAST table with a field we need
    my $iter = 0;
    foreach my $table_entry (reverse @$path) {
      my $tablename = $table_entry->[0];
      last if $sql_tables{$tablename}; #if we need this table, stop trimming
      pop @thesejoins;
    }

    #if we are already doing any of these joins, toss them out
    @thesejoins = grep { my $j = $_;  !(grep { $_ eq $j } @sql_joins) } @thesejoins;

    #add these joins, which are the ones we really need, to the big join we're making
    push @sql_joins,@thesejoins;
  }

  return @sql_joins;
}

=head2 compound

  Usage: $query->compound('&t OR NOT &t','go_accession','go_desc_fulltext');
  Desc: printf-like method to define compound AND/OR WHERE terms out of other
  Args: format string, array of other term names
  Ret : a string identifier for the compound just constructed.  you can use
        this in other compound() calls if you want to make compounds of
        compounds
  Side Effects:

  Example:

    you can construct arbitrarily complex ways of evaluating the search
    parameters by nesting calls of compound_term, like so:

    $query->go_accession('=?',2342);
    $query->go_desc_fulltext(' @@ to_tsquery(?)',to_tsquery_string('monkeys'));
    $query->compound('&t OR NOT &t','go_accession','go_desc_fulltext');

  Usage of compounds has its effects felt only in the SQL WHERE and HAVING
  clauses that this thing produces.  Those are rendered
  in _sql_tables_and_conditions() above

=cut

my $_termname_collision_preventer = 0; #incrementing thing for autogenerating term names
sub compound {
  my $this = shift;
  my $termname = $_[0] =~ /&t/ ? 'c'.$_termname_collision_preventer++ : shift;
  my $fmtstring = shift;
  my @terms = @_;

  croak "A compound term called '$termname' already exists."
    if $this->{_compounds}{terms}{$termname};

  #break up the format string on the term sequences add a space to the
  #beginning of the format to coddle the lookbehind assertion in the
  #pattern below
  my @fmt = split /(?<=[^&])&t/," $fmtstring",-1; #-1 prevents
                                                  #removing trailing
                                                  #nulls
  $fmt[0]  =~ s/^\s+//g; #trim leading
  $fmt[-1] =~ s/\s+$//g; #and trailing whitespace

  (@fmt == @terms + 1)
    or croak ((ref $this).'->compound: number of arguments does not match format string');

  #check that all of the specified terms actually exist
  $this->param_def($_) || $this->{_combined}{terms}{$_} || croak "Unknown term name '$_'"
    foreach @terms;

  #check whether the given terms are grouped terms, or non-grouped terms
  my $aggregate = grep { my $o = $this->param_def($_);
			 ref $o && $o->{aggregate}
			   || $this->{_combined}{terms}{$_} && $this->{_combined}{terms}{$_}{aggregate}
		       } @terms;

  croak 'Cannot mix aggregate and non-aggregate terms in the same compound term.  Aggregates go in the HAVING, but non-aggregates go in the WHERE'
    unless $aggregate == @terms || $aggregate == 0; #must be all aggregate, or none aggregate

  #do any of these terms need a GROUP BY?
  my $group = grep { my $o = $this->param_def($_);
		     ref $o && $o->{group}
		       || $this->{_combined}{terms}{$_} && $this->{_combined}{terms}{$_}{group}
		     } @terms;

  #concatenate the bind values for these terms
  my @bindvals = map { my $o = $this->param_def($_);
		       if(ref $o and my $param = $this->param_val($_)) {
			 my (undef,@binds) = @$param;
			 @binds
		       } else {
			 ()
		       }
		     } @terms;


  $this->{_compounds}{terms}{$termname} = { subterms => \@terms,
					    format=> \@fmt,
					    aggregate => $aggregate,
					    group => $group,
					    bindvals => \@bindvals,
					  };
  unshift @{$this->{_compounds}{order}},$termname;

  return $termname;
}


=head2 _assemble_sql_queries

  Desc:
  Args: refs to arrays of fields, joins, where conditions, groupby fields,
        having conditions, and orderby conditions, all in SQL but not joined
        together
  Ret : array of (data query, count query, bind val, bind val, bind val,...)

  This is an internal method, so hands off!  Unless you're brave.

=cut

#args: ptrs to fields, joins, conditions, and orderbys
#ret: list consisting of the regular query and the count query
sub _assemble_sql_queries {
  my ($this,$fields,$joins,$wheres,$groupbys,$havings,$orderbys,$bindvals) = @_;

  my $combineop = $this->terms_combine_op;

  ### build a search query ###
  my $sql_where_clause =
    $wheres && @$wheres
      ? 'WHERE '.join(" $combineop ",@$wheres)
      : '';

  my $sql_having_clause =
    $havings && @$havings
      ? 'HAVING '.join(" $combineop ",@$havings)
      : '';

  my $sql_groupby =
    $groupbys && @$groupbys
      ? 'GROUP BY '.join(',',@$groupbys)
      : '';

  my $sql_orderby =
    $orderbys && @$orderbys
      ? 'ORDER BY '.join(',', @$orderbys)
      : '';

  #SQL_CALC_FOUND_ROWS is a mysql-specific thing
  my $sql_calc_found_rows = ($this->{dbtype} && $this->{dbtype} =~ /mysql/i) ? 'SQL_CALC_FOUND_ROWS' : '';

  my $data_query  = join(' ',
			 ('SELECT',
			  $sql_calc_found_rows ,
			  join(',', @$fields),
			  'FROM',
			  join(' ', @$joins),
			  $sql_where_clause,
			  $sql_groupby,
			  $sql_having_clause,
			  $sql_orderby,
			 )
			);

  my $count_query = ($this->{dbtype} && $this->{dbtype} =~ /mysql/i)
    ? 'SELECT FOUND_ROWS()'
    : "SELECT COUNT(*) FROM ($data_query) AS cnt";
	
  if($this->debug) {
    warn((ref $this).": Made query:\n$data_query\n");
    warn((ref $this).": Made count query:\n$count_query\n");
  }

  return ($data_query,$count_query,@$bindvals);
#  return ($data_query,'SELECT 7');
}

# COUNTING
# if not grouped, simple count(*) is fine
# if using group by with mysql, can use FOUND_ROWS()
# if using group with postgres, can use a subquery

#chaining destructors together is good
sub DESTROY {
  my $this = shift;
  return parricide($this, our @ISA);
}

###
1;#do not remove
###
