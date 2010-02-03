package CXGN::Secretary::Gene;
use strict;

=head1 NAME

CXGN::Secretary::Gene

=head1 SYNOPSIS

Manages properties of a given arabidopsis gene, compiles HTML "views" with custom aspects.

=head1 USAGE

 my $gene = CXGN::Secretary::Gene->new("AT1G01010.1");
 $gene->fetch;
 print $gene->queryView #standard
 $gene->hideAllElements;
 $gene->showElements("Annotation", "Localization", "Links");
 
 print $gene->queryView(); #or boxView() or myOwnView()

=cut

use CXGN::DB::Connection;

our $DBH;
our $CHECK; 
our $QUERY_ANNOT;
our $QUERY_SIGP;
our $QUERY_SEQ;
our %QUERIES;

sub import {
	my ($class, $caller, $dbh) = @_;
	$class->setDBH($dbh) if ($dbh);
}

sub setDBH {
	my $class = shift;
	$DBH = shift;
	$DBH->do("SET SEARCH_PATH = tsearch2, public, sgn_people");
	$CHECK = $DBH->prepare("SELECT agi FROM ara_properties WHERE agi=?");
	$QUERY_ANNOT = $DBH->prepare("SELECT * FROM ara_properties JOIN ara_annotation USING(agi) WHERE agi=?");
	$QUERY_SIGP = $DBH->prepare("SELECT * FROM ara_signalp WHERE agi=?");
	$QUERY_SEQ = $DBH->prepare("SELECT * FROM ara_sequence WHERE agi=?");
	%QUERIES = ( 	annot => $QUERY_ANNOT,
						sigp => $QUERY_SIGP,
						seq => $QUERY_SEQ
				);
}

sub new {
	my $class = shift;
	my $agi = uc ( shift );
	my $page = shift;
	my $dbh = shift;
	if($dbh) { setDBH("", $dbh) }
	my $self = bless {}, $class;
	unless($agi =~ /^AT[1-5MC]G\d{5}\.\d+$/) { 
		die "You must send an AGI (ex. AT1G01010.1) as a parameter";
	}
	unless($CHECK || $dbh){
		die "You have to send a database handle or set the global before this point.";
	}
	$CHECK->execute($agi);	
	my $row = $CHECK->fetchrow_hashref;
	unless(defined $row) { 
		die "You must send an existing AGI as a parameter";
	}
	$self->{agi} = $agi;
	$self->{hilight} = 0;
	$self->{search_words} = ();
	$self->{hidden_elements} = {};
	$self->{shown_elements} = {};
	#We need the page object in order to generate hotlist buttons
	if(!ref $page) { $self->{hotlist_disable} = 1 }
	else { $self->{page_object} = $page }
	return $self;
}

sub fetch {
	my $self = shift;	
	my $table = shift;
	$table = lc($table);
	if(!$table) { $table = "annot" }
	my $query = $QUERIES{$table};
	$query->execute($self->{agi});
	my $row = $query->fetchrow_hashref;
	while( my ($key, $value) = each %$row ) {
		$self->{$key} = $value;
	}
}

sub fetch_all {
	my $self = shift;
	foreach( qw| annot sigp seq | ) {
		$self->fetch($_);
	}
}

sub fetch_sigp {
	my $self = shift;
	$QUERY_SIGP->execute($self->{agi});
	my $row = $QUERY_SIGP->fetchrow_hashref;
	while( my ($key, $value) = each %$row ) {
		$self->{$key} = $value;
	}
}

sub fetch_seq {
	my $self = shift;
	$QUERY_SEQ->execute($self->{agi});
	my $row = $QUERY_SEQ->fetchrow_hashref;
	while( my ($key, $value) = each %$row ) {
		$self->{$key} = $value;
	}
}

