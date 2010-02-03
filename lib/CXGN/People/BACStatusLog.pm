package CXGN::People::BACStatusLog;

use strict;
use warnings;

use Carp 'croak';
use English;
use POSIX;
use List::Util qw/sum/;
#use base qw/CXGN::Class::DBI/;

use base qw | CXGN::DB::Object |;

use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident assemble_clone_ident/;

#use this string to find sequencing projects in sgn_people.sp_project.name
our $tomato_comparison_string = 'Tomato Chromosome % Sequencing Project';
our @chromosome_graph_lengths =
  ( 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200 );
our @number_bacs_to_complete =
  ( 0, 391, 268, 274, 193, 111, 213, 277, 175, 164, 186, 135, 113 );#index 0 is used to hold data for all chromosomes combined, but calculate that dynamically, not here

=head2 new

  Usage:        my $bsl = CXGN::People::BACSTatusLog->new($dbh);
  Desc:            make a new BACStatusLog object
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;

    my $self = $class->SUPER::new($dbh);
    $self->set_sql();
    return $self;
}

sub get_statuses_for_person {

    my $self = shift;
    my $person = shift;

    my $status_hash;

    if ($person->get_user_type() eq 'sequencer'){
        my $bacs_query = $self->get_sql("sequencer_bacs");
        $bacs_query->execute($person->get_sp_person_id());
        $status_hash = $bacs_query->fetchall_hashref('bac_id');
    }
    elsif ($person->get_user_type() eq 'curator'){
        my $bacs_query = $self->get_sql("curator_bacs");
        $bacs_query->execute();
        $status_hash = $bacs_query->fetchall_hashref('bac_id');
    }
    return $status_hash;
}

=head2 get_status

  Desc:    return status and genbank status of bac with bac_id as argument
  Args:    bac ID
  Ret :    (status string, genbank status string)
  Side Effects:
  Example:

=cut

sub get_status {
    my $self      = shift;
    my ($bac_id)  = @_;
    my $sth = $self->get_sql('select_status');
    $sth->execute($bac_id);
    my ($status,$genbank_status) = $sth->fetchrow_array();
    $status ||= 'none';
    $genbank_status ||= 'none';
    my %fractionmap = (in_progress => 0.5, complete => 1);
    my $completeness_fraction = $fractionmap{$status} || 0;
    return ( $status, $genbank_status, $completeness_fraction );
}

=head2 change_of_status

  Desc:    change sequencing status of bac
        here only for compatibility: calls change_status
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub change_of_status {
  my $self = shift;
  my ( $bac_id, $person_id, $new_status) = @_;
  $self->change_status(bac => $bac_id,
               person => $person_id,
               seq_status => $new_status,
              );
}


=head2 change_of_genbank_status

  Desc:    change genbank status for BAC
        here only for compatibility
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub change_of_genbank_status {
  my $self = shift;
  my ( $bac_id, $person_id, $new_genbank_status ) = @_;
  $self->change_status( bac  => $bac_id,
                person => $person_id,
                genbank_status => $new_genbank_status,
              );
}

=head2 change_status

  Desc:     change statuses of bac
  Args:    bac => bac id, person => person id,
       seq_status => new sequencing status,
       genbank_status => new genbank status
       only one of seq_status and genbank_status has to be included
  Ret :    unspecified
  Side Effects:    changes status of bac in the sgn_people.bac_status and sgn_people.bac_status_log
                tables

=cut

sub change_status {
    my $self = shift;
    my %args = @_;
    my ( $bac_id, $person_id, $new_status, $new_genbank_status ) = @args{qw/bac person seq_status genbank_status/};
    #   warn 'changing status with '.join(' ',(%args))."\n";
    croak 'Must provide bac id' unless $bac_id;
    croak 'Must provide person id' unless $person_id;

    my ( $status, $genbank_status ) = $self->get_status($bac_id);

    $new_genbank_status ||= $genbank_status;
    $new_status ||= $status;

    #check that the new_status and new_genbank_status are valid values
    croak ("Invalid sequencing status '$new_status'")
    unless grep {$new_status eq $_} qw/none not_sequenced in_progress complete/;
    croak ("Invalid genbank status '$new_genbank_status'")
    unless grep {$new_genbank_status eq $_} qw/none htgs1 htgs2 htgs3 htgs4/;

    return if $new_status eq $status and $new_genbank_status eq $genbank_status;

    $new_genbank_status = undef if $new_genbank_status eq 'none';
    $new_status = undef if $new_status eq 'none';

    my $sth = $self->get_sql('insert');
    $sth->execute($bac_id,$person_id,$new_status,$new_genbank_status);

    $sth = $self->get_sql('get_status_id');
    $sth->execute($bac_id);

    my ($present) = $sth->fetchrow_array();

    if($present){
        $sth = $self->get_sql('update_status');
        $sth->execute($person_id,$new_status,$new_genbank_status,$bac_id);
    }
    else{
        $sth = $self->get_sql('insert_status');
        $sth->execute($bac_id,$person_id,$new_status,$new_genbank_status);
    }
}

