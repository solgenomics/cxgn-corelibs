#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use FindBin;
use File::Spec::Functions qw/ tmpdir catdir catfile /;
use File::Temp qw/tempfile tempdir/;
use Storable qw/retrieve/;
use File::Slurp qw/slurp/;
use POSIX qw/:sys_wait_h/;
use IO::Pipe;
use Path::Class;

use Test::More qw| no_plan |;

BEGIN { use_ok( 'CXGN::Tools::Run' ) };

my $ctr;
my $run = eval {
    $ctr = CXGN::Tools::Run->new();
    $ctr->run('cd thereisnodirectoryhere');
};
ok( $@, 'failed commands throw an error');
diag $ctr->out if $run;

eval {
    my $ctr = CXGN::Tools::Run->new({ raise_error => 0 });
    $ctr->run('cd thereisnodirectoryhere', { raise_error => 0 });
};
ok(! $@, 'turning off raise_error disables error throwing');

my $uptime_out;
{
    my $ctr = CXGN::Tools::Run->new();
    my $uptime = $ctr->run('uptime');
    ok( -f $uptime->out_file, 'uptime out_file is present');
    is($uptime->is_async,0, 'is_async method is present, uptime run is synchronous');
    
    $uptime_out = $uptime->out_file;
    like($uptime->out,qr/up\s+\d+.+load\s+average/i,'uptime output looks plausible');
    unlike($uptime->err,qr/./,'uptime stderr output empty');
    
    my $ctr2 = CXGN::Tools::Run->new();
    $ctr2->run(qw/echo hunka hunka burnin love/);
    is( $ctr2->out, "hunka hunka burnin love\n", 'silly output OK');
    is( $ctr2->err, '', 'silly err is empty');
    #example uptime output: 16:18:27 up 48 days, 23:24,  7 users,  load average: 0.77, 0.43, 0.21
    
    #diag 'uptime printed: '.$uptime->out;
    ok( -f $uptime->out_file, 'uptime out_file is still present');
    ok( -f $uptime->err_file, 'uptime err_file is present');
    
}

 SKIP: {
     skip 'debug flag is turned on',1 if $ENV{CXGNTOOLSRUNDEBUG};
     ok(! -f $uptime_out , 'uptime out_file is gone');
}

#test passing a shell command
my $tempdir = tempdir(catdir(tmpdir(),'cxgn-tools-run-t-XXXXXXXX'),CLEANUP=>0);

my $complete_hook = 0;
my $ctr3 = CXGN::Tools::Run->new({ temp_base => $tempdir,
				   on_completion => " \$complete_hook += 42 ",
				 });

print STDERR "OC: ".$ctr3->on_completion()."\n";
my $string = $ctr3->on_completion();
eval($string);
if ($@) { print "ERROR: $@\n"; }
print STDERR "COMPLETE HOOK: $complete_hook\n";


$ctr3->run('echo monkeys on the top of the mountain > foo.out');
my @files = glob "$tempdir/*";

is(slurp(File::Spec->catfile($ctr3->job_tempdir(),'foo.out')),
   "monkeys on the top of the mountain\n",
   'passing a shell command works',
  );
ok( ! $run->alive, 'run should not show alive');
is( $complete_hook, 42, 'completion hook ran' );

#test in_file options for passing things through stdin
my $stdin_text = "these are the times that try men's souls";
my ($in_fh, $in_file) = tempfile("test-in-file-XXXXX", DIR=>"/tmp");
open(my $IN, ">", $in_file) || die "Can't open in file $in_file";
close($IN);
print STDERR "INFILE = $in_file\n";
my $ctr4 = CXGN::Tools::Run->new({ in_file => $in_file }); 
$ctr4->run('cat');
print STDERR "OUT: ".$ctr4->out."\n";
is($ctr4->out,$stdin_text,'in_file option works for sync run')
  or diag Dumper($ctr4);


print STDERR "Running test 5...\n";
my $inc;
$complete_hook = 0;
my $temp_base = tempdir( 'run-XXXXX', DIR=>'/tmp', CLEANUP=> 0);
my $ctr5 = CXGN::Tools::Run->new({ temp_base => $temp_base} );
$ctr5->run_async('sleep',3);
$inc = 0;
while($ctr5->alive && $inc < 6) {
  ++$inc;
  #diag "sleeping ",$inc;
  sleep 1;
}
ok($inc == 2 || $inc == 3 || $inc == 4,'background sleep is reported alive for about 3 seconds')
  or diag "\$inc actually was: $inc";
ok($ctr5->is_async,'first sleeper call is reported as asynchronous');
$tempdir = $ctr5->temp_base();
ok($ctr5->cleanup,'cleaned up first sleeper');
ok(! -d $tempdir,'first sleeper temp dir is gone');


