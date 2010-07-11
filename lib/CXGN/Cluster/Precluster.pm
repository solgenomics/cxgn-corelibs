
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
use File::Temp qw/tempdir/;

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
    return
      (				#SINGLETONS
       map {
	 my $s = $_;
	 [ [$s->id, 1, $s->seqref->length, 1 ] ]
       } $self->{assembly}->all_singlets
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
	 } $self->{assembly}->all_contigs
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
 Args: a Bio::Index::Fasta object to get sequences from, because
       we need the sequences to calculate the proper assembly
 Side Effects: may call phrap to calculate the assembly

=cut

#use Smart::Comments;

sub get_consensus_base_segments {
    my ($self, $seq_index) = @_;

    $self->_run_phrap($seq_index) if $self->{needs_phrap};

    my %af;
    my $curr_reads;
    my @consensi;
    open my $ace, '<', $self->{phrap_ace} or die "$! opening $self->{phrap_ace}";
    while( my $line = <$ace> ) {
        if( $line =~ /^AF (\S+) (U|C) (\d+)/ ) {
            ### AF: $line
            $af{$1} = [ $2 eq 'C' ? 1 : 0,
                        $3
                      ];
            ### af: $af{$1}
        }
        elsif( $line =~ /^BS (\d+) (\d+) (\S+)/ ) {
            ### line: $line
            my ( $reverse, $offset ) = @{$af{$3}};
            my ( $rs, $re ) = map { $_ - $offset + 1 } $1, $2;
            ### bs:  [ $1, $2, $rs, $re, $3 ]
            ### length 1: $2 - $1 + 1
            ### length 2: $re - $rs + 1
            push @$curr_reads, [ $1, $2, $3, $rs, $re, $reverse ];
            ### read length: $seq_index->fetch($3)->length
        }
        elsif( $line =~ /^CO / ) {
            push @consensi, $curr_reads = [];
        }
    }

    return @consensi;
}



sub _run_phrap {
  my ($self,$seq_index) = @_;

  ref($seq_index) && $seq_index->isa('Bio::Index::Fasta')
    or croak 'must provide a Bio::Index::Fasta';

  #make a temp fasta file and run phrap on it
  my $tempdir = $self->_tempdir;
  my $max_seq_size = 0;
  my $seq_count;
  my $seqs_temp = do {
    my $t = "$tempdir/thiscluster.seq";
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

  my $phrap = CXGN::Tools::Run->run( $phrap_exec,
				     $seqs_temp,
                                     '-new_ace',
				     $self->_phrap_options,
				     { working_dir => $tempdir },
				   );
  #warn "phrap output:\n".$phrap->out;
  $self->{phrap_ace} = "$seqs_temp.ace";

  my $as_in = Bio::Assembly::IO->new( -file => $phrap->out_file,
				      -format => 'phrap',
				    );


  my $as = $self->{assembly} = $as_in->next_assembly;

  $self->{needs_phrap} = 0;
}

# THESE PHRAP OPTIONS ARE FOR ASSEMBLING CONTIGS OF BAC SEQUENCES
#
# if we start wanting to use this module for something else,
# you'll need to factor out these phrap options into subclasses
# and add some kind of accessor to ClusterSet to choose what kind
# of clusters you're making

sub _phrap_options {
  (
   -vector_bound => 0,
   -minmatch     => 1_500,
   -maxmatch     => 60_000,
   -forcelevel   => 10,
   -bypasslevel  => 0,
   -repeat_stringency => .98,
   -node_seg     => 1000,
#   -maxgap       => 1_000,
#   -node_seg     => 20_000,
#   -node_space   => 1_000,
  )
}

sub _tempdir {
  my ($self) = @_;
  $self->{tempdir} ||= tempdir(CLEANUP => 1);
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
