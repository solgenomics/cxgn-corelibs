
=head1 NAME

CXGN::Transcript::EST - a class to deal with EST sequences.

=head1 DESCRIPTION

This class attempts to sanely wrap some of the more esoteric features of the sgn.est table, such as the flags and status fields, and provides accessors for all the database fields of sgn.est and sgn.qc_report. 

=head2 The meaning of the flag fields

The flag bits have the following meaning, according to documentation  by Koni:

=over 10

=item flag

 0x1	Vector parsing anomoly
 0x2	Possibly chimeric (vector parsing triggered)
 0x4	Insert too short
 0x8	High expected error (low base calling quality values overall)
 0x10	Low complexity
 0x20	E.coli or cloning host contamination
 0x40	rRNA contamination
 0x80	Possibly chimeric (arabidopsis screen)
 0x100	Possibly chimeric (internal screen during unigene assembly)
 0x200	Manually censored (reason may not be recorded)

=item status

 0x1	Legacy (sequence & identifier tracked for only legacy dataset support)
 0x2	Discarded (sequence is formally “forgotten”)
 0x4	Deprecated (will end up as 0x2 or 0x1 in subsequent releases)
 0x8	Censored (see also 0x200 in flags above)
 0x10	Vector/Quality not assessed
 0x20	Contaminants not assessed
 0x40	Chimera not assessed

=back

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

Adapted from the unstructured est detail page hacking that occurred over the years by multiple authors.

=head1 CLASS METHODS

The following class methods are implemented:

=cut

use strict;

package CXGN::Transcript::EST;

use CXGN::DB::Object;

use base qw | CXGN::DB::Object |;

our %flags = ( vector_parsing_anomaly => 0,
	       possibly_chimeric => 1,
	       insert_too_short => 2,
	       high_expected_error => 3,
	       low_complexity => 4,
	       ecoli_or_cloning_host_contamination => 5,
	       rRNA_contamination => 6,
	       possibly_chimeric_arabidopsis_screen => 7,
	       possibly_chimeric_unigene_assembly_screen => 8,
	       manually_censored => 9
	       );

our %status = ( legacy => 1,
		discarded => 2,
		deprecated => 3,
		censored => 4,
		vector_quality_not_assessed=>5,
		contaminats_not_assessed=>6,
		chimera_not_assessed=>7
		);
	       
	       


sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->set_est_id($id);
	$self->fetch();
    }
    return $self;
}

sub fetch { 
    my $self = shift;
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $query = "SELECT est_id, read_id, flags, status, seq as untrimmed_seq, substring(seq from hqi_start::int for hqi_length::int) as trimmed_seq, hqi_start, hqi_length, clone.clone_name, seqread.read_id, seqread.trace_name,seqread.direction, seqread.trace_location FROM $sgn.est LEFT JOIN $sgn.qc_report using(est_id) JOIN $sgn.seqread USING(read_id) JOIN $sgn.clone USING(clone_id) where est_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_est_id());
    my $h = $sth->fetchrow_hashref();
    $self->set_est_id($h->{est_id});
    $self->set_read_id($h->{read_id});
    $self->set_trimmed_seq($h->{trimmed_seq});
    $self->set_raw_seq($h->{untrimmed_seq});
    $self->set_hqi_start($h->{hqi_start});
    $self->set_hqi_length($h->{hqi_length});
    $self->set_clone_name($h->{clone_name});
    $self->set_direction($h->{direction});
    $self->set_trace_name($h->{trace_name});
    $self->set_trace_location($h->{trace_location});
    $self->set_status($h->{status});
    $self->set_flags($h->{flags});
    
}

=head2 new_with_alternate_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new_with_alternate_id {
    my $class = shift;
    my $dbh = shift;
    my $alternate_id = shift;
    my $q = "SELECT internal_id, internal_id_type, t1.comment, t2.comment from id_linkage as il LEFT OUTER JOIN types as t1 ON (t1.type_id=il.internal_id_type) LEFT OUTER JOIN types as t2 ON (t2.type_id=il.link_id_type) where il.link_id=?";

    # Not yet....

}



