package CXGN::Searches::People::Query;
use strict;
use English;
use Carp;

use Tie::Function;
our %urlencode;
use Tie::UrlEncoder;
use CXGN::DB::Connection;
use CXGN::DB::Physical;
use CXGN::Tools::Class qw/parricide/;
use CXGN::Tools::List qw/any/;
use CXGN::Tools::Text;
use CXGN::Page::FormattingHelpers qw/simple_selectbox_html
					html_optional_show
					info_table_html
					hierarchical_selectboxes_html
					numerical_range_input_html
					commify_number
					/;

use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

=head1 NAME

CXGN::Searches::People::Query - query for L<CXGN::Searches::People>.

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::Simple::WWWQuery>

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

=over 4

=item none yet

=back

=head1 DESCRIPTION

coming soon

=head1 NORMAL QUERY PARAMETERS (FUNCTIONS)

These are query parameters that act in the normal way defined by
L<CXGN::Search::QueryI>.

=cut

=head1 AUTHOR(S)

    Evan Herbst (adapted from ...Clone::Query by Robert Buels)

=cut

#fields returned by the query, in the order in which they'll be returned
my @_person_fields = ('first_name', 'last_name', 'contact_email', 'organization', 'country', 'research_interests', 'research_keywords', 'sp_person_id','censor');

sub _cached_dbh {
  our $_cached_dbc ||= CXGN::DB::Connection->new('sgn_people');
}


#package configuration
my $sgn_people = 'sgn_people';
__PACKAGE__->selects_data(map {"$sgn_people.sp_person.$_"} @_person_fields);
__PACKAGE__->join_root("$sgn_people.sp_person");

#set up parameters for each of the sp_person table fields
foreach my $param (@_person_fields) {
  __PACKAGE__->has_parameter(name => "$param", columns => "$sgn_people.sp_person.$param");
}

#set up a parameter that searches last and first name for use in quick search
__PACKAGE__->has_parameter( name => 'lower_name',
			    columns => ["$sgn_people.sp_person.first_name","$sgn_people.sp_person.last_name"],
			    sqlexpr => "lower($sgn_people.sp_person.first_name || ' ' || $sgn_people.sp_person.last_name)"
			  );

=head2 quick_search

Specified in L<CXGN::Search::WWWQueryI>.

=cut

sub quick_search {
  my ($this, $search_string) = @_;
  my @tokens = map lc, split /\s+/,$search_string;

  if( any map /,/, @tokens ) {
    @tokens = reverse @tokens;
  }
  s/[^A-Za-z]//g foreach @tokens;

  my $name_str = join ' ',@tokens;
  #warn "NOW SEARCHING WITH '$name_str'\n";
  $this->lower_name('like ?', "\%$name_str\%");
  $this->censor("=?", 0);
  return $this;
}

=head2 _remove_enclosing_percents

Remove the percent signs that may have been put on bindvalues given to DBI, since DBI would rather see
$this->param("ilike ?", "%$param%")
than
$this->param("ilike '%?%'", $param)

-- Evan

Args: list of strings with or without surrounding percents
Ret: list of strings without surrounding percents

Arguments are not destroyed.

=cut

sub _remove_enclosing_percents
{
	my @copy = @_;
	foreach (@copy)
	{
		s/^%?(([^%].*[^%])|[^%])%?$/$1/;
	}
	return @copy;
}

=head2 _to_scalars

  Desc: method to distill this query object into a hash of simple scalar
        variables for the purposes  of using these values in an HTML form
        or URL query string
  Args: none
  Ret : hash of (variable name => value, variable name => value, ...)
  Side Effects: none
  
Needed for quicksearch to work. -- Evan

=cut

sub _to_scalars
{
	my ($this) = @_;
	
	my %scalars;

	#take out the percent signs postgres uses in LIKE statements, if they're on the bindvalues; these fields will probably never contain percents
	foreach my $pn (qw( first_name last_name lower_name organization country research_keywords research_interests) ) {
	  ($scalars{$pn}) = _remove_enclosing_percents($this->param_bindvalues($pn)) if $this->param_bindvalues($pn);
	}

	$scalars{page} = $this->page;

	return %scalars;
}

=head2 request_to_params

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

