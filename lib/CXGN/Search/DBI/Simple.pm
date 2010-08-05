package CXGN::Search::DBI::Simple;

use strict;
use warnings;
use English;
use Carp;
use Time::HiRes;

use CXGN::Tools::Class qw/parricide/;

use base qw/CXGN::Search::SearchI  Class::Data::Inheritable/;

=head1 NAME

CXGN::Search::DBI::Simple - Search object base class

=head1 DESCRIPTION

This is the search object of a set of L<CXGN::Search> objects that make it easy
to construct SQL database searches that involve a single query, joining multiple
tables.  Advanced SQL-generating capability allows defining very complex JOINed
searches that use composite (multi-column) data types, GROUP BY clauses, and/or
HAVING clauses.

These searches can return any data type, with the default being simple arrayrefs
containing each row in the result set.

=head1 USING DBI::SIMPLE SEARCHES

  use CXGN::BogoPeopleSearch;

  #find all the people whose last name begins with J
  my $search = CXGN::BogoPeopleSearch->new;
  my $query = $search->new_query;
  $query->last_name("LIKE 'J%'");
  my $results = $search->do_search($query);

  #print them all out
  print "In all, ",$results->total_results,
        " people have a last name beginning with J:\n";
  while( my $person = $results->next_result ) {
    print "  ",$person->[1]," ",$person->[2],"\n";
  }

=head1 CREATING DBI SEARCHES

=head2 The Simplest Search

Here's how our little people search above is implemented
with CXGN::Search::DBI::Simple.
Pretend there's a table in the database called sgn.person,
created with the SQL

  CREATE TABLE sgn.person (
     person_id int SERIAL,
     first_name varchar(30),
     last_name varchar(30)
  );

Then, to implement a search by last name,
that returns array refs containing rows from this table:

  package CXGN::BogoPeopleSearch;
  use base qw/CXGN::Search::DBI::Simple/
  __PACKAGE__->creates_result('CXGN::BogoPeopleSearch::Result');
  __PACKAGE__->uses_query('CXGN::BogoPeopleSearch::Query');

  1;
  package CXGN::BogoPeopleSearch::Query;
  use base qw/CXGN::Search::DBI::Simple::Query/;
  __PACKAGE__->selects_data(qw/ sgn.person.person_id
                                sgn.person.first_name
                                sgn.person.last_name
                              /);
  __PACKAGE__->join_root('sgn.person');
  __PACKAGE__->has_parameter(name    => 'last_name',
                             columns => 'sgn.person.last_name',
                            )
  1;
  package CXGN::BogoPeopleSearch::Result;
  use base qw/CXGN::Search::BasicResult/;
  1;

Notice that all the table and column names are required to be fully-qualified.
That is, all column names also specify the table and schema they are in, and
all table names also specify the schema name.  When we start making more
complex searches with multiple table in multiple schemas, the search framework
(and the database) relies on this to avoid getting confused.

=head2 A Joined Search

Suppose we want to expand our little people search to search for people using
information that's contained in another table that's related to this one:

  CREATE TABLE sgn.papers (
     person_id int REFERENCES sgn.people (people_id),
     title varchar(30)
  );

And yes I know there can be multiple authors for a paper.  This is a tutorial.
Deal.