sub store { 
}

=head2 get_est_id, set_est_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_est_id {
  my $self=shift;
  return $self->{est_id};

}

sub set_est_id {
  my $self=shift;
  $self->{est_id}=shift;
}

=head2 get_read_id, set_read_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_read_id {
  my $self=shift;
  return $self->{read_id};

}

sub set_read_id {
  my $self=shift;
  $self->{read_id}=shift;
}

=head2 get_trimmed_seq

 Usage:
 Desc:         gets the trimmed seq. To set the trimmed seq,
               set the hqi_start and hqi_length parameters.
 Ret:
 Args:
 Side Effects: 
 Example:

=cut

sub get_trimmed_seq {
  my $self=shift;
  return $self->{trimmed_seq};

}

sub set_trimmed_seq { 
    my $self =shift;
    $self->{trimmed_seq}=shift;
}

=head2 get_trimmed_qscores

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_trimmed_qscores {

}

=head2 get_raw_qscores, set_raw_qscores

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_raw_qscores {
  my $self=shift;
  return $self->{raw_qscores};

}

sub set_raw_qscores {
  my $self=shift;
  $self->{raw_qscores}=shift;
}



=head2 get_raw_seq, set_raw_seq

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_raw_seq {
  my $self=shift;
  return $self->{raw_seq};

}

sub set_raw_seq {
  my $self=shift;
  $self->{raw_seq}=shift;
}




=head2 get_flags, set_flags

 Usage:
 Desc:         get/set the raw flag information. The flag
               field contains information about chimera
               status and contamination. This information
               is better accessed through dedicated accessors
               that are also provided instead of manipulating
               the flag field directly.
  Property:    the flags [byte]
 Side Effects: 
 Example:

=cut

sub get_flags {
  my $self=shift;
  return $self->{flags};

}

sub set_flags {
  my $self=shift;
  $self->{flags}=shift;
}

=head2 get_status, set_status

 Usage:
 Desc:         get/set the status flags. To set/get flags
               the get_flag_bit() accessors for each flag should be used 
               to manipulate the flag information
               (safer).
 Property:     
 Side Effects:
 Example:

=cut

sub get_status {
  my $self=shift;
  return $self->{status};

}

sub set_status {
  my $self=shift;
  $self->{status}=shift;
}


=head2 get_hqi_start, set_hqi_start

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_hqi_start {
  my $self=shift;
  return $self->{hqi_start};

}

sub set_hqi_start {
  my $self=shift;
  $self->{hqi_start}=shift;
}

=head2 get_hqi_length, set_hqi_length

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_hqi_length {
  my $self=shift;
  return $self->{hqi_length};

}


sub set_hqi_length {
  my $self=shift;
  $self->{hqi_length}=shift;
}

=head2 get_qstart, set_qstart

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_qstart {
  my $self=shift;
  return $self->{qstart};

}


sub set_qstart {
  my $self=shift;
  $self->{qstart}=shift;
}

=head2 get_qend, set_qend

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_qend {
  my $self=shift;
  return $self->{qend};

}

sub set_qend {
  my $self=shift;
  $self->{qend}=shift;
}

=head2 get_istart, set_iend

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_istart {
  my $self=shift;
  return $self->{istart};

}

sub set_istart {
  my $self=shift;
  $self->{istart}=shift;
}

=head2 get_iend, set_iend

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_iend {
  my $self=shift;
  return $self->{iend};

}

sub set_iend {
  my $self=shift;
  $self->{iend}=shift;
}

=head2 get_trace_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_trace_name {
  my $self=shift;
  return $self->{trace_name};

}

=head2 set_trace_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_trace_name {
  my $self=shift;
  $self->{trace_name}=shift;
}

=head2 get_direction

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_direction {
  my $self=shift;
  return $self->{direction};

}

=head2 set_direction

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_direction {
  my $self=shift;
  $self->{direction}=shift;
}

=head2 get_trace_location

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_trace_location {
  my $self=shift;
  return $self->{trace_location};

}

