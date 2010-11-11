
=head1 NAME

CXGN::Marker::PCR::Experiment

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

PCR experiment object for both retrieving and inserting marker experiment data.

=cut

use strict;
package CXGN::Marker::PCR::Experiment;
use Carp;
use CXGN::Marker;
use CXGN::Accession;
use CXGN::Tools::Text;
use Array::Compare;
use CXGN::DB::SQLWrappers;
use CXGN::Marker::Tools;
use CXGN::DB::Connection;

=head2 new

    my $experiment_for_viewing=CXGN::Marker::PCR::Experiment->new($dbh,$pcr_experiment_id);
    my $experiment_for_storing=CXGN::Marker::PCR::Experiment->new($dbh);

=cut

sub new
{
    my $class=shift;
    my($dbh,$pcr_experiment_id)=@_;
    my $self=bless({},$class);
    if(CXGN::DB::Connection::is_valid_dbh($dbh))
    {
        $self->{dbh}=$dbh;
    }
    else
    {
        croak("'$dbh' is not a valid dbh");
    }
    if($pcr_experiment_id)
    {

        #find experiment data
        my $pcr_query=$self->{dbh}->prepare
        ("
            SELECT
                marker_experiment.marker_id,
                marker_experiment.location_id,
                pcr_experiment.pcr_experiment_id,
                primer_id_fwd,
                primer_id_rev,
                primer_id_pd,
                primer_type,
                mg_concentration,
                annealing_temp,
                additional_enzymes,
                protocol,
                predicted,
                stock_id
            FROM
                pcr_experiment
                left join marker_experiment using (pcr_experiment_id)
            WHERE
                pcr_experiment_id=?
        ");
        $pcr_query->execute($pcr_experiment_id);
        my $pcr_hashref=$pcr_query->fetchrow_hashref();

# This was causing the page to die for markers 9654 and 9615. Not sure why this problem should
# suddenly turn up. These markers had entries in pcr_experiment but not in marker_experiment, 
# so John considered them valid, but "orphan" experiments. There is a query in CXGN/Marker.pm
# that specifically queries for orphan experiments. That's fine, but then the following check
# fails. For now I'm just changing the field it checks. This shouldn't break anything. -beth, 2007-03-21
#        unless($pcr_hashref->{marker_id})
        unless($pcr_hashref->{pcr_experiment_id})
        {
            croak"Orphan PCR experiment object created with ID of '$pcr_experiment_id'--there is no marker_experiment entry for this experiment";
        }
        unless($pcr_hashref->{pcr_experiment_id})
        {
            croak"PCR experiment not found with ID of '$pcr_experiment_id'";
        }
        while(my($key,$value)=each %$pcr_hashref)
        {
            $self->{$key}=$value;
        }
        $self->{predicted}?$self->{predicted}='t':$self->{predicted}='f';

        #get primers, if they are present
        my $q=$dbh->prepare('select sequence from sequence where sequence_id=?');
        $q->execute($self->{primer_id_fwd});
        ($self->{fwd_primer})=$q->fetchrow_array();
        $q->execute($self->{primer_id_rev});
        ($self->{rev_primer})=$q->fetchrow_array();


        $q->execute($self->{primer_id_pd});
	($self->{dcaps_primer})=$q->fetchrow_array();


        #get pcr products
        my $sizes;
        $q=$dbh->prepare("SELECT accession.accession_id,band_size,multiple_flag FROM pcr_exp_accession inner join pcr_product using(pcr_exp_accession_id) inner join accession on(pcr_exp_accession.accession_id=accession.accession_id) WHERE enzyme_id is null and pcr_experiment_id=?");
	$q->execute($self->{pcr_experiment_id});
        $sizes=$q->fetchall_arrayref();
        if($sizes->[0]){$self->{pcr_bands}=$self->query_results_to_bands_hash($sizes);}
        $q=$dbh->prepare("SELECT accession.accession_id,band_size,multiple_flag FROM pcr_exp_accession inner join pcr_product using(pcr_exp_accession_id) inner join accession on(pcr_exp_accession.accession_id=accession.accession_id) WHERE enzyme_id is not null and pcr_experiment_id=?");
	$q->execute($self->{pcr_experiment_id});
        $sizes=$q->fetchall_arrayref();
        if($sizes->[0]){$self->{pcr_digest_bands}=$self->query_results_to_bands_hash($sizes);}

        #get enzyme
        $q=$dbh->prepare("SELECT enzyme_id,enzyme_name FROM pcr_exp_accession inner join pcr_product using(pcr_exp_accession_id) inner join enzymes using(enzyme_id) where pcr_experiment_id=?");
        $q->execute($self->{pcr_experiment_id});
        ($self->{enzyme_id},$self->{enzyme})=$q->fetchrow_array();#only fetching one row, because they all should be the same. there should be both db and api constraints ensuring that.
    }
    else#else we're creating and empty object
    {
        #initialize empty object--we want some things to have a default value, so the object it will be consistent 
        #and able to be worked with even if you haven't set its predicted field, for instance
        $self->{predicted}='f';
    }

    return $self;
}

=head2 pcr_experiment_id

    my $id=$experiment->pcr_experiment_id();

Returns the PCR experiment ID for this experiment. This cannot be set. It is set when the object is initially retrieved, or when it is stored.

=cut

#this function cannot be used as a setter, since this id is assigned by the database
sub pcr_experiment_id
{
    my $self=shift;
    return $self->{pcr_experiment_id};
}

=head2 equals

    my $experiment=CXGN::Marker::PCR::Experiment->new($dbh,$pcr_experiment_id);
    my $experiment_for_comparison=CXGN::Marker::PCR::Experiment->new($dbh,$possible_match_id);
    if($experiment->equals($experiment_for_comparison)){print"They are the same!";}

=cut

##########################################
# compare this pcr experiment with another
##########################################

sub check_pcr_band_arrays {
    my ($accession, $pcr_hash_1, $pcr_hash_2) = @_;

    my $comp = Array::Compare->new();

    my $croaking = "PCR bands (or digest bands) entry for accession '$accession' does not appear to be array ref";
    
    unless ($pcr_hash_1->{$accession} and $pcr_hash_2->{$accession})           { return 0 }
    unless ((ref($pcr_hash_1->{$accession}) eq 'ARRAY'))                       { croak $croaking }
    unless ((ref($pcr_hash_2->{$accession}) eq 'ARRAY'))                       { croak $croaking }
    # Array::Compare::perm returns true if lists are the same or permutations of each other (bands may have been stored in any order)
    unless ($comp->perm($pcr_hash_1->{$accession}, $pcr_hash_2->{$accession})) { return 0 }

    return 1;
}

sub equals {
    my $self=shift;
    my($other)=@_;

    unless ($other->isa('CXGN::Marker::PCR::Experiment')) { croak "Must send in a PCR experiment object to equals function" }
    unless ($self->marker_id() and $other->marker_id()) { 
	                                                    croak "Must set both PCR experiment objects' marker IDs before comparing\n-----\nself:\n".
                                                       	    $self->as_string()."-----\nother:\n".$other->as_string() 
							}
    unless ($self->protocol() and $other->protocol())      { croak "Must set both PCR experiment objects' protocols before comparing" } 
    unless ($self->predicted() eq 'f' or $self->predicted() eq 't') { 
	                                                    croak "Can't check for equality; invalid predicted field for self:\n".$self->as_string();
							}
    unless ($other->predicted() eq 'f' or $other->predicted() eq 't') { 
	                                                    croak "Can't check for equality; invalid predicted field for other object:\n".$other->as_string();
							}
    if ($self->marker_id() ne $other->marker_id())                { return 0 }
    if ($self->fwd_primer() ne $other->fwd_primer())              { return 0 }
    if ($self->rev_primer() ne $other->rev_primer())              { return 0 }
    if ($self->primer_type() ne $other->primer_type())            { return 0 }
    if ($self->enzyme() ne $other->enzyme())                      { return 0 }
    if ($self->predicted() ne $other->predicted())                { return 0 }
    if ($self->protocol eq 'RFLP' and $other->protocol ne 'RFLP') { return 0 }
    if ($self->protocol ne 'RFLP' and $other->protocol eq 'RFLP') { return 0 }
    
    my $pcr_hash_1 = $self->{pcr_bands};
    my $pcr_hash_2 = $other->{pcr_bands};
    # remove empty keys
    for my $k (keys(%{$pcr_hash_1}))  { delete $pcr_hash_1->{$k} if (@{$pcr_hash_1->{$k}} == 0) }
    for my $k (keys(%{$pcr_hash_2}))  { delete $pcr_hash_2->{$k} if (@{$pcr_hash_2->{$k}} == 0) }

    # check pcr band arrays for all accessions in first object
    for my $accession (keys(%{$pcr_hash_1}))  { unless (&check_pcr_band_arrays($accession, $pcr_hash_1, $pcr_hash_2)) { return 0 } }

    # then check pcr band arrays for all accessions in second object, in case the second has accessions the first doesn't
    for my $accession (keys(%{$pcr_hash_2}))  { unless (&check_pcr_band_arrays($accession, $pcr_hash_1, $pcr_hash_2)) { return 0 } }

    $pcr_hash_1 = $self->{pcr_digest_bands};
    $pcr_hash_2 = $other->{pcr_digest_bands};
    # remove empty keys
    for my $k (keys(%{$pcr_hash_1}))  { delete $pcr_hash_1->{$k} if (@{$pcr_hash_1->{$k}} == 0) }
    for my $k (keys(%{$pcr_hash_2}))  { delete $pcr_hash_2->{$k} if (@{$pcr_hash_2->{$k}} == 0) }
    # check pcr digest band arrays for all accessions in first object
    for my $accession (keys(%{$pcr_hash_1}))  { unless (&check_pcr_band_arrays($accession, $pcr_hash_1, $pcr_hash_2)) { return 0 } }
    # then check pcr digest  band arrays for all accessions in second object, in case the second has accessions the first doesn't
    for my $accession (keys(%{$pcr_hash_2}))  { unless (&check_pcr_band_arrays($accession, $pcr_hash_1, $pcr_hash_2)) { return 0 } }

    #only compare mg and temp IF they are present in BOTH objects... see note below
    if (($self->mg_conc() and $other->mg_conc()) and ($self->mg_conc() != $other->mg_conc())) { return 0 }
    if (($self->temp() and $other->temp()) and ($self->temp() != $other->temp()))             { return 0 }

    #notes: 
    #we did not compare missing temperature or mg concentration values, because yimin says experiments that are so similar
    #that the only difference is that one is missing a temp or mg conc are the same experiment 
    #we did not compare additional_enzymes, because this is just a long text notes field, not essential data for the experiment, 
    #and frequently subject to minor changes in its text. this is just feinan's extra COSII PCR data field.

    return 1;
}

=head2 exists

Returns its pcr_experiment_id if it already exists in the database, or undef if not.

=cut

###################
# storing functions
###################
sub exists
{
    my $self=shift;
    unless($self->{marker_id})
    {
        croak"Cannot test for an experiment's existence without knowing which marker it goes with--store marker and set experiment's marker ID before storing experiments";
    }
    unless($self->{protocol})
    {
        croak"I doubt an experiment like this one exists, since it has no experiment protocol. Set to unknown if necessary.";
    }
    if($self->{pcr_experiment_id})
    {
        #warn"I think it's pretty obvious that this experiment exists, since it seems to have been loaded from the database, or recently stored to the database--it already has an id of $self->{pcr_experiment_id}";
        return $self->{pcr_experiment_id};
    }
    unless($self->predicted() eq 'f' or $self->predicted() eq 't'){croak"Can't check for existence; invalid predicted field for self:\n".$self->as_string();}
    my $possible_matches_query=$self->{dbh}->prepare
    ("
        SELECT 
            pcr_experiment_id
        FROM 
            marker_experiment
        WHERE 
            marker_id=?
            and pcr_experiment_id is not null
    ");
    $possible_matches_query->execute($self->marker_id());
    while(my($possible_match_id)=$possible_matches_query->fetchrow_array())
    {
        #print"possible match id: $possible_match_id\n";
        my $experiment_for_comparison=CXGN::Marker::PCR::Experiment->new($self->{dbh},$possible_match_id);
        if($self->equals($experiment_for_comparison))
        {
            $self->{pcr_experiment_id}=$experiment_for_comparison->{pcr_experiment_id};#ok, we've been found to already exist, so set our pcr_experiment_id
	    return $self->{pcr_experiment_id};
        } 
    }
    return;
}

=head2 store_unless_exists

Stores this experiment in the database, as long as it does not exist. If it does not exist and it is stored, this function will return its new pcr_experiment_id. If the experiment does exists, it will set the pcr_experiment_id but NOT return it.

=cut

sub store_unless_exists {
    my $self=shift;

    if ($self->exists()) { return }

    unless ($self->{marker_id})                                     { croak "Cannot store experiment without marker ID" }
    unless ($self->{protocol})                                      { croak "Cannot store experiment without protocol. Use 'unknown' if necessary." }
    unless ($self->predicted() eq 'f' or $self->predicted() eq 't') { croak "Can't store; invalid predicted field for self:\n".$self->as_string() }
    if ($self->{pcr_experiment_id}) { croak "This experiment appears to have been stored already or created from an existing database entry" }
        ##################### TODO #########################
        #if we already have a PCR experiment ID, and someone
        #calls 'store_unless_exists', this is a perfectly
        #reasonable use case, but i have not implemented it yet.
        #they might want to modify an existing experiment. for 
        #instance, it is common that someone might add digested 
        #bands later, after having loaded an experiment with 
        #only regular pcr bands a few months before. this object cannot yet handle this 
        #situation. that is why it croaks here. if you need to add 
        #this functionality, add it here. it would consist of some 
        #kind of object integrity checking and checking for values 
        #which have been added or modified and adding or modifying 
        #those same values in the database. alternatively, you may
        #just want to write another class--CXGN::Marker::PCR::Experiment::Modfiable
        #or something like that which has fewer checks and just
        #directly accesses data in the database using an object
        #like lukas's modifiable form object. 
    if ($self->{pcr_digest_bands}) {
        unless ($self->{enzyme_id}) { croak "Must have an enzyme set to store digest bands" }
    }

    my $dbh = $self->{dbh};
    my $sql = CXGN::DB::SQLWrappers->new($self->{dbh});

    if ($self->fwd_primer()) {
        my $fwd_info = $sql->insert_unless_exists('sequence',{'sequence'=>$self->fwd_primer()});
        $self->{fwd_primer_id} = $fwd_info->{id};
    }
    if($self->rev_primer()) {
        my $rev_info = $sql->insert_unless_exists('sequence',{'sequence'=>$self->rev_primer()});
        $self->{rev_primer_id} = $rev_info->{id};
    }

    #print"INSERTING:\n".$self->as_string();

    my $pcr_exp_insert = $self->{dbh}->prepare ('
        insert into sgn.pcr_experiment (
            mg_concentration,
            annealing_temp,
            primer_id_fwd,
            primer_id_rev,
            primer_type,
            additional_enzymes,
            predicted
        )
        values (?,?,?,?,?,?,?)
    ');
    $pcr_exp_insert->execute (
	    $self->{mg_concentration},
	    $self->{annealing_temp},
	    $self->{fwd_primer_id},
	    $self->{rev_primer_id},
	    $self->{primer_type},
	    $self->{additional_enzymes},
            $self->{predicted}
    );
    $self->{pcr_experiment_id} =$self->{dbh}->last_insert_id('pcr_experiment') or croak "Could not get last_insert_id from pcr_experiment";

    my %accessions;
    for my $accession(keys(%{$self->{pcr_bands}}),keys(%{$self->{pcr_digest_bands}})) { $accessions{$accession} = 0 }
    # dummy value for now, until we get a pcr_exp_accession_id
    
    my $exp_acc_insert = $self->{dbh}->prepare('insert into sgn.pcr_exp_accession (pcr_experiment_id,accession_id) values (?,?)');
    my $pcr_band_insert= $self->{dbh}->prepare('insert into sgn.pcr_product (pcr_exp_accession_id,enzyme_id,multiple_flag,band_size,predicted) values (?,?,?,?,?)');

    for my $accession_id(keys(%accessions)) {
        $exp_acc_insert->execute($self->{pcr_experiment_id}, $accession_id);
        $accessions{$accession_id} = $self->{dbh}->last_insert_id('pcr_exp_accession') or croak "Could not get last_insert_id from pcr_exp_accession";
  
	my @accession_pcr_bands;
        my @accession_pcr_digest_bands;
        if ($self->{pcr_bands}->{$accession_id}) { @accession_pcr_bands = @{$self->{pcr_bands}->{$accession_id}} }
        if ($self->{pcr_digest_bands}->{$accession_id}) { @accession_pcr_digest_bands = @{$self->{pcr_digest_bands}->{$accession_id}} }
        if ($accession_pcr_bands[0]) { #if there is at least one value in the pcr bands list for this accession
            for my $band(@accession_pcr_bands) {
		#if the band entry starts with an m, it means multiple bands, so set the multiple flag. no enzyme insert for regular pcr bands.
                if($band=~/^m/i) { $pcr_band_insert->execute($accessions{$accession_id},undef,1,undef,$self->{predicted}) }
                else { $pcr_band_insert->execute($accessions{$accession_id},undef,undef,$band,$self->{predicted}) }
	    }
	}
        if($accession_pcr_digest_bands[0]) { # if there is at least one value in the pcr digest bands list for this accession
	    #if the band entry starts with an m, it means multiple bands, so set the multiple flag.
            for my $band(@accession_pcr_digest_bands) {
		if ($band=~/^m/i) { $pcr_band_insert->execute($accessions{$accession_id},$self->{enzyme_id},1,undef,$self->{predicted}) }     
                else { $pcr_band_insert->execute($accessions{$accession_id},$self->{enzyme_id},undef,$band,$self->{predicted}) }
            }
        }            
    }

    #and now for a final test of this object
    if(my $oops_id=$self->store_unless_exists()) {
	my $croaking = "Oops, this object isn't working correctly. Immediately after being stored with ID "
	    . "'$self->{pcr_experiment_id}', it tried to store itself again as a test, and  succeeded with ID '$oops_id' "
	    . "(it should have failed, because it was already inserted!)";
	croak $croaking;
    }

    return $self->{pcr_experiment_id};
}

=head2 update_additional_enzymes

    #this will actually update the pcr experiment entry in the database
    $experiment->update_additional_enzymes('All possible enzymes for blah blah blah are blah blah blah....');

=cut

#storing function for additional_enzymes field. this data is not essential to the experiment. it is just a text field with 
#notes that feinan wants to show up for cosii markers, so it has no special checks or anything.
sub update_additional_enzymes
{
    my $self=shift;
    my($additional_enzymes)=@_;
    if(length($additional_enzymes)>1023)
    {
        croak"Additional enzymes field contents size limit is exceeded by string '$additional_enzymes'";
    }
    unless($self->{pcr_experiment_id})
    {
        croak"This experiment object does not appear to have been loaded or inserted into the database yet, so you cannot update its enzymes";
    }
    my $sth=$self->{dbh}->prepare('update pcr_experiment set additional_enzymes=? where pcr_experiment_id=?');
    $sth->execute($additional_enzymes,$self->{pcr_experiment_id});
}

=head2 as_string

    #print out the whole experiment, for debugging, or for loading script output
    print $experiment->as_string();

=cut

#######################
# display for debugging
#######################
sub as_string
{
    my $self=shift;
    my $string="";
    $string.="<pcr_experiment>\n";
    my @marker_names;
    if($self->{marker_id})
    {
        @marker_names=CXGN::Marker->new($self->{dbh},$self->{marker_id})->name_that_marker();
    }
    else
    {
        @marker_names=('<no marker associated yet>');
    }
    $string.="\tMarker: @marker_names\n";
    $string.="\tPCR experiment ID: $self->{pcr_experiment_id}\n";
    if($self->{location_id})
    {
        $string.="\tThis is a mapping experiment; location ID: $self->{location_id}\n";
    }
    else
    {
        $string.="\tThis experiment does not yet have a map location associated with it in the marker_experiment table\n";
    }
    $string.="\tProtocol: $self->{protocol}\n";
    $string.="\tPrimers: $self->{fwd_primer} (fwd)\t\t$self->{rev_primer} (rev)\n";
    my $pt=$self->{primer_type};
    $pt||='';
    $string.="\tPrimer type: $pt\n";
    my $mg=$self->{mg_concentration};
    $mg||='';
    my $temp=$self->{annealing_temp};
    $temp||='';
    $string.="\tConditions: $mg MG - $temp C\n";
    if($self->{enzyme}){$string.="\tEnzyme: $self->{enzyme}\n";}
    $string.="\tBands:\n";
    my $bands=$self->pcr_bands_hash_of_strings();
    if($bands and %{$bands})
    {
        for my $accession(keys(%{$bands}))
        {
            $string.="\t".CXGN::Accession->new($self->{dbh},$accession)->extra_verbose_name().": ".$bands->{$accession}."\n";
        }
    }
    $string.="\tDigest bands:\n";
    $bands=$self->pcr_digest_bands_hash_of_strings();
    if($bands and %{$bands})
    {
        for my $accession(keys(%{$bands}))
        {
            $string.="\t".CXGN::Accession->new($self->{dbh},$accession)->extra_verbose_name().": ".$bands->{$accession}."\n";
        }
    }
    $string.="\tPredicted: $self->{predicted}\n";
    $string.="</pcr_experiment>\n";
}

=head2 query_results_to_bands_hash

For internal use. Converts bands query results into a form that can be stored easily.

=cut

###########################################
# helpful functions mainly for internal use
###########################################
sub query_results_to_bands_hash
{
    my $self=shift;
    my($sizes)=@_;
    my %bands;
    for my $row(@{$sizes})
    {
        my($accession,$band_size,$multiple_flag)=@{$row};
        if($accession and ($band_size or $multiple_flag))
        {
            my $insert_value;
            if($band_size)
            {
                $insert_value=$band_size;
            }
            elsif($multiple_flag)
            {
                $insert_value='Multiple';
            }
            push(@{$bands{$accession}},$insert_value);
        }
        else
        {
            croak"Unable to load bands hash";
        }
    }
    return \%bands; 
}

=head2 join_bands_hash

For internal use. Converts bands into a more useful form.

=cut

sub join_bands_hash
{
    my $self=shift;
    my($bands_hash)=@_;
    my %expected_structure;
    for my $accession(keys(%{$bands_hash}))
    {
        $expected_structure{$accession}=join('+',@{$bands_hash->{$accession}});
    }
    if(keys(%expected_structure))#if there are values to return, return them
    {
        return \%expected_structure;
    }
    else
    {    
        return;
    }
}

=head2 marker_id

    my $id=$experiment->marker_id();

Gets the marker_id of marker which is involved in this experiment.

    $experiment->marker_id($marker_id);

Sets the marker_id of marker which is involved in this experiment.

=cut

###################
# accessors/setters
###################
sub marker_id 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        unless($value=~/^\d+$/)
        {
            croak"Marker ID must be a number, not '$value'";
        }
        unless(CXGN::Marker::Tools::is_valid_marker_id($self->{dbh},$value))
        {
            croak"Marker ID '$value' does not exist in the database";
        }    
        $self->{marker_id}=$value;
    }
    return $self->{marker_id};
}

=head2 fwd_primer

Returns or sets the forward primer.

=cut

sub fwd_primer 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        $value=$self->test_and_clean_primer($value);
        $self->{fwd_primer}=$value;
    }
    return $self->{fwd_primer};
}

