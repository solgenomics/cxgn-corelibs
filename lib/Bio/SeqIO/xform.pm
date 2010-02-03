package Bio::SeqIO::xform;

use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::Seq::SeqFactory;
use Bio::Seq::SeqFastaSpeedFactory;
use UNIVERSAL qw/isa/;
use base 'Bio::SeqIO';
use Carp;

sub _initialize {
  my($self,@args) = @_;

  my %a = @args; #bind em to a hash

  ### check input ###
  $a{-enclose} && isa($a{-enclose},'Bio::SeqIO')
    or croak "Must provide SeqIO to map via -enclose";

  ref $a{-map_next} eq 'CODE'
    or croak '-map_next must be a subroutine reference'
      if($a{-map_next});

  ref $a{-map_write} eq 'CODE'
    or croak '-map_write must be a subroutine reference'
      if($a{-map_write});

  @{$self}{qw/_seqio    _next      _write    /} =
    @a{qw/    -enclose  -map_next  -map_write/};

  $self->SUPER::_initialize(@args);
}


=head2 enclosed

  Ret : the enclosed SeqIO object, or undef if none set

=cut

sub enclosed {
  my $this = shift;
  UNIVERSAL::isa($this,__PACKAGE__)
      or croak 'improper use of enclosed(), which is a method of '.__PACKAGE__;
  $this->{_seqio};
}


#ret: new page number
# sub _params_nextpage {
#   my $self = shift;
#   if ( defined $self->{_sgn_pagenum} ) {
#     $self->{_sgn_pagenum}++;
#   } else {
#     $self->{_sgn_pagenum} = 0;
#   }
#   $self->params->page($self->{_sgn_pagenum});
# }

=head2 next_seq

 Title   : next_seq
 Usage   :
 Function: returns the next sequence in the stream
 Returns : Bio::Seq object
 Args    : NONE

=cut

sub next_seq {

    my( $self ) = @_;

    my $nextseq = $self->{_seqio}->next_seq;
    return $nextseq unless $nextseq;

    $self->{_next} ? $self->{_next}->($nextseq) : $nextseq;
}

=head2 write_seq

 Title   : write_seq
 Usage   : 

=cut

sub write_seq {
  my $self = shift;
  my @seqs = @_;

  $self->{_seqio}->write_seq(
			     $self->{_write} ?
		   	       $self->{_write}->(@seqs) :
			       @seqs
			    );
}

###
1;#do not remove
###
