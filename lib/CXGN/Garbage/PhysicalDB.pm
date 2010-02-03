package CXGN::Garbage::PhysicalDB;

use CXGN::Garbage::BACDB;
use strict;

######################################################################
#
# Global variables.
#
######################################################################

my $users = {'ra97' => ['Robert', 'Ahrens'],
	     'yx25' => ['Yimin', 'Xu'],
	     'yw84' => ['Eileen', 'Wang']};

my $species = {'tomato' => 'Whatever Rod\'s BAC library is.'};
my $report_dir = '/home/httpd/sgn/support_data/physicalmapping/report/';
my $plate_summary = 'plate_summary_version_';
my $plate_report = 'deconvolution_report_plate_';
my $all_reports = 'all_deconvolution_report_version_';


######################################################################
#
# Methods.
#
######################################################################


sub get_version_number ($) {
    
    my ($dbh) = @_;
    my $stm = "SELECT version_id FROM overgo_version ORDER BY version_id DESC";
    my $sth = $dbh->prepare($stm);
    $sth->execute;
    my $version = $sth->fetchrow_array;
    $sth->finish();
    return ($version || 0);

}


sub start_new_version ($$) {

    my ($dbh, $user) = @_;
    my $user_sth = $dbh->prepare("SELECT user_id FROM users WHERE net_id=?");
    $user_sth->execute($user);
    my $userid = $user_sth->fetchrow_array;
    $user_sth->finish;
    $userid ||  die "ERROR: User with net id $user is not authorized to use this database.\n";
    my $version_sth = $dbh->prepare("INSERT INTO overgo_version SET updated_by=?");
    $version_sth->execute($userid);
    my $version = $version_sth->{'mysql_insertid'};
    $version_sth->finish;
    return $version;

}


sub report_dir () {

    return $report_dir;

}


sub plate_summary () {

    return $plate_summary;

}


sub all_reports () {

    return $all_reports;

}


sub plate_report () {

    return $plate_report;

}


sub test_users () {

    foreach my $usr (keys %$users) {
	print $usr . ": " . join(" ", @{$$users{$usr}}) . "\n";
    }

}


sub load_users ($) {

    my ($dbh) = @_;
    my $stm = "INSERT INTO users SET net_id=?, first_name=?, last_name=?";
    my $sth = $dbh->prepare($stm);
    foreach (keys %$users) {
	$sth->execute($_, $$users{$_}[0], $$users{$_}[1]);
    }
    $sth->finish;

}


sub get_userid ($$) {

    my ($dbh, $username) = @_;
    my $sth = $dbh->prepare("SELECT user_id FROM users WHERE net_id=?");
    $sth->execute($username);
    return $sth->fetchrow_array || "0";

}


sub load_species ($) {

    my ($dbh) = @_;
    my $stm = "INSERT INTO species SET short_name=?, long_name=?";
    my $sth = $dbh->prepare($stm);
    foreach (keys %$species) {
	$sth->execute($_, $$species{$_});
    }
    $sth->finish;

}


sub get_plate_id ($$) {

    my ($dbh, $plateno) = @_;
    my $sth = $dbh->prepare("SELECT plate_id FROM overgo_plates WHERE plate_number=?");
    $sth->execute($plateno);
    my $plate_id = $sth->fetchrow_array;
    # Hacked this out 'cause it's problematic.  Fix elegantly, please....
    #if (my $multipleid = $sth->fetchrow_array) {
	#die "WARNING: Multiple plate ID's deteced for plate $plateno.  ID's $plate_id, $multipleid both exist, maybe more.\n";
    #}
    $sth->finish;
    return $plate_id;
    
}


sub remove_plate_by_plate_id ($$) {

    my ($dbh, $pid) = @_;
    $dbh->do("DELETE FROM probe_markers WHERE overgo_plate_id=$pid");
    $dbh->do("DELETE FROM overgo_plates WHERE plate_id=$pid");

}


