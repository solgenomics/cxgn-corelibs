use strict;
use CXGN::DB::Connection;
use CXGN::People;

package CXGN::Metadata;
use base('CXGN::DB::Connection');

sub new {
    my $class      = shift;
    my $db_name    = shift;
    my $table_name = shift;
    my $id         = shift;

    my $self = $class->SUPER::new();

    $self->set_db_name($db_name);
    $self->set_table_name($table_name);
    $self->set_row_id($id);

    return $self;
}

=head2 function get_db_name

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub get_db_name {
    my $self = shift;
    return $self->{db_name};
}

=head2 function set_db_name

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub set_db_name {
    my $self = shift;
    $self->{db_name} = shift;
}

=head2 function get_table_name

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub get_table_name {
    my $self = shift;
    return $self->{table_name};
}

=head2 function set_table_name

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub set_table_name {
    my $self = shift;
    $self->{table_name} = shift;
}

=head2 function get_id

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub get_row_id {
    my $self = shift;
    return $self->{row_id};
}

=head2 function set_row_id

Synopsis:	
Arguments:	
Returns:	
Side effects:	
Description:	

=cut

sub set_row_id {
    my $self = shift;
    $self->{row_id} = shift;
}

sub comments {
    my $self           = shift;
    my $comments_query = $self->prepare(
'select comment_text from comments inner join attribution using (attribution_id) where database_name=? and table_name=? and row_id=?'
    );
    $comments_query->execute( $self->{db_name}, $self->{table_name},
        $self->{row_id} );
    my @comments;
    while ( my ($comment) = $comments_query->fetchrow_array() ) {
        push( @comments, $comment );
    }
    if   (@comments) { return \@comments; }
    else             { return undef; }
}

sub attribute_bac_to_chromosome {
    my $self = shift;
    my ( $bac_id, $chromosome ) = @_;
    if ( defined($chromosome) ) {
        if ( my $proj = $self->get_project_associated_with_bac($bac_id) ) {

            #remove the existing attribution
            warn
"WARNING: moving BAC $bac_id from chromosome $proj to chromosome $chromosome";
            $self->attribute_bac_to_chromosome( $bac_id, undef );
        }

        #find chromosome project id
        my $project_object = CXGN::People::Project->new($self);
        my $projects       = $project_object->get_projects_with_name_like(
            "Tomato Chromosome $chromosome Sequencing Project");
        my $project_id = $projects->[0][0];
        if ( defined($project_id) ) {

#this insert says, "there is a bac that is going to be attributed to some person, project, or organization"
            my $attribution_insert = $self->prepare(
"insert into attribution (database_name,table_name,primary_key_column_name,row_id) values ('genomic','clone','clone_id',?)"
            );
            $attribution_insert->execute($bac_id);
            my $id_query = $self->prepare(
                "select currval('attribution_attribution_id_seq')");
            $id_query->execute();
            my @id = $id_query->fetchrow_array();
            $id_query->finish();
            my $attribution_id = $id[0];

 #print STDERR "\n\nATTRIBUTION ID: $attribution_id\n\n";
 #this insert says, "attribute this bac to the person/project/organization/role"
            my $attribution_to_insert = $self->prepare(
"insert into attribution_to (attribution_id,person_id,organization_id,project_id,role_id) values (?,?,?,?,?)"
            );
            $attribution_to_insert->execute( $attribution_id, undef, undef,
                $project_id, undef );

       #        warn"$bac_id attributed with attribution id $attribution_id.\n";
            return $attribution_id;
        }
    }
    else {

        #remove the attribution of a bac to a chromosome
        $self->do( <<EOQ, undef, 'genomic', 'clone', 'clone_id', $bac_id );
delete from attribution where database_name = ? and table_name = ? and primary_key_column_name = ? and row_id = ?
EOQ

        #the attribution_to table will be taken care of by the
        #ON DELETE CASCADE of its attribution_id foreign key column
        return;
    }

    #warn"Project not found.\n";
    return;
}

