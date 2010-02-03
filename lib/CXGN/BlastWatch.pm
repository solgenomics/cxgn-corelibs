package CXGN::BlastWatch;

use strict;
use POSIX;
use CXGN::People;
use CXGN::DB::Connection;
use CXGN::BlastWatch::Config;

use Mail::Sendmail;

## TODO: the perldoc stuff REALLY needs to be updated!! ##

#### subroutines to run weekly blast and process results ####
#### run_blast, blast, tempname, handle_results          ####

sub run_blast {

    # retrieves all queries, runs BLAST on each, and adds new results to database

    my $dbh = shift;

    my $select = "SELECT blastwatch_queries_id, sequence, program, database, matrix, evalue FROM blastwatch_queries";	

    my $sth = $dbh->prepare($select);
    $sth->execute();

    while (my @parameters = $sth->fetchrow()) {
	my $bw_query_id = shift @parameters;
 	my $output = blast( @parameters );
 	my $num_results = handle_results($dbh,$bw_query_id,$output);

 	# should reset flag to 0 if not done elsewhere
 	# (I can see benefits either way.. leaving it up during the week
 	# or removing it as soon as the email is sent)
 	# currently this is done when the emails are sent out

	if ($num_results > 0) {
	    # update num_results and set new_results flag
	    my $update = "UPDATE blastwatch_queries SET num_results = num_results + ?, "
 		."new_results = ? WHERE blastwatch_queries_id = ?";
            my $sth2 = $dbh->prepare($update);
	    $sth2->execute($num_results,"t",$bw_query_id);
	    $sth2->finish;   
	}
    }
    $sth->finish;
}

sub blast {

    # runs BLAST on query, creates temp file with output
    my ($sequence, $program, $database, $matrix, $evalue) = @_;

    my $tempfile = File::Temp->new( TEMPLATE => File::Spec->catfile( File::Spec->tmpdir, 'blastwatch-update-XXXXXX' ) );

    my $blast_dbpath = CXGN::BlastWatch::Config->load_locked->{'blast_db_path'};

    my $command = "blastall -p $program -d $blast_dbpath/$database -m8 -o $tempfile -e $evalue";

    if ($program ne "blastn") {
	$command .= " -M $matrix";
    }

    open(BLASTPIPE, "| $command") or die "$!\n";
    print BLASTPIPE $sequence;
    close(BLASTPIPE) or print STDERR 
	"BLAST command \"$command\" failed - non-zero exit status ($! - $?)";	

    return $tempfile;
}

sub handle_results {

    # get relevant information from results file

    my ($dbh,$bw_query_id,$output) = @_;

    chomp (my $num_results = `wc  -l $output`);
    $num_results =~ s/^(\d*).*$/$1/;
    
    if ($num_results == 0) { return 0 } # no results found

    # else
    open(RESULTS, "<$output") or die "can't open $output: $!\n";

    while (<RESULTS>) {
	chomp;
	# s/ //g; # sometimes the output file has spaces; but I'm not sure if this matters
	my @row = split/\t/;
	my @values = @row[0,1,8,9,10,11];
	# query_id,subject_id,subject_start,subject_end,evalue,score

 	my $select = "SELECT blastwatch_results_id from blastwatch_results "
 	    ."where blastwatch_queries_id = ? and query_id = ? and subject_id = ? "
 	    ."and subject_start = ? and subject_end = ? and evalue = ? and score = ?";

  	my $sth = $dbh->prepare($select);
	$sth->execute($bw_query_id,@values);

 	if ($sth->fetchrow()) {
 	    # result is not new
 	    $num_results--;
 	    next;
 	}
 	else {
 	    # insert new result

 	    my $insert = "INSERT into blastwatch_results "
 		."(blastwatch_queries_id, query_id, subject_id, subject_start, "
 		."subject_end, evalue, score) values (?,?,?,?,?,?,?)";
 	    $sth = $dbh->prepare($insert);
 	    $sth->execute($bw_query_id,@values);

 	}
 	$sth->finish();
     }

     close(RESULTS) or die "cannot close $output: $!\n";
   
     return $num_results; # number of *new* results found
}

#### subroutines to contact users                              ####
#### send_updates, send_confirmation, send_message, reset_flag #### 

