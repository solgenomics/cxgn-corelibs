use strict;

####################

package CXGN::Publication;
use base qw/CXGN::Search::DBI::Simple CXGN::Search::WWWSearch/;

__PACKAGE__->creates_result('CXGN::Publication::Result');
__PACKAGE__->uses_query('CXGN::Publication::Query');

#####################

package CXGN::Publication::Result;
use base qw/CXGN::Search::BasicResult/;

#####################

package CXGN::Publication::Query;
use CXGN::Page::FormattingHelpers
  qw(
     simple_selectbox_html
     info_table_html
     hierarchical_selectboxes_html
     conditional_like_input_html
     html_optional_show
    );

use base qw/CXGN::Search::DBI::Simple::WWWQuery/;
our %pname;

sub _cached_dbh() { our $_cached_dbc ||= CXGN::DB::Connection->new('public') }
my $public = 'public';
my $sgn_people= 'sgn_people';
my $phenome=  'phenome';
__PACKAGE__->selects_data("$public.pub.pub_id","$public.pub.title","$public.pub.series_name", "$public.pub.pyear","$phenome.pub_curator.assigned_to","$phenome.pub_curator.date_curated", "$phenome.pub_curator.curated_by", "$phenome.pub_curator.status", "$phenome.pub_curator.date_stored" );


__PACKAGE__->join_root("$public.pub");

__PACKAGE__->uses_joinpath('authorpath', 
			   ["$public.pubauthor", "$public.pubauthor.pub_id = $public.pub.pub_id"],
    );

__PACKAGE__->uses_joinpath('curatorpath', 
			   [ "$phenome.pub_curator", "$phenome.pub_curator.pub_id=$public.pub.pub_id" ],
			   [ "$sgn_people.sp_person", "$phenome.pub_curator.assigned_to = $sgn_people.sp_person.sp_person_id" ],
			   );


__PACKAGE__->has_parameter(name   =>'author',
 	                   columns=>["$public.pubauthor.surname",
				     "$public.pubauthor.givennames"],
			   sqlexpr=>"$public.pubauthor.surname || $public.pubauthor.givennames",
                           );

__PACKAGE__->has_parameter(name   =>'title',
 	                   columns=>"$public.pub.title",
    );
__PACKAGE__->has_parameter(name   =>'pyear',
 	                   columns=>"$public.pub.pyear",
    );
__PACKAGE__->has_parameter(name   =>'series',
 	                   columns=>"$public.pub.series_name",
    );

__PACKAGE__->has_parameter(name   =>'assigned_to',
 	                   columns=>["$sgn_people.sp_person.first_name",
 	                             "$sgn_people.sp_person.last_name",
				     "$sgn_people.sp_person.sp_person_id"],
 	                   sqlexpr=>"$sgn_people.sp_person.last_name || $sgn_people.sp_person.first_name 
                                      || $sgn_people.sp_person.sp_person_id",
    );

__PACKAGE__->has_parameter(name   =>'status',
 	                   columns=>"$phenome.pub_curator.status",
			   );
__PACKAGE__->has_parameter(name   =>'is_curated',
	                   columns=>"$phenome.pub_curator.curated_by",
			   #sqlexpr=>"(count pub_curator.curated_by)",
			  # group  =>1,
 			  # aggregate=>1,
    );
__PACKAGE__->has_parameter(name   =>'date_stored',
	                   columns=>["$phenome.pub_curator.date_stored"],
    );