sub load_overgo_plate ($$$$) {

    my ($pdbh, $mdbh, $plateno, $platefile) = @_;
    my @cols = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H');
    my ($full_wells, $empty_wells) = 0;

    # Enter plate file.
    open PLATE, "<$platefile"
	or die "ERROR: Can't open $platefile.\n";
    my @plate = <PLATE>;
    close PLATE;
    chomp @plate;
    my $last = pop @plate;
    if ((split "\t", $last) > 1) {
	push @plate, $last; 
    }

    # Check for redundancy.
    my $plate_red_chk_sth = $pdbh->prepare("SELECT plate_id FROM overgo_plates WHERE plate_number=?");
    $plate_red_chk_sth->execute($plateno);
    if (my $pid = $plate_red_chk_sth->fetchrow_array) {
	print "ERROR: Plate $plateno already stored in Physical DB with plate_id=$pid.\n";
	while (1) {
	    print "[S]kip this plate, [R]eplace it or [A]bort?  ";
	    my $r = <STDIN>;
	    if ($r =~ /^s/i) { return; }
	    elsif ($r =~ /^r/i) { &remove_plate_by_plate_id($pdbh, $pid); last; }
	    elsif ($r =~ /^a/i) { die "Aborted after not overwriting plate $plateno.\n"; }
	    print "Please choose either 'S' or 'A'.  ";
	}
	# This is the place to implement a call to a "replace/update" function.
    }
					   
    my $row_max = $cols[@plate - 1];
    my $col_max = scalar (split "\t", $plate[0]);
    my $plate_size = $col_max * (scalar @plate);

    my $mrkr_id_stm = "SELECT marker_id FROM markers WHERE marker_name=?";
    my $mrkr_id_sth = $mdbh->prepare($mrkr_id_stm);
    
    my $probe_mrkr_sth = $pdbh->prepare("INSERT INTO probe_markers SET overgo_plate_id=?, overgo_plate_row=?, overgo_plate_col=?, marker_id=?");

    my $plate_sth = $pdbh->prepare("INSERT INTO overgo_plates SET plate_number=?, row_max=?, col_max=?, plate_size=?, empty_wells=0");
    $plate_sth->execute($plateno, $row_max, $col_max, $plate_size);    
    my $plate_id = $plate_sth->{'mysql_insertid'};
    $plate_sth->finish;

    my $row = 'A';
 
    foreach (@plate) {
	my @row = split "\t";
	(@row > 1) or next;
	if (@row != $col_max) {
	    &remove_plate_by_plate_id($pdbh, $plate_id);
	    die "ERROR processing plate $plateno: Incorrectly sized row:\n$_\nThis plate has not been entered into the database.\n";
} 
	my $col = 1;
	foreach my $mname (@row) {
	    if ($mname eq "_") {
		$empty_wells ++;
		next;
	    }
	    $full_wells ++;
	    if ($mname =~ /^(c[^\d]+)(\d+)(\w+)$/) {
		$mname = $1 . "-" . $2 . "-" . $3;
	    }
	    $mrkr_id_sth->execute($mname);
	    my $mrkrid = $mrkr_id_sth->fetchrow_array;
	    if (! $mrkrid) {
		&remove_plate_by_plate_id($pdbh, $plate_id);
		die "ERROR processing plate $plateno: Marker $mname not found in markers table of SGN database.\nThis plate has not been entered into the database.\n";
	    }		
	    $probe_mrkr_sth->execute($plate_id, $row, $col, $mrkrid);
	    $col ++;
	}
	$row ++;
    }

    if (($empty_wells + $full_wells) != 96) {
	&remove_plate_by_plate_id($pdbh, $plate_id);
	die "ERROR processing plate $plateno: Contains $full_wells markers and $empty_wells empty wells, which does not equal 96!\n";
    } elsif ($empty_wells) {
	my $ew_sth = $pdbh->prepare("UPDATE overgo_plates SET empty_wells=? WHERE plate_id=?");
	$ew_sth->execute($empty_wells, $plate_id);
	$ew_sth->finish;
    }
    
    $mrkr_id_sth->finish;
    $probe_mrkr_sth->finish;

}


