package CXGN::Annotation::GAMEXML::Combine;

use strict;
use warnings;

use File::Copy;

#use XML::DOM;
use XML::LibXML;

=head1 NAME

CXGN::Annotation::GAMEXML::Combine - merge GAME XML files

=head1 FUNCTIONS

All listed functions are EXPORT_OK.

=cut

BEGIN {
  our @EXPORT_OK = qw{
		      combine_game_xml_files
		    };
};
our @EXPORT_OK;
use base qw/Exporter/;


=head2 combine_game_xml_files

  Usage: combine_files('game1.xml','game2.xml','game3.xml','merged.xml');
  Desc : merge the annotations contained in several files into a single file
  Ret  : 1 on success, dies on failure
  Args : list of files to merge, output file to put them in
  Side Effects: writes merged XML to the last filename given

  This function assumes that all input files contain annotations for the
  same sequence.  It takes the actual sequence from the first input
  file.

=cut

sub combine_game_xml_files {
  my $outfile = pop;
  my @files = @_;

  if (@files > 1) {
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file(shift @files);

    my $ins_point = $doc->documentElement; #should be the <game> element

    foreach my $file (@files) {
      my $doc2 = $parser->parse_file($file);
      my $node = $doc2->documentElement;

      foreach my $child_node ($node->childNodes) {
	# Do not copy the <seq focus=true> element multiple times
	next if ( $child_node->nodeName() eq 'seq'
		  and $child_node->getAttributeNode("focus")
		  and $child_node->getAttributeNode("focus")->textContent eq 'true'
		);
#	print "appending node ".$child_node->nodeName."\n";
	
	$ins_point->appendChild($child_node);
      }
#      $doc2->dispose();
    }

    open OUT, ">$outfile"
      or die "Could not open '$outfile' for writing: $!";
    print OUT $doc->toString;
    close OUT;
  }
  elsif(@files == 1) {
    copy($files[0],$outfile)
      or die "Could not copy single input file '$files[0]' to output file '$outfile': $!";
  }
  return 1;
}


###
1;#do not remove
###
