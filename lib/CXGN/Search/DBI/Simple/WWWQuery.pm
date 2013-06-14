package CXGN::Search::DBI::Simple::WWWQuery;
use strict;
use Carp;

our %urlencode;
use Tie::UrlEncoder;

=head1 NAME

CXGN::Search::DBI::Simple::WWWQuery - extensions that go with
  L<CXGN::Search::Query::DBI::Simple> for converting your
  Query to and from HTML

=head1 DESCRIPTION

A L<CXGN::Search::DBI::Simple::Query>, but with additional functions
for use on the web.  A WWWQuery can serialize/deflate/encode itself
as an HTML form, then deserialize/inflate/decode itself from the
submitted results of that form.  It can also encode itself
as a query string you can append to a URL, allowing you to make
links that execute a search with specific parameters (like for a link
to the next page of search results).

=head1 SYNOPSIS

  ##### USING A WWWQuery #####

  #let's do a search and print a pre-filled HTML form so they can
  #search again
  my $search = CXGN::BogoSearch->new;
  my $query = $search->new_query;

  #process the parameters coming from the GET or POST request
  $query->from_request( $page->get_all_encoded_arguments );

  #do the search and print the results
  my $results = CXGN::BogoSearch->new->do_search($query);
  while( my $r = $results->next_result) { print $r."<br />"; }

  #search again
  print '<form action="my_page.pl">'.$query->to_html.'</form>';



  ##### SUBCLASSING WWWQuery ###

  ## first the basic search stuff

  #make a search
  package MySearch;
  use base qw/CXGN::Search::DBI::Simple/;
  __PACKAGE__->uses_query( 'MySearch::Query');
  __PACKAGE__->creates_result( 'CXGN::Search::BasicResult' );

  #and make a query
  package MySearch::Query; #and make a query
  use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

  __PACKAGE__->join_root('mytable');
  __PACKAGE__->has_parameter( name    => 'monkey_id',
                              columns => 'mytable.table_id',
                            );
  __PACKAGE__->has_parameter( name    => 'monkey_name',
                              columns => 'mytable.name',
                            );
  __PACKAGE__->selects_data( qw/ mytable.id mytable.name / );

  ## and now define some www stuff

  __PACKAGE__->template(<<EOHTML);
  Id:<input name="NAME_monkey_id" value="VALUE_monkey_id" /><br />
  Name:<input name="NAME_monkey_name" value="VALUE_monkey_name" />
  EOHTML

  #define the mapping from get/post data to search params
  sub request_to_params {
    my ($self,%r) = @_;

    $self->monkey_id('=?',$r{id}) if $r{id};
    $self->monkey_name('=?',$r{name}) if $r{name};
  }

  #and that will make a simple little web search
  #on two fields of one table

=head1 BASE CLASSES

  L<CXGN::Search::DBI::Simple::Query>
  L<CXGN::Search::WWWQuery>

=cut

use base qw/ CXGN::Search::DBI::Simple::Query  CXGN::Search::WWWQuery /;

=head1 ABSTRACT METHODS

These methods are abstract, and you will need to implement them
in your subclass.

=head2 request_to_params

  Desc: given a hash-style list of HTML form names => form values,
        fill in the search parameters in this query object from them.
        Called by from_request in L<CXGN::Search::Query::DBI::WWWSimple>.
  Args: name=>value list of data
  Ret : uspecified
  Side Effects: fill in the internal state of this query object
  Example:

=head1 RECOMMENDED TO OVERRIDE

=head2 to_html

You can use L<CXGN::Page::WebForm>'s simple templating implementation
of this, if you want, but you'll probably want to override it with your
own.  For example, you can't fill in select boxes correctly with that
one.

  Usage: my $html = $query->to_html
  Desc : convert this query to a filled-in html form
  Ret  : string of html
  Args : none
  Side Effects: none

=head1 PROVIDED METHODS

These methods are provided in this class.  You might want to override some of them.

=head2 _to_scalars

  Desc: method to distill this query object into a hash of simple scalar
        variables for the purposes  of using these values in an HTML form
        or URL query string
  Args: none
  Ret : hash of (variable name => value, variable name => value, ...)
  Side Effects: none

