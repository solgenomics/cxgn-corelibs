package CXGN::Garbage::BACDB;

use strict;
use CXGN::Garbage::local_db_link;
use CXGN::Garbage::PhysicalDB;

my $cornell_prefix = 'P';
my $arizona_prefix = 'LE_HBa';
my $stop_col = 'I';
my $stop_filter = 'h';
my $dbh;
my $bac_sth = {};
my $konnex = {'db' => 'physical', 'user' => 'robert'};

my ($filter, $filter_shift) = &initialize_filters();


sub connect_BAC_db () {

    $dbh = local_db_link::connect_db($konnex);
    $$bac_sth{'user_id_by_net_id'} = $dbh->prepare("SELECT user_id FROM users WHERE net_id=?");
    $$bac_sth{'cu_name_from_id'} = $dbh->prepare("SELECT cornell_clone_name FROM bacs WHERE bac_id=?");
    $$bac_sth{'id_from_cu_name'} = $dbh->prepare("SELECT bac_id FROM bacs WHERE cornell_clone_name=?");
    $$bac_sth{'id_from_az_name'} = $dbh->prepare("SELECT bac_id FROM bacs WHERE arizona_clone_name=?");
    $$bac_sth{'insert_bac'} = $dbh->prepare("INSERT INTO bacs SET cornell_clone_name=?, arizona_clone_name=?");
    $$bac_sth{'set_bad_clone'} = $dbh->prepare("UPDATE bacs SET bad_clone=1 WHERE bac_id=?");
    $$bac_sth{'repeal_bad_clone'} = $dbh->prepare("UPDATE bacs SET bad_clone=0 WHERE bac_id=?");
    $$bac_sth{'bac_ctg_id_from_name'} = $dbh->prepare("SELECT contig_id FROM bac_contigs WHERE contig_name=? AND fpc_version=?");
    $$bac_sth{'insert_bac_ctg'} = $dbh->prepare("INSERT INTO bac_contigs SET contig_name=?, fpc_version=?");
    $$bac_sth{'insert_bac_assoc'} = $dbh->prepare("INSERT INTO bac_associations SET bac_id=?, contig_id=?");
    $$bac_sth{'current_fpc_version'} = $dbh->prepare("SELECT fpc_version FROM fpc_version ORDER BY fpc_version DESC");
    return $dbh;

}


sub finish () {

    foreach (keys %$bac_sth) {
	$$bac_sth{$_}->finish;
    }
  local_db_link::disconnect_db($dbh);

}


sub initialize_filters () {

    # Prepare the data for filter A:
    my %filter = ();
    my $val = 0;
    for (my $row=1; $row<7; $row ++) {
	my $col='A';
	while ($col ne $stop_col) {
	    $filter{($row . $col)} = ++ $val;
	    $col ++;
	}
    }
    
    # Handle other filters.
    my %filter_shift = ();
    my $shift = 0;
    my $f='a'; 
    while ($f ne $stop_filter) {
	$filter_shift{$f} = $shift;
	$shift += 48;
	$f ++;
    }

    return (\%filter, \%filter_shift);

}


sub insert_BAC ($) {

    my ($name) = @_;
    if ($name) {
	print "BACDB::insert_BAC WARNING: Attempting to insert a BAC, $name, which is muy suspicious, given that we're now inserting them en masse.\n";
	return;
    }
    my ($cu_name, $az_name);
    if ($name =~ /^$cornell_prefix(\d\d\d)(\w\d\d)$/) {
	$cu_name = $name;
	$az_name = $arizona_prefix . sprintf("%4d", $1) . $2;
    } elsif ($name =~ /^$arizona_prefix(\d\d\d\d)(\w\d\d)$/) {
	$cu_name = $cornell_prefix . sprintf("%3d", $1) . $2;
	$az_name = $name;
    } else {
	print STDERR "WARNING: BAC name $name not of CU or AZ type.  Ignored.\n";
	return;
    }
    $$bac_sth{'insert_bac'}->execute($cu_name, $az_name);
    return $$bac_sth{'insert_bac'}->{'mysql_insertid'};

}