=head2 add_comment

  Desc:     add a comment to a bac.  not yet implemented
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub add_comment {
    my $self = shift;
    my ( $bac_id, $comment ) = @_;
}

=head2 get_chromosome_graph_lengths

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub get_chromosome_graph_lengths {
    my $self = shift;
    return @chromosome_graph_lengths;
}

=head2 get_number_bacs_to_complete

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub get_number_bacs_to_complete {
    my $self = shift;
    my $sum=0;
    for(1..12){$sum+=$number_bacs_to_complete[$_];}
    $number_bacs_to_complete[0]=$sum;
    return @number_bacs_to_complete;
}

=head2 get_number_bacs_complete

  Desc:
  Args:    none
  Ret :
  Side Effects:
  Example:

=cut

sub get_number_bacs_complete {
    #NOTE: project ids in database are assumed to be the same as the chromsome numbers of the projects. this is (currently) true and it makes the code simpler. --john
    my $self=shift;
    my @answer=(0)x13;#index 0 is used to hold data for all chromosomes combined

    my $progress_query=$self->get_sql('number_of_bacs_with_status');
    $progress_query->execute('complete');
    while(my($id,$count)=$progress_query->fetchrow_array()){
        $answer[$id]=$count;
        $answer[0]+=$count;#index 0 is used to hold data for all chromosomes combined
    }
    return @answer;
}

=head2 get_number_bacs_in_progress

  Desc:
  Args:
  Ret :
  Side Effects:
  Example:

=cut

sub get_number_bacs_in_progress {

    #    NOTE: project ids in database are assumed to be the same as the
    #    chromosome numbers of the projects. this is (currently) true and
    #    it makes the code simpler. --john

    my $self=shift;
    my @answer=(0)x13;#index 0 is used to hold data for all chromosomes combined
    my $progress_query = $self->get_sql('number_of_bacs_with_status');
    $progress_query->execute('in_progress');
    while(my($id,$count)=$progress_query->fetchrow_array()) {
        $answer[$id]=$count;
        $answer[0]+=$count;#index 0 is used to hold data for all chromosomes combined
    }
    return @answer;
}

=head2 get_chromosomes_percent_finished

  return percentage of sequencing completed (overall,@for_each_chromosome)

=cut

sub get_chromosomes_percent_finished {
    my $self = shift;

    my @reported_complete    = $self->get_number_bacs_complete;
    my @reported_in_progress = $self->get_number_bacs_in_progress;
    my @available            = $self->get_number_bacs_uploaded;
    my @phases               = map [ $self->get_number_bacs_in_phase($_) ], undef, 1..3;
    #use Data::Dumper;
    #die Dumper(\@phases);
    my @to_do                = get_number_bacs_to_complete();

    my $reported_weight    = 0.6;
    my $in_progress_weight = 0.5;
    my @phase_weights   = ( 0.7, 0.7, 0.8, 1 ); #first one is for no phase info

    return map { my $i = $_;
      if( $to_do[$i] <= 0 ) {
    100
      } else {
    my $complete_but_not_available = $reported_complete[$i]-$available[$i];
    my $completed_number = sum ( $reported_weight*($reported_in_progress[$i]*$in_progress_weight+$complete_but_not_available),
                     ( map {$phase_weights[$_]*$phases[$_][$i]} 0..3 ),
                   );
    POSIX::floor( 100 * $completed_number/$to_do[$i] )
      }
    } (0..12);
}

=head2 get_number_bacs_uploaded

  Usage: my ($total,@nums) = $log->get_number_bacs_uploaded
  Desc : get the number of bacs for each chromosome that have been
         actually uploaded
  Ret  : list of ( total number of bacs uploaded,
                   num for chr1,
                   num for chr2,
                   ...
                 )
  Args : none
  Side Effects: looks things up in the database

=cut

sub get_number_bacs_uploaded {
    my ($self) = @_;
    my $sth = $self->get_sql('number_of_bacs_uploaded');
    $sth->execute();
    return _format_chr_summary($sth->fetchall_arrayref);
}

