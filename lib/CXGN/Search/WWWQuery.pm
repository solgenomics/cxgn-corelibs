package CXGN::Search::WWWQuery;

use strict;
use base qw/  CXGN::Page::WebForm  /;

=head1 NAME

CXGN::Search::WWWQuery - Partial implementation of a CXGN search query
that may be submitted via our website.

=head1 BASE CLASSES

  L<CXGN::Page::WebForm>

=head1 SYNOPSIS

  #convert to a query string
  my $query = $websearch->new_query;
  my $link = '<a href="./somepage.pl?'
             .$query->to_query_string
             .'">search blah blah</a>';

  #do a quick_search
  $query->quick_search('mysearchterm');
  $websearch->do_search($query);

=head1 SUBCLASSES

  L<CXGN::Search::DBI::Simple::WWWQuery>

=head1 DESCRIPTION

coming soon

=head1 ABSTRACT FUNCTIONS

In addition to the functions defined in L<CXGN::Page::WebForm>,
this class also defines the following abstract methods that
must be implemented by subclasses of this class.

=head2 to_query_string

  Desc: convert this query into a GET query string for appending to a
        URL
  Args: optional hash-style list of parameters (plus page and page_size)
                 to force in the query string
  Ret : convert this query object into a URL query string (the stuff that
        goes after the question mark in a URL)
  Side Effects: none

=head2 quick_search

  Desc: checks if the given search term is in this search's domain,
        and sets up the query object to search for that term
  Args: a single search string that the user typed into the
        'quick search'/'sol search' box on the site
  Ret : the query object, or undef if the search term is not valid
  Side Effects: sets up this query for a quick search

  If quick_search returns undef, that means that the search term
  entered is not in the domain of this quick search.

=cut

use Class::MethodMaker
    abstract => [qw(
		    to_query_string
		    quick_search
		   )
		];

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
