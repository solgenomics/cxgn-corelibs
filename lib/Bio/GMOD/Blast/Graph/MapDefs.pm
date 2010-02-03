package Bio::GMOD::Blast::Graph::MapDefs;
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK =
    qw( $imgWidth $imgHeight $fontWidth $fontHeight $imgTopBorder
       $imgBottomBorder $imgLeftBorder $imgRightBorder $namesHorizBorder
       $imgHorizBorder $imgVertBorder $arrowHeight $halfArrowHeight
       $arrowWidth $halfArrowWidth $hspPosInit $hspArrowPad $hspHeight
       $formFieldWidth $tickHeight $bottomDataOffset $topDataOffset
       $kNumberOfPartitions $bucketBest $bucketZeroMax $bucketOneMax
       $bucketTwoMax $bucketThreeMax $bucketFourMax );

$imgWidth = 600;
$imgHeight = 300;

# [[ if GD changes it's small font these are screwed. ]]
$fontWidth = 6;
$fontHeight = 10;

$imgTopBorder = 25; # will be blank.
$imgBottomBorder = $fontHeight*2; # room for key.
$imgLeftBorder = 15; # will be blank.
$imgRightBorder = 40; # will contain "counts shown / counts in box".
$namesHorizBorder = 150; # for extra annotations.

# aliases.
$imgHorizBorder = $imgLeftBorder + $imgRightBorder;
$imgVertBorder = $imgTopBorder + $imgBottomBorder;

# to position the query within the top border.
$topDataOffset = 18;

# make room between hits and key at bottom.
$bottomDataOffset = 2;

$tickHeight = 2;

# graphical arrow height is actually +1;
# we take a central point and draw the
# arrow +/- $arrowHeight/2 around it.
$arrowHeight = 6;

$halfArrowHeight = int($arrowHeight/2);
# the arrowWidth is for the arrow's end bevels.
$arrowWidth = $halfArrowHeight;
$halfArrowWidth = int($arrowWidth/2);

# where we draw the first hit.
$hspPosInit = $imgTopBorder;

# space between hsp rows.
$hspArrowPad = 2;

# how many pixels per hsp row.
# +1 because of notes above re: arrow height.
$hspHeight = ($arrowHeight+1) + ($hspArrowPad*2);

# fixed ranges for the buckets.
# bucket zero has the best hits.
# bucket five has the worst hits.
$kNumberOfPartitions = 5;

$bucketBest = 0;
#previous: 1e-200, 1e-100, 1e-50, 1e-10, 1e0
$bucketZeroMax = 1e-200;
$bucketOneMax = 1e-50;
$bucketTwoMax = 1e-10;
$bucketThreeMax = 1e0;
$bucketFourMax = 1e1000; #this number should be as big as possible, as it causes most of our problems