The implementation provided in this class simply returns unmodified
data set gotten from the Apache request.

=cut

sub _to_scalars {
  shift->_data;
}

=head2 to_query_string

This function is specified in L<CXGN::Search::WWWQueryI> and L<CXGN::Search::WWWQuery>.

  Desc: convert this query object into a URL query string
  Args: optional hash-style list of parameter values to force in the query
        string, most useful probably being 'page' and 'page_size'
  Ret : this query object in the form of a query string,
        usable in an HTML link.

  Calls method _to_scalars().

  Example:

    $query->id('=?',42);
    $query->name('=?','Cheetah');
    $query->page(2);
    my $qstr = $query->to_query_string;
    #should probably return something like 'id=42&name=Cheetah&page=2'

=cut

sub to_query_string {
  my $this = shift;
  my %force = @_;

  my %scalars = $this->_to_scalars;
  $scalars{page_size} = $this->page_size if $this->page_size_isset;
  while( my ($k,$v) = each %force) {
    $scalars{$k} = $v;
  }
  join '&', (map { $this->uniqify_name($_).'='.$urlencode{$scalars{$_}} } (grep {defined($scalars{$_})} keys %scalars) );
}

=head2 from_request

  Desc: deserialize this object from a set of passed parameters
  Args: ref to a hash of parameters
  Ret : unspecified

  Implementation of this is basically:
  - does clear() on this object
  - calls SUPER::from_request to get the parameters that belong to
    us out of the request hash
  - calls request_to_params(), specified above as abstract,
    with the (de-uniqified) parameters from the request

=cut

sub from_request {

  my ($this,$mungedparams) = @_;

  $this->clear(); #clear this query of everything

  ref $mungedparams eq 'HASH'
    or croak 'Argument to from_request must be a hash ref (got a '.(ref $mungedparams).')';

  $this->SUPER::from_request($mungedparams);
  $this->request_to_params( $this->_data );
}

=head1 ADDITIONAL METHODS

These methods are new to this class, they are not specified further up
the inheritance hierarchy.  Many of these are helpful when you're
constructing your own web searches.

=head2 param_bindvalues

  Usage: my @bindvals = $this->param_bindvalues('unigene_id');
  Desc : get the bind values set on this parameter
  Ret  : array of bind values, or undef if param of that name is not set
  Args : none
  Side Effects:
  Example:

=cut

sub param_bindvalues {
  my ($this,$paramname) =  @_;

  my $param_record = $this->param_index($paramname)
    or return;

  my ($id_string,@bindvals) = @$param_record;

  return @bindvals;
}


=head2 param_to_string

  Desc: gets the currently set value of a query parameter as a string
  Args: parameter name
  Ret : in list context:
        (stringified version of the parameter - basically what you
         would get if the parameter value expression was an empty string,
         plus the bind values associated with it, if any)
        in scalar context: just the string
  Side Effects: none
  Example:

      my ($unigene_id) = $this->param_to_string('unigene_id') =~ /(\d+)/;

      #note that this operation is basically what's done by
      #pattern_match_parameter() below

=cut

sub param_to_string {
  my ($this,$paramname) = @_;

  my $param_record = $this->param_index($paramname)
    or return;

  my ($id_string,@bindvals) = @$param_record;

  $id_string = $id_string->('') if ref $id_string eq 'CODE';
  return ($id_string,@bindvals) if wantarray;
  return $id_string;
}

=head2 pattern_match_parameter

  NOTE: it's best to use bind values for parameters if you can.
        easier code, better security, etc.
        only use this function for recovering things like 'IS NOT NULL'
        or '!= 0'.  For other things, use param_bindvalues() above.

  Desc: extract a scalar value from a stringified
        parameter setting with a regular expression
  Args: parameter name, quoted regular expression
  Ret : results of the pattern match, in list context,
        or an empty list if that parameter has not been set
  Side Effects: none
  Example:

=cut

sub pattern_match_parameter {
  my ($this,$paramname,$qr) = @_;
  my $val = $this->param_to_string($paramname);
  return (defined $val) ? ($val =~ $qr) : ();
}

