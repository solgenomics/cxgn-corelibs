package CXGN::Genomic::Search::GSS;
use strict;
use warnings;
use English;
use Carp;

use CXGN::Tools::Class qw/ parricide /;

use CXGN::Genomic::GSS;
use CXGN::Genomic::Search::GSS::Query;
use CXGN::Genomic::Search::GSS::Result;

use Bio::SeqIO::sgn_genomic;

use base qw/CXGN::Search::DBI::CDBI/;

=head1 NAME

CXGN::Genomic::Search::GSS.pm - a CXGN Search object - takes L<CXGN::Genomic::Search::GSS::Query> objects and returns L<CXGN::Genomic::Search::GSS::Result> objects

=head1 SYNOPSIS

  #SIMPLE: count the number of GSS objects in a given library
  my $gss_search = CXGN::Genomic::Search::GSS->new;
  my $gssq = $gss_search->new_query;
  $gssq->library_id($this->library_id);

  my $results = $gss_search->do_search($gssq);

  $results->total_results;


  #MORE ADVANCED USAGE

  my $gss_search = CXGN::Genomic::Search::GSS->new($dbh);
  my $gss_query = $gss_search->new_query();

  #search for all GSS objects with trimmed sequence length between
  #300 and 500
  $gss_query->trimmed_length('&t >= 300 AND &t <= 500");
  #and that have an arizona clone name like 'SL*0002A*'
  $gss_query->arizona_clone_name(" LIKE 'SL%0002A%'");

  #perform the search
  my $gss_result = $gss_search->do_search($gss_query);

  #iterate through every CXGN::Genomic::GSS object in the results
  #and print its external identifier and its vector-trimmed sequence
  #in FASTA format
  while(my $gss = $gss_result->next_result($gss_search,$gss_query)) {
    print '>'.$gss->chromat_object->chromat_external_identifier."\n".$gss->trimmed_seq."\n";
  }

=head1 BASE CLASS(ES)

L<CXGN::Search::SearchI>

=head1 SOME SCRIPTS THAT USE THIS

=over 12

=item genomic_blast_annotations.pl

=item query-genomic-seqs.pl

=back

=head1 FUNCTIONS

=head2 seqIO_search

  Similar to do_search, except returns a BioPerl L<Bio::SeqIO::sgn_genomic>
  object to iterate over the resulting sequences.  Also, the requested page
  number in the given parameters is ignored.

=cut

sub seqIO_search {
  my ($this,$query) = @_;

  return Bio::SeqIO::sgn_genomic->new( -query  => $query,
				       -search => $this,
				       -dbconn => CXGN::Genomic::GSS->db_Main,
				     );
}

__PACKAGE__->creates_result('CXGN::Genomic::Search::GSS::Result');

__PACKAGE__->transforms_rows('CXGN::Genomic::GSS');

__PACKAGE__->uses_query('CXGN::Genomic::Search::GSS::Query');

=head1 AUTHOR(S)

    Robert Buels

=cut


###
1;#do not remove
###
