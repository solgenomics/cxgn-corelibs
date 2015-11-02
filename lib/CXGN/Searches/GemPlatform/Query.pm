package CXGN::Searches::GemPlatform::Query;

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

 CXGN::Searches::GemPlatform::Query 
 query for L<CXGN::Searches::GemPlatform>.

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
my @platform_fields = qw(platform_id platform_name);

sub _cached_dbh() {
	my $schema = "gem";
	our $_cached_dbc ||= CXGN::DB::Connection->new($schema);
}

#package configuration
my $gem = 'gem';
my @qualified_fields = map {"$gem.ge_platform.$_"} @platform_fields;

__PACKAGE__->selects_data(@qualified_fields);
__PACKAGE__->join_root("$gem.ge_platform");


foreach my $param (@platform_fields) {
	__PACKAGE__->has_parameter(name => "$param", columns => "$gem.ge_platform.$param");
}


sub quick_search
{
	my ($this, $search_string) = @_;
	return unless $search_string =~ /^[a-zA-Z _-]+$/;
	$this->platform_parameters("ilike ?", "%$search_string%");
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
	
        ## take out the percent signs postgres uses in LIKE statements, 
        ## if they're on the bindvalues; these fields will probably never contain percents

	($scalars{platform_parameters}) = _remove_enclosing_percents( 
	    $this->param_bindvalues('platform_name')) if $this->param_bindvalues('platform_name');
	
	$scalars{page} = $this->page;
	return %scalars;
}

sub template_parameters {
    my ($this, @args) = @_;
    
    #ILIKE is PostgreSQL-specific
    $this->platform_name(@args);

    $this->compound("&t", "platform_name");
    $this->order_by("platform_name" => "ASC");
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
	
       if($request{platform_parameters}) {
          $this->platform_parameters('ILIKE ?',"%$request{platform_parameters}%");
       }
	
       #page number
       if(defined $request{page}) {
	$this->page($request{page});
       }
}

#html for the query form
sub to_html {

	my $this = shift;
	my %scalars = $this->_to_scalars();
	
	#parameters need to be uniqified in the html form so they can be deuniqified and recognized later as belonging to this specific query class
	my $term = $this->uniqify_name('template_parameters');
	
	return <<EOHTML;
    <div class="row">
       <div class="col-sm-2">
       </div>
       <div class="col-sm-8">
         Find expression data associated with any platform using platform name
  <br /><br />
         <div class="form-horizontal" >
           <div class="form-group">
             <label class="col-sm-3 control-label">Platform Name: </label>
      	     <div class="col-sm-9">
	       <div class="row">
	         <div class="col-sm-10">
	           <input class="form-control" type="text" name="$term" size="20" value="$scalars{template_parameters}" />
	         </div>
	         <div class="col-sm-2">
	           <input class="btn btn-primary" type="submit" value="Search" />
	         </div>
	       </div>
	     </div>
           </div>
         </div>
       </div>
       <div class="col-sm-2">
       </div>
     </div>

EOHTML
}

###
1;#do not remove
###
