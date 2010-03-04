use strict;
use CXGN::Phenome::Qtl::Tools;


package CXGN::Cvterms;
use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;


__PACKAGE__->creates_result('CXGN::Cvterms::Result');
__PACKAGE__->uses_query('CXGN::Cvterms::Query');



###
1;#do not remove
###

package CXGN::Cvterms::Result;
use base qw/CXGN::Search::BasicResult/;
###
1;#do not remove
###

package CXGN::Cvterms::Query;
use CXGN::Page::FormattingHelpers qw/simple_selectbox_html
                                     info_table_html
				     hierarchical_selectboxes_html
                                     conditional_like_input_html
                                     html_optional_show 
				     /;


use CXGN::Chado::Cvterm;
use CXGN::Phenome::Population;
use CXGN::DB::Connection;
use base qw/ CXGN::Search::DBI::Simple::WWWQuery /;

sub _cached_dbh() { our $_cached_dbc ||= CXGN::DB::Connection->new('public') }

my $public = 'public';

__PACKAGE__->selects_data("$public.cvterm.cvterm_id",
			  "$public.cvterm.name",			 
                          "$public.cvtermsynonym.synonym",
			  "$public.cvterm.definition",
			 );


__PACKAGE__->join_root("$public.cvterm");

__PACKAGE__->uses_joinpath("cvtermsynonym_path", ["$public.cvtermsynonym", "$public.cvterm.cvterm_id = $public.cvtermsynonym.cvterm_id"]);

__PACKAGE__->has_parameter(name    => 'cvterm_name',
			   columns => ["$public.cvterm.name", "$public.cvtermsynonym.synonym"],
			   sqlexpr => "$public.cvterm.name || $public.cvtermsynonym.synonym",
			  );

__PACKAGE__->has_parameter(name   =>'cvterm_synonym',
 	                   columns=> "$public.cvtermsynonym.synonym",
			   group  =>1,
			   );


__PACKAGE__->has_parameter(name   =>'has_db_name',
 	                           columns=>"$public.db.name",
	                           );

###### NOW WWW STUFF ###


sub request_to_params {
  my($self, %params) = @_;

  #sanitize all the parameters
  foreach my $key (keys %params) {
      if( $params{$key} ) {
	  $params{$key} =~ s/[;\'\",]//g;
      }
  }
 # $self->cvterm_obsolete("='f'");
  my $cvterm_name_result;
  if($params{cvterm_name}) {
      $self->cvterm_name('ILIKE ?', "%$params{cvterm_name}%");
  }

  
  #page number
  if( defined($params{page}) ) { $self->page($params{page}); }
}

sub _to_scalars {   
    my $self= shift;
    my $search= shift;
    my %params;
    
    #this part defines the mapping from get/post data to search params 
    ($params{cvterm_name}) = $self->param_bindvalues('cvterm_name');
    $params{cvterm_name} =~ s/%//g;
   
       
    return %params;
} 

sub to_html {
    my $self = shift;
    my $dbh=_cached_dbh();
    my @qtl_pops = CXGN::Phenome::Qtl::Tools->new()->has_qtl_data();
   
    my  $pop_links;
    foreach my $pop_obj (@qtl_pops) {
	my $pop_id = $pop_obj->get_population_id();
	my $pop_name = $pop_obj->get_name();
	$pop_links .= qq |<a href="../phenome/population.pl?population_id=$pop_id">$pop_name</a> <br /> |;     
    }

    my $search = 'cvterms_search';
    my %scalars = $self->_to_scalars($search);

    my $cvterm_name = $self->uniqify_name('cvterm_name');
   

    
    my $cvterm_search =  qq|<input name="$cvterm_name" value="$scalars{cvterm_name}" size="30" >|;
  
   $pop_links = "<table align=center cellpadding=20px><tr><td><b>Browse traits/QTLs by population:<br/>$pop_links<b></td></tr></table>";

      
    my $html_ret = <<EOHTML;
    
    <table><tr></tr>
     <tr><td colspan="2" ><b>Search by trait name</b> (<a href="../help/qtl_cvterm_search_help.pl" />help<a />)</td></tr>
     <tr><td>$cvterm_search</td>
        <td><input type="submit" value="Search"/></td> 
        <td><a href="../phenome/qtl_form.pl">[Submit new QTL data]</a></td>       
     </tr>
   </table>   
    

$pop_links  
    
EOHTML

}

# Quick search routine
sub quick_search {
    my ($self,$term) = @_;
    $self->cvterm_name('ILIKE ?', "%$term%");    
    $self->cvterm_obsolete('=?', "f");
    return $self;
}


###
1;#do not remove
###