sub queryView {
	my $self = shift;
	my $page = $self->{page_object};
	$self->_go_view;
	my $content = "";

	my 	(	$agi, $Annotation, $searchHighlight, $firstLoc, 
			$firstLocEvi, $firstFunc, $firstFuncEvi, $firstProc, 
			$firstProcEvi, $Relevancy 
		) =
		(	$self->{agi}, $self->{tair_annotation}, $self->{highlight}, $self->{first_loc}, 
			$self->{first_loc_evi}, $self->{first_func}, $self->{first_func_evi}, $self->{first_proc}, 
			$self->{first_proc_evi}, $self->{relevancy}
		);

	my @searchWords = ();
	if($self->{search_words}){
		@searchWords = @{$self->{search_words}};
	}
	$Relevancy = int($Relevancy * 100);
	my $physicalMode = $page->{physicalMode};
	my $Mol_Weight = $self->{weight} / 1000;
	my $Num_Trans = $self->{transmemcount};
	if(length($Annotation)>500) {$Annotation = substr($Annotation, 0, 500) . "..." }
	my $extraStyle = '';
	if(!$searchHighlight) { $extraStyle = " style='background-color:white'";}
	my $origAnnotation = $Annotation;

	foreach my $buffer ( ($Annotation, $firstLoc,$firstFunc,$firstProc) ){
		#must use a unique dummy tag, since we go through the string multiple times.  if we did a span tag, then weird
		#stuff would happen if someone searched with the keyword 'span'
		foreach my $word (@searchWords){
			$buffer =~ s/\b($word)\b/<HILITEMOMO>$1<\/HILITEMOMO>/ig;
		}
		$buffer =~ s/<HILITEMOMO>(.*?)<\/HILITEMOMO>/<span class='searchHighlight'$extraStyle>$1<\/span>/g;
	}

	my $differentModel = 0;
	if($physicalMode && !($agi =~ /\.1$/)) { $differentModel = 1; $content .=  "&nbsp;&nbsp;&nbsp;" }
	$content .=  "<a href='geneview.pl?g=$agi&query=$page->{searchQuery}&prevLB=$page->{leftBound}' style='";
	if($page->{referenceGene} eq $agi && $physicalMode) { $content .=  "background-color:#009900; color:white; text-decoration:none; padding:1px;" }	
	$content .=  "'><span style='font-size:1.00em;font-weight:bold;";
	if($differentModel && !($page->{referenceGene} eq $agi && $physicalMode)) { $content .=  "color:#7777cc" }
	$content .=  "'>$agi</span></a>";

	my ($local_genetic_area) = $agi =~ /(AT[1-5MC]G\d{3})/;
	if(!$physicalMode) {$content .=  " - <a href='query.pl?query=$local_genetic_area&referenceGene=$agi&prevQ=$page->{searchQuery}&prevLB=$page->{leftBound}'>Neighboring Genes</a>";}
	
	$content .=  " - <span style='font-size:1.05em;'>$Annotation</span><br>";
	$content .=  "<span style='font-size:1em'><b>Protein Weight:</b> <span style='color:#992299'>$Mol_Weight kDa</span> ";
	$content .=  "&nbsp;&nbsp;<b>Predicted Transmembrane Domains:</b> <span style='color:#992299'>$Num_Trans</span>";


	$content .=  " &nbsp;&nbsp;&nbsp;<b>Localization:</b> $firstLoc" if($firstLoc);
	$content .=  " ($firstLocEvi)" if($firstLocEvi);
	$content .=  "<br>";
	$content .=  "<b>Function:</b> $firstFunc" if($firstFunc);
	$content .=  " ($firstFuncEvi)" if($firstFuncEvi);
	$content .=  " &nbsp;&nbsp;<b>Process:</b> $firstProc" if($firstProc);
	$content .=  " ($firstProcEvi)" if($firstProcEvi);
	$content .=  "<br>" if($firstFunc || $firstProc);
	if($Relevancy < 1) { $Relevancy = "< 1";}
	if(!$physicalMode && !$self->{hidden_elements}->{"relevancy"}) {
		$content .=  "<span style='color:#555555; font-size:1em'>Relevancy: <b style='color:#339933'>$Relevancy%</b></span>";
	}
	#TAIR Map not available for Mitochondrial or Chloroplastic sequences	
	if($agi =~ /AT[1-5]G/) {
		$content .=  "&nbsp;&nbsp;<a href='http://www.arabidopsis.org/servlets/mapper?value=$agi&action=search' class='external'>";
		$content .=  "TAIR&nbsp;Map</a>";
	}
	$content .=  "&nbsp;&nbsp;<a href='http://www.arabidopsis.org/servlets/TairObject?type=gene&name=$agi' class='external'>TAIR&nbsp;Gene</a>";


	$content .=  " &nbsp;&nbsp;<span>";

	$content .=  $page->hotlist_button($agi);

$content .=  <<HTML;

</span>
</span>
<br><br>

HTML
	return $content;				
}

