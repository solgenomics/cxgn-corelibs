package CXGN::Search::WWWResult;
use strict;
use warnings;
use English;
use Carp;

#used for the default result_to_html() method below
use Data::Dumper;

use CXGN::Page::FormattingHelpers qw/blue_section_html commify_number/;

=head1 NAME

CXGN::Search::WWWResult - a subclass of L<CXGN::Search::BasicResult> that also
implements the L<CXGN::Search::WWWResultI> interface.

=head1 USING THIS

Make your Result class a child of this one, and override
the result_to_html() method to make it better.  You may also
want to override to_html(), to organize the HTML better or something.

=head1 BASE CLASS(ES)

  L<CXGN::Search::BasicResult>
  L<CXGN::Search::WWWResultI>

=cut

use base qw/CXGN::Search::BasicResult  CXGN::Search::WWWResultI/;

=head1 METHODS

=head2 to_html

See L<CXGN::Search::WWWResultI> for specification.

=cut

#just make a concatenated string of all the current_result_htmls
sub to_html {
  my ($this) = @_;
  my $ret_html = '';

  $this->reset_result; #reset result iterator

  while(my $rh = $this->next_result_html) {
    $ret_html .= $rh;
  }
  $ret_html .= $this->_search->pagination_buttons_html( $this->_query, $this);
#  return $ret_html;
   return blue_section_html('Search Results',
			   $ret_html);
}

=head2 next_result_html

See L<CXGN::Search::WWWResultI> for specification.

=cut

sub next_result_html {
  my $this = shift;
  my $res = $this->next_result
    or return;
  return $this->result_to_html( $res );
}

=head2 current_result_html

See L<CXGN::Search::WWWResultI> for specification.

=cut

sub current_result_html {
  my ($this) = @_;
  return $this->result_to_html( $this->current_result );
}

=head2 result_to_html

  Usage: my $html = $result->result_to_html($result->next_result);
         #should be equivalent to $result->next_result_html
  Desc : by default, just outputs <pre> tags with the output of Data::Dumper in them.
         You should probably override this to make it prettier.
  Ret  : string of html
  Args : the return type of this Result object, whatever that is.
  Side Effects: none

=cut

sub result_to_html {
  my $this = shift;
  my $result = shift;
  local $Data::Dumper::Maxdepth = 1;
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Terse = 1;
  return '<pre style="border: 1px solid gray">'.Dumper($result).'</pre>';
}

=head2 time_html

  Usage: my $time_string = $result->time_html
  Desc : get a string describing the number of matches and timing of this search,
  Ret  : a string
  Args : none
  Side Effects: none
  Example:  '<span class="paginate_summary">Results 1-16 of 12,672 (2.2 seconds)</span>'

=cut

sub time_html {
  my ($this) = @_;

  my $results = $this->total_results;
  my $startmatch = $this->total_results > 0
    ? $this->page * $this->page_size + 1
    : 0;
  my $endmatch = $this->total_results > $this->page_size
    ? $startmatch + $this->page_size - 1
    : $this->total_results;

  return sprintf('<span class="paginate_summary">%d - %d of %s (%0.1f seconds)</span>',
		 $startmatch,
		 $endmatch,
		 commify_number($this->total_results),
		 $this->time());
}




=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
