package CXGN::Searches::Images::Query;
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
use CXGN::Page::FormattingHelpers qw/simple_selectbox_html
					html_optional_show
					info_table_html
					hierarchical_selectboxes_html
					numerical_range_input_html
					commify_number
					/;

use base qw/CXGN::Search::DBI::Simple::WWWQuery/;

=head1 NAME

CXGN::Searches::Images::Query - query for L<CXGN::Searches::Images>.

=head1 BASE CLASS(ES)

L<CXGN::Search::DBI::Simple::WWWQuery>

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

=none

=item none yet

=back

=head1 DESCRIPTION

coming soon

=head1 NORMAL QUERY PARAMETERS (FUNCTIONS)

These are query parameters that act in the normal way defined by
L<CXGN::Search::QueryI>.

=cut

=head1 AUTHOR(S)

    Jessica Reuter (adapted from ...People::Query by Evan Horst/Robert Buels)

=cut

sub _cached_dbh() {
	our $_cached_dbc ||= CXGN::DB::Connection->new('metadata');
}

#package configuration
my $public = 'public';
my $sgn_people = 'sgn_people';
my $metadata = 'metadata';

__PACKAGE__->selects_data("$metadata.md_image.image_id",
			  "$metadata.md_image.name",
			  "$metadata.md_image.description",
			  "$metadata.md_image.original_filename",
			  "sgn_people.sp_person.sp_person_id",
			  "sgn_people.sp_person.first_name",
			  "sgn_people.sp_person.last_name");

__PACKAGE__->join_root("$metadata.md_image");

__PACKAGE__->uses_joinpath('image_person_path',
			   ["$sgn_people.sp_person", "$sgn_people.sp_person.sp_person_id=metadata.md_image.sp_person_id"]);
__PACKAGE__->uses_joinpath('image_tag_path',
			   ["$metadata.md_tag_image", "$metadata.md_tag_image.image_id=metadata.md_image.image_id"],
			   ["$metadata.md_tag", "$metadata.md_tag.tag_id= $metadata.md_tag_image.tag_id"],
			   );

__PACKAGE__->has_parameter(name    => 'image_id',
			   columns => "$metadata.md_image.image_id",
				       );
__PACKAGE__->has_parameter(name    => 'image_tag',
			   columns => "$metadata.md_tag.name",
				       );

__PACKAGE__->has_parameter(name    => 'name',
			   columns => "$metadata.md_image.name",
				       );

__PACKAGE__->has_parameter(name    => 'description',
			   columns => "$metadata.md_image.description",
				       );

__PACKAGE__->has_parameter(name    => 'filename',
			   columns => "$metadata.md_image.original_filename",
				       );

__PACKAGE__->has_parameter(name    => 'submitter_id',
 			   columns => "sgn_people.sp_person.sp_person_id",
 				       );

__PACKAGE__->has_parameter(name    => 'submitter_first_name',
 			   columns => "sgn_people.sp_person.first_name",
 				       );

__PACKAGE__->has_parameter(name    => 'submitter_last_name',
 			   columns => "sgn_people.sp_person.last_name",
    );

##this does not work with postgres 8.3!!! 
# __PACKAGE__->has_complex_parameter(name    => 'submitter',
# 				   uses    => [qw/submitter_last_name, submitter_first_name, submitter_id/],
#  				   setter  => sub {
# 				       my ($self, @args) = @_;
# 				       $self->submitter_last_name(@args);
# 				       $self->submitter_first_name(@args);
# 				       $self->submitter_id(@args);
# 				       $self->compound('&t OR &t OR &t', 'submitter_last_name', 'submitter_first_name', 'submitter_id');
# 				   }
# 				   );

#but this does: 
__PACKAGE__->has_parameter(name   =>'submitter',
	                   columns=>["$sgn_people.sp_person.first_name",
	                             "$sgn_people.sp_person.last_name",
				     "$sgn_people.sp_person.sp_person_id"],
	                   sqlexpr=>"$sgn_people.sp_person.last_name || $sgn_people.sp_person.first_name 
                                     || $sgn_people.sp_person.sp_person_id",
   );

=head2 _remove_enclosing_percents

Remove the percent signs that may have been put on bindvalues given to DBI, since DBI would rather see
$this->param("ilike ?", "%$param%")
than
$this->param("ilike '%?%'", $param)

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

=cut

sub _to_scalars {
	my ($this) = @_;
	
	my %scalars;
	($scalars{description_filename_composite}) = _remove_enclosing_percents($this->param_bindvalues('filename')) if $this->param_bindvalues('filename');
	#($scalars{submitter_composite}) = _remove_enclosing_percents($this->param_bindvalues('submitter_id')) if $this->param_bindvalues('submitter_id');
	
	($scalars{submitter})=  _remove_enclosing_percents($this->param_bindvalues('submitter')) if $this->param_bindvalues('submitter');
	($scalars{image_id}) = _remove_enclosing_percents($this->param_bindvalues('image_id')) if $this->param_bindvalues('image_id');
	($scalars{name}) = _remove_enclosing_percents($this->param_bindvalues('name')) if $this->param_bindvalues('name');
	($scalars{description}) = _remove_enclosing_percents($this->param_bindvalues('description')) if $this->param_bindvalues('description');
        ($scalars{filename}) = _remove_enclosing_percents($this->param_bindvalues('filename')) if $this->param_bindvalues('filename');
	($scalars{submitter_id}) = _remove_enclosing_percents($this->param_bindvalues('submitter_id')) if $this->param_bindvalues('submitter_id');
	($scalars{submitter_first_name}) = _remove_enclosing_percents($this->param_bindvalues('submitter_first_name')) if $this->param_bindvalues('submitter_first_name');
	($scalars{submitter_last_name}) = _remove_enclosing_percents($this->param_bindvalues('submitter_last_name')) if $this->param_bindvalues('submitter_last_name');
	($scalars{image_tag}) = _remove_enclosing_percents($this->param_bindvalues('image_tag')) if $this->param_bindvalues('image_tag');
	
	$scalars{page} = $this->page;
	return %scalars;
}

