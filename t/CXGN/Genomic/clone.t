#!/usr/bin/env perl
use strict;
use warnings;

use UNIVERSAL qw/isa/;

use Bio::SeqUtils;

use List::MoreUtils;

use CXGN::DB::Connection;
use CXGN::DB::DBICFactory;

use CXGN::Tools::Text qw/commify_number/;
use CXGN::CDBI::Class::DBI::TestSampler;
use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident/;

my %config;
BEGIN {
    %config = ( packagename => 'CXGN::Genomic::Clone',
		test_repeats => 4,
		numtests     => 28,
	       );

}
;
use Test::More;
use_ok('CXGN::Genomic::Clone');

my $chado = CXGN::DB::DBICFactory->open_schema('Bio::Chado::Schema');
my $dbh = CXGN::Genomic::Clone->db_Main;
foreach my $cid ( 2, 55724,119416 ) {
    test_random_clone( $dbh, $cid );
}

done_testing;

############# SUBROUTINES #########

sub test_random_clone {
  my $dbh = shift;
  my $id = shift;

  #test that we can retrieve it
  my $clone = CXGN::Genomic::Clone->retrieve($id);
  isa_ok $clone, 'CXGN::Genomic::Clone';

  #diag 'testing with clone id '.$clone->clone_id;

  #check estimated length
  my ($estlen) = $dbh->selectrow_array('select estimated_length from genomic.clone where clone_id=?',undef,$id);
  ok(!defined($estlen) && !defined($clone->estimated_length)
     || $clone->estimated_length == $estlen
    );

  ok($clone->clone_name_with_chromosome || 'does not die','clone_name_with_chromosome method does not die');

  #check has_a relations
  ok( isa($clone->library_id,'CXGN::Genomic::Library') );
  ok( isa($clone->clone_type_id,'CXGN::Genomic::CloneType') );
  #check has_many relations
  my $bad_chromats = grep {! isa($_,'CXGN::Genomic::Chromat')} $clone->chromat_objects;
  ok($bad_chromats == 0);

  #cursory checks of sql
  my @sql_args = ( $clone->library_object->shortname,
                   $clone->platenum,
                   $clone->wellrow,
                   $clone->wellcol,
                 );
  ok($clone->clone_name_mysql(@sql_args) =~ /concat/i);
  ok($clone->clone_name_postgresql(@sql_args) =~ /\|\|/i);
  ok($clone->cornell_clone_name_mysql(@sql_args) =~ /concat/i);
  ok($clone->cornell_clone_name_postgresql(@sql_args) =~ /\|\|/i);

  #clone name and cornell clone name
  my $valid_name_pattern = qr/^[A-Z]{2}_\w+\d{4}[A-Z]\d{2}$/;
  ok($clone->clone_name =~ $valid_name_pattern);
  ok($clone->clone_name eq $clone->arizona_clone_name);
  my $valid_cornell_name_pattern =
    $clone->library_id->shortname eq 'LE_HBa' ? qr/^P\d{3}[A-Z]\d{2}$/ :
      $valid_name_pattern;
  ok($clone->cornell_clone_name =~ $valid_cornell_name_pattern);
  #  warn "clone name was ".$clone->cornell_clone_name;

  #check that we can retrieve from clone name
  is(CXGN::Genomic::Clone->retrieve_from_clone_name($clone->clone_name),
     $clone,
     'can retrieve self by clone name'
    );

  ok($clone->library_id->library_id == $clone->library_object->library_id);

  #test the chado_feature method
  my $features = $clone->chado_feature_rs( $chado );
  can_ok( $features, 'next', 'first', 'all' );
  my $feature = $features->single; #< actually execute the query also

  #check that clone_type_object returns the right stuff
  ok(ref($clone->clone_type_object) eq ref($clone->clone_type_id));
  ok($clone->clone_type_object->clone_type_id == $clone->clone_type_id->clone_type_id);

  #check that the sequencing status is a valid value
  my $seqstatus = $clone->sequencing_status;
  ok(grep {$seqstatus eq $_} qw/in_progress none complete/);

  #check that the clone's sequence is valid
  unlike( $clone->seq || '', qr/[^ACTGXN]/i, 'clone has valid sequence or no sequence');

  #check that the latest sequence name is kosher
  my $chado_name = $clone->latest_sequence_name;
  my $chado_name_parsable = parse_clone_ident($chado_name,'versioned_bac_seq');
  ok( !defined($chado_name) || $chado_name_parsable, 'latest_sequence_name returns a valid value');

  #check restriction fragment functions

  #check that intl_clone_name returns something that looks right
  is( $clone->intl_clone_name, $clone->library_object->shortname.'-'.$clone->platenum.$clone->wellrow.$clone->wellcol,
      'intl_clone_name looks OK');

  my $acc = $clone->genbank_accession( $chado );
  my @acc = $clone->genbank_accession( $chado );
  if($acc) {
    ok(@acc == 1,'genbank_accession returns 1-element list if has genbank accession');
    like($acc,qr/^[A-Z]{2}\d+\.\d+$/,'genbank accession looks correctly formed');
  } else {
    ok(! defined $acc, 'genbank_accession returns undef in scalar context if no accession');
    ok(@acc == 0,'genbank_accession returns empty list in list context if no accession');
  }


  #check clone restriction fragments methods
  my @seqs = $clone->seq;
  if( @seqs == 1 ) {
    my $f = $clone->in_silico_restriction_fragment_sizes('HindIII');
    is ref($f), 'ARRAY', 'in-silico restriction func returns arrayref';
    ok !grep ref,@$f, 'and the arrayref is flat';

    if( my @iv = $clone->in_vitro_restriction_fragment_sizes('HindIII') ) {
      my $iv = shift @iv;
      is ref($iv), 'ARRAY', 'in-vitro restriction func returns arrayref';
      ok !(grep {ref} @$iv), 'invitro arrayref is flat';
    } else {
      ok @iv == 0, 'in_vitro properly returned empty list';
      SKIP: { skip 'no in-vitro restriction record',1 };
    }

  } else {
    ok !defined $clone->in_silico_restriction_fragment_sizes('HindIII'), 'no sequence, so no in silico restriction fragments';
    SKIP: {skip 'no finished sequence', 3}
  }

##############################################################################
}