sub generate_plate_report ($$$) {

    die "This is a legacy method.  Do not use it.\n";
    my ($dbh, $plateno, $version) = @_;
    my %report_stats = ('plateno' => $plateno, 'version' => $version);

    # Get data pertaining to this whole plate.
    my $plate_sth = $dbh->prepare("SELECT plate_id, row_max, col_max, empty_wells FROM overgo_plates WHERE plate_number=?");
    $plate_sth->execute($plateno);
    my ($pid, $rowmax, $colmax, $emptywells) = $plate_sth->fetchrow_array;
    $plate_sth->finish;
    if ($rowmax eq 'H' and $colmax == 12) {
	$report_stats{'platesize'} = 96;
    } else {
	die "WARNING: Non-standard sized plate.  Unequipped to deal with this.\n";
    }
    $report_stats{'emptywells'} = $emptywells;

    # Prepare STH's for querying the database.
    my $well_id_sth = $dbh->prepare("SELECT pm.overgo_probe_id, mm.marker_name FROM probe_markers AS pm INNER JOIN sgn.markers AS mm ON pm.marker_id=mm.marker_id WHERE pm.overgo_plate_id=? AND pm.overgo_plate_row=? AND pm.overgo_plate_col=?");
    my $matched_well_sth = $dbh->prepare("SELECT b.cornell_clone_name FROM overgo_associations AS oa INNER JOIN bacs AS b ON oa.bac_id=b.bac_id WHERE oa.overgo_probe_id=? AND version=?");
    my $unmatched_well_sth = $dbh->prepare("SELECT b.cornell_clone_name, ores.overgo_pool FROM overgo_results AS ores INNER JOIN bacs AS b ON ores.bac_id=b.bac_id WHERE ores.overgo_plate_id=? AND ores.version=? AND (ores.overgo_pool=? OR ores.overgo_pool=?)");

    # Process the plate, one well at a time.
    my $row = "A";
    my %plate;
    my %assocs;
    my %partmatches;
    $report_stats{'detectedempties'} = 0;
    $report_stats{'cleanmatches'} = 0;
    $report_stats{'ambiguousmatches'} = 0;
    while (1) {
	for (my $col=1; $col<=$colmax; $col++) {
	    $well_id_sth->execute($pid, $row, $col);
	    my ($probeid, $probename) = $well_id_sth->fetchrow_array;
	    if (!$probeid) {
		# Well is empty on plate.
		$plate{$row}{$col} = "_";
		$report_stats{'detectedempties'} ++;
		next;
	    }
	    $plate{$row}{$col} = $probename;
	    # See if any BAC's cleanly matched this well.
	    $matched_well_sth->execute($probeid, $version);
	    while (my $bacname = $matched_well_sth->fetchrow_array) {
		push @{$assocs{$probename}}, $bacname;
	    }
	    if ($assocs{$probename}) {
		$report_stats{'cleanmatches'} ++;
	    }
	    # Now check to see if any BAC's matched this well's
	    # pools at all.
	    if (! $assocs{$probename}) {
		$unmatched_well_sth->execute($pid, $version, $row, $col);
		while (my ($bacname, $pool) = $unmatched_well_sth->fetchrow_array) {
		    push @{$partmatches{$probename}{$pool}}, $bacname;
		}
		if (keys %{$partmatches{$probename}}) {
		    $report_stats{'ambiguousmatches'} ++;
		}
	    }
	}
	if ($row eq $rowmax) {
	    last;
	} else {
	    $row ++;
	}
    }

    ($report_stats{'detectedempties'} == $report_stats{'emptywells'})
	or print STDERR "WARNING: For plate $plateno, version $version - expected $emptywells empty wells, found $report_stats{'detectedempties'}.\n";

    $report_stats{'cleanhitsperwell'} = sprintf("%4f", ($report_stats{'cleanmatches'} / ($report_stats{'platesize'} - $report_stats{'emptywells'})));
    $report_stats{'totalhits'} = 2 * $report_stats{'cleanmatches'} + $report_stats{'ambiguousmatches'};
    $report_stats{'overallhitsperwell'} = sprintf("%4f", ($report_stats{'totalhits'} / ($report_stats{'platesize'} - $report_stats{'emptywells'})));

    # Finish all open STH's.
    $well_id_sth->finish;
    $matched_well_sth->finish;
    $unmatched_well_sth->finish;

    return (\%plate, \%assocs, \%partmatches, \%report_stats);

}


