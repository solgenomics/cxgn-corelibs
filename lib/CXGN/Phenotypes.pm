use strict;

package CXGN::Phenotypes;
use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;


__PACKAGE__->creates_result('CXGN::Phenotypes::Result');
__PACKAGE__->uses_query('CXGN::Phenotypes::Query');

# __PACKAGE__->transforms_rows(\&trans);

# sub trans {
#   my $row = shift;
#   return MyObject->new($row);
# }

###
1;#do not remove
###

package CXGN::Phenotypes::Result;
use base qw/CXGN::Search::BasicResult/;
###
1;#do not remove
###

package CXGN::Phenotypes::Query;
use CXGN::Page::FormattingHelpers qw/simple_selectbox_html
                                     info_table_html
				     hierarchical_selectboxes_html
                                     conditional_like_input_html
                                     html_optional_show 
				     /;


use CXGN::Phenome::Individual;
use CXGN::Phenome::Population;
use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

sub _cached_dbh() { our $_cached_dbc ||= CXGN::DB::Connection->new('phenome') }
my $phenome    = 'phenome';
my $sgn        = 'sgn';
my $sgn_people = 'sgn_people';
my $public     = 'public';
my $metadata   = 'metadata';

__PACKAGE__->selects_data("$phenome.individual.individual_id",
			  "$phenome.individual.name",
			  "$phenome.individual.description",
    );


__PACKAGE__->join_root("$phenome.individual");


__PACKAGE__->uses_joinpath('population_path',
			   [ "$phenome.population", "$phenome.population.population_id=$phenome.individual.population_id"]);

__PACKAGE__->uses_joinpath('image_path',
			   [ "$phenome.individual_image", "$phenome.individual_image.individual_id=$phenome.individual.individual_id"],
			   ["$metadata.md_image", "$metadata.md_image.image_id=$phenome.individual_image.image_id"],
			   );


__PACKAGE__->uses_joinpath('allele_path',
			   [ "$phenome.individual_allele", "$phenome.individual_allele.individual_id=$phenome.individual.individual_id"],
			   [ "$phenome.allele", "$phenome.allele.allele_id=$phenome.individual_allele.allele_id"],
			   );
__PACKAGE__->uses_joinpath('organism_path',
			    [ "$sgn.common_name", "$sgn.common_name.common_name_id=$phenome.individual.common_name_id"],
			   );
__PACKAGE__->uses_joinpath('person_path', 
			   ["$sgn_people.sp_person", "$sgn_people.sp_person.sp_person_id=$phenome.individual.sp_person_id"],
			   );

__PACKAGE__->uses_joinpath('dbxrefpath',
			   [ "$phenome.individual_dbxref", "$phenome.individual_dbxref.individual_id=$phenome.individual.individual_id"],
			   [ "$public.dbxref", "$public.dbxref.dbxref_id=$phenome.individual_dbxref.dbxref_id"],
			   [ "$public.cvterm", "$public.dbxref.dbxref_id=$public.cvterm.dbxref_id"],
			   [ "public.cvtermsynonym", "$public.cvterm.cvterm_id=$public.cvtermsynonym.cvterm_id"],
			   [ "$public.db", "$public.dbxref.db_id=$public.db.db_id"],
			   [ "$public.pub_dbxref", "$public.pub_dbxref.dbxref_id=$public.dbxref.dbxref_id"],
			   );


__PACKAGE__->has_parameter(name    => 'individual_name',
			   columns => "$phenome.individual.name",
			  );

__PACKAGE__->has_parameter(name    => 'phenotype',
			   columns => "$phenome.individual.description",
			   );

__PACKAGE__->has_parameter(name    => 'population_id',
			   columns => "$phenome.population.population_id",
			   );
__PACKAGE__->has_parameter(name    => 'population_name',
			   columns => "$phenome.population.name",
			   );

__PACKAGE__->has_parameter(name    => 'population_description',
			   columns => "$phenome.population.description",
			   );

