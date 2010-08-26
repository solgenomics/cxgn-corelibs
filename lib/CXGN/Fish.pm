package CXGN::Fish;
use strict;
use warnings;

use CXGN::Page::FormattingHelpers;

sub find_file {
  my ($conf, $fn) = @_;
  unless ($conf && $fn) {
    die (__PACKAGE__ . "find_file() called without a conf object or a file name");
  }
  $conf->get_conf('static_datasets_url')."/images/fish/$fn";
}

# Takes a DBH and a BAC id, returns a big html string for displaying
sub fish_image_html_table {
  my ($dbh, $bacid) = @_;
  my @exps;
  my $fish_html = '';
  unless ($bacid =~ m/\d+/) {
    die ("invalid BAC id $bacid");
  }
  my ($fish_arm_count) = $dbh->selectrow_array("SELECT COUNT(DISTINCT chromo_arm) FROM fish_result WHERE clone_id = $bacid");
  my $fish_results = $dbh->selectall_arrayref("SELECT fish_result_id,
                                                      experiment_name,
                                                      percent_from_centromere,
                                                      chromo_arm
                                                 FROM fish_result
                                         NATURAL JOIN fish_karyotype_constants
                                                WHERE clone_id = $bacid");

  my $fish_aggregates = $dbh->selectall_arrayref("SELECT avg (percent_from_centromere),
                                                         stddev (percent_from_centromere),
                                                         avg (percent_from_centromere)*arm_length,
                                                         stddev (percent_from_centromere)*arm_length,
                                                         arm_length,
                                                         chromo_num,
                                                         chromo_arm
                                                    FROM fish_result
                                            NATURAL JOIN fish_karyotype_constants
                                                   WHERE clone_id = $bacid
                                                GROUP BY arm_length, chromo_num, chromo_arm");

  # this is not the most elegant solution, but it was quick, and nothing else seemed to work properly
  my $fish_aggregates_2 = $dbh->selectall_arrayref("SELECT stddev (percent_from_centromere),
                                                         stddev (percent_from_centromere)*arm_length
                                                         FROM fish_result
                                            NATURAL JOIN fish_karyotype_constants
                                                   WHERE clone_id = $bacid and experiment_name not like 'correction'
                                                GROUP BY arm_length");

  if (@$fish_results) {
      my $img_table = {};
      my $xls_table = {};
      my %result_percent_dist;
      my %result_um_dist;
      my $corrected = 0;
      
      # Collect the following for each fish_result:
      # (1) the percent-distance-from-centromere for each experiment
      # (2) image name/id pairs into hashes, with each hash associated
      #     with the experiment name.
      foreach my $fish_result (@$fish_results) {
	  my ($rid, $exp, $distp, $arm) = @$fish_result;
	  push @exps, $exp;
	  $result_percent_dist{$exp} = sprintf("%3.1F%%", $distp*100);
	  if ($fish_arm_count>1) {
	      $result_percent_dist{$exp}.=" of arm $arm";
	  }


	  if ($exp ne 'correction') {
	      my $files = $dbh->selectall_arrayref("SELECT image_id, original_filename || file_ext
                                              FROM sgn.fish_result_image
                                              JOIN metadata.md_image USING (image_id)
                                             WHERE fish_result_id = $rid");
	      # For each image filename, lop off the experiment name, then
	      # remove the extension, then capitalize it, then make an href that
	      # points to it, and store that in a hash of hashes whose keys
	      # are the experiment id.
	      foreach my $file (@$files) {
		  my ($iid, $fn) = @$file;
		  if ($fn =~ m/jpg$/i) {
		      $fn =~ s/$exp[\s_]+//;
		      $fn =~ s/.[^.]*$//;
		      $fn = ucfirst ($fn);
		      $img_table->{$exp}{$fn} = $iid;
		  } elsif ($fn =~ m/xls$/i) {
		      $xls_table->{$exp} = [$fn, $iid];
		  } # ignore other files (we don't have any at present).
	      }
	  }
	  else { $corrected = 1 }
      }
      
      # If we're here and there are no images, something's wrong, but the user doesn't need
      # to see that.
      if (%$img_table) {
	  # The following few lines perform a lexicographic sort on ordered pairs
	  # encoded as "x-y", instead of (x, y).
	  # Helper functions:
	  # Returns true if every argument is non-false.
	  sub every { $_ || return 0 for @_; 1 }
	  # We define a default sort helper function that does what cmp does.
	  my $cmp = sub { my ($ay, $be) = @_; $ay cmp $be };
	  # If all the experiment names are comparable in the desired way, use a
	  # comparison subroutine that puts 99-1 /before/ 100-1.
	  if (every map { $_ =~ m/\d+-\d+/ } @exps) {
	      $cmp = sub { my ($ay, $be) = @_; $ay =~ s/\d+-//; $be =~ s/\d+-//; $ay cmp $be; };
	  }
	  # Now go over the experiments in the desired sort order,
	  # accumulating an HTML table whose rows are links
	  # to the images plus whatever extra data we want to display.
	  my $table = ();
	  foreach my $expnm (sort { $cmp->($a, $b) } @exps) {
	      my $row = ();
	      
	      # correction factor; does not have associated images
	      if ($expnm eq 'correction') {
		  push @$row, "$expnm <a href=\"#correction\" style=\"font-size: smaller; vertical-align: text-top; color: blue; font-style: italic;\">2</a>";
		  push (@$row, "", "", "");
	      }

	      else {
		  # FIXME: if we ever get a second FISH sumitter, make this do something useful.
		  push @$row, "$expnm <a href=\"#fish_attrib1\" style=\"font-size: smaller; vertical-align: text-top; color: blue; font-style: italic;\">1</a>";
		  
		  # Image columns
		  foreach my $imgnm (sort keys %{$img_table->{$expnm}}) {
		      push @$row,
		      "<a href=\"/maps/physical/view_fish.pl?id=$bacid&amp;image_id=" . $img_table->{$expnm}{$imgnm} . "\">$imgnm</a>";
		  }

		  # Miscellaneous extra per-row data.
		  #XXX: uncomment for excel files, when download-file.pl is available 
		  # push @$row, "<a href=\"/maps/physical/download-file.pl?fgrp=Fish&amp;id=".$xls_table->{$expnm}[1]."\">".$xls_table->{$expnm}[0]."</a>";
	      }

	      push @$row, $result_percent_dist{$expnm};
	      push @$table, $row;
	  }

      my $fish_tail;
      my ($avg, $dev, $avgd, $devd, $arm_length, $chromo_num, $chromo_arm);
      if ($fish_arm_count == 1) {
	if ($fish_aggregates) {
	  ($avg, $dev, $avgd, $devd, $arm_length, $chromo_num, $chromo_arm) = @{$fish_aggregates->[0]};
          ($dev,$devd) = @{$fish_aggregates_2->[0]};
	  push @$table, ['<strong>Mean&plusmn;sd</strong>', undef,undef,undef, sprintf ("%3.1F%%&plusmn;%3.1F%%", $avg*100, $dev*100)];
	}
	if ($avgd && $devd && $arm_length && $chromo_arm && $chromo_num) {
	  $fish_tail .= sprintf ("<br /><span>Given an estimated length of %3.1F&micro;m for chromosome %s%s and the mean percentage above, this BAC is approximately %3.1F&micro;m&plusmn;%3.1F&micro;m from the chromosome centromere.</span><br />", $arm_length, $chromo_num, $chromo_arm, $avgd, $devd);
	}
      } else {
	my %msg;
	map {
	  ($avg, $dev, $avgd, $devd, $arm_length, $chromo_num, $chromo_arm) = @{$_};
	  $msg{$chromo_arm} = sprintf ("The mean distance on the %s arm is %3.1F%&plusmn;%3.1F from the centromere (%3.1F&micro;m&plusmn;%3.1F&micro;m).", $chromo_arm, $avg*100, $dev*100, $avgd, $devd);
	} @$fish_aggregates;
	$fish_tail .= "<br /><span>This BAC appears on both chromosome arms. $msg{P} $msg{Q}</span><br />";
      }
      #$fish_tail .= "!!!!!".$attribs{fish_attrib1}."<<<";
      # FIXME: if we ever get a second FISH sumitter, make this do something useful.
      $fish_tail .= "<br/><a id=\"fish_attrib1\" style=\"font-style: italic;\"><span style=\"font-size: smaller; vertical-align: text-top; color: blue; margin-right: .5em;\">1</span>Experiment conducted in the lab of Stephen Stack at Colorado State University.</a><br/>";
	  
	  if ($corrected == 1) {
	      # BAC name may need to be fixed in the future..
	      my $text = "The position of this BAC has been adjusted slightly to reflect its location relative to the typical position of marker BAC LE_HBa0234C10.";
	      $fish_tail .= "<br/><a id=\"correction\" style=\"font-style: italic;\"><span style=\"font-size: smaller; vertical-align: text-top; color: blue; margin-right: .5em;\">2</span>$text<br/>";
	  }
	  
      $fish_html .= 
	CXGN::Page::FormattingHelpers::columnar_table_html
	(headings=>['SC Spread ID', 'Images', undef, undef, 'Distance from centromere <br />(percentage of arm length)'], data=>$table) . $fish_tail;
    }
  }
  return $fish_html;
}

1;
