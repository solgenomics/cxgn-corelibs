package CXGN::Transcript::Unigene;

=head1 NAME

CXGN::Transcript::Unigene - a class to deal with unigenes in the SGN database

=head1 DESCRIPTION

The unigene table in the SGN database has complex relationships. This object deals with these relationships and adds some handy accessors for related data, such as member ship information and annotation information.

It inherits from CXGN::DB::Object for the database connection accessors.

Storing infomation back to the database is not fully supported. Some accessors that associate unigenes with other information will directly modify the database though. This is indicated in the pod.

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu> (July 2007)

Cobbled together from years of unstructured unigene detail page hacking by too many people.

=head1 MEMBER FUNCTIONS

This class implements the following functions:

=cut

use strict;
use warnings;
use Carp;

use CXGN::DB::Object;
use CXGN::Tools::WebImageCache;
use CXGN::Unigene::Tools;
use CXGN::Transcript::CDS;
use CXGN::Transcript::EST;
use CXGN::Transcript::UnigeneBuild;

use base qw | CXGN::DB::Object |;

=head2 constructor new

 Usage:        constructor
 Desc: 
 Ret:          a CXGN::Transcript::Unigene object
 Args:         a $dbh database handle, preferentially created
               using CXGN::DB::Connection
               a $id specifying a unigene
               if $id is omitted, an empty unigene object is 
               created.
 Side Effects: accesses the database
 Example:

=cut

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);

    if ($id=~/SGN-*U(\d+)/i) { 
	$id = $1; 
    }

    if ($id) { 
	$self->set_unigene_id($id);
	$self->fetch();
	if (!$self->get_unigene_id()) { 
	    return undef;
	}
    }
    return $self;
}


=head2 new_random

 Usage:        my $u = CXGN::Transcript::Unigene->new_randoma($dbh);
 Desc:         returns a random unigene. Used on the unigene
               search form.
 Ret:          a random unigene object.
 Args:
 Side Effects:
 Example:

=cut

sub new_random {
    my $class = shift;
    my $dbh = shift;
    my $query = "select unigene_id from sgn.unigene LEFT JOIN sgn.unigene_build USING (unigene_build_id) where sgn.unigene_build.status='C' and nr_members>1 order by random() limit 1";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my ($unigene_id) = $sth->fetchrow_array();
    
    my $self = $class->new($dbh, $unigene_id);
    return $self;
    
}

=head2 new_lite_unigene

 Usage:        my $unigene_lite = CXGN::Transcript::Unigene->new_lite_unigene($dbh, $id)
 Desc:         instantiateds a "light" unigene object, meaning one 
               that has not all the accessors populated.
               List of accessors that can be used on a light object:
               [TO BE DETERMINED]
               The purpose of this object is to have a faster unigene
               object.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new_lite_unigene {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    
    #if ($id=~/SGN-*U(\d+)/i) { 
#	$id = $1; 
#    }
    
    if ($id) { 
	$self->set_unigene_id($id);
	$self->fetch_lite($id);
	#if (!$self->get_unigene_id()) { 
	#    return undef;
	#}
    }
    return $self;
}    

sub fetch_lite { 
    my $self =shift;
    my $query = "SELECT unigene_id, unigene_build_id, nr_members, build_nr,  database_name, sequence_name, status FROM sgn.unigene LEFT JOIN sgn.unigene_build using(unigene_build_id) WHERE unigene_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my ($unigene_id, $unigene_build_id, $nr_members, $build_nr, $database_name, $sequence_name, $status) = $sth->fetchrow_array();
    $self->set_unigene_id($unigene_id);
    $self->set_build_id($unigene_build_id);
    $self->set_build_nr($build_nr);
    $self->set_nr_members($nr_members);
    $self->set_alternate_namespace($database_name);
    $self->set_alternate_identifier($sequence_name);
    $self->set_status($status);
}

# deprecated. This should be in UnigeneBuild.
#
sub get_unigene_ids_by_build_id { 
    my $dbh = shift;
    my $build_id = shift;
    my $query = "SELECT unigene_id FROM sgn.unigene WHERE unigene_build_id=? ORDER BY unigene_id";
    my $sth = $dbh->prepare($query);
    $sth->execute($build_id);
    my @unigene_ids = ();
    while (my ($unigene_id) = $sth->fetchrow_array()){ 
	push @unigene_ids, $unigene_id;
    }
    return @unigene_ids;
}

sub fetch { 
    my $self =shift;
    my $query = "SELECT unigene_id, unigene_build_id, nr_members, build_nr, seq, qscores, database_name, sequence_name FROM 
                 sgn.unigene LEFT JOIN sgn.unigene_consensi using(consensi_id) LEFT JOIN sgn.unigene_build using(unigene_build_id) WHERE 
                 unigene_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my ($unigene_id, $unigene_build_id, $nr_members, $build_nr, $seq, $qscores, $database_name, $sequence_name) = 
	$sth->fetchrow_array();
    $self->set_unigene_id($unigene_id);
    $self->set_build_id($unigene_build_id);
    $self->set_build_nr($build_nr);
    $self->set_nr_members($nr_members);
    $self->set_sequence($seq);
    $self->set_scores($qscores);
    $self->set_alternate_namespace($database_name);
    $self->set_alternate_identifier($sequence_name);
    
    # if it is a singleton unigene, fetch the sequence data from the
    # est table, using trimming information in the qc_report table.
    #         (substring(est.seq FROM qc_report.hqi_start::int FOR qc_report.hqi_length::int)) as trimmed 
    if ($nr_members ==1) { 
	my $est_q = "SELECT est.seq as raw, est.qscore, qc_report.hqi_start, hqi_length
                   
                     FROM sgn.unigene_member JOIN sgn.est USING (est_id)
                     JOIN sgn.qc_report ON (est.est_id=qc_report.est_id) 
                    WHERE sgn.unigene_member.unigene_id=?";
	my $est_h = $self->get_dbh()->prepare($est_q);
	$est_h->execute($self->get_unigene_id());
	my ($raw, $scores, $hqi_start, $hqi_length) = $est_h->fetchrow_array();

	# tri both sequence and scores...
	#
	my $trimmed = substr($raw, $hqi_start, $hqi_length);
	$self->set_sequence($trimmed);

	my @scores = split /\s+/, $scores;
	my $score_string = join " ", (@scores[$hqi_start..($hqi_length+$hqi_start)]);

	#print STDERR "length raw: ".length($raw)." START: $hqi_start LENGTH: $hqi_length\n";
	$self->set_scores($score_string);

    }

    # get the estscan predicted peptide and cds sequences
    #
    my $estscan_q = "SELECT cds_id, seq_text, protein_seq, forward_reverse, run_id, score 
                     FROM sgn.cds WHERE unigene_id=?";
    my $estscan_h = $self->get_dbh()->prepare($estscan_q);
    $estscan_h->execute($self->get_unigene_id());
    my ($cds_id, $seq_text, $protein_seq, $forward_reverse, $run_id, $score) = 
	$estscan_h->fetchrow_array();
    
    $self->set_estscan_protein($protein_seq);
    $self->set_estscan_cds($seq_text);
    $self->set_estscan_direction($forward_reverse);
}

