package CXGN::Marker::Modifiable;
=head1 NAME

CXGN::Marker::Modifiable

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Subclass of CXGN::Marker object used for storing new marker data and adding new data to an existing marker.

=cut

use strict;
use warnings;
use CXGN::Marker::Tools;
use CXGN::Marker::PCR::Experiment;
use CXGN::Marker::Location;
use CXGN::Tools::Text;
use CXGN::DB::SQLWrappers;
use Carp;

use base('CXGN::Marker');

=head2 new

    my $marker=CXGN::Marker::Modifiable->new($dbh);

Create a new marker to be stored.

    my $existing_marker_to_add_data=CXGN::Marker::Modifiable->new($dbh,$marker_id);

Get an existing marker but add new data to it.

=cut

#sending in a marker id means retrieve that marker from the database. not sending one in means you're going to create one. 
sub new 
{
    my $class=shift;
    my($dbh,$marker_id)=@_;
    unless(CXGN::DB::Connection::is_valid_dbh($dbh))
    {
        croak"'$dbh' is not a valid dbh";
    }
    if(defined($marker_id))
    {
        unless($marker_id=~/^\d+$/ and $marker_id>0)
        {
            croak"Invalid marker ID '$marker_id'";
        }
    }
    my $self;

    #if we have a marker id, we can use the superclass constructor, as long as we also fully populate the object from the database, 
    #so it is guaranteed to be fully populated when we try to save it.
    if($marker_id)
    {
        $self=$class->SUPER::new(@_);
        unless($self){croak"Could not create a marker object from marker ID '$marker_id'";}
    }
    #otherwise, we are creating an empty marker object.
    else
    {
        $self=bless({},$class);
        $self->{dbh}=$dbh;
    }

    unless($self)
    {
        croak"Could not create modifiable marker";
    }

    #if this is an existing marker, we must populate it.
    #if it is a new marker, we must make it realize that it is already populated 
    #so it does not clobber our new data with empty database query results.
    $self->populate_from_db();  

    #get an sql wrapper for use when storing data
    $self->{sql}=CXGN::DB::SQLWrappers->new($self->{dbh});

    return $self;
}

=head2 new_pcr_experiment, new_rflp_experiment, new_location

    my $new_pcr_exp_obj=$marker->new_pcr_experiment();
    my $new_rflp_exp_obj=$marker->new_rflp_experiment();
    my $new_location_obj=$marker->new_location();

Syntactic sugar for creating new objects of these classes.

=cut

sub new_pcr_experiment
{
    my $self=shift;
    return CXGN::Marker::PCR::Experiment->new($self->{dbh});
}

sub new_rflp_experiment
{
    my $self=shift;
    return CXGN::Marker::RFLP::Experiment->new($self->{dbh});
}

sub new_location
{
    my $self=shift;
    return CXGN::Marker::Location->new($self->{dbh});
}    

=head2 set_marker_name

    $marker->set_marker_name('c2-blah/?_333');

Sets the markers preferred name. If you want to add another alias for this marker, youll need to do it in the database, since its a rare occurrence. There may be a server-side database function we have written to do it. 

=cut

sub set_marker_name
{
    my $self=shift;
    my($name)=@_;
    unless($name)
    {
        croak"You did not send in a name";
    }
    my($clean_name,$subscript)=CXGN::Marker::Tools::clean_marker_name($name);
    if($subscript)
    {
        croak"You must extract marker subscripts yourself using clean_marker_name on '$name'. How smart do you think I am?";
    }
    unless($clean_name=~/^(\w|\-|\?|\/|\.)+$/)
    {
        croak"'$clean_name' is not a valid marker name";
    }
    if(my $name=$self->name_that_marker())
    {
        croak"Marker is already named '$name'; cannot change its name to '$clean_name'";
    }
    $self->{marker_names}->[0]=$clean_name;
}

=head2 add_collection

    $marker->add_collection('COSII');

Add a collection name (not collection ID) to a markers attributes. A marker can be part of any number of collections, but usually that number is only 1 or 2. 

