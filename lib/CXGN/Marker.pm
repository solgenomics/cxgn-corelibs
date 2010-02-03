
=head1 NAME

CXGN::Marker

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Marker object for retrieving marker data. It is streamlined to work fairly efficiently with both scripts which only want one or two pieces of marker data, and scripts which want all of a marker's data. The module for storing marker data is a subclass of this, CXGN::Marker::Modifiable.

=cut

use strict;
package CXGN::Marker;
use CXGN::Marker::Tools;
use CXGN::Marker::Location;
use CXGN::Marker::PCR::Experiment;
use CXGN::Marker::RFLP::Experiment;
use CXGN::Map::Tools;
use CXGN::Tools::Text;
use CXGN::DB::Connection;
use Carp;

=head2 new

    my $marker=CXGN::Marker->new($dbh,$marker_id);

Takes a dbh and marker ID and returns a marker object.

=cut

#this is the constructor for a marker whose data you want to get from the database. you must send in a dbh and a marker id. this returns undef if the marker is not found.
sub new
{
    my $class=shift;
    my($dbh,$marker_id)=@_; 
    my $self=bless({},$class);
    if(CXGN::DB::Connection::is_valid_dbh($dbh))
    {
        $self->{dbh}=$dbh;
    }
    else
    {
        croak"You must supply a dbh as the first argument to the marker constructor";
    }
    unless($marker_id and $marker_id=~/^\d+$/ and $marker_id>0)
    {
        croak"Marker ID '$marker_id' is not a valid ID";
    }
    $self->{marker_id}=CXGN::Marker::Tools::is_valid_marker_id($dbh,$marker_id);
    unless($self->{marker_id})
    {
        warn"Marker ID '$marker_id' not found in database";
        return undef;
    }
    return $self;
}

=head2 new_with_name

 Usage:        my $marker = CXGN::Marker->new($dbh, $name)
 Desc:         retrieves the marker with name $name.
               The name must be in the marker_alias table 
               as the preferred name (which is unique).
 Ret:          a CXGN::Marker object
 Args:         a database handle, and a marker name [string]
 Side Effects: accesses the database

=cut

sub new_with_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
    
    my $query = "SELECT marker_id FROM sgn.marker_alias WHERE alias ilike ? and preferred='t'";
    my $sth = $dbh->prepare($query);
    $sth->execute($name);
    my ($marker_id) = $sth->fetchrow_array();
    if (!defined($marker_id)) { return undef; }
    my $self = $class->new($dbh, $marker_id);
    return $self;
}



=head2 _should_we_run_query

For internal use only.

=cut

#store whether this query has already been run, so we don't have to run it again.
#this helps optimize the speed of the display object, for scripts that use a lot of them.
#also, it prevents the Modifiable subclass from being able to clobber its own modifications by calling accessors 
#which reload data from the database.
sub _should_we_run_query
{
    my $self=shift;
    my($query_name)=@_;

    #if we do not have a marker id yet, we are a new marker being created for future insertion. therefore, our 
    #data will not be in the database, and running a query would be unnecessary and/or bad.
    unless($self->{marker_id})
    {
        return 0;
    }    
    
    #if this query has already been run, return that we do not need to run it again
    if($self->{data_populated}->{$query_name})
    {
        return 0;
    }

    #if it hasn't already been run, note that we assume it will be now be run, and return that it should be run
    $self->{data_populated}->{$query_name}=1;
    return 1;

}

=head2 as_string

    print $marker->as_string();

Returns a string of this markers data for debugging.

=cut

#for debugging and such
sub as_string
{
    my $self=shift;
    
    #any time you need a fully populated marker, you must run populate_from_db    
    $self->populate_from_db();

    my $string='';
    $string.="<marker>\n";
    $string.="Name(s): ".CXGN::Tools::Text::list_to_string(@{$self->{marker_names}});

    if($self->{marker_id})
    {
        $string.="\tSGN-M$self->{marker_id}\n";
    }
    else
    {
        $string.="\t(Marker not yet inserted into database)\n";
    }

    $string.="Collections: ".CXGN::Tools::Text::list_to_string(@{$self->{collections}})."\n";
    for my $location(@{$self->{locations}})
    {
        $string.="Location:\tMap version ID '$location->{map_version_id}'\tLinkage group ID '$location->{lg_id}'\tPosition '$location->{position}'\tConfidence '$location->{confidence}'\tSubscript '$location->{subscript}'\n";
        $string.="Mapped via:\tPCR exp ID: '$location->{pcr_experiment_id}'\tRFLP exp ID: '$location->{rflp_experiment_id}'\n";
    }
    $string.="Non-mapping PCR experiments:\n";
    for my $pcr_id(@{$self->{non_mapping_pcr_experiment_ids}})
    {
        $string.=CXGN::Marker::PCR::Experiment->new($self->{dbh},$pcr_id)->as_string();        
    }

    $string.="</marker>\n";

    return $string;
}

