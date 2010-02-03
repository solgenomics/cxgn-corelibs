#!/usr/bin/perl
use strict;
use warnings;
use English;
use FindBin;

use Bio::SeqIO;

use File::Spec::Functions;
use File::Temp qw/ tempdir tempfile /;

use Fatal qw/ open mkdir chmod /;

use Test::More;
BEGIN {
    if( `which fastacmd` ) {
        plan tests => 293;
    }
    else {
        plan skip_all => 'fastacmd is not installed, required to test CXGN::BlastDB::FileSet';
    }
}

use Test::Warn;

my  $DATADIR = catdir( $FindBin::RealBin, '..','data');
-d $DATADIR or die "missing data dir $DATADIR";

BEGIN {
    use_ok(  'CXGN::BlastDB::FileSet'  )
        or BAIL_OUT('could not include the module being tested');
}


my $tempdir = tempdir( CLEANUP => 1);


###  test die cases
eval {
    CXGN::BlastDB::FileSet->open( full_file_basename => catfile( $tempdir, 'testy', 'blowup' ),
                                  type => 'protein',
                                  write => 1,
                                 );
};
like( $@, qr/create_dirs must be set/, 'creation in nonexistent dir without create flag dies' );

my $intheway;
my @t = (['nin','nucleotide'], ['pin','protein']);
for my $t ( \@t, [reverse @t] ) {
    $intheway = catfile( $tempdir, 'fooey.'.$t->[0][0] );
    my $fs = CXGN::BlastDB::FileSet->open( full_file_basename => catfile( $tempdir, 'fooey' ),
                                            write => 1,
                                            type => $t->[1][1],
                                          );
    ok( $fs, 'write-open succeeds even if existing files are present for a different db type' );
    ok( ! $fs->is_split, 'returns false for is_split');

    unlink $intheway;
}


foreach my $type ('nucleotide','protein') {

    my $test_seq_file = catfile( $DATADIR, "blastdb_test.$type.seq" );

    ### test new creation
    my $test_ffbn = catfile( $tempdir, "testdb_$type" );
    my $fs = CXGN::BlastDB::FileSet->open( full_file_basename => $test_ffbn,
                                           type => $type,
                                           write => 1,
                                         );
    is( scalar $fs->list_files, 0, 'new db does not have any files' );
    ok( !$fs->format_time, 'format_time returns nothing for no files');
    ok( !$fs->files_are_complete, 'files_are_complete returns false for empty DB');
    ok( !$fs->is_split, 'returns false for is_split');

    is( $fs->type, $type, 'correct initial type');

    ### test formatting from file
    foreach my $index (0,1) {

        my $st = time;
        unlink $fs->list_files;

        ok(! $fs->check_format_permissions, 'check_format_permissions should be OK' );

        my $test_title = "test title,dflgksjdf;\nholycow";
        $fs->format_from_file( seqfile => $test_seq_file,
                               title => $test_title,
                               indexed_seqs => $index,
                             );
        my $et = time;

        is( scalar $fs->list_files, ($index ? 5 : 3), 'newly formatted db has the right number of files' )
            or diag "actual files:\n",map "  $_\n",$fs->list_files;

        is( $fs->title, $test_title, 'got correct title' );

        my $ftime = $fs->format_time;
        # do times within 60 seconds because format_time only has
        # resolution of nearest minute
        cmp_ok( $ftime, '>=', $st-60, 'format time reasonable 1');
        cmp_ok( $ftime, '<=', $et+60, 'format time reasonable 2');

        my $mtime = $fs->file_modtime;
        cmp_ok( $mtime, '>=', $st-1, 'modtime reasonable 1');
        cmp_ok( $mtime, '<=', $et+1, 'modtime reasonable 2');

        is( $fs->title, $test_title, 'got correct title' );

        ok( $fs->files_are_complete, 'files read as complete' );

        ok( ! $fs->is_split, 'returns false for is_split');

        #try to fake a split db
        my $c = 0;
        my @fake_split = map { s/\./sprintf('.%02d.',++$c)/e; $_ } $fs->list_files;
        open my $f, '>', $_ foreach @fake_split;

        ok( $fs->is_split, 'faked out is_split' )
            or diag "faked files:\n", map "  $_\n", $fs->list_files;

        unlink @fake_split;
    }

    ok( ! defined $fs->get_sequence('this is nonexistent ya ya ya'), 'get_sequence returns undef for nonexistent sequence' );

    # $fs should be indexed now, test get_sequence
    my $seqio = Bio::SeqIO->new( -file => $test_seq_file, -format => 'fasta');
    my $test_seq_count = 0;
    while ( my $one = $seqio->next_seq ) {
        my $d = $one->desc; $d =~ s/\s+$//; $one->desc($d); #< strip whitespace from bioperl's defline, because fastacmd strips it
        same_seqs( $fs->get_sequence($one->id), $one );
        $test_seq_count++;
    }

    is( $fs->sequences_count, $test_seq_count, 'sequences_count looks right' );


    ### test opening
    my $fs2 = CXGN::BlastDB::FileSet->open( full_file_basename => catfile( $DATADIR, "blastdb_test.$type" ) );
    ok( $fs2, 'db open succeeded' );
    is( $fs2->sequences_count, $test_seq_count, 'sequences count of opened database looks right' );
    ok( !$fs2->write, 'write is NOT set on an opened database' );

    ok( $fs2->files_are_complete, 'newly opened db shows files complete');
    is( $fs2->type, $type, 'got right type for opened db');
    ok( ! $fs2->is_split, 'returns false for is_split');

    # get_sequence should die since test db not indexed
    eval { $fs2->get_sequence('whatever') };
    like $@, qr/not.+indexed/i, 'get_sequence dies if db not indexed';

    # test to_fasta
    my $from_db = Bio::SeqIO->new( -fh => $fs2->to_fasta, -format => 'fasta' );
    my $from_file = Bio::SeqIO->new( -file => $test_seq_file, -format => 'fasta' );
    while ( my $db = $from_db->next_seq ) {
        my $bpseq = $from_file->next_seq;
        my $d = $bpseq->desc; $d =~ s/\s+$//; $bpseq->desc($d); #< strip whitespace from bioperl's defline, because fastacmd strips it
        same_seqs( $bpseq, $db );
    }
}

