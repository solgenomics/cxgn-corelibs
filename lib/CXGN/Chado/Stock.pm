=head1 NAME

CXGN::Chado::Stock - a second-level DBIC Bio::Chado::Schema::Stock::Stock object

Version:1.0

=head1 DESCRIPTION

Created to work with  CXGN::Page::Form::AjaxFormPage
for eliminating the need to refactor the  AjaxFormPage and Editable  to work with DBIC objects.
Functions such as 'get_obsolete' , 'store' , and 'exists_in_database' are required , and do not use standard DBIC syntax.


=head1 DEPRECATED

This module is needs to be deprecated.  Do not use in new code.  Build new code with Moose instead in sgn/lib/CXGN/Stock.pm

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=cut

package CXGN::Chado::Stock ;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Bio::Chado::Schema;
use CXGN::Metadata::Schema;
use Bio::GeneticRelationships::Pedigree;
use Bio::GeneticRelationships::Individual;
use SGN::Model::Cvterm;
use base qw / CXGN::DB::Object / ;

=head2 new

  Usage: my $stock = CXGN::Chado::Stock->new($schema, $stock_id);
  Desc:
  Ret: a CXGN::Chado::Stock object
  Args: a $schema a schema object,
        $stock_id, if omitted, an empty stock object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use. die if the id is not an integer.

=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into the object.
    #my $self = $class->SUPER::new($schema);
    my $self = bless {}, $class;
    $self->set_schema($schema);
    my $stock;
    if (defined $id) {
	$stock = $self->get_resultset('Stock::Stock')->find({ stock_id => $id });
    } else {
	### Create an empty resultset object;
	$stock = $self->get_resultset('Stock::Stock')->new( {} );
    }
    ###It's important to set the object row for using the accesor in other class functions
    $self->set_object_row($stock);
    return $self;
}



=head2 store

 Usage: $self->store
 Desc:  store a new stock
 Ret:   a database id
 Args:  none
 Side Effects: checks if the stock exists in the database, and if does, will attempt to update
 Example:

=cut

sub store {
    my $self=shift;
    my $id = $self->get_stock_id();
    my $schema=$self->get_schema();
    #no stock id . Check first if the name  exists in te database
    if (!$id) {
	my $exists= $self->exists_in_database();
	if (!$exists) {
	    my $new_row = $self->get_object_row();
	    $new_row->insert();

	    $id=$new_row->stock_id();
	}else {
	    my $existing_stock=$self->get_resultset('Stock::Stock')->find($exists);
	    #don't update here if stock already exist. User should call from the code exist_in_database
	    #and instantiate a new stock object with the database id
	    #updating here is not a good idea, since it might not be what the user intended to do
            #and it can mess up the database.
	}
    }else { # id exists
	$self->get_object_row()->update();
    }
    return $id
}

########################


=head2 exists_in_database

 Usage: $self->exists_in_database()
 Desc:  check if the uniquename exists in the stock table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $stock_id = $self->get_stock_id();
    my $uniquename = $self->get_uniquename || '' ;
    my ($s) = $self->get_resultset('Stock::Stock')->search(
	{
	    uniquename  => { 'ilike' => $uniquename },
	});
    #loading new stock - $stock_id is undef
    if (defined($s) && !$stock_id ) {  return $s->stock_id ; }

    #updating an existing stock
    elsif ($stock_id && defined($s) ) {
	if ( ($s->stock_id == $stock_id) ) {
	    return 0;
	    #trying to update the uniquename
	} elsif ( $s->stock_id != $stock_id ) {
	    return " Can't update an existing stock $stock_id uniquename:$uniquename.";
	    # if the new name we're trying to update/insert does not exist in the stock table..
	} elsif ($stock_id && !$s->stock_id) {
	    return 0;
	}
    }
    return undef;
}

=head2 get_organism

 Usage: $self->get_organism
 Desc:  find the organism object of this stock
 Ret:   L<Bio::Chado::Schema::Organism::Organism> object
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_organism {
    my $self = shift;
    if (my $bcs_stock = $self->get_object_row) {
        return $bcs_stock->organism;
    }
    return undef;
}


=head2 get_species

 Usage: $self->get_species
 Desc:  find the species name of this stock , if one exists
 Ret:   string
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_species {
    my $self = shift;
    my $organism = $self->get_organism;
    if ($organism) {
        return $organism->species;
    }else { return undef; }
}

=head2 set_species

Usage: $self->set_species
 Desc:  set organism_id for the stock using organism.species name
 Ret:   nothing
 Args:  species name (case insensitive)
 Side Effects: sets the organism_id for the stock
 Example:

=cut

sub set_species {
    my $self = shift;
    my $species_name = shift; # this has to be EXACTLY as stored in the organism table
    my $organism = $self->get_schema->resultset('Organism::Organism')->search(
        { 'lower(species)' => { like =>  lc($species_name) } } )->single ; #should be 1 result
    if ($organism) {
        $self->get_object_row->set_column(organism_id => $organism->organism_id );
    }
    else {
        warn "NO organism found for species name $species_name!!\n";
    }
}

