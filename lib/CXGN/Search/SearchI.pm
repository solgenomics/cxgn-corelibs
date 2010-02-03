package CXGN::Search::SearchI;

=head1 NAME

CXGN::Search::SearchI - Abstract interface for CXGN Search objects.

=head1 BASE CLASS(ES)

none

=head1 SYNOPSIS

This is an abstract class.  Do not use it directly.  Objects
that implement this interface may be used as:

    my $search = CXGN::Search::SomeSearch->new;
    my $query = CXGN::Search::SomeSearch::Query->new;

    #somehow set up your search on the query object
    $query->set_up_query_parameters_somehow_or_other;

    my $results = $search->do_search($query);

    while(my $any_kind_of_object = $results->next_result) {
      print $any_kind_of_object->to_string;
    }

=head1 SUBCLASSES

  L<CXGN::Search::DBI::Simple>
  L<CXGN::Search::DBI::CDBI> (subclass of Simple)

=head1 DESCRIPTION

SearchI is an abstract interface to be implemented by objects that conduct searches on CXGN databases.
Note that the way in which parameters are set on the query object is not specified here.

=head1 FUNCTIONS

=head2 new

  Desc: Make a new search object.
  Args: none required
  Ret : a new SearchI-implementing object

=head2 do_search

  Desc: Execute the search that the (derived from this) object is implementing.
  Args: An object that implements CXGN::Search::QueryI
  Ret : An object implementing CXGN::Search::ResultI

=head2 do_count

  Desc: Execute the search that the (derived from this) object is implementing,
        but only count the results, don't fetch them, create objects, or buffer
        them.
  Args: An object that implements CXGN::Search::QueryI
  Ret : An object implementing CXGN::Search::ResultI

=head2 new_query

  Desc: return a new query object of the appropriate type for use with this
        search
  Ret:  a new query object

=cut

use Class::MethodMaker
    abstract => [qw/
		    new
		    do_search
		    new_query
		   /];

=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###