__PACKAGE__->has_parameter(name    => 'allele_phenotype',
			   columns => "$phenome.allele.allele_phenotype",
			   );

__PACKAGE__->has_parameter(name   =>'individual_obsolete',
			   columns=>"$phenome.individual.obsolete",
			   );

__PACKAGE__->has_parameter(name   =>'individual_sp_person_id',
			   columns=>"$phenome.individual.sp_person_id",
			   );



__PACKAGE__->has_parameter(name   =>'common_name',
			   columns=>"$sgn.common_name.common_name",
			   );
__PACKAGE__->has_parameter(name   =>'common_name_id',
			   columns=>"$sgn.common_name.common_name_id",
			   );

__PACKAGE__->has_parameter(name   =>'editor',
			   columns=>["$sgn_people.sp_person.first_name",
				     "$sgn_people.sp_person.last_name"],
			   sqlexpr=>"$sgn_people.sp_person.last_name || $sgn_people.sp_person.first_name",
			  );


__PACKAGE__->has_complex_parameter( name => 'allele_keyword',
				    uses => ['phenotype','allele_phenotype', 'individual_name'],
				    setter => sub {
					my ($self, @args) = @_;
					$self->phenotype(@args);
					$self->allele_phenotype(@args);
					$self->individual_name(@args);
					$self->compound('&t OR &t OR &t' ,'phenotype','allele_phenotype', 'individual_name');
				    }
				    );
__PACKAGE__->has_parameter(name   =>'has_db_name',
	                   columns=>"$public.db.name",
			   );

__PACKAGE__->has_parameter(name   =>'has_annotation',
 			   columns=>["$phenome.individual_dbxref.individual_id"],
 			   sqlexpr=>"count (distinct $phenome.individual_dbxref.individual_id)",
 			   group  =>1,
 			   aggregate=>1,
 			   );

__PACKAGE__->has_parameter(name   =>'has_reference',
 			   columns=>["$phenome.individual_dbxref.individual_id"],
 			   sqlexpr=>"count (distinct $phenome.individual_dbxref.individual_id)",
 			   group  =>1,
 			   aggregate=>1,
 			   );



__PACKAGE__->has_parameter(name   =>'cvterm',
 	                   columns=> "$public.cvterm.name",
			   );
__PACKAGE__->has_parameter(name   =>'cvterm_synonym',
 	                   columns=> "$public.cvtermsynonym.synonym",
			   group  =>1,
			   );
__PACKAGE__->has_parameter(name   =>'accession',
 	                   columns=> "$public.dbxref.accession",
			   );

__PACKAGE__->has_parameter(name   =>'ontology_term',
 	                   columns=>["$public.dbxref.accession",
 	                             "$public.cvterm.name"],
 	                   sqlexpr=>"$public.cvterm.name || $public.dbxref.accession",
	                   group  => 1,
			   );

__PACKAGE__->has_parameter(name   =>'has_locus_link',
 			   columns=>["$phenome.individual_allele.individual_id"],
 			   sqlexpr=>"count (distinct $phenome.individual_allele.individual_id)",
 			   group  =>1,
 			   aggregate=>1,
 			   );
