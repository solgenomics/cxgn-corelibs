
use strict;

package CXGN::Cluster::Match;

sub new { 
    my $class = shift;
    my $debug = shift;
    my $self = bless {}, $class;
    $self->set_debug($debug);
    $self->set_word_size(10);
    $self->set_min_match_length(10);
    return $self;
}

=head2 accessors get_query, set_query

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_query {
  my $self = shift;

  return $self->{query}; 
}

sub set_query {
  my $self = shift;
  $self->{query} = shift;
  $self->debug("query: $self->{query}");
}
=head2 accessors get_subject, set_subject

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_subject {
  my $self = shift;
  return $self->{subject}; 
}

sub set_subject {
  my $self = shift;
  $self->{subject} = shift;
#  $self->debug("subject: $self->{subject}");
}


=head2 accessors get_debug, set_debug

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_debug {
  my $self = shift;
  return $self->{debug}; 
}

sub set_debug {
  my $self = shift;
  $self->{debug} = shift;
}

=head2 debug

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub debug { 
    my $self = shift;
    my $message = shift;
    if ($self->get_debug()) { 
	print STDERR "$message\n";
    }
}

=head2 accessors get_word_size, set_word_size

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_word_size {
  my $self = shift;
  return $self->{word_size}; 
}

sub set_word_size {
  my $self = shift;
  $self->{word_size} = shift;
}

=head2 accessors get_min_match_length, set_min_match_length

 Usage:
 Desc:         the minimal length of a match in bp to be retained
               shorter matches will be discarded. Note that this cannot
               be smaller than the word size.
 Property
 Side Effects:
 Example:

=cut

sub get_min_match_length {
  my $self = shift;
  return $self->{min_match_length}; 
}

sub set_min_match_length {
  my $self = shift;
  $self->{min_match_length} = shift;
}


=head2 match_sequences

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub match_sequences { 
    my $self = shift;

    $self->debug("hashing query...");
    my $query_hashref = $self->hash_matches($self->get_query());

    $self->debug("hashing subject...");
    my $subject_hashref = $self->hash_matches($self->get_subject());

    my @matches = ();

    # sort by coordinates: first produce flat list and then sort
    my @match_list = ();
    foreach my $word (keys(%$query_hashref)) { 
	foreach my $query_start (@{$query_hashref->{$word}})  { 
	    push @match_list, [ $query_start, $word ];
	}
    }
    my @sorted_match_list = sort { $a->[0] <=> $b->[0];  } @match_list;
    my $largest_query_match_end = 0;
    foreach my $match (@sorted_match_list) { 
	my $query_start = $match->[0];
	my $word = $match->[1];
	$self->debug("extending word $word at pos $query_start...");
	my $query_match_start = undef;
	my $query_match_end = undef;
	my $subject_match_start = undef;
	my $subject_match_end = undef;
	if ( ($query_start < $largest_query_match_end)) { 
	    print STDERR "Skipping $word at $query_start because it is in a previous match\n";
	    next;
	}
	else {
	    foreach my $subject_start (@{$subject_hashref->{$word}}) { 
		
		my $five_prime_match = $self->five_prime_extend_match($query_start, $subject_start);
		my $three_prime_match = $self->three_prime_extend_match($query_start, $subject_start);
		my $match= $five_prime_match.$word.$three_prime_match;
		$self->debug("Match: $five_prime_match \| $word \| $three_prime_match");

		$query_match_start = $query_start - length($five_prime_match) +1;
		$query_match_end = $query_start + $self->get_word_size() + length($three_prime_match) +1;
		$subject_match_start = $subject_start - length($five_prime_match) +1;
		$subject_match_end = $subject_start + $self->get_word_size() + length($three_prime_match) +1;


		if ($query_match_end - $query_match_start +1 > $self->get_min_match_length()) { 
		    
		    push @matches, [ $match, 
				     $query_match_start, 
				     $query_match_end, 
				     $subject_match_start, 
				     $subject_match_end
				     ];
		}
		else { 
		    $self->debug("Skipping match because length < ".$self->get_min_match_length());
		}

		if ($largest_query_match_end < $query_match_end) { 
		    $largest_query_match_end = $query_match_end; 
		}
	    }
	}    
    }

    return @matches;
}

sub five_prime_extend_match { 
    my $self = shift;

    $self->debug("five_prime_extend_match");
    my $query_start = shift;
    my $subject_start = shift;
    
    my @query = split //, $self->get_query();
    my @subject = split //, $self->get_subject();
    my $five_prime_match = "";
    my $match_score = 1;
    my $i = 1;
    
    
    while ( ($query_start - $i >= 0) && ($subject_start - $i >= 0)) { 
	$self->debug("comparing query_pos ".($query_start-$i)." ".($query[$query_start-$i])." with subject pos ".($subject_start-$i)." ".($subject[$subject_start-$i]));

	my $score = $self->match_score($query[$query_start - $i], $subject[$subject_start -$i]);
	my $match_score += $score;
	$self->debug("score: $score. total match_score: $match_score");
	if ($match_score >= 0) { $five_prime_match = $query[$query_start-$i].$five_prime_match; }
	else { last; }
	$i++;
    }
    
    return $five_prime_match;
}

sub three_prime_extend_match { 
    my $self = shift;
    $self->debug("three_prime_extend_match");
    my $query_start = shift;
    my $subject_start = shift;
    
    my @query = split //, $self->get_query();
    my @subject = split //, $self->get_subject();
    my $match_score = 1;
    my $three_prime_match = "";
    my $i = 1;
    while ( ($query_start + $self->get_word_size() +$i < length($self->get_query())) && ($subject_start + $self->get_word_size() + $i < length($self->get_subject())) ) { 

	$self->debug("comparing query_pos ".($query_start+$i+$self->get_word_size())." ".($query[$query_start+$i+$self->get_word_size()])." with subject pos ".($subject_start+$i+$self->get_word_size())." ".($subject[$subject_start+$i+$self->get_word_size()]));

	my $score = $self->match_score($query[$query_start + $self->get_word_size() + $i], $subject[$subject_start + $self->get_word_size() + $i]);

	$match_score += $score;
	$self->debug("score: $score. total match_score: $match_score");
	if ($score > 0) { 
	    $three_prime_match = $three_prime_match . $query[$query_start + $self->get_word_size() + $i]; 
	}
	else { last; }
	$i++;
    }
    return $three_prime_match;
    
}

sub match_score { 
    my $self = shift;
    
    my $q = shift;
    my $s = shift;
    
    $self->debug("match score: $q vs $s");
    if ($q eq $s) { return 2; }
    else { return -1; }
}

sub hash_matches { 
    my $self = shift;
    
    my $seq = shift;
    $self->debug("hashing matches...");
    my %hash= ();
    foreach my $k (0..(length($seq)-$self->get_word_size())) { 
	my $word = substr($seq, $k, $self->get_word_size());
	#$self->debug("word: $word, pos: $k");
	push @{$hash{$word}}, $k;
    }
    return \%hash;
}
    
    
   


return 1;
