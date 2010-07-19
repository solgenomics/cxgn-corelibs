
=head1 NAME

CXGN::Cluster::Precluster

=head1 DESCRIPTION

An instance of Precluster represents one cluster. New members can be
added using add_member, and the members of a cluster can be retrieved
using get_members.

The final assemblies of each cluster are lazily calculated when you
call get_contig_coords().  SO, if you never call that, for example,
when you want to assemble the members yourself, then you never incur
the overhead of generating final assemblies.

To be implemented: A function to obtain the sequence of the contig
(for mode of operation (2))

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

Robert Buels <rmb32@cornell.edu>

=head1 FUNCTIONS

=cut

use strict;

package CXGN::Cluster::Precluster;
use Carp;
use namespace::autoclean;

use File::Path qw/ mkpath  /;
use File::Temp qw/ tempdir /;
use List::Util qw/ min max sum /;

use Bio::Assembly::IO;

use CXGN::Tools::Run;

use base qw ( CXGN::Cluster::Object );

=head2 constructor new()

 Usage:        my $c = CXGN::Cluster::Precluster->new($cluster_set);
 Desc:         generates a new CXGN::Cluster::Precluster object
 Args:         a cluster_set object, to which this precluster belongs
 Side Effects: meddles with some stuff in the cluster_set object
 Example:

=cut

sub new {
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    my $cluster_set = shift;
    if (!$cluster_set) {
	die "CXGN::Cluster::Precluster::new()- need cluster set";
    }
    $self->set_cluster_set($cluster_set);
    $self->set_unique_key($self->get_cluster_set()->generate_unique_key());
    $self->debug( "Generated cluster with unique key = ".$self->get_unique_key()."\n" );
    return $self;
}

=head2 function add_member()

 Usage:        $cluster->add_member($id)
 Desc:         adds member with id $id to the cluster
 Ret:          nothing
 Args:         a member id [string]
 Side Effects: also adds the id to the cluster_set, which
               keeps a hash of all ids and to which clusters
               they belong (for fast retrieval).
 Example:

=cut

sub add_member {
    my $self = shift;
    my $id = shift;

    $self->{members}{$id}++;
    $self->get_cluster_set()->add_id($self, $id);

    # this flag keeps track of whether we need to calculate the true
    # assembly of the members of this precluster
    $self->{needs_phrap} = $self->get_member_count > 1;
}

=head2 function get_contig_coords()

 Usage: @list = $cluster->get_contig_coords($seq_index)
 Desc:  returns a list of all the contigs in the final assembly, each of
        which lists the coordinates of its member sequences
        with contig name, start coord, end_coord, and strand
        (with 1 meaning positive strand, -1 meaning negative strand, and
        0 meaning unknown).
        Sorted by start coord ascending.
 Ret:   list as
       [ [ seqname, global_start, global_end, 1/0/-1 ],
         ...
       ],
       [ [ seqname, global_start, global_end, 1/0/-1 ],
         ...
       ],
       ...

       NOTE: the coordinates reported for the member sequences will
       overlap, because that's how the contig was built.

 Args: a Bio::Index::Fasta object to get sequences from, because
       we need the sequences to calculate the proper assembly
 Side Effects: calls phrap to calculate the assembly

=cut

sub get_contig_coords {
  my ($self,$seq_index) = @_;

  $self->_run_phrap($seq_index) if $self->{needs_phrap};

  if($self->get_member_count > 1) {

    my $as_in = Bio::Assembly::IO->new( -file => $self->{phrap}->out_file,
                                        -format => 'phrap',
                                        -alphabet => 'dna',
                                       );
    my $as = $as_in->next_assembly;

    return
      (				#SINGLETONS
       map {
	 my $s = $_;
	 [ [$s->id, 1, $s->seqref->length, 1 ] ]
       } $as->all_singlets
      ),
	(			#CONTIGS
	 map {
	   my $c = $_;
	   [
	    sort {$a->[1] <=> $b->[1]}
	    map {
	      my (undef,$seqname) = split /:/,$_->primary_tag;
	      [ $seqname, $_->start, $_->end, $_->entire_seq->strand ]
	    }
	    grep $_->primary_tag =~ /^_unalign_coord:/,
	    $c->get_features_collection->get_all_features
	   ]
	 } $as->all_contigs
	);
  } else {
    my ($seq_name) = $self->get_members;
    return [[$seq_name,1,$seq_index->fetch( $seq_name )->length, 1]];
  }
}

