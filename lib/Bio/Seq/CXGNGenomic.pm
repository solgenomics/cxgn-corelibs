package Bio::Seq::CXGNGenomic;

use Carp;
use English;
use base qw/Bio::Seq::Quality/;
use Data::Dumper;

use Class::MethodMaker 
  [
   scalar => [ +{-type => 'CXGN::Genomic::GSS'}, 'gss_object' ],
  ];

#allowed to make new CXGNGenomic seqs
sub can_call_new {
  1;
}

sub vector_trimmed_trunc {
  my $this = shift;
  shift && croak 'Too many arguments to trimmed_seq.';

#  print 'trimmed qual is '.$this->gss_object->trimmed_qual."\n";

  __PACKAGE__->new(-display_id       => $this->display_id,
		   -accession_number => $this->accession_number,
		   -alphabet         => $this->alphabet,
		   -desc             => $this->desc.' (vector and quality trimmed)',
		   -verbose          => $this->verbose,
		   -primary_id       => $this->primary_id,
		   -seq              => $this->gss_object->trimmed_seq,
		   -qual             => $this->gss_object->trimmed_qual || '1',
		   #above strange || '1' is there to sidestep BioPerl bugzilla bug #1824
		  );
}



###
1;# do not remove
###