=head2 add_synonym

Usage: $self->add_synonym
 Desc:  add a synonym for this stock. a stock can have many synonyms
 Ret:   nothing
 Args:  name
 Side Effects:
 Example:

=cut

sub add_synonym {
    my $self = shift;
    my $synonym = shift;
    my $synonym_cvterm = SGN::Model::Cvterm->get_cvterm_row($self->get_schema, 'stock_synonym', 'stock_property');
    my $stock = $self->get_object_row();
    $stock->create_stockprops({$synonym_cvterm->name() => $synonym});
}

=head2 remove_synonym

Usage: $self->remove_synonym
 Desc:  removes a synonym for this stock
 Ret:   nothing
 Args:  name
 Side Effects: removes an entry from stockprop table
 Example:

=cut

sub remove_synonym {
    my $self = shift;
    my $synonym = shift;
    my $synonym_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($self->get_schema, 'stock_synonym', 'stock_property')->cvterm_id();
    my $synonym_rs = $self->get_schema->resultset("Stock::Stockprop")->search({'stock_id'=>$self->get_stock_id, 'type_id'=>$synonym_cvterm_id, 'value'=>$synonym});
    while(my $s = $synonym_rs->next()){
        $s->delete();
    }
}

=head2 get_type

 Usage: $self->get_type
 Desc:  find the cvterm type of this stock
 Ret:   L<Bio::Chado::Schema::Cv::Cvterm> object
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_type {
    my $self = shift;

    if (my $bcs_stock = $self->get_object_row ) {
	return  $bcs_stock->type;
    }
    return undef;
}

sub get_object_row {
    my $self = shift;
    return $self->{object_row};
}

sub set_object_row {
  my $self = shift;
  $self->{object_row} = shift;
}

=head2 get_resultset

 Usage: $self->get_resultset(ModuleName::TableName)
 Desc:  Get a ResultSet object for source_name
 Ret:   a ResultSet object
 Args:  a source name
 Side Effects: none
 Example:

=cut

sub get_resultset {
    my $self=shift;
    my $source = shift;
    return $self->get_schema()->resultset("$source");
}

=head2 accessors get_schema, set_schema

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_schema {
  my $self = shift;
  return $self->{schema};
}

sub set_schema {
  my $self = shift;
  $self->{schema} = shift;
}


###mapping accessors to DBIC

=head2 accessors get_name, set_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_name {
    my $self = shift;
    return $self->get_object_row()->get_column("name");
}

sub set_name {
    my $self = shift;
    $self->get_object_row()->set_column(name => shift);
}

=head2 accessors get_uniquename, set_uniquename

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_uniquename {
    my $self = shift;
    return $self->get_object_row()->get_column("uniquename");
}

sub set_uniquename {
    my $self = shift;
    $self->get_object_row()->set_column(uniquename => shift);
}

=head2 accessors get_organism_id, set_organism_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_organism_id {
    my $self = shift;
    if (my $bcs_stock =  $self->get_object_row ) {
        return $bcs_stock->get_column("organism_id");
    }
    return undef;
}

sub set_organism_id {
    my $self = shift;
    $self->get_object_row()->set_column(organism_id => shift);
}

=head2 accessors get_type_id, set_type_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_type_id {
    my $self = shift;
    if (my $bcs_stock = $self->get_object_row ) {
        return $bcs_stock->get_column("type_id");
    }
}

sub set_type_id {
    my $self = shift;
    $self->get_object_row()->set_column(type_id => shift);
}

=head2 accessors get_description, set_description

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_description {
    my $self = shift;
    return $self->get_object_row()->get_column("description");
}

sub set_description {
    my $self = shift;
    $self->get_object_row()->set_column(description => shift);
}

=head2 accessors get_stock_id, set_stock_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_stock_id {
    my $self = shift;
    if ( my $bcs_stock = $self->get_object_row ) {
        return $bcs_stock->get_column("stock_id");
    }
    return undef;
}

sub set_stock_id {
    my $self = shift;
    $self->get_object_row()->set_column(stock_id => shift);
}

=head2 accessors get_is_obsolete, set_is_obsolete

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_is_obsolete {
    my $self = shift;
    my $stock = $self->get_object_row();
    return $stock->get_column("is_obsolete") if $stock;
}

sub set_is_obsolete {
    my $self = shift;
    #my $stock = $self->get_object_row();
    my $obsolete_string = '_OBSOLETED_' . localtime();
    my $name = $self->get_name() . $obsolete_string;
    $self->set_name($name);
    my $uniquename = $self->get_uniquename() . $obsolete_string;
    $self->set_uniquename($uniquename);
    $self->get_object_row()->set_column(is_obsolete => shift);
}

