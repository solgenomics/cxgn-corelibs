#!/usr/bin/perl

=head1 NAME

  experiment.t
  A piece of code to test the CXGN::GEM::Experiment module

=cut

=head1 SYNOPSIS

 perl experiment.t

 Note: To run the complete test the database connection should be done as
       postgres user
 (web_usr have not privileges to insert new data into the gem tables)

 prove experiment.t

 This test needs some env. variables.
  export GEM_TEST_METALOADER='metaloader user'
  export GEM_TEST_DBDSN='database dsn as:
     'dbi:DriverName:database=database_name;host=hostname;port=port'

  Example:
    export GEM_TEST_DBDSN='dbi:Pg:database=sandbox;host=localhost;'

  export GEM_TEST_DBUSER='database user with insert permissions'
  export GEM_TEST_DBPASS='database password'


=head1 DESCRIPTION

 This script check 75 variables to test the right operation of the
 CXGN::GEM::Experiment module:

=cut

=head1 AUTHORS

 Aureliano Bombarely Gomez
 (ab782@cornell.edu)

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use CXGN::GEM::Test;

my $gem_test = CXGN::GEM::Test->new;

plan tests => 75;

use_ok('CXGN::GEM::Schema');                ## TEST1
use_ok('CXGN::GEM::ExperimentalDesign');    ## TEST2
use_ok('CXGN::GEM::Experiment');            ## TEST3
use_ok('CXGN::GEM::Target');                ## TEST4
use_ok('CXGN::Metadata::Metadbdata');       ## TEST5

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
my $creation_user_name = $gem_test->metaloader_user;

my $schema = $gem_test->dbic_schema('CXGN::GEM::Schema');

$schema->txn_begin();

## Get the last values
my %nextvals           = $schema->get_nextval();
my $last_metadata_id   = $nextvals{'md_metadata'} || 0;
my $last_expdesign_id  = $nextvals{'ge_experimental_design'} || 0;
my $last_experiment_id = $nextvals{'ge_experiment'} || 0;
my $last_dbxref_id     = $nextvals{'dbxref'} || 0;

## Create a empty metadata object to use in the database store functions
my $metadbdata =
  CXGN::Metadata::Metadbdata->new( $schema, $creation_user_name );
my $creation_date    = $metadbdata->get_object_creation_date();
my $creation_user_id = $metadbdata->get_object_creation_user_by_id();

#######################################
## FIRST TEST BLOCK: Basic functions ##
#######################################

## (TEST FROM 6 to 12)
## This is the first group of tests, to check if an empty object can store and after can return the data
## Create a new empty object;

my $exp0 = CXGN::GEM::Experiment->new( $schema, undef );

## Load of the eight different parameters for an empty object using a hash with keys=root name for tha function and
## values=value to test

my %test_values_for_empty_object = (
    experiment_id          => $last_experiment_id + 1,
    experiment_name        => 'experiment test',
    experimental_design_id => $last_expdesign_id + 1,
    replicates_nr          => 3,
    colour_nr              => 1,
    description            => 'this is a description test',
    contact_id             => $creation_user_id
);

## Load the data in the empty object
my @function_keys = sort keys %test_values_for_empty_object;
foreach my $rootfunction (@function_keys) {
    my $setfunction = 'set_' . $rootfunction;
    if ( $rootfunction eq 'experiment_id' ) {
        $setfunction = 'force_set_' . $rootfunction;
    }
    $exp0->$setfunction( $test_values_for_empty_object{$rootfunction} );
}

## Get the data from the object and store in two hashes. The first %getdata with keys=root_function_name and
## value=value_get_from_object and the second, %testname with keys=root_function_name and values=name for the test.

my ( %getdata, %testnames );
foreach my $rootfunction (@function_keys) {
    my $getfunction = 'get_' . $rootfunction;
    my $data        = $exp0->$getfunction();
    $getdata{$rootfunction} = $data;
    my $testname = 'BASIC SET/GET FUNCTION for ' . $rootfunction . ' test';
    $testnames{$rootfunction} = $testname;
}

## And now run the test for each function and value