=head2 get_unigene_id, set_unigene_id

  Usage:        $id = $unigene->get_unigene_id()
  Property:     the unique id of the unigene as an int.
               see get_sgn_id for obtaining a formatted
               sgn identifier.
 
=cut

sub get_unigene_id {
  my $self=shift;
  return $self->{unigene_id};
}

sub set_unigene_id {
  my $self=shift;
  $self->{unigene_id}=shift;
}


=head2 get_status, set_status

  Usage:        $status = $unigene->get_status()
  Property:     the status of the unique as a single character .
                'C' = current
                'P' =
                'D' = 
 
=cut

sub get_status {
  my $self=shift;
  return $self->{status};
}

sub set_status {
  my $self=shift;
  $self->{status}=shift;
}

=head2 function get_sgn_id

 Usage:        my $id = $unigene->get_sgn_id()
 Desc:         returns the unigene id formatted in the 
               standard sgn way, eg, SGN-U222222
               to set the id, use the set_unigene_id
               setter.

=cut

sub get_sgn_id {
  my $self=shift;
  return "SGN-U".$self->{unigene_id};
}

=head2 accessors get_build_id, set_build_id

 Usage:       
 Property:     the build_id of the unigene. This id can
               be used to instantiate a unigene_build object.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_build_id {
  my $self=shift;
  return $self->{build_id};

}

sub set_build_id {
  my $self=shift;
  $self->{build_id}=shift;
}

=head2 get_unigene_build

 Usage:        my $unigene_build = $u->get_unigene_build();
 Desc:         returns a L<CXGN::Transcript::UnigeneBuild> object
               corresponding to the build of this unigene.
 Ret:          a L<CXGN::Transcript::UnigeneBuild> object
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_unigene_build {
    my $self = shift;
    return my $unigene_build = CXGN::Transcript::UnigeneBuild->new($self->get_dbh(), $self->get_build_id());
}



=head2 get_build_nr, set_build_nr

 Usage:        my $build_nr = $u->get_build_nr();
 Desc:         the build nr is a counter of how many builds
               have been created for a given set of input 
               data. Not to be confused with the unigene_build_id.
 Ret:          the build_nr, and integer.
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_build_nr {
  my $self=shift;
  return $self->{build_nr};

}


sub set_build_nr {
  my $self=shift;
  $self->{build_nr}=shift;
}





=head2 accessors get_sequence, set_sequence

 Usage:        my $seq = $unigene->get_sequence()
 Desc:         returns the DNA sequence of the unigene.
               if the unigene is a contig, returns the sequence
               of the contig, and if the unigene is a singleton,
               returns the trimmed est sequence.

=cut

sub get_sequence {
  my $self=shift;
  return $self->{sequence};

}

sub set_sequence {
  my $self=shift;
  $self->{sequence}=shift;
}

=head2 accessors get_scores, set_scores

 Usage:        my @scores = $unigene->get_scores()
 Desc:         returns a list of score values for each 
               nucleotide position in the unigene.

=cut

sub get_scores {
  my $self=shift;
  return $self->{scores};

}

sub set_scores {
  my $self=shift;
  $self->{scores}=shift;
}

=head2 accessors get_nr_members, set_nr_members

 Usage:        my $member_count = $unigene->get_nr_members();
 Desc:         returns the number of member sequences (ESTs)
               that compose the unigene.

=cut

sub get_nr_members {
  my $self=shift;
  return $self->{nr_members};

} 

sub set_nr_members {
  my $self=shift;
  $self->{nr_members}=shift;
}

=head2 add_est_member

 Usage:
 Desc:
 Ret:          nothing
 Args:         $est - a CXGN::Transcript::EST object
               $qstart int
               $end int
               $qstart int
               $qend int

 Side Effects: modifies the database in realtime.
 Example:

=cut

sub add_est_member {
    my $self = shift;
    my $est_object = shift;
    my $start = shift;
    my $end = shift;
    my $qstart = shift;
    my $qend = shift;
    my $query = "INSERT INTO sgn.unigene_member (unigene_id, est_id, start, end, qstart, qend) VALUES (?,?,?,?,?,?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute(
		  $self->get_unigene_id(),
		  $est_object->get_est_id(),
		  $start,
		  $end,
		  $qstart,
		  $qend
		  );
    
        
}


=head2 function get_member_est_ids

 Usage:        my @est_ids = $unigene->get_member_est_ids()
 Desc:         returns the ids of member ids as a list
 Side Effects: accesses the database

=cut