=cut

sub add_collection
{
    my $self=shift;
    my($collection)=@_;
    unless($collection)
    {
        croak"You did not send in a collection";
    }
    if($collection=~/^\d+$/)
    {
        croak"You must send in a collection name, not an ID ('$collection')";
    }

    #Feel free to remove or modify this block if it gets annoying
    unless($collection eq 'TM' or $collection eq 'P' or $collection eq 'COS' or $collection eq 'COSII' or $collection eq 'KFG')
    {
        croak"Collection '$collection' does not exist";        
    }

    unless(CXGN::Marker::Tools::get_collection_id($self->{dbh},$collection))
    {
        croak"Collection '$collection' does not already exist; you must add it manually so I can find its ID";
    }
    if($self->is_in_collection($collection))
    {
        warn"Marker ".$self->name_that_marker()." is already in collection '$collection'";
        return;
    }
    push(@{$self->{collections}},$collection);

    #Feel free to remove or modify this block if it gets annoying
    if($self->{collections} and scalar(@{$self->{collections}})>2)
    {
        warn"This marker's number of collections is getting pretty high. It is now in ".scalar(@{$self->{collections}})." collections.";
    }
}

=head2 add_source

    $marker->add_source({source_name=>'EST BY READ',id_in_source=>3});

This is how we say that a marker comes from an EST, for instance. A marker could have any number of sources, but usually that number is only 1 or 2. You must send in a hashref with the appropriate values.

=cut

sub add_source
{
    my $self=shift;
    my($source_hash)=@_;
    unless($source_hash->{source_name})
    {
        croak"You must send add_source a hash ref with a value for key 'source_name'";
    }
    if($source_hash->{source_name}=~/^\d+$/)
    {
        croak"You must send in a source name, not an ID ('$source_hash->{source_name}')";
    }
    unless(exists($source_hash->{id_in_source}))#note: this CAN be null, which indicates id_in_source is not known
    {
        croak"You must send add_source a hash ref with key 'id_in_source' (whose value CAN be undef)";
    }
    $source_hash->{derived_from_source_id}=CXGN::Marker::Tools::get_derived_from_source_id($self->{dbh},$source_hash->{source_name});
    unless($source_hash->{derived_from_source_id})
    {
        croak"Source '$source_hash->{source_name}' was not found in the database; you will need to add it manually";
    }
    for my $existing_source_hash(@{$self->{derived_from_sources}})
    {
        if((uc($source_hash->{source_name}) eq uc($existing_source_hash->{source_name}))and($source_hash->{id_in_source}==$existing_source_hash->{id_in_source}))
        {
            warn"Marker '".$self->name_that_marker()."' already has entry for source '$existing_source_hash->{source_name}' and ID in source '$existing_source_hash->{id_in_source}'";
            return;
        }
    }
    push(@{$self->{derived_from_sources}},$source_hash);
}

=head2 add_experiment

Add an entry for the marker_experiment table, to be stored by this object later, when store_new_data is called.
Protocol should be specified when sending in a location on its own. When sending in an experiment object with
the location, the experiment object will be expected to contain the protocol, so in that case, do not send it in.

Add a map location with no related experiment data:

    $marker->add_experiment({location=>$location_object,protocol=>'RFLP'});

Add a map location which was discovered by way of a PCR experiment:

    $marker->add_experiment({location=>$location_object,pcr_experiment=>$pcr_experiment_object});

Add a map location which was discovered by way of an RFLP experiment:

    $marker->add_experiment({location=>$location_object,rflp_experiment=>$rflp_experiment_object});

=cut

