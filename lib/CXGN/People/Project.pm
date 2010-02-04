
=head1 NAME

CXGN::People::Projects - a class to handle projects, particularly tomato genome sequencing projects.

=head1 DESCRIPTION

A class to interrogate the database about projects. The object is not specific to one project, but represents a collection of all projects.

=head1 AUTHORS

 Lukas Mueller, John Binns, Robert Buels.

 Copyleft (c) Sol Genomics Network. All rights reversed.

=cut

package CXGN::People::Project;

use strict;
#use CXGN::Class::DBI;
#use base qw/CXGN::Class::DBI/;

use base qw | CXGN::DB::Object |;

=head2 constructor new()

 Usage:        my $p = CXGN::People::Project->new($dbh);
 Desc:         creates a new CXGN::People::Project object
 Args:         a database handle 
 Side Effects: 
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
#    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    $self->set_sql();
    return $self;
}

=head2 get_projects_with_name_like

 Usage:        my @project = $p ->get_projects_with_name_like('$name');
 Desc:         returns a list of project_ids whose name matches $name
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_projects_with_name_like {
    my $self = shift;
    my ($comparison_string) = @_;
 	my $projects_query = $self->get_sql("projects_by_name");
    $projects_query->execute($comparison_string);
    my $projects = $projects_query->fetchall_arrayref();
    $projects_query->finish();
    return $projects;
}

=head2 get_name_from_project_id

 Usage:        my $name = get_name_from_project_id($id)
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_name_from_project_id {
    my $self = shift;
    my ($project_id) = @_;
    my $name_query = $self->get_sql('name_by_id');
    $name_query->execute($project_id);
    my @name_result = $name_query->fetchrow_array();
    $name_query->finish();
    my $name = $name_result[0];
    return $name;
}


=head2 function distinct_country_projects()

 Usage:        @p = $p->distinct_country_projects()
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:
 Notes:        this was converted to a class method, as it has been used as such.
               a database handle was added as a parameter.

=cut

sub distinct_country_projects {
	my $class = shift;
	my $dbh  = shift; # CXGN::DB::Connection->new();  *** refactored
	my $helper = CXGN::People::Project->new($dbh);
	my $sth = $helper->get_sql('distinct_country_projects');
	$sth->execute();
	return $sth->fetchall_arrayref();
}


=head2 all_projects

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub all_projects {
	my $self = shift;
 	my $sth = $self->get_sql('all_projects'); 
	$sth->execute();
	return $sth->fetchall_arrayref();
}

### SQL helper functions

sub set_sql {
    my $self = shift;
    $self->{queries} = {
	
		projects_by_name =>

			"	
				SELECT sp_project_id 
				FROM sp_project 
				WHERE name LIKE ?
			",

		name_by_id =>
		
			"
				SELECT name 
				FROM sp_project 
				WHERE sp_project_id=?
			",
		

		distinct_country_projects =>
			
			"
				SELECT DISTINCT 
					(	SELECT sp_project_id 
						FROM sgn_people.sp_project s 
						WHERE s.description=os.description 
						ORDER BY sp_project_id limit 1) AS sp_project_id, 
					description 
				FROM 
					sgn_people.sp_project os 
				WHERE
					sp_project_id <= 12
				ORDER BY 
					sp_project_id
			",

		all_projects =>

			"	
				SELECT sp_project_id,description 
				FROM sgn_people.sp_project 
				ORDER BY sp_project_id
			",

	};
	while(my($k,$v) = each %{$self->{queries}}){
	    $self->{query_handles}->{$k}=$self->get_dbh()->prepare($v);
	}

}

sub get_sql { 
    my $self = shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}


###
1;#do not remove
###