foreach my $rootfunction (@function_keys) {
    is(
        $getdata{$rootfunction},
        $test_values_for_empty_object{$rootfunction},
        $testnames{$rootfunction}
    ) or diag "Looks like this failed.";
}

## Testing the die results (TEST 13 to 23)

throws_ok { CXGN::GEM::Experiment->new() } qr/PARAMETER ERROR: None schema/,
  'TESTING DIE ERROR when none schema is supplied to new() function';

throws_ok { CXGN::GEM::Experiment->new( $schema, 'no integer' ) }
qr/DATA TYPE ERROR/,
'TESTING DIE ERROR when a non integer is used to create a protocol object with new() function';

throws_ok { CXGN::GEM::Experiment->new($schema)->set_geexperiment_row() }
qr/PARAMETER ERROR: None geexperiment_row/,
'TESTING DIE ERROR when none schema is supplied to set_geexperiment_row() function';

throws_ok { CXGN::GEM::Experiment->new($schema)->set_geexperiment_row($schema) }
qr/SET ARGUMENT ERROR:/,
'TESTING DIE ERROR when argument supplied to set_geexperiment_row() is not a CXGN::GEM::Schema::GeExperiment row object';

throws_ok { CXGN::GEM::Experiment->new($schema)->force_set_experiment_id() }
qr/PARAMETER ERROR: None/,
'TESTING DIE ERROR when none experimental_design_id is supplied to set_force_experiment_id() function';

throws_ok {
    CXGN::GEM::Experiment->new($schema)->force_set_experiment_id('non integer');
}
qr/DATA TYPE ERROR:/,
'TESTING DIE ERROR when argument supplied to set_force_experiment_id() is not an integer';

throws_ok { CXGN::GEM::Experiment->new($schema)->set_experiment_name() }
qr/PARAMETER ERROR: None data/,
'TESTING DIE ERROR when none data is supplied to set_experiment_name() function';

throws_ok { CXGN::GEM::Experiment->new($schema)->set_experimental_design_id() }
qr/PARAMETER ERROR: None/,
'TESTING DIE ERROR when none experimental_design_id is supplied to set_experimental_design_id() function';

throws_ok {
    CXGN::GEM::Experiment->new($schema)
      ->set_experimental_design_id('non integer');
}
qr/DATA TYPE ERROR:/,
'TESTING DIE ERROR when argument supplied to set_experimental_design_id() is not an integer';

throws_ok {
    CXGN::GEM::Experiment->new($schema)->set_replicates_nr('non integer');
}
qr/DATA ARGUMENT ERROR:/,
'TESTING DIE ERROR when argument supplied to set_replicates_nr() is not an integer';

throws_ok { CXGN::GEM::Experiment->new($schema)->set_colour_nr('non integer') }
qr/DATA ARGUMENT ERROR:/,
'TESTING DIE ERROR when argument supplied to set_colour_nr() is not an integer';

################################################################
## SECOND TEST BLOCK: Experiment Store and Obsolete Functions ##
################################################################

## Use of store functions.

