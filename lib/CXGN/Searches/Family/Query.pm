package CXGN::Searches::Family::Query;
use strict;
use English;
use Carp;

use CXGN::DB::Connection;
use CXGN::Tools::Class qw/parricide/;
use CXGN::Tools::Text;

use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

=head1 NAME

CXGN::Searches::Family::Query - query for L<CXGN::Searches::Family>.

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::Simple::WWWQuery>

=cut

=head1 AUTHOR(S)

    C. Carpita (stolen from interns who stole from Robert Buels...shameful)

=cut

#fields returned by the query, in the order in which they'll be returned
my @family_params = ('family_id', 'family_annotation', 'family_nr', 'member_count');
my @build_params = ('i_value', 'status', 'build_nr', 'family_build_id');

sub _cached_dbh()
{
	our $_cached_dbc ||= CXGN::DB::Connection->new('sgn');
}

#package configuration
my $sgn = 'sgn';

my @selects = map {"$sgn.family.$_"} @family_params;
push(@selects, map {"$sgn.family_build.$_"} @build_params);

#this should be last, we only select it in order to get the
#buggy code to join the tables...grrr

#push(@selects, "$sgn.family_member.cds_id"); 

__PACKAGE__->selects_data(@selects);

__PACKAGE__->join_root("$sgn.family");
__PACKAGE__->uses_joinpath('family_build', ["$sgn.family_build", "$sgn.family_build.family_build_id=$sgn.family.family_build_id"]);
__PACKAGE__->uses_joinpath('to_cds', 
	["$sgn.family_member", "$sgn.family_member.family_id=$sgn.family.family_id"],
	["$sgn.cds", "$sgn.cds.cds_id=$sgn.family_member.cds_id"],
);
#__PACKAGE__->uses_joinpath('cds', ["$sgn.cds", "$sgn.cds.cds_id=$sgn.family_member.cds_id"] );

foreach my $param (@family_params)
{
	__PACKAGE__->has_parameter(name => "$param", columns => "$sgn.family.$param");
}

foreach my $param (@build_params){
	__PACKAGE__->has_parameter(name => "$param", columns => "$sgn.family_build.$param");
}

__PACKAGE__->has_parameter(name => "member_count2", columns => "$sgn.family.member_count" );

__PACKAGE__->has_parameter(
	name => "unigene_id", 
	columns => "$sgn.cds.unigene_id", 
	group => 1
	);

__PACKAGE__->debug(2);

=head2 quick_search

Specified in L<CXGN::Search::WWWQueryI>.

=cut

sub quick_search {
  my ($self, $search_string) = @_;
  return unless $search_string =~ /^[a-zA-Z0-9 '-]+$/;
  $self->family_annotation("ilike ?", "\%$search_string\%"); 
  $self->family_nr("=?", $search_string);
  return $self;
}

=head2 _remove_enclosing_percents

Remove the percent signs that may have been put on bindvalues given to DBI, since DBI would rather see
$self->param("ilike ?", "%$param%")
than
$self->param("ilike '%?%'", $param)

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
	my ($self) = @_;
	
	my %scalars;
	#take out the percent signs postgres uses in LIKE statements, if they're on the bindvalues; these fields will probably never contain percents
	
	foreach(qw/ family_id 
				family_build_id 
				family_annotation
				family_nr 
				i_value 
				build_nr 
				status 
				member_count
				member_count2
				unigene_id
				/) {
		($scalars{$_}) = _remove_enclosing_percents($self->param_bindvalues($_)) if $self->param_bindvalues($_);
	}

	($scalars{sortby}) = $self->order_by();
	foreach(qw/mcc mcc2/){
		($scalars{$_}) = $self->{$_};
	}
	$scalars{page} = $self->page;
	return %scalars;
}

=head2 request_to_params

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