=head2 rev_primer

Returns or sets the reverse primer.

=cut




sub rev_primer 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        $value=$self->test_and_clean_primer($value);
        $self->{rev_primer}=$value;
    }
    return $self->{rev_primer};
}



sub dcaps_primer
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        $value=$self->test_and_clean_primer($value);
        $self->{dcaps_primer}=$value;
    }
    return $self->{dcaps_primer};
}


=head2 primer_type

Returns or sets the primer type.

=cut

sub primer_type 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        unless($value eq 'iUPA' or $value eq 'eUPA')
        {
            croak"'$value' is not a valid primer type";
        }
        $self->{primer_type}=$value;
    }
    return $self->{primer_type};
}

=head2 mg_conc

Returns or sets the magnesium concentration.

=cut

sub mg_conc 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        unless(CXGN::Tools::Text::is_number($value))
        {
            croak"'$value' is not a valid number for mg concentration";
        }
        $self->{mg_concentration}=$value;
    }
    return $self->{mg_concentration};
}

=head2 temp

Returns or sets the temperature. If you send in Fahrenheit you must have an 'F' after the degrees. It will convert it to Celsius for you.

=cut

sub temp 
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        unless($value=~/^(\d*?\.?\d*?)[cf]?$/i)
        {
            croak"'$value' is an invalid anneal temp";
        }
        $value=~s/C$//i;#strip C for Celsius
        if($value=~s/F$//i)#if it was an F for Fahrenheit, convert it to Celsius
        {
            $value=($value+40)*5/9;
        }
        $self->{annealing_temp}=$value;
    }
    return $self->{annealing_temp};
}