eval {

    ## Before work with any store function for Experiment, it will need create a Experimental_Design row inside the database to get
    ## a real experimental_design_id

    my $expdesign = CXGN::GEM::ExperimentalDesign->new($schema);
    $expdesign->set_experimental_design_name('experimental_design_test');
    $expdesign->set_design_type('test');
    $expdesign->set_description('This is a description test');

    $expdesign->store_experimental_design($metadbdata);
    my $expdesign_id = $expdesign->get_experimental_design_id();

    ## Now it will create a Experiment Object and store all the data

    my $exp1 = CXGN::GEM::Experiment->new($schema);
    $exp1->set_experiment_name('exp1');
    $exp1->set_experimental_design_id($expdesign_id);
    $exp1->set_replicates_nr(5);
    $exp1->set_colour_nr(2);
    $exp1->set_contact_id($creation_user_id);

    $exp1->store_experiment($metadbdata);

    ## Testing the experiment data stored (TEST 24 TO 29)

    my $exp_id1 = $exp1->get_experiment_id();
    is(
        $exp_id1,
        $last_experiment_id + 1,
        "TESTING STORE_EXPERIMENT FUNCTION, checking experiment_id"
    ) or diag "Looks like this failed";

    my $exp2 = CXGN::GEM::Experiment->new( $schema, $exp_id1 );
    is( $exp2->get_experiment_name(),
        'exp1', "TESTING STORE_EXPERIMENT FUNCTION, checking experiment_name" )
      or diag "Looks like this failed";
    is( $exp2->get_experimental_design_id(),
        $expdesign_id,
        "TESTING STORE_EXPERIMENT FUNCTION, checking experimental_design_id" )
      or diag "Looks like this failed";
    is( $exp2->get_replicates_nr(),
        5, "TESTING STORE_EXPERIMENT FUNCTION, checking replicates_nr" )
      or diag "Looks like this failed";
    is( $exp2->get_colour_nr(), 2,
        "TESTING STORE_EXPERIMENT FUNCTION, checking colour_nr" )
      or diag "Looks like this failed";
    is( $exp2->get_contact_id(), $creation_user_id,
        "TESTING STORE_EXPERIMENT FUNCTION, checking contact_id" )
      or diag "Looks like this failed";

    ## Testing the get_medatata function (TEST 30 to 32)

    my $obj_metadbdata = $exp2->get_experiment_metadbdata();
    is(
        $obj_metadbdata->get_metadata_id(),
        $last_metadata_id + 1,
        "TESTING GET_METADATA FUNCTION, checking the metadata_id"
    ) or diag "Looks like this failed";
    is( $obj_metadbdata->get_create_date(),
        $creation_date, "TESTING GET_METADATA FUNCTION, checking create_date" )
      or diag "Looks like this failed";
    is( $obj_metadbdata->get_create_person_id_by_username,
        $creation_user_name,
        "TESING GET_METADATA FUNCTION, checking create_person by username" )
      or diag "Looks like this failed";

    ## Testing die for store_experiment function (TEST 33 and 34)

    throws_ok { $exp2->store_experiment() } qr/STORE ERROR: None metadbdata/,
'TESTING DIE ERROR when none metadbdata object is supplied to store_experiment() function';

    throws_ok { $exp2->store_experiment($schema) }
    qr/STORE ERROR: Metadbdata supplied/,
'TESTING DIE ERROR when argument supplied to store_experiment() is not a CXGN::Metadata::Metadbdata object';

    ## Testing if it is_obsolete (TEST 35)

    is( $exp2->is_experiment_obsolete(),
        0, "TESTING IS_EXPERIMENT_OBSOLETE FUNCTION, checking boolean" )
      or diag "Looks like this failed";

    ## Testing obsolete functions (TEST 36 to 39)

    $exp2->obsolete_experiment( $metadbdata, 'testing obsolete' );

    is( $exp2->is_experiment_obsolete(), 1,
"TESTING EXPERIMENT_OBSOLETE FUNCTION, checking boolean after obsolete the experiment"
    ) or diag "Looks like this failed";

    is(
        $exp2->get_experiment_metadbdata()->get_metadata_id,
        $last_metadata_id + 2,
        "TESTING EXPERIMENT_OBSOLETE, checking metadata_id"
    ) or diag "Looks like this failed";

    $exp2->obsolete_experiment( $metadbdata, 'testing obsolete', 'REVERT' );

    is( $exp2->is_experiment_obsolete(), 0,
"TESTING REVERT EXPERIMENT_OBSOLETE FUNCTION, checking boolean after revert obsolete"
    ) or diag "Looks like this failed";

    is(
        $exp2->get_experiment_metadbdata()->get_metadata_id,
        $last_metadata_id + 3,
        "TESTING REVERT EXPERIMENT_OBSOLETE, for metadata_id"
    ) or diag "Looks like this failed";

    ## Testing die for obsolete function (TEST 40 to 42)

    throws_ok { $exp2->obsolete_experiment() }
    qr/OBSOLETE ERROR: None metadbdata/,
'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_experiment() function';

    throws_ok { $exp2->obsolete_experiment($schema) }
    qr/OBSOLETE ERROR: Metadbdata/,
'TESTING DIE ERROR when argument supplied to obsolete_experiment() is not a CXGN::Metadata::Metadbdata object';

    throws_ok { $exp2->obsolete_experiment($metadbdata) }
    qr/OBSOLETE ERROR: None obsolete note/,
'TESTING DIE ERROR when none obsolete note is supplied to obsolete_experiment() function';

    ## Testing store for modifications (TEST 43 to 46)

    $exp2->set_description('This is another test');
    $exp2->store_experiment($metadbdata);

    is(
        $exp2->get_experiment_id(),
        $last_experiment_id + 1,
        "TESTING STORE_EXPERIMENT for modifications, checking the experiment_id"
    ) or diag "Looks like this failed";
    is( $exp2->get_experiment_name(), 'exp1',
"TESTING STORE_EXPERIMENT for modifications, checking the experiment_name"
    ) or diag "Looks like this failed";
    is(
        $exp2->get_description(),
        'This is another test',
        "TESTING STORE_EXPERIMENT for modifications, checking description"
    ) or diag "Looks like this failed";

    my $obj_metadbdata2 = $exp2->get_experiment_metadbdata();
    is(
        $obj_metadbdata2->get_metadata_id(),
        $last_metadata_id + 4,
        "TESTING STORE_EXPERIMENT for modifications, checking new metadata_id"
    ) or diag "Looks like this failed";

    ## Testing new by name (TEST 47)

    my $exp3 = CXGN::GEM::Experiment->new_by_name( $schema, 'exp1' );
    is(
        $exp3->get_experiment_id(),
        $last_experiment_id + 1,
        "TESTING NEW_BY_NAME, checking experiment_id"
    ) or diag "Looks like this failed";

    ##############################################
    ## FORTH BLOCK: Experiment_Dbxref functions ##
    ##############################################

    ## Testing of the dbxref

    ## First, it need to add all the rows that the chado schema use for a dbxref

    my $new_db_id = $schema->resultset('General::Db')->new(
        {
            name        => 'dbtesting',
            description => 'this is a test for add a tool-pub relation',
            urlprefix   => 'http//.',
            url         => 'www.testingdb.com'
        }
    )->insert()->discard_changes()->get_column('db_id');

    my $new_dbxref_id1 = $schema->resultset('General::Dbxref')->new(
        {
            db_id       => $new_db_id,
            accession   => 'TESTDBACC01',
            version     => '1',
            description => 'this is a test for add a tool-pub relation',
        }
    )->insert()->discard_changes()->get_column('dbxref_id');

    my $new_dbxref_id2 = $schema->resultset('General::Dbxref')->new(
        {
            db_id       => $new_db_id,
            accession   => 'TESTDBACC02',
            version     => '1',
            description => 'this is a test for add a tool-pub relation',
        }
    )->insert()->discard_changes()->get_column('dbxref_id');

    ## Testing the die when the wrong for the row accessions get/set_geexpdesigndbxref_rows (TEST 48 to 50)

    throws_ok { $exp3->set_geexperimentdbxref_rows() }
    qr/FUNCTION PARAMETER ERROR:None geexperimentdbxref_row/,
'TESTING DIE ERROR when none data is supplied to set_geexperimentdbxref_rows() function';

    throws_ok { $exp3->set_geexperimentdbxref_rows('this is not an integer') }
    qr/SET ARGUMENT ERROR:/,
'TESTING DIE ERROR when data type supplied to set_geexperimentdbxref_rows() function is not an array reference';

    throws_ok { $exp3->set_geexperimentdbxref_rows( [ $schema, $schema ] ) }
    qr/SET ARGUMENT ERROR:/,
'TESTING DIE ERROR when the elements of the array reference supplied to set_geexperimentdbxref_rows() function are not row objects';

    ## Check set/get for dbxref (TEST 51)

    $exp3->add_dbxref($new_dbxref_id1);
    $exp3->add_dbxref(
        {
            accession => 'TESTDBACC02',
            dbxname   => 'dbtesting',
        }
    );

    my @dbxref_list             = ( $new_dbxref_id1, $new_dbxref_id2 );
    my @dbxref_id_list          = $exp3->get_dbxref_list();
    my $expected_dbxref_id_list = join( ',', sort { $a <=> $b } @dbxref_list );
    my $obtained_dbxref_id_list =
      join( ',', sort { $a <=> $b } @dbxref_id_list );

    is( $obtained_dbxref_id_list, $expected_dbxref_id_list,
        'TESTING ADD_DBXREF and GET_DBXREF_LIST, checking dbxref_id list' )
      or diag "Looks like this failed";

    ## Store function (TEST 52)

    $exp3->store_dbxref_associations($metadbdata);

    my $exp4 =
      CXGN::GEM::Experiment->new( $schema, $exp3->get_experiment_id() );

    my @dbxref_id_list2 = $exp4->get_dbxref_list();
    my $expected_dbxref_id_list2 = join( ',', sort { $a <=> $b } @dbxref_list );
    my $obtained_dbxref_id_list2 =
      join( ',', sort { $a <=> $b } @dbxref_id_list2 );

    is( $obtained_dbxref_id_list2, $expected_dbxref_id_list2,
        'TESTING STORE DBXREF ASSOCIATIONS, checking dbxref_id list' )
      or diag "Looks like this failed";

    ## Testing die for store function (TEST 53 AND 54)

    throws_ok { $exp3->store_dbxref_associations() }
    qr/STORE ERROR: None metadbdata/,
'TESTING DIE ERROR when none metadbdata object is supplied to store_dbxref_associations() function';

    throws_ok { $exp3->store_dbxref_associations($schema) }
    qr/STORE ERROR: Metadbdata supplied/,
'TESTING DIE ERROR when argument supplied to store_dbxref_associations() is not a CXGN::Metadata::Metadbdata object';

    ## Testing obsolete functions (TEST 55 to 57)

    my $m = 0;
    foreach my $dbxref_assoc (@dbxref_id_list2) {
        $m++;
        is( $exp4->is_experiment_dbxref_obsolete($dbxref_assoc), 0,
"TESTING GET_EXPERIMENT_DBXREF_METADATA AND IS_EXPERIMENT_DBXREF_OBSOLETE, checking boolean ($m)"
        ) or diag "Looks like this failed";
    }

    my %expdbxref_md1 = $exp4->get_experiment_dbxref_metadbdata();
    is(
        $expdbxref_md1{ $dbxref_id_list[1] }->get_metadata_id,
        $last_metadata_id + 1,
        "TESTING GET_EXPERIMENT_DBXREF_METADATA, checking metadata_id"
    ) or diag "Looks like this failed";

    ## TEST 58 TO 61

    $exp4->obsolete_dbxref_association( $metadbdata, 'obsolete test for dbxref',
        $dbxref_id_list[1] );
    is( $exp4->is_experiment_dbxref_obsolete( $dbxref_id_list[1] ),
        1, "TESTING OBSOLETE EXPERIMENT DBXREF ASSOCIATIONS, checking boolean" )
      or diag "Looks like this failed";

    my %expdbxref_md2 = $exp4->get_experiment_dbxref_metadbdata();
    is(
        $expdbxref_md2{ $dbxref_id_list[1] }->get_metadata_id,
        $last_metadata_id + 5,
        "TESTING OBSOLETE EXPERIMENT DBXREF FUNCTION, checking new metadata_id"
    ) or diag "Looks like this failed";

    $exp4->obsolete_dbxref_association( $metadbdata,
        'revert obsolete test for dbxref',
        $dbxref_id_list[1], 'REVERT' );
    is( $exp4->is_experiment_dbxref_obsolete( $dbxref_id_list[1] ),
        0, "TESTING OBSOLETE DBXREF ASSOCIATIONS REVERT, checking boolean" )
      or diag "Looks like this failed";

    my %expdbxref_md2o = $exp4->get_experiment_dbxref_metadbdata();
    my $expdbxref_metadata_id2 =
      $expdbxref_md2o{ $dbxref_id_list[1] }->get_metadata_id();
    is(
        $expdbxref_metadata_id2,
        $last_metadata_id + 6,
        "TESTING OBSOLETE DBXREF FUNCTION REVERT, checking new metadata_id"
    ) or diag "Looks like this failed";

    ## Checking the errors for obsolete_pub_asociation (TEST 62 TO 65)

    throws_ok { $exp4->obsolete_dbxref_association() }
    qr/OBSOLETE ERROR: None metadbdata/,
'TESTING DIE ERROR when none metadbdata object is supplied to obsolete_dbxref_association() function';

    throws_ok { $exp4->obsolete_dbxref_association($schema) }
    qr/OBSOLETE ERROR: Metadbdata/,
'TESTING DIE ERROR when argument supplied to obsolete_dbxref_association() is not a CXGN::Metadata::Metadbdata object';

    throws_ok { $exp4->obsolete_dbxref_association($metadbdata) }
    qr/OBSOLETE ERROR: None obsolete note/,
'TESTING DIE ERROR when none obsolete note is supplied to obsolete_dbxref_association() function';

    throws_ok { $exp4->obsolete_dbxref_association( $metadbdata, 'test note' ) }
    qr/OBSOLETE ERROR: None dbxref_id/,
'TESTING DIE ERROR when none dbxref_id is supplied to obsolete_dbxref_association() function';

    #########################################
    ## FIFTH BLOCK: General Store function ##
    #########################################

    ## First, check if it die correctly (TEST 66 AND 67)

    throws_ok { $exp4->store() } qr/STORE ERROR: None metadbdata/,
'TESTING DIE ERROR when none metadbdata object is supplied to store() function';

    throws_ok { $exp4->store($schema) } qr/STORE ERROR: Metadbdata supplied/,
'TESTING DIE ERROR when argument supplied to store() is not a CXGN::Metadata::Metadbdata object';

    my $exp5 = CXGN::GEM::Experiment->new($schema);
    $exp5->set_experiment_name('exp2');
    $exp5->set_experimental_design_id($expdesign_id);
    $exp5->set_replicates_nr(3);
    $exp5->set_colour_nr(2);
    $exp5->set_contact_id($creation_user_id);

    $exp5->add_dbxref($new_dbxref_id1);

    $exp5->store($metadbdata);

    ## Checking the parameters stored

    ## TEST 68 TO 69

    is(
        $exp5->get_experiment_id(),
        $last_experiment_id + 2,
        "TESTING GENERAL STORE FUNCTION, checking experiment_id"
    ) or diag "Looks like this failed";

    my @dbxref_list3 = $exp5->get_dbxref_list();
    is( $dbxref_list3[0], $new_dbxref_id1,
        "TESTING GENERAL STORE FUNCTION, checking dbxref_id" )
      or diag "Looks like this failed";

    #################################################################
    ## SIXTH BLOCK: Functions that interact with other GEM objects ##
    #################################################################

    ## To test get_experimental_design it doesn't need create any expdesign (this was done in the begining of the script )

    ## Testing experimental_design object (TEST 70 and 71)

    my $expdesign2 = $exp5->get_experimental_design();

    is(
        ref($expdesign2),
        'CXGN::GEM::ExperimentalDesign',
        "TESTING GET_EXPERIMENTAL_DESIGN function, testing object reference"
    ) or diag "Looks like this failed";
    is( $expdesign2->get_experimental_design_name(), 'experimental_design_test',
"TESTING GET_EXPERIMENTAL_DESIGN function, testing experimental_design_name"
    ) or diag "Looks like this failed";

    ## Testing target objects

    ## First it will create a two Experiment object and store its data (TEST 72 to 75)

    my @target_names = ( 'target_test1', 'target_test2' );

    foreach my $target_name (@target_names) {
        my $target = CXGN::GEM::Target->new($schema);
        $target->set_target_name($target_name);
        $target->set_experiment_id( $last_experiment_id + 1 );

        $target->store($metadbdata);
    }

    my $exp6 = CXGN::GEM::Experiment->new( $schema, $last_experiment_id + 1 );

    ## Now test the get_experiment_list function

    my @targets = $exp6->get_target_list();
    my $o       = 0;

    foreach my $targ (@targets) {
        my $t = $o + 1;
        is( ref($targ), 'CXGN::GEM::Target',
            "TESTING GET_TARGET_LIST function, testing object reference ($t)" )
          or diag "Looks like this failed";
        is( $targ->get_target_name(),
            $target_names[$o],
            "TESTING GET_TARGET_LIST function, testing target_names ($t)" )
          or diag "Looks like this failed";
        $o++;
    }

};    ## End of the eval function

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

## This test does not set the table sequences anymore (method is deprecated)

####
1;    #
####