=head2 ranged_parameter_from_scalars

  Desc: set the given query parameter with an SQL snippet
        constructed from the three given scalar values.
        Often used with output from form elements made with
        L<CXGN::Page::FormattingHelpers> numerical_range_input_html
  Args: (param name, range scalar value, value 1, value 2)
  Ret : unspecified
  Side Effects: sets the given query parameter in this query object
  Example:

=cut

sub ranged_parameter_from_scalars {
  no strict 'refs';		#using symbolic refs here
  my ($this,$paramname,$range,$v1,$v2) = @_;

  return unless length $v1; #< if $v1 has no string length, we're just setting empty strings

  if ($range eq 'gt' && length $v1) {
    $this->$paramname(" > ?",$v1);
  } elsif ($range eq 'lt' && length $v1) {
    $this->$paramname(" < ?",$v1);
  } elsif ($range eq 'bet') {
    croak "second param must be provided if range is 'bet'!"
      unless length $v2;
    $this->$paramname("&t > ? AND &t < ?",$v1,$v2);
  } elsif ($range eq 'eq') {
    $this->$paramname("= ?",$v1);
  } else {
    die "Invalid range type for $paramname";
  }
}

=head2 ranged_parameter_to_scalars

  Desc: convert a ranged parameter (>,<,=) in your query object to
        three scalars
  Args: parameter name
  Ret : (range setting, value 1, value 2)
      Where range setting is one of
     'bet', 'gt', 'lt', 'eq'
  Side Effects:
  Example:

    my ($range,$estlen1,$estlen2) =
       $this->ranged_parameter_to_scalars('estimated_length');

=cut

sub ranged_parameter_to_scalars {
  my ($this,$paramname) = @_;
  #convert estimated length expressions to scalars
  my ($str,$v1,$v2) = $this->param_to_string($paramname);
  my $range =
    !defined($v1) ? undef :
    defined($v2)  ? 'bet' :
    $str =~ />/   ? 'gt'  :
    $str =~ /</   ? 'lt'  :
    $str =~ /=/   ? 'eq'  :
	            undef;
  ($range,$v1,$v2);
}

=head2 conditional_like_from_scalars

  Usage: $this->conditional_like_from_scalars
            ('locus_name',
             @scalars{qw/locus_name_matchtype locus_name/}
            );
  Desc : set a 'conditional-like' parameter in your object,
         from two scalars.  This method and its 'to_scalars' mate
         go well with the conditional_like_input_html() method
         in L<CXGN::Page::FormattingHelpers>
  Ret  : nothing meaningful
  Args : name of the parameter to set in your object,
         value of the scalar that holds the type of match to make,
         value of the scalar that holds the string to match against
  Side Effects: sets the given parameter in this object

=cut

sub conditional_like_from_scalars {
  my ($self,$paramname,$matchtype,$matchstring) = @_;
  no strict 'refs';		#using symbolic refs here

  if ($matchtype eq 'starts_with') {
    $self->$paramname('ILIKE ?',"$matchstring%");
  } elsif ($matchtype eq 'ends_with') {
    $self->$paramname('ILIKE ?','%'.$matchstring);
  } elsif ($matchtype eq 'contains') {
    $self->$paramname('ILIKE ?','%'.$matchstring.'%');
  } elsif ($matchtype eq 'exactly') {
    $self->$paramname('ILIKE ?',"$matchstring");
  } else {
    die "Invalid match type '$matchtype' for $paramname";
  }
}

=head2 conditional_like_to_scalars

  Usage: my ($matchtype,$string) =
           conditional_like_to_scalars('locus_name');
  Desc : convert a 'conditional-like' parameter in your object
         to two scalars, a match type and a matching string
  Ret  : a match type, which is one of
           qw/ starts_with  ends_with  contains  exactly /,
         and a match string, which is just some string
  Args : the parameter name in your object
  Side Effects: none

=cut

sub conditional_like_to_scalars {
  my ($self,$paramname) = @_;
  my ($str) = $self->param_bindvalues($paramname);
  my $matchtype =
    !defined($str)   ? undef         :
    $str =~ /^%.+%$/ ? 'contains'    :
    $str =~ /^%/     ? 'ends_with'   :
    $str =~ /%$/     ? 'starts_with' :
	               'exactly';
  $str =~ s/^%|%$//g; #remove sql wildcards
  ($matchtype,$str);
}


=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