__PACKAGE__->has_parameter(name   =>'has_image',
 			   columns=>["$phenome.individual_image.image_id"],
 			   sqlexpr=>"count (distinct $phenome.individual_image.image_id)",
 			   group  =>1,
 			   aggregate=>1,
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
  $self->individual_obsolete("='f'");
  
  if($params{allele_keyword}) {
      $self->allele_keyword('ILIKE ?', "%$params{allele_keyword}%");
  }

  if($params{phenotype}) {
      $self->phenotype('ILIKE ?', "%$params{phenotype}%");
  }

  if($params{allele_phenotype}) {
      $self->allele_phenotype('ILIKE ?',"%$params{phenotype}%");
  }
      
  if($params{individual_name}) {
      $self->individual_name('ILIKE ?', "%$params{individual_name}%");
  }
  
  if($params{population_id}) {
      $self->population_id('= ?', "$params{population_id}");
  }
  if($params{population_name}) {
      $self->population_name('ILIKE ?', "$params{population_name}");
  }
  
  if($params{common_name}) {
      $self->common_name('ILIKE ?', "$params{common_name}");
  }
  if($params{editor}) {
      $self->editor('ILIKE ?', "%$params{editor}%");
  }


  if ($params{has_annotation} ) {
      $self->has_annotation('=1');
      $self->has_db_name("IN ('SP', 'PO')");
      $self->terms_combine_op('AND');
  }
  if ($params{has_reference} ) {
      $self->has_reference('=1');
      $self->has_db_name("= 'PMID'");
      $self->terms_combine_op('AND');
  }
  
  if ($params{ontology_term}) {
      if ($params{ontology_term} =~m /(..)(:)(\d+)/i) {  #PO: | GO: | SP:
	  print STDERR "Found db_name $1, ontology_term: $3..**\n\n";
	  $self->has_db_name('ILIKE ?', "$1");
	  $self->ontology_term('ILIKE ?', "%$3%");
	  $self->terms_combine_op('AND');
	  
      }else {
	  $self->cvterm_synonym('ILIKE ?', "%$params{ontology_term}%");
	  $self->ontology_term('ILIKE ?', "%$params{ontology_term}%");
	  $self->has_db_name("IN ('SP', 'PO')");
	  $self->compound('&t AND (&t OR &t)','has_db_name','ontology_term', 'cvterm_synonym');
      }
  }
  if ($params{has_locus_link}) {
      $self->has_locus_link('!=0');
  }
  if ($params{has_image}) {
      $self->has_image('!=0');
  }
  #page number
  if( defined($params{page}) ) { $self->page($params{page}); }
}

sub _to_scalars {   
    my $self= shift;
    my $search= shift;
    my %params;
    
    #this part defines the mapping from get/post data to search params 
    ($params{allele_keyword}) = $self->param_bindvalues('allele_keyword');
    $params{allele_keyword} =~ s/%//g;
    ($params{individual_name}) = $self->param_bindvalues('individual_name');
    $params{individual_name} =~ s/%//g;
    ($params{population_id}) = $self->param_bindvalues('population_id');
    ($params{population_name}) = $self->param_bindvalues('population_name');
    ($params{common_name}) = $self->param_bindvalues('common_name');
    ($params{editor}) = $self->param_bindvalues('editor');
    $params{editor} =~ s/%//g;
    
    $params{has_annotation} = $self->pattern_match_parameter('has_annotation', qr/=1/);
    $params{has_annotation} = $self->pattern_match_parameter('has_db_name', qr/SP|PO/);
    
    $params{has_reference} = $self->pattern_match_parameter('has_reference', qr/=1/);
    $params{has_reference} = $self->pattern_match_parameter('has_db_name', qr/PMID/);
    
        
    ($params{ontology_term}) = $self->param_bindvalues('ontology_term');
    $params{ontology_term} =~ s/%//g;
    ($params{has_db_name}) = $self->param_bindvalues('has_db_name');
    
    if ( $params{has_db_name} ) {
	$params{ontology_term} = $params{has_db_name} . ":" . $params{ontology_term};
    }
    
    ($params{has_locus_link}) = $self->pattern_match_parameter('has_locus_link', qr/!=\s*0/);
    ($params{has_image}) = $self->pattern_match_parameter('has_image', qr/!=\s*0/);

       
    return %params;
} 