sub print_report ($$$$) {

    die "This is a legacy method.  Do not use it.\n";
    my ($rPlate, $rAssocs, $rPartial, $rReport) = @_;
    my $report = &report_dir . "dummy_report_plate_" . $$rReport{'plateno'} . "_version_" . $$rReport{'version'};
    open REPORT, ">$report"
	or die "ERROR: Can't write to file $report.\n";
    print STDERR "Written data for plate $$rReport{'plateno'}, version $$rReport{'version'} to $report.\n";

    # Calculate some statistics.
    my $platesize = $$rReport{'platesize'};
    my $clean_matches = $$rReport{'cleanmatches'};
    my $ambiguous_matches = $$rReport{'ambiguousmatches'};
    my $emptywells = $$rReport{'emptywells'};
    my $unmatched_wells = $platesize - $clean_matches - $ambiguous_matches - $emptywells;

    # Print SUMMARY.
    print REPORT "Deconvolution report for plate $$rReport{'plateno'}, version $$rReport{'version'}.\n";
    print REPORT "\n========================================\n\n";
    print REPORT "SUMMARY:\n\n";
    print REPORT "Number of wells which cleanly match one or more BAC's: " . $clean_matches . "\n";
    print REPORT "Number of wells which ambiguously match one or more BAC's: " . $ambiguous_matches . "\n";
    print REPORT "Number of wells which matched no BAC's: " . $unmatched_wells . "\n";
    print REPORT "Number of empty wells: " . $emptywells . "\n";
    print REPORT "----------------------\n";
    print REPORT "TOTAL NUMBER OF WELLS: " . $platesize . "\n";
    print REPORT "\nAverage number of cleanly matched BAC's per (non-empty) well: " . $$rReport{'cleanhitsperwell'} . "\n";
    print REPORT "Average number of BAC's matching this plate per (non-empty) well: " . $$rReport{'overallhitsperwell'} . "\n";
    print REPORT "\n========================================\n\n";

    # Prepare specifics.
    my @wellformed;
    my @partial;
    my @unmatched;
    foreach my $row (sort keys %$rPlate) {
	foreach my $col (sort keys %{$$rPlate{$row}}) {
	    if (! defined $$rPlate{$row}{$col}) {
		die "ERROR: Well $row, $col not defined on plate $$rReport{'plateno'}.\n";
	    }
	    if ($$rPlate{$row}{$col} eq "_") {
		next;
	    } elsif (${$rAssocs}{$$rPlate{$row}{$col}}) {
		print STDERR "Made it here.\n";
		push @wellformed, "($row, $col) $$rPlate{$row}{$col}: " . join(", ", @{$$rAssocs{$$rPlate{$row}{$col}}}) . "\n";
	    } elsif ($$rPartial{$$rPlate{$row}{$col}}) {
		foreach my $pool (keys %{$$rPartial{$$rPlate{$row}{$col}}}) {
		    push @partial, "$$rPlate{$row}{$col} [pool $pool]: " . join(", ", @{$$rPartial{$$rPlate{$row}{$col}}{$pool}}) . "\n";
		}
	    } else {
		push @unmatched, "($row, $col) $$rPlate{$row}{$col}\n";
	    }
	}

    }

    # Now print this information.
    print REPORT "WELL-FORMED ASSOCIATIONS:\n\n";
    foreach (@wellformed) {
	print REPORT $_;
    }
    print REPORT "\n========================================\n\n";
    print REPORT "PARTIALLY MATCHED WELLS:\n\n";
    foreach(@partial) {
	print REPORT $_;
    }
    print REPORT "\n========================================\n\n";
    print REPORT "UNMATCHED WELLS:\n\n";
    foreach (@unmatched) {
	print REPORT $_;
    }
    close REPORT;

}


