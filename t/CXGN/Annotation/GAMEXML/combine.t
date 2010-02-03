#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Temp qw/tempfile/;

use Test::More tests => 2;
use Test::XML::Simple;

use CXGN::Tools::File qw/file_contents/;

use CXGN::Annotation::GAMEXML::Combine qw/combine_game_xml_files/;
use CXGN::Annotation::GAMEXML::FromFile qw/gff_to_game_xml/;

sub here($) { File::Spec->catfile($FindBin::Bin,shift) };

my (undef,$tempfile1) = tempfile;
my (undef,$tempfile2) = tempfile;

gff_to_game_xml( here 'C01HBa0088L02.seq', here 'C01HBa0088L02.seq.out.gff', $tempfile1,
		 program_name => 'RepeatMasker',
		 database_name => 'SGN Repeats',
#		 render_as_annotation => 1,
	       );

#print "./Combinefile.pl bleh.xml $tempfile1 $ENV{PWD}/C01HBa0088L02.geneseqer.xml\n";
combine_game_xml_files($tempfile1,here 'C01HBa0088L02.geneseqer.xml',$tempfile2);
#system "cat $tempfile2";
ok(-f $tempfile2);
xml_valid(file_contents($tempfile2), 'combined files are valid xml');