=head2 function get_image_ids

  Synopsis:     my @images = $self->get_image_ids()
  Arguments:    none
  Returns:      a list of image ids
  Side effects:	none
  Description:	a method for fetching all images associated with a stock

=cut

sub get_image_ids {
    my $self = shift;
    my @ids;
    my $q = "select distinct image_id, cvterm.name, stock_image.display_order FROM phenome.stock_image JOIN stock USING(stock_id) JOIN cvterm ON(type_id=cvterm_id) WHERE stock_id = ? ORDER BY stock_image.display_order ASC";
    my $h = $self->get_schema->storage->dbh()->prepare($q);
    $h->execute($self->get_stock_id);
    while (my ($image_id, $stock_type) = $h->fetchrow_array()){
        push @ids, [$image_id, $stock_type];
    }
    return @ids;
}

=head2 associate_allele

 Usage: $self->associate_allele($allele_id, $sp_person_id)
 Desc:  store a stock-allele link in phenome.stock_allele
 Ret:   a database id
 Args:  allele_id, sp_person_id
 Side Effects:  store a metadata row
 Example:

=cut

sub associate_allele {
    my $self = shift;
    my $allele_id = shift;
    my $sp_person_id = shift;
    if (!$allele_id || !$sp_person_id) {
        warn "Need both allele_id and person_id for linking the stock with an allele!";
        return
    }
    my $metadata_id = $self->_new_metadata_id($sp_person_id);
    #check if the allele is already linked
    my $ids =  $self->get_schema->storage->dbh->selectcol_arrayref
        ( "SELECT stock_allele_id FROM phenome.stock_allele WHERE stock_id = ? AND allele_id = ?",
          undef,
          $self->get_stock_id,
          $allele_id
        );
    if ($ids) { warn "Allele $allele_id is already linked with stock " . $self->get_stock_id ; }
#store the allele_id - stock_id link
    my $q = "INSERT INTO phenome.stock_allele (stock_id, allele_id, metadata_id) VALUES (?,?,?) RETURNING stock_allele_id";
    my $sth  = $self->get_schema->storage->dbh->prepare($q);
    $sth->execute($self->get_stock_id, $allele_id, $metadata_id);
    my ($id) =  $sth->fetchrow_array;
    return $id;
}

=head2 associate_owner

 Usage: $self->associate_owner($owner_sp_person_id, $sp_person_id)
 Desc:  store a stock-owner link in phenome.stock_owner
 Ret:   a database id
 Args:  owner_id, sp_person_id
 Side Effects:  store a metadata row
 Example:

=cut

sub associate_owner {
    my $self = shift;
    my $owner_id = shift;
    my $sp_person_id = shift;
    if (!$owner_id || !$sp_person_id) {
        warn "Need both owner_id and person_id for linking the stock with an owner!";
        return
    }
    my $metadata_id = $self->_new_metadata_id($sp_person_id);
    #check if the owner is already linked
    my $ids =  $self->get_schema->storage->dbh->selectcol_arrayref
        ( "SELECT stock_owner_id FROM phenome.stock_owner WHERE stock_id = ? AND owner_id = ?",
          undef,
          $self->get_stock_id,
          $owner_id
        );
    if ($ids) { warn "Owner $owner_id is already linked with stock " . $self->get_stock_id ; }
#store the owner_id - stock_id link
    my $q = "INSERT INTO phenome.stock_owner (stock_id, owner_id, metadata_id) VALUES (?,?,?) RETURNING stock_owner_id";
    my $sth  = $self->get_schema->storage->dbh->prepare($q);
    $sth->execute($self->get_stock_id, $owner_id, $metadata_id);
    my ($id) =  $sth->fetchrow_array;
    return $id;
}

=head2 get_trait_list

 Usage:
 Desc:         gets the list of traits that have been measured
               on this stock
 Ret:          a list of lists  ( [ cvterm_id, cvterm_name] , ...)
 Args:
 Side Effects:
 Example:

=cut

