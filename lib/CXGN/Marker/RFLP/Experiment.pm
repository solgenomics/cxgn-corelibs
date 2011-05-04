package CXGN::Marker::RFLP::Experiment;

=head1 NAME

CXGN::Marker::RFLP::Experiment;

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Object for displaying and storing RFLP experiment data. 

=cut

use Modern::Perl;
use CXGN::Marker::Tools;
use CXGN::DB::Connection;
use CXGN::Tools::Text;


sub new {
    my $class = shift;
    my ( $dbh, $id ) = @_;
    unless ( CXGN::DB::Connection::is_valid_dbh($dbh) ) { die "Invalid DBH"; }
    my $self = bless( {}, $class );
    $self->{dbh} = $dbh;
    if ($id) {
        my $q = $dbh->prepare( '
            select
                rflp_id,
                library_name,
                clone_name,
                vector,
                cutting_site,
                forward_seq_id,
                reverse_seq_id,
                insert_size,
                drug_resistance,
                marker_prefix,
                marker_suffix
            from
                rflp_markers
            where
                rflp_id=?                
        ' );
        $q->execute($id);
        my $hr = $q->fetchrow_hashref();
        unless ( $hr->{rflp_id} ) {
            die "RFLP experiment not found with id '$id'";
        }
        while ( my ( $key, $value ) = each %$hr ) {
            $self->{$key} = $value;
        }
    }

    #all RFLP markers have RFLP protocol
    $self->{protocol} = 'RFLP';

    return $self;
}

sub marker_id {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value =~ /^\d+$/ ) {
            die "Marker ID must be a number, not '$value'";
        }
        unless (
            CXGN::Marker::Tools::is_valid_marker_id( $self->{dbh}, $value ) )
        {
            die "Marker ID '$value' does not exist in the database";
        }
        $self->{marker_id} = $value;
    }
    return $self->{marker_id};
}

sub library_name {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        $self->{library_name} = $value;
    }
    return $self->{library_name};
}

sub clone_name {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        $self->{clone_name} = $value;
    }
    return $self->{clone_name};
}

sub vector {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value eq 'pBLUESC'
            or $value eq 'pBR'
            or $value eq 'pCDNAII'
            or $value eq 'pCR1000'
            or $value eq 'pCRII'
            or $value eq 'PCRII'
            or $value eq 'pGEM4Z'
            or $value eq 'pUC' )
        {
            die("Vector '$value' is invalid");
        }
        $self->{vector} = $value;
    }
    return $self->{vector};
}

sub cutting_site {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value eq 'EcoR1'
            or $value eq 'EcoR1/BamH1'
            or $value eq 'EcoR1/HindIII'
            or $value eq 'EcoRI'
            or $value eq 'ECORI'
            or $value eq 'HindIII/EcoR1'
            or $value eq 'PST1'
            or $value eq 'SRD/PST1' )
        {
            die("Cutting site '$value' is invalid");
        }
        $self->{cutting_site} = $value;
    }
    return $self->{cutting_site};
}

sub forward_seq_id {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        my $q =
          $self->{dbh}
          ->prepare('select seq_id from rflp_sequences where seq_id=?');
        $q->execute($value);
        my ($exists) = $q->fetchrow_array();
        unless ($exists) {
            die "RFLP sequence with ID '$value' does not exist";
        }
        $self->{forward_seq_id} = $value;
    }
    return $self->{forward_seq_id};
}

sub reverse_seq_id {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        my $q =
          $self->{dbh}
          ->prepare('select seq_id from rflp_sequences where seq_id=?');
        $q->execute($value);
        my ($exists) = $q->fetchrow_array();
        unless ($exists) {
            die "RFLP sequence with ID '$value' does not exist";
        }
        $self->{reverse_seq_id} = $value;
    }
    return $self->{reverse_seq_id};
}

sub insert_size {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value =~ /^\d+$/ ) {
            die "'$value' is not a valid insert size";
        }
        $self->{insert_size} = $value;
    }
    return $self->{insert_size};
}

sub drug_resistance {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value eq 'Amp'
            or $value eq 'Amp*'
            or $value eq 'AMP'
            or $value eq 'KN'
            or $value eq 'TET' )
        {
            die "Drug resistance '$value' is not valid";
        }
        $self->{drug_resistance} = $value;
    }
    return $self->{drug_resistance};
}

sub marker_prefix {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value eq 'CT' or $value eq 'CD' or $value eq 'TG' ) {
            die "Marker prefix '$value' is invalid";
        }
        $self->{marker_prefix} = $value;
    }
    return $self->{marker_prefix};
}

