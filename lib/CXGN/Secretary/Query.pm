package CXGN::Secretary::Query;
use strict;

=head1 NAME

CXGN::Secretary::Query

=head1 SYNOPSIS

Wrapper/Handler for Secretary Search Queries

=head1 USAGE

my $query = CXGN::Secretary::Query->new ({ dbh => $DBH, search_query => "galactose modification weight<20k", left_bound => 21, no_agi_check => 1});
 $query->addConditions("targetp > 0.5", "weight>5k");
 $query->addWords("Glycosylation", "Secreted");
 $query->addRequiredWords("putative");
 $query->addPhrases("This exact phrase must be found in the annotation now");
 $query->prepare; #important! 
 $query->execute;
 my @agis = $query->result();
 my $agi2score_hashref = $query->scores();
 my $score = $query->getScore($agis[0]); 

=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut

use CXGN::DB::Connection;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $args = shift;
	unless(ref $args) { die "Must send hashref with values for the keys dbh and search_query.  no_agi_check is optional"	}
	$self->{dbh} = $args->{dbh};
	unless(CXGN::DB::Connection::is_valid_dbh($self->{dbh})) { die "Invalid database handle passed"; }
	$self->{search_query} = $args->{search_query};
	$self->{query_fetch_size} = $args->{query_fetch_size} || 20;	
	unless($self->{search_query}) { die "No value for key 'search_query' sent.  Why call me in the first place?" }
	$self->{left_bound} = $args->{left_bound} || 1;
	$self->{no_auto_parse} = $args->{no_auto_parse} || 0;
		
	# Do we make sure the agi's in the query actually exist?  If it's a script-built query of several known agi's, we don't really need to (costly operation).  If the user enters them, then don't set this variable to 1, and they will be auto-checked.
	$self->{no_agi_check} = $args->{no_agi_check};

	$self->{search_query} =~ s/^\s+//;
	$self->{search_query} =~ s/\s+$//;

	#not really necessary, but it's good to keep track of what my variables are:
	$self->{db_query};
	$self->{extra_tables} = [];
	$self->{phrases} = [];
	$self->{conditionals} = [];
	$self->{explicit_agis} = [];
	$self->{results} = [];
	$self->{words} = [];

	#default is parse.  set no_auto_parse to 1 if you want to build and execute a query directly
	$self->parse unless($self->{no_auto_parse});
	return $self;
}


=head2 prepare

Build the Postgres Query String from the handle's data structure, which 
must occur after parsing and modification and before execution of the 
query.

=cut