#takes an arrayref of chromosome summary like [ [ 1, 33], [2, 44], ...]
#and formats it into a chromosome array like (TOTAL, chr1, chr2, ...)
sub _format_chr_summary($) {
    my $summary = shift;
    my @ret = (sum(map $_->[1],@$summary), (0)x12);
    #fill in the chromosomes that are present with an assignment to an
    #array slice
    @ret[map $_->[0],@$summary] = map $_->[1],@$summary;
    return @ret;
}

=head2 get_number_bacs_in_phase

  Usage: my ($total, @nums) = $log->get_number_bacs_in_phase(2);
  Desc : get the total number of BACs that are known to be in
         the given HTGS phase
  Args : an htgs phase, either 1,2, or 3, or undef.
         if undef, returns counts of BACs that have no phase
         information in the database (old bac submissions, etc)
  Ret  : a list of (TOTAL, chr1, chr2, ...)

=cut

#memoize('get_number_bacs_in_phase');
sub get_number_bacs_in_phase {
  my ($self,$phase) = @_;
  croak "invalid phase $phase"
    unless (!defined $phase ||  $phase <= 3 && $phase >= 1 );

  my $sth = $self->get_sql('bacs_including_phases');
  $sth->execute();

  our %phases;
  unless( %phases ) {
    foreach my $row (@{$sth->fetchall_arrayref}) {
      my ($chr,$seqname,$p) = @$row;
      my $parsed = parse_clone_ident($seqname,'versioned_bac_seq')
    or die "could not parse $seqname";
      my $bacname = assemble_clone_ident('agi_bac_with_chrom',$parsed);
      #warn "made bacname $bacname\n";
      $phases{$chr}{$bacname} = $p unless $phases{$chr}{$bacname} && $phases{$chr}{$bacname} > $p;
    }
  }

  my @counts = (0)x13;
  if (defined $phase) {
    # now group the bacs by phase
    foreach my $chr (keys %phases) {
      foreach my $bac (keys %{$phases{$chr}}) {
    if( $phases{$chr}{$bac} && $phases{$chr}{$bac} == $phase ) {
      #warn "found phase $phase: $chr $bac: $phases{$chr}{$bac}\n";
      #warn "$bac\n";
      $counts[$chr]++;
    }
      }
    }
  } else {
    foreach my $chr (keys %phases) {
      foreach my $bac (keys %{$phases{$chr}}) {
    $counts[$chr]++ unless $phases{$chr}{$bac};
      }
    }
  }
  $counts[0] += $counts[$_] foreach 1..$#counts;
  return @counts;
}


