#!/usr/bin/perl

=head1 NAME

  po_functions_expdesign.t
  A piece of code to test PO functions in CXGN::GEM::ExperimentalDesign 

=cut

=head1 SYNOPSIS

 perl po_functions_expdesign.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove experimentaldesign.t

 this test needs some environment variables:
  export GEM_TEST_METALOADER='metaloader user'
  export GEM_TEST_DBDSN='database dsn as: 
     'dbi:DriverName:database=database_name;host=hostname;port=port'

  Example:
    export GEM_TEST_DBDSN='dbi:Pg:database=sandbox;host=localhost;'

  export GEM_TEST_DBUSER='database user with insert permissions'
  export GEM_TEST_DBPASS='database password'

=head1 DESCRIPTION

 This script check functions related with PO terms (cvterm)

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut


use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

use CXGN::DB::Connection;

## The tests still need search_path

my @schema_list = ('gem', 'biosource', 'metadata', 'public');
my $schema_list = join(',', @schema_list);
my $set_path = "SET search_path TO $schema_list";

## First check env. variables and connection

BEGIN {

    ## Env. variables have been changed to use biosource specific ones

    my @env_variables = qw/GEM_TEST_METALOADER GEM_TEST_DBDSN GEM_TEST_DBUSER GEM_TEST_DBPASS/;

    for my $env (@env_variables) {
        unless (defined $ENV{$env}) {
            plan skip_all => "Environment variable $env not set, aborting";
        }
    }

    eval { 
        CXGN::DB::Connection->new( 
                                   $ENV{GEM_TEST_DBDSN}, 
                                   $ENV{GEM_TEST_DBUSER}, 
                                   $ENV{GEM_TEST_DBPASS}, 
                                   {on_connect_do => $set_path}
                                 ); 
    };

    if ($@ =~ m/DBI connect/) {

        plan skip_all => "Could not connect to database";
    }

    plan tests => 10;
}

BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::ExperimentalDesign'); ## TEST2
    use_ok('CXGN::GEM::Experiment');         ## TEST3
    use_ok('CXGN::GEM::Target');             ## TEST4
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST5
    use_ok('CXGN::Biosource::Sample');       ## TEST6
}

#if we cannot load the Schema modules, no point in continuing
CXGN::Biosource::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Biosource::Schema module');
CXGN::Metadata::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Metadata::Schema module');
Bio::Chado::Schema->can('connect')
    or BAIL_OUT('could not load the Bio::Chado::Schema module');
CXGN::GEM::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::GEM::Schema module');


my $creation_user_name = $ENV{GEM_TEST_METALOADER};

## The GEM schema contain all the metadata, chado and biosource classes so don't need to create another Metadata schema

my $schema = CXGN::GEM::Schema->connect( $ENV{GEM_TEST_DBDSN}, 
                                         $ENV{GEM_TEST_DBUSER}, 
                                         $ENV{GEM_TEST_DBPASS}, 
                                         {on_connect_do => $set_path});

$schema->txn_begin();


## Get the last values

my %nextvals = $schema->get_nextval();
my $last_metadata_id = $nextvals{'md_metadata'} || 0;
my $last_expdesign_id = $nextvals{'ge_experimental_design'} || 0;
my $last_dbxref_id = $nextvals{'dbxref'} || 0;
my $last_pub_id = $nextvals{'pub'} || 0;


## Create a empty metadata object to use in the database store functions

my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();




