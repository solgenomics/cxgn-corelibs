package CXGN::Searches::Library::Query;
use strict;
use English;
use Carp;

use Tie::Function;
our %urlencode;
use Tie::UrlEncoder;
use CXGN::DB::Connection;
use CXGN::DB::Physical;
use CXGN::Tools::Class qw/parricide/;
use CXGN::Tools::Text;
use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

=head1 NAME

CXGN::Searches::Library::Query - query for L<CXGN::Searches::Library>.

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::Simple::WWWQuery>

=head1 SYNOPSIS

coming soon

=cut

=head1 AUTHOR(S)

    Evan Herbst

=cut

#the fields the search should return from different tables
my @library_fields = qw(library_id library_name library_shortname development_stage authors comments cultivar tissue);
my @organism_fields = qw(organism_name);

sub _cached_dbh()
{
	my $schema = "sgn";
	our $_cached_dbc ||= CXGN::DB::Connection->new($schema);
}

#package configuration
my $sgn = 'sgn';
my @qualified_fields = map {"$sgn.library.$_"} @library_fields;
push @qualified_fields, map {"$sgn.organism.$_"} @organism_fields;
__PACKAGE__->selects_data(@qualified_fields);
__PACKAGE__->join_root("$sgn.library");
__PACKAGE__->uses_joinpath('organism', ["$sgn.organism", "$sgn.organism.organism_id = $sgn.library.organism_id"]);
foreach my $param (@library_fields)
{
	if($param eq "library_id") #a hack, but I do like to be able to use loops -- Evan
	{
		__PACKAGE__->has_parameter(name => "$param", columns => "$sgn.library.$param", sqlexpr => "distinct $sgn.library.$param");
	}
	else
	{
		__PACKAGE__->has_parameter(name => "$param", columns => "$sgn.library.$param");
	}
}
foreach my $param (@organism_fields)
{
	__PACKAGE__->has_parameter(name => "$param", columns => "$sgn.organism.$param");
}

=head2 _preprocess_search_string

Call before a quick search or a regular search. NOT a class function.

Desc: replace some common organism names with the names found in the database
Args: search string
Ret: processed string

=cut

sub _preprocess_search_string
{
	my $term = shift;
	chomp($term);
	#replace some common organism names with useful query terms
	$term =~ s/tomato/lycopersicon/i;
	$term =~ s/potato/solanum tuberosum/i;
	$term =~ s/eggplant/solanum melongena/i;
	$term =~ s/pepper/capsicum/i;
	return $term;
}

=head2 quick_search

Specified in L<CXGN::Search::WWWQueryI>.

=cut

sub quick_search
{
	my ($this, $search_string) = @_;
	return unless $search_string =~ /^[a-zA-Z _-]+$/;
	$search_string = _preprocess_search_string($search_string);
	$this->library_parameters("ilike ?", "%$search_string%");
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
	
	#convert quicksearch parameters to the parameters the regular search wants; we only need to process one parameter name, since 
	#all the parameters used by the quicksearch are given equal values
	
	my %scalars;
	#take out the percent signs postgres uses in LIKE statements, if they're on the bindvalues; these fields will probably never contain percents
	($scalars{library_parameters}) = _remove_enclosing_percents($this->param_bindvalues('library_name')) if $this->param_bindvalues('library_name');
	
	$scalars{page} = $this->page;
	return %scalars;
}

sub library_parameters {
    my ($this, @args) = @_;
    
    #ILIKE is PostgreSQL-specific
    $this->library_name(@args);
    $this->library_shortname(@args);
    $this->development_stage(@args);
    $this->tissue(@args);
    $this->authors(@args);
    $this->comments(@args);
    $this->cultivar(@args);
    $this->organism_name(@args);
    $this->compound("&t or &t or &t or &t or &t or &t or &t or &t", "library_name", "library_shortname", "development_stage", "tissue", 
		    "authors", "comments", "cultivar", "organism_name");
    $this->order_by("library_shortname" => "ASC");
}

=head2 request_to_params

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

    sub request_to_params {
    my ($this, %request) = @_;
	
    #sanitize all the parameters
    foreach my $key (keys %request) {
       if($request{$key}) {
	  $request{$key} = CXGN::Tools::Text::trim($request{$key});
	  $request{$key} =~ s/[;'",\\]//g;
	  }
       }
	
       if($request{library_parameters}) {
          $this->library_parameters('ILIKE ?',"%$request{library_parameters}%");
       }
	
       #page number
       if(defined $request{page}) {
	$this->page($request{page});
       }
}

#html for the query form
sub to_html
{
	my $this = shift;
	my %scalars = $this->_to_scalars();
	
	#parameters need to be uniqified in the html form so they can be deuniqified and recognized later as belonging to this specific query class
	my $term = $this->uniqify_name('library_parameters');
	
	return <<EOHTML;
  <br />
  Find EST libraries by keyword, e.g. library name, organism, tissue, development stage, or authors. 
  <br /><br />
  <table summary="" cellpadding="0" cellspacing="2" border="0" width="65%" align="center">
     <tr><td>Keyword</td><td><input type="text" name="$term" size="20" value="$scalars{library_parameters}" /></td>
	 <td><input type="submit" value="Search" /></td></tr>
  </table>
EOHTML
}

###
1;#do not remove
###