sub add_experiment
{
    my $self=shift;
    my($experiment)=@_;
    my $new_location=$experiment->{location};#get values from the hashref that was sent in
    my $new_pcr=$experiment->{pcr_experiment};
    my $new_rflp=$experiment->{rflp_experiment};
    my $protocol='[MODIFIABLE MARKER OBJECT FAILED TO SET]';#just temporarily sticking something in there, but a missing protocol should be caught by the following code anyway
    if($experiment->{protocol} and ($new_pcr or $new_rflp))#if we are sending in a protocol, but there is also an experiment sent in, we could just ask the experiment for its protocol
    {
        croak"Protocol ($experiment->{protocol}) must be set in the experiment object (unless there is no experiment object).";
    }
    if($new_location)
    {
        unless($new_location->isa('CXGN::Marker::Location'))
        {
            croak"Parameter '$new_location' is not a CXGN::Marker::Location object";
        }        
        unless($new_pcr or $new_rflp)#unless we can find the protocol from the experiment objects...
        {
            unless($protocol=$experiment->{protocol})#we will need to get the protocol from the caller right now
            {
                croak"If you do not send in an experiment with a location, you must send in the protocol to add_experiment. Use 'unknown' if necessary";
            }
        }
    }
    if($new_pcr)
    {
        unless($new_pcr->isa('CXGN::Marker::PCR::Experiment'))
	{
            croak"Parameter '$new_pcr' is not a PCR experiment";  
        }
        $protocol=$new_pcr->protocol();#get protocol from pcr experiment object, rather than from the hash sent in
    }
    if($new_rflp)
    {
        unless($new_rflp->isa('CXGN::Marker::RFLP::Experiment'))
        {
            croak"Parameter '$new_rflp' is not an RFLP experiment";         
        }
        $protocol=$new_rflp->protocol();#get protocol from rflp experiment object, rather than from the hash sent in
    }
    unless($new_location or $new_pcr or $new_rflp)
    {
        croak"add_experiment must be called with a hash ref with key 'location' pointing to a location object, and/or key 'pcr_experiment' pointing to a pcr experiment object, and/or key 'rflp_experiment' pointing to an rflp experiment object";
    }
    unless($protocol eq 'AFLP' or $protocol eq 'CAPS' or $protocol eq 'dCAPS' or $protocol eq 'RAPD' or $protocol eq 'SNP' or $protocol eq 'SSR' or $protocol eq 'RFLP' or $protocol eq 'PCR' or $protocol =~/DArT/i or $protocol =~ /OPA/i or $protocol eq 'unknown')
    {
        croak"Protocol '$protocol' is invalid.";
    }
    $experiment->{protocol}=$protocol;#ok, now we've gotten the protocol, one way or the other
    
    #check to see we don't have this experiment-location already. if so, don't add it again.
    if($self->{experiments})#if we have some experiments, either retrieved from the db at creation time, or from previous calls to this method
    {
        for my $existing_experiment(@{$self->{experiments}})#for the experiments we do have
        {
            my $existing_location=$existing_experiment->{location};
            my $existing_pcr=$existing_experiment->{pcr_experiment};
            my $existing_rflp=$existing_experiment->{rflp_experiment};
            my $existing_protocol=$existing_experiment->{protocol};
            if(($existing_location xor $new_location) or ($existing_pcr xor $new_pcr) or ($existing_rflp xor $new_rflp))#if we have one but not the other filled in for each column of the marker_experiment table, then the rows are certainly not the same
            {
                #continue towards the push below, because we have not found a possbile match                
            }
            elsif($existing_protocol eq 'RFLP' and $protocol ne 'RFLP')#if the one we found is RFLP and this one is not, then they don't match
            {
                #continue towards the push below, because we have not found a possbile match    
            }
            elsif($existing_protocol ne 'RFLP' and $protocol eq 'RFLP')#if the one we found is not RFLP and this one is, then they don't match
            {
                #continue towards the push below, because we have not found a possbile match   
            }
            else#else... maybe we DO have it already... let's check a little deeper and find out for sure
            {
                if(!$existing_location or ($existing_location and $existing_location->equals($new_location)))#if we don't have an existing location, or if we have both and they are equal, then we may still have a match
                {                    
                    if(!$existing_pcr or ($existing_pcr and $existing_pcr->equals($new_pcr)))#if we don't have an existing pcr, or if we have both and they are equal, then we may still have a match
                    {
                        if(!$existing_rflp or ($existing_rflp and $existing_rflp->equals($new_rflp)))#if we don't have an existing rflp, or if we have both and they are equal, then we... HAVE A MATCH!
                        {                            
                            return;#then an existing entry in this marker object is equivalent to the one you're trying to add, so there is no need to add it 
                        }
                    }
                }                
            }
        }
    }    

    push(@{$self->{experiments}},$experiment);#add it, as requested

}

