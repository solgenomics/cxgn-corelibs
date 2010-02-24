package CXGN::Searches::GemTemplate::Query;

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

 CXGN::Searches::GemTemplate::Query
 query for L<CXGN::Searches::GemTemplate>.

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::Simple::WWWQuery>

=cut

our $VERSION = '0.01';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

coming soon

=cut

=head1 AUTHOR(S)

 Aureliano Bombarely
 (ab782@cornell.edu)

=cut

#the fields the search should return from different tables
my @template_fields = qw(template_id template_name);
my @platform_fields = qw(platform_id platform_name);

sub _cached_dbh() {
	my $schema = "gem";
	our $_cached_dbc ||= CXGN::DB::Connection->new($schema);
}

#package configuration
my $gem = 'gem';
my @qualified_fields = map {"$gem.ge_template.$_"} @template_fields;
push @qualified_fields, map {"$gem.ge_platform.$_"} @platform_fields;

__PACKAGE__->selects_data(@qualified_fields);
__PACKAGE__->join_root("$gem.ge_template");
__PACKAGE__->uses_joinpath( 'ge_platform', 
			    [ 
			      "$gem.ge_platform", 
			      "$gem.ge_platform.platform_id = $gem.ge_template.platform_id"
			    ]
                          );

foreach my $param (@template_fields) {
    __PACKAGE__->has_parameter( name    => "$param", 
				columns => "$gem.ge_template.$param" );

}
foreach my $param (@platform_fields) {
    __PACKAGE__->has_parameter( name    => "$param", 
				columns => "$gem.ge_platform.$param");
}


sub quick_search
{
	my ($this, $search_string) = @_;
	return unless $search_string =~ /^[a-zA-Z _-]+$/;
	$this->template_parameters("ilike ?", "%$search_string%");
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

sub _remove_enclosing_percents {
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

sub _to_scalars {
	my ($this) = @_;
	
	## convert quicksearch parameters to the parameters the regular search wants; 
	## we only need to process one parameter name, since 
	## all the parameters used by the quicksearch are given equal values
	
	my %scalars;
	
        ## take out the percent signs postgres uses in LIKE statements, if they're on the bindvalues; 
        ## these fields will probably never contain percents
	
	($scalars{template_parameters}) = _remove_enclosing_percents(
	    $this->param_bindvalues('template_name')) if $this->param_bindvalues('template_name');
	
	$scalars{page} = $this->page;
	return %scalars;
}

sub template_parameters {
    my ($this, @args) = @_;
    
    #ILIKE is PostgreSQL-specific
    $this->template_name(@args);

    $this->compound("&t", "template_name");
    $this->order_by("template_name" => "ASC");
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
	
       if($request{template_parameters}) {
          $this->template_parameters('ILIKE ?',"%$request{template_parameters}%");
       }
	
       #page number
       if(defined $request{page}) {
	$this->page($request{page});
       }
}

#html for the query form
sub to_html {
    my $this = shift;
    my $search = 'advanced';
    my %scalars = $this->_to_scalars();
	
    my $term = $this->uniqify_name('template_parameters');
	
    return <<EOHTML;
  <br />
  Find expression data associated with any template using template_name
  <br /><br />
  <table summary="" cellpadding="0" cellspacing="2" border="0" width="65%" align="center">
     <tr><td>Template name</td><td><input type="text" name="$term" size="20" value="$scalars{template_parameters}" /></td>
	 <td><input type="submit" value="Search" /></td></tr>
  </table>
EOHTML
}

###
1;#do not remove
###