Then, our search would become

  package CXGN::BogoPeopleSearch;
  use base qw/CXGN::Search::DBI::Simple/
  __PACKAGE__->creates_result('CXGN::BogoPeopleSearch::Result');
  __PACKAGE__->uses_query('CXGN::BogoPeopleSearch::Query');

  1;
  package CXGN::BogoPeopleSearch::Query;
  use base qw/CXGN::Search::DBI::Simple::Query/;
  __PACKAGE__->selects_data(qw/ sgn.person.person_id
                                sgn.person.first_name
                                sgn.person.last_name
                              /);
  __PACKAGE__->join_root('sgn.person');
  ### NEW
  __PACKAGE__->uses_joinpath('papers', ['sgn.papers','sgn.papers.person_id=sgn.person.person_id]);
  ### /NEW
  __PACKAGE__->has_parameter( name    => 'last_name',
                              columns => 'sgn.person.last_name',
                            );
  ### NEW
  __PACKAGE__->has_parameter( name    => 'paper_title',
                              columns => 'sgn.papers.title',
                              group   => 1,
                            );
  ### /NEW
  1;
  package CXGN::BogoPeopleSearch::Result;
  use base qw/CXGN::Search::BasicResult/;
  1;

Note that we've inserted two more function calls, a uses_joinpath(),
and another has_parameter().  The uses_joinpath tells the Query how to construct
a join into papers.  Notice the additional 'group => 1' argument to uses_joinpath.  This
specifies that there may be multiple rows in the papers table for each row in the person
table, and that it should construct the query accordingly.
The has_parameter adds a parameter called paper_title that searches the sgn.papers.title table.
Now, users of the module can search for people by the titles of papers they've authored:

  $query->paper_title('ILIKE ?','%crystallin%');
  my $results = $search->do_search($query);

will return a CXGN::BogoPeopleSearch::Result object containing all people who
authored papers whose titles contained the word 'crystallin'.

=head2 Defining and Using Complex Data

coming soon

=head2 Putting Your Search on the Web

see L<CXGN::Search::DBI::Simple::WWWQuery>

=head1 SYNOPSIS

  #let's implement a complete simple database search
  #note that all table and column names must be FULLY QUALIFIED
  #as schema.table.column_name

  ### SEARCH ###
  package BogoSearch;

  use base qw/CXGN::Search::DBI::Simple/;

  __PACKAGE__->creates_result('BogoSearch::Result');
  __PACKAGE__->uses_query('BogoSearch::Query');
  __PACKAGE__->transforms_rows(\&my_bogo_transform_row);

  sub my_bogo_transform_row {
    my @data_from_database = @_;

    #return a new object loaded with this data
    return BogoObject->new(@data_from_database);
  }

  1; #modules must return true

  ### RESULT ###
  package BogoSearch::Result;
  use base qw/CXGN::Search::BasicResult/;

  1; #usually not necessary to modify the Results object

  ### QUERY ###
  package BogoSearch::Query;

  use base qw/CXGN::Search::Query::DBI::Simple/;

  __PACKAGE__->join_root('sgn.unigene');
  __PACKAGE__->uses_joinpath('build',['sgn.unigene_build', "sgn.unigene.unigene_build_id=sgn.unigene_build.unigene_build_id"]);
  __PACKAGE__->uses_joinpath('consensus',['sgn.unigene_consensi, "sgn.unigene.consensi_id=sgn.unigene_consensi.consensi_id']);

  #make parameters for all of the columns in a unigene,
  my @ug_columns = qw/ unigene_id unigene_build_id consensi_id nr_members cluster_no contig_no /;
  __PACKAGE__->has_parameter(name => "$_", columns => "sgn.unigene.$_") foreach @ug_columns;

  #make fulltext search parameters for blast deflines and manual annotation text fields
  __PACKAGE__->has_parameter(name => 'blast_defline_fulltext',
			     columns => 'sgn.blast_defline.defline_fulltext',
			     group   => 1,
			    );

  __PACKAGE__->selects_columns(qw/ sgn.unigene.unigene_id / );

  #and now you have a search

=head1 BASE CLASSES

L<CXGN::Search::SearchI>

=head1 SUBCLASSES

L<CXGN::Search::DBI::CDBI> - same as this object, but customized to deal
 more efficiently with L<Class::DBI> returned objects

L<CXGN::Genomic::Search::GSS> - search for L<CXGN::Genomic::GSS> objects
L<CXGN::Genomic::Search::Clone> - search for L<CXGN::Genomic::Clone> objects

=cut

#automatically construct boilerplate 'new' and accessors
use Class::MethodMaker
  [ scalar   => [ 'debug',
                  +{ -type => 'CXGN::Search::QueryI'}, 'query',
		],
    new      => [qw/ -init new /],
  ];

=head1 DEFINING YOUR SEARCH

=head2 transforms_rows

  Desc: specify how this search transforms rows of data into whatever
        type it returns
  Args: reference to subroutine to run in order to convert a row of data
        into the desired return type
  Ret : 1
  Side Effects:
  Example:

=cut

sub transforms_rows {
  my $class = shift;
  ref $class
    and croak "transforms_rows is a class method, not an object method";

  my $coderef = shift;

  #validate params
  ref($coderef) eq 'CODE'
    or croak 'invalid parameters to transforms_rows';

  #create class data if necessary
  $class->can('_class_transforms_rows')
    or $class->mk_classdata('_class_transforms_rows'); #provided by Class::Data::Inheritable

  #create the new processing code ref
  $class->_class_transforms_rows($coderef);

  return 1;
}

=head2 creates_result

  Desc: set the class of Result objects this search will return
  Args: name of a Result class that implements CXGN::Search::ResultI
  Ret : 1
  Side Effects: sets result class name in internal class data
  Example:

    use base qw/CXGN::Search::DBI::Simple/;
    __PACKAGE__->creates_result('CXGN::Unigene::Search::Result');

=cut

sub creates_result {
  my $class = shift;
  ref $class
    and croak "creates_result is a class method, not an object method";

  my $result_class_name = shift;

  #validate params
  UNIVERSAL::isa($result_class_name,'CXGN::Search::ResultI')
    or croak "invalid args to creates_result(): result class name must be a subclass of CXGN::Search::ResultI, you requested result class '$result_class_name'";

  #create class data if necessary
  $class->can('_class_creates_result')
    or $class->mk_classdata('_class_creates_result'); #provided by Class::Data::Inheritable

  #create the new processing code ref
  $class->_class_creates_result($result_class_name);

  return 1;

}

=head2 uses_query

  Desc: set the class of Query objects used by your search
  Args: string containing the name of a search query that implements
        CXGN::Search::Query::DBI::QueryI
  Ret : 1
  Side Effects: remembers Query name in internal class data
  Example:

    use base qw/CXGN::DBI::Simple/;
    __PACKAGE__->uses_query('CXGN::Unigene::Search::Query');

=cut

sub uses_query {
  my $class = shift;
  ref $class
    and croak "uses_query is a class method, not an object method";

  my $query_class_name = shift;

  #validate params
  UNIVERSAL::isa($query_class_name,'CXGN::Search::DBI::Simple::Query')
    or croak "invalid args to uses_query(): query class name must be a subclass of CXGN::Search::Query::DBI::QueryI";

  #create class data if necessary
  $class->can('_class_uses_query')
    or $class->mk_classdata('_class_uses_query'); #provided by Class::Data::Inheritable

  #create the new processing code ref
  $class->_class_uses_query($query_class_name);

  return 1;
}

=head1 RECOMMENDED OVERRIDABLE METHODS

=head2 row_to_object

  Args: row of data (array) from DBI query result, the content and order
        of which is of course a result of the SQL generated by the
        Query object you're using with your search
  Ret : a NEW object of the desired return type for the search
        you will be doing, loaded with the data from the database
        If this method is not overridden and transforms_rows() is
        not set, this method simply returns an array ref containing
        the data in the row.

  NOTE: the fields that this function will be passed are determined
        by the SQL field names returned by the sql_fieldlist() method
        in the Query object you will be using with this search

=cut

sub row_to_object {
  my $this = shift;
  my $class = ref($this) or croak 'improper call of row_to_object';

  if($class->can('_class_transforms_rows')) {
    return $class->_class_transforms_rows->(@_);
  } else {
    return [@_];
  }
}

=head2 new_result

  Desc: return a new Result handle of the appropriate type for this search
        Subclass implementors must override this method.
  Args: (optional) Query object used to generate this result

=cut

sub new_result {
  my ($this,$query) = @_;
  my $class = ref $this;

  my $new_result =  $class->_class_creates_result->new($this,$query);
  $new_result->_query($query);
  $new_result->_search($this);
  return $new_result;
}

=head2 new_query

  ABSTRACT

  Returns a brand new Query instance for use with this search.

  This method is specified in the L<CXGN::Search::SearchI> interface.

=cut

sub new_query {
  my $class = ref shift;
  return $class->_class_uses_query->new(@_);
}

=head1 IMPLEMENTED METHODS

=head2 new

  Desc: Construct a new object.  This is boilerplate, generated by
        Class::MethodMaker.  It calls init() below.  If you need to
        do things at construct time, override init() and put them there.
  Args: none

=head2 init

  Desc: Initialize the new search object.
  Args: none

  The provided init method just sets default a max_cached_rows of 20,000
  and a default page size of 20.  Feel free to override it.

=cut

sub init {
  my $this = shift;

  #by default, hold 20,000 Clone rows in memory at a time
  $this->max_cached_rows(20_000);
  $this->page_size(20);
}

=head2 _rows_limit

  Desc: method to extract and return the SQL limit and offset from a
        L<CXGN::Search::DBI::Simple::Query> object.
  Args: the query object
  Ret : hash of limit=>SQL limit number,
        offset=>SQL offset number

=cut

sub _rows_limit {
  my $this = shift;
  my $query = shift;

  ### figure out limits on the SQL query based on
  ### the requested page and the page size
  #information: result set size, requested page, page size
  #the section of the results we need for this page

  ### check that result set size is at least as big as
  ### requested page size
  ($this->max_cached_rows >= $this->page_size)
    or croak 'Cannot execute search: results page size ('.$this->page_size.') must be less than or equal to maximum results set size ('.$this->max_cached_rows.')';

  my $page = $query->page;
  my $offset = $page * $this->page_size;
  my $limit = $this->page_size;

  return ( limit => $limit,
	   offset => $offset,
	 );
}

=head2 do_search

  Desc: method to conduct a search for the users objects
  Args: a L<CXGN::Search::SearchI>
  Ret : a L<CXGN::Search::ResultI> handle that encapsulates
        the search results

  This method is specified in the L<CXGN::Search::SearchI> interface.

=cut

sub do_search {
  shift->_do_search(shift);
}

=head2 do_count

  Desc: method to count the number of results that would be returned by a search
  Args: a L<CXGN::Search::SearchI>
  Ret : a L<CXGN::Search::ResultI> handle that encapsulates
        the search results

  This method is specified in the L<CXGN::Search::SearchI> interface.

=cut

sub do_count {
  shift->_do_search(shift,1);
}

sub _do_search {
  my $this = shift;
  my $query = shift;
  my $count_only = shift;

  croak 'This search object requires a query object based on CXGN::Search::DBI::Simple::Query'
    unless UNIVERSAL::isa($query,'CXGN::Search::DBI::Simple::Query');

  ### get our page size from the query if it is set ###
  $this->page_size($query->page_size) if $query->page_size_isset;

  my ( $data_query, $count_query, @bindvals ) = $query->to_sql;

  #render the limit sql
  my %lim = $this->_rows_limit($query);
  my $lim_sql = "LIMIT $lim{limit} OFFSET $lim{offset}";

  my $start_time = Time::HiRes::time();

  ### query the database, possibly fetching the Result from cache ###
  # check cache
  if ( my $cached_result = $this->_searchresult_cache_lookup($data_query,\%lim,\@bindvals) ) {
    $cached_result->_time(Time::HiRes::time() - $start_time); #set elapsed time
    return $cached_result;
  }
  ### assemble a results object from the resulting data ###
  my $results = $this->new_result($query);
  $results->page_size($this->page_size); #set the page size

  unless($count_only) {
    ### execute the DB query ###
    my $sth;
    my $dbconn = CXGN::DB::Connection->new;
    eval {
      my $oldpe = $dbconn->dbh_param('PrintError');
      $dbconn->dbh_param('PrintError',0);

      $sth = $dbconn->prepare("$data_query $lim_sql");
      if ( $this->debug ) {
	warn __PACKAGE__.": executing query\n$data_query $lim_sql\n";
      }
      $sth->execute(@bindvals);

      $dbconn->dbh_param('PrintError',$oldpe);
    }; if( $EVAL_ERROR ) {
      croak 'Error executing generated SQL (DBI error: \''.$dbconn->errstr."') (SQL: $data_query $lim_sql)";
    }

    foreach my $row (@{$sth->fetchall_arrayref}) {
      # make a new object and put it in the results
      $results->push( $this->row_to_object(@$row) );
    }
    $sth->finish;
  }

  ## get the count of total search results ##
  $results->total_results( $this->_count_cache_lookup($count_query,\@bindvals) );
  $results->_page($query->page); #the results now contain the requested page
#  warn ((ref $this).': query returned '.$results->total_results." results\n");

  ### cache the SearchResult object if it was a full search###
  unless($count_only) {
    $this->_searchresult_cache_add($data_query,\%lim,$results,\@bindvals);
  }

  ### set the search results elapsed time ###
  $results->_time(Time::HiRes::time() - $start_time);

  ### return the search results ###
  return $results;
}

### check the SearchResult cache for a SearchResult for that
### query string
sub _searchresult_cache_lookup {
  my ( $this, $querystr, $lim, $bindvals ) = @_;
  return undef;
}

### add a Result object to the cache
sub _searchresult_cache_add {
  my ($this, $querystr, $lim, $searchresult, $bindvals) = @_;
  return undef;
}


{
  my %countcache;
  my $slow_query_threshold = 2; #seconds

  ### results count caching ###
  # cache only slow queries
  sub _count_cache_lookup {
    my ($this, $querystr, $bindvals) = @_;
    my $cachekey = $querystr.join(',',@$bindvals);
    my $count;
    unless( defined($count=$countcache{$cachekey}) ) {
      my $btime = time();
      my $dbconn = CXGN::DB::Connection->new;
      eval {
	my $oldpe = $dbconn->dbh_param('PrintError');
	$dbconn->dbh_param('PrintError',0);
	
	warn __PACKAGE__.": querying result count\n" if $this->debug;
	($count) = $dbconn->selectrow_array($querystr,undef,@$bindvals);
	warn __PACKAGE__.": finished querying result count\n" if $this->debug;

	$dbconn->dbh_param('PrintError',$oldpe);
      }; if($EVAL_ERROR) {
	croak 'Invalid syntax in search parameters (DBI said:\''.$dbconn->errstr."', SQL count query was: '$querystr'";
      }
      $count ||= 0;
      $countcache{$cachekey} = $count if ( time() - $btime > $slow_query_threshold );
    }
    $count;
  }
}

=head2 max_cached_rows

  Get/set limit of rows/objects to keep in the results cache.

  Note that this is not "page_size" (see below).  This value is
  strictly for avoiding out-of-memory conditions for very large
  returned result sets.

  Note that this method is NOT required by the L<CXGN::Search::SearchI>
  interface.

=cut

sub max_cached_rows {
    my ($this,$newlim) = @_;

    if(defined($newlim)) {
	## range check ##
	$newlim > 0
	    or croak 'max_cached_rows must be greater than 0';
	$this->{_max_cached_rows} = $newlim;
    }
    return $this->{_max_cached_rows};
}

=head2 page_size

  Get/set the number of return-type objects in a single page (set) of results.
  The page size is controlled by the Search instead of the Query because
  the page size information is needed if the Search object should want to
  keep a cache of search result objects.

  If the new page size is greater than the current max_cached_rows,
  max_cached_rows will be increased.

  Note that this method is NOT required by the L<CXGN::Search::SearchI>
  interface.

=cut

sub page_size {
    my ($this,$newsize) = @_;

    if(defined($newsize)) {
	$newsize > 0
	    or croak 'page_size must be greater than 0';
	$this->{_page_size} = $newsize;
	
	unless( $this->max_cached_rows >= $newsize ) {
	  $this->max_cached_rows($newsize);
	}
    }
    return $this->{_page_size};
}

=head2 debug

  Usage:
  Desc : get/set debugging level, defaults to 0. when nonzero,
         prints debugging information (like the queries that are
         being executed)
  Ret  :
  Args :
  Side Effects:
  Example:

=cut




#have to have the destroy method here, since this does multiple
#inheritance
sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###