=head2 function get_consensus_base_segments()

 Usage: @list = $cluster->get_consensus_base_segments($seq_index)
 Ret:  get a list of the read segments used to produce each consensus
       sequence, as:
          ( [ [ start wrt contig,
                end wrt contig,
                read id,
                start wrt read,
                end wrt read,
                1 if read is reverse-complemented, 0 if not
              ]
              ... (and so on for each read)
            ],
            ... (and so on for each consensus sequence)
          )
 Args: Bio::Index::Fasta object to get sequences from,
       list of options, as:
          min_segment_size => filter out consensus segments smaller
                              than this.  filtered segments will
                              be replaced with extensions of the
                              segments at either side

 Side Effects: may call phrap to calculate the assembly

=cut

#use Smart::Comments;

sub get_consensus_base_segments {
    my ($self, $seq_index, %options) = @_;

    $self->_run_phrap($seq_index) if $self->{needs_phrap};

    my %used_reads;
    my %af;
    my $curr_reads;
    my @consensi;
    open my $ace, '<', $self->{phrap_ace} or die "$! opening $self->{phrap_ace}";
    while( my $line = <$ace> ) {
        if( $line =~ /^AF (\S+) (U|C) ([-\d]+)/ ) {
            ### AF: $line
            $af{$1} = [ $2 eq 'C' ? 1 : 0,
                        $3
                      ];
            ### af: $af{$1}
        }
        elsif( $line =~ /^BS ([-\d]+) ([-\d]+) (\S+)/ ) {
            ### line: $line
            my $af = $af{$3} or do {
                warn "no AF found for '$3'";
                my $error_dir = "/tmp/precluster-error-data";
                system "rm -rf $error_dir";
                system "cp -ra ".$self->_tempdir." $error_dir";
                die "copied erroneous data to $error_dir.  aborting.\n";
            };
            my ( $reverse, $offset ) = @$af;
            my ( $rs, $re ) = map { $_ - $offset + 1 } $1, $2;
            ### bs:  [ $1, $2, $rs, $re, $3 ]
            ### length 1: $2 - $1 + 1
            ### length 2: $re - $rs + 1
            push @$curr_reads, [ $1, $2, $3, $rs, $re, $reverse ];
            $used_reads{$3} = 1;
            ### read length: $seq_index->fetch($3)->length
        }
        elsif( $line =~ /^CO / ) {
            push @consensi, $curr_reads = [];
        }
    }

    push @consensi,
        map { my $length = $seq_index->fetch($_)->length;
              [[ 1, $length, $_, 1, $length, 0 ]],
            }
        grep !$used_reads{$_},
        $self->get_members;

    if( $options{min_segment_size} ) {
        foreach my $c (@consensi) {
            if ( @$c > 1 ) {
                $c = $self->_weighted_simplify_base_segments( $c, $seq_index, $options{min_segment_size} );
            }
        }
    }

    return @consensi;
}



