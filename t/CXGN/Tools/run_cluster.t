use strict;
use warnings;
use English;
use Test::More;

use File::Temp qw/ tempfile /;

use CXGN::Tools::File qw/ file_contents /;

BEGIN {
    if( $ENV{CXGNTOOLSRUNTESTCLUSTER} ) {
        plan tests => 23;
    }
    else {
        plan skip_all => 'cluster job tests skipped by default, set environment var CXGNTOOLSRUNTESTCLUSTER=1 to test';
    }

    use_ok('CXGN::Tools::Run');
}

my @nodes = defined $ENV{FORCE_TORQUE_NODE} ? (nodes => $ENV{FORCE_TORQUE_NODE}) : ();

my $complete_hook = 0;
my $cjob = CXGN::Tools::Run->run_cluster( perl => -e => 'sleep 1; print "foofoofoo\n"',
                                         {
                                          working_dir => '/data/shared',
                                          @nodes,
                                          temp_base => '/data/shared/tmp',
					  vmem => 400,
                                          on_completion => sub { $complete_hook += 42 },
					  max_cluster_jobs => 1_000_000,
                                         });
isa_ok($cjob,'CXGN::Tools::Run');
ok($cjob->alive,'cluster sleep job must be alive, waiting for it to finish...');
sleep 10;
ok(! $cjob->alive,'cluster job is now dead');
ok(! $cjob->alive,'cluster job still dead');
ok(! $cjob->alive,'cluster job is still quite dead');
is($cjob->out,"foofoofoo\n",'got correct cluster job standard output');
is($cjob->err,'','got correct cluster job error output');
is($complete_hook, 42,'completion hook ran once');
$cjob->cleanup;

CXGN::Tools::Run->temp_base('/data/shared/tmp');

#now test that we can kill cluster jobs
$complete_hook = 0;
is( $complete_hook, 0);
$cjob = CXGN::Tools::Run->run_cluster( sleep => 300,
                                       { @nodes,
                                         working_dir => '/data/shared/tmp',
                                         on_completion => sub { $complete_hook = 'should not run!' },
                                       }
                                     );
is( $complete_hook, 0, 'completion hook did not run yet');
ok($cjob->alive,'second cluster sleep job is alive');
is($cjob->die,1,'second cluster job die request returned 1');
ok(! $cjob->alive, 'second cluster sleep job is actually dead');
like($cjob->job_id,qr/^\d+(\.\w+)+$/,'job id ('.$cjob->job_id.') looks right');
is( $complete_hook, 0, 'completion hook never ran');
$cjob->cleanup;

#test cluster jobs with different working directories
$cjob = CXGN::Tools::Run->run_cluster("echo barbarbar > foo.out",{@nodes, working_dir => '/data/shared/tmp'});
$cjob->wait;
is(file_contents("/data/shared/tmp/foo.out"),"barbarbar\n",'correct contents of test file');
unlink "/data/shared/tmp/foo.out";
$cjob->cleanup;

#test cluster jobs that die
my (undef,$tempfile) = tempfile('/data/shared/tmp/cxgn-tools-run-XXXXXXXX',UNLINK=>1);
eval {
    $cjob = CXGN::Tools::Run->run_cluster(qq|perl -e 'print "foo\\n"; exit 123;'|,
					  { working_dir => '/data/shared/tmp',
					    out_file => $tempfile,
					    vmem => 400,
                                            @nodes,
                                            on_completion => sub { $complete_hook = 'should not run if job died' },
					  }
					 );
    $cjob->wait;
};
is( $complete_hook, 0, 'on_completion hook did not run' );
ok($EVAL_ERROR,'cluster job dies propagate to calling host')
    or diag "error was: $EVAL_ERROR";
is($cjob->exit_status >>8 ,123,'cluster job error exit status is correct')
    or diag "error was: $EVAL_ERROR";
like($cjob->err,qr/command failed/,'cluster job stderr is correct');
is($cjob->out,"foo\n",'cluster job stdout is correct');
is(file_contents($tempfile),"foo\n",'cluster job wrote to the correct file');
$cjob->cleanup;


