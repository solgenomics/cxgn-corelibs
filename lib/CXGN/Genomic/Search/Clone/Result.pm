package CXGN::Genomic::Search::Clone::Result;
use strict;
use warnings;

use CXGN::DB::DBICFactory;

use CXGN::Page::FormattingHelpers qw/commify_number columnar_table_html info_section_html/;
use CXGN::Tools::Identifiers qw/link_identifier/;

use base qw/CXGN::Search::WWWResult/;

=head1 NAME

CXGN::Genomic::Search::Result - result for L<CXGN::Genomic::Search::Clone>.

=head1 BASE CLASS(ES)

L<CXGN::Search::WWWResult>

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

=over 4

=item none yet

=back

=head1 DESCRIPTION

Result for L<CXGN::Genomic::Search::Clone>.

=head1 FUNCTIONS

=head2 to_html

Specified in L<CXGN::Search::Result::WWWResultI>.

=cut

sub to_html {
  my ($this) = @_;

  my $chado = CXGN::DB::DBICFactory->open_schema('Bio::Chado::Schema');

  my $clonedatapage = '/maps/physical/clone_info.pl';
  my $readinfopage = '/maps/physical/clone_read_info.pl';

  my $results_html = '';
  our $physical_dbconn ||= CXGN::DB::Connection->new;
  my @tableheadings = 
  my @tabledata;
  my $clonequerystring = $this->_query->to_query_string;
  while (my $clone = $this->next_result) {
    my $href = "$clonedatapage?id=".$clone->clone_id.'&'.$clonequerystring;
    my $linktag_first = qq{<a href="$href"> };

    sub munge {			#limit to 2 words and 21 chars
      no warnings;
      substr(join(' ',(split(' ',shift))[0..1]),0,21)
    }
    sub abbrev_first_word {
      my $str = shift || '';
      $str =~ s/(\w)\w+/$1\./;
      $str;
    }

    sub readlinks_html {	#take a clone and make a list of links to its sequence reads
      my ($clone,$readinfopage) = @_;;
      my @chromats = $clone->chromat_objects;
      join(', ',map {qq{<a href="$readinfopage?chrid=}.$_->chromat_id.'">'.$_->primer.'</a>'} @chromats); #'fix syntax highlighting
    }

    my (undef,$organism,$accession_common) = $clone->library_object->accession_name;

    my ($overgo_hit) = $physical_dbconn->selectrow_array('select count(assoc.plausible>0) from overgo_associations as assoc where assoc.bac_id=?',undef,$clone->clone_id);
    $overgo_hit &&= 'yes';

    push @tabledata,[ map {$_ || '-'} ($linktag_first.($clone->clone_name_with_chromosome || $clone->clone_name).'</a>',
				       (map {$_ && munge($_)} (abbrev_first_word($organism))),
					link_identifier($clone->genbank_accession($chado),'genbank_accession') || undef,
				       readlinks_html($clone,$readinfopage),
				       $overgo_hit,
				      )
		    ];
  }
  $results_html .= @tabledata ? columnar_table_html(headings => [ 'Clone Name','Organism','GenBank Accession','End Sequences','Overgo Hit'],
						    data => \@tabledata
						   )
                              : '<b>No matches found.</b>';
  $results_html .= $this->_search->pagination_buttons_html($this->_query,$this);

  $results_html = info_section_html(title => 'BAC Search Results',
				    subtitle => $this->time_html.' '.$this->_search->page_size_control_html($this->_query).'&nbsp;per&nbsp;page',
				    contents => <<EOH
<div style="text-align: right; margin-bottom: 0.3em"><a href="clone_reg.pl?$clonequerystring">view/edit BAC registry info</a></div>
$results_html
EOH
				   );
  return <<EOH;
<div id="searchresults">
$results_html
</div>
EOH

}


=head1 AUTHOR(S)

    Robert Buels

=cut



###
1;#do not remove
###