=head2 store_new_data

    $marker->store_new_data();

Store all data for this marker which does not already exist in the database. 
This is unlike the more simple 'store_unless_exists' function which I have written for other objects, such as CXGN::Marker::Location.
This method will not make an all-or-nothing decision as to whether to 'store' this marker.
Instead, it will explore all of this markers data and only store the parts of it that are not already stored.
If you somehow manage to put this marker object into a state in which it has LESS data than the corresponding tables in the database, you are evil.
However, it will still try to insert any new data it contains.

=cut

sub store_new_data
{
    my $self=shift;
    my $dbh=$self->{dbh};
    my $sql=$self->{sql};
    my @inserts;
    my @marker_names=$self->name_that_marker();
    my($marker_name,@aliases)=@marker_names;
    my $q;

    #check that we have a name
    unless($marker_name)
    {
        croak"A marker must at least have a name before you try to insert it";
    }

    #if we don't have an id yet, check if we already have a marker with this name in the database. 
    #if so, there is a conflict, or we should have been given the existing marker's id when our constructor was called. 
    unless($self->{marker_id})
    {
        my @marker_ids;    
        for my $name(@marker_names)
        {
            if(CXGN::Marker::Tools::marker_name_to_ids($dbh,$name))
            {
                croak"Marker already exists in database with name '$name'. If you meant to modify this marker, you should have sent its ID to the constructor. If there really is a new marker with the same name as an old one, the world has come to an end. Insert it manually and refer to it by its ID.";
            }
        }
        $q=$dbh->prepare('insert into sgn.marker (marker_id) values (default)');
        $q->execute();
        $self->{marker_id}=$dbh->last_insert_id('marker') or croak "Unable to retrieve marker ID from database after insert";
        #print STDERR "INSERTING new marker SGN-M$self->{marker_id}.\n";
        push(@inserts,{marker=>$self->{marker_id}});
    
        #insert our preferred name
        my $alias_id=$sql->insert("marker_alias",{alias=>$marker_name,marker_id=>$self->{marker_id},preferred=>'t'});
        #print"INSERTING preferred alias '$marker_name'.\n";
        push(@inserts,{marker_alias=>$alias_id});

    }
    my $marker_id=$self->{marker_id};

    #see if all our aliases exist. if not, enter them.
    for my $alias(@aliases)
    {
        $q=$dbh->prepare('select marker_id from marker_alias where alias ilike ?');#yes, this is case-insensitive. even though markers can have different names based only on case, normally, that is a mistake!
        $q->execute($alias);
        if(my($id)=$q->fetchrow_array())
        {
            unless($id==$marker_id)
            {
                croak"Alias '$alias' found, but associated with marker ID '$id' instead of our ID ($marker_id)";
            }
        }
        else
        {
            my $alias_id=$sql->insert("marker_alias",{alias=>$alias,marker_id=>$marker_id,preferred=>'f'});
            #print"INSERTING other alias '$alias'.\n";
            push(@inserts,{marker_alias=>$alias_id});
	}
    }

    #insert our collections, unless they are already in the database
    my $collections=$self->collections();
    for my $collection(@{$collections})
    {
        my $collection_id=CXGN::Marker::Tools::get_collection_id($self->{dbh},$collection) or croak"Collection '$collection' does not exist";

        #see if this marker is already in the database as being part of this collection. if not, make it part of this collection.
        my $info=$sql->insert_unless_exists('marker_collectible',{marker_id=>$marker_id,mc_id=>$collection_id});
        if($info->{inserted})
	{
            #print"INSERTING marker_collectible ID $info->{inserted}.\n"
            push(@inserts,{marker_collectible=>$info->{id}});
	}
    }

    #insert our derivations, unless they are already in the database
    my $derived_froms=$self->derived_from_sources();
    for my $derived(@{$derived_froms})
    {
        unless($derived->{derived_from_source_id})
        {
            croak"No derived from source ID found";
        }

        #it is ok to have empty ID in source
        unless($derived->{id_in_source})
        {
            $derived->{id_in_source}=undef;
        }

        my $info=$sql->insert_unless_exists('marker_derived_from',{marker_id=>$marker_id,derived_from_source_id=>$derived->{derived_from_source_id},id_in_source=>$derived->{id_in_source}});        
        if($info->{inserted})
        {
            #print"INSERTING marker_derived_from.\n"
            push(@inserts,{marker_derived_from=>$info->{id}});            
        }
    }

    #insert our experiments, unless they are already in the database
    my $experiments=$self->experiments();
    if($experiments)
    {
        for my $experiment(@{$experiments})    
        {
            my($location_id,$pcr_id,$rflp_id);
            my $location=$experiment->{location};
            my $pcr=$experiment->{pcr_experiment};    
            my $rflp=$experiment->{rflp_experiment};
            if($location)
            {
                $location->marker_id($marker_id);
                if(my $location_id=$location->store_unless_exists())
                {
                    #print"INSERTED: Location\n";
                    push(@inserts,{marker_location=>$location_id});  
                }
                $location_id=$location->location_id() or croak"Could not get location_id from location object";
            }
            if($pcr)
            {
                $pcr->marker_id($marker_id);
                if(my $pcr_id=$pcr->store_unless_exists())
                {
                    #print"INSERTED: PCR\n";
                    push(@inserts,{pcr_experiment=>$pcr_id}); 
                }
                $pcr_id=$pcr->pcr_experiment_id() or croak"Could not get pcr_experiment_id from pcr experiment object";
            }
            if($rflp)
            {
                $rflp->marker_id($marker_id);
                if(my $rflp_id=$rflp->store_unless_exists())
                {
                    #print"INSERTED: RFLP\n";
                    push(@inserts,{rflp_markers=>$rflp_id}); 
                }
                $rflp_id=$rflp->rflp_id() or croak"Could not get rflp_id from rflp experiment object";
            }

            #store this marker_experiment entry unless it's already in the database
            my $protocol=$experiment->{protocol};
            my $info=$sql->insert_unless_exists('marker_experiment',{marker_id=>$marker_id,location_id=>$location_id,pcr_experiment_id=>$pcr_id,rflp_experiment_id=>$rflp_id,protocol=>$protocol});
            if($info->{inserted})
            {
                #print"INSERTING mapping marker_experiment for marker '$marker_id' location '$location_id' pcr '$pcr_id' rflp '$rflp_id' protocol '$protocol'\n";
                push(@inserts,{marker_experiment=>$info->{id}});            
            }
        }
    }

    #let the caller know if some data has been stored
    return \@inserts;

}