sub send_updates {

    # finds queries with new results and sends update to user

    my $dbh = shift;

    # see which queries have new results
    my $select = "SELECT blastwatch_queries_id, sp_person_id, num_results from blastwatch_queries where new_results = 't'";

    my $sth = $dbh->prepare($select);
    $sth->execute();

    while (my ($bw_query_id,$sp_person_id) = $sth->fetchrow()) {
	&send_confirmation($dbh,$bw_query_id,$sp_person_id);
	
	# reset flag
        &reset_flag($dbh,$bw_query_id);
    }

    $sth->finish;

}

sub send_confirmation {

    # creates email to update user of new results

    my ($dbh,$bw_query_id,$sp_person_id) = @_;
    
    my $select = "SELECT sequence, program, database, matrix, evalue, num_results "
	. "FROM blastwatch_queries where blastwatch_queries_id = ?";
    my $sth2 = $dbh->prepare($select);
    $sth2->execute($bw_query_id);
    my ($sequence,$program,$database,$matrix,$evalue,$num_results) = $sth2->fetchrow();
    $sth2->finish;
    
    my $subject = "[SGN] BLAST Watch results changed";

    my $body = <<MESSAGE;

Please do *NOT* reply to this message. The return address is not valid.
Use sgn-feedback\@sgn.cornell.edu instead.

Results for the following query in BLAST Watch have changed.

Query sequence: 
$sequence

Program: $program

Database: $database

Substitution Matrix: $matrix

Expect (e-value) Threshold: $evalue

There are now $num_results results.  Please login to view these results.

Thank you,
SOL Genomics Network

MESSAGE
;

    &send_message($dbh,$body,$subject,$sp_person_id);
}


sub send_message {

    # send message to user
    my ($dbh,$body, $subject, $sp_person_id) = @_;

    my $select = "SELECT private_email FROM sgn_people.sp_person where sp_person_id = ?";
    my $sth2 = $dbh->prepare($select);
    $sth2->execute($sp_person_id);
    my $mailto = $sth2->fetchrow();
    $sth2->finish;

    my $mailfrom = CXGN::BlastWatch::Config->load->{mail_from};

    sendmail(
             To      => $mailto,
             From    => $mailfrom,
             Subject => $subject,
             Body    => $body,
            );
}

sub reset_flag {

    # resets "new results" flag after message has been sent

    my ($dbh,$bw_query_id) = @_;
    my $update = "UPDATE blastwatch_queries set new_results = ? where blastwatch_queries_id = ?";
    my $sth2 = $dbh->prepare($update);
    $sth2->execute('f',$bw_query_id);
    $sth2->finish;
}


#### subroutines to handle queries  ####
#### insert_query, delete_query     ####

sub insert_query {

   # inserts new query into database if it is not a repeat

    my ($dbh, @values) = @_;

    # check for repeated query
    my $select = "SELECT blastwatch_queries_id FROM blastwatch_queries "
	."where sp_person_id = ? and sequence = ? and program = ? and database = ? and matrix = ? and evalue = ?";
    my $sth = $dbh->prepare($select);
    $sth->execute(@values);

    if ($sth->fetchrow()) {
	# query is not new
	return 0;
    }

    # else, insert new query

    my $insert = "INSERT INTO blastwatch_queries (sp_person_id, sequence, program, database, matrix, evalue)"
	. "values (?,?,?,?,?,?)";

    $sth = $dbh->prepare($insert);
    $sth->execute(@values);
    $sth->finish;
    
    return 1;
}

sub delete_query {

    # deletes queries

    my ($dbh,$sp_person_id,@bw_query_ids) = @_;

    foreach my $bw_query_id (@bw_query_ids) {

	my $select = "SELECT sp_person_id FROM blastwatch_queries WHERE blastwatch_queries_id = ?";
	my $sth = $dbh->prepare($select);
	$sth->execute($bw_query_id);
    
	my $spid = $sth->fetchrow();
	if ($spid != $sp_person_id) { return 0 }
    
	$sth = $dbh->prepare("DELETE FROM blastwatch_queries WHERE blastwatch_queries_id = ?");
	$sth->execute($bw_query_id);

    }

    return 1;
}



#### subroutines to handle queries on My SGN   ####
#### get_queries, format_queries, create_table ####


