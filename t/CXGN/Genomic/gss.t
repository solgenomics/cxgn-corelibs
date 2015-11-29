#!/usr/bin/env perl
use strict;
use warnings;
#use UNIVERSAL qw/isa/;


use CXGN::CDBI::Class::DBI::TestSampler;
BEGIN {
  our %config = ( packagename => 'CXGN::Genomic::GSS',
		  test_repeats => 50,
		  numtests     => 24,
		);

};
our %config;
use Test::More tests => $config{numtests}*$config{test_repeats};

use CXGN::Genomic::GSS;

sub test {
  my $dbh = shift;
  my $id = shift;

  ###test that we can retrieve it
  my $gss = $config{packagename}->retrieve($id);
  isa_ok( $gss, $config{packagename} );

  ### check basic data integrity
  my @fields = qw/ status flags seq qual call_positions version chromat_id gss_id /;
  my $fieldlist = join( ', ', @fields );
  my $gss2 = $dbh->selectrow_hashref( <<EOSQL, undef, $id );
SELECT $fieldlist
FROM genomic.gss
WHERE gss_id = ?
EOSQL
  foreach my $field (qw/seq qual call_positions version gss_id/) {
      my $v1 = $gss->$field;
      my $v2 = $gss2->{$field};
      ok( !defined $v1 && !defined $v2 || $gss->$field eq $gss2->{$field} );
  }

  ###test chromat_id
  isa_ok($gss->chromat_id, 'CXGN::Genomic::Chromat' );
  isa_ok($gss->chromat_object, 'CXGN::Genomic::Chromat' );
  ok( $gss->chromat_object->chromat_id == $gss->chromat_id->chromat_id );
  ok( $gss->chromat_object->chromat_id == $gss2->{chromat_id} );

  ###test gss_submitted_to_genbank
  my ($good1,$good2) = (1,1);
  foreach my $sub ($gss->gss_submitted_to_genbank_objects) {
    $good1 &&= ref($sub) eq 'CXGN::Genomic::GSSSubmittedToGenbank'
      or diag 'improper type for gss_submitted_to_genbank object';
    $good2 &&= ($sub->gss_id == $gss->gss_id)
      or diag $sub->gss_id.'!='.$gss->gss_id;
  }
  ok( $good1 );
  ok( $good2 );

  ###test status
  #look for any invalid status keys
  is( $gss->gen_status_mask($gss->status), $gss2->{status}, 'status is correct');
  is( $gss->gen_flags_mask($gss->flags), $gss2->{flags}, 'flags is correct' );
  my %validflags = map { $_,1 } @CXGN::Genomic::GSS::otherflags;
  my %validstatus = map { $_,1 } @CXGN::Genomic::GSS::statusflags;
  ok(! grep {! $validflags{$_} } keys(%{$gss->flags}) );
  ok(! grep {! $validstatus{$_} } keys(%{$gss->status}) );

  #check status2str and flags2str are at least the right length
  ok($gss->status2str == keys(%{$gss->status}));
  ok($gss->flags2str == keys(%{$gss->flags}));

  ### check that lengths of seqs, quals, and call_positions are all the same
  my $seq     = $gss->seq;
  my $tseq    = $gss->trimmed_seq;
  ok( !defined $_->[0]  || length $_->[1]  == scalar( my @foo = split /\s/, $_->[0] )
      , "valid $_->[2]",
    ) or diag("seq: '$_->[1]'\n$_->[2]: '$_->[0]'\n")
      for [ $gss->qual,           $seq,  'qual'         ],
	  [ $gss->trimmed_qual,   $tseq, 'trimmed qual' ],
	  [ $gss->call_positions, $seq,  'call pos'     ];

  #check consistency of trimmed_regions by trimming the raw sequence
  #with them and seeing if it comes out the same as the trimmed version
  $seq = $gss->seq;
  my $good3 = 1;
  my @trimmed = $gss->trimmed_regions;
  my $prevs = 0;
  my $prevlen = 0;
  foreach my $trim (@trimmed) {
    my ($s,$e) = @$trim;
    $prevs <= $s or diag 'trimmed_regions not in ascending order';
    my $len = $e-$s+1;
    substr($seq,$s-$prevlen,$len,''); #splice out parts of $seq
    $prevlen = $len;
    $prevs = $s;
  }
  ok($seq eq $gss->trimmed_seq) or
#     diag html_break_string($seq,70,"\n")
#       ."\nis not equal to\n"
# 	.html_break_string($gss->trimmed_seq,70,"\n");

  ###check the external identifier
  ok( index($gss->external_identifier,$gss->chromat_object->clone_read_external_identifier)
      != -1
    );
 SKIP: {
    skip($gss->version <= 1,1);
    isnt(index($gss->external_identifier,'_$gss->version'),-1);
  }

  ###check that unixtime doesn't crash: this could use some work
  $gss->unixtime;

  ###check to_bio_seq
  my $bseq = $gss->to_bio_seq(
    -factory => Bio::Seq::SeqFactory->new( -type => 'Bio::Seq::CXGNGenomic' )
			     );
  #check seqs the same
  ok($bseq->seq eq $gss->seq) or
#     diag html_break_string($bseq->seq,70,"\n")
#       ."\nis not equal to\n"
# 	.html_break_string($gss->seq,70,"\n");

  #check that quals the same
  ok(join(' ',@{$bseq->qual}) eq $gss->qual) or
#     diag html_break_string(join(' ',@{$bseq->qual}),70,"\n")
#       ."\nis not equal to\n"
# 	.html_break_string($gss->qual,70,"\n");

  #check the display_id is the external_identifier
  ok($bseq->display_id eq $gss->external_identifier);

}#end test subroutine

#now run the actual sampled test
my $tester = CXGN::CDBI::Class::DBI::TestSampler->new;

$tester->test_class($config{packagename},
                    $config{test_repeats},
                    \&test);

$tester->disconnect(42);