sub to_html {
    my $self = shift;
    my $search = 'pheno_search';
    my %scalars = $self->_to_scalars($search);

    my $allele_keyword = $self->uniqify_name('allele_keyword');
    my $accession = $self->uniqify_name('individual_name');
    my $population_name= $self->uniqify_name('population_name');
    my $population_id = $self->uniqify_name('population_id');
    my $common_name_id = $self->uniqify_name('common_name_id');
    my $common_name = $self->uniqify_name('common_name');    

    my $editor = $self->uniqify_name('editor');
    my $has_annotation= $self->uniqify_name('has_annotation');
    my $has_reference= $self->uniqify_name('has_reference');
    my $ontology_term = $self->uniqify_name('ontology_term');
    my $has_locus_link = $self->uniqify_name('has_locus_link');
    my $has_image = $self->uniqify_name('has_image');
    
    my $dbh=_cached_dbh();
    my $population_names_ref = CXGN::Phenome::Population::get_all_populations($dbh);
    #add an empty entry to the front of the list
    unshift @$population_names_ref, [0, ''];
   
    my $population = simple_selectbox_html( choices  => $population_names_ref,
					    name     => $population_id,
					    selected => $scalars{population_id},
 					  );

    my ($organism_names_ref, $organism_ids_ref) = CXGN::Phenome::Individual::get_existing_organisms($dbh);
    #add an empty entry to the front of the list
    unshift @$organism_names_ref, '';
    
    my $organism = simple_selectbox_html( choices  => $organism_names_ref,
					  name     => $common_name,
					  selected => $scalars{common_name},
					  );
    #check boxes
    @scalars{qw/has_locus_link has_annotation has_reference has_image/} =
	map {$_ ? 'checked="checked" ' : undef} @scalars{qw/has_locus_link has_annotation has_reference has_image/};
    
    my $pheno_search=  qq|<input name="$allele_keyword" value="$scalars{allele_keyword}" size="30" >|;
			    
    
    my $show_advanced_search =
	grep {defined($_)} @scalars{qw/ population_id common_name individual_name editor has_locus_link
					has_annotation has_reference
					ontology_term has_image 
					/};
    my $advanced_search= html_optional_show('advanced_search',
					    'Advanced search options',
					    qq|<div class="minorbox">\n|
			   .info_table_html(
					    'Population' => $population,
					    'Organism'   => $organism,
					    'Show only accessions with' => <<EOH,
					    <input type="checkbox" name="$has_locus_link" $scalars{has_locus_link} />Associated locus <br />
					    <input type="checkbox" name="$has_annotation" $scalars{has_annotation} />SP/PO annotation<br />
					    <input type="checkbox" name="$has_image" $scalars{has_image} />Image<br />
EOH
					    'Editor' =>qq|<input name="$editor" value="$scalars{editor}" size="20"/>|,
					    'Accession' => qq|<input name="$accession" value="$scalars{individual_name}"size="20"/>|,
					    'Ontology term' => qq|<input name="$ontology_term" value = "$scalars{ontology_term}" />
					    <br /><span class="ghosted">(Term name or ID: e.g. 'inflorescence' or 'PO:0007010')</span>|,
					    __border   =>0,
					    __multicol =>2,
					    __tableattrs => 'width="100%"',
					    ) .qq|</div>|,
			   $show_advanced_search);
    $scalars{has_locus_link}     ||= '';
    $scalars{has_annotation} ||= '';
    $scalars{has_reference}  ||= '';
    $scalars{has_image}  ||= '';
    
    my $html_ret = <<EOHTML;
    (<a href="../help/phenotype_search_help.pl" />phenotype search help page<a />)
    <table><tr></tr>
    <tr><td colspan="2" ><b>Search by keyword</b></td></tr>
    <tr><td>$pheno_search</td>
    <td><a href="../phenome/individual.pl?action=new">[Submit new accession]</a> </td>
    </tr></table>
    <br />
    $advanced_search
    <div align = "center"><input type="submit" value="Search"/></div>
EOHTML


}

# Quick search routine
sub quick_search {
    my ($self,$term) = @_;
    $self->allele_keyword('ILIKE ?', "%$term%");
    $self->individual_obsolete('=?', "f");
    return $self;
}


###
1;#do not remove
###