sub get_BAC_id ($) {

    my ($name) = @_;
    my $bac_id;
    if ($name =~ /^$cornell_prefix\S+/) {
	$$bac_sth{'id_from_cu_name'}->execute($name);
	$bac_id = $$bac_sth{'id_from_cu_name'}->fetchrow_array;
    } elsif ($name =~ /^$arizona_prefix\S+/) {
	$$bac_sth{'id_from_az_name'}->execute($name);
	$bac_id = $$bac_sth{'id_from_az_name'}->fetchrow_array;
    } else {
	print STDERR "WARNING: Trying to get ill-named BAC: $name.\n";
    }
    $bac_id ||= &insert_BAC($name);
    return $bac_id;

}


sub BAC_CUID_from_filter ($$$) {

    my ($f_code, $spot, $position) = @_;
    $f_code = lc $f_code;
    if (not defined $$filter_shift{$f_code}) {
	print STDERR "WARNING: Filter $f_code not defined.\n";
	return "";
    }
    if (not $$filter{$spot}) {
	print STDERR "WARNING: Spot position $spot unknown.\n";
	return "";
    }
    my $cuname;
    if ($position =~ /(\w)(\d+)/) {
	my ($p_prefix, $p_suffix) = ($1, $2);
	$cuname = $cornell_prefix . 
	    sprintf("%03d", ($$filter{$spot} + $$filter_shift{$f_code})) . 
		$p_prefix . sprintf("%02d", $p_suffix);
    } else {
	print STDERR "WARNING: Badly formed position spec $position.\n";
	$cuname = "";
    }
    return $cuname;

}


sub BAC_AZID_from_filter ($$$) {

    my ($f_code, $spot, $position) = @_;
    $f_code = lc $f_code;
    defined ($$filter_shift{$f_code})
	or die "ERROR: Filter $f_code not defined.\n";
    $$filter{$spot} or die "ERROR: Spot position $spot unknown.\n";
    my $azname;
    if ($position =~ /(\w)(\d+)/) {
	my ($p_prefix, $p_suffix) = ($1, $2);
	$azname = $arizona_prefix . 
	    sprintf("%04d", ($$filter{$spot} + $$filter_shift{$f_code})) . 
		$p_prefix . sprintf("%02d", $p_suffix);
    } else {
	print STDERR "WARNING: Badly formed position spec $position.  Skipping this BAC.\n";
	$azname = "";
    }
    return $azname;

}


sub dump_filter ($) {

    my ($fcode) = @_;
    foreach (keys %$filter) {
	print $_ . ":" . ($$filter{$_} + $$filter_shift{$fcode}) . "\n";
    }

}


sub BAC_CUID_from_ID ($) {

    my ($id) = @_;
    $$bac_sth{'cu_name_from_id'}->execute($id);
    my $cuname = $$bac_sth{'cu_name_from_id'}->fetchrow_array;
    return $cuname;

}


sub BAC_AZID_from_ID ($) {

    my ($id) = @_;
    $$bac_sth{'az_name_from_id'}->execute($id);
    my $azname = $$bac_sth{'az_name_from_id'}->fetchrow_array;
    return $azname;

}


sub set_bad_clone ($) {

    my ($ident) = @_;
    my $id;
    if ($ident =~ /^\d+$/) {
	$id = $ident;
    } else {
	$id = &get_BAC_id($ident);
    }
    if ($id) {
	$$bac_sth{'set_bad_clone'}->execute($id);
    } else {
	print STDERR "set_bad_clone WARNING: No ID found for BAC with identifier $ident.\n";
    }

}


sub get_bac_ctg_id ($$) {

    my ($ctg_name, $fpc_version) = @_;
    $$bac_sth{'bac_ctg_id_from_name'}->execute($ctg_name, $fpc_version);
    my $ctg_id = $$bac_sth{'bac_ctg_id_from_name'}->fetchrow_array;
    if ($ctg_id) {
	return $ctg_id;
    } else {
	$$bac_sth{'insert_bac_ctg'}->execute($ctg_name, $fpc_version);
	return $$bac_sth{'insert_bac_ctg'}->{'mysql_insertid'};
    }

}


sub insert_bac_association ($$) {
    
    my ($bac_id, $ctg_id) = @_;
    $$bac_sth{'insert_bac_assoc'}->execute($bac_id, $ctg_id);

}


