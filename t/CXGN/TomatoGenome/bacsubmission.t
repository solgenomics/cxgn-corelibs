#!/usr/bin/perl
use strict;
use warnings;
use UNIVERSAL qw/ isa /;
use Data::Dumper;

use CXGN::DB::Connection;

use List::Util qw/ shuffle /;
use List::MoreUtils qw/ all /;

use FindBin;
use File::Spec::Functions qw/ catdir catfile/;
use File::Basename;
use File::Find;

use CXGN::Tools::File qw/ file_contents /;
use CXGN::Tools::List qw/ str_in /;

use CXGN::Genomic::CloneIdentifiers qw/ parse_clone_ident /;

BEGIN {
  my $testfiles_path = catdir( $FindBin::RealBin, 'data' );
  our @test_tarballs = (
			{ file      => 'LE_HBa0034B23.tar.gz',
			  errors    => 3,
			  bacname   => 'LE_HBa0034B23',
			  has_qual_file => 1,
			  reparable => 0,
			  finished  => 1,
			  numseqs   => 1,
			  gbacc     => undef,
			},
			{ file      => 'C01HBa0163B20.tar.gz',
			  errors    => 0,
			  bacname   => 'C01HBa0163B20',
			  finished  => 1,
			  reparable => 1,
			  numseqs   => 1,
			  gbacc     => 'AC171727.1',
			},
			{ file => 'C04HBa0036C23.tar.gz',
			  errors => 0,
			  bacname => 'C04HBa0036C23',
			  reparable => 1,
			  finished => 1,
			  numseqs => 1,
			  gbacc => 'CT990637.2',
			},
			{ file      => 'C01HBa0001M12.tar.gz',
			  errors    => 3,
			  portable_errors => 2,
			  bacname   => 'C01HBa0001M12',
			  reparable => 0,
			  finished  => 0,
			  numseqs   => 5,
			  gbacc     => undef,
			},
			{ file      => 'C01HBa0051C14.tar.gz',
			  errors    => 1,
			  bacname   => 'C01HBa0051C14',
			  finished  => 1,
			  reparable => 0,
			  numseqs   => 1,
			  gbacc     => undef,
			},
			{ file      => 'C01HBa0088L02.tar.gz',
			  errors    => 2,
			  portable_errors  => 1,
			  bacname   => 'C01HBa0088L02',
			  reparable => 0,
			  finished  => 1,
			  numseqs   => 1,
			  gbacc     => 'AC171726.2',
			},
	
			{ file      => 'C04SLm0059M16.tar.gz',
			  errors    => 0,
			  bacname   => 'C04SLm0059M16',
			  reparable => 1,
			  finished  => 1,
			  numseqs   => 1,
			  version   => 1,
			  gbacc     => 'CU179634.6',
			  matching_seq_orgs => [ { org_shortname => 'sanger',
						   org_upload_account_name => 'uk',
						   org_sp_organization_id => 10,
						   org_name => 'Wellcome Trust Sanger Institute',
						 }
					       ],
			},
			

		       );
  $_->{file} = catfile($testfiles_path,$_->{file})
    foreach @test_tarballs;
}
our @test_tarballs;
use Test::More tests => 1+scalar(@test_tarballs)*39 + scalar( grep !$_->{has_qual_file},@test_tarballs )*1;
use Test::Warn;

BEGIN {
  use_ok('CXGN::TomatoGenome::BACSubmission',':errors');
}
use CXGN::Tools::Run;

use CXGN::DB::Connection;

my $dbh = CXGN::DB::Connection->new;
sub _hashall {
  my $sth = shift;
  my @hashes;
  while ( my $h = $sth->fetchrow_hashref ) {
    my $new_h = {};
    while (my ($k,$v) = each %$h) {
      #add an org_ to the beginning of each column name,
      #and don't include undefined values
      if ( defined $v ) {
	$new_h->{"org_$k"} = $v;
      }
    }
    push @hashes, $new_h;
  }
  return @hashes;
}

my $all_seq_orgs = do {
  my $s = $dbh->prepare('select * from sgn_people.sp_organization');
  $s->execute;
  [_hashall($s)];
};
#print "all seq orgs ".Dumper $all_seq_orgs;

