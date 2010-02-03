
=head1 NAME 

CXGN::Transcript::CDS - a class that deals with coding sequence associated with unigenes.

=head1 DESCRIPTION

Stores predicted CDS and protein sequences from unigene data. The two methods that are currently used are ESTScan and a simple longest 6 frame translation. 

The ESTScan CDS predictions contain edits. Insertions are reflected by inserted X's into the sequence, while removed nucleotides are represented by lower case letters in an uppercase background. This sequence is stored in the seq_text field. The actual cds sequence with the lower case letters removed is stored in the seq_edits table.

In general, the correct cds sequence is stored into cds.cds_seq column, and is available through the get_cds_seq accessor.
The corresponding protein sequence is available through get_protein_seq. Note that ESTScan has a bug in the way it calculates the protein (ignores N's in the nucleotide sequence); therefore, protein sequences need to be calculated using the the cds_translate.pl script in /sgn-tools/unigene.

The longest 6-frame translations can be generated using the get_longest_protein.pl script in /sgn-tools/protein. It returns both the cds and the protein sequence in two separate fasta files.


=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 EDITS

reformat_unigene_sequence_with_edit() added 06/23/08 by Mallory Freeberg

=head1 METHODS

This class defines the following methods:

=cut 

use strict;

package CXGN::Transcript::CDS;

use base qw | CXGN::DB::Object |; 
use base qw | Bio::Seq |;
use base qw | CXGN::Transcript::Unigene |;

=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->set_cds_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 new_with_unigene_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new_with_unigene_id {
    my $class = shift;
    my $dbh = shift;
    my $unigene_id = shift;
    my $sgn = $dbh->qualify_schema("sgn");
    my $query = "SELECT cds_id FROM $sgn.cds WHERE unigene_id = ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($unigene_id); 
    my ($cds_id) = $sth->fetchrow_array();
    
    my $self = CXGN::Transcript::CDS->new($dbh, $cds_id);
    return $self;
    
}

=head2 exists

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists {
    my $dbh = shift;
    my $unigene_id = shift;
    my $type = shift;
    
    my $query = "SELECT cds_id FROM sgn.cds WHERE unigene_id=? and type=?";
    
    my $sth = $dbh->prepare($query);
    $sth->execute($unigene_id, $type);

    my @cds_ids = ();
    while (my ($cds_id) = $sth->fetchrow_array()) { 
	push @cds_ids, $cds_id;
    }
    return @cds_ids;
    
}



=head2 fetch

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT cds_id, unigene_id, protein_feature_id, seq_text, seq_edits, cds_seq, protein_seq, cds.\"begin\", cds.\"end\", cds.forward_reverse, frame, cds.run_id, cds.score, method, preferred FROM sgn.cds WHERE cds_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cds_id());
    my ($cds_id, $unigene_id, $protein_feature_id, $seq_text, $seq_edits, $cds_seq, $protein_seq, $begin, $end, $forward_reverse, $frame, $run_id, $score, $method, $preferred) = 
	$sth->fetchrow_array();

    $self->set_cds_id($cds_id);
    $self->set_unigene_id($unigene_id);
    $self->set_protein_feature_id($protein_feature_id);
    $self->set_cds_seq($cds_seq);
    $self->set_seq_text($seq_text);
    $self->set_seq_edits($seq_edits);
    $self->set_protein_seq($protein_seq);
    $self->set_begin($begin);
    $self->set_end($end);
    $self->set_direction($forward_reverse);
    $self->set_frame($frame);
    $self->set_run_id($run_id);
    $self->set_score($score);
    $self->set_method($method);
    $self->set_preferred($preferred);

    return $cds_id;
}