sub _run_phrap {
  my ($self,$seq_index) = @_;

  ref($seq_index) && $seq_index->isa('Bio::Index::Fasta')
    or croak 'must provide a Bio::Index::Fasta';

  #make a temp fasta file and run phrap on it
  my $assembly_dir = $self->get_assembly_dir || $self->_tempdir;
  -d $assembly_dir or mkpath( $assembly_dir )
      or die "assembly files dir '$assembly_dir' does not exist, and could not create";
  my $max_seq_size = 0;
  my $seq_count;
  my $seqs_temp = do {
    my $t = "$assembly_dir/precluster_members.seq";
    my $seqs_temp_io = Bio::SeqIO->new( -file => ">$t", -format => 'fasta');
    foreach my $id ( $self->get_members ) {
	my $seq = $seq_index->fetch($id)
	  or die "$id not found in sequences index\n";
	$seq_count++;
	$max_seq_size = $seq->length if $seq->length > $max_seq_size;
	$seqs_temp_io->write_seq($seq);
    }
    $t
  };

  #warn "got max_seq_size $max_seq_size, count $seq_count\n";
  my $phrap_exec = $max_seq_size > 64_000 ? 'phrap.longreads' :
                      $seq_count >  5_000 ? 'phrap.manyreads' :
                                            'phrap';
  #warn "and thus we're using $phrap_exec\n";

  $self->{phrap_out} = "$seqs_temp.stdout";

  $self->{phrap} =
      CXGN::Tools::Run->run(
          $phrap_exec,
          $seqs_temp,
          '-new_ace',
          $self->phrap_options,
          {
              working_dir => $assembly_dir,
              out_file => $self->{phrap_out},
              err_file => "$seqs_temp.stderr",
          },
         );

  #warn "phrap output:\n".$phrap->out;
  $self->{phrap_ace} = "$seqs_temp.ace";

  $self->{needs_phrap} = 0;
}


sub _weighted_simplify_base_segments {
    my ( $self, $original_segments, $seq_index, $min_seg_len ) = @_;

    # segment record layout:
    #  0 member_contig_start
    #  1 member_contig_end
    #  2 name
    #  3 member_local_start
    #  4 member_local_end
    #  5 member_reverse

    my @output_segments = @$original_segments;

    for( my $segment_num = 0; $segment_num < @output_segments; $segment_num++ ) {
        # init variables holding this segment, the segments on either
        # side, and the lengths of each.  some of these may be
        # undefined.
        my ( $seg, $seg_before, $seg_after ) =
            @output_segments[ $segment_num, $segment_num - 1, $segment_num + 1 ];
        undef $seg_before if $segment_num == 0;
        my ( $seg_len, $seg_before_len, $seg_after_len ) =
            map { $_ ? $_->[1] - $_->[0] + 1
                     : undef
                 }
              $seg, $seg_before, $seg_after;

        # if the segment is big enough, leave it alone
        next unless $seg_len < $min_seg_len;

        # otherwise, remove it and expand the segments on either side

        my $seg_before_bases_available =
            $seg_before ? $seq_index->fetch( $seg_before->[2] )->length - $seg_before->[4]
                        : 0;
        my $seg_after_bases_available  =
            $seg_after  ? $seg_after->[3] - 1
                        : 0;

        # if no bases are available on either side, we cannot excise this.
        next unless  $seg_before_bases_available || $seg_after_bases_available;

        my ( $expand_before, $expand_after ) = do {
            no warnings 'uninitialized';
            map {
                my $weight = $_ / ( $seg_before_bases_available + $seg_after_bases_available );
                sprintf( '%0.0f', $weight * $seg_len );
            } $seg_before_bases_available, $seg_after_bases_available
        };

        # if we don't have enough sequence available on either side to
        # excise and cover this segment, leave it alone
        next unless $expand_before <= $seg_before_bases_available;
        next unless $expand_after <= $seg_after_bases_available;
        # also leave it alone if it is the only one left for this read
        next if 1 == scalar grep $_->[2] eq $seg->[2], @output_segments;


        # now do the actual segment adjusting:
        if( $expand_before ) {
            $expand_before > 0 or die "sanity check failed ($seg_before_bases_available,$expand_before)";
            $_ += $expand_before for @{$seg_before}[1,4];
        }
        if( $expand_after ) {
            $expand_after > 0 or die "sanity check failed ($seg_after_bases_available,$expand_after)";
            $_ -= $expand_after for @{$seg_after}[0,3];
        }

        # and then delete this segment from the array
        undef $output_segments[$segment_num];
        @output_segments = grep $_, @output_segments;
        $segment_num--; #< because the segments have shifted over, we need to do this index again
    }

    # now go through and merge any adjacent same-read segments
    for( my $segment_num = 0; $segment_num < @output_segments; $segment_num++ ) {
        # init variables holding this segment, the segments on either
        # side, and the lengths of each.  some of these may be
        # undefined.
        my ( $seg, $seg_after ) = @output_segments[$segment_num, $segment_num+1];

        # find segments where the segment after this one is the same
        # read and orientation
        next unless $seg_after && $seg->[2] eq $seg_after->[2] && !($seg->[5] xor $seg_after->[5]);

        # merge the coordinates into the first seg
        $seg->[4] = $seg_after->[4];
        $seg->[1] = $seg_after->[1];

        # delete the second seg
        undef $output_segments[$segment_num+1];
        @output_segments = grep $_, @output_segments;
        $segment_num--; #< we need to go over this one again to evaluate the next merge
    }

    return \@output_segments;
}