=head2 connect_experiment_to_location

Rather than calling store_new_data, which only handles new inserts, not updates, the CAPS loading script
must call this function instead. This function will take a newly created (and stored) experiment object
and connect it to an existing location which was loaded earlier by the map data loading script.

    $pcr->store_unless_exists();
    my @changed_rows=$marker->connect_experiment_to_location({pcr_experiment=>$pcr,location=>$loc});

=cut

sub connect_experiment_to_location
{
    my $self=shift;
    my($loc_exp_data)=@_;
    my $loc=$loc_exp_data->{location};

    #just a bunch of error checks
    ref($loc) eq 'CXGN::Marker::Location' or croak"connect_experiment_to_location needs a location object sent in through an anonymous hashref with key 'location'";
    $loc->location_id() or croak"connect_experiment_to_location needs you to store your location object before calling";
    my $pcr=$loc_exp_data->{pcr_experiment};
    my $rflp=$loc_exp_data->{rflp_experiment};
    ($pcr or $rflp) or croak"connect_experiment_to_location needs either a PCR or RFLP experiment object sent in through an anonymous hashref with key 'pcr_experiment' or 'rflp_experiment'";
    ($pcr and $rflp) and croak"connect_experiment_to_location needs either a PCR or RFLP experiment object sent in through an anonymous hashref with key 'pcr_experiment' or 'rflp_experiment'--NOT BOTH!";
    my($protocol,$pcr_id,$rflp_id);
    if($pcr)
    {
        ref($pcr) eq 'CXGN::Marker::PCR::Experiment' or croak"connect_experiment_to_location: thing found in pcr_experiment key is not a PCR experiment object";
        $pcr->pcr_experiment_id() or croak"connect_experiment_to_location needs you to store your PCR experiment object before calling";
        $protocol=$pcr->protocol();
        $pcr_id=$pcr->pcr_experiment_id();
    }
    if($rflp)
    {
        ref($rflp) eq 'CXGN::Marker::RFLP::Experiment' or croak"connect_experiment_to_location: thing found in rflp_experiment key is not an RFLP experiment object";    
        $rflp->rflp_id() or croak"connect_experiment_to_location needs you to store your RFLP experiment object before calling";
        $protocol=$rflp->protocol();  
        $rflp_id=$rflp->rflp_id();      
    }

    # check if marker experiment exists at all for this marker_id, location_id and protocol

    my $select = 'select marker_experiment_id from marker_experiment where marker_id = ? and location_id = ? and protocol = ?';
    my $sth = $self->{dbh}->prepare($select);
    $sth->execute($self->marker_id(),$loc->location_id(),$protocol);

    unless ($sth->fetchrow_array()) { die "marker experiment does not exist yet with this marker_id, location_id and protocol" }

    #get marker_experiment_ids to be updated

    my $q=$self->{dbh}->prepare('select marker_experiment_id from marker_experiment where marker_id=? and location_id=? and protocol=? and pcr_experiment_id is null and rflp_experiment_id is null');#only find the empty ones, in case some have already been connected, we don't want to screw with them
    $q->execute($self->marker_id(),$loc->location_id(),$protocol);

    #for each row to be updated, update it. this allows you to connect a stored experiment to an EXISTING marker_experiment entry
    my @changed_rows;
    while(my ($mxid) = $q->fetchrow_array())
    {
        my $sql='update marker_experiment set pcr_experiment_id=?,rflp_experiment_id=? where marker_experiment_id=?';
        my $q2=$self->{dbh}->prepare($sql);
        $q2->execute($pcr_id,$rflp_id,$mxid);
        push(@changed_rows,$mxid);
        #print STDERR "Executing\n$sql\nwith values\n($pcr_id,$rflp_id,$mxid)\n";
    }

    # if we've gotten this far and don't have some changed rows, figure out why
    # this is usually because the experiment already exists with an association
    unless (@changed_rows) {

        my $sth;

        if ($pcr) {
	    my $select = 'select marker_experiment_id from marker_experiment where pcr_experiment_id = ? and '
		.'location_id = ? and protocol = ? and rflp_experiment_id is null';
	    $sth = $self->{dbh}->prepare($select);
            $sth->execute($pcr_id,$loc->location_id(),$protocol);
        }

        elsif ($rflp) {
	    my $select = 'select marker_experiment_id from marker_experiment where rflp_experiment_id = ? '
		.'and location_id = ? and protocol = ? and pcr_experiment_id is null';
            $sth = $self->{dbh}->prepare($select);
            $sth->execute($rflp_id,$loc->location_id(),$protocol);
        }

        else {die "Should not get here" }

        my $existing;

        while (my ($existing_id) = $sth->fetchrow_array()) {
           # print "marker_experiment row '$existing_id' already exists with a location-experiment association like the one described.\n";
            $existing = 1;
        }
        unless ($existing) { die "I couldn't update any rows, but I don't know why." }
    }
    
    return @changed_rows;
}

1;
