package CXGN::Search::BasicResult;
use strict;
use Carp;
use UNIVERSAL qw/isa/;
use base qw/CXGN::Search::ResultI/;

=head1 NAME

CXGN::Search::BasicResult - basic search result object partially
                            implementing L<CXGN::Search::ResultI>.

                            This is a partial implementation mean to be used
                            as a base class.

=head1 BASE CLASS(ES)

=over 4

=item L<CXGN::Search::ResultI>

=back

=head1 SYNOPSIS

  coming soon

=head1 SUBCLASSES

=over 4

=item L<CXGN::Genomic::Search::GSS::Result>

=back

=head1 DESCRIPTION

CXGN::Search::BasicResult is the bare bones of a search result class,
providing facilities for keeping and iterating through a set of returned
data objects (e.g. sequence objects, person objects, whatever).

=head1 FUNCTIONS

Implements all functions specified in L<CXGN::Search::ResultI>.

=cut

use Class::MethodMaker
  [ new    => [qw/ -init new /],
    scalar => [qw/_page _time/,
	       +{ -type => 'CXGN::Search::SearchI' }, '_search',
	       +{ -type => 'CXGN::Search::QueryI'  }, '_query',
	      ],
  ];

sub init {
  my $this = shift;
  my $search = shift;
  my $query = shift;

  $this->{_objs} = [];
  $this->reset_result;
  $this->_search($search);
  $this->_query($query);
  1;
}

sub next_result {
  my ($this) = @_;
  my $res = $this->current_result;

  my ($ap_query,$ap_search) = $this->autopage;

  if( ! defined($res) && $ap_query && $ap_search ) {
    #if we have no current result
    #and we are autopaging

    my $pagesize = $this->page_size;
    my $page = $this->page;
    #we turn to the next page IF:
    if( defined($pagesize) && $this->count >= $pagesize   #  either this page is full
	|| ! defined($page)                               #  OR we have not yet loaded the first page
      ) {
#       warn "***next_result running autopage_search page=".$ap_query->page."\n";
#       warn "current result is ".$this->current_result.", pagesize $pagesize, page $page, count ".$this->count."\n";
      $ap_query->next_page;
#      warn "***next_result new page is ".$ap_query->page."\n";
      $this->_perform_autopage_search;
    }
    $res = $this->current_result; #load the first result from the new page
  }

  $this->{_iter}++ if $res;

  return $res;
}

#args: none
#ret: undef
#if autopage has been set, performs the search.
sub _perform_autopage_search {
  my ($this) = @_;

  my ($ap_query,$ap_search) = $this->autopage;

  $|= 1;
#  warn "**performing autopage search, page=".$ap_query->page."\n";

  die 'cannot perform search if autopage not set'
    unless $ap_query && $ap_search;

  #get a new result object with new data from the search obj
  my $new = $ap_search->do_search($ap_query);
#   use Data::Dumper;
#  $Data::Dumper::Maxdepth = 2;
#   warn "Old result:\n",Dumper($this),"new result:\n",Dumper($new);
  %$this = %$new;
#  warn "replaced result:\n",Dumper($this);

  #restore the modal state into the new object
  $this->autopage($ap_query,$ap_search);

  undef;
}

## reset the results iterator
sub reset_result {
  my ($this) = @_;

  $this->{_iter} = 0;

  1;
}

## get the current result
sub current_result {
  my ($this) = @_;

  return undef if $this->{_iter} >= $this->page_size;

  return $this->{_objs}[$this->{_iter}];
}

#get/set autopage properties (see docs in ResultI)
sub autopage {
  my ($this,$query,$search) = @_;

  if($query || $search) {     #IF SETTING
    isa($query,'CXGN::Search::QueryI')
	or croak "Passed query must be a subclass of CXGN::Search::QueryI (you passed a '".ref($query)."')";
    isa($search,'CXGN::Search::SearchI')
	or croak "Passed search must be a subclass of CXGN::Search::SearchI (you passed a '".ref($search)."')";
    return (@{$this->{_autopage}}{qw/query search/} = ($query,$search));


  } else {     #IF GETTING
    if(exists($this->{_autopage}->{query})) {
      isa($this->{_autopage}->{query},'CXGN::Search::QueryI')
	  or die "Internally stored autopage query is not a CXGN::Search::QueryI (it is a a '".ref($query)."')";
    }
    if(exists($this->{_autopage}->{search})) {
      isa($this->{_autopage}->{search},'CXGN::Search::SearchI')
	  or die "Internally stored autopage search is not a CXGN::Search::SearchI (it is a a '".ref($search)."')";
    }
    return @{$this->{_autopage}}{qw/query search/};
  }
}

sub push {
  my $this = shift;

  return if length(@{$this->{_objs}}) == $this->page_size;

  push @{$this->{_objs}},@_;

  return scalar(@{$this->{_objs}});
}

sub count {
  my ($this) = shift;
  return scalar(@{$this->{_objs}});
}

sub page_size {
  my ($this,$size) = @_;

  if(defined($size)) {
    ### range check ###
    $size > 0 or croak 'Page size must be greater than 0';

    $this->{_pagesize} = $size;
  }
  $this->{_pagesize};
}

sub page {
  my $this = shift;
  @_ and croak "page() is a read-only accessor, it takes no arguments";
  $this->_page;
}

sub total_results {
  my ($this,$newres) = @_;

  if(defined($newres)) {
    $this->{_total_results} = $newres;
  } elsif( !defined($this->{_total_results}) ) {
    my ($query,$search) = $this->autopage;
    if($query && $search) {

      $query->page(0)
	unless defined($query->page);

#      warn "***total_results running the autopage search\n";
      $this->_perform_autopage_search;
    } else {
      croak "Total results not yet available, you must set the total results of set autopage first.\n";
    }
  }

  $this->{_total_results};
}

sub time {
  shift->_time;
}

# NOTE: sub _page, _search, and _query are implemented by Class::MethodMaker
# see 'use Class::MethodMaker' above

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
