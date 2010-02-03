package CXGN::Search::QueryI;

=head1 NAME

QueryI - Abstract interface for queries in the CXGN search framework

=head1 BASE CLASS(ES)

none

=head1 SYNOPSIS

This is an abstract class.  Do not use it directly.  Objects
that implement this interface may be used as:

    my $search = CXGN::Search::SomeSearch->new; #this is a SearchI object
    my $query = CXGN::Search::SomeSearch::Params->new; #this is a QueryI object

    my $pagenumber = 2;	      #use this for paging through result data

    $query->my_favorite_parameter("= 'blahblahblah'");
    $query->my_second_fav_parameter("> 42");
    $query->page($pagenumber);

    my $results = $search->do_search($query);

    while(my $something = $results->next_result) {
      print $something->to_string;
    }

=head1 SUBCLASSES

=over 4

=item L<CXGN::Genomic::Search::GSS::Query>

=back

=head1 DESCRIPTION

QueryI is an abstract interface to be implemented by objects that encapsulate a query to an object (implementing L<CXGN::Search::SearchI>) that conducts searches on some kind of database.  Note that this need not be an SQL database.  For example, one could use this framework to implement a BLAST search.

=head1 FUNCTIONS

=head2 new

  Desc: Make a new Query object.
  Args: none required
  Ret : a new QueryI-implementing object

  A new object is created with its requested page number set to 0.
  Pages are numbered starting with 0.

=head2 clear

  Desc: clear all parameters set on this query and reset its page number to 0
  Args: none
  Ret : undef

=head2 params

  Desc: get/set any of the query parameters supported by this object via 
        a hash argument
  Args: a hash of query parameters to set
  Ret : a hash of all of the parameters set on this object, in the same
        kind of format

  Reserved parameter names:
      "page" - reserved for setting page numbers
      "page_size" - reserved for setting the page size

  Example:
        $myquery->params( param1 => sub { "$_[0] < 12 AND $_[0] > 2" },
                          param2 => '> 34',
                        );

=head2 page

  Desc:  get/set the requested page number

  Side Effects:  if called with an argument, sets the current page number in the
                 object's internal state

=head2 page_size

  Usage: my $size = $query->page_size
  Desc : get/set the page size requested by this query.  can be overridden by the search's page size
  Args : optional new page size to set (integer > 0)
  Ret  : new page size

=head2 next_page

  Desc: Increment the requested page number.
  Ret : the new page number

  If the page number is currently not defined, sets it to 0.

=cut

use Class::MethodMaker
    abstract => [qw/

		 new

		 clear

		 params
		 page
                 page_size
		 next_page

		 /];


=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###
