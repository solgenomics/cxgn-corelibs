
use strict;

package CXGN::Insitu::ExperimentSearch;

use base qw / CXGN::Search::DBI::Simple CXGN::Search::WWWSearch /;

__PACKAGE__->creates_result("CXGN::Insitu::ExperimentSearchResult");
__PACKAGE__->uses_query("CXGN::Insitu::ExperimentSearchQuery");

package CXGN::Insitu::ExperimentSearchResult;

use base qw /CXGN::Search::BasicResult/;

package CXGN::Insitu::ExperimentSearchQuery;

use base qw/ CXGN::Search::DBI::Simple::WWWQuery /;

use CXGN::Page::FormattingHelpers qw /simple_selectbox_html
  info_table_html
  hierarchical_selectboxes_html
  conditional_like_input_html
  /;

my $s   = 'insitu';
my $p   = 'sgn_people';

#__PACKAGE__->selects_data("$s.experiment.name", "$s.experiment.tissue", "$s.experiment.stage", "$s.experiment.description", "$s.primer.name", "$s.primer.clone", "$s.image.name", "$s.image.description", "$p.sp_person.last_name", "$p.sp_person.first_name");

__PACKAGE__->selects_data("$s.experiment.experiment_id");

# set up the table that everything will join to
#
__PACKAGE__->join_root("$s.experiment");

# set up the join paths to the above table
#
__PACKAGE__->uses_joinpath( "probepath",
    [ "$s.probe", "$s.probe.probe_id = $s.experiment.probe_id" ] );
__PACKAGE__->uses_joinpath( "imagepath",
    [ "$s.image", "$s.image.experiment_id=$s.experiment.experiment_id" ] );
__PACKAGE__->uses_joinpath( "peoplepath",
    [ "$p.sp_person", "$p.sp_person.sp_person_id=$s.experiment.user_id" ] );
__PACKAGE__->uses_joinpath(
    "organism_joinpath",
    [
        "$s.is_organism",
        "$s.experiment.is_organism_id=$s.is_organism.is_organism_id"
    ]
);

# add the parameter to field mappings
#
__PACKAGE__->has_parameter(
    name    => "experiment_name",
    columns => "$s.experiment.name",
);
__PACKAGE__->has_parameter(
    name    => "exp_tissue",
    columns => "$s.experiment.tissue",
);
__PACKAGE__->has_parameter(
    name    => "exp_stage",
    columns => "$s.experiment.stage",
);
__PACKAGE__->has_parameter(
    name    => "exp_description",
    columns => "$s.experiment.description",
);
__PACKAGE__->has_parameter(
    name    => "probe_name",
    columns => "$s.probe.name",
);
__PACKAGE__->has_parameter(
    name    => "probe_identifier",
    columns => "$s.probe.identifier",
);
__PACKAGE__->has_parameter(
    name    => "image_name",
    columns => "$s.image.name",
);
__PACKAGE__->has_parameter(
    name    => "image_description",
    columns => "$s.image.description",
);
__PACKAGE__->has_parameter(
    name    => "person_last_name",
    columns => "$p.sp_person.last_name",
);
__PACKAGE__->has_parameter(
    name    => "person_first_name",
    columns => "$p.sp_person.first_name",
);
__PACKAGE__->has_parameter(
    name    => "organism_name",
    columns => "$s.is_organism.name",
);
__PACKAGE__->has_parameter(
    name    => "common_name",
    columns => "$s.is_organism.common_name",
);

