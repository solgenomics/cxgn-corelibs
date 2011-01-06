package CXGN::People::BACStatusLog;

use strict;
use warnings;

use Carp 'croak';
use English;
use POSIX;
use List::Util qw/sum min/;
#use base qw/CXGN::Class::DBI/;

use base qw | CXGN::DB::Object |;

use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident assemble_clone_ident/;

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


sub bac_by_bac_progress_statistics {
    my ( $self ) = @_;
    my $dbh = $self->get_dbh;

    no warnings 'uninitialized';
    my %progress;

    my $attr_data = $dbh->selectall_arrayref( <<'' );
      SELECT
          bac_id
          ,proj.name
          ,status
      FROM sgn_people.bac_status as bs
      LEFT JOIN metadata.attribution as attr
          ON (attr.row_id=bs.bac_id)
      LEFT JOIN metadata.attribution_to as attr_to
          USING ( attribution_id )
      LEFT JOIN sgn_people.sp_project as proj
          ON (sp_project_id=project_id)
      WHERE
          (
              attr.database_name = 'physical'
              AND
              attr.table_name = 'bacs'
          )
          OR
          (
              attr.database_name = 'genomic'
              AND
              attr.table_name = 'clone'
          )

    # calculate per-chromosome in_progress and complete
    for my $row ( @$attr_data ) {
        my ( $clone_id, $name, $status ) = @$row;
        $status ||= 'no_status';
        my $chr = $name =~ /Tomato Chromosome (\d+)/ ? $1+0 : 'unmapped';
        for my $group ( $chr, 'overall' ) {
            $progress{$group}{$status}++;
        }
    }

    my $upload_data = $dbh->selectall_arrayref( <<'' );
         SELECT
            SUBSTRING(f.name from 2 for 2) AS chr
            ,f.name
            ,fp.value as htgs_phase
         FROM genomic.clone_feature
         JOIN feature f
           USING(feature_id)
         JOIN public.organism o
           USING(organism_id)
         LEFT JOIN featureprop fp
           ON( fp.feature_id = f.feature_id AND fp.type_id IN( SELECT cvterm_id from cvterm where name = 'htgs_phase' ) )
         WHERE
            o.species = 'Solanum lycopersicum'

    # calculate per-chromosome htgs and available
    for my $row ( @$upload_data ) {
        my ( $chr, undef, $htgs_phase ) = @$row;
        $chr = $chr+0 ? $chr+0 : 'unmapped';
        for my $group ( $chr, 'overall' ) {
            $progress{$group}{available}++;
            $progress{$group}{"htgs_$htgs_phase"}++;
        }
    }

    # calculate per-chromosome pct_done
    my %number_bacs_to_complete =
        qw(
            1 391
            2 268
            3 274
            4 193
            5 111
            6 213
            7 277
            8 175
            9 164
           10 186
           11 135
           12 113
          );
    $number_bacs_to_complete{overall} = sum( values %number_bacs_to_complete );

    for my $chr ( keys %progress ) {
        my $chr_prog = $progress{$chr};

        my @phases = map $chr_prog->{"htgs_$_"}, (undef, 1..3);

        my @phase_weights   = ( 0.7, 0.7, 0.8, 1 ); #first one is for no phase info
        my $to_do = $chr_prog->{total_bacs} = $number_bacs_to_complete{$chr};

        my $reported_weight    = 0.6;
        my $in_progress_weight = 0.5;

        if( $to_do <= 0 ) {
            $chr_prog->{pct_done} = 100;
        } else {
            my $complete_but_not_available = $chr_prog->{complete} - $chr_prog->{available};
            my $completed_number = sum(
                $reported_weight * sum(
                    $in_progress_weight * $chr_prog->{in_progress},
                                      1 * $complete_but_not_available,
                   ),
                ( map $phase_weights[$_]*$phases[$_], 0..3 ),
             );
            $chr_prog->{pct_done} =
                min( 100,
                     POSIX::floor( 100 * $completed_number / $to_do )
                   );
       }
    }

    $progress{overall}{pct_reported_finished} = sprintf('%0.0f',100 * $progress{overall}{complete}/$progress{overall}{total_bacs});
    $progress{overall}{pct_available} = sprintf('%0.0f',100 *  $progress{overall}{available}/$progress{overall}{total_bacs});

    return \%progress;
}

sub DESTROY {
    my $self = shift;
    $_->finish for grep defined, values %{$self->{query_handles}};
}


###
1;#do not remove
###
