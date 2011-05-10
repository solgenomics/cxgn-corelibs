#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use File::Temp qw/tempfile/;
use Data::Dumper;

use Test::More;

use Bio::Index::Fasta;

use CXGN::Tools::List qw/str_in/;
use IPC::Cmd qw/can_run/;

BEGIN {
  use_ok( 'CXGN::Cluster' )
    or plan skip_all => 'could not include the module being tested';

  unless( can_run('phrap.longreads') ){
    plan skip_all => 'phrap.longreads not available';
  }
}

plan tests => 19;

#now start testing with them
my $set = CXGN::Cluster::ClusterSet->new;

my @seqnames = sort qw/monkey bonobo homo orangutan chimpanzee gorilla marmoset lemur/;

$set->add_match(@seqnames[0,1]);
is_deeply( cs_contents($set),
	   [[ @seqnames[0,1] ]],
	   'one cluster with 2 members',
	 );


$set->add_match(@seqnames[0,2]);
is_deeply( cs_contents($set),
	   [[ @seqnames[0,1,2] ]],
	   'then three members',
	 );

$set->add_match(@seqnames[3,3]);
is_deeply( cs_contents($set),
	   [[ @seqnames[0,1,2] ],
	    [ $seqnames[3] ],
	   ],
	   'self-match adds an unrelated cluster',
	 );

$set->add_match(@seqnames[0,0]);
is_deeply( cs_contents($set),
	   [[ @seqnames[0,1,2] ],
	    [ $seqnames[3] ],
	   ],
	   'self-match of already present sequence does not change anything',
	 );

$set->add_match(@seqnames[1,1]);
is_deeply( cs_contents($set),
	   [[ @seqnames[0,1,2] ],
	    [ $seqnames[3] ],
	   ],
	   'self-match of already present sequence does not change anything',
	 );


$set->add_match(@seqnames[3,7]);
$set->add_match(@seqnames[3,6]);
$set->add_match(@seqnames[3,5]);
is_deeply( cs_contents($set),
	   [
	    [ @seqnames[3,5,6,7] ],
	    [ @seqnames[0,1,2] ],
	   ],
	   'and add more to the second cluster',
	 );



#find our file of test sequences
my $test_seqs_filename = File::Spec->catfile($FindBin::Bin,'data','test.seq');
die "can't open $test_seqs_filename" unless -r $test_seqs_filename;

#make a Bio::Index of them so we can retrieve individual ones
my $test_seqs_index = Bio::Index::Fasta->new( -filename => do { my (undef,$tf) = tempfile(UNLINK => 1); $tf },
					      -write_flag => 1
					    );
$test_seqs_index->make_index($test_seqs_filename);

#make a new set
$set = CXGN::Cluster::ClusterSet->new;

#now test the cluster calculation using a few things we know should cluster in the test set
my @known_clusters =
  (
   [sort qw/C04HBa0114G11.1 C04HBa0050I18.1 C04HBa0036C23.1 C04HBa0008H22.1/],
   [sort qw/C04HBa0024G05.1 C04HBa0020F17.1 /],
   [sort qw/C10HBa0020A12.1 C10HBa0248A13.3 /],
  );

#make a cluster with just one member
$set->add_match($known_clusters[0][0],$known_clusters[0][0]);
my @c = $set->get_clusters;
is_deeply(cs_contents($set),
	  [[$known_clusters[0][0]]],
	  'single-member cluster loaded OK',
	 );

is_deeply( [ $c[0]->get_contig_coords($test_seqs_index) ],
	   [[['C04HBa0008H22.1',1,81572,1]]],
	   'singleton contig coordinates appear correctly',
	 );

#put in the first cluster
$set->add_match($known_clusters[0][0],$_) foreach @{$known_clusters[0]};;
is_deeply(cs_contents($set),
	  [$known_clusters[0]],
	  'first known cluster members loaded ok'
	 );

#now get its coordinates, it should come out as just one contig
@c = $set->get_clusters;
#print Dumper $c[0]->get_contig_coords($test_seqs_index);
is_deeply( [ $c[0]->get_contig_coords($test_seqs_index) ],
	   [[
	    [
	     'C04HBa0114G11.1',
	     1,
	     '28696',
	     1
	    ],
	    [
	     'C04HBa0050I18.1',
	     26697,
	     '140337',
	     1
	    ],
	    [
	     'C04HBa0036C23.1',
	     138338,
	     '252489',
	     1
	    ],
	    [
	     'C04HBa0008H22.1',
	     250490,
	     '332061',
	     1
	    ]
	   ]],
	   'first test contig assembled OK'
	 );