print STDERR "Running test 6...\n";
#test an async process that dies
{ my $failer;
  my $completion_hook = 42;
  print STDERR "Check async process that dies...\n";
  eval {
      my $ctr6 = CXGN::Tools::Run->new({ on_completion => "sub { \$completion_hook += 3 }" });
      print STDERR "Created CXGN::Tools::Run...\n";
      $failer = $ctr6->run_async(qq|perl -e 'die "oh crap I died."'|);
      print STDERR "Wait...\n";
      $ctr6->wait if $failer;
      print STDERR "Done waiting...\n";
  };
  print STDERR "check die\n";
  ok( $@, 'async processes propagate dies');
  print STDERR "ERROR STRING = $@\n";
  like( $@, qr/oh crap I died/,'die message propagated');
  is( $completion_hook, 42, 'completion hook did not run for failed process' );

  print STDERR "Running test 7...\n";
  #test turning off error raising
  eval {
      my $ctr7 = CXGN::Tools::Run->new({ raise_error => 0 });
      $failer = $ctr7->run_async(qq|perl -e 'die "oh crap I died.\n"'|);
      $failer->wait if $failer;
  };
  is($@, '', 'async processes do not propagate dies if raise_error is off');
  ok( $failer, 'still got a job object if raise_error is off' );
  like($failer->err,qr/oh crap I died/,'die message was on stderr');
  like($failer->error_string,qr/oh crap I died./,'die message was correctly recorded in error string');
}

#test handing a background process from program to program
#async_2.aux starts a background process, then stores its object
#to a file.  we read it back from that file and test that
#we can work with it
print STDERR "CONTINUING...\n";
my $filename;
 my $time_before_run = time;
# CXGN::Tools::Run::Run3::run3("$FindBin::Bin/async_2.aux",\undef,\$filename);
# #($filename) = `$FindBin::Bin/async_2.t`;
# #system "$FindBin::Bin/async_2.t";
 my $time_after_run  = time;
# chomp $filename;
# ok(-r $filename,'background process file')
#   or diag "frozen process handle filename was: $filename";

# print STDERR "MORE...\n";
# my $sleeper2 = eval{ retrieve($filename) };
# unlink $filename or die "Could not unlink $filename: $!";
# isa_ok($sleeper2,'CXGN::Tools::Run','thawed process handle');
# my $pid = $sleeper2->pid;
# ok($pid,"pid function is present ($pid)");
# $inc = 0;
# while($sleeper2->alive && $inc < 3) {
#   $inc++;
#   #diag "sleeping ",$inc;
#   sleep 1;
# }
# system("pstree -p | grep sleep") if $ENV{CXGNTOOLSRUNDEBUG};
# ok($sleeper2->die,'killed child process'); #kill the sleeper
# sleep 3; #give the killed child a chance to die and disappear, might take a while if the system is under heavy load
# system("pstree -p | grep sleep") if $ENV{CXGNTOOLSRUNDEBUG};
# ok(! `ps aux | grep 'sleep 30' | grep -v grep`,'child process is really dead')
#   or system("pstree -p | grep sleep | grep -v grep");
# my $time_after_dead = time;
# is($inc,3,'handoff background process from program to program');

# #check that start and end times are present and reasonable
# cmp_ok($sleeper2->start_time,'>=',$time_before_run,'sane start time 1');
# cmp_ok($sleeper2->start_time,'<=',$time_after_run,'sane start time 2');
# cmp_ok($sleeper2->end_time,'>=',$time_after_run,'sane end time 1');
# cmp_ok($sleeper2->end_time,'<=',$time_after_dead,'sane end time 2');

# $tempdir = $sleeper2->tempdir;
# ok($sleeper2->cleanup,'cleaned up second sleeper');
# ok(! -d $tempdir,'second sleeper temp dir is gone');

print STDERR "Running test 8...\n";
#now test synchronous running
$time_before_run = time;
my $ctr8 = CXGN::Tools::Run->new();
my $sleeper3 = $ctr8->run('sleep',2);
$time_after_run = time;
cmp_ok($time_after_run - $time_before_run, '>=', 2, 'synchronous run');

#test exit status
isnt($sleeper3->exit_status,undef,'exit_status is present and defined');
is($sleeper3->exit_status >> 8,0,'exit status was 0');

#test out and err files
my $echostring = 'monkeys in the bushes';
my $ctr9 = CXGN::Tools::Run->new();
my $echoer = $ctr9->run('echo','-n',$echostring);
is($echoer->out,$echostring,'out() function');

my $ctr10 = CXGN::Tools::Run->new();

my $cder = $ctr10->run('perl','-e','print STDERR "bleh"');