sub report_plate ($$) {

    my ($dbh, $rPlate) = @_;
    my $default_number_of_pools = 20;

    # Prepare marker_name sth.
    my $probe_stats_sth = $dbh->prepare("SELECT m.marker_name, pm.overgo_plate_row, pm.overgo_plate_col FROM probe_markers AS pm INNER JOIN sgn.markers AS m ON pm.marker_id=m.marker_id WHERE pm.overgo_probe_id=?");

    # Preprocess clone <--> well associations to count and order them.
    my %hitsperprobe;
    my $matchedwells = 0;
    foreach my $pid (keys %{$$rPlate{'matched_probes'}}) {
	$hitsperprobe{$pid} = scalar @{$$rPlate{'matched_probes'}{$pid}};
	$matchedwells ++;
    }

    # Open REPORT file for this plate.
    my $report = &report_dir() . &plate_report() . $$rPlate{'plateno'} . "_version_" . $$rPlate{'version'};

    open REPORT, ">$report"
	or die "ERROR: Can't write to $report.\n";

    # Print SUMMARY.
    print REPORT "Deconvolution report for plate $$rPlate{'plateno'}, version $$rPlate{'version'}.\n";
    print REPORT "\n========================================\n\n";
    print REPORT "SUMMARY:\n\n";
    print REPORT "Number of wells which cleanly match one or more BAC's: " . $matchedwells . "\n";
    print REPORT "Number of wells which ambiguously match one or more BAC's: " . ($$rPlate{'plate_size'} - $matchedwells - $$rPlate{'empty_wells'}) . "\n";
    #print REPORT "Number of wells which matched no BAC's: " . ($$rPlate{'plate_size'} - $$rPlate{'good_matches'}) . "\n";
    print REPORT "Number of empty wells: " . $$rPlate{'empty_wells'} . "\n";
    print REPORT "TOTAL NUMBER OF WELLS: " . $$rPlate{'plate_size'} . "\n";
    print REPORT "----------------------\n";
    print REPORT "Number of BAC's which cleanly matched this plate: $$rPlate{'good_matches'}.\n";
    print REPORT "Number of BAC's which ambiguously (multiple rows or columns) matched this plate: $$rPlate{'bad_matches'}.\n";
    print REPORT "Number of BAC's which matched only a single pool on this plate: $$rPlate{'single_matches'}.\n";
    print REPORT "Number of BAC's which matched either multiple row pools or multiple column pools: $$rPlate{'onedimensional_matches'}.\n";
    print REPORT "TOTAL NUMBER OF BACS MATCHING THIS PLATE: " . ($$rPlate{'good_matches'} + $$rPlate{'bad_matches'} + $$rPlate{'single_matches'} + $$rPlate{'onedimensional_matches'}) . "\n";
    print REPORT "----------------------\n";
    print REPORT "Average number of BAC's cleanly matching each nonempty well: " . sprintf("%4g", ($$rPlate{'good_matches'} / ($$rPlate{'plate_size'} - $$rPlate{'empty_wells'}))) . "\n";
    print REPORT "Average number of BAC's cleanly matching each well which was cleanly matched: " . sprintf("%4g", ($$rPlate{'good_matches'} / $matchedwells)) . "\n";
    print REPORT "Average number of BAC's matching each pool on this plate: " . sprintf("%4g", (($$rPlate{'good_matches'} + $$rPlate{'bad_matches'} + $$rPlate{'single_matches'} + $$rPlate{'onedimensional_matches'}) / $default_number_of_pools)) . "\n";
    print REPORT "\n========================================\n\n";

    print REPORT "WELL-FORMED ASSOCIATIONS:\n(In descending order of the number of BAC's they matched.)\n";
    foreach my $pid (sort {$hitsperprobe{$b} <=> $hitsperprobe{$a}} keys %hitsperprobe) {
	$probe_stats_sth->execute($pid);
	my ($probename, $r, $c) = $probe_stats_sth->fetchrow_array;
	print REPORT "($r, $c) $probename [$hitsperprobe{$pid}]: " . join(", ", @{$$rPlate{'matched_probes'}{$pid}}) . "\n";
    }
    print REPORT "\n========================================\n\n";
    print REPORT "BACS AMBIGUOUSLY MATCHING THIS PLATE:\n\n";
    foreach my $am_bac (keys %{$$rPlate{'ambiguous_bacs'}}) {
	print REPORT "$am_bac : " . join(", ", @{$$rPlate{'ambiguous_bacs'}{$am_bac}});
	my @tentative_matches_list = ();
	foreach my $pid (@{$$rPlate{'tentative_matches'}{$am_bac}}) {
	    $probe_stats_sth->execute($pid);
	    my ($probename, $r, $c) = $probe_stats_sth->fetchrow_array;
	    push @tentative_matches_list, "$probename [$r,$c]";
	}
	print REPORT " => " . join(", ", @tentative_matches_list) . "\n";
    }
    print REPORT "\n========================================\n\n";
    print REPORT "BACS MATCHING ONLY A SINGLE WELL ON THIS PLATE:\n\n";
    foreach my $sngl_bac (sort {$$rPlate{'single_well_bacs'}{$a} <=> $$rPlate{'single_well_bacs'}{$b}} keys %{$$rPlate{'single_well_bacs'}}) {
	print REPORT "$sngl_bac : $$rPlate{'single_well_bacs'}{$sngl_bac}\n";
    }
    print REPORT "\n========================================\n\n";
    close REPORT;

    $probe_stats_sth->finish;

    if ($$rPlate{'total_bacs'} != $$rPlate{'processed_bacs'}) {
	print STDERR "WARNING: On plate $$rPlate{'plateno'}, version $$rPlate{'version'}: considered a total of $$rPlate{'total_bacs'} BACs but only processed $$rPlate{'processed_bacs'} of them.\n";
    }

}