sub get_fpc_version (;$$) {

    my ($user, $date, $path) = @_;
    my $fpcversion;

    if ($user && $date) {
	my $this_fpc_sth = $dbh->prepare("SELECT fpc_version FROM fpc_version WHERE updated_on=? AND updated_by=?");
	$this_fpc_sth->execute($date, $user);
	$fpcversion = $this_fpc_sth->fetchrow_array || "0";
	$this_fpc_sth->finish;
    } else {
	$$bac_sth{'current_fpc_version'}->execute();
	$fpcversion = $$bac_sth{'current_fpc_version'}->fetchrow_array || "0";
    }
    return $fpcversion;

}


sub new_fpc_version ($$$) {

    my ($date, $user, $fpcfile) = @_;
    
    $$bac_sth{'user_id_by_net_id'}->execute($user);
    my $userid = $$bac_sth{'user_id_by_net_id'}->fetchrow_array;
    $userid || die "ERROR: User with net id $user not found in table USERS.\n";
    my $query_sth = $dbh->prepare("SELECT fpc_version FROM fpc_version WHERE updated_on=? AND updated_by=? AND fpcfile=?");
    $query_sth->execute($date, $userid, $fpcfile);
    if (my $prev_id = $query_sth->fetchrow_array) {
	print STDERR "WARNING: FPC version $prev_id already describes this file.\n";
	return 0;
	#print STDERR "WARNING: FPC version $prev_id already describes this file.\n";
	#return $prev_id;
    }
    $query_sth->finish;
    my $new_fpcv_sth = $dbh->prepare("INSERT INTO fpc_version SET updated_on=$date, updated_by=?, fpcfile=?");
    $new_fpcv_sth->execute($userid, $fpcfile);
    my $new_version_no = $new_fpcv_sth->{'mysql_insertid'};
    $new_fpcv_sth->finish;
    return $new_version_no;

}


sub infer_all_BACs_from_filters ($;$) {

    my ($badclones, $outfile) = @_;
    $outfile ||= 'bacs.load';
    my @rows = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P');

    my %badclones=();
    if ($badclones ne 'nobad') {
	open BAD, "<$badclones"
	    or die "ERROR: Can't read from $badclones.\n";
	my @bc = <BAD>;
	close BAD;
	chomp @bc;
	my $pfx = &cornell_prefix();
	foreach (@bc) {
	    $badclones{($pfx . $_)} = 1;
	}
    } 

    # Get the species ID from the DB.
    my $species_sth = $dbh->prepare("SELECT species_id FROM species WHERE short_name='tomato'");
    $species_sth->execute();
    my $species_id = $species_sth->fetchrow_array;
    $species_sth->finish;

    # Open the file to write this data to.
    open BACS, ">$outfile"
	or die "ERROR: Can't write to file $outfile.\n";

    # Work through the filters and extrapolate the name of every possible BAC.
    my $bac_id=0;
    foreach my $fltr_code (sort keys %$filter_shift) {
	my $shift = $$filter_shift{$fltr_code};
	foreach my $spot (keys %$filter) {
	    my $spot_code = ($$filter{$spot} + $shift);
	    foreach my $row (@rows) {
		for (my $col=1; $col<=24; $col++) {
		    $bac_id ++;
		    my $cu_name = $cornell_prefix . sprintf("%03d", $spot_code) . $row . sprintf("%02d", $col);
		    my $az_name = $arizona_prefix . sprintf("%04d", $spot_code) . $row . sprintf("%02d", $col);
		    my $sp6_end_seq_id=0;
		    my $t7_end_seq_id=0;
		    my $genbank_accession="";
		    my $estimated_length=0;
		    print BACS "$bac_id\t$cu_name\t$az_name\t$species_id\t$sp6_end_seq_id\t$t7_end_seq_id\t$genbank_accession\t" . ($badclones{$cu_name} || "0") . "\t$estimated_length\n";
		}
	    }
	}
    }
    
    close BACS;
    
}


sub cornell_prefix () {
    return $cornell_prefix;
}


sub arizona_prefix () {
    return $arizona_prefix;
}

return 1;