sub get_trait_list {
    my $self = shift;

    my $q = "select distinct(cvterm.cvterm_id), db.name || ':' || dbxref.accession, cvterm.name, avg(phenotype.value::Real), stddev(phenotype.value::Real), count(phenotype.value::Real) from stock as accession join stock_relationship on (accession.stock_id=stock_relationship.object_id) JOIN stock as plot on (plot.stock_id=stock_relationship.subject_id) JOIN nd_experiment_stock ON (plot.stock_id=nd_experiment_stock.stock_id) JOIN nd_experiment_phenotype USING(nd_experiment_id) JOIN phenotype USING (phenotype_id) JOIN cvterm ON (phenotype.cvalue_id = cvterm.cvterm_id) JOIN dbxref ON(cvterm.dbxref_id = dbxref.dbxref_id) JOIN db USING(db_id) where accession.stock_id=? and phenotype.value~? group by cvterm.cvterm_id, db.name || ':' || dbxref.accession, cvterm.name";
    my $h = $self->get_schema()->storage->dbh()->prepare($q);
    my $numeric_regex = '^[0-9]+([,.][0-9]+)?$';
    $h->execute($self->get_stock_id(), $numeric_regex);
    my @traits;
    while (my ($cvterm_id, $cvterm_accession, $cvterm_name, $avg, $stddev, $count) = $h->fetchrow_array()) {
	push @traits, [ $cvterm_id, $cvterm_accession, $cvterm_name, $avg, $stddev, $count ];
    }

    # get directly associated traits
    #
    $q = "select distinct(cvterm.cvterm_id), db.name || ':' || dbxref.accession, cvterm.name, avg(phenotype.value::Real), stddev(phenotype.value::Real) from stock JOIN nd_experiment_stock ON (stock.stock_id=nd_experiment_stock.stock_id) JOIN nd_experiment_phenotype USING(nd_experiment_id) JOIN phenotype USING (phenotype_id) JOIN cvterm ON (phenotype.cvalue_id = cvterm.cvterm_id) JOIN dbxref ON(cvterm.dbxref_id = dbxref.dbxref_id) JOIN db USING(db_id) where stock.stock_id=? and phenotype.value~? group by cvterm.cvterm_id, db.name || ':' || dbxref.accession, cvterm.name";
    $h = $self->get_schema()->storage()->dbh()->prepare($q);
    $numeric_regex = '^[0-9]+([,.][0-9]+)?$';
    $h->execute($self->get_stock_id(), $numeric_regex);
    while (my ($cvterm_id, $cvterm_accession, $cvterm_name, $avg, $stddev) = $h->fetchrow_array()) {
	push @traits, [ $cvterm_id, $cvterm_accession, $cvterm_name, $avg, $stddev ];
    }

    return @traits;

}

=head2 get_trials

 Usage:
 Desc:          gets the list of trails this stock was used in
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_trials {
    my $self = shift;
    my $dbh = $self->get_schema()->storage()->dbh();
    my $stock_type = $self->get_type->name();

    if ($stock_type ne 'accession' && $stock_type ne 'plot'){
        die "CXGN::Chado::Stock::get_trials requires either an accession or a plot.\n";
    }

    my $geolocation_q = "SELECT nd_geolocation_id, description FROM nd_geolocation;";
    my $geolocation_h = $dbh->prepare($geolocation_q);
    $geolocation_h->execute();
    my %geolocations;
    while (my ($nd_geolocation_id, $description) = $geolocation_h->fetchrow_array()) {
        $geolocations{$nd_geolocation_id} = $description;
    }

    my $geolocation_type_id = SGN::Model::Cvterm->get_cvterm_row($self->get_schema(), 'project location', 'project_property')->cvterm_id();
    my $q;
    if ($stock_type eq 'accession'){
        $q = "SELECT DISTINCT project.project_id, project.name, projectprop.value 
        FROM stock AS accession 
        JOIN stock_relationship ON (accession.stock_id=stock_relationship.object_id) 
        JOIN stock AS plot ON (plot.stock_id=stock_relationship.subject_id) 
        JOIN nd_experiment_stock ON (plot.stock_id=nd_experiment_stock.stock_id) 
        JOIN nd_experiment_project USING (nd_experiment_id) 
        JOIN project USING (project_id) 
        FULL OUTER JOIN projectprop ON (project.project_id=projectprop.project_id AND projectprop.type_id=$geolocation_type_id) 
        JOIN cvterm ON (cvterm.cvterm_id=nd_experiment_stock.type_id) 
        FULL OUTER JOIN breeding_programs ON (breeding_programs.breeding_program_id=project.project_id) 
        WHERE accession.stock_id=? 
            AND cvterm.name!='phenotyping_experiment' 
            AND cvterm.name!='analysis_experiment' 
            AND breeding_program_id IS NULL;";
    } else { # Odds are if this is not an accession, it is a plot.
        $q = "select DISTINCT project.project_id, project.name, projectprop.value from stock 
		JOIN nd_experiment_stock USING(stock_id) 
		JOIN nd_experiment_project USING(nd_experiment_id) 
		JOIN project USING (project_id) 
        JOIN nd_experiment ON nd_experiment.nd_experiment_id=nd_experiment_project.nd_experiment_id
        JOIN cvterm ON cvterm.cvterm_id=nd_experiment.type_id
		FULL OUTER JOIN projectprop ON (project.project_id=projectprop.project_id AND projectprop.type_id=$geolocation_type_id) 
		WHERE stock.stock_id=? AND cvterm.name!='phenotyping_experiment' AND cvterm.name!='analysis_experiment';";
    }
    my $h = $dbh->prepare($q);
    $h->execute($self->get_stock_id());
    my @trials;
    while (my ($project_id, $project_name, $nd_geolocation_id) = $h->fetchrow_array()) {
		next if (!$nd_geolocation_id); #The logic here is that field trials must have a location, this is enforced during their creation. 
		push @trials, [ $project_id, $project_name, $nd_geolocation_id, $geolocations{$nd_geolocation_id} ];
    }

    return @trials;
}

