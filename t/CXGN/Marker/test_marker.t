#!/usr/bin/perl
use strict;
use warnings;
#use CXGN::Error::Backtrace;
use CXGN::Marker;
use CXGN::Marker::Modifiable;
use CXGN::Marker::Tools;
use CXGN::Marker::Location;
use CXGN::Marker::PCR::Experiment;
use CXGN::Marker::RFLP::Experiment;
use CXGN::DB::Connection;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;
my $ERRORS;
open($ERRORS,'>errors.txt');
my $dbh=CXGN::DB::Connection->new({dbhost=>'scopolamine',dbname=>'sandbox',dbschema=>'sgn',dbuser=>'update',dbpass=>'dontcare'});
my @dirty_names=CXGN::Marker::Tools::dirty_marker_names($dbh);
ok(!@dirty_names,'All marker names should be clean');
if(@dirty_names)
{
    print"Dirty names:\n";
    for(@dirty_names)
    {
        print"$_ cleans to ".CXGN::Marker::Tools::clean_marker_name($_)."\n";
    }
}
my $consistent_lg_q=$dbh->prepare('select * from marker_location inner join linkage_group using (lg_id) where marker_location.map_version_id<>linkage_group.map_version_id');
$consistent_lg_q->execute();
my @oops=$consistent_lg_q->fetchrow_array();
ok(!@oops,'lg_ids and map_version_ids should be consistent');
my $no_orphan_pcr_q=$dbh->prepare('select * from pcr_experiment left join marker_experiment using (pcr_experiment_id) where marker_experiment.pcr_experiment_id is null');
$no_orphan_pcr_q->execute();
@oops=$no_orphan_pcr_q->fetchrow_array();
ok(!@oops,'Should be no orphan PCR experiments');
print"======================================================\n";
my $id_q=$dbh->prepare('select marker_id from marker order by marker_id');
my $name_q=$dbh->prepare
("
    select 
        alias 
    from 
        marker_alias 
    where 
        marker_id=? 
        and preferred='t'
");
my $collections_q=$dbh->prepare
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
my $sources_q=$dbh->prepare
('
    select 
        source_name,
        id_in_source 
    from 
        marker_derived_from 
        inner join derived_from_source using (derived_from_source_id) 
    where 
        marker_id=?
');
my $experiments_q=$dbh->prepare
('
    select 
        location_id,
        pcr_experiment_id,
        rflp_experiment_id,
        protocol
    from
        marker_experiment
    where
        marker_id=?
');
my($names_found,$experiments_found,$sources_found,$collectibles_found)=(0,0,0,0);
$id_q->execute();
my $marker;
while(my($marker_id)=$id_q->fetchrow_array())
{

    #make a marker out of all marker ids in database
    $marker=CXGN::Marker->new($dbh,$marker_id);
    isa_ok($marker,'CXGN::Marker');

    #make a modifiable marker to load this marker's data into.
    #the goal here is to make a marker which contains no new data, just old data.
    #we will try to store it, but calling the store function SHOULD end up having no effect on the database.
    my $duplicate_modifiable=CXGN::Marker::Modifiable->new($dbh);

    #test marker id
    ok($marker_id==$marker->marker_id(),"Marker ID $marker_id");

    #test marker name
    $name_q->execute($marker_id);
    my ($marker_name)=$name_q->fetchrow_array();
    my ($oops_name)=$name_q->fetchrow_array();
    unless(ok(!$oops_name,"Should only be one preferred name."))
    {
        print $ERRORS "Should only be one preferred name, but found at least 2: $marker_name and $oops_name.\n";
    }
    ok($marker_name eq $marker->name_that_marker(),"Marker name $marker_name should be the same as ".$marker->name_that_marker());
    my @names=$marker->name_that_marker();
    $names_found+=@names;
    $duplicate_modifiable->set_marker_name($marker_name);

    #test collections
    $collections_q->execute($marker_id);
    my $collections=$marker->collections();
    if($collections){$collectibles_found+=@{$collections};}
    while(my($collection)=$collections_q->fetchrow_array())
    {
        ok((grep {$_ eq $collection} @{$collections}),"Collection $collection");
        $duplicate_modifiable->add_collection($collection);
    }

    #test derivations
    $sources_q->execute($marker_id);
    my $sources=$marker->derived_from_sources();
    if($sources){$sources_found+=@{$sources};}
    while(my($source,$id_in_source)=$sources_q->fetchrow_array())
    {
        ok
        (
            (
                grep 
                {
                    my $matches=0;
                    if($_->{source_name} eq $source)
                    {
			if(!defined($_->{id_in_source}) and !defined($id_in_source))
                        {
                            $matches=1;
                        }
                        else
                        {
                            if(defined($_->{id_in_source}) and defined($id_in_source))
                            {
                                if($_->{id_in_source}==$id_in_source)
                                {
                                    $matches=1;    
                                }
                            }    
                        }
                    }
                    $matches;
                } 
                @{$sources}
	    ),$id_in_source?"Source $source ID: ".$id_in_source:"Source $source ID: NULL"
        );
        $duplicate_modifiable->add_source({source_name=>$source,id_in_source=>$id_in_source});        
    }

    #test locations/experiments
    $experiments_q->execute($marker_id);
    my $experiments=$marker->experiments();
    if($experiments){$experiments_found+=@{$experiments};}    
    while(my($location_id,$pcr_experiment_id,$rflp_experiment_id,$protocol)=$experiments_q->fetchrow_array())
    {
        $location_id||='';
        $pcr_experiment_id||='';
        $rflp_experiment_id||='';
        $protocol||='';
        my($location,$pcr,$rflp);
        if($location_id)
        {
            $location=CXGN::Marker::Location->new($dbh,$location_id);
        }
        if($pcr_experiment_id)
        {
            $pcr=CXGN::Marker::PCR::Experiment->new($dbh,$pcr_experiment_id);    
            $protocol=$pcr->protocol();
        }
        if($rflp_experiment_id)
        {
            $rflp=CXGN::Marker::RFLP::Experiment->new($dbh,$rflp_experiment_id);
            $protocol=$rflp->protocol();
        }
        ok
        (
            (
                grep 
                {
                    my $matches=1;
                    if($_->{location} xor $location){$matches=0;}
                    if($_->{location} and $location)
                    {
                        if($_->{location}->equals($location))
                        {
                            #print $location->as_string();
                        }
                        else
                        {
                            $matches=0;
                        }
                    }
                    if($_->{pcr_experiment} xor $pcr){$matches=0;}
                    if($_->{pcr_experiment} and $pcr)
                    {
                        if($_->{pcr_experiment}->equals($pcr))
                        {
                            #print $pcr->as_string();
                        }
                        else
                        {
                            $matches=0;
                        }
                    }
                    if($_->{rflp_experiment} xor $rflp){$matches=0;}
                    if($_->{rflp_experiment} and $rflp)
                    {
                        if($_->{rflp_experiment}->equals($rflp))
                        {        
                            #print $rflp->as_string();
                        }
                        else
                        {
                            $matches=0;
                        }
                    }
                    if($_->{protocol} xor $protocol){$matches=0;}
                    if($_->{protocol} and $protocol)
                    {
                        if($_->{protocol} eq $protocol)
                        {
                            #
                        }
                        else
                        {
                            $matches=0;
                        }
                    }
                    $matches;
                } 
                @{$experiments}
	    ),"Location ID '$location_id', PCR ID '$pcr_experiment_id', RFLP ID '$rflp_experiment_id', subtype '$protocol'"
	);

        #if the pcr or rflp experiment object is keeping track of the protocol, we are not allowed to send it in (this prevents inconsistencies)
        if($pcr or $rflp)
        {
            $protocol=undef;
	}

        $duplicate_modifiable->add_experiment({location=>$location,pcr_experiment=>$pcr,rflp_experiment=>$rflp,protocol=>$protocol});        
    }

    #now cheat by setting the marker's id manually, which will indicate to the object that it DOES already exist, but MAYBE some of its data is new.
    #then if we try to store it, it should check to see if it has new data and only store the new data.
    #it should find that it has NO NEW DATA and it should not do anything.
    $duplicate_modifiable->{marker_id}=$marker_id;
    my $stored;
    my $error;
    eval
    {
        $stored=@{$duplicate_modifiable->store_new_data()};
    };
    unless(ok(!$@,"Should not die on store attempt"))
    {
        print "$@\n";
        print $ERRORS "$@\n";
    }
    unless(ok(!$stored,'Should not store any data'))
    {
        print "Marker object returned $stored data insertions for marker $marker_id\n";
        print $ERRORS "Marker object returned $stored data insertions for marker $marker_id\n";
    }

    #test that a new marker cannot be created with an existing marker name
    $duplicate_modifiable->{marker_id}=undef;
    dies_ok {$duplicate_modifiable->store_new_data()};

    print"-----------------------------------------------------------\n";
}

#test some counts of table entries which were obtained in different ways
my $exps_count_q=$dbh->prepare("select count(*) from marker_experiment");
$exps_count_q->execute();
my($exps_count)=$exps_count_q->fetchrow_array();
ok($exps_count==$experiments_found,"$exps_count experiment entries found should match $experiments_found experiments");
my $collectibles_count_q=$dbh->prepare("select count(*) from marker_collectible");
$collectibles_count_q->execute();
my($collectibles_count)=$collectibles_count_q->fetchrow_array();
ok($collectibles_count==$collectibles_found,"$collectibles_count collectibles entries found should match $collectibles_found collectibles");
my $names_count_q=$dbh->prepare("select count(*) from marker_alias");
$names_count_q->execute();
my($names_count)=$names_count_q->fetchrow_array();
ok($names_count==$names_found,"$names_count names entries found should match $names_found names");
my $sources_count_q=$dbh->prepare("select count(*) from marker_derived_from");
$sources_count_q->execute();
my($sources_count)=$sources_count_q->fetchrow_array();
ok($sources_count==$sources_found,"$sources_count sources entries found should match $sources_found sources");

close $ERRORS;
$dbh->rollback();