sub deconvolute_plate ($$;$) {

    my ($dbh, $plateno, $version) = @_;
    my %report = ('plateno' => $plateno,
		  'total_bacs' => 0,
		  'processed_bacs' => 0,
		  'good_matches' => 0,
		  'bad_matches' => 0,
		  'single_matches' => 0,
		  'onedimensional_matches' => 0);

    # Get version.
    my $version ||= &get_version_number($dbh);
    $report{'version'} = $version;

    # Get plate information.
    my $plate_sth = $dbh->prepare("SELECT plate_id, row_max, col_max, empty_wells, plate_size FROM overgo_plates WHERE plate_number=?");
    $plate_sth->execute($plateno);
    my ($pid, $rowmax, $colmax, $empty, $psize) = $plate_sth->fetchrow_array;
    # Ideally would error check for uniqueness here.
    $plate_sth->finish;
    $report{'empty_wells'} = $empty;
    $report{'plate_size'} = $psize;

    # Read BAC <--> pool associations in.
    my $pool_sth = $dbh->prepare("SELECT r.overgo_pool, r.bac_id FROM overgo_results AS r INNER JOIN bacs AS b ON r.bac_id=b.bac_id WHERE r.version=? AND r.overgo_plate_id=? AND r.bac_id IS NOT NULL AND b.bad_clone=0 ORDER BY r.bac_id");
    $pool_sth->execute($version, $pid);
    my $last_bacid=0;
    my @rows=();
    my @cols=();

    # STH's for INSERTING data about probe <--> BAC associations.
    my $overgo_assoc_sth = $dbh->prepare("INSERT INTO overgo_associations SET version=?, overgo_probe_id=?, bac_id=?, plausible=0");
    my $overgo_tentative_sth = $dbh->prepare("INSERT INTO tentative_overgo_associations SET version=?, overgo_probe_id=?, bac_id=?, conflict_type=?");
    my $ta_conflict_sth = $dbh->prepare("INSERT INTO tentative_association_conflict_groups SET conflict_id=?, tentative_assoc_id=?"); 
    my $overgo_probe_id_sth = $dbh->prepare("SELECT overgo_probe_id FROM probe_markers WHERE overgo_plate_id=? AND overgo_plate_row=? AND overgo_plate_col=?");

    while (my ($pool, $bacid) = $pool_sth->fetchrow_array) {

	$report{'total_bacs'} ++;

	if ($bacid == $last_bacid) {

	    # Keep adding pools for current BAC.
	    if ($pool =~ /^\d+$/) {
		push @cols, $pool;
	    } else {
		push @rows, $pool;
	    }

	} elsif ($last_bacid == 0) {

	    # Initialization case.
	    if ($pool =~ /^\d+$/) {
		push @cols, $pool;
	    } else {
		push @rows, $pool;
	    }
	    $last_bacid = $bacid;

	} else {

	    # Process old BAC.
	    my $bac_name = BACDB::BAC_CUID_from_ID($last_bacid);
	    if ((@rows == 1) && (@cols == 1)) {
		# This is the ideal association.  Therefore
		# we log it in the OVERGO_ASSOCIATIONS table.
		$report{'good_matches'} ++;
		$overgo_probe_id_sth->execute($pid, $rows[0], $cols[0]);
		my $probe_id = $overgo_probe_id_sth->fetchrow_array;
		if (! $probe_id) {
		    print REPORT "WARNING: No probe found for plate $plateno, row $rows[0], column $cols[0], which should match BAC $bac_name";
		} else {
		    $overgo_assoc_sth->execute($version, $probe_id, $last_bacid);
		    push @{$report{'matched_probes'}{$probe_id}}, $bac_name;
		}
		$report{'processed_bacs'} += 2;
	    } elsif (@rows && @cols) {
		# This is an ambiguous case, which is logged separately
		# in the tables TENTATIVE_OVERGO_ASSOCIATIONS and
		# TENTATIVE_ASSOCIATION_CONFLICT_GROUPS.
		my @taids = ();
		my @tent_probe_ids = ();
		my $conflict_size = (scalar @rows) + (scalar @cols);
		foreach my $r (@rows) {
		    foreach my $c (@cols) {
			$overgo_probe_id_sth->execute($pid, $r, $c);
			my $probe_id = $overgo_probe_id_sth->fetchrow_array;
			if (! $probe_id) {
			    print REPORT "WARNING: No probe found for plate $plateno, row $r, column $c, which should match BAC $bac_name";
			} else {
			    $overgo_tentative_sth->execute($version, $probe_id, $last_bacid, $conflict_size);
			    push @taids, $overgo_tentative_sth->{'mysql_insertid'};
			    push @tent_probe_ids, $probe_id;
			}
		    }
		}
		# Now insert the unique tentative assoc ID's generated by 
		# entering the tentative associations into the table
		# TENTATIVE_ASSOCIATION_CONFLICT_GROUPS.  For this, we use
		# the tentative_assoc_id of the first association as the
		# overall int id for that conflict as it is guaranteed to
		# be unique for this particular association, version, etc.
		foreach (@taids) {
		    $ta_conflict_sth->execute($taids[0], $_);
		}
		# This is an imperfect case so we REPORT it.
		$report{'bad_matches'} += $conflict_size; # Used to be ++.
		push @{$report{'ambiguous_bacs'}{$bac_name}}, @rows, @cols;
		push @{$report{'tentative_matches'}{$bac_name}}, @tent_probe_ids;
		$report{'processed_bacs'} += $conflict_size;
	    } elsif ((@rows == 1) || (@cols == 1)) {
		# This is the next-worse-case: There aren't even tentative
		# associations to be investigated, but at least the BAC
		# is only associated with one pool, meaning it might 
		# later be subjected to some further analysis.
		$report{'single_matches'} ++;
		$report{'single_well_bacs'}{$bac_name} = ($rows[0] || $cols[0]);
	    } elsif (@rows || @cols) {
		$report{'onedimensional_matches'} += (scalar @rows) + (scalar @cols);
		$report{'processed_bacs'} += ((scalar @rows) + (scalar @cols));
	    }
	    # Initialize the new BAC.
	    @rows = ();
	    @cols = ();
	    $last_bacid = $bacid;
	    if ($pool =~ /^\d+$/) {
		push @cols, $pool;
	    } else {
		push @rows, $pool;
	    }

	}

    }

    $pool_sth->finish;
    $overgo_assoc_sth->finish;
    $overgo_probe_id_sth->finish;
    $overgo_tentative_sth->finish;
    $ta_conflict_sth->finish;

    &update_plate_summary(\%report);
    &report_plate($dbh, \%report);

}