=head2 get_stored_analyses

 Usage:
 Desc:          gets the list of stored analyses using this stock (accession)
 Args:
 Side Effects:
 Example:

=cut

sub get_stored_analyses {
    my $self = shift;
    my $dbh = $self->get_schema()->storage()->dbh();
    my $stock_type = $self->get_type->name();

    if ($stock_type ne 'accession') {
        die "CXGN::Chado::Stock::get_stored_analyses requires an accession.\n";
    }

    my $q;
    if ($stock_type eq 'accession'){
        $q = "SELECT DISTINCT project.project_id, project.name 
        FROM stock AS accession 
        JOIN stock_relationship ON (accession.stock_id=stock_relationship.object_id) 
        JOIN stock AS plot ON (plot.stock_id=stock_relationship.subject_id) 
        JOIN nd_experiment_stock ON (plot.stock_id=nd_experiment_stock.stock_id) 
        JOIN nd_experiment_project USING (nd_experiment_id) 
        JOIN project USING (project_id) 
        JOIN cvterm ON (cvterm.cvterm_id=nd_experiment_stock.type_id) 
        WHERE accession.stock_id=?  
            AND cvterm.name='analysis_experiment';";
    } else { #This code doesn't get called anywhere, but is here in case it is needed in the future
        $q = "select distinct(project.project_id), project.name from stock 
		JOIN nd_experiment_stock USING(stock_id) 
		JOIN nd_experiment_project USING(nd_experiment_id) 
        JOIN nd_experiment ON nd_experiment.nd_experiment_id=nd_experiment_project.nd_experiment_id
        JOIN cvterm ON cvterm.cvterm_id=nd_experiment.type_id
		JOIN project USING (project_id)  
		WHERE stock.stock_id=? AND cvterm.name='analysis_experiment';";
    }
    my $h = $dbh->prepare($q);
    $h->execute($self->get_stock_id());
    my @analyses;
    while (my ($project_id, $project_name) = $h->fetchrow_array()) {
		push @analyses, [ $project_id, $project_name ];
    }

    return @analyses;
}

sub get_direct_parents {
    my $self = shift;
    my $stock_id = shift || $self->get_stock_id();

    #print STDERR "get_direct_parents with $stock_id...\n";

    my $female_parent_id;
    my $male_parent_id;

    eval {
	$female_parent_id = $self->get_schema()->resultset("Cv::Cvterm")->find( { name => 'female_parent' })->cvterm_id();
	$male_parent_id = $self->get_schema()->resultset("Cv::Cvterm")->find( { name => 'male_parent' }) ->cvterm_id();
    };
    if ($@) {
	die "Cvterm for female_parent and/or male_parent seem to be missing in the database\n";
    }

    my $rs = $self->get_schema()->resultset("Stock::StockRelationship")->search( { object_id => $stock_id, type_id => { -in => [ $female_parent_id, $male_parent_id ] } });
    my @parents;
    while (my $row = $rs->next()) {
	print STDERR "Found parent...\n";
	my $prs = $self->get_schema()->resultset("Stock::Stock")->find( { stock_id => $row->subject_id() });
	my $parent_type = "";
	if ($row->type_id() == $female_parent_id) {
	    $parent_type = "female";
	}
	if ($row->type_id() == $male_parent_id) {
	    $parent_type = "male";
	}
	push @parents, [ $prs->stock_id(), $prs->uniquename(), $parent_type ];
    }

    return @parents;
}

sub get_recursive_parents {
    my $self = shift;
    my $individual = shift;
    my $max_level = shift || 1;
    my $current_level = shift;

    if (!defined($individual)) { return; }

    if ($current_level > $max_level) {
	print STDERR "Reached level $current_level of $max_level... we are done!\n";
	return;
    }

    $current_level++;
    my @parents = $self->get_direct_parents($individual->get_id());

    #print STDERR Dumper(\@parents);

    my $pedigree = Bio::GeneticRelationships::Pedigree->new( { name => $individual->get_name()."_pedigree", cross_type=>"unknown"} );

    foreach my $p (@parents) {
	my ($parent_id, $parent_name, $relationship) = @$p;

	my ($female_parent, $male_parent, $attributes);
	my $parent = Bio::GeneticRelationships::Individual->new( { name => $parent_name, id=> $parent_id });
	if ($relationship eq "female") {
	    $pedigree->set_female_parent($parent);
	}

	if ($relationship eq "male") {
	    print STDERR "Adding male parent...\n";
	    $pedigree->set_male_parent($parent);
	}


	$self->get_recursive_parents($parent, $max_level, $current_level);
    }
    $individual->set_pedigree($pedigree);
}

sub get_parents {
    my $self = shift;
    my $max_level = shift || 1;

	my $root;
	if ($self->get_stock_id){
    $root = Bio::GeneticRelationships::Individual->new(
	{
	    name => $self->get_uniquename(),
	    id => $self->get_stock_id(),
	});

    $self->get_recursive_parents($root, $max_level, 0);
	}
    return $root;
}

