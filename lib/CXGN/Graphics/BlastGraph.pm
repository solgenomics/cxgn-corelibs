#!/usr/bin/perl

# BlastGraph: use gd to create a histogram of matches on a unigene BLASTed against a database, by individual base.
# This is different from the graph created in view_result.pl: that one is made by means of the Bio::GMOD::Blast::Graph package.
# This package is auxiliary to view_result.pl only.
#
# Use this package by calling new() and then get_map_html(). The image created is available a la carte as well,
# since its name is taken in as a ctor parameter.
#
# author: Evan
package CXGN::Graphics::BlastGraph;
use strict;
use GD;
use Bio::SearchIO;    #BLAST output parser


#one argument: hashref{blast_outfile => $absolute_filename, graph_outfile => $absolute_filename}
sub new {
    my $class     = shift(@_);
    my %filenames = @_;
    my $obj       = {};

    $obj->{blast_outfile} = $filenames{blast_outfile};
    $obj->{graph_outfile} = $filenames{graph_outfile};

    #to be filled
    $obj->{query_length}     = 0;
    $obj->{num_hits_by_base} = []
      ; #number of actual matches (denoted by '|' in BLAST output) within region-matches
    $obj->{num_inclusions_by_base} = []
      ; #number of non-base-matches (denoted by ' ' in BLAST output) within region-matches
    $obj->{divisions} = []
      ; #the lower bounds of the various conservedness divisions, from most to least conserved
    $obj->{conservedness_regions} =
      [];    #each element contains {'start', 'end', 'division' (an index)}
    $obj->{conservedness_stripe_yTop} = 0;
    $obj->{conservedness_stripe_yBot} = 0;

    bless( $obj, $class );
    return $obj;
}

#parse input file (BLAST's output) and save stats
#no arguments
#returns an error string (empty if no error)
sub parse_results {
    my $self = shift(@_);

    #make one pass over the input file to check for results
    my ( $hits, $makegraph );
    open my $results, "<" . $self->{blast_outfile}
      or return "$! opening BLAST result file $self->{blast_outfile}";
    while (<$results>) {
        if (m/BLASTN/) {
            $makegraph = 1;
	    #we should create a graph (the input isn't messed up)
        }
        if (m/Sbjct:/) {
            $hits = 1;    #there was at least one hit
            last;
        }
    }
    seek $results, 0, 0; #< go back to the beginning

    #read through the input thoroughly; parse and graph results if present
    if ( $hits && $makegraph ) {
        my $report = Bio::SearchIO->new( -fh => $results, -format => 'blast' );
	my $result = $report->next_result;

        $self->{query_length} = $result->query_length;
        for ( my $i = 0 ; $i < $self->{query_length} ; $i++ ) {
            $self->{num_hits_by_base}->[$i]       = 0;
            $self->{num_inclusions_by_base}->[$i] = 0;
        }

	#homology, query and subject characters
        while ( my $hit = $result->next_hit ) {
            while ( my $hsp = $hit->next_hsp ) {
                my $i = $hsp->query->start - 1;    #index into query sequence
                for ( my $j = 0 ; $j < length( $hsp->homology_string ) ; $j++ ) {
		    my $hch = substr( $hsp->homology_string, $j, 1 );
		    my $qch = substr( $hsp->query_string,    $j, 1 );
		    my $sch = substr( $hsp->hit_string,      $j, 1 );

                    if ( $qch eq "-" ) { #gap in query sequence: don't count it
                        $i--;
                    }
                    elsif ( $hch eq "|" ) {   #exact match
                        $self->{num_hits_by_base}->[$i]++;
                    }
                    elsif ( $hch eq " " ) {
			#nonmatch within matched region: counts as three-fifths of a person
                        $self->{num_inclusions_by_base}->[$i]++;
                    }
                    $i++;
                }
            }
        }
    }
    return "";
}