sub get_member_est_ids {
    my $self = shift;
    my $query = "SELECT est_id FROM sgn.unigene_member WHERE unigene_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @est_ids = ();
    while (my ($est_id) = $sth->fetchrow_array()) { 
	push @est_ids, $est_id;
    }
    return @est_ids;
}

=head2 get_member_ests

 Usage:        my @est_obj = $unigene->get_member_ests()
 Desc:         returns the member ests as a list of 
               CXGN::Transcript::EST objects
 Ret:          a list of CXGN::Transcript::EST objects
 Args:         none
 Side Effects: accesses the database

=cut

sub get_member_ests {
    my $self = shift;
    my @est_ids = $self->get_member_est_ids();
    my @ests = ();
    foreach my $est_id (@est_ids) { 
	push @ests, CXGN::Transcript::EST->new($self->get_dbh(), $est_id);
    }
    return @ests;
}

=head2 get_est_align_coords

 Usage:
 Desc:         returns $start, $stop, $qstart, $qend, $dir
               for the alignment of a member sequence
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_est_align_coords {
    my $self = shift;
    my $est_id = shift;
    
    my $query = "SELECT  start, stop, qstart, qend, dir
		 FROM sgn.unigene LEFT JOIN sgn.unigene_member USING (unigene_id) 
                 WHERE sgn.unigene.unigene_id=? AND est_id=?	";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id(), $est_id);
    
    my ($start, $stop, $qstart, $qend, $dir) = $sth->fetchrow_array();
#    print STDERR "**** EST: $start,$stop, $qstart, $qend, $dir\n";
    return ($start, $stop, $qstart, $qend, $dir);
    
}

=head2 get_manual_annotations

 Usage:        my @a = $u->get_manual_annotations();
 Desc:         returns the manual annotations for this unigene.
 Ret:          a list of lists, with the following columns:
               1. annotator name
               2. annotation date
               3. annotation last modified
               4. annotation text
               5. clone_name
               6. clone id
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_manual_annotations {
    my $self = shift;
    my $query = "SELECT sgn_people.sp_person.first_name || ' ' || sgn_people.sp_person.last_name, 
				manual_annotations.date_entered, 
				manual_annotations.last_modified, 
				manual_annotations.annotation_text, 
				clone.clone_name, 
				clone.clone_id 
		FROM sgn.unigene 
		LEFT JOIN sgn.unigene_member USING (unigene_id) 
		LEFT JOIN sgn.est USING (est_id) 
                LEFT JOIN sgn.seqread USING (read_id) 
		LEFT JOIN sgn.clone USING (clone_id) 
		LEFT JOIN sgn.manual_annotations ON (clone.clone_id = manual_annotations.annotation_target_id) 
		LEFT JOIN sgn_people.sp_person ON (manual_annotations.author_id = sgn_people.sp_person.sp_person_id) 
		LEFT JOIN sgn.annotation_target_type ON (manual_annotations.annotation_target_type_id = annotation_target_type.annotation_target_type_id) 
		WHERE sgn.unigene.unigene_id=? 
			AND sgn.annotation_target_type.type_name='clone'
		";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @list = ();
    while (my @data = $sth->fetchrow_array()) { 
	push @list, \@data;
    }
    return @list;

}

=head2 accessors get_alternate_namespace, set_alternate_namespace

 Usage:        my $db = $unigene->get_alternate_namespace()
 Desc:        
 Property:     each unigene can have an alternate namespace associate with
               it, which is stored in the sgn.unigene.database_name field.
               the get_alternate_identifier() accessor gets the associated 
               identifer, stored in the sgn.unigene.sequence_name field.
 Side Effects:
 Example:

=cut

sub get_alternate_namespace {
  my $self = shift;
  return $self->{alternate_namespace}; 
}

sub set_alternate_namespace {
  my $self = shift;
  $self->{alternate_namespace} = shift;
}
=head2 accessors get_alternate_identifier, set_alternate_identifier

 Usage:        my $alternate = $u->get_alternate_namespace().$u->get_alterante_identifer
 Desc:         gets the alternate identifier. Currently used to store legacy
               identifiers for coffee unigenes.
 Property:     
 Side Effects:
 Example:

=cut

sub get_alternate_identifier {
  my $self = shift;
  return $self->{alternate_identifier}; 
}

sub set_alternate_identifier {
  my $self = shift;
  $self->{alternate_identifier} = shift;
}



=head2 function get_arabidopsis_annotations

 Usage:         @annotations = $unigene->get_arabidopsis_annotations(1e-6)
 Desc:          gets the blast-based annotation against arabidopsis
 Ret:           a list of lists of annotations, sorted by score descending.
                The list of list consists of the following headers:
                  blast_db_id
                  seq_id
                  evalue
                  score
                  identities
                  start_coord
                  end_coord
                  annotation text
                
 Args:          an optional evalue cutoff. Default is 1.
 Note:          the corresponding setter is not implemented.
 Side Effects:
 Example:

=cut

sub get_arabidopsis_annotations {
  my $self=shift;
  my $evalue_cutoff = shift || 1;
  return $self->get_annotations(2, $evalue_cutoff);
}

sub set_arabidopsis_annotations {
  my $self=shift;

}

=head2 function get_annotation_string

 Usage:  print $unigene->get_annotation_string(1e-10, 200);
 Desc:   Concats the arabidopsis, then genbank deflines with ';'
 Ret:    A string representing the unigene annotation
 Args:   (float) The max evalue for match
         (int) limit characters of annotation, unlimited by default.
		   Will only cut-off middle of annotation item if it is the 
		   first item, otherwise the item is not added

=cut

sub get_annotation_string {
	my $self = shift;
	my ($evalue, $limit) = @_;
	my @annotations = ();
	foreach($self->get_arabidopsis_annotations($evalue), $self->get_genbank_annotations($evalue)) {
		push(@annotations, pop @$_);
	}
	my $annotation_string = "";
	foreach my $annot (@annotations){
		if(defined($limit) && (length($annotation_string) + length("; $annot")) > $limit){
			unless($annotation_string){
				$annotation_string = substr($annot, 0, $limit);
			}
			last;
		}
		$annotation_string .= "; " if($annotation_string);	
		$annotation_string .= $annot;
	}
	return $annotation_string;
}