sub request_to_params
{
  my ($this, %request) = @_;

  #sanitize all the parameters
  foreach my $key (keys %request)
  {
    if( $request{$key} )
	 {
      $request{$key} = CXGN::Tools::Text::trim($request{$key});
      $request{$key} =~ s/[;'",]//g;
    }
  }

  #ILIKE is PostgreSQL-specific
  if( $request{lower_name} ) {
    $this->lower_name('ilike ?',"%$request{lower_name}%");
  }
  if ($request{first_name}) {
    $this->first_name(" ILIKE ?", "%$request{first_name}%");
  }
  if ($request{last_name}) {
    $this->last_name(" ILIKE ?", "%$request{last_name}%");
  }
  if ($request{organization}) {
    $this->organization(" ILIKE ?", "%$request{organization}%");
  }
  if ($request{country}) {
    $this->country(" ILIKE ?", "%$request{country}%");
  }
  if ($request{research_interests}) {
    $this->research_interests(" ILIKE ?", "%$request{research_interests}%");
  }
  if ($request{research_keywords}) {
    $this->research_keywords(" ILIKE ?", "%$request{research_keywords}%");
  }

  #page number
  if (defined $request{page}) {
    $this->page($request{page});
  }
  
  $this->censor("!=1");
  
  #auxiliary SQL stuff
  if ($request{sortby}) {
    $this->order_by($request{sortby} => 'ASC'); #it must be defined; it's a drop-down menu
  } else {
    $this->order_by(last_name => 'ASC');
  }
}

#html for the query form
sub to_html
{
	my $this = shift;
	
	#parameters need to be uniqified in the html form so they can be deuniqified and recognized later as belonging to this specific query class
	my $first_name = $this->uniqify_name('first_name');
	my $last_name = $this->uniqify_name('last_name');
	my $organization = $this->uniqify_name('organization');
	my $country = $this->uniqify_name('country');
	my $research_interests = $this->uniqify_name('research_interests');
	my $research_keywords = $this->uniqify_name('research_keywords');
	my $sortby = $this->uniqify_name('sortby');
	
	#the 'value=$scalars{paramname}' bit is meant to autofill the 'search again' form, which Lukas considers a feature -- Evan
	my %scalars = $this->_to_scalars();
	my ($order_by_param) = $this->order_by(); #take the first key of the returned hash -- make sure we're in list context
	#autofill stuff for the sort-by options
	my %selected;
	foreach my $sort_option (qw(last_name organization country))
	{
		if($order_by_param eq $sort_option)
		{
			$selected{$sort_option} = "selected=\"selected\"";
		}
		else
		{
			$selected{$sort_option} = "";
		}
	}
	return <<EOHTML;
This page allows you to search a user-managed database of researchers interested in Solanaceae biology. You can add yourself using the add/modify link below. Please search the database before adding your information, because you may already be in the database.
<br /><br />
<table width="600" border="0">
	<tr>
		<td>
			<a href="/solpeople/login.pl">[Add/modify your information]</a>
			<br /><br />
			<b>Search criteria</b>
			<br /><br />
			<center>
			<table border="0">
				<tr>
					<td>First name:</td>
					<td><input type="text" name="$first_name" value="$scalars{first_name}" /></td>
				</tr>
				<tr>
					<td>Last name:</td>
					<td><input type="text" name="$last_name" value="$scalars{last_name}" /></td>
				</tr>
				<tr>
					<td>Organization:</td>
					<td><input type="text" name="$organization" value="$scalars{organization}" /></td>
				</tr>
				<tr>
					<td>Country:</td>
					<td><input type="text" name="$country" value="$scalars{country}" /></td>
				</tr>
				<tr>
					<td>Interests:</td>
					<td><input type="text" name="$research_interests" value="$scalars{research_interests}" /></td>
				</tr>
				<tr>
					<td>Keywords:</td>
					<td><input type="text" name="$research_keywords" value="$scalars{research_keywords}" /></td>
				</tr>
			</table>
			</center>
			<br /><br />
			Sort results by
			<select name="$sortby">
				<option value="last_name" $selected{last_name}>last name</option>
				<option value="organization" $selected{organization}>organization</option>
				<option value="country" $selected{country}>country</option>
			</select>
			<br /><br />
			<input type="reset" value="Reset" />
			&nbsp; &nbsp; &nbsp;<input type="submit" value="Search" />
		</td>
	</tr>
</table>
<br /><br />
EOHTML
}

###
1;#do not remove
###
