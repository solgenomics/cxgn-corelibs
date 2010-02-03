package CXGN::Search::WWWResultI;

=head1 NAME

CXGN::Search::WWWResultI - interface specification for a Result object that
knows how to transform its results into HTML.

=head1 ABSTRACT METHODS

=head2 to_html

  Usage: my $html = $results->to_html
  Desc : make a nice HTML display of this page of results, including links for paging through the results
  Ret  : a string of HTML and maybe some embedded javascript
  Args : none
  Side Effects: none

=head2 next_result_html

  Usage: my $html = $results->next_result_html
  Desc : same as next_result(), except returns an HTML representation of the object
  Ret  : string of html
  Args : none
  Side Effects: none

=head2 current_result_html

  Usage: my $html = $results->current_result_html
  Desc : same as current_result(), except it returns an HTML representation of the object
  Ret  : string of html
  Args : none
  Side Effects: none

=cut

use Class::MethodMaker
  abstract => [qw/
		  to_html
		  next_result_html
		  current_result_html
		 /];

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
