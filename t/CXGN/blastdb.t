#!/usr/bin/perl

use strict;
use warnings;
use English;
use FindBin;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Copy;
use File::Path;
use File::Basename;

use Test::More;

use Bio::SeqIO;

use CXGN::DB::Connection;
use CXGN::BlastDB;

use List::MoreUtils qw/all/;
use CXGN::Publish qw/copy_or_print/;

BEGIN {
    eval { CXGN::BlastDB->retrieve_all };
    if ($@ =~ m/DBI connect/) {
        plan skip_all => "Could not connect to database";
    } else {
        plan tests => 52;
    }
}
BEGIN { use_ok('CXGN::BlastDB'); }


#get some dbs
my @dbs = CXGN::BlastDB->retrieve_all;
ok(@dbs > 0,'retrieve_all command exists, got some dbs');

my @uni = CXGN::BlastDB->search_ilike(title => '%univec%core');
ok(@uni == 1, 'exactly one univec core blast db registered');

ok( (all { $_->list_files && 1 || 0 } @dbs),
    'all databases exist on disk');

ok( (all {my $c = $_->sequences_count; defined($c) && $c > 0} @dbs),
    'all databases have more than zero sequences in them');

#test needs_update
my @update_results = map {
  my $u = $_->needs_update;
  #diag $_->file_base.' '.($u ? 'needs' : 'does NOT need')." updating\n";
  $u
} @dbs;

ok( (all { $_ == 0 || $_ == 1 } @update_results),
    'needs_update returns valid values',
  );

#test list_files
ok( (all { map {-f} $_->list_files } @dbs ),
    'list_files only returns files that actually exist',
  );

#test format_from_file
my $testseqs = File::Spec->catfile($FindBin::Bin,'data','blastdb_test.nucleotide.seq');
my $tempdir = tempdir(CLEANUP=>1);
my $test_ffbn = File::Spec->catfile($tempdir,'test-cxgn-blastdb');
my ($tester) = grep $_->index_seqs, @dbs;
$tester or BAIL_OUT('cannot find any dbs with index_seqs set!');
my $old_dbpath = CXGN::BlastDB->dbpath;
CXGN::BlastDB->dbpath($tempdir);
my $st = time;
$tester->format_from_file($testseqs);
my $et = time;
ok( $tester->files_are_complete, 'format_from_file made test blast db ok' );
ok( $tester->is_indexed, 'tester should be marked as indexed on disk');
#diag "new testing copy has files:\n", map {"$_\n"} $tester->list_files;
#test format_time
cmp_ok($st,'<=',$tester->format_time+60,'format_time reasonable 1');
cmp_ok($et,'>=', $tester->format_time-60,'format_time reasonable 2');
cmp_ok($tester->format_time,'>',0,'format_time is not too small');

#test to_fasta
my $tester_seqs = Bio::SeqIO->new( -fh => $tester->to_fasta, -format => 'fasta');
my $orig_seqs = Bio::SeqIO->new(-file => $testseqs, -format => 'fasta');
while(my $tseq = $tester_seqs->next_seq) {
  my $oseq = $orig_seqs->next_seq
    or last;
  same_seqs( $tseq, $oseq );
  same_seqs( $oseq, $tester->get_sequence( $oseq->id ) );
};
ok(! $orig_seqs->next_seq, "not more sequences in original than in tester filehandle");
CXGN::BlastDB->dbpath($old_dbpath);

#test is_split
my ($nr) = CXGN::BlastDB->search_like( file_base => '%nr' );
isa_ok($nr,'CXGN::BlastDB');
ok( $nr->is_split, 'nr is correctly detected as being split' );
my ($uv) = @uni;
isa_ok($uv,'CXGN::BlastDB');
ok(! $uv->is_split, 'univec is correctly detected as being NOT split' );

#test files_are_complete
ok( $nr->files_are_complete, 'nr has a complete set of files' );
ok( $uv->files_are_complete, 'univec has a complete set of files' );
#copy univec somewhere
my $copydest = File::Spec->catdir( $tempdir, (fileparse($uv->file_base))[1]);
foreach ( $uv->list_files ) {
  -d $copydest or mkpath([$copydest]) or die "could not make path $copydest";
  copy_or_print($_,$copydest) or die "could not copy $_ to $tempdir: $!";
}
CXGN::BlastDB->dbpath( $tempdir );
ok( $uv->files_are_complete, 'copied univec has a complete set of files');
#now delete a file and see if it notices
if( my $goner = ($uv->list_files)[0] ) {
  unlink $goner or die "could not delete '$goner': $!";
}
ok( ! $uv->files_are_complete, 'deleted blast db file was noticed');

#test identifier_url
like( $nr->identifier_url('foo'), qr/ncbi.nlm.nih.gov.+foo/, 'identifier_url works' );

# compares two Bio::PrimarySeqI objects - 5 tests
sub same_seqs {
    my ($one, $two) = @_;
    isa_ok( $one, 'Bio::PrimarySeqI', 'seq object one' );
    isa_ok( $two, 'Bio::PrimarySeqI', 'seq object two' );
    is( $two->id, $one->id, $one->id.' id OK');
    is( $two->seq, $one->seq, $one->id.' seq OK');
    is( $two->description, $one->description, $one->id.' desc OK');
}
