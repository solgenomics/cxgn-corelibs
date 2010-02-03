#!/usr/bin/perl
use strict;
use warnings;
use English;
use Data::Dumper;

use File::Temp qw/tempfile/;

BEGIN {
  our @tests =
    (
     { file      => 'LE_HBa0034B23.tar.gz',
       parsed    => undef,
       pub       => undef,
     },
     { file      => 'C03HBa0034B23.tar.gz',
       parsed    => { lib => 'LE_HBa',
		      plate => 34,
		      row => 'B',
		      col => 23,
		      chr => 3,
		      seq_name => 'C03HBa0034B23',
		      clone_name => 'C03HBa0034B23',
		      seq_version => undef,
		      file_version => undef,
		      filename => 'C03HBa0034B23.tar.gz',
		      full_unversioned => './C03HBa0034B23.tar.gz',
		      basename => 'C03HBa0034B23.tar.gz',
		      finished => undef,
		    },

     },
     { file      => 'C14HBa1234B12.tar.gz',
       parsed    => { lib => 'LE_HBa',
		      plate => 1234,
		      row => 'B',
		      col => 12,
		      chr => 14,
		      seq_name => 'C14HBa1234B12',
		      clone_name => 'C14HBa1234B12',
		      seq_version => undef,
		      file_version => undef,
		      filename => 'C14HBa1234B12.tar.gz',
		      full_unversioned => './C14HBa1234B12.tar.gz',
		      basename => 'C14HBa1234B12.tar.gz',
		      finished => undef,
		    },
     },
     { file      => 'C14HBa1234B12.2.v27.tar.gz',
       parsed    => { lib => 'LE_HBa',
		      plate => 1234,
		      row => 'B',
		      col => 12,
		      chr => 14,
		      seq_name => 'C14HBa1234B12.2',
		      clone_name => 'C14HBa1234B12',
		      seq_version => 2,
		      file_version => 27,
		      filename => 'C14HBa1234B12.2.v27.tar.gz',
		      full_unversioned => './C14HBa1234B12.2.tar.gz',
		      basename => 'C14HBa1234B12.2.v27.tar.gz',
		      finished => undef,
		    },
     },
    );

  #test the genbank acc and seq name lookup functions
  our %name_accs = ( 'C01HBa0003D15.1' => 'AC193776.1',
		     'C01HBa0051C14.1' => 'AC193777.1',
		     'C01HBa0088L02.2' => 'AC171726.2',
		     'C01HBa0163B20.1' => 'AC171727.1',
		     'C01HBa0216G16.2' => 'AC171728.2',
		     'C01HBa0252G05.2' => 'AC171729.2',
		     'C01HBa0256E08.2' => 'AC171730.2',
		     'C01HBa0329A12.1' => 'AC193779.1',
		   );
}
use Test::More tests => 6+scalar(our @tests)*2+3*scalar(keys our %name_accs) + 8 + 28;
use Test::Exception;

use_ok(  'CXGN::TomatoGenome::BACPublish',
	 qw(
	    parse_filename
	    publishing_locations
	    aggregate_filename
	    glob_pattern
	    sequencing_files
	    seq_name_to_genbank_acc
	    genbank_acc_to_seq_name
	    cached_validation_text
	    cached_validation_errors
	    valcache
	    tpf_file
	    agp_file
	    tpf_agp_files
	   )
      );

foreach my $test (our @tests) {

  #test parse_filename
  my $parsed = parse_filename($test->{file});
  is_deeply($parsed,$test->{parsed},
	    'parse_filename works')
    or diag( "$test->{file} was parsed as:\n",
	     Dumper($parsed),
	     "but should have been parsed as:\n",
	     Dumper($test->{parsed}),
	   );

  #test publishing_locations
 SKIP: {
      skip 'not a valid published filename', 1 unless $parsed;

      if( $parsed->{chr} > 12 ) {
	  throws_ok {
	      publishing_locations('/fakeplace/',$parsed->{seq_name},1);
	  } qr/chromosome/, 'publishing_locations dies for invalid chrs';
      } else {
	  my $pub = publishing_locations('/fakeplace/',$parsed->{seq_name},1);
	  ok( defined $pub->{annot_merged},
	      "publishing_locations works for '$parsed->{seq_name}' 1")
	      or diag Dumper [ $test->{file}, $parsed, $pub ];
      }
  }
}