=head2 protocol

Returns or sets the experiment protocol.

=cut

sub protocol
{
    my $self=shift;
    my($protocol)=@_;
    if($protocol)
    {
        unless($protocol eq 'AFLP' or $protocol eq 'CAPS' or $protocol eq 'RAPD' or $protocol eq 'SNP' or $protocol eq 'SSR' or $protocol eq 'RFLP' or $protocol eq 'PCR' or $protocol eq 'unknown' or $protocol =~ /Indel/i)
        {
            croak"Protocol '$protocol' is invalid.";
        }
        if($protocol eq 'RFLP')
        {
            croak"RFLP is not a valid PCR experiment protocol";
        }
        $self->{protocol}=$protocol;
    }
    return $self->{protocol};
}

=head2 enzyme

Returns or sets the enzyme used to get the digest bands.

=cut
 
sub enzyme 
{
    my $self=shift;
    my($enzyme)=@_;
    if($enzyme)
    {
        $enzyme=~s/\s//g unless $enzyme=~/and/; #clear whitespace
        $enzyme=~s/(1+)$/'I' x length($1)/e; #1 -> I

        # this isn't working for some reason

	if ($enzyme eq 'PCR') { $enzyme = 'amplicon difference' }
	# TODO: change this to undef once everything is working
	elsif ($enzyme eq 'SNP') { $enzyme = 'unknown' }
	elsif (!$enzyme) { $enzyme = 'unknown' }

	unless($self->{enzyme_id}=CXGN::Marker::Tools::get_enzyme_id($self->{dbh},$enzyme)) {
	    croak "'$enzyme' is not a valid enzyme (you may need to add it to the enzyme table)";
	}

        $self->{enzyme}=$enzyme;
    }

    return $self->{enzyme};
}