=head2 function get_genbank_annotations

 Usage:        my @annotations = $unigene->get_genbank_annotation(1e-7)
 Desc:         retrieves the genbank blast annotations from the db.
 Ret:          a list of lists, see get_arabidopsis_annotations().
 Args:         
 Side Effects:
 Example:

=cut

sub get_genbank_annotations {
  my $self=shift;
  my $evalue_cutoff = shift || 1;
  return $self->get_annotations(1, $evalue_cutoff);

}

sub set_genbank_annotations {
  my $self=shift;
  
}

=head2 function get_annotations

 Usage:        
 Desc:
 Ret:
 Args:         the blast annotation target database id
               which is 1 for genbank nr
                        2 for arabidopsis
                        3 for swissprot
 Side Effects:
 Example:

=cut

sub get_annotations {
    my $self = shift;
    my $blast_target_id = shift;
    my $evalue_cutoff = shift || 1;
    my $query = "SELECT blast_annotations.blast_target_id, blast_hits.target_db_id, evalue, score, identity_percentage, apply_start, apply_end, defline FROM sgn.blast_annotations JOIN sgn.blast_hits using(blast_annotation_id) JOIN sgn.blast_defline USING(defline_id) WHERE apply_id=? AND apply_type=15  AND sgn.blast_annotations.blast_target_id=? AND evalue<? ORDER BY score desc";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id(), $blast_target_id, $evalue_cutoff);

    my @annotations = ();
    while (my @data = $sth->fetchrow_array()) { 
	push @annotations, \@data;
    }
    return @annotations;
    

}


=head2 function get_microarray_info

 Usage:        my @microarray_info = $u->get_microarray_info()
 Desc:         returns information on whether and where this 
               unigene has representation on a microarray.
 Ret:          returns a list of hashrefs with the following keys:
               * clone_id
               * est_id
               * direction
               * chip_name
               * release
               * version
               * spot_id
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_microarray_info {
    my $self = shift;

    my $sgn = $self->get_dbh()->qualify_schema("sgn");

    my $query = "SELECT clone.clone_id as clone_id, est.est_id as est_id, seqread.direction as direction,
                 chip_name, release, microarray.version as version, spot_id, 
                 content_specific_tag 
		 FROM sgn.unigene 
		 LEFT JOIN sgn.unigene_member USING (unigene_id) 
		 LEFT JOIN sgn.est USING (est_id) 
		 LEFT JOIN sgn.seqread using (read_id) 
		 LEFT JOIN sgn.clone using (clone_id) 
		 INNER JOIN sgn.microarray using (clone_id) 
		 WHERE sgn.unigene.unigene_id=? 
		 ORDER BY sgn.clone.clone_id";
    my $sth  = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @answer = ();
    while (my $hashref = $sth->fetchrow_hashref()) { 
	push @answer, $hashref;
    }
    return @answer;
}


=head2 get_mapped_members

 Usage:        my @mapped = $u->get_mapped_members();
 Desc:         returns information on the mapping of 
               member EST sequences
 Ret:          a list of hashrefs with the following keys:
               * clone_id
               * marker_id
 Args:
 Side Effects:
 Example:

=cut

sub get_mapped_members {
    my $self =shift;
    my $query = "
    SELECT 
        ests_mapped_by_clone.clone_id as clone_id, 
        marker_id
    FROM 
        sgn.unigene_member 
        INNER JOIN sgn.est USING (est_id) 
        INNER JOIN sgn.seqread USING (read_id) 
        INNER JOIN sgn.ests_mapped_by_clone USING (clone_id) 
    WHERE 
        unigene_id=?
";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @clone_marker_list = ();
    while (my $data =$sth->fetchrow_hashref()) { 
	push @clone_marker_list, $data;
    }
    return @clone_marker_list;
}

=head2 get_cosii_info

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_cosii_info {
    my $self =shift;

    my $sth=$self->get_dbh()->prepare("select marker_id,alias from sgn.cosii_ortholog inner join sgn.marker using (marker_id) inner join sgn.marker_alias using (marker_id) where preferred='t' and (unigene_id=?)");
    $sth->execute($self->get_unigene_id());

    my @cosii_data = ();
    while(my ($marker_id,$marker_name)=$sth->fetchrow_array())
    {
	push @cosii_data, [$marker_id, $marker_name];

    }

    return @cosii_data;
    ###########################################
    #end COSII marker section inserted by john. 

}



=head2 get_estscan_cds, set_estscan_cds

 Usage:        DEPRECATED
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_estscan_cds {
  my $self=shift;
  return $self->{estscan_cds};

}

sub set_estscan_cds {
  my $self=shift;
  $self->{estscan_cds}=shift;
}

=head2 get_estscan_protein, set_estscan_protein

 Usage:        DEPRECATED
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_estscan_protein {
  my $self=shift;
  return $self->{estscan_protein};

}

sub set_estscan_protein {
  my $self=shift;
  $self->{estscan_protein}=shift;
}

=head2 get_estscan_direction

 Usage:        DEPRECATED
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_estscan_direction {
  my $self=shift;
  return $self->{estscan_direction};

}

sub set_estscan_direction {
  my $self=shift;
  $self->{estscan_direction}=shift;
}


=head2 get_cds_list()

 Usage:        my @cds = $unigene->get_cds_list()
 Desc:         returns the associated CDS objects, which
               contain cds and protein information 
               see L<CXGN::Transcript::CDS> for more info.
 Ret:          returns a list of CXGN::Transcript::CDS objects
 Args:         none.
 Side Effects: accesses the database.

=cut