sub _go_view {
	my $self = shift;
	my $page = $self->{page_object};
	my @GO_array = ($self->{localization}, $self->{localization_evidence}, $self->{function}, $self->{function_evidence}, $self->{process}, $self->{process_evidence});
	my @GO_first_array = ();
	my $code = '';
	my $def = '';

	my $array_pos = 0;
	foreach(@GO_array){
		my $firstpiece = '';
		if(/::/) {
			($firstpiece) = /(.*?)::/;  #un-greedy match up to first '::'
		}
		else {
			$firstpiece = $_;
		}
		if($array_pos%2){  # only operate on the odd (evidence) elements of the array
			if($firstpiece =~ /-PMID/) {
				($code) = $firstpiece =~ /(\w+)-PMID/;
			}
			else {
				$code = $firstpiece;
			}
			my ($remaining) = $firstpiece =~ /(PMID.*)/;
			if($remaining){	
				my ($PMID) = $firstpiece =~ /PMID:(\d+)/;
				$remaining =~ s/PMID:\d+/PubMed/;
				$remaining = "-<a class='external' href='http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=pubmed&dopt=Abstract&list_uids=$PMID&query_hl=5&itool=pubmed_docsum'>$remaining</a>";
			} else { $remaining = '' }
			if($code){
				my $def = $page->{evicode2definition}->{$code};
				$firstpiece = "<span title='$def'>" . $code . "</span>" . $remaining;
			}
			else { $firstpiece = '' }
		}
		push(@GO_first_array, $firstpiece);
		$array_pos++;
	}

	$self->{first_loc} = $GO_first_array[0];
	$self->{first_loc_evi} = $GO_first_array[1];
	$self->{first_func} = $GO_first_array[2];
	$self->{first_func_evi} = $GO_first_array[3];
	$self->{first_proc} = $GO_first_array[4];
	$self->{first_proc_evi} = $GO_first_array[5];
}

sub getSignalScore {
	my $self = shift;
	return unless $self->_check_key("nn_score");	
	return $self->{nn_score};
}

sub getCleavagePosition {
	my $self = shift;
	return unless $self->_check_key("nn_ypos");
	return $self->{nn_ypos};
}
sub getValue {
	my ($self, $key) = @_;
	return unless _check_key($key);
	return $self->{$key};
}

sub isSignalPositive {
	my $self = shift;
	return unless $self->_check_key("nn_d");
	if($self->{nn_d} eq 'Y'){
		return 1;
	}
	elsif($self->{nn_d} eq 'N'){
		return 0;
	}
	else {
		#There is a serious problem that needs to be fixed immediately:
		die "\nWARNING: NN decision score not recognized for " . $self->{agi};
	}
}

sub _check_key {
	my $self = shift;
	my $key = shift;
	unless(exists $self->{$key}){
		print STDERR "\nWARNING: The key '$key' has not been set (queried) for " . $self->{agi};
		return 0;
	}
	return 1;
}

sub setRelevancy {
	my ($self, $score) = @_;
	$self->{relevancy} = $score;
}

sub setHighlight {
	my ($self, $highlight) = @_;
	$self->{highlight} = $highlight;
}

sub setSearchWords {
	my ($self, @searchWords) = @_;
	$self->{search_words} = \@searchWords;
}

sub hideElements {
	my ($self, @elements) = @_;
	$self->{hidden_elements}->{$_} = 1 foreach @elements;
}


1;
