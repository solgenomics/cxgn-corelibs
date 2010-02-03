package CXGN::Search::WWWSearch;

use strict;
use POSIX;
use CXGN::Tools::List qw/distinct/;
use CXGN::Page::FormattingHelpers qw/commify_number simple_selectbox_html/;
use UNIVERSAL qw/isa/;
use Carp;

use base qw/ CXGN::Search::WWWSearchI /;

=head1 NAME

WWWSearch - Partial implementation of a CXGN search used on our website.

=head1 BASE CLASSES

  L<CXGN::Search::WWWSearchI>

=back

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

coming soon

=head1 DESCRIPTION

coming soon

=head1 ADDITIONAL FUNCTIONS

=head2 pagination_buttons_html

  Desc: given the Query and Result object this is being used with,
        make some HTML pagination controls
  Args: Query object, and latest Result object, (optional) URI of search page to link to
  Ret : html that produces a set of links for paging through the results
        of a search

  Perhaps this function could become part of the official interface, but I'm not sure
  if all possible web searches would need pagination.

=cut

sub pagination_buttons_html {
  my ($this,$query,$result,$linkpage) = @_;
  $linkpage ||= ''; #a blank link page is OK, will go to current page

  isa($this,__PACKAGE__)
    and isa($query,'CXGN::Search::WWWQuery')
      and isa($result,'CXGN::Search::ResultI')
	or croak "arguments to pagination_buttons_html must be the query object, then the result object, then an optional page URI to link to";

  my $pagesize = $this->page_size; #number of results in a page
  my $totalresults = $result->total_results; #total results from the query

  return '' if $pagesize >= $totalresults;

  #page numbers of this page, prev page, and next page
  my $currpage = $query->page;
  my $nextpage = $pagesize * ($currpage+1) < $totalresults ? $currpage + 1 : undef;
  my $prevpage = ($currpage > 0) ? $currpage - 1 : undef;

  sub escape_amps(@) {
    my @r = map { my $s = $_; $s =~ s/&(?!>amp;)/&amp;/g; $s } @_;
    return wantarray ? @r : $r[0];
  }

  #make query strings that repeat this search at the previous page
  #and the next page
  my $prevqs = escape_amps $query->to_query_string(page => $prevpage);
  my $nextqs = escape_amps $query->to_query_string(page => $nextpage);

  #make the HTML that will draw the previous and next page links
  my $prevhtml = defined $prevpage ? qq{<a class="paginate_nav" href="$linkpage?$prevqs">&lt;</a>} : '';
#    qq{<span class="paginate_nav_ghosted">&lt;&lt;</span>};
  my $nexthtml = defined $nextpage ? qq{<a class="paginate_nav" href="$linkpage?$nextqs">&gt;</a>} : '';
#    qq{<span class="paginate_nav_ghosted">&gt;&gt;</span>};

  #if more than 2 pages, make a series of page numbers that are direct links to that page
  #  figure out the limits of the window: page + 9 and page - 10
  my $number_links = do {
    #would use List::Util::max here, but it doesn't work on OSX!
    my $min  = ( 0 > $currpage-10 ? 0 : $currpage-10 );
    my $last = ceil($totalresults/$pagesize)-1;
    my $max  = $last > $currpage+9 ? $currpage+9 : $last;
    my @links = map { my $qs = escape_amps $query->to_query_string(page => $_);
		      my $printnum = $_+1;
		      $_ == $currpage
                        ? qq{<span class="paginate_nav_currpage">$printnum</span>}
			: qq{<a class="paginate_nav" href="$linkpage?$qs">$printnum</a>}
		    } ($min..$max);
    join('&nbsp;',@links);
  };

  #make the string describing where in the search we are
  my ($page_end) = sort {$a<=>$b} ($pagesize*($currpage+1),$totalresults); #minimum
  my $descstring = 'results '.($totalresults ? $pagesize*$currpage+1 : 0)." to $page_end of ".(commify_number($totalresults) || 0);

  return <<EOHTML;
<div class="paginate_nav">
  $prevhtml&nbsp;$number_links&nbsp;$nexthtml
</div>
EOHTML
}

=head2 page_size_control_html

  Usage: my $page_size = $search->page_size_control_html($query);
  Desc : get an HTML control to change the page size for displaying
         search results on a web page
  Args : query object to use, latest Result object,
         (optional) URI of search page to link to
  Ret  : HTML string, with some embedded javascript

=cut

sub page_size_control_html {
  my ($self,$query,$result,$linkpage) = @_;
  $linkpage ||= '';

  my $currsize = $self->page_size;
  my $currpage = $query->page;
  my $currqs   = $query->to_query_string(page_size => $currsize);

  return simple_selectbox_html( choices =>
				[
				 map {
				   my $size = $_;
				   my $new_pagenum = transform_page_number($currpage,$currsize,$size);
				   my $link = escape_amps $query->to_query_string(page => $new_pagenum, page_size => $size);
				   [$link,$size]
				 } distinct sort {$a <=> $b} 10, 20, 50, 100, 200, 500, $currsize || ()
				],
				selected => escape_amps $currqs,
				params  => { onchange => "location = '$linkpage?'+this.value" },
			      );
}

#given an old page size, a new page size, and a page number,
#return the page number that will show roughly the same
#data for the new page size
sub transform_page_number {
  my ($pagenum,$old_size,$new_size) = @_;

  return floor($pagenum*$old_size/$new_size);
}



=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###