sub set_sql {
    my $self = shift;
    $self->{queries}= {

    sequencer_bacs =>

            "
                SELECT bac_id, status, genbank_status
                FROM sgn_people.bac_status
                WHERE bac_id IN
                (
                    SELECT
                        row_id
                    FROM
                        sgn_people.sp_person
                    INNER JOIN sgn_people.sp_project_person
                        ON (sp_person.sp_person_id=sp_project_person.sp_person_id)
                    INNER JOIN metadata.attribution_to
                        ON (sp_project_id=project_id)
                    INNER JOIN metadata.attribution
                        USING (attribution_id)
                    LEFT JOIN physical.bacs
                        ON (metadata.attribution.row_id=physical.bacs.bac_id)
                    WHERE
                    (
                        (
                            metadata.attribution.database_name='physical'
                            AND
                            metadata.attribution.table_name='bacs'
                        )
                        OR
                        (
                            metadata.attribution.database_name='genomic'
                            AND
                            metadata.attribution.table_name='clone'
                        )
                    )

                    AND sp_person.sp_person_id=?
                    ORDER BY
                        project_id,
                        arizona_clone_name
                )
            ",

        curator_bacs =>

            "
                SELECT
                    bac_id, status, genbank_status
                FROM sgn_people.bac_status
                WHERE bac_id IN
                (
                    SELECT row_id
                    FROM metadata.attribution_to
                    INNER JOIN metadata.attribution
                        USING (attribution_id)
                    LEFT JOIN physical.bacs
                        ON (metadata.attribution.row_id=physical.bacs.bac_id)

                    WHERE
                    (
                        (
                            metadata.attribution.database_name='physical'
                            AND
                            metadata.attribution.table_name='bacs'
                        )
                        OR
                        (
                            metadata.attribution.database_name='genomic'
                            AND
                            metadata.attribution.table_name='clone'
                        )
                    )
                    ORDER BY
                        project_id,
                        arizona_clone_name
                )
            ",

        select_status =>

            "
                SELECT
                    status, genbank_status
                FROM
                    sgn_people.bac_status
                WHERE
                    bac_id=?
            ",

        get_status_id =>

            "
                SELECT
                    bac_status_id
                FROM
                    sgn_people.bac_status
                WHERE
                    bac_id=?
            ",

        insert =>

            "
                INSERT INTO sgn_people.bac_status_log
                    (bac_id,person_id,status,genbank_status)
                VALUES
                    (?,?,?,?)
            ",

        update_status =>

            "
                UPDATE sgn_people.bac_status
                SET
                    person_id=?,
                    status=?,
                    genbank_status=?
                WHERE
                    bac_id=?
            ",


        insert_status =>

            "
                INSERT INTO sgn_people.bac_status
                    (bac_id,person_id,status,genbank_status)
                VALUES
                    (?,?,?,?)
            ",

        number_of_bacs_with_status =>

            "
                SELECT
                    sp_project_id,
                    COUNT(status)
                FROM
                    sgn_people.sp_project
                INNER JOIN metadata.attribution_to
                    ON (sp_project_id=project_id)
                INNER JOIN metadata.attribution
                    USING (attribution_id)
                INNER JOIN sgn_people.bac_status
                    ON (metadata.attribution.row_id=bac_id)
                WHERE
                (
                    (
                        metadata.attribution.database_name='physical'
                        AND
                        metadata.attribution.table_name='bacs'
                    )
                OR
                    (
                        metadata.attribution.database_name='genomic'
                        AND
                        metadata.attribution.table_name='clone'
                    )
                )
                AND status=?
                GROUP BY
                    sp_project_id,
                    status
            ",

        number_of_bacs_uploaded =>

            "
                SELECT chr,count(*)
                FROM (
                    SELECT
                       SUBSTRING(f.name from 2 for 2) AS chr
                     FROM clone_feature
                          JOIN feature f
                           USING(feature_id)
                                             JOIN public.organism o
                                                   USING(organism_id)
                                        WHERE o.species = 'Solanum lycopersicum'
                     GROUP BY
                      clone_id
                      , SUBSTRING(f.name from 2 for 2)
                ) AS foo
                                WHERE chr <> '00'
                GROUP BY chr
                ORDER BY chr
            ",

        number_of_bacs_in_phase =>

            "
                SELECT
                        SUBSTRING(f.name from 2 for 2)
                        AS chr,
                    count(*)
                FROM clone_feature cf
                      JOIN feature f
                                        USING(feature_id)
                                      JOIN public.organism o
                                        USING(organism_id)
                      JOIN featureprop fp
                    USING (feature_id)
                      JOIN cvterm ct
                    ON (ct.cvterm_id = fp.type_id)
                WHERE
                    ct.name = 'htgs_phase'
                    AND fp.value = ?
                                        AND o.species = 'Solanum lycopersicum'
                GROUP BY chr
                ORDER BY chr
            ",

        number_of_bacs_in_some_phase =>

            "
                SELECT
                    SUBSTRING(f.name from 2 for 2)
                        AS chr,
                    count(*)
                FROM clone_feature cf
                     JOIN feature f
                    USING (feature_id)
                                     JOIN public.organism o
                                        USING(organism_id)
                     JOIN featureprop fp
                    USING (feature_id)
                     JOIN cvterm ct
                    ON (ct.cvterm_id = fp.type_id)
                     WHERE
                    ct.name = 'htgs_phase'
                                        AND o.species = 'Solanum lycopersicum'
                GROUP BY chr
                ORDER BY chr
            ",
         bacs_including_phases => <<EOSQL,
SELECT
    substring(f.name from 2 for 2) as chr,
    f.name as bacname,
    fp.value as phase
FROM clone_feature cf
     JOIN feature f
        USING (feature_id)
     LEFT JOIN featureprop fp
        ON ( f.feature_id = fp.feature_id
             AND fp.type_id IN(select cvterm_id from cvterm where cvterm.name='htgs_phase')
           )
     JOIN public.organism o
        USING(organism_id)
where f.name is not null
      AND o.species = 'Solanum lycopersicum'
ORDER BY f.name
EOSQL
         };

    while(my($k,$v) = each %{$self->{queries}}){
        $self->{query_handles}->{$k}= $self->get_dbh()->prepare($v);
    }
}

sub get_sql {
    my $self =shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}

sub DESTROY {
    my $self = shift;
    $_->finish for grep defined, values %{$self->{query_handles}};
}

###
1;#do not remove
###