#output to a given file using our collected data
#no arguments
#returns an error string (empty if no error)
sub write_img {
    my $self = shift(@_);
    my $errs = $self->parse_results();
    my $img  = GD::Image->new( 650, 140 )
      ;    #this size is a guess--should be the same as in view_result.pl

    #pixel coordinates from top left of image
    $self->{hist_xmin} = 25;
    $self->{hist_ymin} = 15;
    $self->{hist_xmax} = 625;
    $self->{hist_ymax} = 105;

    #normalize counts to fit in an image nicely
    my ( $max_hits, $new_max ) = ( 0, $self->{hist_ymax} - $self->{hist_ymin} );
    for ( my $i = 0 ; $i < $self->{query_length} ; $i++ ) {
        if ( $self->{num_hits_by_base}->[$i] +
            $self->{num_inclusions_by_base}->[$i] > $max_hits )
        {
            $max_hits =
              $self->{num_hits_by_base}->[$i] +
              $self->{num_inclusions_by_base}->[$i];
        }
    }

    #create cool picture here
    my $white = $img->colorAllocate( 255, 255, 255 );
    my $gray  = $img->colorAllocate( 160, 160, 160 );
    my $black = $img->colorAllocate( 0,   0,   0 );
    my $green = $img->colorAllocate( 0,   255, 0 );
    my $blue  = $img->colorAllocate( 0,   0,   255 );
    $img->fill( 0, 0, $white );
    $img->transparent($white);    #make background white as well as transparent

    #numerical info on hits in region
    $img->line(
        $self->{hist_xmin}, $self->{hist_ymin}, $self->{hist_xmax},
        $self->{hist_ymin}, $gray
    );
    $img->line(
        $self->{hist_xmax}, $self->{hist_ymin}, $self->{hist_xmax},
        $self->{hist_ymax}, $gray
    );
    $img->line( $self->{hist_xmin} - 2,
        $self->{hist_ymax}, $self->{hist_xmax}, $self->{hist_ymax}, $black );
    $img->line( $self->{hist_xmin}, $self->{hist_ymin}, $self->{hist_xmin},
        $self->{hist_ymax} + 2, $black );
    $img->line( $self->{hist_xmin} - 2,
        $self->{hist_ymin}, $self->{hist_xmin}, $self->{hist_ymin}, $black );
    $img->line(
        $self->{hist_xmin} + ( $self->{hist_xmax} - $self->{hist_xmin} ) / 2,
        $self->{hist_ymax},
        $self->{hist_xmin} + ( $self->{hist_xmax} - $self->{hist_xmin} ) / 2,
        $self->{hist_ymax} + 2,
        $black
    );
    $img->line( $self->{hist_xmax}, $self->{hist_ymax}, $self->{hist_xmax},
        $self->{hist_ymax} + 2, $black );
    $img->string(
        GD::Font->Small,
        $self->{hist_xmin} - 20,
        $self->{hist_ymin} - 5,
        "" . $max_hits, $black
    );
    $img->string(
        GD::Font->Small,
        $self->{hist_xmin} +
          ( $self->{hist_xmax} - $self->{hist_xmin} ) / 2 -
          12,
        $self->{hist_ymax} + 2,
        "" . int( $self->{query_length} / 2 ),
        $black
    );
    $img->string(
        GD::Font->Small,
        $self->{hist_xmax} - 12,
        $self->{hist_ymax} + 2,
        "" . $self->{query_length}, $black
    );
    $img->string( GD::Font->Small, $self->{hist_xmin}, $self->{hist_ymax} + 2,
        "Query", $black );

    #info on relative conservedness/uniqueness of region
    my ( $imgWidth, $imgHeight ) = $img->getBounds();
    $img->string(
        GD::Font->Small,
        $imgWidth / 2 - 39,
        $self->{hist_ymax} + 14,
        "Conservedness", $black
    );
    $self->{divisions} = [ 1000, 300, 100, 30, 10, 3, 1, 0 ]
      ; #the lower bounds of the various conservedness divisions, from most to least conserved
    my @divColors = (
        $img->colorAllocate( 255, 0,   0 ),      #red = most conserved
        $img->colorAllocate( 255, 128, 0 ),      #orange
        $img->colorAllocate( 255, 255, 0 ),      #yellow
        $img->colorAllocate( 0,   255, 0 ),      #green
        $img->colorAllocate( 0,   255, 128 ),    #turquoise
        $img->colorAllocate( 0,   0,   255 ),    #blue
        $img->colorAllocate( 128, 0,   255 ),    #purple
        $img->colorAllocate( 0,   0,   0 )       #black = least conserved
    );
    $self->{conservedness_stripe_yTop} = $self->{hist_ymax} + 27;
    $self->{conservedness_stripe_yBot} = $self->{hist_ymax} + 34;

    #temporaries
    my $curRegion = 0;    #index into $self->{conservedness_regions}
    for ( my $i = 0 ; $i < $self->{query_length} ; $i++ ) {

        #get the left and right limits of the rectangle to be drawn
        my $x =
          $self->{hist_xmin} + 1 +
          $i *
          ( $self->{hist_xmax} - $self->{hist_xmin} ) /
          $self->{query_length};
        my $x2 =
          $self->{hist_xmin} + 1 +
          ( $i + 1 ) *
          ( $self->{hist_xmax} - $self->{hist_xmin} ) /
          $self->{query_length};

        #draw green and/or blue line in histogram
        my $hitTopY =
          $self->{hist_ymax} -
          $self->{num_hits_by_base}->[$i] *
          $new_max /
          ( $max_hits > 0 ? $max_hits : 1000000 );
        my $includeTopY =
          $hitTopY -
          $self->{num_inclusions_by_base}->[$i] *
          $new_max /
          ( $max_hits > 0 ? $max_hits : 1000000 );
        if ( $self->{num_hits_by_base}->[$i] > 0 ) {
            $img->filledRectangle( $x, $hitTopY, $x2, $self->{hist_ymax} - 1,
                $green );
        }
        if ( $self->{num_inclusions_by_base}->[$i] > 0 ) {
            $img->filledRectangle( $x, $includeTopY, $x2, $hitTopY, $blue );
        }

        #draw colored line at bottom to represent conservedness
        my $totHits =
          $self->{num_hits_by_base}->[$i] +
          $self->{num_inclusions_by_base}->[$i];
        for ( my $j = 0 ; $j < scalar( @{ $self->{divisions} } ) ; $j++ ) {

            #find which division we're currently in
            if ( $totHits >= $self->{divisions}->[$j] ) {
                $img->filledRectangle(
                    $x, $self->{conservedness_stripe_yTop},
                    $x2, $self->{conservedness_stripe_yBot},
                    $divColors[$j]
                );
                if ( $i == 0 )    #start the first region
                {
                    $self->{conservedness_regions}->[$curRegion] = {};
                    $self->{conservedness_regions}->[$curRegion]->{start_base} =
                      $i;
                    $self->{conservedness_regions}->[$curRegion]->{start_x} =
                      $x;
                    $self->{conservedness_regions}->[$curRegion]->{division} =
                      $j;
                }
                elsif ( $j != $self->{conservedness_regions}->[$curRegion]
                    ->{division} )    #add a new region if our division changed
                {
                    $self->{conservedness_regions}->[$curRegion]->{end_base} =
                      $i - 1;
                    $self->{conservedness_regions}->[$curRegion]->{end_x} =
                      $x - 1;
                    $self->{conservedness_regions}->[ ++$curRegion ] = {};
                    $self->{conservedness_regions}->[$curRegion]->{start_base} =
                      $i;
                    $self->{conservedness_regions}->[$curRegion]->{start_x} =
                      $x;
                    $self->{conservedness_regions}->[$curRegion]->{division} =
                      $j;
                }
                elsif ( $i == $self->{query_length} - 1 )   #end the last region
                {
                    $self->{conservedness_regions}->[$curRegion]->{end_base} =
                      $i;
                    $self->{conservedness_regions}->[$curRegion]->{end_x} = $x;
                }
                last;
            }
        }
    }

    open( OUTFILE, ">$self->{graph_outfile}" )
      or return $errs
      . "; Makegraph2 unable to open output file $self->{graph_outfile} ($!)";
    binmode OUTFILE;
    print OUTFILE $img->png;
    close OUTFILE;
    return $errs;
}

