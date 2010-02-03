package CXGN::Genomic::BlastHit;

=head1 NAME

    CXGN::Genomic::BlastHit - genomic.blast_hit object abstraction

=head1 DESCRIPTION

none yet

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;
use Carp;

=head1 DATA FIELDS

  Primary Keys:
      blast_hit_id

  Columns:
      blast_hit_id
      blast_query_id
      identifier
      evalue
      score
      identity_percentage
      align_start
      align_end
      blast_defline_id

  Sequence:
      (genomic base schema).blast_hit_blast_hit_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.blast_hit');

our @primary_key_names =
    qw/
      blast_hit_id
      /;

our @column_names =
    qw/
      blast_hit_id
      blast_query_id
      identifier
      evalue
      score
      identity_percentage
      align_start
      align_end
      blast_defline_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.blast_hit_blast_hit_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';


=head2 blast_query_id

  Desc: L<Class::DBI> has_a relationship to L<CXGN::Genomic::BlastQuery>
  Args: none
  Ret : the L<CXGN::Genomic::BlastQuery> associated with this BlastHit
  Side Effects:
  Example:

=cut

__PACKAGE__->has_a(blast_query_id => 'CXGN::Genomic::BlastQuery');


=head2 query_object

Alias for blast_query_id() above.

=cut

sub query_object {
  shift->blast_query_id(@_);
}

=head2 blast_defline_id

  Desc: L<Class::DBI> has_a relationship to L<CXGN::Genomic::BlastDefline>
  Args: none
  Ret : L<CXGN::Genomic::BlastDefline> object associated with this Blasthit
  Side Effects:
  Example:

=cut

__PACKAGE__->has_a(blast_defline_id => 'CXGN::Genomic::BlastDefline');

=head2 defline_object

Alias for blast_defline_id() above.

=cut

sub defline_object {
  shift->blast_defline_id(@_);
}

=head2 summary_html

  Desc:
  Args: none
  Ret : string containing an HTML summary of this BlastHit's vital statistics
  Side Effects: none
  Example:

  print $myhit->summary_html();

=cut

sub summary_html {
  my $this = shift;

  #info: database, hit ID, defline, evalue, score 

  my $query = $this->query_object;
  my $db = $query->db_object
    or croak 'No DB object found for blast hit '.$this->blast_hit_id;
  my $defline = $this->defline_object;


  #make the db name a link if we have a URL
  my $db_html = $db->title.' ('.$db->file_base.')';
  $db_html = $db->info_url
    ? qq{<a class="blasthit_db" href="}.$db->info_url.qq{">$db_html</a>}
    : qq{<span class="blasthit_db">$db_html</span>};

  my ($score,$evalue,$identity,$start,$end) =
    ($this->score, $this->evalue, $this->identity_percentage,
     $this->align_start, $this->align_end);

  #make the identifier of the thing it hit a link if we can.  first
  #see if there's an explicit lookup_url in the DB object, then see if
  #CXGN::Tools::Identifiers can make a link out of it
  my $lookup_url = $db->identifier_url($this->identifier);
  my $id_html =  $lookup_url
    ? qq{<a href="$lookup_url">}.$this->identifier.'</a>'
    : $this->identifier;

  $identity = sprintf('%0.2f%%',$identity*100);

  my $hit_type = 'NCBI BLAST';
  my $seq_len = $query->query_len;
  my $frame = ($start < $end)
    ? ($start % 3) + 1
    : -((($seq_len - $start - 1) % 3) + 1);

  my $align_len = $end-$start;
  $align_len = -$align_len if $align_len < 0;
  my $align_percentage = sprintf('%0.2f',$align_len/$seq_len*100);

  my $align_len_html = "${align_len}bp&nbsp;($align_percentage%)";

  my @statnames = ('Score','E Value','Identity','Align. Length','Frame');

  #for both statistic names and values, replace all spaces with non-breaking
  #and put in correct span for styling
  @statnames = 
    map 
      {s/\s/&nbsp;/g; qq|<span class="blasthit_statname">$_</span>| }
	@statnames;
  my %stats;
  @stats{@statnames} = 
    map { s/\s/&nbsp;/g;
	  qq|<span class="blasthit_statval">$_</span>|
	}
      ($score,$evalue,$identity,$align_len_html,$frame);

  my $stats_html;
  foreach my $sname (@statnames) {
    $stats_html .= "$sname&nbsp;$stats{$sname}\n";
  }

  my $dl_html =
    '<span class="blasthit_defline">'
      .($defline->defline || '<span class="ghosted">No sequence description found.</span>').'</span>';

  return <<EOH;
<table cellspacing="0" class="blasthit" width="100%">
<tr><td class="blasthit_db" colspan="2"><table width="100%"><tr><td>$db_html</td><td class="blasthit_type"><span class="blasthit_type">$hit_type</span></td></table></td>
</tr>
<tr><td class="blasthit_id"><span class="blasthit_id">$id_html</span></td>
    <td class="blasthit_stats">
       $stats_html
    </td>
</tr>
<tr>
    <td class="blasthit_defline" colspan="2">$dl_html</td>
</tr>
</table>
EOH
}


=head1 PACKAGE METHODS

=head2 delete_where_associated_with_blast_query

  Desc:
  Args: a CXGN::Genomic::BlastQuery object
  Ret : unspecified
  Side Effects:
  Example:

   CXGN::Genomic::BlastHit->delete_where_associated_with_blast_query($myquery);

  Note:

   THIS METHOD IS DEPRECATED.
   Do $_->delete foreach $query->blast_hit_objects yourself instead.

=cut

sub delete_where_associated_with_blast_query {

  my ($class,$blastquery) = @_;

  ref($class)
    and croak 'delete_where_associated_with_blast_query() is a package method, not an object method';

  UNIVERSAL::isa($blastquery,'CXGN::Genomic::BlastQuery')
      or croak "Must supply a BlastQuery or subclass thereof";

  $_->delete foreach $blastquery->blast_hit_objects;
  return 1;
}


=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
