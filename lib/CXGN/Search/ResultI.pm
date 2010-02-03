package CXGN::Search::ResultI;

=head1 NAME

ResultI - Abstract interface for CXGN search Result objects.

=head1 BASE CLASS(ES)

none

=head1 SYNOPSIS

This is an abstract class.  Do not use it directly.  Objects
that implement this interface may be used as:

    my $search = CXGN::Something::SomeSearch->new;
    my $query = $search->new_query;

    my $pagenumber = 2;	      #use this for paging through result data

    $query->my_favorite_parameter('blahblahblah');
    $query->my_second_fav_parameter(42);
    $query->page($pagenumber);

    my $results = $search->do_search($query);
    $results->page == $pagenumber
      or die "this should always be true";

    print $results->html($pagenumber);


=head1 SUBCLASSES

=over 4

=item L<CXGN::Genomic::Search::GSS::Result>

=back

=head1 DESCRIPTION

ResultI is an abstract interface to be implemented by objects that encapsulate results of searches on CXGN databases.

=head1 FUNCTIONS

=head2 new

  Desc: create a new Result set
  Args: search object used to generate this result,
        query object used to generate this result
  Ret : not specified

=head2 init

  Desc: initialize a new ResultI object.  Will be called by the new() method.
  Args: args for new()
  Ret : not specified

=head2 next_result

  Ret : the next return-type object in the result, or undef if there
        are no more
  Args: none
  Desc: if autopaging is off, return undef if there are no more objects
        in this page (set) of results.  if autopaging is on, return undef
        only if there are no more results at all that matched the Query.

=head2 reset_result

  Desc: reset the selected result to the first result in the current
        result set if autopage is off, or the first result in the entire
        set of matched results, if autopage is on.
  Args: none
  Ret : true on success, false on failure

=head2 current_result

  Desc: return the currently selected result in the result set.
        When called on a new result set, returns the first result in the set.
  Args: none.
  Ret : the currently selected result in the result set

=head2 autopage

  Turn on/off autopage mode.  It is off by default.

  Desc: registers the L<CXGN::Search::QueryI> and L<CXGN::Search::SearchI>
        that are being used with this result object, so that this result
        object can 'turn pages' itself, instead of you having to do it
  Args: (L<CXGN::Search::QueryI>,L<CXGN::Search::SearchI>)
            to turn autopaging on
        or (undef,undef)
            to turn autopaging off
  Ret : the L<CXGN::Search::QueryI> and L<CXGN::Search::SearchI> objects
        that have been registered as being used with this result, if
        autopaging is off, or (undef,undef) if autopaging is off

  If autopaging is off on this result object, calling next_page() will return
  undef when there are no more return objects in this Result object.

  If autopaging is on for this result object, calling next_page()
  will automatically fetch the next page of results and return the first
  result in the new page, or undef if there are no more.

=head2 page

  Desc: get the page number held by this Result object
  Args: none
  Ret : the page number currently held by this Result object

  NOTE: if this is defined, it asserts that the data from that page
        is indeed contained RIGHT NOW in this ResultI object.

=head2 push

  Desc: add data objects to the end of this result set.  Mostly
        used by the associated Search object for loading data objects
        into this Result set.
  Args: data object of the correct type for the search at hand
  Ret : the new number of results contained in the results object,
        or undef if the Result is full (contains as many results as
        its page_size will allow)

=head2 count

  Args: none
  Ret : number of return-type objects contained in this particular result
        page

=head2 total_results

  Args: none
  Ret : Total number of return-type objects matched by the query.

  If autopage is set, total_results will perform the search if necessary
  to get the total results.

=head2 page_size

  Desc: get/set the maximum number of return-type objects contained at one
        time in a page of results
  Args: optional new page size
  Ret : the current page size

=head2 time

  Usage: my $time = $result->time;
  Desc : get the time it took to fetch this result object
  Ret  : floating point number containing the elapsed time, in seconds
  Args : none
  Side Effects: none
  Example:

=cut

use Class::MethodMaker
  [ abstract => [qw/

                   new
	           init

	           next_result
	           reset_result
	           current_result

	           push

	           count
	           total_results

                   autopage
                   page
                   _page
	           page_size

		   time

	           /
		],
  ];

###
1;#do not remove
###