=head2 set_trace_location

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_trace_location {
  my $self=shift;
  $self->{trace_location}=shift;
}

=head2 get_clone_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_clone_name {
  my $self=shift;
  return $self->{clone_name};

}

=head2 set_clone_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_clone_name {
  my $self=shift;
  $self->{clone_name}=shift;
}

=head2 accessors get_flag_bit, set_flag_bit

 Usage:        my $est->set_flag_bit('possibly_chimeric', 1);
               my $est->set_flag_bit('insert_too_short', 0);
               my $low_complexity_flag = $est->get_flag_bit('low_complexity');
 Desc:         this function sets the flags using common accessors. The flag
               name has to be provided as an argument. The legal flags are:
               o vector_parsing_anomaly
               o possibly_chimeric
               o insert_too_short
               o high_expected_error
               o low_complexity
               o ecoli_or_cloning_host_contamination
               o rRNA_contamination
               o possibly_chimeric_arabidopsis_screen
               o possibly_chimeric_unigene_assembly_screen
               o manually_censored
               the program will die if an illegal flag name is supplied.
 Property      manipulates the flags property in the est table. The flags can
               be accessed collectively as an int using the accessors 
               get_flags() and set_flags()


=cut

sub get_flag_bit {
  my $self = shift;
  my $bit_name = shift;

  if (!exists($flags{$bit_name})) { die "no bit with name $bit_name"; }
  return $self->get_bit($self->get_flags(), $flags{$bit_name});

}

sub set_flag_bit {
  my $self = shift;
  my $bit_name = shift;
  my $bit_value = shift;

  if (!exists($flags{$bit_name})) { die "no bit with name $bit_name"; }

  my $new_flags = $self->set_bit($self->get_flags(), $flags{$bit_name}, $bit_value);

  $self->set_flags($new_flags);
  
}

=head2 accessors get_status_bit, set_status_bit

 Usage:        $est->set_status_bit('contaminants_not_assessed', 1)
 Desc:         sets specific bits in the status fields of the 
               sgn.est table. The currently defined status bit names are:
               o legacy
               o discarded
               o deprecated
	       o censored
	       o vector_quality_not_assessed
	       o contaminats_not_assessed
	       o chimera_not_assessed
               undefined status bit names will cause a die.
 Property:     The function accesses the status bits in the est table
               through the accessors set_status() and get_status().      

=cut

sub get_status_bit {
  my $self = shift;
  my $status_bit_name = shift;

  if (!exists($status{$status_bit_name})) { die "Status bit $status_bit_name does not exist!"; }
  return $self->get_bit($self->get_status(), $status{$status_bit_name});
}

sub set_status_bit {
  my $self = shift;
  my $status_bit_name = shift;
  my $value = shift;

  if (!exists($status{$status_bit_name})) { die "Status bit $status_bit_name does not exist!"; }
  my $new_status = $self->set_bit($self->get_status(), $status{$status_bit_name}, $value);
  $self->set_status($new_status);
}


=head2 function get_bit

 Usage:        my $new_int = $est->get_bit($int, $n)
 Desc:         sets the $n-th bit in $int and returns
               the corresponding new int $new_int.
 Example:      my $new_int = $est->get_bit($status, 4);
 Note:         used internally for the set_flag_bit() 
               and set_status_bit() accessors

=cut

sub get_bit {
  my $self = shift;
  my $int = shift;
  my $which_bit = shift;
  my $mask = 2 ** $which_bit;
  if ($int & $mask) { 
      return 1;
  }
  else { 
      return 0;
  }
  
}

=head2 function set_bit

 Usage:        
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub set_bit {
  my $self = shift;
  my $int = shift;
  my $which_bit = shift;
  my $value = shift;

  if ($value) { $value =1; }
  else { $value = 0; }

  my $ormask = 2 ** $which_bit;
  my $andmask =   1023 - $ormask;

  my $new_int = 0;
  if ($value ==1) {   $new_int = ($int | $ormask); }
  elsif ($value == 0) { $new_int = ($int & $andmask); }

  return $new_int;
}


###
1;#do not remove
###

