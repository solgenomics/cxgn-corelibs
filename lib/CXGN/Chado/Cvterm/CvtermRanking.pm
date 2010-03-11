     

=head1 NAME

CXGN::Chado::Cvterm::CvtermRanking 

=head1 SYNOPSIS

=head1 AUTHOR

Naama (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;

use CXGN::DB::Object;
#use CXGN::Chado::Cvterm;
use CXGN::Chado::Publication;
use CXGN::DB::Connection;

package CXGN::Chado::Cvterm::CvtermRanking;

use base qw / CXGN::DB::Object CXGN::Tools::Tsearch/;


=head2 new

 Usage: my $cvterm_rank = CXGN::Chado::Cvterm::CvtermRanking->new($dbh,$cvterm_id, $pub_id);
 Desc:
 Ret:    
 Args: $dbh, $cvterm_id, $pub_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $cvterm_id= shift; # the primary key in the databaes of this object
    my $pub_id=shift;
    my $args = {};  
    
    my $self = bless $args, $class;
    
    $self->set_dbh($dbh);
    $self->set_cvterm_id($cvterm_id);
    $self->set_pub_id($pub_id);
    if ($cvterm_id && $pub_id) {
	$self->fetch(); #get the  details   
	$self->set_validate_status();
    }
    return $self;
}

sub fetch {
    my $self=shift;
    my $query = "SELECT rank, match_type, headline 
                    FROM cvterm_pub_ranking 
                    WHERE cvterm_id=? and pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $self->get_pub_id());
    
    my ($rank,$match_type,$headline)=$sth->fetchrow_array();
    $self->set_rank($rank);
    $self->set_match_type($match_type);
    $self->set_headline($headline);
}


=head2 store

 Usage: $self->store()
 Desc:  store a new cvterm_pub_ranking
 Ret:   1 if stored or 0 if cvterm_pub_rank_exists
 Args:  none
 Side Effects: inserts a new row in cvterm_pub_ranking table
 Example:

=cut

sub store {
    my $self=shift;
    my $exists=$self->cvterm_pub_rank_exists();
    my $store= 0;
    if (!$exists) {
	$store= 1;
	my $query= "INSERT INTO cvterm_pub_ranking (cvterm_id,pub_id, rank, match_type, headline)
                     VALUES (?,?,?,?,?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id, $self->get_pub_id(), $self->get_rank(), $self->get_match_type(), $self->get_headline());
    }else{
	#is update necessary here? 
    }
    return $store;
}


=head2 get_cvterm_pub_rank

 Usage: $cvterm->get_cvterm_pub
 Desc:  find the publications associated with the cvterm and the sum of the ranking 
 Ret:   a hashref $pub_id => $total_rank
 Args:  none
 Side Effects: 
 Example:

=cut

sub get_cvterm_pub_rank {
    
    my $cvterm=shift;
    my $cvterm_id = $cvterm->get_cvterm_id();
 
    my $query = "SELECT pub_id, rank,match_type, headline
                 FROM cvterm_pub_ranking 
                 WHERE cvterm_id =?";
  
    my $sth=$cvterm->get_dbh()->prepare($query);
    $sth->execute($cvterm_id);
    my $total_cvterm_pub_rank={};
    my $cvterm_pub_rank={};

    while (my @pub = $sth->fetchrow_array() ) {
	$cvterm_pub_rank->{$pub[0]} += $pub[1]; # total rank for this publication
    }
    
    return $cvterm_pub_rank;
}



=head2 get_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_rank {
  my $self=shift;
  return $self->{rank};

}

=head2 set_rank

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_rank {
  my $self=shift;
  $self->{rank}=shift;
}

=head2 get_match_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_match_type {
  my $self=shift;
  return $self->{match_type};

}

=head2 set_match_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_match_type {
  my $self=shift;
  $self->{match_type}=shift;
}

=head2 get_headline

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_headline {
  my $self=shift;
  return $self->{headline};

}

=head2 set_headline

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_headline {
  my $self=shift;
  $self->{headline}=shift;
}

=head2 get_cvterm_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cvterm_id {
  my $self=shift;
  return $self->{cvterm_id};

}

=head2 set_cvterm_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cvterm_id {
  my $self=shift;
  $self->{cvterm_id}=shift;
}

=head2 get_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pub_id {
  my $self=shift;
  return $self->{pub_id};

}

=head2 set_pub_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pub_id {
  my $self=shift;
  $self->{pub_id}=shift;
}


=head2 add_cvterm_pub_rank

 Usage: $self->add_cvterm_pub_rank()
 Desc:   take the cvterm name and synonyms and find associated publications 
         by using a tsearch2 text indexing vector.
 Ret:    nothing
 Args:  none
 Side Effects: for each matching publication (see Chado::Publication::get_abstract_rank and get_title_rank)
               calling $self->do_insert(match_type, @publications) which stores a new CvtermRanking
 Example:

=cut

sub add_cvterm_pub_rank {
    my $cvterm=shift;
    my $cvterm_id = $cvterm->get_cvterm_id();
    my $self=CXGN::Chado::Cvterm::CvtermRanking->new($cvterm->get_dbh(), $cvterm_id, undef); #a new empty object for storing the new cvterm_pub_rank
    my %cvterm_pub=(); #hash for storing number of inserts per match_type

    my $name = CXGN::Tools::Tsearch::process_string($cvterm->get_cvterm_name());
    my @cvterm_synonyms=$cvterm->get_synonyms();
    my @synonyms=();
    foreach my $s(@cvterm_synonyms) {
	my $synonym=CXGN::Tools::Tsearch::process_string($s, 1);
	if (length($synonoym) >1 ) { push @synonyms, $synonym; }
    }
    my $syn_str = join('|', @synonyms);
    if (length($name) > 1) {
	my $name_abstract= CXGN::Chado::Publication::get_pub_rank($cvterm->get_dbh(), $name, 'abstract');
	$cvterm_pub{name_abstract}=$self->do_insert('name_abstract', $name_abstract) if $name_abstract;
	
	my $name_title= CXGN::Chado::Publication::get_pub_rank($cvterm->get_dbh(), $name, 'title');
	$cvterm_pub{name_title}=$self->do_insert('name_title', $name_title) if $name_title;
    }
    
    if ($syn_str) {
	my $synoym_abstract= CXGN::Chado::Publication::get_pub_rank($cvterm->get_dbh(), $syn_str, 'abstract');
	$cvterm_pub{synonym_abstract}=$self->do_insert('synonym_abstract', $synonym_abstract) if $synonym_abstract;
	
	my $synonym_title= CXGN::Chado::Publication::get_pub_rank($cvterm->get_dbh(), $syn_str, 'title');
	$cvterm_pub{synonym_title}=$self->do_insert('synonym_title', $synonym_title) if $synonym_title;
    }
    return %cvterm_pub;
}



=head2 cvterm_pub_rank_exists

 Usage: $self->cvterm_pub_exists()
 Desc:   check if a cvterm is matched with a pub 
 Ret:   number of times the match occurs
 Args:   none
 Side Effects: none
 Example:

=cut

sub cvterm_pub_rank_exists {
    my $self=shift;
    my $query = "SELECT count(*)  FROM phenome.cvterm_pub_ranking WHERE cvterm_id = ? AND pub_id = ? AND match_type= ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $self->get_pub_id(), $self->get_match_type());
    my ($result) = $sth->fetchrow_array();
   
    return $result; 
}


###
1;#do not remove
###

