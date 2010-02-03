package Bio::SeqIO::sgn_genomic;

use strict;
use English;

# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::Seq::SeqFactory;
use Bio::Seq::SeqFastaSpeedFactory;
use base 'Bio::SeqIO';
use Carp;

use Class::MethodMaker
  [ scalar => [+{-type=>'CXGN::Genomic::Search::GSS::Query'},  'query',
	       +{-type=>'CXGN::Genomic::Search::GSS::Result'}, 'result',
	       +{-type=>'CXGN::Genomic::Search::GSS'},         'search',
	      ]
  ];


sub _initialize {
  my($self,@args) = @_;

  my %a = @args; #bind em to a hash

  $a{-query} or croak "Must provide search query via -query ($a{-query})";
  $a{-dbconn} && UNIVERSAL::isa($a{-dbconn},'CXGN::DB::Connection')
    or croak 'Must provide CXGN::DB::Connection object via -dbconn';

  $self->query($a{-query});
  $self->search( CXGN::Genomic::Search::GSS->new($self->query) );

  $self->SUPER::_initialize(@args);
  unless ( defined $self->sequence_factory ) {
      $self->sequence_factory( Bio::Seq::SeqFactory->new( -type => 'Bio::Seq::CXGNGenomic' ) );
  }

  #set the results object to autopage through the results
  $self->query->order_by(gss_id => 'asc');
  $self->result($self->search->new_result);
  $self->result->autopage($self->query,$self->search);
}

=head2 next_seq

 Title   : next_seq
 Usage   : $seq = $stream->next_seq()
 Function: returns the next sequence in the stream
 Returns : Bio::Seq object or undef if no more sequences
 Args    : NONE

=cut

sub next_seq {
    my( $self ) = @_;
    my $alphabet;

    #note: initialize above put the result in autopage mode
    my $gss = $self->result->next_result
      or return undef;

    ### at this point, $gss _must_ contain our new gss object ###
    $gss->isa('CXGN::Genomic::GSS')
      or die 'there is something wrong with this code';

#    print 'try gss '.$gss->gss_id." ($gss)\n";
#    my $seq =
#    eval {
    $gss->to_bio_seq( -factory => $self->sequence_factory );
#     }; if($EVAL_ERROR) {
#       use Data::Dumper;
#       warn $EVAL_ERROR;
#       die Dumper($gss);
#     }
#    print "got seq $seq\n";
#    print "got gss ".$seq->gss_object."\n";
#    return sequences$seq;
}

=head2 write_seq

 Title   : write_seq
 Usage   : this method is not implemented.  writing to the
           genomic database is not allowed through this interface

=cut

sub write_seq {
  croak 'write_seq not implemented.  Writing to the genomic database is not allowed through this interface';
}

=head2 result

  Accessor for this seqIO GSS results object

=head2 query

  Accessor for this seqIO GSS results object

=head2 search

  Accessor for this seqIO GSS results object

=cut

###
1;#do not remove
###