sub prepare {
	my $self = shift;	
	my $db_query = "";

	$self->_make_my_arrays_unique;
	return if($self->{agi_simple_query});
	return if($self->{physical_mode});
	my $ts_query = (join " ", @{$self->{words}});
 	$ts_query =~ s/\\(['"\\])/$1/g;
	$ts_query =~ s/\s+AND\s+/&/g;
	$ts_query =~ s/\s+OR\s+/|/g;
	$ts_query =~ s/\s+/|/g;
	$ts_query =~ s/\|+/|/g;
	$ts_query =~ s/&+/&/g;
	$ts_query =~ s/^[&|]//;
	$ts_query =~ s/[&|]$//;
	$ts_query =~ s/(['"\\])/\\$1/g;
	my $ts_func = "to_tsquery('default', '$ts_query')";
	my $rank_func = "rank(fulltext, $ts_func)";
	my $conditional_sql = "";
	if(length($ts_query)>0) {
		$conditional_sql .= "fulltext @@ $ts_func ";
		if(@{$self->{phrases}}>0) {$conditional_sql .= "AND "}
	}
	foreach my $phrase (@{$self->{phrases}}) {
		$conditional_sql .= "(";
		$conditional_sql .= "tair_annotation LIKE '\%$phrase%'";	
		$conditional_sql .= " OR localization LIKE '\%$phrase%'";
		$conditional_sql .= " OR process LIKE '\%$phrase%'";
		$conditional_sql .= " OR function LIKE '\%$phrase%'";
		$conditional_sql .= " OR aliases LIKE '\%$phrase%'";
		$conditional_sql .= ") AND";
	}
	if(@{$self->{phrases}}) { $conditional_sql = substr($conditional_sql, 0, length($conditional_sql)-3); }
	my $basequery = "SELECT DISTINCT ara_annotation.agi";
	my $countquery = "SELECT COUNT(DISTINCT ara_annotation.agi) FROM ara_annotation";
	if(length($ts_query)>0) {$basequery .= ", $rank_func"}
	$basequery .= " FROM ara_annotation";
	foreach(@{$self->{extra_tables}}) { 
		my $join_type = "";
		if(/ara_intron/){
			$join_type = "LEFT";
		}
		$basequery .= " $join_type JOIN $_ USING(agi) "; 
		$countquery .= " $join_type JOIN $_ USING(agi) ";
	}
	$basequery .= " WHERE $conditional_sql";
	$countquery .= " WHERE $conditional_sql";
	if (@{$self->{conditionals}} > 0) { 
		if(@{$self->{phrases}}>0 || length($ts_query) > 0) { 
			$basequery .= " AND "; 
			$countquery .= " AND ";
		}
		$basequery .= join(" AND ", @{$self->{conditionals}});
		$countquery .= join (" AND ", @{$self->{conditionals}}); 
	}
	if (length($ts_query)>0) {
		$basequery .= " ORDER BY $rank_func DESC ";
	}
	my $query_lb = $self->{left_bound} - 1;
	$self->{db_query} = $basequery . " LIMIT $self->{query_fetch_size} OFFSET $query_lb";
	$self->{db_count_query} = $countquery;
}

sub _make_my_arrays_unique {
	my $self = shift;
	#unique-ify all arrays:
	my %seen = {};
	%seen = {};
	@{$self->{phrases}} = grep { !$seen{$_}++ } @{$self->{phrases}};
	%seen = {};
	my @new_words = ();	
	foreach(@{$self->{words}}){
		if(!$seen{$_}){
			$seen{$_}++;
			push(@new_words, $_);
		}
		elsif(/(AND)|(OR)/) { push(@new_words, $_) }
	} 
	$self->{words} = \@new_words;
	%seen = {};
	@{$self->{extra_tables}} = grep { !$seen{$_}++ } @{$self->{extra_tables}};
	##
}

=head2 parse

No arguments, no returns.  This is called automatically on new(), unless you send the argument 'no_auto_parse => 1'.  Parses the search query and pulls out all the interesting stuff into arrays, leaving behind a fulltext string.  Follow this with prepare() to create the database search string and execute() to execute the query.

=cut

sub parse {
	my $self = shift;
	my $search_query = $self->{search_query};	
	my $other_stuff = $self->_parse_explicit_agis($search_query);		
	$other_stuff =~ s/\s+//g;
	if(!$other_stuff) { 
		$self->{agi_simple_query} = 1;
		return;
	}
	
	$search_query = $self->_parse_phrases($search_query); # $search_query now has quoted phrases removed
	$search_query = $self->_parse_conditionals($search_query); # $search_query now has conditionals removed 
	$self->_parse_words($search_query);		
}

sub _parse_words {
	my $self = shift;
	my $search_query = shift;		
	$search_query =~ s/^\s+//;
	$search_query =~ s/\s+$//;
	my @words = split /\W+/, $search_query;
	$self->{words} = \@words;
}

sub _parse_explicit_agis {
	my $self = shift;
	my $query = shift;
	my $check_q = $self->{dbh}->prepare("SELECT agi FROM ara_properties WHERE agi=?");
	my $buffer = $query;
	
	while($buffer){
		my ($agi) = $buffer =~ /(AT[1-5MC]G\d{5}\.\d+)/i; 
		$agi = uc($agi);
		if($agi) {
			if($self->{no_agi_check}) {
				push(@{$self->{explicit_agis}}, $agi);
			} #if we come from the advanced query, we don't need to verify AGIs, which takes time
			else {
				$check_q->execute($agi);
				if($check_q->fetchrow_array()) { push(@{$self->{explicit_agis}}, $agi) }
			}
			$buffer =~ s/AT[1-5MC]G\d{5}\.\d+//i;
			$query = $buffer;
		}
		else {$buffer = ''}
	}
	return $query;
}

=head2 _parse_conditionals

This is where all the grabbing of special commands (e.g. "weight<20k") and removal from the search_query occurs

=cut

sub _parse_conditionals {
	my $self = shift;
	my $search_query = shift;
	my $buffer = $search_query;
	while($buffer){
		my ($cond_signalp) = $buffer =~ /(signalp\s*[<>=:]\s*[0-9.yesno]+)/i;	
		my ($cond_weight) = $buffer =~ /(weight\s*[<>=]\s*[0-9.]+\s*k?)/i;
		my ($cond_targetp) = $buffer =~ /(targetp\s*[=:]\s*\w)/i;
		my ($cond_intron) = $buffer =~ /(introns?\s*[<>=]\s*[0-9yesno]+)/i;
		my ($cond_modelnum) = $buffer =~ /(MODEL\d+)/;  #MODEL must be in CAPS
		my ($cond_chrom) = $buffer =~ /(chr(om(osome)?)?[=:][1-5MC])/i;
		if($cond_signalp){
			my $temp_cond = $cond_signalp;	
			if($temp_cond =~ /signalp\s*[<>=]\s*[0-9.]+/){
				$temp_cond =~ s/signalp\s*([<>=])\s*([0-9.]+)/ara_signalp.nn_score $1 $2/i;
			}
			elsif($temp_cond =~ /signalp\s*[=:]\s*(y(es)?)|(no?)/i){
				my ($sigbool) = $temp_cond =~ /\s*[=:]\s*(\w)/i;
# 				print "<!--SigBool:$sigbool-->";
				$sigbool = uc($sigbool);
				if($sigbool eq 'Y') { 
					$temp_cond = "ara_signalp.nn_d = 'Y'";
				}
				else {
					$temp_cond = "ara_signalp.nn_d = 'N'";
				}
			}
			else {  #malformed, so throw it away
				$search_query =~ s/\Q$cond_signalp//g;
				$buffer =~ s/\Q$cond_signalp//g;
				next;
			}

			push(@{$self->{extra_tables}}, "ara_signalp");
			push(@{$self->{conditionals}}, $temp_cond);
			$search_query =~ s/\Q$cond_signalp//g;
			$buffer =~ s/\Q$cond_signalp//g;
		}
		elsif($cond_intron){
			my ($operator) = $cond_intron =~ /introns?\s*([<>=:])/i;
			my ($operand) = $cond_intron =~ /[<>=:]\s*((\d+)|(yes)|(no))/;
			if($operand =~ /yes/i){
				$operator = ">";
				$operand = 0;
			}
			elsif($operand =~ /no/i){
				$operator = "=";
				$operand = 0;
			}
			elsif($operator eq ":"){
				$operator = "=";
			}
			my $conditional = "ara_properties.introncount $operator $operand";
			push(@{$self->{extra_tables}}, "ara_properties");
			push(@{$self->{conditionals}}, $conditional);
			$search_query =~ s/\Q$cond_intron//g;
			$buffer =~ s/\Q$cond_intron//g;
		}
		elsif($cond_weight){
			my $temp_cond = $cond_weight;	
			if ($temp_cond =~ /k$/i) {
				my ($kiloweight) = $temp_cond =~ /([0-9.]+)\s*k/;
				$kiloweight *= 1000;
				$temp_cond =~ s/[0-9.]+\s*k/$kiloweight/;
			}
			$temp_cond =~ s/weight\s*([<>=])\s*([0-9.]+)/ara_properties.weight $1 $2/i;
			push(@{$self->{extra_tables}}, "ara_properties");
			push(@{$self->{conditionals}}, $temp_cond);
			$search_query =~ s/\Q$cond_weight//g;
			$buffer =~ s/\Q$cond_weight//g;
		}
		elsif($cond_targetp){
			my ($char) = $cond_targetp =~ /targetp\s*=\s*(\w)/i;
			$char = uc($char);
			push(@{$self->{extra_tables}}, "ara_targetp");
			push(@{$self->{conditionals}}, "ara_targetp.location = '$char'");
			$search_query =~ s/\Q$cond_targetp\E\w*//g;  #in this case, we want to also dismiss word chars directly after the variable def, in case the user enters
			$buffer =~ s/\Q$cond_targetp\E\w*//g; # something like 'targetp=Mitochondria'.  See how flexible it becomes!
		}
		elsif($cond_modelnum){
			my ($number) = $cond_modelnum =~ /MODEL(\d+)/;
			push(@{$self->{conditionals}}, "ara_annotation.agi LIKE '%.$number'");
			$search_query =~ s/\Q$cond_modelnum//g;
			$buffer =~ s/\Q$cond_modelnum//g;
		}
		elsif($cond_chrom){
			my ($chrom) = $cond_chrom =~ /[:=]([1-5MC])/;
			push(@{$self->{conditionals}}, "ara_annotation.agi LIKE 'AT${chrom}G%'");
			$search_query =~ s/\Q$cond_chrom//g;
			$buffer =~ s/\Q$cond_chrom//g;
		}
		else{
			$buffer = '';
		}
	}
	return $search_query;
}

sub _parse_phrases {
	my $self = shift;
	my $search_query = shift;
	my @quoted = ();
	while(my ($qmatch) = $search_query =~ /"([^"]+)"/){
		$qmatch =~ s/^\s+//;
		$qmatch =~ s/\s+$//;
		$qmatch =~ s/(['"\\])/\\$1/g;
		push(@quoted, $qmatch) if $qmatch =~ /\S+/;
		$search_query =~ s/"[^"]+"//;
	}
	$self->{phrases} = \@quoted;
	return $search_query;
}

=head2 addConditions 

Takes a quoted word list of conditionals and parses them for recognizable conditions.  See _parse_conditionals() in the code for conditionals that you can use.  Feel free to add more to that code.

=cut

sub addConditions {
	my ($self, @conditions) = @_;
	my $cond_str = join " ", @conditions;
	_parse_conditionals($cond_str);
}

=head2 addWords(qw||), addRequiredWords(qw||), addPhrases(qw||)

Add words, required words, and phrases to the search query, respectively

=cut

sub addWords {
	my ($self, @words) = @_;
	push(@{$self->{words}}, @words);
}

sub addRequiredWords {
	my ($self, @words) = @_;
	@words = map { " AND " . $_ } @words;	
	push (@{$self->{words}}, @words);
}

sub addPhrases {
	my ($self, @phrases) = @_;
	push(@{$self->{phrases}}, @phrases);
}

=head2 execute

Executes the query, must be preceded by prepare(), which must be preceded by parse() at some point (parse is auto-called on new())

=cut

sub execute {
	my $self = shift;
	#die $self->{db_query};
	if($self->{agi_simple_query}) {
		$self->{result_size} = @{$self->{explicit_agis}};
		@{$self->{agis}} = splice (@{$self->{explicit_agis}}, $self->{left_bound}-1, 20);
		my %scores;
		foreach(@{$self->{agis}}) {
			$scores{$_} = 1;
		}
		$self->{agi2score} = \%scores;
		return;
	}
	$self->{query_handle} =	$self->{dbh}->prepare($self->{db_query});
	$self->{query_handle}->execute();
	my %scores;
	my @AGIs;
	while(my $row = $self->{query_handle}->fetchrow_hashref) {
		my ($agi, $score) = ($row->{agi}, $row->{rank});
		if($score > 0) { $scores{$agi} = $score }
		else { $scores{$agi} = 1 }
		push(@AGIs, $agi);
	}
	$self->{agi2score} = \%scores;
	$self->{agis} = \@AGIs;
}

=head2 execute_count

Executes the count query, which can be intensive, so only use this when you don't already know the total query result count and you have to know what it is.

=cut

sub execute_count {
	my $self = shift;
	return if $self->{agi_simple_query};
	$self->{count_query_handle} = $self->{dbh}->prepare($self->{db_count_query});
	$self->{count_query_handle}->execute();
	my @row = $self->{count_query_handle}->fetchrow_array;
	$self->{result_size} = $row[0];
}


sub results {
	my $self = shift;
	return @{$self->{agis}};
}

sub scores {
	my $self = shift;
	return $self->{agi2score};
}

sub resultSize {
	my $self = shift;
	return $self->{result_size};
}

sub getScore {
	my ($self, $agi) = @_;
	return $self->{agi2score}->{$agi};
}

sub getSearchWords {
	my $self = shift;
	my @searchWords = ();
	push(@searchWords, @{$self->{words}}, @{$self->{phrases}});
	@searchWords = grep { !($_ eq "AND" || $_ eq "OR") } @searchWords;
	return @searchWords;
}


=head2 setQuery

Use this to set the database query directly instead of using parsing and data structures.  I can't think of a reason for this, but I'm sure someone will.

=cut

sub setQuery {
	my ($self, $query) = shift;
	$self->{db_query} = $query;
}

sub getQuery {
	my $self = shift;
	return $self->{db_query};
}


####
1;### Lemme alone!
####