#intended to be called by the client after creating a new blastgraph2 object
#return a string with HTML code for a map element corresponding to highly conserved and unique regions of the query
#no arguments
sub get_map_html {
    my $self = shift(@_);
    my $code = "<map name=\"graph2map\" id=\"graph2map\">\n";
    my ( $regionCoordStr, $queryRegionStr, $divisionBoundStr );
    my $i = 0;
    foreach my $region ( @{ $self->{conservedness_regions} } ) {
        $regionCoordStr = ""
          . ( $region->{start_x} ) . ","
          . $self->{conservedness_stripe_yTop} . ","
          . ( $region->{end_x} ) . ","
          . $self->{conservedness_stripe_yBot};
        $queryRegionStr = "[$region->{start_base} -> $region->{end_base}]";
        $divisionBoundStr =
          "($self->{divisions}[$region->{division}]"
          . ( ( $region->{division} > 0 )
            ? ", " . ( $self->{divisions}[ $region->{division} - 1 ] - 1 )
            : "+" )
          . ")";
        $code .=
"<area shape=\"rect\" coords=\"$regionCoordStr\" onmouseover=\"document.graph2form.graph2details.value='Query region $queryRegionStr: conservedness in $divisionBoundStr'\" alt=\"\" />\n";
        $i++;
    }
    return
        $code
      . "</map>\n<p />\n<form name=\"graph2form\" method=\"post\" action=\"\" enctype=\"application/x-www-form-urlencoded\">"
      . "\n<input type=\"text\" name=\"graph2details\" size=\"100\" value=\"Mouseover colored stripe at bottom of histogram\" />\n<p />\n";
}

###
1;    #do not remove
###