# compares two Bio::PrimarySeqI objects - 5 tests
sub same_seqs {
    my ($one, $two) = @_;
    isa_ok( $one, 'Bio::PrimarySeqI', 'seq object one' );
    isa_ok( $two, 'Bio::PrimarySeqI', 'seq object two' );
    is( $one->id, $two->id, $one->id.' id OK');
    is( $one->seq, $two->seq, $one->id.' seq OK');
    is( $one->description, $two->description, $one->id.' desc OK');
}

# test check_format_permissions
my $permdir = catdir( $tempdir, 'permdir' );
mkdir $permdir;
my $fs3 = CXGN::BlastDB::FileSet->open( full_file_basename => catfile( $permdir, 'foo'), write => 1);
ok(! $fs3->check_format_permissions, 'check_format_permissions OK for ffbn in new dir' );
ok( ! $fs3->is_split, 'returns false for is_split');
chmod 0444,$permdir;
my $perr = $fs3->check_format_permissions;
ok($perr, 'check_format_permissions returns bad for ffbn in non-writable' );
like( $perr, qr/directory/i, 'permissions error mentions directory');
eval { CXGN::BlastDB::FileSet->open( full_file_basename => catfile( $permdir, 'foo' ),
                                     write => 1,
                                   );
   };
like($@, qr/writable/, 'new() should die if ffbn is not writable');
chmod 0744,$permdir;
ok(! $fs3->check_format_permissions, 'check_format_permissions OK again' );

my $test_seq_file = catfile( $DATADIR, "blastdb_test.nucleotide.seq" );
$fs3->format_from_file( seqfile => $test_seq_file );
my @newfiles = $fs3->list_files;
is( scalar @newfiles, 3, 'format succeeded in new dir' );
ok(! $fs3->check_format_permissions, 'check_format_permissions still OK after new format' );
foreach my $f (@newfiles) {
    chmod 0444,$f;
    my $perr2 = $fs3->check_format_permissions;
    like( $perr2, qr/$f/, 'perm error mentions file');
}
chmod 0744, $_ for @newfiles;
ok(! $fs3->check_format_permissions, 'and then it comes back OK after all are writable again' );


#test downloading and formatting NR
SKIP: {
  my $big_file = $ENV{CXGN_BLASTDB_FILESET_TEST_BIG_FORMAT}
    or skip 'set CXGN_BLASTDB_FILESET_TEST_BIG_FORMAT=(file path) to test formatting a really big protein database.  note that this test can take an hour or more to run.',3;

  -f $big_file or die "file '$big_file' does not exist";
  -r $big_file or die "file '$big_file' not readable";
  my $size = -s $big_file;
  $size >= 1_000_000_000 or die "file '$big_file' is only '$size' bytes, not big enough for this test";

  my $seq_cnt = `grep '^>' $big_file | wc -l`;
  chomp $seq_cnt;
  $seq_cnt+0 > 0 or die "'$big_file' does not look like a fasta file to me";

  my $fs = CXGN::BlastDB::FileSet->open( full_file_basename => catfile($tempdir, 'big_format'),
					 write => 1,
					 type => 'protein',
				       );

  $fs->format_from_file(seqfile => $big_file, title => 'my crazy title');

  is( $fs->title, 'my crazy title' );
  my @files = $fs->list_files;
  ok( (grep /\.\d{2}\./, @files), 'looks like big formatted db is split' );
  is( $fs->sequences_count, $seq_cnt, 'sequences count looks right' );
}