=head2 get_stockprop_hash

 Usage:
 Desc:  Returns a hash of all stockprops and values for this stock
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_stockprop_hash {
	my $self = shift;
	my $stock_id = $self->get_stock_id;
	my $stockprop_rs = $self->get_schema->resultset('Stock::Stockprop')->search({stock_id => $stock_id}, {join=>['type'], +select=>['type.name', 'me.value'], +as=>['name', 'value']});
	my $stockprop_hash;
	while (my $r = $stockprop_rs->next()){
		push @{ $stockprop_hash->{$r->get_column('name')} }, $r->get_column('value');
	}
	#print STDERR Dumper $stockprop_hash;
	return $stockprop_hash;
}

# subsequent 2 calls moved to Bio::GeneticRelationships::Individual
# sub recursive_parent_levels {
#     my $self = shift;
#     my $individual = shift;
#     my $max_level = shift;
#     my $current_level = shift;

#     my @levels;
#     if ($current_level > $max_level) {
# 	print STDERR "Exceeded max_level $max_level, returning.\n";
# 	return;
#     }

#     if (!defined($individual)) {
# 	print STDERR "no more individuals defined...\n";
# 	return;
#     }

#     my $p = $individual->get_pedigree();

#     if (!defined($p->get_female_parent())) { return; }

#     my $cross_type = $p->get_cross_type() || 'unknown';

#     if ($cross_type eq "open") {
# 	print STDERR "Open cross type not supported. Skipping.\n";
# 	return;
#     }

#     if (defined($p->get_female_parent()) && defined($p->get_male_parent())) {
# 	if ($p->get_female_parent()->get_name() eq $p->get_male_parent->get_name()) {
# 	    $cross_type = "self";
# 	}
#     }

#     $levels[0] = { female_parent => $p->get_female_parent()->get_name(),
# 		    male_parent =>  $p->get_male_parent()->get_name(),
# 		    level => $current_level,
# 		    cross_type => $cross_type,
#     };

#     if ($p->get_female_parent()) {
# 	my @maternal_levels =  $self->recursive_parent_levels($p->get_female_parent(), $max_level, $current_level+1);
# 	push @levels, $maternal_levels[0];
#     }

#     if ($p->get_male_parent()) {
# 	my @paternal_levels = $self->recursive_parent_levels($p->get_male_parent(), $max_level, $current_level+1);
# 	push @levels, $paternal_levels[0];
#     }

#     return @levels;
# }


# sub get_parents_string {
#     my $self = shift;
#     my $max_level = shift || 1;

#     my $pedigree_root = $self->get_parents($max_level);

#     print "getting string for: ".Dumper($pedigree_root);

#     my @levels = $self->recursive_parent_levels($pedigree_root, $max_level, 0);
#     my $s = "";
#     my @s = ();
#     my $repeat = 0;
#     for (my $i=0; $i < @levels; $i++) {
# 	print STDERR "level $i\n";
# 	$repeat =  ($levels[$i]->{level});
# 	if ($levels[$i]->{level} == $max_level) {
# 	    print STDERR "REPEAT: $repeat\n";
# 	    push @s, $levels[$i]->{female_parent}.('/' x $repeat).$levels[$i]->{male_parent};

# 	}

#     }
#     my $s = join ('/' x ($repeat+1), , @s);
#     print STDERR "S: $s\n";
#     return @levels;
# }

=head2 _new_metadata_id

Usage: my $md_id = $self->_new_metatada_id($sp_person_id)
Desc:  Store a new md_metadata row with a $sp_person_id
Ret:   a database id
Args:  sp_person_id

=cut

sub _new_metadata_id {
    my $self = shift;
    my $sp_person_id = shift;
    my $metadata_schema = CXGN::Metadata::Schema->connect(
        sub { $self->get_schema->storage->dbh },
        );
    my $metadata = CXGN::Metadata::Metadbdata->new($metadata_schema);
    $metadata->set_create_person_id($sp_person_id);
    my $metadata_id = $metadata->store()->get_metadata_id();
    return $metadata_id;
}