#test aggregate_filename

#dies on invalid tagname
eval{aggregate_filename('foobar')};
ok($EVAL_ERROR,'aggregate_filename dies on invalid tag');

#works for all_seqs
my $agf = aggregate_filename('all_seqs');
my $glob = glob_pattern('all_seqs');
#diag "aggregate filename all_seqs => $agf, glob is $glob";
like($agf,qr/^\//,'has an all_seqs tag, looks like an absolute path');
like($glob,qr/^\//,'has an all_seqs glob, looks like an absolute path');
#and chrX_all_seqs
$agf = aggregate_filename('chr1_finished_seqs');
$glob = glob_pattern('chr1_finished_seqs');
#diag "aggregate filename chr1_finished_seqs => $agf, glob is $glob";
like($agf,qr/^\//,'has a chr1_finished_seqs tag, looks like an absolute path');
like($glob,qr/^\//,'has a chr1_finished_seqs glob, looks like an absolute path');


my $dbh = CXGN::DB::Connection->new({ config => CXGN::TomatoGenome::Config->load });
while(my ($n,$a) = each our %name_accs) {
  is(seq_name_to_genbank_acc($n,$dbh),$a,"seq_name_to_genbank_acc('$n') -> $a");
  is(genbank_acc_to_seq_name($a,$dbh),$n,"genbank_acc_to_seq_name('$a') -> $n");
  $a =~ s/\.\d+//; #clip off the accession
  is(genbank_acc_to_seq_name($a,$dbh),$n,"genbank_acc_to_seq_name('$a') -> $n");
}


#test cached_validation_text
my (undef,$tempfile) = tempfile(UNLINK => 1);
is(cached_validation_text($tempfile),undef,'no val in validation cache');
is_deeply([cached_validation_errors($tempfile)],[],'no val in validation cache 2');

valcache($tempfile,{ text => 'foobar', errors => [1,2,3] });
sleep 2;
is(cached_validation_text($tempfile),'foobar','validation cache stores OK');
is_deeply([cached_validation_errors($tempfile)],[1,2,3],'validation cache stores OK 2');
sleep 2;
`touch $tempfile`;
is(cached_validation_text($tempfile),undef,'validation cache invalidates with mtime');
is_deeply([cached_validation_errors($tempfile)],[],'validation cache invalidates with mtime 2');
valcache($tempfile,{ text => 'monkeys', errors => [3,4,5]});
is(cached_validation_text($tempfile),'monkeys','validation cache stores OK');
is_deeply([cached_validation_errors($tempfile)],[3,4,5],'validation cache stores OK 2');

#test tpf_file, agp_file, tpf_agp_files
for my $chr (1..12) {
  my ($t,$a) = tpf_agp_files($chr);
  is($t,tpf_file($chr),"tpf_file returns the same as tpf_agp_files for chr $chr");
  is($a,agp_file($chr),"agp_file returns the same as tpf_agp_files for chr $chr");
}

# test sequencing_files
require CXGN::Genomic::Clone;
my $clone = CXGN::Genomic::Clone->retrieve( 7376 );
isa_ok( $clone, 'CXGN::Genomic::Clone', 'got a clone to test with');
SKIP: {
    $clone && $clone->latest_sequence_name
	or skip 'could not find a sequenced clone to test with, skipping sequencing_files test', 3;
    my %seqfiles = sequencing_files( $clone, '/fake/ftpsite/root' );
    ok( exists $seqfiles{$_}, "got $_" )
	for qw| tar obsolete gff3 |;
}
$dbh->disconnect(42);
