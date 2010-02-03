package CXGN::Search::DBI::CDBI;
use strict;
use warnings;
use Carp;
use English;
use Time::HiRes;

use CXGN::Tools::Class qw/parricide/;

=head1 NAME

CXGN::Search::DBI::CDBI - search framework Search object customized for
efficiently returning L<Class::DBI>-based objects

=head1 DESCRIPTION

=head1 SYNOPSIS

  use base qw/CXGN::Search::DBI::CDBI/;

  __PACKAGE__->creates_result('CXGN::Unigene::Search::Result');

  __PACKAGE__->uses_query('CXGN::Unigene::Search::Query');

  __PACKAGE__->transforms_rows('CXGN::CDBI::SGN::Unigene');

  #now you have a search


=head1 BASE CLASS

L<CXGN::Search::DBI::Simple>

=head1 SUBCLASSES

L<CXGN::Genomic::Search::GSS>
L<CXGN::Genomic::Search::Clone>

=cut

use base qw/CXGN::Search::DBI::Simple/;

=head1 DEFINING YOUR SEARCH

=head2 transforms_rows

  Overrides superclass method in L<CXGN::Search::DBI::Simple>.
  Takes a package name now, not a subroutine reference.

  Setting this is mandatory.

  Desc:
  Args: string containing the name of a Class::DBI-based class
  Ret : 1
  Side Effects: sets class data for this object
  Example:

   use base qw/CXGN::Search::DBI::CDBI/;
   __PACKAGE__->transforms_rows('CXGN::CDBI::SGN::Unigene');

=cut

sub transforms_rows {
  my $class = shift;
  ref $class
    and croak "creates_result is a class method, not an object method";

  my $result_class_name = shift;

  #validate params
  UNIVERSAL::isa($result_class_name,'Class::DBI')
    or croak "invalid args to transforms_rows(): query class name '$result_class_name' must be a subclass of Class::DBI.  Did you forget to load '$result_class_name'?";

  #create class data if necessary
  $class->can('_class_transforms_rows')
    or $class->mk_classdata('_class_transforms_rows'); #provided by Class::Data::Inheritable

  #create the new processing code ref
  $class->_class_transforms_rows($result_class_name);

  return 1;
}

=head1 RECOMMENDED OVERRIDABLE METHODS

=head2 return_class

  Desc: override this to specify our return type
  Args: none
  Ret : string containing the name of the return type class
  Side Effects:
  Example:

=cut

sub return_class {
  my $this = shift;
  my $class = ref $this;
  return $class->_class_transforms_rows;
}

=head1 OVERRIDDEN METHODS

=head2 do_search

  Desc: Same as do_search in base class, except implemented
        differently for L<Class::DBI>.
  Args: L<CXGN::Search::Query::DBI::QueryI> - based Query
  Ret : L<CXGN::Search::BasicResult> object containing L<Class::DBI> objects
  Side Effects: runs one or more SELECT queries on the database
  Example:

  my $resultset = $search->do_search($query);

  Using the class name from return_class() above, assembles the results using
  the Class::DBI (actually L<Ima::DBI>) method set_sql().

=cut

sub do_search {
  my $this = shift;
  my $query = shift;

  croak 'This search object requires a query object based on CXGN::Search::DBI::Simple::Query, you passed a '.ref($query)
    unless UNIVERSAL::isa($query,'CXGN::Search::DBI::Simple::Query');

  ### get our page size from the query if it is set ###
  $this->page_size($query->page_size) if $query->page_size_isset;

  my ( $data_query, $count_query, @bindvals ) = $query->to_sql;

  #render the limit sql
  my %lim = $this->_rows_limit($query);
  my $lim_sql = "LIMIT $lim{limit} OFFSET $lim{offset}";

  my $start_time = Time::HiRes::time();

  ### query the database, possibly fetching the Result from cache ###
  my $r = $this->_searchresult_cache_lookup($data_query,\%lim,\@bindvals)
    || do {

      ### assemble a results object from the resulting data ###
      my $results = $this->new_result($query);
      $results->page_size($this->page_size); #set the page size

      UNIVERSAL::isa($this->return_class,'Class::DBI')
	  or croak 'Package name returned by return_class() must inherit from Class::DBI';

      eval { #catch any syntax errors from the database and format em
# 	no strict 'refs'; #using symbolic refs here
	my $dbh = $this->return_class->db_Main(); #db_Main is provided by Class::DBI, overridden by CXGN::CDBI::Class::DBI
	#don't use prepare_cached here, because the (big) result set will also be cached!
	my $sth = $dbh->prepare("$data_query $lim_sql");
	warn __PACKAGE__.": executing query\n$data_query $lim_sql\n" if $this->debug;
	$sth->execute(@bindvals);
	$results->push( $this->return_class->sth_to_objects($sth) );
	warn __PACKAGE__.": executed query successfully\n" if $this->debug;
      }; if($EVAL_ERROR) {
	croak "Error executing generated SQL (error was '$EVAL_ERROR')";
      }

      ## get the count of total search results ##
      $results->total_results( $this->_count_cache_lookup($count_query,\@bindvals) );
      $results->_page($query->page); #the results now contain the requested page
      #  warn ((ref $this).': query returned '.$results->total_results." results\n");

      ### cache the SearchResult object ###
      $this->_searchresult_cache_add($data_query,\%lim,$results,\@bindvals);

      ### return the search results ###
      $results;
    };

  ### set the elapsed time for this search ###
  $r->_time(Time::HiRes::time() - $start_time);

  return $r;
}

=head2 row_to_object

Defined in L<CXGN::Search::DBI::Simple>.  row_to_object() isn't used
for Class::DBI, instead we just specify the name of the class with
return_class() above.

=cut

sub row_to_object {
  Carp::cluck __PACKAGE__.": Why are you calling row_to_object?  It's not used for a CDBI search.";
}

sub DESTROY {
  my $this = shift;
  return parricide($this,our @ISA);
}

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