sub get_cds_list {
    my $self = shift;
    my $query = "SELECT cds_id FROM sgn.cds WHERE unigene_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @cds_ids = ();
    while (my ($cds_id) = $sth->fetchrow_array()) { 
	push @cds_ids, CXGN::Transcript::CDS->new($self->get_dbh(), $cds_id);
    }
    return @cds_ids;
}

=head2 function gene_ontology_annotations

 Usage:        my @go_annots = $u->gene_ontology_anntations()
 Desc:         returns go annotation information for this unigene
 Ret:          a list of lists, with the following columns:
               1. go_accession
               2. go_description
 Args:         none
 Side Effects: accesses the database.
 Example:

=cut

sub gene_ontology_annotations {
    my $self = shift;

    my $query = "	SELECT g.go_accession, g.description 
						FROM sgn.domain_match AS dm,  
							sgn.domain AS d, 
							sgn.interpro AS i, 
							sgn.interpro_go AS ig, 
							sgn.go AS g 
						WHERE dm.domain_id = d.domain_id 
							AND d.interpro_id = i.interpro_id 
							AND i.interpro_accession = ig.interpro_accession 
							AND ig.go_accession = g.go_accession 
							AND dm.hit_status = 'T' 
							AND dm.unigene_id=?	";

    my $sth  = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id);
    
    my @go_annotations = ();
    while (my ($go_accession, $go_description) = $sth->fetchrow_array()) { 
	push @go_annotations, [$go_accession, $go_description];
    }
    return @go_annotations;
    
}


=head2 get_families

 Usage:        my @family_data = $unigene->get_families();
 Desc:       
 Ret:          a list of arrayrefs that contain family_id, i_value, 
               family_annotation, and member_count.
 Args:         none
 Side Effects: accesses da database.
 Example:

=cut