sub clear_overgo_associations ($$) {

    # Clears out the OVERGO_ASSOCIATIONS and TENTATIVE_OVERGO_ASSOCIATIONS
    # tables of data for a given version.
    my ($dbh, $version) = @_;
    $dbh->do("DELETE FROM overgo_associations WHERE version=$version");
    $dbh->do("DELETE FROM tentative_overgo_associations WHERE version=$version");

}


sub update_plate_summary ($) {

    # Updates this plate's information to the "summary" file stored in
    # the report directory.
    my ($rReport) = @_;
    my $summaryfile = &report_dir() . &plate_summary() . $$rReport{'version'};
    my @summary;

    # Read in summary file.
    if (-f $summaryfile) {
	open SUM_IN, "<$summaryfile"
	    or die "ERROR: Can't read from $summaryfile.\n";
	@summary = <SUM_IN>;
	close SUM_IN;
    }

    # Search for summary for this plateno.  Either replace it
    # or append it.
    my %summarydata = ();
    foreach (@summary) {
	if (/^(\d+)\t(.+)$/) {
	    $summarydata{$1} = $2;
	} elsif (/^\s*$/) {
	    # This clause handles accidental "blank" line at end.
	    next;
	} else {
	    die "ERROR: Ill-formed line in summary file $summaryfile:\n$_";
	}
    }
    $summarydata{"0"} = "Cleanly matched\tAmbiguous\tEmpty\tBAC matches\tAmbiguous BAC matches\tSingle BAC matches\tTotal BAC's"; 
    my $matchedwells = scalar keys %{$$rReport{'matched_probes'}};
    $summarydata{$$rReport{'plateno'}} = $matchedwells . "\t" . ($$rReport{'plate_size'} - $matchedwells - $$rReport{'empty_wells'}) . "\t" . $$rReport{'empty_wells'} . "\t" . $$rReport{'good_matches'} . "\t" . $$rReport{'bad_matches'} . "\t" . $$rReport{'single_matches'} . "\t" . ($$rReport{'good_matches'} + $$rReport{'bad_matches'} + $$rReport{'single_matches'}); 

    # Print the new summary file.
    open SUM_OUT, ">$summaryfile"
	or die "ERROR: Can't write to $summaryfile.\n";
    foreach (sort {$a <=> $b} keys %summarydata) {
	print SUM_OUT $_ . "\t" . $summarydata{$_} . "\n";
    }
    close SUM_OUT;

}


return 1;