my $bs = [ $c[0]->get_consensus_base_segments($test_seqs_index, min_segment_size => 100 ) ];
is_deeply( $bs,
           [
               [
                   [
                       '1',
                       '26696',
                       'C04HBa0114G11.1',
                       1,
                       26696,
                       0
                      ],
                   [
                       '26697',
                       '138337',
                       'C04HBa0050I18.1',
                       1,
                       111641,
                       0
                      ],
                   [
                       '138338',
                       '250489',
                       'C04HBa0036C23.1',
                       1,
                       112152,
                       0
                      ],
                   [
                       '250490',
                       '332061',
                       'C04HBa0008H22.1',
                       1,
                       81572,
                       0
                      ]
                  ]
              ],
           'get_consensus_base_segments',
          )
    or diag Dumper $bs;

#put in the second cluster
$set->add_match($known_clusters[1][0],$_) foreach @{$known_clusters[1]};
is_deeply(cs_contents($set),
	  [@known_clusters[0,1]],
	  'second known cluster members loaded ok'
	 );

#assemble the second cluster
@c = $set->get_clusters;
is_deeply( [ $c[0]->get_contig_coords($test_seqs_index) ],
	   [[
	     [
	      'C04HBa0024G05.1',
	      1,
	      '85242',
	      1
	     ],
	     [
	      'C04HBa0020F17.1',
	      83243,
	      '211703',
	      1
	     ]
	    ]],
	   'second test contig assembled OK'
	 );

$bs = [ $c[0]->get_consensus_base_segments($test_seqs_index) ];
is_deeply( $bs,
           [
               [
                   [
                       '1',
                       '83242',
                       'C04HBa0024G05.1',
                       1,
                       83242,
                       0
                      ],
                   [
                       '83243',
                       '211703',
                       'C04HBa0020F17.1',
                       1,
                       128461,
                       0
                      ]
                  ]
           ],
          )
    or diag Dumper $bs;


#make an artificial linkage between the first and second cluster, this
#should assemble into two real contigs
$set->add_match($known_clusters[0][0],$known_clusters[1][1]);
is_deeply(cs_contents($set),
	  [[sort @{$known_clusters[0]},@{$known_clusters[1]}]],
	  'artificial cluster linkage results in joining of clusters'
	 );

#now check that they assemble into two actual contigs
@c = $set->get_clusters;
#bprint Dumper $c[0]->get_contig_coords($test_seqs_index);
is_deeply( [ $c[0]->get_contig_coords($test_seqs_index) ],
	   [
	    [
	     [
	      'C04HBa0024G05.1',
	      1,
	      '85242',
	      1
	     ],
	     [
	      'C04HBa0020F17.1',
	      83243,
	      '211703',
	      1
	     ]
	    ],
	    [
	     [
	      'C04HBa0114G11.1',
	      1,
	      '28696',
	      1
	     ],
	     [
	      'C04HBa0050I18.1',
	      26697,
	      '140337',
	      1
	     ],
	     [
	      'C04HBa0036C23.1',
	      138338,
	      '252489',
	      1
	     ],
	     [
	      'C04HBa0008H22.1',
	      250490,
	      '332061',
	      1
	     ]
	    ]
	   ],
	   'erroneous precluster assembles into two actual contigs'
	 );


#make a new set
$set = CXGN::Cluster::ClusterSet->new;

# now add fake matches between and among the known clusters to put
# them all in one precluster
$set->add_match( $known_clusters[0][0], $known_clusters[2][0] );
$set->add_match( $known_clusters[2][0], $_ ) for @{$known_clusters[2]};

@c = $set->get_clusters;
is( scalar(@c), 1, 'got one cluster' );
# and check the base segments that are made
$bs = [ $c[0]->get_consensus_base_segments($test_seqs_index, min_segment_size => 100 ) ];
is_deeply( $bs,
           [
               [
                   [
                       1,
                       134537,
                       'C10HBa0020A12.1',
                       1,
                       134537,
                       0
                      ],
                   [
                       134538,
                       134541,
                       'C10HBa0248A13.3',
                       134538,
                       134541,
                       0
                      ],
                   [
                       134542,
                       135038,
                       'C10HBa0020A12.1',
                       134542,
                       135038,
                       0
                      ]
                  ],
               [
                   [
                       1,
                       81572,
                       'C04HBa0008H22.1',
                       1,
                       81572,
                       0
                      ]
                  ]
              ],
           'segment merging worked'
          )
    or diag Dumper $bs;

#make a sorted list of sorted arrayrefs representing the clusters in the set
#clusters sorted in descending size order,
#members sorted in alphabetical order
sub cs_contents {
  my $set = shift;
  my @c = $set->get_clusters;
  return [ sort {@$b <=> @$a}  map [sort $_->get_members], @c ];
}