is($cder->err,'bleh','err() function');

#now test forking with tempfiles

my $testtemp = tempdir(CLEANUP=>1);
system("echo foo foo foo > $testtemp/foo");
my $completion_hook = 0;
my $ctr11 = CXGN::Tools::Run->new({ tempdir => $testtemp, on_completion => "\$completion_hook += 42" });
my $tempy = $ctr11->run_async('cat',file($testtemp,'foo'));
$tempy->wait;
$tempy->alive for 1..10;
is($tempy->out,"foo foo foo\n",'tempdir out 1');
is($completion_hook, 42, 'completion hook ran once');
$tempdir = $tempy->job_tempdir;
ok($tempy->cleanup,'cleaned up first tempy');
ok(! -d $tempdir,'temp dir is gone');

print STDERR "Running test 12...\n";
my $ctr12 = CXGN::Tools::Run->new();
my $tempy2 = $ctr12->run_async('cat',"$testtemp/foo");
$tempy2->wait;
is($tempy2->out,"foo foo foo\n",'tempdir out 2');
$tempdir = $tempy2->job_tempdir();
ok($tempy2->cleanup,'cleaned up second tempy');
ok(! -d $tempdir,'temp dir is gone');

#test running processes in different working dirs
# my $ctr13 = CXGN::Tools::Run->new();
# my $workie1 = $ctr13->run_async('cat','foo', { working_dir => $testtemp });
# $workie1->wait;
# is($workie1->out,"foo foo foo\n",'asynchronous run with different working dir');
# $workie1->cleanup;

#test using IO::Pipes between them
SKIP: {
  skip 'IO::Pipe support not yet working',1;

  my $pipe = IO::Pipe->new;
      
  my $piper1 = CXGN::Tools::Run->new({ working_dir => $testtemp, out_file => $pipe });
      
  my $piper2 = CXGN::Tools::Run->new({ in_file => $pipe });
  $piper1->run_async('cat','foo');
  $piper2->run_async('cat');
  $piper1->wait;
  $piper2->wait;
  is($piper2->out,"foo foo foo\n",'asynchronous runs with pipes between them');
  $piper1->cleanup;
  $piper2->cleanup;
}

# my $ctr14 = CXGN::Tools::Run->new({ working_dir => $testtemp });
# $ctr14->run('cat','foo');
# is($ctr14->out,"foo foo foo\n",'synchronous run with different working dir');

print STDERR "Running test 15...\n";
#test running multiple processes, then killing the parent of that
my $tester_pid = fork;
defined $tester_pid or die "Couldn't fork";
unless($tester_pid) {
  #create a long-running sleeper
  eval {
      my $ctr15 = CXGN::Tools::Run->new();
    my $s1 = $ctr15->run('sleep',57)
      or die "i can't sleep: $!";
  }; if( $@ ) {
    die $@ unless $@ =~ /Got signal SIGTERM/;
  }
  exit(-1);
}
sleep 2;
kill SIGTERM => $tester_pid
  or die "Could not kill $tester_pid";
sleep 1;
(my $wres = waitpid($tester_pid,WNOHANG)) > 0
  or die "waitpid($tester_pid,0) failed";

ok( $wres == $tester_pid, 'forked tester died');
is( $?>>8, 255, 'forked tester died with -1');
my @psoutput = `ps aux | grep 'sleep 57' | grep -v grep`;
ok(! @psoutput,'children of forked tester also died')
  or diag @psoutput;


# #test the existing_temp option
# my $newtemp = tempdir('cxgn-tools-run-t-XXXXXXXX',CLEANUP=>1);
# my $run3 = CXGN::Tools::Run->new({ existing_temp => $newtemp });
# $run3->run( echo => 'monkeys in my drawers!');
# my $expected_outfile = File::Spec->catfile($newtemp,'out');
# ok( -f $expected_outfile, 'outfile in existing_temp exists');
# is($run3->_file_contents($expected_outfile), "monkeys in my drawers!\n",
#    'outfile in existing_temp contains the right stuff');

print STDERR "Last test...\n";

{
  my $comp = 42;
  my $ctr16 = CXGN::Tools::Run->new({ on_completion => "sub { \$comp += 3 }" });
  my $sleeper3 = $ctr16->run_async('sleep', 10);
  ok( $sleeper3->alive, 'long-running async process is alive');
  ok( $sleeper3->pid, 'got a pid for it' );
  ok( $sleeper3->alive, 'child alive');
  ok( $sleeper3->die, 'killed child process');
  ok( ! $sleeper3->alive, 'child is not alive');
  is( $comp, 42, 'completion function does not run for a killed async process' );
}

done_testing();

print STDERR "Testing Done!!!\n";