=head2 request_to_params

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

sub request_to_params {
  my ($this, %request) = @_;

  #sanitize all the parameters
  foreach my $key (keys %request)
  {
    if( $request{$key} ) {
      $request{$key} = CXGN::Tools::Text::trim($request{$key});
      $request{$key} =~ s/[;'",]//g;
    }
  }
  
	#ILIKE is PostgreSQL-specific
        if($request{description_filename_composite}) {
		$this->description_filename_composite("ILIKE ?", "%$request{description_filename_composite}%");
	}
        if($request{submitter_composite}) {
		$this->submitter_composite("ILIKE ?", "%$request{submitter_composite}%");
	}

        if($request{image_id}) {
		$this->image_id("=?", "$request{image_id}");
	}
	if($request{name}) {
		$this->name(" ILIKE ?", "%$request{name}%");
	}
	if($request{description}) {
		$this->description(" ILIKE ?", "%$request{description}%");
	}
        if($request{filename}) {
		$this->filename(" ILIKE ?", "%$request{filename}%");
	}
        
        #if($request{submitter_id}) {
 	#	$this->submitter_id("ILIKE ?", "$request{submitter_id}");
 	#}
        #if($request{submitter_first_name}) {
 	#	$this->submitter_first_name(" ILIKE ?", "%$request{submitter_first_name}%");
 	#}
        #if($request{submitter_last_name}) {
 	#	$this->submitter_last_name(" ILIKE ?", "%$request{submitter_last_name}%");
 	#}
        if ($request{submitter}) {
                $this->submitter("ILIKE ? ", "%$request{submitter}%");
        }
        if($request{image_tag}) {
		$this->image_tag(" ILIKE ?", "%$request{image_tag}%");
	}

  #page number
  if(defined $request{page}) {
    $this->page($request{page});
  }

  $this->order_by(submitter_last_name => 'ASC');
}

#html for the query form
sub to_html {
	my $this = shift;
	
	#parameters need to be uniqified in the html form so they can be deuniqified and recognized later as belonging to this specific query class
	my $composite = $this->uniqify_name('description_filename_composite');
	my $submitter_composite = $this->uniqify_name('submitter_composite');

        my $image_id = $this->uniqify_name('image_id');
	my $name = $this->uniqify_name('name');
	my $description = $this->uniqify_name('description');
        my $filename = $this->uniqify_name('filename');
	my $submitter_id = $this->uniqify_name('submitter_id');
	my $submitter_first_name = $this->uniqify_name('submitter_first_name');
	my $submitter_last_name = $this->uniqify_name('submitter_last_name');
	my $image_tag = $this->uniqify_name('image_tag');
	my $submitter= $this->uniqify_name('submitter');
	my %scalars = $this->_to_scalars();
	return <<EOHTML;
This page allows you to search images contained in the SGN databases.
<br />
All images may not have names or explicit descriptions associated with them.
<br /><br />
<table width="600" border="0">
	<tr>
		<td>
			<b>Search criteria</b>
			<br /><br />
			<center>
			<table border="0">
			       
				<tr>
					<td>Image descriptors (name, description, or filename):</td>
					<td><input type="text" name="$composite" value="$scalars{description_filename_composite}" /></td>
				</tr>
				<tr>
					<td>Submitter (name or ID):</td>
					<td><input type="text" name="$submitter" value="$scalars{submitter}" /></td>
				</tr>
				<tr>
					<td>Image tag:</td>
					<td><input type="text" name="$image_tag" value="$scalars{image_tag}" /></td>
				</tr>
			</table>
			</center>
			<br /><br />
			<input type="reset" value="Reset" />
			&nbsp; &nbsp; &nbsp;<input type="submit" value="Search" />
		</td>
	</tr>
</table>
<br /><br />
EOHTML
}

# Composite parameter routine so quick search can look in name, image description, and filename for descriptive data about an image
sub description_filename_composite {
    my ($self, @args) = @_;
    $self->name(@args);
    $self->description(@args);
    $self->filename(@args);
    $self->compound('&t OR &t OR &t','name', 'description','filename');
}

# Composite parameter routine so main search can identify a submitter two different ways
sub submitter_composite {
    my ($self, @args) = @_;
    $self->submitter_id(@args);
    $self->submitter_last_name(@args);
    $self->compound('&t OR &t','submitter_id', 'submitter_last_name');
}

# Quick Search Routine
sub quick_search {
    my ($self,$term) = @_;
    $self->description_filename_composite('ILIKE ?', "%$term%");
    return $self;
}

###
1;#do not remove
###