=head2 additional_enzymes

Returns or sets Feinan^s COSII additional_enzymes field. 

=cut

sub additional_enzymes
{
    my $self=shift;
    my($value)=@_;
    if($value){$self->{additional_enzymes}=$value;}
    return $self->{additional_enzymes};
}

=head2 predicted

Returns or sets whether or not the band sizes stored in this object are predicted.

=cut

sub predicted
{
    my $self=shift;
    my($value)=@_;
    if($value)
    {
        $value=lc($value);
        unless($value eq 't' or $value eq 'f')
        {
            croak"Predicted must be either 't' or 'f'";
        }
        $self->{predicted}=$value;
    }
    return $self->{predicted};
}

=head2 add_pcr_bands_for_accession

    $experiment->add_pcr_bands_for_accession('250+400','LA716');

=cut

#example use: $created_experiment->add_pcr_bands_string_for_accession('750+900','LA925');
sub add_pcr_bands_for_accession
{
    my $self=shift;
    my($bands_string,$accession)=@_;
    my $accession_object=CXGN::Accession->new($self->{dbh},$accession);
    unless($accession_object)
    {
        croak"Accession '$accession' not found\n";
    }
    my $accession_id=$accession_object->accession_id();
    unless($accession_id){croak("Accession '$accession' not found");}
    my @bands=split(/\+/,$bands_string);
    $self->{pcr_bands}->{$accession_id}=\@bands; 
    $self->{pcr_bands}=$self->test_and_clean_bands($self->{pcr_bands});   
}