eval {

    ##################################
    ### 1) PO CHECKING AND LOADING ###
    ##################################

    ## Test if exists all the PO variables needed and insert them if does not exists

    ## Define the list of things needed:
    
    ## 1.a) db.name='PO', dbxref.accession='0009011', cv.name='plant_structure', cvterm.name='plant structure' 
    ## 1.b) db.name='PO', dbxref.accession='0009003', cv.name='plant_structure', cvterm.name='sporophyte' 
    ## 1.c) db.name='PO', dbxref.accession='0006342', cv.name='plant_structure', cvterm.name='infructescence' 
    ## 1.d) db.name='PO', dbxref.accession='0009001', cv.name='plant_structure', cvterm.name='fruit' 

    my %po_cv_id;
    my %po_cvterm_id;
    my %po_dbxref_id;
    
    my %po_data = ( 
	'plant_structure' => {
	    'plant structure' => '0009011',
	    'sporophyte'      => '0009003',
	    'infructescence'  => '0006342',
	    'fruit'           => '0009001',
	    'organ'           => '0009008',
	    'phyllome'        => '0006001',
	    'leaf'            => '0009025' 
	},
	'plant_growth_and_development_stage' => {
	    'plant growth and development stages' => '0009012',
	    'whole plant growth stages'           => '0007033',
	    'B reproductive growth'               => '0007130',
	    '6 ripening'                          => '0007010',
	    'FR.00 beginning of fruit ripening'   => '0007036',
	    'FR.02 mid stage of fruit ripening'   => '0007031',
	    'FR.04 fruit ripening complete'       => '0007038'
	}
	);
    
    foreach my $cv_name (keys %po_data) {
	my %po_terms = %{$po_data{$cv_name}};

	foreach my $cvterm_name (keys %po_terms) {	    
	    my $cvterm_row = $schema->resultset('Cv::Cvterm')
	                            ->create_with( 
	                                           { 
						       name   => $cvterm_name,
						       cv     => $cv_name,
						       db     => 'PO',
						       dbxref => $po_terms{$cvterm_name},
						   } 
				    );
      
	    ## Get the cvterm_id

	    $po_cv_id{$cv_name} = $cvterm_row->get_column('cv_id');	    
	    $po_cvterm_id{$cvterm_name} = $cvterm_row->get_column('cvterm_id');

	    ## Get the dbxref_id to load samples

	    $po_dbxref_id{$cvterm_name} = $cvterm_row->get_column('dbxref_id');    
	}
    }

    ## Check if exists the cvtermpath associated with these PO terms.
    ## The cvtermpath are:
    ## subject_id=$po_cvterm_id_po{'fruit'}, object_id=$po_cvterm_id_po{'infructescence'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=1
    ## subject_id=$po_cvterm_id_po{'fruit'}, object_id=$po_cvterm_id_po{'sporophyte'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=2
    ## subject_id=$po_cvterm_id_po{'fruit'}, object_id=$po_cvterm_id_po{'plant structure'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=3
    ## subject_id=$po_cvterm_id_po{'leaf'}, object_id=$po_cvterm_id_po{'phyllome'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=1
    ## subject_id=$po_cvterm_id_po{'leaf'}, object_id=$po_cvterm_id_po{'organ'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=2
    ## subject_id=$po_cvterm_id_po{'leaf'}, object_id=$po_cvterm_id_po{'plant structure'}, cv_id=$po_cv_id{'plant_structure'}, pathdistance=3
    ## These data will be stored as array of hash references
    
    ## Get the type
    my $type_row = $schema->resultset('Cv::Cvterm')
	                  ->create_with( 
	                                           { 
						       name   => 'is_a',
						       cv     => 'relationship',
						       db     => 'OBO_REL',
						       dbxref => 'is_a',
						   } 
				    );
    my $type_id = $type_row->get_column('cvterm_id');

    my %hash1 = (subject_id => $po_cvterm_id{'fruit'}, object_id => $po_cvterm_id{'infructescence'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 1, type_id => $type_id);
    my %hash2 = (subject_id => $po_cvterm_id{'fruit'}, object_id => $po_cvterm_id{'sporophyte'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 2, type_id => $type_id);
    my %hash3 = (subject_id => $po_cvterm_id{'fruit'}, object_id => $po_cvterm_id{'plant structure'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 3, type_id => $type_id);
    my %hash4 = (subject_id => $po_cvterm_id{'leaf'}, object_id => $po_cvterm_id{'phyllome'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 1, type_id => $type_id);
    my %hash5 = (subject_id => $po_cvterm_id{'leaf'}, object_id => $po_cvterm_id{'organ'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 2, type_id => $type_id);
    my %hash6 = (subject_id => $po_cvterm_id{'leaf'}, object_id => $po_cvterm_id{'plant structure'}, 
		 cv_id => $po_cv_id{'plant_structure'}, pathdistance => 3, type_id => $type_id);
    my %hash7 = (subject_id => $po_cvterm_id{'FR.00 beginning of fruit ripening'}, object_id => $po_cvterm_id{'6 ripening'}, 
		 cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 1, type_id => $type_id);
    my %hash8 = (subject_id => $po_cvterm_id{'FR.00 beginning of fruit ripening'}, object_id => $po_cvterm_id{'B reproductive growth'}, 
		 cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 2, type_id => $type_id);
    my %hash9 = (subject_id => $po_cvterm_id{'FR.00 beginning of fruit ripening'}, object_id => $po_cvterm_id{'whole plant growth stages'}, 
		 cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 3, type_id => $type_id);
    my %hash10 = (subject_id => $po_cvterm_id{'FR.00 beginning of fruit ripening'}, object_id => $po_cvterm_id{'plant growth and development stages'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 4, type_id => $type_id);
    my %hash11 = (subject_id => $po_cvterm_id{'FR.02 mid stage of fruit ripening'}, object_id => $po_cvterm_id{'6 ripening'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 1, type_id => $type_id);
    my %hash12 = (subject_id => $po_cvterm_id{'FR.02 mid stage of fruit ripening'}, object_id => $po_cvterm_id{'B reproductive growth'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 2, type_id => $type_id);
    my %hash13 = (subject_id => $po_cvterm_id{'FR.02 mid stage of fruit ripening'}, object_id => $po_cvterm_id{'whole plant growth stages'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 3, type_id => $type_id);
    my %hash14 = (subject_id => $po_cvterm_id{'FR.02 mid stage of fruit ripening'}, object_id => $po_cvterm_id{'plant growth and development stages'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 4, type_id => $type_id);
    my %hash15 = (subject_id => $po_cvterm_id{'FR.04 fruit ripening complete'}, object_id => $po_cvterm_id{'6 ripening'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 1, type_id => $type_id);
    my %hash16 = (subject_id => $po_cvterm_id{'FR.04 fruit ripening complete'}, object_id => $po_cvterm_id{'B reproductive growth'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 2, type_id => $type_id);
    my %hash17 = (subject_id => $po_cvterm_id{'FR.04 fruit ripening complete'}, object_id => $po_cvterm_id{'whole plant growth stages'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 3, type_id => $type_id);
    my %hash18 = (subject_id => $po_cvterm_id{'FR.04 fruit ripening complete'}, object_id => $po_cvterm_id{'plant growth and development stages'}, 
		  cv_id => $po_cv_id{'plant_growth_and_development_stage'}, pathdistance => 4, type_id => $type_id);

    my @popath = (\%hash1, \%hash2, \%hash3, \%hash4, \%hash5, \%hash6, 
		  \%hash7, \%hash8, \%hash9, \%hash10, \%hash11, \%hash12, 
		  \%hash13, \%hash14, \%hash15, \%hash16, \%hash17, \%hash18,);


    ## The function to test does use other data (type_id) or tables (cvtermrelationship) so if these data do not exist the test will not add them
    
    foreach my $data_href (@popath) {
    
	my ($cvtermpath_row) = $schema->resultset('Cv::Cvtermpath')
	                              ->find_or_create($data_href);

	my $cvtermpath_id = $cvtermpath_row->get_column('cvtermpath_id');
    }

    ## Now all the PO data should be loaded

    
    ################################
    ### 2) GEM DATA TEST LOADING ###
    ################################

    ## 1) ExperimentalDesign
    
    my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema);
    $expdesign->set_experimental_design_name('experimental_design_test');
    $expdesign->set_design_type('test');
    $expdesign->set_description('This is a description test');

    $expdesign->store_experimental_design($metadbdata);
    my $expdesign_id = $expdesign->get_experimental_design_id();

    ## Also it will create a default experimental design to trest the default behaviour of the function
    ## returning the experiments alphabetically order

    my $expdesign2 = CXGN::GEM::ExperimentalDesign->new($schema);
    $expdesign2->set_experimental_design_name('default experimental_design_test');
    $expdesign2->set_design_type('test');
    $expdesign2->set_description('This is a description test');

    $expdesign2->store_experimental_design($metadbdata);
    my $expdesign_id2 = $expdesign2->get_experimental_design_id();

    ## 2) Experiments
    ##    This test will create 4 experiments ('Leaf test', 'Red Fruit test', 'Yellow Fruit test', 'Green Fruit test')
    
    my @experiment_names = ('Leaf test', 'Red Fruit test', 'Yellow Fruit test', 'Green Fruit test');
    my @default_exp_names = ('Leaf default test', 'Red Fruit default test', 'Yellow Fruit default test', 'Green Fruit default test');
    my @target_suffix = ('Target 1', 'Target 2', 'Target 3');
    my %po_associations = ( 'Leaf test'         => ['leaf'], 
			    'Red Fruit test'    => ['fruit', 'FR.04 fruit ripening complete'], 
			    'Yellow Fruit test' => ['fruit', 'FR.02 mid stage of fruit ripening'], 
			    'Green Fruit test'  => ['fruit', 'FR.00 beginning of fruit ripening']
	                  );
    
    ## First it will create the default values (default experiment does not need target, samples ... )

    foreach my $def_exp_name (@default_exp_names) {
	my $exp2 = CXGN::GEM::Experiment->new($schema);
	$exp2->set_experiment_name($def_exp_name);
	$exp2->set_experimental_design_id($expdesign_id2);
	$exp2->set_replicates_nr(3);
	$exp2->set_colour_nr(1);
	$exp2->set_contact_id($creation_user_id);

	$exp2->store_experiment($metadbdata);
    }

    ## Real dataset

    foreach my $exp_name (@experiment_names) {
	
	my $exp = CXGN::GEM::Experiment->new($schema);
	$exp->set_experiment_name($exp_name);
	$exp->set_experimental_design_id($expdesign_id);
	$exp->set_replicates_nr(3);
	$exp->set_colour_nr(1);
	$exp->set_contact_id($creation_user_id);

	$exp->store_experiment($metadbdata);
	my $exp_id = $exp->get_experiment_id();

	## 3) Target
	##    The target will have the name $exp_name . ' target 1'...

	foreach my $target_suffix (@target_suffix) {
	    
	    my $target_name = $exp_name . ' ' . $target_suffix;

	    my $target = CXGN::GEM::Target->new($schema);
	    $target->set_target_name($target_name);
	    $target->set_experiment_id($exp_id);

	    $target->store_target($metadbdata);
	    my $target_id = $target->get_target_id();

	    ## Before add target element we need to create the samples associaed with the targets
	    
	    ## 4) Sample

	    my $sample_name = $target_name;
	    $sample_name =~ s/Target/Sample/;
	
	    my $sample = CXGN::Biosource::Sample->new($schema);
	    $sample->set_sample_name($sample_name);
	    $sample->set_description('This is a description test');
	    $sample->set_contact_by_username($creation_user_name);

	    ## Also It need dbxref_id associated with the PO terms

	    my @po_terms = @{$po_associations{$exp_name}};
	    foreach my $term (@po_terms) {
		my $podbxref_id = $po_dbxref_id{$term};
		$sample->add_dbxref($podbxref_id);
	    }
	    $sample->store($metadbdata);
	    my $sample_id = $sample->get_sample_id();

	    ## 5) Target Element
	    
	    my $target_element_name = $target_name;
	    $target_element_name =~ s/Target/Target Element/;

	    $target->add_target_element(
                                     {
                                       target_element_name => $target_element_name,
                                       sample_name         => $sample_name,
                                       dye                 => 'Test Dye',
                                     }
                                   );
	    $target->store($metadbdata);
	}
    }

    #########################
    ## 3) FUNCTION TESTING ##
    #########################

    ## 1) First Get the object

    my $test_expdesign = CXGN::GEM::ExperimentalDesign->new($schema, $expdesign_id);
    
    ## 2) Define the expected list

    my @exp_experiment_names = ('Green Fruit test', 'Yellow Fruit test', 'Red Fruit test', 'Leaf test');

    ## 3) Use the function

    my @obt_experiment_names = ();
    my @test_experiments = $test_expdesign->get_po_sorted_experiment_list();
    foreach my $test_exp (@test_experiments) {
	my $test_name = $test_exp->get_experiment_name();
	push @obt_experiment_names, $test_name;
    }

    ## 4) Check the results

    is(scalar(@obt_experiment_names), scalar(@exp_experiment_names), "TESTING get_po_sorted_experiment_list function, checking array element count")
	or diag("Looks like this failed");
    is(join(',', @obt_experiment_names), join(',', @exp_experiment_names), "TESTING get_po_sorted_experiment_list function, checking array element names")
	or diag("Looks like this failed");

    ## 5) Testing default

    my $test_expdesign2 = CXGN::GEM::ExperimentalDesign->new($schema, $expdesign_id2);
    
    my @exp_def_experiment_names = ('Green Fruit default test', 'Leaf default test', 'Red Fruit default test', 'Yellow Fruit default test');
    my @obt_def_experiment_names = ();
    my @def_test_experiments = $test_expdesign2->get_po_sorted_experiment_list();
    foreach my $def_test_exp (@def_test_experiments) {
	my $def_test_name = $def_test_exp->get_experiment_name();
	push @obt_def_experiment_names, $def_test_name;
    }

    is(scalar(@obt_def_experiment_names), scalar(@exp_def_experiment_names), "TESTING get_po_sorted_experiment_list function (default), checking array element count")
	or diag("Looks like this failed");
    is(join(',', @obt_def_experiment_names), join(',', @exp_def_experiment_names), "TESTING get_po_sorted_experiment_list function (default), checking array element names")
	or diag("Looks like this failed");

};  ## End of the eval function

if ($@) {
    print "\nEVAL ERROR:\n\n$@\n";
}


## ROLLBACK

$schema->txn_rollback();



####
1; #
####