=head2 marker_id

    my $id=$marker->marker_id();

Returns this markers ID.

=cut

#you cannot set the marker id except in the constructor
sub marker_id
{
    my $self=shift;
    return $self->{marker_id};
}

=head2 name_that_marker

    my $marker_name=$marker->name_that_marker();
    my @marker_names=$marker->name_that_marker();

Returns a the preferred alias, or all aliases starting with the preferred, depending on what you are expecting.

=cut

#the marker name is stored as a "preferred" alias
sub name_that_marker
{
    my $self=shift;
    if($self->_should_we_run_query('name_that_marker'))
    {
        my $name_q = $self->{dbh}->prepare("select alias from marker_alias where marker_id=? order by preferred desc,alias");
        $name_q->execute($self->{marker_id});
        while(my ($alias) = $name_q->fetchrow_array())
        {
            push(@{$self->{marker_names}},$alias);
	}
    }
    if(wantarray)
    {
        return @{$self->{marker_names}};
    }
    else
    {
        return $self->{marker_names}->[0];
    }
}

=head2 collections

    my $collections=$marker->collections();

Returns an arrayref of this markers collections.

=cut

#this is a list of groups this marker is considered to be a part of. this is usually a list of one or two collection names.
sub collections
{
    my $self=shift;
    if($self->_should_we_run_query('collections'))
    {
        my $collections_q=$self->{dbh}->prepare
        ('
            select 
                mc_name 
            from 
                marker 
                inner join marker_collectible using (marker_id) 
                inner join marker_collection using (mc_id) 
            where 
                marker.marker_id=?
        ');
        $collections_q->execute($self->{marker_id});
        while(my($collection)=$collections_q->fetchrow_array())
        {
            push(@{$self->{collections}},$collection);
        }
    }
    return $self->{collections};
}

=head2 derived_from_sources

    my $sources=$marker->derived_from_sources();
    if($sources)
    {
        for my $source(@{$sources})
        {
            my $source_name=$source->{source_name};
            my $id_in_source=$source->{id_in_source};
            print"Marker is from source '$source_name' with ID '$id_in_source'\n";
        }
    }

Returns an arrayref of sources whence this marker came.

=cut

#ids of all sources from which this marker was derived
sub derived_from_sources
{
    my $self=shift;
    if($self->_should_we_run_query('derived_from_sources'))
    { 
        my $sources_q=$self->{dbh}->prepare
        ('
            select 
                source_name,
                derived_from_source_id,
                id_in_source 
            from 
                marker_derived_from 
                inner join derived_from_source using (derived_from_source_id) 
            where 
                marker_id=?
        ');
        $sources_q->execute($self->{marker_id});
	$self->{derived_from_sources}=$sources_q->fetchall_arrayref({});
    }
    return $self->{derived_from_sources};
}

=head2 experiments

    my $exps=$marker->experiments();
    if($exps)
    {
        for my $exp(@{$exps})
        {
            if($exp->{location}){print $exp->{location}->as_string();}
            if($exp->{pcr_experiment}){print $exp->{pcr_experiment}->as_string();}
            if($exp->{rflp_experiment}){print $exp->{rflp_experiment}->as_string();}            
        }
    }

Returns an arrayref of hashrefs with keys 'location', 'pcr_experiment', and 'rflp_experiment' which have values which are objects of these types.

=cut

#get information about all of this marker's locations on various maps
sub experiments
{
    my $self=shift;
    my $dbh=$self->{dbh};
    if($self->_should_we_run_query('experiments'))
    {
        #the order-bys in this SQL statement make the marker_experiment entries with MORE information
        #show up FIRST. the reason for doing this is that the display page (markerinfo.pl) assumes
        #that if it has already displayed a location or experiment, that it does not need to display
        #it again. if an entry with MORE information came LATER in the list, it might be overlooked
        #by markerinfo. so, to reiterate:
        # 
        #SOME OF THESE ORDER-BYS ARE IMPORTANT FOR THE WEBPAGE DISPLAY!
        #IF YOU CHANGE THEM, SOME DATA MAY NOT SHOW UP ON THE WEBSITE! 
        my $locations_q=$dbh->prepare
        ('
            select 
                marker_experiment_id,
                location_id,
                pcr_experiment_id,
                rflp_experiment_id,
                protocol
            from
                marker_experiment
                left join marker_location using (location_id)
            where
                marker_id=?
            order by
                map_version_id desc,
                subscript,
                pcr_experiment_id,
                rflp_experiment_id,
                protocol
        ');
        #SOME OF THESE ORDER-BYS ARE IMPORTANT FOR THE WEBPAGE DISPLAY!
        #IF YOU CHANGE THEM, SOME DATA MAY NOT SHOW UP ON THE WEBSITE!
        $locations_q->execute($self->{marker_id});
        while(my ($marker_experiment_id,$location_id,$pcr_experiment_id,$rflp_experiment_id,$protocol)=$locations_q->fetchrow_array())
        {
            my %experiment;
            if($location_id)
            {
                $experiment{location}=CXGN::Marker::Location->new($dbh,$location_id);
            }
            if($pcr_experiment_id)
            {
                $experiment{pcr_experiment}=CXGN::Marker::PCR::Experiment->new($dbh,$pcr_experiment_id);
            }
            if($rflp_experiment_id)
            {            
                $experiment{rflp_experiment}=CXGN::Marker::RFLP::Experiment->new($dbh,$rflp_experiment_id);
            }
            $experiment{protocol}=$protocol;
            $experiment{marker_experiment_id}=$marker_experiment_id;
            push(@{$self->{experiments}},\%experiment);
        }
        my $orphan_pcr_notification='';
        #grab any remaining pcr_experiments even if they are missing their marker_experiment entries
        my $orphan_pcr_q=$dbh->prepare
        ('
            select
                pcr_experiment_id
            from
                pcr_experiment
                left join marker_experiment using (pcr_experiment_id)
            where
                marker_experiment.pcr_experiment_id is null
                and pcr_experiment.marker_id=?
        ');
        $orphan_pcr_q->execute($self->{marker_id});
        while(my ($orphan_pcr_id)=$orphan_pcr_q->fetchrow_array())
        {
            my %experiment;
            $experiment{pcr_experiment}=CXGN::Marker::PCR::Experiment->new($dbh,$orphan_pcr_id);
            push(@{$self->{experiments}},\%experiment);
            $orphan_pcr_notification.=$self->name_that_marker()." has orphan PCR experiment ID '$orphan_pcr_id'\n";          
        }
        if($orphan_pcr_notification)
        {
            #turn this once when beth is finished fixing the known ones
            #CXGN::Apache::Error::notify('found orphan PCR experiment',$orphan_pcr_notification);
        }
    }
    return $self->{experiments};
}

=head2 populate_from_db

    $marker->populate_from_db();

Fully populates the object. Mainly for use by CXGN::Marker::Modifiable to ensure that the marker is in a consistent state.

=cut

#this function MUST contain all of the accessors which populate this object, because it is used by the Modifiable subclass, which MUST have a fully populated object.
#if you add a marker accessor which retrieves data from the database (as the others do), you MUST call it here.
sub populate_from_db
{
    my $self=shift;
    $self->name_that_marker();
    $self->collections();
    $self->derived_from_sources();
    $self->experiments();                
}





#----------------------------------------------------------------------------
#the following functions are different from those above. they do not populate 
#the object, and they do not store any state.  they are just used to get 
#ancillary data about a marker. probably other markerinfo.pl functions should
#be moved into here eventually. 
#
#these COULD populate the object, but most of them won't need to be called more 
#than once. also, this module kind of works hand in hand with CXGN::Marker::Modifiable, 
#so I think it would be confusing if the marker could store state in itself, but not
#store that state to the database. as this module stands now, all state which
#it can store in itself it can also store in the database.
#----------------------------------------------------------------------------
=head2 current_mapping_experiments

    my $experiments=$marker->current_mapping_experiments();

Usually these are the ones you are interested in, right? Note: this does not get the simple non-mapping polymorphism tests.

=cut

sub current_mapping_experiments
{
    my $self=shift;
    my @current_mapping_experiments;
    my $experiments=$self->experiments();
    if($experiments and @{$experiments})
    {
        for my $experiment(@{$self->{experiments}})
        {
            if($experiment->{location})
            {
                my $map_version_id=$experiment->{location}->map_version_id();
                if(CXGN::Map::Tools::is_current_version($self->{dbh},$map_version_id))
                {
                    push(@current_mapping_experiments,$experiment);
                }               
            }
        }
    }
    return \@current_mapping_experiments;
}

=head2 upa_experiments

    my $experiments=$marker->upa_experiments();

This gets the COSII iUPA and eUPA experiments.

=cut

sub upa_experiments
{
    my $self=shift;
    my @upa_experiments;
    my $experiments=$self->experiments();
    if($experiments and @{$experiments})
    {
        for my $experiment(@{$self->{experiments}})
        {
            if
            (
                !$experiment->{location}#if there is no associated location 
                and $experiment->{pcr_experiment}#and this is a PCR experiment (not RFLP)
                and#and there is some primer type given
                (
                    $experiment->{pcr_experiment}->primer_type() eq 'iUPA'
                    or $experiment->{pcr_experiment}->primer_type() eq 'eUPA'
                )
            )
            {
                #then it is one of feinan's COSII iUPA or eUPA experiments
                push(@upa_experiments,$experiment);
            }
        }
    }
    return \@upa_experiments;
}

=head2 comments

    print $marker->comments();

Returns marker comment text. 

=cut

sub comments 
{
    my $self=shift;  
    my $dbh=$self->{dbh};
    my $id=$dbh->quote($self->{marker_id});
    my ($comment)=$dbh->selectrow_array("SELECT comment_text from metadata.attribution as a inner join metadata.comments as c using(attribution_id) where a.table_name = 'markers' and row_id = $id");
    return $comment;
}

=head2 marker_page_link

    print"<a href=\"".$marker->marker_page_link()."\">[Link to marker]</a>";

Returns the stuff that goes in the 'href' attribute of the 'a' tag which will take you to a markers page.

=cut

#get a link to a marker's info page
sub marker_page_link
{
    my $self=shift;
    return"/search/markers/markerinfo.pl?marker_id=$self->{marker_id}";
}

=head2 cosii_unigenes

    my @unigenes=$marker->cosii_unigenes();

Returns an array of hashrefs with COSII unigene data.

=cut

#special marker data accessors
sub cosii_unigenes
{
    my $self=shift;
    unless($self->is_in_collection('COSII')){return;}
    my $dbh=$self->{dbh};
    my @unigenes;
    my $unigene_query=$dbh->prepare('select unigene_id,copies,database_name,sequence_name from cosii_ortholog where marker_id=?');
    $unigene_query->execute($self->{marker_id});
    my $unigene_results_ref=$unigene_query->fetchall_arrayref();
    my @unigene_results=@{$unigene_results_ref};
    for(0..$#unigene_results)
    {
        $unigenes[$_]={};
        $unigenes[$_]->{unigene_id}=$unigene_results[$_][0];
        $unigenes[$_]->{copies}=$unigene_results[$_][1];
        $unigenes[$_]->{database_name}=$unigene_results[$_][2];
        $unigenes[$_]->{sequence_name}=$unigene_results[$_][3];
        if($unigenes[$_]->{unigene_id})
        {
            my $unigeneq=$dbh->prepare("SELECT groups.comment from unigene LEFT JOIN unigene_build USING (unigene_build_id) LEFT JOIN groups ON (groups.group_id=unigene_build.organism_group_id) where unigene_id=?");
            $unigeneq->execute($unigenes[$_]->{unigene_id});
            my($org_group_name)=$unigeneq->fetchrow_array();
            $unigenes[$_]->{organism}=$org_group_name;
        }
        else{$unigenes[$_]->{organism}=undef;}
    }
    return @unigenes;
}


################################################
#tools
################################################
#finds whether this marker is in a collection

=head2 is_in_collection

    if($marker->is_in_collection('COSII')){print"This marker is a COSII marker."}

Takes a collection name and returns a 1 if the marker is in the collection or a 0 if not.

=cut

sub is_in_collection
{
    my $self=shift;
    my($collection_maybe)=@_;
    unless($collection_maybe){return 0;}
    my $collections=$self->collections();
    for my $collection(@{$collections})
    {
        if($collection_maybe eq $collection)
        {
            return 1;
	}    
    }
    return 0;
}

1;