=head2 add_pcr_digest_bands_for_accession

    $experiment->add_pcr_digest_bands_for_accession('250+400','LA716');

=cut

#example use: $created_experiment->add_pcr_digest_bands_string_for_accession('multiple','LA716');
sub add_pcr_digest_bands_for_accession
{
    my $self=shift;
    my($bands_string,$accession)=@_;
    my $accession_object=CXGN::Accession->new($self->{dbh},$accession);
    unless($accession_object)
    {
        croak"Accession '$accession' not found\n";
    }
    my $accession_id=$accession_object->accession_id();
    unless($accession_id){croak("Accession '$accession' not found");}
    my @bands=split(/\+/,$bands_string);
    $self->{pcr_digest_bands}->{$accession_id}=\@bands;  
    $self->{pcr_digest_bands}=$self->test_and_clean_bands($self->{pcr_digest_bands});    
}

######################
# convenient accessors
######################

=head2 pcr_bands_hash_of_strings

Get PCR bands in a form that CXGN::Marker::PCR likes.

=cut

sub pcr_bands_hash_of_strings
{
    my $self=shift;
    return $self->join_bands_hash($self->{pcr_bands});
}

=head2 pcr_digest_bands_hash_of_strings

Get PCR digest bands in a form that CXGN::Marker::PCR likes.