sub store { 
    my $self = shift;
    if ($self->get_cds_id()) { 
	my $query = "UPDATE sgn.cds set
                     unigene_id=?, protein_feature_id=?, seq_text=?, seq_edits=?, cds_seq=?, protein_seq=?, \"begin\"=?, \"end\"=?, forward_reverse=?, frame=?, run_id=?, score=?, method=?, preferred=?
                     WHERE cds_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( 
		       $self->get_unigene_id(),
		       $self->get_protein_feature_id(),
		       $self->get_seq_text(),
		       $self->get_seq_edits(),
		       $self->get_cds_seq(),
		       $self->get_protein_seq(),
		       $self->get_begin(),
		       $self->get_end(),
		       $self->get_direction(),
		       $self->get_frame(),
		       $self->get_run_id(),
		       $self->get_score(),
		       $self->get_method(),
		       $self->get_preferred(),
		       $self->get_cds_id()
		       
		       
		       );

    }
    else { 
	my $query = "INSERT INTO sgn.cds (
                       unigene_id, protein_feature_id, seq_text, seq_edits, cds_seq, protein_seq, \"begin\", \"end\", forward_reverse, frame, run_id, score, method, preferred) VALUES (?, ?,?, ?, ?, ?, ?, ?, ?, ?,?, ?,?,? )";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		        $self->get_unigene_id(),
		      $self->get_protein_feature_id(),
		       $self->get_seq_text(),
		       $self->get_seq_edits(),
		      $self->get_cds_seq(),
		       $self->get_protein_seq(),
		       $self->get_begin(),
		       $self->get_end(),
		       $self->get_direction(),
		      $self->get_frame(),
		       $self->get_run_id(),
		       $self->get_score(),
		      $self->get_method(),
		      $self->get_preferred()
		      );
	return $self->get_currval("sgn.cds_cds_id_seq");
    }
    
}
 
=head2 accessors get_cds_id, set_cds_id

 Usage:
 Property:      the primary key of the table.

=cut

sub get_cds_id {
  my $self=shift;
  return $self->{cds_id};

}

sub set_cds_id {
  my $self=shift;
  $self->{cds_id}=shift;
}

=head2 accessors get_unigene_id, set_unigene_id

 Usage:
 Property:     foreign key to unigene. The unigene this
               cds entry is associated with.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_unigene_id {
  my $self=shift;
  return $self->{unigene_id};

}

sub set_unigene_id {
  my $self=shift;
  $self->{unigene_id}=shift;
}

=head2 accessors get_protein_feature_id, set_protein_feature_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_protein_feature_id {
  my $self = shift;
  return $self->{protein_feature_id}; 
}

sub set_protein_feature_id {
  my $self = shift;
  $self->{protein_feature_id} = shift;
}


=head2 accessors get_seq_text, set_seq_text

 Usage:        my $seq_text = $cds->get_seq_text()
 Desc:         gets the sequence text predicted by ESTScan.
               BIG CAVEAT: this sequence contains the nucleotides
               that ESTScan removed in lower case, while everything
               else is in uppercase. Use get_cds_seq() to get the 
               correct cds sequence irrespective of method used.
 Side Effects:
 Example:

=cut

sub get_seq_text {
  my $self=shift;
  return $self->{seq_text};

}

sub set_seq_text {
  my $self=shift;
  $self->{seq_text}=shift;
}

=head2 accessors get_cds_seq, set_cds_seq

 Usage:        my $cds_seq = $cds->get_cds_seq
 Desc:         gets the cds sequence 
 Side Effects: property usually set in constructor...
               the value is populated from the cds_seq field
               of the sgn.cds database table. This field contains
               the correct cds sequence irregardless of the method
               used.
 Example:

=cut

sub get_cds_seq {
  my $self=shift;
  return $self->{cds_seq};

}


sub set_cds_seq {
  my $self=shift;
  $self->{cds_seq}=shift;
}



=head2 accessors get_seq_edits, set_seq_edits

 Usage:        my $seq_edits = $cds->get_seq_edits
 Desc:         gets the sequence that ESTScan predicted
 Ret:          with the lower case letter removed.
               To access the cds irregardless of method used,
               use the get_cds_seq() accessor.
 Args:
 Side Effects:
 Example:

=cut

sub get_seq_edits {
  my $self=shift;
  return $self->{seq_edits};

}

sub set_seq_edits {
  my $self=shift;
  $self->{seq_edits}=shift;
}

=head2 accessors get_protein_seq, set_protein_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_protein_seq { 
    my $self=shift;
    return $self->{protein_seq};

}

sub set_protein_seq { 
  my $self=shift;
  $self->{protein_seq}=shift;
}

=head2 accessors get_begin, set_begin

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_begin {
  my $self=shift;
  return $self->{begin};

}

sub set_begin {
  my $self=shift;
  $self->{begin}=shift;
}

=head2 accessors get_end, set_end

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_end {
  my $self=shift;
  return $self->{end};

}

sub set_end {
  my $self=shift;
  $self->{end}=shift;
}

