#!/usr/bin/perl
use strict;
use warnings;
use CXGN::DB::Connection;

BEGIN {
  our $dbc = CXGN::DB::Connection->new;
  our @table_tests = (  {  schema    => 'genomic',
			   table     => 'blast_hit',
			   info      =>
			     { columns   => [qw/ blast_hit_id
						 blast_query_id
						 identifier
						 evalue
						 score
						 identity_percentage
						 align_start
						 align_end
						 blast_defline_id
						 /],
			       primary   => ['blast_hit_id'],
			       sequence  => $dbc->qualify_schema('genomic',1).'.blast_hit_blast_hit_id_seq',
			     },
			},
			{  schema    => 'sgn',
			   table     => 'blast_hits',
			   info      =>
			     { columns   => [qw/ blast_hit_id
						 blast_annotation_id
						 target_db_id
						 evalue
						 score
						 identity_percentage
						 apply_start
						 apply_end
						 defline_id
						 /],
			       primary   => ['blast_hit_id'],
			       sequence  => $dbc->qualify_schema('sgn',1).'.blast_hits_blast_hit_id_seq',
			     },
			},
		     );
}
our @table_tests;
our $dbc;

use Test::More tests => @table_tests*1;

use CXGN::Tools::PgCatalog qw/ table_info /;

foreach my $test (@table_tests) {
  my %info = table_info( $dbc, $test->{schema}, $test->{table} );

  is_deeply(\%info, $test->{info}, "correct for $test->{schema}.$test->{table}");
}