__PACKAGE__->has_complex_parameter( name => 'any_name',
 				    uses => [qw/ title series /],
 				    setter => sub {
					my ($self, @args) = @_;
					$self->title(@args);
					$self->series(@args);
					
					$self->compound('&t OR &t' ,'title', 'series');
 				    }
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
    
    if($params{any_name}) {
	$self->any_name('ILIKE ?',"%$params{any_name}%");
    }

    #if ($params{editor} =~ m/^\d/) {
#	$self->editor('= ?', "$params{editor}");
    if ($params{assigned_to}) {
	$self->assigned_to('ILIKE ?', "%$params{assigned_to}%");
    }
    
    if ($params{is_curated}) {
	$self->is_curated('IS NOT NULL');
    }
 
    if ($params{author}) {
	$self->author('ILIKE ?', "%$params{author}%");
    }
    if ($params{date_stored}) {
	$self->date_stored('> ?', "$params{date_stored}");
    }
    if($params{status}) {
	$self->status('ILIKE ?', "$params{status}");
    }

    #page number
    if( defined($params{page}) ) {
	$self->page($params{page});
    }
}

sub _to_scalars {   
    my $self= shift;
    my $search= shift;
    my %params;
    
    no warnings 'uninitialized';

    #this part defines the mapping from get/post data to search params
        
    ($params{any_name}) = $self->param_bindvalues('any_name');
    $params{any_name} =~ s/%//g;
     
    ($params{author}) = $self->param_bindvalues('author');
    $params{author} =~ s/%//g;
    
    ($params{assigned_to}) = $self->param_bindvalues('assigned_to');
    $params{assigned_to} =~ s/%//g;
    
    ($params{date_stored}) = $self->param_bindvalues('date_stored');
    $params{date_stored} =~ s/%//g;
    
    ($params{status}) = $self->param_bindvalues('status');

    $params{is_curated} = $self->pattern_match_parameter('is_curated',  /IS NOT NULL/);
    
    return %params;
}

sub to_html {
    my $self = shift;
    my $search = 'advanced';
    my %scalars = $self->_to_scalars($search);

    #make %pname, a tied hash that uniqifies names the make_pname
    # function is in CXGN::Page::WebForm, which is a parent of
    # CXGN::Search::DBI::Simple::WWWQuery
    $self->make_pname;
    our %pname;
    
    my $dbh=_cached_dbh();
    
    my @stat_list= ("", "pending", "curated", "rejected", "no gene");
    my $stats = simple_selectbox_html( choices  => \@stat_list,
					  name     => $pname{status},
					  selected => $scalars{status},
					  );
    
    my $is_curated= $self->uniqify_name('is_curated');
    my $any_name = $self->uniqify_name('any_name');
    my $author = $self->uniqify_name('author');
    my $assigned_to = $self->uniqify_name('assigned_to');
    my $date_stored = $self->uniqify_name('date_stored');


    #check boxes
    @scalars{qw/ is_curated is_assigned /} =
	map {$_ ? 'checked="checked" ' : undef} @scalars{qw/ is_curated is_assigned /};
    
    my $a_search=
	info_table_html( 
			 'Title'=>qq|<input name="$pname{any_name}" value="$scalars{any_name}" size="60" />|,
			 __border =>0,) .
	info_table_html (
			 'Author' => qq|<input name = "$pname{author}" value="$scalars{author}" size="20" />|,
	    		 'Date stored' =>qq|<input name="$pname{date_stored}" value="$scalars{date_stored}" size="10"/>|,
			 'SGN curator'=> qq|<input name="$pname{assigned_to}" value="$scalars{assigned_to}" size="20" />|,
			 'Status' => $stats,
			 'Curated'    => qq|<input type="checkbox" name="$is_curated" $scalars{is_curated}  /><br />|,
			 __border   =>0,
			 __multicol =>2,
			 __tableattrs => 'width="100%"',
			 );
    
    #$scalars{is_curated}   ||= '';
    
    my $html_ret = <<EOHTML;
    <table><tr></tr>
	<tr><td>$a_search</td></tr>
    <tr><td><a href="/chado/publication.pl?action=new">[Submit new publication]</a> </td>
    </tr></table>
    <br />
	<div align="center"><input type="submit" value="Search"/></div>
EOHTML
}

sub quick_search {
    my ($self,$term) = @_;
    $self->any_name('ILIKE ?', "%$term%");
    return $self;		  
}

###
1;#do not remove
###