# =head2 accessors get_forward_reverse, set_forward_reverse

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_forward_reverse {
#   my $self=shift;
#   return $self->{forward_reverse};

# }

# sub set_forward_reverse {
#   my $self=shift;
#   $self->{forward_reverse}=shift;
# }


=head2 get_direction

 Usage:        my $direction = $cds->get_direction()
 Desc:         gets the direction of the cds relative to the 
               unigene. Either "F" for forward or "R" for 
               reverse.
 Side Effects: this property is set in the constructor. 
               it maps to the somewhat cumbersomly named 
               forward_reverse column in the database.
 Example:

=cut

sub get_direction {
  my $self=shift;
  return $self->{direction};

}

sub set_direction {
  my $self=shift;
  $self->{direction}=shift;
}

=head2 accessors get_frame, set_frame

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_frame {
  my $self=shift;
  return $self->{frame};

}


sub set_frame {
    my $self=shift;
    $self->{frame}=shift;
}



=head2 accessors get_run_id, set_run_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_run_id {
  my $self=shift;
  return $self->{run_id};

}

sub set_run_id {
  my $self=shift;
  $self->{run_id}=shift;
}

=head2 accessors get_score, set_score

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_score {
  my $self=shift;
  return $self->{score};

}

sub set_score {
  my $self=shift;
  $self->{score}=shift;
}

# =head2 accessors get_longest_frame_translation, set_longest_frame_translation

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_longest_frame_translation {
#   my $self=shift;
#   return $self->{longest_frame_translation};

# }

# sub set_longest_frame_translation {
#   my $self=shift;
#   $self->{longest_frame_translation}=shift;
# }

# =head2 accessors get_longest_frame, set_longest_frame

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_longest_frame {
#   my $self=shift;
#   return $self->{longest_frame};

# }

# sub set_longest_frame {
#   my $self=shift;
#   $self->{longest_frame}=shift;
# }

# =head2 function get_proteins

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_proteins {
#     my $self = shift;
#     my $sgn = $self->get_dbh()->qualify_schema("sgn");
#     my $query = "SELECT protein_id FROM $sgn.protein WHERE cds_id=?";
#     my $sth = $self->get_dbh()->prepare($query);
#     $sth->execute($self->get_cds_id());
#     my @proteins = ();
#     while (my ($protein_id) = $sth->fetchrow_array()) { 
# 	push @proteins, CXGN::Transcript::Protein->new($self->get_dbh(), $protein_id);
#     }
#     return @proteins;
# }


=head2 accessors get_method, set_method

 Usage:        my $method = $cds->get_method()
 Desc:         the method used to predict the cds/protein seq
 Ret:          either "estscan" or "longest6frame"
 Args:         none

=cut

sub get_method {
    my $self=shift;
    return $self->{method};

}

sub set_method {
    my $self=shift;
    $self->{method}=shift;
}


=head2 get_preferred

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_preferred {
    my $self=shift;
    
    return $self->{preferred};

}

=head2 set_preferred

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_preferred {
    my $self=shift;
    my $preferred = shift;
    if ($preferred=~/t/i) { 
	$preferred = 1;
    }
    if ($preferred=~/f/i) { 
	$preferred= 0;
    }
    $self->{preferred}=$preferred;
}

=head2 get_signalp_info

 Usage:        my ($nn_ypos, $nn_score, $nn_d) = $unigene->get_signalp_info()
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_signalp_info {
    my $self = shift;
    my $query = "SELECT nn_ypos, nn_score, nn_d 
	FROM public.signalp 
	WHERE cds_id=? ";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cds_id()); 
    my ($nn_ypos, $nn_score, $nn_d) = $sth->fetchrow_array();
    return ($nn_d, $nn_ypos, $nn_score);
}


=head2 function get_interpro_domains

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_interpro_domains {
    my $self = shift;
    my $query = "SELECT interpro_accession, interpro.description, match_begin, match_end 
						FROM sgn.interpro 
						LEFT JOIN sgn.domain USING (interpro_id) 
						LEFT JOIN sgn.domain_match USING (domain_id) 
						WHERE cds_id = ? 
							AND hit_status LIKE 'T'	";
    my $sth = $self->get_dbh()->prepare_cached($query);
    $sth->execute($self->get_cds_id());
    my @interpro_domain_list = ();
    while (my ($interpro_accession, $description, $match_begin, $match_end)= $sth->fetchrow_array()) { 
	push @interpro_domain_list, [$interpro_accession,$description, $match_begin, $match_end];
    }
    return @interpro_domain_list;

}

return 1;
