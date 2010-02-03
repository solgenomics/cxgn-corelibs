#!/usr/bin/env perl
use strict;
use warnings;
use English;

use Test::More tests => 34;
use Test::Exception;

use File::Temp;

use List::MoreUtils qw/ all /;

use CXGN::Genomic::Clone;
use CXGN::Publish;

use Data::Dumper;

BEGIN {
  use_ok(  'CXGN::PotatoGenome::FileRepository'  )
    or BAIL_OUT('could not include the module being tested');
}

my $test_dir =  File::Temp->newdir;

my $repos_dir_1 = "$test_dir/test1";

my $repos = CXGN::PotatoGenome::FileRepository->new( basedir => $repos_dir_1,
                                                     create  => 1,
                                                   );
isa_ok( $repos, 'CXGN::PotatoGenome::FileRepository' );

{  my $file = $repos->get_vf( class => 'AllCloneSequences', format => 'fasta.gz' );
   ok( ref $file, 'got an object from get_vf');
   isa_ok($file,'CXGN::FileRepository::VersionedFile');
   is( $file->current_file, undef, 'no current published version');
   is( $file->current_version, undef, 'no current version number');
}


{  my $allseqs = $repos->get_vf( class => 'AllCloneSequences', format => 'fasta.gz' );
   ok( ref $allseqs, 'got an object from allseqs get_vf');
   isa_ok( $allseqs, 'CXGN::FileRepository::VersionedFile');

   my $clone_file = $repos->get_vf( class => 'SingleCloneSequence',
                                     sequence_name => 'RH123A12.3',
                                     project => 'NL',
                                     format => 'fasta',
                                   );
   isa_ok( $clone_file, 'CXGN::FileRepository::VersionedFile');
   is( $clone_file->current_file, undef, 'no current clone seq file');

   my $tempfile = File::Temp->new;
   $tempfile->print("this is some test output\n");
   $tempfile->close;

   my $tempfile2 = File::Temp->new;
   $tempfile2->print("this is some other test output\n");
   $tempfile2->close;

   $repos->publish(  $allseqs->publish_new_version( $tempfile ),
                     $clone_file->publish_new_version( $tempfile2 ),
                  );

   #system find => $repos_dir_1;

   # now look up the clone seq file again
   ($clone_file) = my @results = $repos->search_vfs( class => 'SingleCloneSequence',
                                                     sequence_name => 'RH123A12.3',
                                                   );
   is( scalar(@results), 1, 'got one search result for clone file');
   isa_ok( $clone_file, 'CXGN::FileRepository::VersionedFile');
   isa_ok( $clone_file->current_file, 'Path::Class::File', 'current_file')
       or diag Dumper $clone_file;

}

{
    my $allseqs = $repos->get_file( class => 'AllCloneSequences', format => 'fasta.gz' );
    ok( ref $allseqs, 'got an object from allseqs find_file');
    ok( -f $allseqs, 'got the allseqs file' );

    dies_ok {
        $repos->get_file( class => 'SingleCloneSequence',
                          sequence_name => 'RH123A12.3',
                        );
    }, 'dies on non-unique search conditions';
    my $clone_file = $repos->get_file( class => 'SingleCloneSequence',
                                       sequence_name => 'RH123A12.3',
                                       project => 'NL',
                                       format => 'fasta',
                                     );

    isa_ok( $clone_file, 'Path::Class::File');
    ok( -f "$clone_file", 'got the clone file from find_file');
    is( $clone_file->basename, 'RH123A12.3.v1.fasta', 'got current clone seq file');
}

{ # generate and publish a few more potato clone sequences

    my @test_cloneseqs = (
                           { sequence_name => 'RH222A14.53',
                             project => 'JP',
                           },
                           { sequence_name => 'RH111A01.53',
                             project => 'NL',
                           },
                           { sequence_name => 'RH333C14.53',
                             project => 'ES',
                           },
                           { sequence_name => 'RH555F02.53',
                             project => 'CC',
                           },
                           { sequence_name => 'RH444A01.53',
                             project => 'XD',
                           },
                         );
    # publish a bunch more clone seqs
    my @tempfiles_scope; #< put tempfiles in here to keep them around until publish
    $repos->publish( map {
        my $rec = $_;
        my $clone_file = $repos->get_vf( class => 'SingleCloneSequence',
                                         format => 'fasta',
                                         %$rec
                                       );
        isa_ok( $clone_file, 'CXGN::FileRepository::VersionedFile');
        is( $clone_file->current_file, undef, 'no current clone seq file');
        my $tempfile = File::Temp->new;
        $tempfile->print(rand()."\n");
        $tempfile->close;
        push @tempfiles_scope, $tempfile;
        $clone_file->publish_new_version( "$tempfile" );
    } @test_cloneseqs
   );

    # now search for the clone seq files and make sure we get the right number
    my @all_clone_seqs = $repos->search_files( class => 'SingleCloneSequence' );
    is( scalar(@all_clone_seqs), scalar(@test_cloneseqs)+1, 'got the right number of clone seqs from the search');
    ok( (all {$_->isa('Path::Class::File')} @all_clone_seqs), 'all the clone seq files are Path::Class::File objects' );
    ok( (all {-f "$_"} @all_clone_seqs), 'all the clone seq files exist' );

    # search by a specific clone object
    my $clone = CXGN::Genomic::Clone->retrieve_from_clone_name('RH111A01.53');
    my ($vf) = my @vfs = $repos->search_vfs( class => 'SingleCloneSequence',
                                  clone => $clone,
                                );
    is( scalar(@vfs), 1, 'found right number of vfs' );
    isa_ok( $vf->current_file, 'Path::Class::File', 'got currently published file' );
}