sub request_to_params
{
	my ($self, %request) = @_;

	#sanitize all the parameters
	foreach my $key (keys %request) {
	    if( $request{$key} ) {
	      $request{$key} = CXGN::Tools::Text::trim($request{$key});
	      $request{$key} =~ s/[;'",]//g;
	    }
	}
	
	if($request{family_id}){
		foreach(qw/family_nr family_build_id i_value/){
			$request{$_} = "";
		}
		$request{status} = "E";
	}
	if($request{build_nr}){
		$request{status} = "E";
	}

	foreach my $cnt_key (qw/member_count member_count2/){
	my $mcc_key = "mcc";
	$mcc_key .= "2" if $cnt_key =~ /member_count2/;
		if($request{$cnt_key}){
			my $mcc = $request{$mcc_key};
			$mcc ||= "eq";
			my $o = "=";
			$o = ">" if $mcc eq "gt";
			$o = "<" if $mcc eq "lt";
			$self->$cnt_key(" $o?", $request{$cnt_key});
			$self->{$mcc_key} = $mcc;	
		}
 	} 
	#ILIKE is PostgreSQL-specific
	if($request{family_annotation}){
		$self->family_annotation(" ILIKE ?", "%$request{family_annotation}%");
	}
	

	foreach(qw/unigene_id family_nr family_build_id build_nr family_id/){
		($request{$_}) = $request{$_} =~ /(\d+)/;
		next unless $request{$_};
		$self->$_(" =?", $request{$_});
	}
	($request{i_value}) = $request{i_value} =~ /([\d\.]+)/;
	if($request{i_value}){
		$self->i_value(" =?", $request{i_value});
	}

	$request{status} = 'C' unless $request{status} =~ /^E|D/i;
	if($request{status} && $request{status} =~ /^C|D/i){
		$request{status} = substr($request{status}, 0, 1);
		$self->status(" =?", uc($request{status}));
	}


	#page number
	if(defined $request{page}) {
	    $self->page($request{page});
	}
  
	#auxiliary SQL stuff
	if($request{sortby}){
		my $sortby = $request{sortby};
		if($sortby eq "member_count"){
			$self->order_by("member_count" => 'DESC');
		}
		else {
			$self->order_by($sortby => 'ASC'); #it must be defined; it's a drop-down menu
		}
	}
	else {
		$self->order_by('family_nr' => 'ASC');
	}
}

#html for the query form
sub to_html
{
	my $self = shift;

	#parameters need to be uniqified in the html form so they can be deuniqified and recognized later as belonging to this specific query class
	my $family_nr = $self->uniqify_name('family_nr');
	my $family_id = $self->uniqify_name('family_id');
	my $family_build_id = $self->uniqify_name('family_build_id');
	my $build_nr = $self->uniqify_name('build_nr');
	my $family_annotation = $self->uniqify_name('family_annotation');
	my $status = $self->uniqify_name('status');
	my $member_count = $self->uniqify_name('member_count');
	my $member_count2 = $self->uniqify_name('member_count2');
	my $mcc = $self->uniqify_name('mcc');
	my $mcc2 = $self->uniqify_name('mcc2');
	my $i_value = $self->uniqify_name('i_value');

	my $unigene_id = $self->uniqify_name('unigene_id');
	my $sortby = $self->uniqify_name('sortby');
	
	my %scalars = $self->_to_scalars();
	my ($order_by_param) = $self->order_by(); #take the first key of the returned hash -- make sure we're in list context
	#autofill stuff for the sort-by options

        no warnings 'uninitialized';
	my %selected;
	foreach my $sort_option (qw/member_count family_build_id/)
	{
		$selected{$sort_option} = "";
		$selected{$sort_option} = "selected=\"selected\"" if($order_by_param eq $sort_option);
	}
	my %status_selected;
	my ($stat_param) = $scalars{status};
	$stat_param ||= "C";
	foreach my $statopt (qw/C D E/){
		$status_selected{$statopt} = 'selected="selected"' if ($stat_param eq $statopt);
		$status_selected{$statopt} = '' if ($stat_param ne $statopt);
	}

	my %ivalue_selected;
	my ($ivalue_param) = $scalars{i_value};
	foreach my $ivopt (qw/1.1 2 5/){
		$ivalue_selected{$ivopt} = 'selected="selected"' if ($ivalue_param eq $ivopt);
		$ivalue_selected{$ivopt} = '' if ($ivalue_param ne $ivopt);
	}

	my %mcc_selected;
	my %mcc_selected2;
	foreach my $mcc_opt(qw/ eq gt lt /){
		$mcc_selected{$mcc_opt} = "";
		$mcc_selected2{$mcc_opt} = "";
		$mcc_selected{$mcc_opt} = 'selected="selected"' if ($mcc_opt eq $scalars{mcc});
		$mcc_selected2{$mcc_opt} = 'selected="selected"' if ($mcc_opt eq $scalars{mcc2});
	}

	return <<EOHTML;
This page allows you to search unigene families based on family parameters, including size, clustering strictness, and annotation.
<br /><br />
<table width="600" border="0">
	<tr>
		<td>
			<b>Criteria</b>
			<br /><br />
			<center>
			<table border="0">
				<tr>
					<td>Annotation Text:</td>
					<td><input type="text" name="$family_annotation" value="$scalars{family_annotation}" /></td>
				</tr>
				<tr>
					<td>Family Number:</td>
					<td><input type="text" name="$family_nr" value="$scalars{family_nr}" /></td>
				</tr>

				<tr>
					<td>Family ID:</td>
					<td><input type="text" name="$family_id" value="$scalars{family_id}" /></td>
				</tr>
				<tr>
					<td>Build Number:</td>
					<td><input type="text" name="$build_nr" value="$scalars{build_nr}" /></td>
				</tr>
				<tr>
					<td>Unigene ID:</td>
					<td><input type="text" name="$unigene_id" value="$scalars{unigene_id}" /></td>
				</tr>
				<tr>
				<td>Build Status
				<select name="$status">
					<option value="C" $status_selected{C}>Current</option>
					<option value="D" $status_selected{D}>Old</option>
					<option value="E" $status_selected{either}>Either</option>
				</select>
				</td>
				<td align="right">I-Value
				<select name="$i_value">
					<option value="">Select I-Value</option>
					<option value="1.1" $ivalue_selected{1.1}>1.1</option>
					<option value="2" $ivalue_selected{2}>2</option>
					<option value="5" $ivalue_selected{5}>5</option>
				</select>
				</td>
				</tr>
				<tr>
				<td colspan="2" align="left">
				Family Size
				<select name="$mcc">
					<option value="eq" $mcc_selected{eq}>=</option>
					<option value="lt" $mcc_selected{lt}>&lt;</option>
					<option value="gt" $mcc_selected{gt}>&gt;</option>
				</select>
				&nbsp;
				<input type="text" size="4" name="$member_count" value="$scalars{member_count}" />
				&nbsp;<b>and</b>&nbsp;
				<select name="$mcc2">
					<option value="eq" $mcc_selected2{eq}>=</option>
					<option value="lt" $mcc_selected2{lt}>&lt;</option>
					<option value="gt" $mcc_selected2{gt}>&gt;</option>
				</select>
				<input type="text" size="4" name="$member_count2" value="$scalars{member_count2}" />
				</td>
				</tr>
			</table>
			<br />
			Sort results by
			<select name="$sortby">
				<option value="family_build_id" $selected{family_build_id}>Family Build</option>
				<option value="member_count" $selected{member_count}>Family Size</option>
			</select><br /><br />
			<input type="submit" value="Search Families" />
			</center>
			<br /><br />
		</td>
	</tr>
</table>
<br /><br />
EOHTML
}

###
1;#do not remove
###
