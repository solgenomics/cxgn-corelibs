#!/usr/bin/perl

=head1 NAME

  expression.t
  A piece of code to test the CXGN::GEM::Expression module

=cut

=head1 SYNOPSIS

 perl expression.t

 Note: To run the complete test the database connection should be done as 
       postgres user 
 (web_usr have not privileges to insert new data into the gem tables)  

 prove expression.t

 This test needs some env. variables.
  export GEM_TEST_METALOADER='metaloader user'
  export GEM_TEST_DBDSN='database dsn as: 
     'dbi:DriverName:database=database_name;host=hostname;port=port'

  Example:
    export GEM_TEST_DBDSN='dbi:Pg:database=sandbox;host=localhost;'

  export GEM_TEST_DBUSER='database user with insert permissions'
  export GEM_TEST_DBPASS='database password'


=head1 DESCRIPTION

 This script check 93 variables to test the right operation of the 
 CXGN::GEM::Expression module:

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

    plan tests => 93;
}


BEGIN {
    use_ok('CXGN::GEM::Schema');             ## TEST1
    use_ok('CXGN::GEM::Expression');         ## TEST2
    use_ok('CXGN::Metadata::Metadbdata');    ## TEST3
    use_ok('CXGN::GEM::TechnologyType');     ## TEST4
    use_ok('CXGN::GEM::Platform');           ## TEST5
    use_ok('CXGN::GEM::Template');           ## TEST6
    use_ok('CXGN::GEM::ExperimentalDesign'); ## TEST7
    use_ok('CXGN::GEM::Experiment');         ## TEST8
    use_ok('CXGN::GEM::Target');             ## TEST9
    use_ok('CXGN::GEM::Hybridization');      ## TEST10
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

## Variables predifined by environment variables
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
my $last_template_expression_id = $nextvals{'ge_template_expression'} || 0;
my $last_expression_by_experiment_id = $nextvals{'ge_expression_by_experiment'} || 0;

my $last_experiment_id = $nextvals{'ge_experiment'} || 0;
my $last_template_id = $nextvals{'ge_template'} || 0;
my $last_hybridization_id = $nextvals{'ge_hybridization'} || 0;


## Create a empty metadata object to use in the database store functions
my $metadbdata = CXGN::Metadata::Metadbdata->new($schema, $creation_user_name);
my $creation_date = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();


#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 11 TO 22)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object; 

my $expression0 = CXGN::GEM::Expression->new($schema, undef); 

## The first to functions require set two hash references:

## 1) Experiment:

my $experiment0_href = { 
                         experiment_id           => $last_experiment_id+1,  
			 replicates_used         => 3, 
			 mean                    => 10, 
			 median                  => 10.5,
			 standard_desviation     => 0.1, 
			 coefficient_of_variance => 0.5
                       };

## 2) Hybridization

my $hybridization0_href = {
                            hybridization_id       => $last_hybridization_id+1,  
			    template_signal        => 1000, 
			    template_signal_type   => 'fluorescence', 
			    statistical_value      => 0.0001, 
			    statistical_value_type => 'p-value', 
			    flag                   => 'X'

                          };

## Now it will set both datatypes

$expression0->set_experiment($experiment0_href);
$expression0->set_hybridization($hybridization0_href);

## Finally it get get the data to check that it has been correctly set

my %experiment0 = $expression0->get_experiment();
my %hybridization0 = $expression0->get_hybridization();

my %expdata0 = %{$experiment0{$last_experiment_id+1}};
my %hybdata0 = %{$hybridization0{$last_hybridization_id+1}};

foreach my $exp_key (keys %expdata0) {

    my $msg0 = "TESTING get/set_experiment: checking $exp_key";
    is($expdata0{$exp_key}, $experiment0_href->{$exp_key}, $msg0)
	or diag "Looks like this failed";
}
foreach my $hyb_key (keys %hybdata0) {

    my $msg0 = "TESTING get/set_hybridization: checking $hyb_key";
    is($hybdata0{$hyb_key}, $hybridization0_href->{$hyb_key}, $msg0)
	or diag "Looks like this failed";
}

## Test get/force_set_template_id (TEST FROM 23 TO 25)

$expression0->force_set_template_id($last_template_id+2);
my %experiment0_a = $expression0->get_experiment();
my %hybridization0_a = $expression0->get_hybridization();

is($experiment0_a{$last_experiment_id+1}->{'template_id'}, $last_template_id+2, "TESTING force_set_template_id: checking final template_id using get_experiment")
    or diag "Looks like this failed";
is($hybridization0_a{$last_hybridization_id+1}->{'template_id'}, $last_template_id+2, "TESTING force_set_template_id: checking final template_id using get_hybridization")
    or diag "Looks like this failed";

my $template_id0 = $expression0->get_template_id();
is($template_id0, $last_template_id+2, "TESTING get_template_id: checking template_id using get_template_id")
    or diag "Looks like this failed";

## Testing the die results (TEST FROM 26 TO 33)

throws_ok { CXGN::GEM::Expression->new() } qr/PARAMETER ERROR: None schema/, 
    'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Expression->new($schema, 'no integer')} qr/DATA TYPE ERROR/, 
    'TESTING DIE ERROR when a non integer is used to create a expression object with new() function';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplateexperiment_row() } qr/FUNCTION PARAMETER ERROR: None getemplate_experiment_row/, 
    'TESTING DIE ERROR when none argument is supplied to set_getemplateexperiment_row() function';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplateexperiment_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_getemplateexperiment_row() is not an ARRAY REFERENCE';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplateexperiment_row([$schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when elements in the array ref. argument supplied to set_getemplateexperiment_row() is not a CXGN::GEM::Schema::GeExpressionByExperiment row object';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplatehybridization_row() } qr/FUNCTION PARAMETER ERROR: None getemplate_hybridization_row/, 
    'TESTING DIE ERROR when none argument is supplied to set_getemplatehybridization_row() function';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplatehybridization_row($schema) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when argument supplied to set_getemplatehybridization_row() is not an ARRAY REFERENCE';