sub attribute_bac_to_project {
    my ( $self, $bac_id, $project_id ) = @_;

    if ( defined($project_id) ) {
        if ( my $proj = $self->get_project_associated_with_bac($bac_id) ) {

            #remove the existing attribution
            $self->attribute_bac_to_project( $bac_id, undef );
        }

#this insert says, "there is a bac that is going to be attributed to some person, project, or organization"
        my $attribution_insert = $self->prepare(
"insert into attribution (database_name,table_name,primary_key_column_name,row_id) values ('genomic','clone','clone_id',?)"
        );
        $attribution_insert->execute($bac_id);
        my $id_query =
          $self->prepare("select currval('attribution_attribution_id_seq')");
        $id_query->execute();
        my @id = $id_query->fetchrow_array();
        $id_query->finish();
        my $attribution_id = $id[0];

 #print STDERR "\n\nATTRIBUTION ID: $attribution_id\n\n";
 #this insert says, "attribute this bac to the person/project/organization/role"
        my $attribution_to_insert = $self->prepare(
"insert into attribution_to (attribution_id,person_id,organization_id,project_id,role_id) values (?,?,?,?,?)"
        );
        $attribution_to_insert->execute( $attribution_id, undef, undef,
            $project_id, undef );

       #        warn"$bac_id attributed with attribution id $attribution_id.\n";
        return $attribution_id;
    }
    else {

        #remove the attribution of a bac to a chromosome
        $self->do( <<EOQ, undef, 'genomic', 'clone', 'clone_id', $bac_id );
delete from attribution where database_name = ? and table_name = ? and primary_key_column_name = ? and row_id = ?
EOQ

        #the attribution_to table will be taken care of by the
        #ON DELETE CASCADE of its attribution_id foreign key column
        return;
    }
}

sub get_project_associated_with_bac {
    my $self          = shift;
    my ($bac_id)      = @_;
    my $project_query = $self->prepare(
"select project_id from attribution inner join attribution_to on attribution.attribution_id=attribution_to.attribution_id where database_name='genomic' and table_name='clone' and row_id=?"
    );
    $project_query->execute($bac_id);
    my ($proj_id) = $project_query->fetchrow_array();

    #warn"\n\nASSOCIATED WITH PROJECT: '$proj_id'\n\n";
    return $proj_id;
}

1;

package CXGN::Metadata::Attribution;

use base('CXGN::Metadata');

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    @{ $self->{attributions} } = ();

    $self->_fetch_attribution_data();

    return $self;
}

sub _fetch_attribution_data {
    my $self = shift;

    #print "ROW-ID: ".$self->get_row_id()."\n";
    my $q = "
        SELECT 
            person_id, 
            sp_organization.name, 
            sp_project.name, 
            role_name, 
            attribution.attribution_id 
        FROM 
            attribution 
            inner join attribution_to using(attribution_id)
            left join roles using (role_id)
            left join sgn_people.sp_organization on (organization_id=sp_organization_id)
            left join sgn_people.sp_project on (project_id=sp_project_id) 
         WHERE  
            attribution.database_name=? 
            and attribution.table_name=? 
            and attribution.row_id=?
    ";

    my $h = $self->prepare($q);
    $h->execute( $self->get_db_name(), $self->get_table_name(),
        $self->get_row_id() );
    my %attribution;
    while (
        my ( $person_id, $organization, $project, $role_name, $attribution_id )
        = $h->fetchrow_array() )
    {

        #print "PERSON-ID: $person_id, RPOJECT_ID: $project_id etc...\n";
        $attribution{person} = CXGN::People::Person->new( $self, $person_id );
        $attribution{organization} = $organization;
        $attribution{project}      = $project;

        #print "project name: ".($attribution{project}->get_name())."\n";
        $attribution{role} = $role_name;

        #print "Attribution_id: $attribution_id\n";
        push @{ $self->{attributions} }, \%attribution;

    }
}

=head2 function get_attributions

Synopsis:	
Arguments:	
Returns:      a list of hashes containing objects, hash keys are person, project, organization and a string, role.	
Side effects:	
Description:	

=cut

sub get_attributions {
    my $self = shift;
    return @{ $self->{attributions} };
}

1;