sub get_queries {

    # selects out BLAST Watch queries for user and creates table

    my ($dbh,$sp_person_id) = @_;

    my $select = "SELECT blastwatch_queries_id, sequence, program, database, matrix, "
	. "evalue, num_results FROM blastwatch_queries WHERE sp_person_id = ?";

    my $sth = $dbh->prepare($select);
    $sth->execute($sp_person_id);

    my $queries = "";
    while (my @v = $sth->fetchrow()) {
	my $q .= &format_queries($queries, $sp_person_id, @v);
	$queries = $q;
    }

    $sth->finish;

    &create_table($sp_person_id,$queries); 
}

sub format_queries {

    # puts queries into table format and sets up full sequence view and deletion

    my ($queries, $sp_person_id, $bw_query_id, $sequence, $program, $database, $matrix, $evalue, $num) = @_;  

    # crop full sequence to 50 characters
    my $seq = substr($sequence, 0, 50);

    # remove white space and force sequence to wrap
    $sequence =~ s/\s/ /g;
    my $length = length($sequence);
    my $wrap = 85;
    for (my $i = $wrap; $i < $length ; $i += $wrap + 1) {
	substr($sequence, $i, 0) = " ";
    }

    # truncate evalue
    if ($evalue =~ /(\d*\W)(\d*)(e-\d*)?/) {
	my $b = substr($2,0,2);
	$evalue = $1.$b.$3;
    }

    $queries .= <<TEXT;

<tr>
<td><a href="/tools/blast/watch/results.pl?query=$bw_query_id" onMouseover="showSequence('$sequence')" onMouseout="hideSequence()">$seq</a></td>
<td>$program</td>
<td>$database</td>
<td>$matrix</td>
<td align="right">$evalue</td>
<td align="right">$num</td>
<td>
<input type="checkbox" value="$bw_query_id" name="bw_query_id" />
</td>
</tr>

TEXT

     return $queries;

}

sub create_table {

    # adds header to results table and creates form for deletion

    my ($sp_person_id,$queries) = @_;

    my $table = <<TEXT;


<form method="post" action="/tools/blast/watch/delete.pl" onSubmit="return confirm('Are You Sure?')">
  <table summary="" width="90%">
  <input type="hidden" value="$sp_person_id" name="sp_person_id" />
  <tr><td align='center'>Mouse over sequence to view it in full. Click on sequence to view results.</td></tr>
  </table>
  <table summary="" width="90%" border="1" cellpadding="2" cellspacing="2"><tr>
  <td><strong>Sequence</strong></td>
  <td><strong>Program</strong></td>
  <td><strong>Database</strong></td>
  <td><strong>Matrix</strong></td>
  <td><strong>E-value</strong></td>
  <td><strong>Results</strong></td>
  <td>
  <input type="submit" value="Delete" />
  </td>
  </tr>
  $queries
  </table>
</form>
<table summary="" width="90%">
<tr><td><div id="Heading"></div></td></tr>
<tr><td align="center"><div id="fullSequence"></div></td></tr>
</table>

TEXT

    return($table);

}

#### subroutines to handle queries  ####
#### get_results, format_results    ####

sub get_results {

    # gets results for a given query

    my ($dbh,$bw_query_id) = @_;

    # test if query is valid
    my $select1 = "SELECT blastwatch_queries_id from blastwatch_queries where blastwatch_queries_id = ?";

    my $sth1= $dbh->prepare($select1);
    $sth1->execute($bw_query_id);
    
    unless (my $id = $sth1->fetchrow()) {
	return 0; # invalid query
    }
    
    my $select = "SELECT query_id,subject_id, subject_start, subject_end,evalue,score FROM "
	. "blastwatch_results where blastwatch_queries_id = ?";

    my $sth = $dbh->prepare($select);
    $sth->execute($bw_query_id);
    
    my $results = "";

    while (my @v = $sth->fetchrow()) {
	my $r .= &format_results($results, @v);
	$results = $r;
    }

    $sth->finish;
    
    if (!$results ) { $results = "No results found." }
    
    return $results;
}

sub format_results {

    # puts results into table format

    my ($results, $query, $subject, $start, $end, $evalue, $score) = @_;

    $results .= <<TEXT;

    <tr>
	<td>$query</td>
	<td>$subject</td>
	<td>$start</td>
	<td>$end</td>
	<td>$evalue</td>
	<td>$score</td>
    </tr>

TEXT

     return $results;
}

###
1;# do not remove this
###
