#!/usr/bin/perl
use strict;
use warnings;
use English;

use FindBin;
use IO::String;
use File::Spec;
use File::Temp qw/tempfile/;

use Tie::Function;

use Bio::Tools::RepeatMasker;
use Bio::FeatureIO;

use Test::More qw(no_plan);
use CXGN::Tools::File qw/file_contents/;

use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml geneseqer_to_game_xml/;

my (undef,$tempfile) = tempfile(CLEANUP => 1);

sub here($) { File::Spec->catfile($FindBin::Bin,shift) };

diag "using temp file $tempfile";

geneseqer_to_game_xml( here 'C01HBa0088L02.seq' , here 'C01HBa0088L02.geneseqer.est', $tempfile,
#		       render_as_annotation => 1,
		     );

my $test_gxml = here 'C01HBa0088L02.geneseqer.xml';
ok( file_contents($tempfile) eq file_contents( $test_gxml), 'geneseqer_to_game_xml' )
  or print file_contents($tempfile);

#gff_to_game_xml( here 'volvox.fa', here 'volvox6.gff', $tempfile);
gff_to_game_xml( here 'C01HBa0088L02.seq', here 'C01HBa0088L02.seq.out.gff', $tempfile,
		 program_name => 'RepeatMasker',
		 database_name => 'SGN Repeats',
#		 render_as_annotation => 1,
	       );

diag "used temp file $tempfile";

#test gff3 to gamexml
my $fake_repeatmasker_file = IO::String->new(<<EOREPEATMASKER);
  SW  perc perc perc  query            position in query         matching    repeat         position in  repeat
score  div. del. ins.  sequence          begin    end   (left)   repeat      class/family   begin  end (left)  ID

  918  20.4  6.8  1.9  C01HBa0088L02      2095   2556 (124560) C  Contig151   Unknown/repeat   (7)  832    325   1
  488  17.9  0.0  6.6  C01HBa0088L02      2590   2736 (124380) C  Contig386   Unknown/repeat (592)  124      1   2
 1718  15.9  0.9  3.5  C01HBa0088L02      2787   3105 (124011) +  Contig358   Unknown/repeat     1  311    (3)   3
  312  14.5  0.0  1.6  C01HBa0088L02      3974   4036 (123080) C  hind_R=2046 Unknown          (0)  120     59   4
EOREPEATMASKER

my $fi = Bio::Tools::RepeatMasker->new( -fh => $fake_repeatmasker_file );

my ($tempfh,$tempfile2) = tempfile(CLEANUP=>1);
{ my $fo = Bio::FeatureIO->new(-fh=> $tempfh, -format => 'gff', -version => 3);
  while (my $feature_pair = $fi->next_result() ) {
    $feature_pair->primary_tag('nucleotide_motif');
    my $old = $feature_pair->feature1;
    my $f = Bio::SeqFeature::Annotated->new( -feature => $old );
    $fo->write_feature( $f );
  }
}

#print file_contents($tempfile2);
#now convert that gff3 to gamexml
gff_to_game_xml( here 'C01HBa0088L02.seq', $tempfile2, $tempfile,
		 program_name => 'RepeatMasker',
		 database_name => 'SGN Repeats',
		 gff_version => 3,
#		 render_as_annotation => 1,
	       );
gff_to_game_xml( here 'C06HBa0002C17.1.v1.seq',
		 here 'C06HBa0002C17.1.v2.repeatmasker.gff',
		 $tempfile,
		 program_name => 'RepeatMasker',
		 database_name => 'SGN Repeats',
	       );

#print file_contents($tempfile);

#TODO: these tests suck.  they really need to be more rigorous