sub get_families {

    my $self = shift;
    

# $family_q = $dbh->prepare("	SELECT i_value, family.family_id, family_annotation, status
# 							FROM sgn.family_build 
# 							INNER JOIN sgn.family USING (family_build_id) 
# 							INNER JOIN sgn.family_member USING (family_id) 
# 							INNER JOIN cds USING (cds_id) 
# 							WHERE unigene_id = ?
# 						");

# $family_member_q = $dbh->prepare("	SELECT count(family_member_id) 
# 									FROM family_member 
# 									WHERE family_id = ? 
# 									GROUP BY family_id	");
######################################################

    my $family_group_h = $self->get_dbh()->prepare("	SELECT max(group_id) 
									FROM sgn.family_build 
									INNER JOIN sgn.family USING (family_build_id) 
									INNER JOIN sgn.family_member USING (family_id) 
									INNER JOIN sgn.cds USING (cds_id) 
									WHERE unigene_id=?		");
    $family_group_h->execute($self->get_unigene_id());
    my ($group_id) = $family_group_h->fetchrow_array();

    
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $family_q = $self->get_dbh()->prepare("	SELECT  sgn.family.family_id, i_value, family_annotation
							FROM $sgn.family_build 
							JOIN $sgn.family USING (family_build_id) 
							JOIN $sgn.family_member USING (family_id) 
							JOIN $sgn.cds USING(cds_id)
                                                        WHERE   group_id=? AND
								unigene_id = ? 
--AND $sgn.family_build.status='C' --
                                                        GROUP BY family_id, i_value, family_annotation
                                                        ORDER BY family_id"	);

    $family_q ->execute($group_id, $self->get_unigene_id());
    my @family_data = ();


    while (my ($family_id, $i_value, $family_annotation, $member_count) = $family_q->fetchrow_array())  {
	my $member_count_q = $self->get_dbh()->prepare("SELECT count(*) from $sgn.family_member WHERE family_id=?");
	$member_count_q->execute($family_id);
	my ($member_count) = $member_count_q->fetchrow_array();
	push @family_data, [$family_id, $i_value, $family_annotation, $member_count];
    }
    return @family_data;

}

=head2 get_current_unigene_ids

 Usage:        my @current_unigene_ids = $unigene_build->get_current_unigene()
 Desc:         returns the unigene ids of the current unigene build that share
               ESTs with the given unigene id. 
 Ret:          a list of unigene ids
 Args:         none
 Side Effects: accesses the database

=cut

sub get_current_unigene_ids {
    my $self = shift;
    #If the build is deprecated, run this query to find the updated unigene(s)
    my $unigene_updatedq = $self->get_dbh->prepare
	("
	SELECT distinct unigene_id FROM sgn.unigene_member
		JOIN sgn.unigene USING (unigene_id) 
		JOIN sgn.unigene_build USING (unigene_build_id) 
	WHERE 
		est_id IN 
			(select est_id FROM unigene_member WHERE unigene_id=?)  
		AND status = 'C' 
		AND unigene_build_id = 
			( SELECT latest_build_id FROM unigene_build 
			  WHERE unigene_build_id = 
			  	( SELECT unigene_build_id FROM unigene 
				  WHERE unigene_id=?
				)
			)
      ");

    my $unigene_id = $self->get_unigene_id();
    
    $unigene_updatedq ->execute($unigene_id, $unigene_id);
    my @unigene_ids = ();
    while (my ($updated_id) = $unigene_updatedq->fetchrow_array()) { 
	push @unigene_ids, $updated_id;
    }
    return @unigene_ids;
}

=head2 get_preceding_unigene_ids

 Usage:        my @preceding_unigene_ids = $unigene_build->get_preceding_unigene_ids($unigene_id)
 Desc:         returns the preceding unigene ids. A list because
               sometimes unigenes are merged.
 Ret:          a list of unigene ids from the previous build.
 Args:         unigene_id
 Side Effects: 
 Example:

=cut

sub get_preceding_unigene_ids {
    my $self = shift;

    #Find the preceding unigene(s) if there is a preceding build
    my $unigene_precededq = $self->get_dbh()->prepare
	("
	SELECT distinct unigene_id FROM sgn.unigene_member
		JOIN sgn.unigene USING (unigene_id) 
		JOIN sgn.unigene_build USING (unigene_build_id) 
	WHERE   unigene_id != ? AND
		est_id IN 
			(select est_id FROM sgn.unigene_member WHERE unigene_id=?)  
		AND unigene_build_id = 
			( SELECT unigene_build_id FROM sgn.unigene_build 
			  WHERE next_build_id = 
			  	( SELECT unigene_build_id FROM sgn.unigene 
				  WHERE unigene_id=?
				)
			)
        ");
    
    $unigene_precededq->execute($self->get_unigene_id(), $self->get_unigene_id(), $self->get_unigene_id());
    my @unigene_ids = ();
    while (my ($old_id) = $unigene_precededq->fetchrow_array()) { 
	if ($old_id) { push @unigene_ids, $old_id; }
    }
    return @unigene_ids;
     
}

=head2 superseding_build_info

 Usage:        my ($superseding_build_name, $build_nr) = 
                 $unigene->superseding_build_info();
 Desc:         gets the build name and the build_nr (not the build_id!)
               for the current unigene.
 Side Effects: Accesses the database.

=cut

sub superseding_build_info { 
    my $self = shift;
    
#Find superseding build name, given unigene_id
    my $sth = $self->get_dbh->prepare
	("
	SELECT groups.comment, build_nr FROM sgn.unigene_build 
		JOIN sgn.groups ON (organism_group_id=group_id)
	WHERE
		unigene_build_id = 
		( SELECT latest_build_id FROM sgn.unigene_build
		  WHERE
			unigene_build_id =
			( SELECT unigene_build_id FROM sgn.unigene
			  WHERE
				unigene_id=?
			)
		)
        ");
    $sth->execute($self->get_unigene_id());
    my ($superseding_build_name, $build_nr) = $sth->fetchrow_array();
    return ($superseding_build_name, $build_nr);
}



=head2 get_unigene_member_count_in_library

 Usage:        my $count = $u->get_unigene_member_count_in_library($library_id)
 Desc:         gives the number of ESTs that are present in this
               unigene from library $library_id
 Ret:          the number of ESTs, an integer.
 Args:         the library_id

=cut

sub get_unigene_member_count_in_library {
    my $self = shift;
    my $library_id = shift;
    my $query = "SELECT count(*) FROM sgn.unigene 
		   LEFT JOIN sgn.unigene_member USING (unigene_id) 
		   LEFT JOIN sgn.est USING (est_id) 
	  	   LEFT JOIN sgn.seqread USING (read_id) 
		   LEFT JOIN sgn.clone USING (clone_id) 
  		   LEFT JOIN sgn.library USING (library_id)  
      		   WHERE sgn.unigene.unigene_id=? AND sgn.library.library_id=?";

    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id(), $library_id);
    my ($count) = $sth->fetchrow_array();
    return $count;
}

=head2 function get_member_library_ids

 Usage:        my @library_ids = $unigene->get_member_library_ids()
 Desc:         returns a list of library ids that are the source of 
               the member ests of this unigene, sorted by the descending
               number of member sequences (descending)
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_member_library_ids {
    my $self = shift;
    my $sgn = $self->get_dbh()->qualify_schema("sgn");
    my $query = "SELECT library_id, count(*) as c FROM sgn.unigene_member 
                  JOIN sgn.est USING(est_id) 
                  JOIN sgn.seqread USING(read_id) 
                  JOIN sgn.clone using(clone_id) 
                  WHERE unigene_id=? 
                  GROUP BY library_id 
                  ORDER BY c desc";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @library_ids = ();
    while (my ($library_id, $count) = $sth->fetchrow_array()) { 
	push @library_ids, $library_id;
    }
    return @library_ids;
}

=head2 get_associated_loci

 Usage:        my @associated_loci = $unigene->get_associated_loci($obsolete);
 Desc:         gets all the loci that are associated with this unigene 
 Ret:          a CXGN::Phenome::Locus object
 Args:         $obsolete ['f' or 't' optional] passing this arg will fetch only the non-obsolete links, or all the obsolete
                unigene-locus associations (may be useful for an unobsolete function)
 Side Effects: accesses the database

=cut

sub get_associated_loci {
    my ( $self, $obs ) = @_;

    my $query = "SELECT locus_id FROM phenome.locus_unigene WHERE unigene_id=?";
    my @bind = ( $self->get_unigene_id );

    if( defined $obs ) {
        $obs = lc $obs;
        $obs eq 't' || $obs eq 'f'
            or croak "obsolete must be either 't' or 'f' if passed";

        $query .= " AND phenome.locus_unigene.obsolete = ?";
        push @bind, $obs;
    }

    my $sth = $self->get_dbh()->prepare_cached($query);
    $sth->execute(@bind);

    my @loci = ();
    while (my ($locus_id) = $sth->fetchrow_array()) { 
	push @loci, CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
    }
    return @loci;
}

=head2 function get_preferred_protein

 Usage:        my $cds_id = $u->get_preferred_protein()
 Desc:         selects the so-called preferred protein among
               all the protein predictions for this unigene.
               The preferred protein is set using the function
               determine_and_set_preferred_protein().
 Ret:          the cds_id of the preferred protein prediction.
 Args:         none
 Side Effects: none
 Example:

=cut

sub get_preferred_protein {
    my $self = shift;
    my $query = "SELECT cds_id FROM cds WHERE unigene_id=? and preferred='t'";

    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($self->get_unigene_id());
    
    my ($cds_id) = $sth->fetchrow_array();
    return $cds_id;
}



=head2 function determine_and_set_preferred_protein

 Usage:        my $unigene->determine_and_set_preferred_protein()
 Desc:         determines which of the predicted proteins associated with 
               the unigene is the best one. Uses a simple metric. First, 
               the longest protein is considered the best one. Then, each
               protein is considered sorted by its length, and the first 
               to match the direction to the best blastmatch is selected
               as the preferred protein. If there is only one associated
               protein, it will be selected as the preferred one.
 Ret:          nothing
 Args:         none
 Side Effects: modifies the database.
               first, sets all the preferred flats of the associated cds to 'f',
               then sets the preferred flag of the "best" cds/protein to 't'.
 Example:

=cut

sub determine_and_set_preferred_protein {
    my $self = shift;
    my $query = "SELECT cds_id FROM cds WHERE unigene_id=? ORDER BY length(cds.protein_seq)";

    my $sth = $self->get_dbh()->prepare($query);
    
    $sth->execute($self->get_unigene_id());
    
    my @cds = ();
    while (my ($cds_id) = $sth->fetchrow_array()) { 
	push @cds, CXGN::Transcript::CDS->new ($self->get_dbh(), $cds_id);
	
    }
    
    # change all preferred statuses to false
    foreach my $c (@cds) { 
	$c->set_preferred(0);
	$c->store();
    }

    if (! @cds) { return ; }
    if (@cds == 1) { 
	# we only have one predicted protein. it's the preferred one by default!
	$cds[0]->set_preferred(1);
	$cds[0]->store();
    }
    else { 
	# verify that the direction is the same as for the best hits of some blast targets.
	my @arabidopsis_hits = $self->get_arabidopsis_annotations();
	my @genbank_hits = $self ->get_genbank_annotations();

	my $best_genbank_blast_hit_direction = "";
	my $best_arabidopsis_blast_hit_direction= "";

	if (@arabidopsis_hits) { 
	    my $dir = $arabidopsis_hits[0]->[6] - $arabidopsis_hits[0]->[5];
	    if ($dir<0) { 
		$best_arabidopsis_blast_hit_direction="R";
	    }
	    else { $best_arabidopsis_blast_hit_direction = "F"; }

	}
	
	if (@genbank_hits) { 
	    my $dir = $genbank_hits[0]->[6] - $genbank_hits[0]->[5];
	    if ($dir < 0) { 
		$best_genbank_blast_hit_direction = "R";
	    }
	    else { 
		$best_genbank_blast_hit_direction = "F";
	    }
	}

	my $have_preferred = 0;
 	foreach my $c (@cds) { 
	    if ($best_genbank_blast_hit_direction) { 
		if ($c->get_direction() eq $best_genbank_blast_hit_direction) { 
		    $c->set_preferred(1);
		    $c->store();
		    $have_preferred = 1;
		    last();
		}
	    }
	    if ($best_arabidopsis_blast_hit_direction) { 
		if ($c->get_direction() eq $best_arabidopsis_blast_hit_direction) { 
		    $c->set_preferred(1);
		    $c->store();
		    $have_preferred=1;
		    last();
		}
		
	    }
	}
	if (!$have_preferred) { 
	    $cds[0]->set_preferred(1);
	    $cds[0]->store();
	}
	
    }
    foreach my $c (@cds) { 
	if ($c->get_preferred()) { 
	    return $c; 
	}
    }
    
    
}



=head2 function get_unigene_member_image

 Usage:        my $html = $unigene->get_unigene_member_image(@ests_to_be_hilited);
 Desc:         returns an image tag and associated html for 
               displaying the unigene member image. This image is currently
               being created using an external C program which this 
               function calls.
 Ret:          html [string]
 Args:         a listref of EST ids to be highlighted in the image
               a boolean to force re-load the image
 Side Effects:
 Example:

=cut

sub get_unigene_member_image {
    my $self = shift;
    my $highlight_ref = shift; # the est ids to be highlighted on the overview
    my $force_image = shift;
    
    my $unigene_id = $self->get_unigene_id();
    my @highlight = ();
    if ($highlight_ref) { 
	@highlight = @$highlight_ref;
    }
    my @members = $self->get_member_ests();

    my $highlight_link = ""; # not sure what that is for...    
    my $alignment_content;
    my $nr_members = $self->get_nr_members();
    my $cache = CXGN::Tools::WebImageCache->new();
    $cache->set_force($force_image);
    if ( ($nr_members > 1 && $nr_members < 20) || $force_image )  {	
	$cache->set_key("unigene_image-$unigene_id-".join(",", @highlight));
        $cache->set_expiration_time(86400); # seconds, this would be a day.
	$cache->set_map_name("contigmap_SGN-U".$self->get_unigene_id()); # what's in the <map name='map_name' tag.
	my $vh = CXGN::VHost->new();
	my $temp_dir = $vh->get_conf("tempfiles_subdir");
        $cache->set_temp_dir(File::Spec->catfile($temp_dir, "unigene_images"));
        $cache->set_basedir($vh->get_conf("basepath"));

        if (!$cache->is_valid()) {
	    # generate the image and associated image map.
	    my $img_fullpath = $cache->get_image_path();
	    my $map_fullpath = $cache->get_image_map_path();
	    
	    my $image_program = File::Spec->catfile($vh->get_conf('basepath'),
						    $vh->get_conf('programs_subdir'),
						    'draw_contigalign',
						    );
	    
	    
	    my $stuff="| $image_program --imagefile=\"$img_fullpath\" --mapfile=\"$map_fullpath\" --link_basename=\"/search/est.pl?request_from=1&request_type=7&request_id=\" --image_name=\"SGN-U$unigene_id\"";

#	    print STDERR "Calling drawcontig_align: $stuff\n";

	    open IMAGE_PROGRAM,$stuff;
	    foreach my $m ( @members ) {
		my $est_id = $m->get_est_id();
		my ($start, $end, $qstart, $qend, $dir) = $self->get_est_align_coords($est_id);
		my $highlight =0;
		if (grep (/^$est_id$/, @highlight)) { 
		    $highlight = 1;
		}
		else { 
		    $highlight = 0;
		}
		
		my ($strim, $etrim) = ($qstart- $start, $end - $qend);
		my $label = sprintf "%-12s %-10s","SGN-E".$m->get_est_id(),$m->get_clone_name();
		print IMAGE_PROGRAM join( "\t", $label,
					  $m->get_est_id(), $dir, $start, $end, $strim, $etrim, $highlight),"\n";
	    }
	    close IMAGE_PROGRAM
		or CXGN::Apache::Error::notify('failed to display unigene alignment image',"Non-zero exit code from unigene alignment imaging program $image_program ($?)");
	}
	
	my $hide_image= "";

	if ($nr_members == 1 || $nr_members > 20) {
	    $hide_image = qq{<br />[<a href="/search/unigene.pl?unigene_id=$unigene_id&amp;force_image=0$highlight_link">Hide Image</a>]};
	}
	
	$alignment_content = "<center>";
	$alignment_content .= $cache->get_image_html();
	
	$alignment_content .= <<EOF
	    <br /><span class="ghosted">To view details for a particular member sequence, click the SGN-E# identifier.</span>$hide_image
	    </center>
EOF
	    
     } else {
	 if ($nr_members == 1) {
	     my $est_id = $members[0]->get_est_id();
	     my $clone_name = $members[0]->get_clone_name();
	     # Don't bother passing the highlight option around here -- there is only one EST
	     $alignment_content = <<EOF;
	     <center>
		 <span class="ghosted">Alignment image suppressed for unigene with only one aligned EST <a href="/search/est.pl?request_id=$est_id&request_type=7&request_from=X">SGN-E$est_id</a></span><br />
		 [<a href="/search/unigene.pl?unigene_id=$unigene_id&amp;force_image=1">Show Image</a>]
		 </center>
EOF

         } else {
	     # If a highlight option was passed in, pass it on...
	     $alignment_content = <<EOF;
	     <center>
		 <span class="ghosted">Alignment image suppressed for unigene with $nr_members aligned sequences.</span><br />
		 [<a href="/search/unigene.pl?unigene_id=$unigene_id&amp;force_image=1$highlight_link">Show Image</a>]
		 </center>
EOF
	
         }
	 
	 
	 
     }
    return $alignment_content;
}


=head2 add_dbxref_id

 Usage:        my $id = $u->add_dbxref_id($dbxref_id)
 Desc:         adds the dbxref $dbxref_id to the unigene $u.
               $u needs to be already stored into the database
               and have a valid unigene id for this function
               to succeed.
 Ret:          an id designating the new unigene-dbxref relationship
 Args:         a dbxref_id [int]
 Side Effects: modifies the database.
 Example:

=cut

sub add_dbxref_id {
    my $self = shift;
    my $dbxref_id = shift;
    if ($self->unigene_dbxref_exists($dbxref_id) ) { 
	print STDERR " ***  unigene-dbxref already exists for dbxref_id $dbxref_id and unigene_id ". $self->get_unigene_id() . " \n"; 
	return undef; 
    }
    my $query = "INSERT INTO public.unigene_dbxref (unigene_id, dbxref_id) VALUES (?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id(), $dbxref_id);
    my $id = $self->get_currval("public.unigene_dbxref_unigene_dbxref_id_seq");
    return $id;
}

=head2 unigene_dbxref_exists 

 Usage:        my $exists= $self->unigene_dbxref_exists($dbxref_id)
 Desc:         check if unigene-dbxref connection already exists in the database
               Use this function before storing a new unigene_dbxref! ($self->add_dbxref_id() ) 
 Ret:          database id or undef
 Args:         dbxref_id
 Side Effects: accesses the database
 Example:

=cut

sub unigene_dbxref_exists {
    my $self = shift;
    my $dbxref_id=shift;
    my $query= "SELECT unigene_dbxref_id FROM public.unigene_dbxref 
                WHERE dbxref_id=? AND unigene_id= ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($dbxref_id, $self->get_unigene_id() ) ;
    my ($id) = $sth->fetchrow_array();
    if ($id)  { return $id ; }
    else { return undef ; }
}

=head2 get_dbxref_ids

 Usage:        my @dbxref_ids = $u -> get_dbxref_ids()
 Desc:         returns a list of dbxref_ids that are associated
               with this unigene
 Ret:          a list of int
 Args:         none
 Side Effects: accesses the database
 Example:

=cut

sub get_dbxref_ids {
    my $self = shift;
    my $query = "SELECT dbxref_id FROM unigene_dbxref WHERE unigene_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_unigene_id());
    my @dbxref_ids = ();
    while (my ($dbxref_id) = $sth->fetchrow_array()) { 
	push @dbxref_ids, $dbxref_id;
    }
    return @dbxref_ids;
}

=head2 get_dbxrefs

 Usage:        my @dbxrefs = $u -> get_dbxrefs()
 Desc:         returns a list of dbxref objects that
               are associated with the unigene
 Ret:          a list of CXGN::Chado::Dbxref objects
 Args:         none
 Side Effects: accesses the database
 Example:

=cut

sub get_dbxrefs {
    my $self = shift;
    my @dbxrefs = ();
    foreach my $id ($self->get_dbxref_ids() ) { 
	push @dbxrefs, CXGN::Chado::Dbxref->new($self->get_dbh(), $id);
    }
    return @dbxrefs;
}

=head2 create_unigene_dbxref_schema

 Usage:        CXGN::Transcript::Unigene::create_unigene_dbxref_schema($dbh);
 Desc:         creates the unigene_dbxref table in the public schema
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub create_unigene_dbxref_schema { 
    my $dbh = shift;
    
    my $query = "CREATE TABLE public.unigene_dbxref (
                   unigene_dbxref_id serial primary key not null,
                   unigene_id bigint not null references sgn.unigene,
                   dbxref_id bigint not null references public.dbxref
                 )";
    $dbh->do($query);

    
}

1;