=head2 merge

 Usage:         $s->merge(221, 1);
 Desc:          merges stock $s with stock_id 221. Optional delete boolean
                parameter indicates whether other stock should be deleted.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub merge {
    my $self = shift;
    my $other_stock_id = shift;
    my $delete_other_stock = shift;

    if ($other_stock_id == $self->get_stock_id()) {
	print STDERR "Trying to merge stock into itself ($other_stock_id) Skipping...\n";
	return;
    }



    my $stockprop_count=0;
    my $subject_rel_count=0;
    my $object_rel_count=0;
    my $stock_allele_count=0;
    my $image_count=0;
    my $experiment_stock_count=0;
    my $stock_dbxref_count=0;
    my $stock_owner_count=0;
    my $parent_1_count=0;
    my $parent_2_count=0;
    my $other_stock_deleted = 'NO';


    my $schema = $self->get_schema();

    # move stockprops
    #
    my $sprs = $schema->resultset("Stock::Stockprop")->search( { stock_id => $other_stock_id });
    while (my $row = $sprs->next()) {

	# check if this stockprop already exists for this stock; save only if not
	#
	my $thissprs = $schema->resultset("Stock::Stockprop")->search(
	    {
		stock_id => $self->get_stock_id(),
		type_id => $row->type_id(),
		value => $row->value()
	    });

	if ($thissprs->count() == 0) {
	    my $value = $row->value();
	    my $type_id = $row->type_id();

	    my $rank_rs = $schema->resultset("Stock::Stockprop")->search( { stock_id => $self->get_stock_id(), type_id => $type_id });

	    my $rank;
	    if ($rank_rs->count() > 0) {
		$rank = $rank_rs->get_column("rank")->max();
	    }

	    $rank++;
	    $row->rank($rank);
	    $row->stock_id($self->get_stock_id());

	    $row->update();

	    print STDERR "MERGED stockprop_id ".$row->stockprop_id." for stock $other_stock_id type_id $type_id value $value into stock ".$self->get_stock_id()."\n";
	    $stockprop_count++;
	}
    }

    # move subject relationships
    #
    my $ssrs = $schema->resultset("Stock::StockRelationship")->search( { subject_id => $other_stock_id });

    while (my $row = $ssrs->next()) {

	my $this_subject_rel_rs = $schema->resultset("Stock::StockRelationship")->search( { subject_id => $self->get_stock_id(), object_id => $row->object_id, type_id => $row->type_id() });

	if ($this_subject_rel_rs->count() == 0) { # this stock does not have the relationship
	    # get the max rank
	    my $rank_rs = $schema->resultset("Stock::StockRelationship")->search( { subject_id => $self->get_stock_id(), type_id => $row->type_id() });
	    my $rank = 0;
	    if ($rank_rs->count() > 0) {
		$rank = $rank_rs->get_column("rank")->max();
	    }
	    $rank++;
	    $row->rank($rank);
	    $row->subject_id($self->get_stock_id());
	    $row->update();
	    print STDERR "Moving subject relationships from stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	    $subject_rel_count++;
	}
    }

    # move object relationships
    #

    ## TO DO: check parents, because these will need special checks
    ## (if already two parents are present for the merge target, don't transfer the parents)
    ##
    my $female_parent_id = SGN::Model::Cvterm->get_cvterm_row($self->get_schema, 'stock_relationship', 'female_parent')->cvterm_id();
    my $male_parent_id   = SGN::Model::Cvterm->get_cvterm_row($self->get_schema, 'stock_relationship', 'male_parent')->cvterm_id();

    my $female_parent_rs = $schema->resultset("Stock::StockRelationship")->search( { object_id => $other_stock_id, type_id => $female_parent_id });
    my $male_parent_rs   = $schema->resultset("Stock::StockRelationship")->search( { object_id => $other_stock_id, type_id => $male_parent_id });

    my @parents = $self->get_direct_parents();
    my $this_female_parent_id;
    my $this_male_parent_id;

    if (@parents > 2) {
	print STDERR "WARNING: ".$self->get_uniquename()." has ".scalar(@parents)." parents! (too many!)\n";
    }

    foreach my $parent (@parents) {
	if ($parent->[2] eq "female") { $this_female_parent_id = $parent->[0]; }
	if ($parent->[2] eq "male") { $this_male_parent_id = $parent->[0]; }
    }


    if ($female_parent_rs->count() > 0) {
	if ($this_female_parent_id != $female_parent_rs->stock_id()) {
	    print STDERR "WARNING! Female parents are different for stock to be merged: ".$self->get_stock_id()." and ".$other_stock_id." NEEDS TO BE FIXED!\n";
	}
    }
    if ($male_parent_rs ->count() > 0) {
	if ($this_male_parent_id != $male_parent_rs->stock_id()) {
	    print STDERR "WARNING! Male parents are different for stock to be merged: ".$self->get_stock_id()." and ".$other_stock_id." NEEDS TO BE FIXED!\n";
	}
    }

    my $osrs = $schema->resultset("Stock::StockRelationship")->search( { object_id => $other_stock_id });
    while (my $row = $osrs->next()) {
	my $this_object_rel_rs = $schema->resultset("Stock::StockRelationship")->search( { object_id => $self->get_stock_id, subject_id => $row->subject_id(), type_id => $row->type_id() });

	if ($this_object_rel_rs->count() == 0) {
	    my $rank_rs = $schema->resultset("Stock::StockRelationship")->search( { object_id => $self->get_stock_id(), type_id => $row->type_id() });
	    my $rank = 0;
	    if ($rank_rs->count() > 0) {
		$rank = $rank_rs->get_column("rank")->max();
	    }
	    $rank++;
	    $row->rank($rank);
	    $row->object_id($self->get_stock_id());
	    $row->update();
	    print STDERR "Moving object relationships from stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	    $object_rel_count++;
	}
    }

    # move experiment_stock
    #
    my $esrs = $schema->resultset("NaturalDiversity::NdExperimentStock")->search( { stock_id => $other_stock_id });
    while (my $row = $esrs->next()) {
	$row->stock_id($self->get_stock_id());
	$row->update();
	print STDERR "Moving experiments for stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	$experiment_stock_count++;
    }

    # move stock_cvterm relationships
    #


    # move stock_dbxref
    #
    my $sdrs = $schema->resultset("Stock::StockDbxref")->search( { stock_id => $other_stock_id });
    while (my $row = $sdrs->next()) {
	$row->stock_id($self->get_stock_id());
	$row->update();
	$stock_dbxref_count++;
    }

    # move sgn.pcr_exp_accession relationships
    #


    # move sgn.pcr_experiment relationships
    #



    # move stock_genotype relationships
    #


    my $phenome_schema = CXGN::Phenome::Schema->connect(
	sub { $self->get_schema->storage->dbh() }, { on_connect_do => [ 'SET search_path TO phenome, public, sgn'], limit_dialect => 'LimitOffset' }
	);

    # move phenome.stock_allele relationships
    #
    my $sars = $phenome_schema->resultset("StockAllele")->search( { stock_id => $other_stock_id });
    while (my $row = $sars->next()) {
	$row->stock_id($self->get_stock_id());
	$row->udate();
	print STDERR "Moving stock alleles from stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	$stock_allele_count++;
    }

# move image relationships
    #

    my $irs = $phenome_schema->resultset("StockImage")->search( { stock_id => $other_stock_id });
    while (my $row = $irs->next()) {

	my $this_rs = $phenome_schema->resultset("StockImage")->search( { stock_id => $self->get_stock_id(), image_id => $row->image_id() } );
	if ($this_rs->count() == 0) {
	    $row->stock_id($self->get_stock_id());
	    $row->update();
	    print STDERR "Moving image ".$row->image_id()." from stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	    $image_count++;
	}
	else {
	    print STDERR "Removing stock_image entry...\n";
	    $row->delete(); # there is no cascade delete on image relationships, so we need to remove dangling relationships.
	}
    }

    # move stock owners
    #
    my $sors = $phenome_schema->resultset("StockOwner")->search( { stock_id => $other_stock_id });
    while (my $row = $sors->next()) {

	my $this_rs = $phenome_schema->resultset("StockOwner")->search( { stock_id => $self->get_stock_id(), sp_person_id => $row->sp_person_id() });
	if ($this_rs->count() == 0) {
	    $row->stock_id($self->get_stock_id());
	    $row->update();
	    print STDERR "Moved stock_owner ".$row->sp_person_id()." of stock $other_stock_id to stock ".$self->get_stock_id()."\n";
	    $stock_owner_count++;
	}
	else {
	    print STDERR "(Deleting stock owner entry for stock $other_stock_id, owner ".$row->sp_person_id()."\n";
	    $row->delete(); # see comment for move image relationships
	}
    }

    # move map parents
    #
    my $sgn_schema = SGN::Schema->connect(
	sub { $self->get_schema->storage->dbh() }, { limit_dialect => 'LimitOffset' }
	);

    my $mrs1 = $sgn_schema->resultset("Map")->search( { parent_1 => $other_stock_id });
    while (my $row = $mrs1->next()) {
	$row->parent_1($self->get_stock_id());
	$row->update();
	print STDERR "Move map parent_1 $other_stock_id to ".$self->get_stock_id()."\n";
	$parent_1_count++;
    }

    my $mrs2 = $sgn_schema->resultset("Map")->search( { parent_2 => $other_stock_id });
    while (my $row = $mrs2->next()) {
	$row->parent_2($self->get_stock_id());
	$row->update();
	print STDERR "Move map parent_2 $other_stock_id to ".$self->get_stock_id()."\n";
	$parent_2_count++;
    }

    if ($delete_other_stock) {
	my $row = $self->get_schema->resultset("Stock::Stock")->find( { stock_id => $other_stock_id });
	$row->delete();
	$other_stock_deleted = 'YES';
    }


    print STDERR "Done with merge of stock_id $other_stock_id into ".$self->get_stock_id()."\n";
    print STDERR "Relationships moved: \n";
    print STDERR <<COUNTS;
    Stock props: $stockprop_count
    Subject rels: $subject_rel_count
    Object rels: $object_rel_count
    Alleles: $stock_allele_count
    Images: $image_count
    Experiments: $experiment_stock_count
    Dbxrefs: $stock_dbxref_count
    Stock owners: $stock_owner_count
    Map parents: $parent_1_count
    Map parents: $parent_2_count
    Other stock deleted: $other_stock_deleted.
COUNTS

}

##########
1;########
##########