my %cached_filters;
sub _gaussian_simplify_base_segments {
    my ($self, $original_segments, $window_size) = @_;

    ### strategy:
    # Treats the tiling path as a set of N digital signals in the
    # base-pair domain.  So for each base, there are N signal levels,
    # each expressing the contribution of each clone to that base.  In
    # the input data, the signals will look like noisy binary
    # (two-level, 0 or 1) functions, each base will have only
    # contributions from one clone sequence.  The objective is to
    # smooth those noisy binary functions into continuous functions,
    # then use those smoothed functions to construct a tiling path by
    # finding the strongest (smoothed) signal at each base.

    # This is intended to construct a simplified version of the tiling
    # path found by the assembler, while still keeping the large
    # segments, the "broad strokes" of the tiling path that the
    # assembler found.  This should also mitigate errors introduced
    # in the AGP by the edits phrap makes to repetitive sequences.

    # initialize the signals for each clone.
    # %signals is:
    #    clone name => { original => arrayref of per-base signal levels (with undef treated as zero),
    #                    filtered => same as original, but after filtering
    #                  }
    #
    my %signals;
    my %offsets;
    my $contig_length = 0;
    foreach my $segment (@$original_segments) {
        my ( $member_contig_start, $member_contig_end, $name, $member_local_start, $member_local_end, $member_reverse ) = @$segment;
        my $member_strand = $member_reverse ? '-' : '+';

        my $stranded_name = $name.$member_strand;

        ### initialize the digital signals
        $signals{$stranded_name}{original}[$_] = 1
            for ($member_contig_start-1) .. ($member_contig_end-1);

        ### also keep track of some other aspects of the contig

        # like the overall contig length
        $contig_length = $member_contig_end if $member_contig_end > $contig_length;

        # and the offset of each member relative to the contig
        my $member_offset = $member_contig_start - $member_local_start;
        if( defined $offsets{ $stranded_name } ) {
            $offsets{$stranded_name} == $member_offset
                or die "conflicting offsets found for $stranded_name, is the input data malformed?";
        } else {
            $offsets{$stranded_name} = $member_offset;
        }

    }

    # make a sub ref that applies the gaussian filter to a signal (cached)
    my $gaussian_filter =
        $cached_filters{$window_size} ||=
            $self->_make_sampled_gaussian_filter( $window_size );
    #my $gaussian_filter = sub { shift };
    foreach my $signal (values %signals) {
        $signal->{filtered} = $gaussian_filter->( $signal->{original} );
    }

    my @new_segments;
    for( my $x = 0; $x < $contig_length; $x++ ) {
        my $dominant_member   = 'foo';
        my $dominant_siglevel = 0;
        foreach my $member ( keys %signals ) {
            my $siglevel = $signals{$member}{filtered}[$x];
            no warnings 'uninitialized';
            if( $siglevel > $dominant_siglevel ) {
                $dominant_member   = $member;
                $dominant_siglevel = $siglevel;
            }
        }

        no warnings 'uninitialized';
        my $last_segment = $new_segments[-1];
        if( $last_segment && $last_segment->{name} eq $dominant_member ) {
            $last_segment->{contig_end}++;
            $last_segment->{local_end}++;
        } else {
            my $offset = $offsets{$dominant_member};
            #warn "new segment: $dominant_member ($dominant_siglevel) starting at contig $x, local ".($x-$offset)."\n";
            push @new_segments, {
                name         => $dominant_member,
                contig_start => $x,
                contig_end   => $x,
                local_start  => $x - $offset,
                local_end    => $x - $offset,
            };
        }
    }

    # now fix up names and forward/reverse in the new segments before
    # returning them
    return [
        map {
            my $s = $_;
            my $reverse = chop $s->{name};
            $reverse = $reverse eq '-' ? 1 : 0;
            $_++ for @{$s}{qw{ contig_start contig_end local_start local_end }};
            [  @{$s}{qw{ contig_start contig_end name local_start local_end }}, $reverse ]
        } @new_segments
       ];
}