=cut

sub pcr_digest_bands_hash_of_strings 
{
    my $self=shift;
    return $self->join_bands_hash($self->{pcr_digest_bands});
}

=head2 test_and_clean_primer

For internal use.

=cut

#####
# etc
#####
sub test_and_clean_primer
{
    my $self=shift;
    my($primer)=@_;

    $primer =~ s/\s//g;

    unless($primer=~/[ATGCatgc]+/)#primers are known base pairs start to finish
    {
        croak"'$primer' is not a valid primer";
    }
    return uc($primer);#uppercase sequence data
}

=head2 test_and_clean_bands

For internal use.

=cut

#bands must look like this: {'LA716'=>['Multiple'],'LA925'=>[750,900]}
sub test_and_clean_bands
{
    my $self=shift;
    my($bands)=@_;
    unless(ref($bands) eq 'HASH')
    {
        croak"Bands must be hash ref";
    }
    for my $accession_id(keys(%{$bands}))
    {
        unless(CXGN::Accession->new($self->{dbh},$accession_id)->accession_id()){croak"Accession '$accession_id' not found";}
        unless(ref($bands->{$accession_id}) eq 'ARRAY')
        {
            croak"Bands hash ref must contain array refs";
        }
        my @bands_array=@{$bands->{$accession_id}};#copy this array out to make the following code more readable, maybe
        for my $index(0..$#bands_array)
        {
            $bands_array[$index]=CXGN::Tools::Text::remove_all_whitespaces(lc($bands_array[$index]));

            if($bands_array[$index]=~/^m/i){$bands_array[$index]='Multiple';}

	    unless ($bands_array[$index] eq 'Multiple'){
	      $bands_array[$index] = int($bands_array[$index]);
	    }

            unless(($bands_array[$index] eq 'Multiple') or (CXGN::Tools::Text::is_number($bands_array[$index])))
            {
                croak"'$bands_array[$index]' is an invalid band size";
            }            
        }
        $bands->{$accession_id}=\@bands_array;#copy this array back in
    }    
    return $bands;
}

##store the primers, or any other sequnces linked, in the sequence table, and link to pcr_experiment##

=head2 store_sequence

 Usage: $self->store_sequence($sequence_name, $sequence);
 Desc:  store a primer, or any other sequence type, of the pcr_experiment in the sequence table ,
        and link to the experiment using pcr_experiment_sequence table.
 Ret:  a database id
 Args: a string with sequence type, and the sequence string
       sequence types should be listed in the cvterm table with cv_name =
       'sequence' (this is the namespace for SO http://song.cvs.sourceforge.net/viewvc/song/ontology/so.obo?view=log )
 Side Effects: store a new sequence in sgn.sequence, if one does not exist.
               Sequences are converted to all upper-case.

Example
    my $id = $self->store_sequence('forward_primer','ATCCGTGACGTAC');

=cut

sub store_sequence {
    my $self = shift;
    my $sequence_type = shift;
    my $seq = shift || die 'No sequence for type $sequence_type passed to store_sequence function! \n';
   
    #find if the type is stored in the database
    my $q = "SELECT cvterm_id FROM public.cvterm
             WHERE name ilike ? AND cv_id =
             (SELECT cv_id FROM public.cv WHERE cv.name ilike ?) ";
    my $sth=$self->{dbh}->prepare($q);
    $sth->execute($sequence_type,'sequence');
    my ($type_id) = $sth->fetchrow_array();
    die "Sequence type $sequence_type does not exist in the database!\n Expected to find cvterm $sequence_type with cv_name 'sequence'!\n Please check your databae, and make sure Sequence Ontology is up-to-date\n " if !$type_id;
    ##
    $seq =~ s/\s//g;
    unless($seq=~/[ATGCatgc]+/)   {
        croak"'$seq' is not a valid sequence";
    }
    $seq = uc($seq);#uppercase sequence data
    ##
    my $sql = CXGN::DB::SQLWrappers->new( $self->{dbh} );
    my $sequence = $sql->insert_unless_exists('sequence',{'sequence'=>$seq });
    #store the link
    $q = "Insert INTO sgn.pcr_experiment_sequence (sequence_id, pcr_experiment_id, type_id) 
          VALUES (?,?,?) RETURNING pcr_experiment_sequence_id";
    $sth=$self->{dbh}->prepare($q);
    $sth->execute( $sequence->{id} ,  $self->{pcr_experiment_id} , $type_id );
    #my $pcr_seq = $sql->insert_unless_exists('pcr_experiment_sequence' , { 'sequence_id' => $sequence->{id} , 'pcr_experiment_id' => $self->{pcr_experiment_id} , 'type_id' => $type_id } );
    return ($sth->fetchrow_array());
}


##get the associated sequences and their types from pcr_experiment_sequence##

=head2 get_sequences

 Usage: $self->get_sequences
 Desc:  find the sequences associated with the marker, and their types
 Ret:   hashref {$sequence_type => [$seq1, $seq2] }
 Args:  none
 Side Effects: none

=cut

sub get_sequences {
    my $self = shift;
    my $q = "SELECT cvterm.name, sequence FROM sgn.pcr_experiment
             JOIN sgn.pcr_experiment_sequence USING (pcr_experiment_id)
             JOIN sgn.sequence USING (sequence_id)
             JOIN public.cvterm on cvterm_id = sgn.pcr_experiment_sequence.type_id
             WHERE pcr_experiment.pcr_experiment_id = ?";
    my $sth = $self->{dbh}->prepare($q);
    $sth->execute($self->{pcr_experiment_id});
    my %HoA;
    while ( my ($sequence_type, $sequence) = $sth->fetchrow_array() ) {
        push @ {$HoA{$sequence_type} }, $sequence ;
    }
    return \%HoA;
}



1;