throws_ok { CXGN::GEM::Expression->new($schema)->set_getemplatehybridization_row([$schema]) } qr/SET ARGUMENT ERROR:/, 
    'TESTING DIE ERROR when elements in the array ref. argument supplied to set_getemplatehybridization_row() is not a CXGN::GEM::Schema::GeTemplateExpression row object';

################################################################
## SECOND TEST BLOCK: Experiment Store and Obsolete Functions ##
################################################################

## Use of store functions.

eval {

    my $expression1 = CXGN::GEM::Expression->new($schema);

    ## Before use any store function it will need store the following data:

    ## 0) Template (so it needs TechnologyType and Platform)

    my $techtype = CXGN::GEM::TechnologyType->new($schema);
    $techtype->set_technology_name('technology_type_name_test');
    $techtype->store($metadbdata);
    my $techtype_id = $techtype->get_technology_type_id();

    my $platform = CXGN::GEM::Platform->new($schema);
    $platform->set_platform_name('platform_name_test');
    $platform->set_technology_type_id($techtype_id);
    $platform->store($metadbdata);
    my $platform_id = $platform->get_platform_id();

    my $template = CXGN::GEM::Template->new($schema);
    $template->set_template_name('template_name_test');
    $template->set_platform_id($platform_id);
    $template->store($metadbdata);
    my $template_id = $template->get_template_id();
    
    ## 1) Experiment (so it needs ExperimentalDesign before that)

    my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema);
    $expdesign->set_experimental_design_name('experimental_design_test');
    $expdesign->store($metadbdata);
    my $expdesign_id = $expdesign->get_experimental_design_id();

    my $experiment = CXGN::GEM::Experiment->new($schema);
    $experiment->set_experiment_name('experiment_test');
    $experiment->set_experimental_design_id($expdesign_id);
    $experiment->store($metadbdata);
    my $experiment_id = $experiment->get_experiment_id();

    ## 2) Hybridization (it needs Target)

    my $target = CXGN::GEM::Target->new($schema);
    $target->set_target_name('target_name_test');
    $target->set_experiment_id($experiment_id);
    $target->store($metadbdata);
    my $target_id = $target->get_target_id();

    my $hybridization = CXGN::GEM::Hybridization->new($schema);
    $hybridization->set_target_id($target_id);
    $hybridization->set_platform_id($platform_id);
    $hybridization->store($metadbdata);
    my $hybridization_id = $hybridization->get_hybridization_id();


    ## Now it will store a template_experiment_row (TEST FROM 34 TO 53)

    my $experiment1_href = { 
	                     experiment_id           => $experiment_id, 
			     template_id             => $template_id,
			     replicates_used         => 3, 
			     mean                    => 10, 
			     median                  => 10.5,
			     standard_desviation     => 0.1, 
			     coefficient_of_variance => 0.5
                           };

    $expression1->set_experiment($experiment1_href);
    
    my $hybridization1_href = {
                            hybridization_id       => $hybridization_id,  
			    template_signal        => 1000, 
			    template_signal_type   => 'fluorescence', 
			    statistical_value      => 0.0001, 
			    statistical_value_type => 'p-value', 
			    flag                   => 'X'

                          };
    
    $expression1->set_hybridization($hybridization1_href);

    ## Store should store both datatypes (experiment and hybridization)

    $expression1->store($metadbdata);

    my $expression2 = CXGN::GEM::Expression->new($schema, $template_id);

    my %experiment2 = $expression2->get_experiment();
    my %hybridization2 = $expression2->get_hybridization();

    my %expdata2= %{$experiment2{$experiment_id}};
    my %hybdata2= %{$hybridization2{$hybridization_id}};

    foreach my $exp_key2 (keys %expdata2) {

	my $msg1 = "TESTING store function for store_template_experiment: checking $exp_key2";
	
	
	## It also will return expression_by_experiment_id, but it has not the id, so it will skip that
	## using another test.

	if ($exp_key2 eq 'expression_by_experiment_id') {
	    is($expdata2{$exp_key2}, $last_expression_by_experiment_id+1, $msg1)
		or diag "Looks like this failed";
	}
	elsif ($exp_key2 eq 'metadata_id') {
	     is($expdata2{$exp_key2}, $last_metadata_id+1, $msg1)
		or diag "Looks like this failed";
	}
	else {
	    is($expdata2{$exp_key2}, $experiment1_href->{$exp_key2}, $msg1)
		or diag "Looks like this failed";
	}
    }
    foreach my $hyb_key2 (keys %hybdata2) {

	my $msg1 = "TESTING store function for store_template_hybridization: checking $hyb_key2";

	if ($hyb_key2 eq 'template_expression_id') {
	    is($hybdata2{$hyb_key2}, $last_template_expression_id+1, $msg1)
		or diag "Looks like this failed";
	}
	elsif ($hyb_key2 eq 'metadata_id') {
	    is($hybdata2{$hyb_key2}, $last_metadata_id+1, $msg1)
		or diag "Looks like this failed";
	}
	else {
	    is($hybdata2{$hyb_key2}, $hybridization1_href->{$hyb_key2}, $msg1)
		or diag "Looks like this failed";
	}
    }

    ## Now it will test the die for the store functions... (TEST FROM 54 TO 59)

    throws_ok { $expression2->store() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store() function';
    throws_ok { $expression2->store($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when metadbdata object supplied to store() function is not CXGN::Metadata::Metadbdata object';
    throws_ok { $expression2->store_template_experiment() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_template_experiment() function';
    throws_ok { $expression2->store_template_experiment($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when metadbdata object supplied to store_template_experiment() function is not CXGN::Metadata::Metadbdata object';
    throws_ok { $expression2->store_template_hybridization() } qr/STORE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to store_template_hybridization() function';
    throws_ok { $expression2->store_template_hybridization($schema) } qr/STORE ERROR: Metadbdata supplied/, 
      'TESTING DIE ERROR when metadbdata object supplied to store_template_hybridization() function is not CXGN::Metadata::Metadbdata object';

    
    ## Testing obsolete methods.

    ## 1) Get the metadata (TEST FROM 60 TO 63)

    my %metadbdata1 = $expression2->get_template_experiment_metadbdata();
    
    is($metadbdata1{$experiment_id}->get_metadata_id(), $last_metadata_id+1, "TESTING get_template_experiment_metadata: checking metadata_id")
	or diag "Looks like this failed";
    
    my %metadbdata2 = $expression2->get_template_hybridization_metadbdata();
    
    is($metadbdata2{$hybridization_id}->get_metadata_id(), $last_metadata_id+1, "TESTING get_template_hybridization_metadata: checking metadata_id")
	or diag "Looks like this failed";
    
    ## Both of them should not be obsolete
    
    is($expression2->is_template_experiment_obsolete($experiment_id), 0, "TESTING is_template_experiment_obsolete: checking 0/1")
	or diag "Looks like this failed";
    is($expression2->is_template_hybridization_obsolete($hybridization_id), 0, "TESTING is_template_hybridization_obsolete: checking 0/1")
	or diag "Looks like this failed";


    ## Now it will test a store modification (TEST FROM 64 TO 69)

    my $experiment2_href = { 
	                     experiment_id           => $experiment_id,
			     replicates_used         => 3, 
			     mean                    => 80,    ## Modification
			     median                  => 10.5,
			     standard_desviation     => 0.1, 
			     coefficient_of_variance => 0.5
                           };

    $expression2->set_experiment($experiment2_href);
    
    my $hybridization2_href = {
                            hybridization_id       => $hybridization_id,  
			    template_signal        => 1000,   
			    template_signal_type   => 'fluorescence', 
			    statistical_value      => 0.0001, 
			    statistical_value_type => 'p-value', 
			    flag                   => 'Y'      ## Modification

                          };
    
    $expression2->set_hybridization($hybridization2_href);

    $expression2->store($metadbdata);

    my $expression3 = CXGN::GEM::Expression->new($schema, $template_id);

    my %experiment3 = $expression3->get_experiment();
    my %hybridization3 = $expression3->get_hybridization();

    ## It will check the element modificated, an element no modificated and metadata_id

    is($experiment3{$experiment_id}->{replicates_used}, 3, "TESTING store_template_experiment function (modifications): Checking no modified element")
	or diag("Looks like this failed");
    is($experiment3{$experiment_id}->{mean}, 80, "TESTING store function (modifications): Checking modified element")
	or diag("Looks like this failed");
    is($experiment3{$experiment_id}->{metadata_id}, $last_metadata_id+2, "TESTING store_template_experiment function (modifications): Checking no new metadata_id")
	or diag("Looks like this failed");

    is($hybridization3{$hybridization_id}->{template_signal}, 1000, "TESTING store_template_hybridization function (modifications): Checking no modified element")
	or diag("Looks like this failed");
    is($hybridization3{$hybridization_id}->{flag}, 'Y', "TESTING store_template_hybridization function (modifications): Checking modified element")
	or diag("Looks like this failed");
    is($hybridization3{$hybridization_id}->{metadata_id}, $last_metadata_id+3, "TESTING store_template_hybridization function (modifications): Checking new metadata_id")
	or diag("Looks like this failed");

    ## 2.a) Obsolete data (template_experiment) (TEST FROM 70 TO 75)

    my $obsolete_note1 = "Test obsolete function for template experiment";
    $expression3->obsolete_template_experiment($metadbdata, $obsolete_note1, $experiment_id);
    
    my $expression4 = CXGN::GEM::Expression->new($schema, $template_id);
    is($expression4->is_template_experiment_obsolete($experiment_id), 1, "TESTING obsolete_template_experiment: checking 0/1")
	or diag "Looks like this failed";
    
    my %metadbdata4 = $expression4->get_template_experiment_metadbdata();
    is($metadbdata4{$experiment_id}->get_metadata_id(), $last_metadata_id+4, "TESTING obsolete_template_experiment: checking metadata_id")
	or diag "Looks like this failed";
    is($metadbdata4{$experiment_id}->get_obsolete_note(), $obsolete_note1, "TESTING obsolete_template_experiment: checking obsolete_note")
	or diag "Looks like this failed";

    my $obsolete_note2 = "Test revert obsolete function for template experiment";
    $expression4->obsolete_template_experiment($metadbdata, $obsolete_note2, $experiment_id, 'REVERT');

    my $expression5 = CXGN::GEM::Expression->new($schema, $template_id);
    is($expression5->is_template_experiment_obsolete($experiment_id), 0, "TESTING revert obsolete_template_experiment: checking 0/1")
	or diag "Looks like this failed";
    
    my %metadbdata5 = $expression5->get_template_experiment_metadbdata();
    is($metadbdata5{$experiment_id}->get_metadata_id(), $last_metadata_id+5, "TESTING revert obsolete_template_experiment: checking metadata_id")
	or diag "Looks like this failed";
    is($metadbdata5{$experiment_id}->get_obsolete_note(), $obsolete_note2, "TESTING revert obsolete_template_experiment: checking obsolete_note")
	or diag "Looks like this failed";

     ## 2.b) Obsolete data (template_hybridization) (TEST FROM 76 TO 81)

    my $obsolete_note3 = "Test obsolete function for template hybridization";
    $expression5->obsolete_template_hybridization($metadbdata, $obsolete_note3, $hybridization_id);
    
    my $expression6 = CXGN::GEM::Expression->new($schema, $template_id);
    is($expression6->is_template_hybridization_obsolete($hybridization_id), 1, "TESTING obsolete_template_hybridization: checking 0/1")
	or diag "Looks like this failed";
    
    my %metadbdata6 = $expression6->get_template_hybridization_metadbdata();
    is($metadbdata6{$hybridization_id}->get_metadata_id(), $last_metadata_id+6, "TESTING obsolete_template_hybridization: checking metadata_id")
	or diag "Looks like this failed";
    is($metadbdata6{$hybridization_id}->get_obsolete_note(), $obsolete_note3, "TESTING obsolete_template_hybridization: checking obsolete_note")
	or diag "Looks like this failed";

    my $obsolete_note4 = "Test revert obsolete function for template hybridization";
    $expression6->obsolete_template_hybridization($metadbdata, $obsolete_note4, $hybridization_id, 'REVERT');

    my $expression7 = CXGN::GEM::Expression->new($schema, $template_id);
    is($expression7->is_template_hybridization_obsolete($hybridization_id), 0, "TESTING revert obsolete_template_hybridization: checking 0/1")
	or diag "Looks like this failed";
    
    my %metadbdata7 = $expression7->get_template_hybridization_metadbdata();
    is($metadbdata7{$hybridization_id}->get_metadata_id(), $last_metadata_id+7, "TESTING revert obsolete_template_hybridization: checking metadata_id")
	or diag "Looks like this failed";
    is($metadbdata7{$hybridization_id}->get_obsolete_note(), $obsolete_note4, "TESTING revert obsolete_template_hybridization: checking obsolete_note")
	or diag "Looks like this failed";

    
    ## Testing of the die for obsolete functions (TEST FROM 82 TO 91)

    throws_ok { $expression7->obsolete_template_experiment() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_template_experiment() function';
    throws_ok { $expression7->obsolete_template_experiment($schema) } qr/OBSOLETE ERROR: Metadbdata obj./, 
      'TESTING DIE ERROR when metadbdata object supplied to obsolete_template_experiment() function is not a CXGN::Metadata::Metadbdata object';
    throws_ok { $expression7->obsolete_template_experiment($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_template_experiment() function';
    throws_ok { $expression7->obsolete_template_experiment($metadbdata, 'obsolete_note') } qr/OBSOLETE ERROR: None experiment_id/, 
      'TESTING DIE ERROR when none experiment_id is supplied to obsolete_template_experiment() function';
    throws_ok { $expression7->obsolete_template_experiment($metadbdata, 'obsolete_note', $last_experiment_id+3) } qr/OBSOLETE ERROR: Experiment_id/, 
      'TESTING DIE ERROR when experiment_id supplied to obsolete_template_experiment() function does not exist';

    throws_ok { $expression7->obsolete_template_hybridization() } qr/OBSOLETE ERROR: None metadbdata/, 
      'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_template_hybridization() function';
    throws_ok { $expression7->obsolete_template_hybridization($schema) } qr/OBSOLETE ERROR: Metadbdata obj./, 
      'TESTING DIE ERROR when metadbdata object supplied to obsolete_template_hybridization() function is not a CXGN::Metadata::Metadbdata object';
    throws_ok { $expression7->obsolete_template_hybridization($metadbdata) } qr/OBSOLETE ERROR: None obsolete note/, 
      'TESTING DIE ERROR when none obsolete note is supplied to obsolete_template_hybridization() function';
    throws_ok { $expression7->obsolete_template_hybridization($metadbdata, 'obsolete_note') } qr/OBSOLETE ERROR: None hybridization_id/, 
      'TESTING DIE ERROR when none experiment_id is supplied to obsolete_template_hybridization() function';
    throws_ok { $expression7->obsolete_template_hybridization($metadbdata, 'obsolete_note', $last_hybridization_id+3) } qr/OBSOLETE ERROR: Hybridization_id/, 
      'TESTING DIE ERROR when experiment_id supplied to obsolete_template_hybridization() function does not exist';

    #############################
    ## TEST OF EXTRA FUNCTIONS ##
    #############################

    ## 1) get_experiment_object (TEST 92)

    my @experiments = $expression7->get_experiment_object();
    
    is($experiments[0]->get_experiment_name(), 'experiment_test', "TESTING get_experiment_object, testing experiment_name")
	or diag("Looks like this failed");


    ## 2) get_hybridization_object (TEST 93)

    my @hybridization = $expression7->get_hybridization_object();
    
    is($hybridization[0]->get_platform_id(), $platform_id, "TESTING get_hybridization_object, testing platform_id")
	or diag("Looks like this failed");



};  ## End of the eval function

if ($@) {
    print "\nEVAL ERROR:\n\n$@\n";
}


 ## RESTORING THE ORIGINAL STATE IN THE DATABASE
## To restore the original state in the database, rollback (it is in a transaction) and set the table_sequence values. 

$schema->txn_rollback();

## The transaction change the values in the sequence, so if we want set the original value, before the changes
 ## we have two options:
  ##     1) SELECT setval (<sequence_name>, $last_value_before_change, true); that said, ok your last true value was...
   ##    2) SELECT setval (<sequence_name>, $last_value_before_change+1, false); It is false that your last value was ... so the 
    ##      next time take the value before this.
     ##  
      ##   The option 1 leave the seq information in a original state except if there aren't any value in the seq, that it is
       ##   more as the option 2 

####
1; #
####