# override the request_to_params function to refine the SQL from
# the user's input (such as adding wildcards etc.)
#
sub request_to_params {
    my $self   = shift;
    my %params = @_;

    # make all parameters substring searches.
    #
    foreach my $k ( keys %params ) {

        # add the condition only if the user entered a parameter
        if ( defined( $params{experiment_name} ) ) {
            $self->experiment_name( "ILIKE ?", "%$params{experiment_name}%" );
        }
        if ( defined( $params{exp_tissue} ) ) {
            $self->exp_tissue( "ILIKE ?", "%$params{exp_tissue}%" );
        }
        if ( defined( $params{exp_stage} ) ) {
            $self->exp_stage( "ILIKE ?", "%$params{exp_stage}%" );
        }
        if ( defined( $params{exp_description} ) ) {
            $self->exp_description( "ILIKE ?", "%$params{exp_description}%" );
        }
        if ( defined( $params{probe_name} ) ) {
            $self->probe_name( "ILIKE ?", "%$params{probe_name}%" );
        }
        if ( defined( $params{probe_description} ) ) {
            $self->probe_description( "ILIKE ?",
                "%$params{probe_description}%" );
        }
        if ( defined( $params{probe_identifier} ) ) {
            $self->probe_identifier( "ILIKE ?", "%$params{probe_identifier}%" );
        }
        if ( defined( $params{image_name} ) ) {
            $self->image_name( "ILIKE ?", "%$params{image_name}%" );
        }
        if ( defined( $params{image_description} ) ) {
            $self->image_description( "ILIKE ?",
                "%$params{image_description}%" );
        }
        if ( defined( $params{person_first_name} ) ) {
            $self->person_first_name( "ILIKE ?",
                "%$params{person_first_name}%" );
        }
        if ( defined( $params{person_last_name} ) ) {
            $self->person_last_name( "ILIKE ?", "%$params{person_last_name}%" );
        }
        if ( defined( $params{common_name} ) ) {
            $self->common_name( "ILIKE ?", "%$params{common_name}%" );
        }
        if ( defined( $params{organism_name} ) ) {
            $self->organism_name( "ILIKE ?", "%$params{organism_name}%" );
        }

    }

    if ( defined( $params{page} ) ) {
        $self->page( $params{page} );
    }
}

# override _to_scalars to re-populate the form from the previous
# user input
#
sub _to_scalars {
    my $self = shift;

    my %params = ();

    my @keys = (
        "experiment_name",   "exp_stage",
        "exp_tissue",        "exp_description",
        "probe_name",        "probe_description",
        "probe_identifier",  "image_name",
        "image_description", "person_first_name",
        "person_last_name",  "common_name",
        "organism_name"
    );
    foreach my $k (@keys) {
        ( $params{$k} ) = $self->param_bindvalues($k);
        $params{$k} =~ s/\%//g;
    }

    return %params;
}

sub to_html {
    my $self = shift;

    my %scalars = $self->_to_scalars();

    my %fields = ();

    my @keys = (
        "experiment_name",   "exp_stage",
        "exp_tissue",        "exp_description",
        "probe_name",        "probe_description",
        "probe_identifier",  "image_name",
        "image_description", "person_first_name",
        "person_last_name",  "organism_name",
        "common_name"
    );

    #    my @keys =( "experiment_id");
    foreach my $k (@keys) {
        $fields{$k} = $self->uniqify_name($k);
    }

    my $return_string = undef;

    $return_string = <<HTML;

<center> 
<table summary=\"\">
    <tr><td>Experiment name: </td><td><input name=\"$fields{experiment_name}\" value=\"$scalars{experiment_name}\" /></td></tr>
    <tr><td>Tissue: </td><td><input name=\"$fields{exp_tissue}\" value=\"$scalars{exp_tissue}\" /></td></tr>
    <tr><td>Stage:  </td><td><input name=\"$fields{exp_stage}\" value=\"$scalars{exp_stage}\" /></td></tr>
    <tr><td>Description:</td><td><input name=\"$fields{exp_description}\" value=\"$scalars{exp_description}\"  /></td></tr>
    <tr><td>Probe name: </td><td><input name=\"$fields{probe_name}\" value=\"$scalars{probe_name}\" /></td></tr>
    <tr><td>Probe identifier: </td><td><input name=\"$fields{probe_identifier}\" value=\"$scalars{probe_identifier}\" /></td></tr>
    <tr><td>Image name: </td><td><input name=\"$fields{image_name}\" value=\"$scalars{image_name}\" /></td></tr>
    <tr><td>Image description: </td><td><input name=\"$fields{image_description}\" value=\"$scalars{image_description}\" /></td></tr>
    <tr><td>Submitter first name:</td><td><input name=\"$fields{person_first_name}\" value=\"$scalars{person_first_name}\" /></td></tr>
    <tr><td>Last name: </td><td><input name=\"$fields{person_last_name}\" value=\"$scalars{person_last_name}\" /></td></tr>
    <tr><td>Organism name: </td><td><input name=\"$fields{organism_name}\" value=\"$scalars{organism_name}\" /></td></tr>
    <tr><td>Organism common name:  </td><td><input name=\"$fields{common_name}\" value=\"$scalars{common_name}\" /></td></tr>
    </table>
    <input type=\"submit\" value=\"Search\" />
</center>

HTML

    return $return_string;
}

# Quick search routine
sub quick_search {
    my ( $self, $term ) = @_;
    $self->name( 'ILIKE ?', "%$term%" );
    return $self;
}

return 1;