sub marker_suffix {
    my $self = shift;
    my ($value) = @_;
    if ($value) {
        unless ( $value =~ /^\d+$/ ) {
            die "'$value' is not a valid suffix";
        }
        $self->{marker_suffix} = $value;
    }
    return $self->{marker_suffix};
}

sub protocol {
    my $self = shift;
    return $self->{protocol};
}

sub rflp_id {
    my $self = shift;
    return $self->{rflp_id};
}

sub equals {
    my $self = shift;
    my ($other) = @_;
    if (    $self->{marker_id} eq $other->{marker_id}
        and $self->{library_name}    eq $other->{library_name}
        and $self->{clone_name}      eq $other->{clone_name}
        and $self->{vector}          eq $other->{vector}
        and $self->{cutting_site}    eq $other->{cutting_site}
        and $self->{forward_seq_id}  eq $other->{forward_seq_id}
        and $self->{reverse_seq_id}  eq $other->{reverse_seq_id}
        and $self->{insert_size}     eq $other->{insert_size}
        and $self->{drug_resistance} eq $other->{drug_resistance}
        and $self->{marker_prefix}   eq $other->{marker_prefix}
        and $self->{marker_suffix}   eq $other->{marker_suffix} )
    {
        return 1;
    }
    return 0;
}

sub exists {
    my $self = shift;
    unless ( $self->{marker_id} ) {
        die "Cannot test if experiment exists without marker ID";
    }
    if ( $self->{rflp_id} ) {

#warn"I think it's pretty obvious that this experiment exists, since it seems to have been loaded from the database, or recently stored to the database--it already has an id of $self->{rflp_id}";
        return $self->{rflp_id};
    }
    my $dbh = $self->{dbh};
    my $q   = $dbh->prepare( '
        select 
            rflp_id 
        from 
            rflp_markers 
            inner join marker_experiment on (rflp_id=rflp_experiment_id)
        where 
            marker_id=?
            and not(library_name is distinct from ?)
            and clone_name=? 
            and vector=? 
            and cutting_site=? 
            and not(forward_seq_id is distinct from ?) 
            and not(reverse_seq_id is distinct from ?) 
            and insert_size=? 
            and drug_resistance=? 
            and marker_prefix=? 
            and marker_suffix=? 
    ' );
    $q->execute(
        $self->{marker_id},       $self->{library_name},
        $self->{clone_name},      $self->{vector},
        $self->{cutting_site},    $self->{forward_seq_id},
        $self->{reverse_seq_id},  $self->{insert_size},
        $self->{drug_resistance}, $self->{marker_prefix},
        $self->{marker_suffix}
    );
    my ($exists) = $q->fetchrow_array();
    if ($exists) {
        $self->{rflp_id} = $exists;
        return $exists;
    }
}

sub store_unless_exists {
    my $self = shift;
    if ( $self->exists() ) {
        return;
    }
    unless ( $self->{marker_id} ) {
        die "Cannot store experiment without marker ID";
    }
    my $q = $self->{dbh}->prepare( '
        insert into rflp_markers
        (
            library_name, 
            clone_name, 
            vector, 
            cutting_site, 
            forward_seq_id, 
            reverse_seq_id, 
            insert_size, 
            drug_resistance, 
            marker_prefix, 
            marker_suffix
        )
        values
        (
            ?,?,?,?,?,?,?,?,?,?
        )
    ' );
    $q->execute(
        $self->{library_name},   $self->{clone_name},
        $self->{vector},         $self->{cutting_site},
        $self->{forward_seq_id}, $self->{reverse_seq_id},
        $self->{insert_size},    $self->{drug_resistance},
        $self->{marker_prefix},  $self->{marker_suffix}
    );
    print "INSERTING:\n" . $self->as_string();
    $self->{rflp_id} = $self->{dbh}->last_insert_id('rflp_markers')
      or die("Could not get last insert ID from database");
    return $self->{rflp_id};
}

sub as_string {
    my $self   = shift;
    my $string = '';
    $string .= "marker_id: $self->{marker_id}\n";
    $string .= "rflp_id: $self->{rflp_id}\n";
    $string .= "library_name: $self->{library_name}\n";
    $string .= "clone_name: $self->{clone_name}\n";
    $string .= "vector: $self->{vector}\n";
    $string .= "cutting_site: $self->{cutting_site}\n";
    $string .= "forward_seq_id: $self->{forward_seq_id}\n";
    $string .= "reverse_seq_id: $self->{reverse_seq_id}\n";
    $string .= "insert_size: $self->{insert_size}\n";
    $string .= "drug_resistance: $self->{drug_resistance}\n";
    $string .= "marker_prefix: $self->{marker_prefix}\n";
    $string .= "marker_suffix: $self->{marker_suffix}\n";
}
1;
