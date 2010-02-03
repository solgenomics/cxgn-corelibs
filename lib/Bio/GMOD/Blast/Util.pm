package Bio::GMOD::Blast::Util;
#######################################################################
# Author:           Shuai Weng  <shuai@genome.stanford.edu>
# Date:             May 2003
# 
#
#######################################################################
use strict;


#######################################################################
sub checkLoad {
#######################################################################
# This method is used to check the server load. It will return 1 if 
# the load is too high.

    my ($self, $maxLoad) = @_;

    my @load = `/usr/bin/w`;

    if ($load[0] =~ / load average: ([0-9\.]+), / ) {

	if ($1 > $maxLoad) { return 1; }

	return;

    }

    return;

}

#######################################################################
sub loadWait {
#######################################################################
# This method simply checks server's load and prints some message to 
# stdout if the load is too high.
 
    my ($self, $maxLoad, $loadlog) = @_;

    my $loadwait = 1;
    my $loadfirst = 1;

    my $thetime = $self->theTime;

    my $remotehost = $self->remoteHost;

    while ($loadwait) {

	if ( !$self->checkLoad($maxLoad) ) {

	    last;

	} 
       
	if ( $loadfirst ) {

	    print "Please wait... The load on the server is too high. Your request will start once the load drops.<p>\n";

	    print "<b>You can return to the form and use the email option to have the result, or the URL of the result, emailed to you.</b><p>\n";

	    $loadfirst = 0;

	    open (loadlog, ">>$loadlog") or warn "could not open loadlog\n";

	    print loadlog "$thetime $remotehost ".(caller(1))[1]."\n";

	    close (loadlog);

	} 
	else {

	    print "waiting... <br>\n";

	    sleep 10;

	}
	
    }

}

#######################################################################
sub queueWait {
#######################################################################
# This method simply checks to see if there is another process running
# for the client machine. If yes, it will print some 'wait' related
# message to stdout. 
 
    my ($self, $lockDir, $queueDesc, $queuelog) = @_;

    my $queuewait = 1;
    my $waitfirst = 1;

    my $thetime = $self->theTime;

    my $remotehost = $self->remoteHost;

    my $lockfile = $lockDir.$self->remoteAddr;

    while($queuewait) {

	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
	    $atime, $mtime, $ctime, $blksize, $blocks) 
	    = stat "$lockfile";

	if (!$atime) {

	    open(QUEUE, ">$lockfile") or warn "could not open lockfile\n";

	    print QUEUE "$queueDesc\n";

	    close(QUEUE);

	    $queuewait = 0;

	} 
	else {

	    if ( $waitfirst ) {

		print "Please wait... Another BLAST, FASTA, or PatMatch search is currently being processed for a computer at your institution.<p>\n";

		print "<b>You can return to the form and use the email option to have the result, or the URL of the result, emailed to you.</b><p>\n";

		$waitfirst = 0;

		open (queuelog, ">>$queuelog") or warn "could not open queuelog\n";
		print queuelog "$thetime $remotehost ".(caller(1))[1]."\n";

		close (queuelog);

	    } 
	    else {
		
		print "waiting... <br>\n";
	    
	    }
	    sleep 10;
	}
    }

    return $lockfile;

}

#######################################################################
sub theTime {
#######################################################################
# This method simply returns the current time in the special format.

    my ($self) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) 
	= localtime(time);
    
    # convert to current year and remove the century
    $year = ($year + 1900) % 1000;

    my $thetime = sprintf ("%2d/%2d/%2d:%2d:%2d:%2d", 
			   $mday, $mon+1, $year, 
			   $hour, $min, $sec);

    $thetime =~ s/ /0/g;

    return $thetime;

}

#######################################################################
sub remoteHost {
#######################################################################
# This method simply returns the remote host name or remote address.

    my ($self) = @_;

    return $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

}

#######################################################################
sub remoteAddr {
#######################################################################
# This method simply returns the remote address

    my ($self) = @_;

    my $remoteaddr = $ENV{'REMOTE_ADDR'};

    $remoteaddr =~ s/\.\w*$//;

    return $remoteaddr;

}

#######################################################################
sub deleteUnwantedCharFromSequence {
#######################################################################
# This method simply removes all sequence-unrelated characters from 
# the protein or dna sequences.
 
    my ($self, $seqRef) = @_;
 
    # if seqence contains '..' assume it's GCG form
    # discard everything before the .. and the .. too      
    $$seqRef =~ s/^.+\.\.(.+)$/$1/;

    # discard first fasta def line if it is fasta format
    $$seqRef =~ s/^>[^\15\12]+//;

    # discard all no-alphabet characters 
    $$seqRef =~ s/[^A-Za-z]//g;

}

#######################################################################
sub createTmpSeqFile {
#######################################################################
# This method simply creates a tmp sequence file for the blast search.

    my ($self, $tmpfile, $seqname, $sequence) = @_;

    my $lineWidth = 70;
    
    if (!$sequence) { return; }

    open(SEQTMP, ">$tmpfile") || 
	die "Can't create tmp seqfile $tmpfile:$!";

    print SEQTMP ">$seqname\n";

    while(length($sequence) > $lineWidth) { 

	print SEQTMP substr($sequence, 0, $lineWidth), "\n";

	$sequence = substr($sequence, $lineWidth, length($sequence));

    }
    print SEQTMP $sequence , "\n";

    close(SEQTMP);

}

#######################################################################
sub validateEmail {
#######################################################################
# This method is used to validate the email address.

    my ($self, $email) = @_;

    my ($username, $hostname) = split('@', $email);

    if ( !$username || !$hostname) { return; }

    open(hostchk, "/tools/net/bin/host $hostname|") or 
	warn "could not open hostchk";

    my $hostvalid;

    while (<hostchk>) {

	if ( /.*\tA\t.*/ || /.*\tMX\t.*/ ) {

	    $hostvalid++;
	
	}
	
    }
    close(hostchk);

    return $hostvalid;

}

#######################################################################
sub writeLog {
#######################################################################
# This methods is used to write logs into logfile.

    my($self, $logfile, $program, $dataset, $options, $Cuser, 
       $Csystem, $seqlen, $remotelink) = @_;

    my $remotehost = $self->remoteHost;
    my $thetime = $self->theTime;

    open(LOG, ">>$logfile") || 
	warn "Could not open blastlog file '$logfile':$!\n";
	
    printf(LOG "%s [%s] \"%s_sc %s%s\" u:%1.2f s:%1.2f len=%d %s\n", 
	   $remotehost, $thetime, $program, $dataset, $options,
	   $Cuser, $Csystem, $seqlen, $remotelink);

    close(LOG);

}

#######################################################################
sub blastOptions {
#######################################################################
# This method is used to set the blast options.

    my ($self, $program, $seqlen) = @_;

    my $hspmax;
    my $gapmax;

    if ( $seqlen < 10000 ) {

	if ($program eq "blastn") {

	    $hspmax = 6000;

	    $gapmax = 3000;

	} 
	else {

	    $hspmax = 2000;

	    $gapmax = 1000;

	}
    } 
    else {

	$hspmax = 10000;

	if ($program eq "blastn") {

	    $gapmax = 3000;

	} 

	else {

	    $gapmax = 1000;
	}
    }

    return " -hspsepsmax=" . $hspmax . " -hspsepqmax=" . $hspmax . " -gapsepsmax=" . $gapmax . " -gapsepqmax=" . $gapmax . " ";

}


#######################################################################
1; ####################################################################
#######################################################################