sub _make_sampled_gaussian_filter {
    my ($self,$window_size) = @_;

    my $two_t = $window_size / 2;
    my $half_window = sprintf( '%0.0f', $two_t );
    my $actual_window_length = 2 * $half_window + 1;

    my $const = 1 / sqrt( 3.1415927 * $two_t  );
    my @weights = map {
        $const * exp(  -( $_**2 )/$two_t  );
    } -$half_window .. $half_window;

    my $correction_wt = sum @weights[ 0..$half_window ];

    return sub {
        my $in = shift;
        my @out;
        for( my $center = 0; $center < @$in; $center++) {
            my $in_value = $in->[$center];
            my $lower = max( 0,                    $center-$half_window );
            my $upper = min( $center+$half_window, $#$in - 1             );
            for( my $x = $lower; $x <= $upper; $x++ ) {
                no warnings 'uninitialized';
                $out[ $x ] += $in_value * $weights[ $x - $center + $half_window ];
            }
        }

        # compensate a bit for end effects by boosting the signals on
        # the ends with half the gaussian dist
        my $begin_correction = $correction_wt * $out[0];
        my $end_correction   = $correction_wt * $out[-1];
        for my $x ( 0..$half_window ) {
            $out[ $x ] += $begin_correction;
        }
        for my $x ( ($#$in - $half_window)..$#$in ) {
            $out[ $x ] += $end_correction;
        }

        return \@out;
    };
}


=head2 phrap_options

Get the list of options passed to phrap to control its behavior.

CURRENTLY THESE PHRAP OPTIONS ARE FOR ASSEMBLING CONTIGS OF BAC
SEQUENCES

if we start wanting to use this module for something else, you'll need
to factor out these phrap options into subclasses and add some kind of
accessor to ClusterSet to choose what kind of clusters you're making

=cut

sub phrap_options {
    my $self = shift;
    shift and die 'setting not yet supported';
    return (
        -vector_bound => 0,
        -minmatch     => 1_500,
        -maxmatch     => 60_000,
        -bypasslevel  => 0,
        -repeat_stringency => .98,
        '-force_high',
        -node_seg     => 2_000,
        -node_space   => 1_000,
       );
}

=head2 set_assembly_dir, get_assembly_dir

  Usage: $precluster->set_assembly_dir('/foo/bar');
         $precluster->get_assembly_dir
  Desc : set/get the directory in which to deposit assembly files for
         this precluster.  if not set, puts them in a tempdir and
         discards them at program end
  Ret  :
  Side Effects:
  Example :

=cut

sub set_assembly_dir {
  my ( $self, $dir ) = @_;
  $self->{assembly_dir} = $dir;
}

sub get_assembly_dir { shift->{assembly_dir} }

sub _tempdir {
  my ($self) = @_;

  $self->{tempdir} ||=
      File::Temp->newdir( TEMPLATE => 'cxgn-cluster-precluster-XXXXXXX',
                          CLEANUP  => 1,
                         );
}

=head2 function get_members()

 Usage:        my @members = $cluster->get_members()
 Desc:         returns a list of member ids
 Args:         none
 Side Effects: none
 Example:      none

=cut

sub get_members {
    my $self = shift;
    return sort keys %{$self->{members}} ;
}

=head2 get_member_count

  Usage: my $cnt = $cluster->get_member_count
  Desc : get the number of sequences in this precluster
  Args : none
  Ret  : number of member sequences in this cluster

=cut

sub get_member_count {
  my ($self) = @_;
  return scalar keys %{$self->{members}} ;
}


=head2 function get_consensus_seq

 Usage:        $cluster->get_consensus_seq( $seq_index );
 Desc:         calculates the optimal consensus sequences of the
               members of this cluster
 Args:         a Bio::Index::Fasta object from which to get the sequence
               for each member
 Ret:          a list of Bio::PrimarySeq objects containing the consensus
               sequences.
 Side Effects: might run phrap to calculate the alignments


 NOT YET IMPLEMENTED

=cut

sub get_consensus_seq {
  croak 'get_consensus_seq not yet implemented';
}


=head2 function write_member_seqs()

  Usage: $cluster->write_member_seqs($seq_index, $seqio_out);
  Desc : get the sequence of each cluster member from the given index
         and write it to the given Bio::SeqIO
  Args : a Bio::Index from which to get the sequences for members,
         a Bio::SeqIO object to write them to
  Ret  : nothing meaningful.
  Side Effects: dies on error
  Example:

=cut

sub write_member_seqs {
    my ($self,$index,$out) = @_;
    foreach my $id ( $self->get_members ) {
	my $seq = $index->fetch($id);
	$out->write_seq($seq);
    }
}

=head2 accessors get_cluster_set(), set_cluster_set()

 Usage:        $self->set_cluster_set($cluster_set)
 Desc:         Accessors for the cluster_set property
 Getter Ret:   the cluster set object that this precluster
               belongs to
 Setter Args:  a cluster_set that this precluster should
               belong to

=cut

sub get_cluster_set {
  my $self=shift;
  return $self->{cluster_set};
}
sub set_cluster_set {
  my $self=shift;
  $self->{cluster_set}=shift;
}

#this accessor should not be used by people outside of the Cluster
#framework, so i deleted their documentation
sub get_unique_key {
  my $self=shift;
  return $self->{unique_key};
}

sub set_unique_key {
  my $self=shift;
  $self->{unique_key}=shift;
}


=head2 function get_size()

synonym for get_member_count(): return the number of members in the cluster

=cut

sub get_size {
  shift->get_member_count;
}

=head2 function combine()

 Usage:        $cluster1->combine($cluster2)
 Desc:         combines cluster $cluster1 with cluster $cluster2,
               adding all elements in cluster2 to cluster1.
               cluster2 is deleted.
 Ret:          nothing
 Args:         a CXGN::Cluster::Precluster object
 Side Effects: the cluster specified by the argument will be deleted
 Example:

=cut

sub combine {
    my $self = shift;
    my $other = shift;

    my @other_members = $other->get_members();
    foreach my $o (@other_members) {
	$self->add_member($o);
    }
    $self->get_cluster_set()->remove_cluster($other);
    $self->{needs_phrap} = $self->get_member_count > 1;
}


##########
return 1;#
##########