foreach my $test (@test_tarballs) {
  my $submission = CXGN::TomatoGenome::BACSubmission->open( $test->{file} );
  ok( isa($submission,'CXGN::TomatoGenome::BACSubmission'), "CXGN::TomatoGenome::BACSubmission constructor works" );
  is( $submission->tar_file, $test->{file}, 'tar_file() accessor works');
  is( $submission->bac_name, $test->{bacname}, "inferred correct BAC name");

  my @a = $submission->analyses;
  ok( (all {$_} map { ref $_ && $_->can('run') or diag "$_ cannot run" } @a), 'analyses returned a list of analysis objects');
  ok( (all {$_} map { my $n = $_->analysis_name; length $n or diag "invalid aname '$n' for analysis package '$_'" } @a),
      'analysis packages all have names'
    );

  my @errors;
  if( $test->{has_qual_file} ) {
    @errors = $submission->validation_errors;
  } else {
    warning_like {
      @errors = $submission->validation_errors;
    } qr/No .qual file found in/, 'validation_errors warns about absence of qual file';
  }

#  print "Got validation errors:\n",(map {"  . $_\n"} @errors) if @errors;
  is( scalar(@errors),
      $test->{errors},
      "tarball $test->{file} validation error count",
    )
    or diag "Errors were: ".$submission->validation_text;

  #test repair
  my $repair_result = $submission->repair;
  @errors = $submission->validation_errors;
  is( !!$repair_result, !!$test->{reparable},
      'correct repair outcome')
    or diag "Errors after repair: ".$submission->validation_text;
  is( !!$repair_result, !scalar(@errors),
      'repair outcome agrees with validation routine')
    or diag "Errors after repair: ".$submission->validation_text;

  #test figuring out versions from the tar file
  is( $submission->version, $test->{version}, "version is correct");

  #reports correct genbank accession
  is( $submission->genbank_accession, $test->{gbacc}, 'genbank accession is correct');

  #reports correct sequence count
  is( $submission->sequences_count, $test->{numseqs}, 'correct seqs count');

  ##also test the portable validate_submission script on this
  # artificially truncate its @INC to make sure it is not accessing any CXGN modules
  my $val_sub = CXGN::Tools::Run->run('perl',
				      -e => q|
@INC=grep !(-d "$_/CXGN"),@INC;
my $file = `which validate_submission.pl`;
chomp $file;
unless (my $return = do $file) {
   die "couldn't parse $file: $@" if $@;
   die "couldn't do $file: $!"    unless defined $return;
   die "couldn't run $file"       unless $return;
}
|,

				      $test->{file},
				     );
  #count the number of validation errors it found
  open my $outfile, $val_sub->out_file
    or die "Could not open stdout file ".$val_sub->out_file.": $!";
  my $val_sub_errcnt = 0;
  my $got_errors_intro = 0;
  while(my $line = <$outfile>) {
    $val_sub_errcnt++
      if $line =~ /^\s+-\s+[\w\d]+/;
    $got_errors_intro = 1
      if $line =~ /failed:/i;
  }
  close $outfile;
  my $port_errors = $test->{portable_errors};
  $port_errors = $test->{errors} unless defined $port_errors;
  is($val_sub_errcnt,$port_errors,'portable validate_submission.pl script gets the correct error count')
    or diag "validate_submission.pl stdout was: ".$val_sub->out."\n and its stderr was: ".$val_sub->err;
  is($got_errors_intro,$port_errors ? 1 : 0,'portable validation script output looks correctly formed')
    or diag "validate_submission.pl stdout was: ".$val_sub->out."\n and its stderr was: ".$val_sub->err;

  #reports correct is_finished
  is(!!$submission->is_finished,!!$test->{finished},'reports correct is_finished');

 SKIP: {
    skip 'since test submission is invalid',3
      if $test->{errors} && ! $test->{reparable};

    #make a new tar and check that it worked right
    my $newtar = $submission->new_tarfile;
    ok( -r $newtar,
	'newly made tar file is readable' );
    my $newsub = CXGN::TomatoGenome::BACSubmission->open($newtar);
    ok( isa($newsub,'CXGN::TomatoGenome::BACSubmission'),
	"new tar $newtar is an openable submission file");
    my $new_vecscreen_file = catfile( $newsub->_tempdir, $submission->bac_name, $submission->bac_name.'.seq.screen');
    ok( -f $new_vecscreen_file,
	"vector screened seqs file $new_vecscreen_file inside the new tar file"),
      or find( sub {diag $_}, $newsub->_tempdir);
  }

  #test the sequencing organization stuff
  my @expected_orgs = $submission->sequencing_possible_orgs;

  is_deeply(\@expected_orgs, $test->{matching_seq_orgs} || $all_seq_orgs, 'got correct list of matching seq orgs')
    or diag 'actually got '.Dumper \@expected_orgs;

  #test setting the sequencing organization
  $submission->sequencing_info( org_shortname => 'inra');
  @expected_orgs = $submission->sequencing_possible_orgs;
  is(scalar(@expected_orgs),1,'org_shortname inra gives just one possible org entry')
    or diag 'after inra, actually got '.Dumper \@expected_orgs;
  #is_deeply(\@expected_orgs, 

  #check contents of sequencer_info.txt file
  is( file_contents( $submission->_seqinfo_filename), <<EOF, 'correct contents of sequencing info file');
org_shortname	inra
org_name	French National Institute for Agriculture Research (INRA)
org_upload_account_name	france
EOF

  ok( ! str_in( E_SEQ_INFO, $submission->validation_errors ), 'inra shortname for sequencing info does not make an error' );

 SKIP: {
    skip 'since test submission is invalid',16
      if $test->{errors} && ! $test->{reparable};

    #test sequence renaming
    my $original_file = $submission->sequences_file;
    my $renamed_file = $submission->renamed_sequences_file;
    ok( -r $original_file, 'original sequence file exists and is readable');
    ok( -r $renamed_file, "renamed sequence file ($renamed_file) exists and is readable");

    my $orig_seqs = Bio::SeqIO->new( -file => $original_file,
				     -format => 'fasta',
				   );
    my $ren_seqs  = Bio::SeqIO->new( -file => $renamed_file,
				     -format => 'fasta',
				   );
    my $seqs_ok = 1;
    my $names_ok = 1;
    my $account_ok = 1;
    my $seq_count = 0;
    my $all_renames_hyphenated = 1;
    my $some_renames_hyphenated = 0;
    while( my $orig = $orig_seqs->next_seq ) {
      my ($old_id) = $orig->desc =~ /submitted_to_sgn_as:(\S+)/;
      $old_id ||= $orig->primary_id;
      my $ren = $ren_seqs->next_seq;
#      print $orig->display_id,'->',$ren->display_id,"\n";
      $seqs_ok  &&= $ren && $ren->seq eq $orig->seq;
      $names_ok &&= $ren && -1 != index($ren->desc,$old_id)
	or diag "improper renamed defline: ".$ren->desc;
      $account_ok &&= $ren && -1 != index($ren->desc,'upload_account_name:france')
	or diag "no upload account in defline: ".$ren->desc;

      #diag "renamed defline: ".$ren->desc;

      $all_renames_hyphenated &&= $ren->primary_id =~ /-\d+$/;
      $some_renames_hyphenated ||= $ren->primary_id =~ /-\d+$/;

      $seq_count++;
    }
    #make sure there aren't more renamed seqs than originals
    $seqs_ok &&= ! $ren_seqs->next_seq;

    ok( $seqs_ok,
	'original and renamed sequences contain the same seqs');
    ok( $names_ok,
	'renamed sequences contain the original names in their deflines');
    ok( $account_ok,
	'renamed sequences contain the upload account in their deflines');
    ok( $seq_count >= 1,
	'at least 1 sequence in BAC submission file');
    is( $submission->sequences_count, $seq_count, 'sequences_count() returns the right number of sequences');
    is( $seq_count, scalar($submission->sequences),
	'sequences() returns the right number of sequences');
    is( $seq_count, scalar($submission->vector_screened_sequences),
	'vector_screened_sequences() returns the right number of sequences');
    ok( $seq_count > 1 && $all_renames_hyphenated || $seq_count == 1,
	'all renamed sequences have -# extensions');
    is( $all_renames_hyphenated, $some_renames_hyphenated,
	'either all renames are hyphenated or none are');


    #check chromosome number querying and changing
    my $old_chromosome = $submission->chromosome_number;
    my $parsed_old_bac_name = parse_clone_ident( $submission->bac_name, 'agi_bac_with_chrom' ) || {};
    is( $parsed_old_bac_name->{chr}, $old_chromosome, 'queried correct chromosome number' );

    #pick a random other chromosome to assign this bac to
    my ($new_chromosome) = shuffle grep $_ != $old_chromosome, 0..12;
    my $new_chromosome_name = $new_chromosome || 'unmapped';
    #diag "renaming from chromosome $old_chromosome to chromosome $new_chromosome";
    is( $submission->chromosome_number($new_chromosome), $new_chromosome_name, 'chromosome setter returns correct number' );

    my $new_name = $submission->bac_name;
    my $parsed_new_bac_name = parse_clone_ident( $new_name, 'agi_bac_with_chrom' ) || {};
    is( $parsed_new_bac_name->{chr}, $new_chromosome_name, 'queried correct new chromosome name' );

    like( $submission->sequences_file, qr/$new_name.seq$/, 'main sequence file appears to have been renamed' );
    like( $submission->main_submission_dir, qr/$new_name$/, 'main submission dir appears to have been renamed' );
  }

  $submission->sequencing_info( org_shortname => 'nonexistent');
  warning_like {
    ok( str_in( E_SEQ_INFO, $submission->validation_errors ), 'nonexistent shortname in sequencing info results in error' );
  } qr/unknown organization shortname/, 'nonexistent shortname also prints a warning';

  $submission->close;
}

$dbh->disconnect(42);

