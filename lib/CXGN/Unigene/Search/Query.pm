package CXGN::Unigene::Search::Query;
use strict;
use warnings;
use Carp;

#Storable and Cache are used for caching the list of unigene builds
#in generating the search form
use Storable qw/ freeze thaw /;
use Cache::File;

use CXGN::Page::FormattingHelpers qw/ simple_selectbox_html
				      numerical_range_input_html
				      info_table_html
				      commify_number
				    /;
use CXGN::Tools::Class qw/ parricide /;
use CXGN::Tools::Text qw/ to_tsquery_string from_tsquery_string trim /;
use CXGN::Tools::Identifiers qw/identifier_namespace clean_identifier/;
use CXGN::Tools::List qw/str_in/;
use CXGN::CDBI::SGN::Unigene;
use base qw/ CXGN::Search::DBI::Simple::WWWQuery /;

####################  BASIC SEARCH STUFF #############################

#make some aliases for fully-qualified table names so
#we don't have to type them
my $sgn = 'sgn';
my ($ug,  $ugc,  $ugb,  $ugm,  $est,  $qcr,
    $seqread,  $clone,
    $bq,  $bh,  $bdl,  $bdb,
    $ma,  $pum,  $mk,
    $cds,  $domm,  $dom,   $ipr,   $iprgo,  $go) =
  map {"$sgn.$_"}
  qw/  unigene unigene_consensi unigene_build unigene_member est qc_report
       seqread clone
       blast_annotations blast_hits blast_defline blast_targets
	    manual_annotations primer_unigene_match marker
       cds  domain_match  domain  interpro  interpro_go  go
     /;

my $b_applytype = 15;
my $m_applytype = 1;

#define all the tables and how they join together
__PACKAGE__->join_root("$sgn.unigene");
__PACKAGE__->uses_joinpath('build',
			   [$ugb, "$ug.unigene_build_id=$ugb.unigene_build_id"],
			  );
__PACKAGE__->uses_joinpath('consensus',
			   [$ugc, "$ug.consensi_id=$ugc.consensi_id"],
			  );
__PACKAGE__->uses_joinpath('members_qcr',
			   [$ugm, "$ug.unigene_id=$ugm.unigene_id"],
			   [$est, "$ugm.est_id=$est.est_id"],
			   [$qcr, "$est.est_id=$qcr.est_id"],
			  );
__PACKAGE__->uses_joinpath('members_clone',
			   [$ugm,     "$ug.unigene_id=$ugm.unigene_id"],
			   [$est,     "$ugm.est_id=$est.est_id"],
			   [$seqread, "$est.read_id = $seqread.read_id"],
			   [$clone,   "$clone.clone_id = $seqread.clone_id"],
			  );
__PACKAGE__->uses_joinpath('blast',
			   [$bq,  "$ug.unigene_id=$bq.apply_id AND $bq.apply_type=$b_applytype"],
			   [$bh,  "$bq.blast_annotation_id=$bh.blast_annotation_id"],
			   [$bdl, "$bh.defline_id=$bdl.defline_id"],
			  );
__PACKAGE__->uses_joinpath('manual',
			   [$ma, "$ug.unigene_id=$ma.annotation_target_id AND $ma.annotation_target_type_id=$m_applytype"],
			  );
__PACKAGE__->uses_joinpath('marker', [$pum,"$ug.unigene_id=$pum.unigene_id"],
			   [$mk, "$pum.marker_id=$mk.marker_id"],
			  );
__PACKAGE__->uses_joinpath('go',
			   [$cds,  "$cds.unigene_id=$ug.unigene_id"],
			   [$domm, "$domm.cds_id=$cds.cds_id"],
			   [$dom,  "$dom.domain_id=$domm.domain_id"],
			   [$ipr,  "$ipr.interpro_id=$dom.interpro_id"],
			   [$iprgo,"$iprgo.interpro_accession=$ipr.interpro_accession"],
			   [$go,   "$go.go_accession=$iprgo.go_accession"],
			  );

#make parameters for all of the columns in a unigene
__PACKAGE__->has_parameter(name => "$_", columns => "$sgn.unigene.$_") foreach CXGN::CDBI::SGN::Unigene->columns;

# __PACKAGE__->has_parameter( name    => 'published_identifier',
# 			    columns => [ "$sgn.unigene.database_name",
# 					 "$sgn.unigene.sequence_name",
# 				       ],
# 			    sqlexpr => "$sgn.unigene.database_name || '-U' || $sgn.unigene.sequence_name",
# 			  );

#make a length parameter
__PACKAGE__->has_parameter(name => 'length',
			   columns => [ "$sgn.unigene_consensi.seq",
					"$sgn.unigene_member.qstart",
					"$sgn.unigene_member.qend",
				      ],
			   sqlexpr => <<EOSQL,
COALESCE( char_length($sgn.unigene_consensi.seq), $sgn.unigene_member.qend - $sgn.unigene_member.qstart + 1 )
EOSQL
			   group   => 1,
			  );

__PACKAGE__->has_parameter( name    => 'primer_matches_marker',
			    columns => "$pum.marker_id",
			    group   => 1,
			  );

#make fulltext search parameters for blast deflines and manual annotation text fields
__PACKAGE__->has_parameter(name    => 'blast_defline_fulltext',
			   columns => "$sgn.blast_defline.defline_fulltext",
			   group   => 1,
			  );

__PACKAGE__->has_parameter(name    => 'manual_annot_fulltext',
			   columns => "$sgn.manual_annotations.annotation_text_fulltext",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'domain_desc_fulltext',
			   columns => "$dom.description_fulltext",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'domain_accession',
			   columns => "$dom.domain_accession",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'interpro_desc_fulltext',
			   columns => "$ipr.description_fulltext",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'interpro_accession',
			   columns => "$ipr.interpro_accession",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'go_desc_fulltext',
			   columns => "$go.description_fulltext",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'go_accession',
			   columns => "$go.go_accession",
			   group   => 1,
			  );
__PACKAGE__->has_parameter(name    => 'clone_name',
			   columns => "$clone.clone_name",
			   group   => 1, #< might have multiple clones
			  );
__PACKAGE__->has_parameter(name    => 'est_id',
			   columns => "$est.est_id",
			   group   => 1, #< might have multiple members
			  );
__PACKAGE__->has_parameter(name    => 'build_status',
			   columns => "$ugb.status",
			  );

#set which columns we select with
__PACKAGE__->selects_class_dbi('CXGN::CDBI::SGN::Unigene');


#make a genbank_accession parameter, which sets the clone_name to be
#in a set of GIs that resolve from the given accession
sub genbank_accession {
  my ($self,$accession) = @_;

  #validate arguments
  $accession
    or croak "must provide an accession\n";

  $accession =~ /^[A-Z_]+\d+$/
    or croak "'$accession' does not look like a valid unversioned genbank accession\n";


  #look for a clone name that is one of the GIs that correspond to
  #that accession
  $self->clone_name(<<EOQ,($accession)x2);
IN(
   select 'GI|' || dbx.accession as gi
   from public.feature f
   join public.feature_dbxref fd using(feature_id)
   join public.dbxref dbx on fd.dbxref_id = dbx.dbxref_id
   join public.db db using(db_id)
   where
       db.name = 'DB:GenBank_GI'
     and
       f.name = ?
   UNION
   select 'GI|' || dbx.accession as gi
   from public.feature f
   join public.dbxref dbx using(dbxref_id)
   join public.db db using(db_id)
   where
       db.name = 'DB:GenBank_GI'
     and
       f.name = ?
 )
EOQ
}

####################################### WEB SEARCH STUFF ##########################


sub to_html {
  no warnings 'substr'; #turn off 'uninitialized value' warnings

  my $this = shift;

  my %scalars = $this->_to_scalars;

  #use Tie::Function so I can use hash syntax to call this function,
  #thereby letting me interpolate function calls into strings.
  tie my %pnames,   'Tie::Function', sub { $this->uniqify_name(@_) };
  tie my %webvalue, 'Tie::Function', sub { $this->data(@_)         };

  #make a 2-D array of selection box choices (like those passed to CXGN::FormattingHelpers::simple_selectbox_html
  #for the choices of unigene builds

  #do some caching of the unigene build choices, since they are a little expensive to generate
  my $unigene_build_choices = do {
    _unigene_build_choices()
  };

  my $blast_checked    = $scalars{annot_type} eq 'blast'    ? 'checked="checked" ' : '';
  my $manual_checked   = $scalars{annot_type} eq 'manual'   ? 'checked="checked" ' : '';
  my $interpro_checked = $scalars{annot_type} eq 'interpro' ? 'checked="checked" ' : '';
  my $go_checked       = $scalars{annot_type} eq 'go'       ? 'checked="checked" ' : '';
  my $domain_checked   = $scalars{annot_type} eq 'domain'   ? 'checked="checked" ' : '';

  my $marker_checked = $scalars{has_marker} ? ' checked="checked"' : '';

  my $table1 = info_table_html( 'Unigene Identifier'      =>
				qq|<table><tr><td><input type="text" value="$webvalue{sequence_name}" name="$pnames{sequence_name}" size="18" /></td><td style="color: gray">SGN-U1234<br />or CGN-U124510</td></tr></table>|,
				'Includes member'  =>
				qq!<table><tr><td><input type="text" value="$webvalue{clone_name}" name="$pnames{clone_name}" size="18" /></td><td style="color: gray">cLED-10-L1<br />or SGN-E231384<br />or GI:399643<br />or gi|399643|L24060.1|<br />or L24060</td></tr></table>!,
				'Annotation text contains'   => <<EOHTML,
  <input value="$scalars{annotation}" type="text" size="45" name="$pnames{annotation}" /><br />
  <table cellpadding="0" cellspacing="0" summary="">
    <tr><td><input type="radio" name="$pnames{annot_type}" value="blast" $blast_checked/>Automatic&nbsp;(BLAST)</td>
        <td><input type="radio" name="$pnames{annot_type}" value="manual" $manual_checked/>Manual</td>
        <td><input type="radio" name="$pnames{annot_type}" value="interpro" $interpro_checked/>Interpro</td>
    </tr>
    <tr><td><input type="radio" name="$pnames{annot_type}" value="domain" $domain_checked/>Protein&nbsp;Domain</td>
        <td colspan="2"><input type="radio" name="$pnames{annot_type}" value="go" $go_checked/>Gene&nbsp;Ontology</td>
    </tr>
  </table>
EOHTML

				__multicol   => 2,
				__tableattrs => 'width="100%"',
				__border        => 0,
				'&nbsp;'      => '',
				'Number of members' =>
				numerical_range_input_html( compare => [$pnames{membersrange}, $scalars{membersrange} ],
							    value1  => [$pnames{members1},     commify_number($scalars{members1}) ],
							    value2  => [$pnames{members2},     commify_number($scalars{members2}) ],
							    units   => '',
							  ),
				Length              =>
				numerical_range_input_html( compare => [$pnames{lenrange}, $scalars{lenrange} ],
							    value1  => [$pnames{len1},     commify_number($scalars{len1}) ],
							    value2  => [$pnames{len2},     commify_number($scalars{len2}) ],
							    units   => 'bp',
							  ),
#				'Must Have'             => <<EOHTML,
#<input type="checkbox" name="$pnames{has_marker}"$marker_checked><label for="$pnames{has_marker}">associated marker</label>
#EOHTML
			      );

#  warn "scalar is $scalars{unigene_build_id}\n";
  my $buildform = info_table_html ('Unigene build' =>
				   simple_selectbox_html( choices  => $unigene_build_choices,
							  name     => $pnames{unigene_build_id},
							  selected => $scalars{unigene_build_id},
							),
				   '&nbsp;'        => qq|<input type="submit" value="Search" />|,
				   __multicol      => 2,
 				   __border        => 0,
				   __tableattrs    => 'width="100%"',
				  );

  return <<UNIGENETAB;
  <input type="hidden" name="$pnames{page}" value="0" />
  $table1
  $buildform
UNIGENETAB
}

#assemble an array ref of
#[ build id, build description ] for use in the html form above
sub _unigene_build_choices {
  my @sorted_build_list =
    sort { $a->organism_group_name cmp $b->organism_group_name
	     || $b->build_date cmp $a->build_date              } CXGN::CDBI::SGN::UnigeneBuild->retrieve_all;

  my @build_choices =
    map { my $build = $_;
	  my $id = $build->unigene_build_id;
	  my $current = ($build->status eq 'C' ? '' : '&nbsp;&nbsp;[old] ');
	  my $desc_string = $current.$_->organism_group_name.' #'.$build->build_nr.' ('.$build->build_date.')';

	  [ $id, $desc_string ] #return this

	} @sorted_build_list;

  return [ ['C','any current build'],
	   ['any','any build (including old builds)'],
	   @build_choices,
	 ];
}

=head2 request_to_params

  Desc: given a hash-style list of HTML form names => form values,
        fill in the search parameters in this query object from them.
        Called by from_request in L<CXGN::Search::Query::DBI::WWWSimple>.
  Args: name=>value list of query parameters
  Ret : uspecified
  Side Effects: fill in the internal state of this query object
  Example:

=cut

sub request_to_params {
  my $this = shift;
  my %request = @_;


  # validate parameters
  #these should not be necessary, since DBI placeholders are used throughout
#   delete $params{w9e3_membersrange} unless $params{w9e3_membersrange} =~ /^\d+$/;
#   delete $params{w9e3_members1} unless $params{w9e3_members1} =~ /^\d+$/;
#   delete $params{w9e3_unigene_build_id} unless $params{w9e3_unigene_build_id} =~ /^\d+$/;
#   delete $params{w9e3_len1} unless $params{w9e3_len1} =~ /^\d+$/;

  #sanitize all the parameters
  foreach my $key (keys %request) {
    if( $request{$key} ) {
      $request{$key} = trim($request{$key});
      $request{$key} =~ s/[;'",]//g;
    }
  }

  #sequence_name
  if( $request{sequence_name} ) {
    my $ns = identifier_namespace($request{sequence_name});
    my ($digits) =  $request{sequence_name} =~ /(\d+)/;
    if( $ns eq 'sgn_u') {
       # SGN-U given
       # use unigene_id, NOT sequence_name
       # don't use database_name
       $this->unigene_id("=?",$digits);
    }
    elsif( $ns eq 'cgn_u') {
      $this->database_name('=?','CGN');
      $this->sequence_name(" = ?",$digits);
    }
    else {
      $this->database_name('=?','SGN');
      $this->sequence_name('=?',$digits);
    }
  }

  #clone_name
  if($request{clone_name}) {
    my $ns = identifier_namespace($request{clone_name});
#    warn "GOT NS '$ns' for request '$request{clone_name}'\n";
    if($ns eq 'genbank_accession') {
      $request{clone_name} = clean_identifier($request{clone_name},'genbank_accession');
      if(my ($acc) = $request{clone_name} =~ /([A-Z_]+\d+)/i) {
	$acc = uc $acc;
	$this->genbank_accession($acc);
      } else {
	die "could not understand genbank accession\n";
      }
    } elsif($ns eq 'genbank_gi') { #just try to extract numbers from it as a GI
      my ($digits) = $request{clone_name} =~ /(\d{4,})/
	or die 'could not understand genbank GI number';
      $this->clone_name('=?',"GI|$digits");
    } elsif($ns eq 'sgn_e') {
      my ($digits) = $request{clone_name} =~ /(\d{4,})/
	or die 'could not understand SGN-E number';
      $this->est_id('=?',$digits);
    } else {
      my $clean = clean_identifier($request{clone_name}) || $request{clone_name};
      $this->clone_name('=?',$clean);
    }
  }

  #unigene build
  if( $request{unigene_build_id} ) {
    if( $request{unigene_build_id} eq 'C' ) {
      $this->build_status('=?','C');
    } elsif($request{unigene_build_id} eq 'any')  {
      #do nothing
    } else {
      $this->unigene_build_id("= ?",$request{unigene_build_id});
    }
  }

  #consensus length
  if( defined($request{len1}) ) {
    $this->ranged_parameter_from_scalars('length',
					 @request{ qw/lenrange len1 len2/ }
					);
  }

  #number of members
  if( defined($request{members1}) ) {
    $this->ranged_parameter_from_scalars('nr_members',
					 @request{ qw/membersrange members1 members2/ }
					);
  }

  #has_marker
  if( $request{has_marker} ) {
    $this->primer_matches_marker('IS NOT NULL');
  }

  #page number
  if( defined($request{page}) ) {
    $this->page($request{page});
  }

  #assemble query params and orderbys for fulltext annotation searches
#  my @fulltext_orderby = ();
  if( defined($request{annotation}) ) {

    #format the query string like tsearch expects
    my $qstr = to_tsquery_string($request{annotation});
    my ($qnums) = $request{annotation} =~ /(\d{3,})/;

    #make the query and orderby for blast annotations,
    #if requested
    if( $request{annot_type} eq 'blast' ) {
      $this->blast_defline_fulltext(" @@ to_tsquery(?)",$qstr);
    }
    elsif( $request{annot_type} eq 'manual') {
      $this->manual_annot_fulltext(" @@ to_tsquery(?)",$qstr);
    }
    elsif( $request{annot_type} eq 'domain') {
      $this->domain_desc_fulltext(" @@ to_tsquery(?)",$qstr);
      if( defined($qnums) ) { #if there are some nums in it
	$this->domain_accession("=?",$request{annotation});
	$this->compound('&t OR &t','domain_accession','domain_desc_fulltext');
      }
    }
    elsif( $request{annot_type} eq 'interpro') {
      $this->interpro_desc_fulltext(" @@ to_tsquery(?)",$qstr);
      if( defined($qnums) ) {
	$this->interpro_accession("= ('IPR' || ?)",$qnums);
	$this->compound('&t OR &t','interpro_accession','interpro_desc_fulltext');
      }
    }
    elsif( $request{annot_type} eq 'go') {
      $this->go_desc_fulltext(" @@ to_tsquery(?)",$qstr);
      if( defined($qnums) ) {
	$this->go_accession("=?",$qnums);
	$this->compound('&t OR &t','go_accession','go_desc_fulltext');
      }
    }
  }

  sub any { $_ && return 1 for @_; 0 } #given a list, returns whether any are true

  #if none of the parameters that involve checking whether NULL
  #values are set, we can optimize by replacing the default
  #left joins with natural (inner) joins, which are often faster
  my @null_checking_params = qw/ len1 /;
  unless( any @request{@null_checking_params} ) {
    $this->natural_joins(1);
  }

  #warning: specifying an ordering makes big queries really really slow
  $this->orderby( unigene_id       => 'ASC',
		  unigene_build_id => 'ASC',
		  nr_members       => 'DESC',
		);

  return 1;
}

=head2 _to_scalars

  Desc: method to distill this query object into a hash of simple scalar
        variables for the purposes  of using these values in an HTML form
        or URL query string
  Args: none
  Ret : hash of (variable name => value, variable name => value, ...)
  Side Effects: none

=cut

sub _to_scalars {
  my ($this) = @_;

  my %scalars;

  ($scalars{sequence_name}) = $this->param_bindvalues('sequence_name');

  ($scalars{unigene_build_id}) = $this->param_bindvalues('unigene_build_id');
  ($scalars{unigene_build_id}) = $this->param_bindvalues('build_status') unless $scalars{unigene_build_id};
  $scalars{unigene_build_id} ||= 'any';

  $scalars{page} = $this->page;

  ($scalars{clone_name}) = $this->param_bindvalues('clone_name');

  @scalars{qw/lenrange len1 len2/} = $this->ranged_parameter_to_scalars('length');
  @scalars{qw/membersrange members1 members2/} = $this->ranged_parameter_to_scalars('nr_members');

  my ($blast_annot)    = $this->param_bindvalues('blast_defline_fulltext');
  my ($manual_annot)   = $this->param_bindvalues('manual_annot_fulltext');
  my ($interpro_annot) = $this->param_bindvalues('interpro_desc_fulltext');
  my ($go_annot)       = $this->param_bindvalues('go_desc_fulltext');
  my ($domain_annot)   = $this->param_bindvalues('domain_desc_fulltext');

  #boolean-ize these two flag values
  $scalars{annot_type} = $blast_annot    ? 'blast'   :
                         $manual_annot   ? 'manual'  :
                         $interpro_annot ? 'interpro':
                         $go_annot       ? 'go'      :
                         $domain_annot   ? 'domain'  :
			                   'blast';

  $scalars{annotation} =
    $blast_annot || $manual_annot || $interpro_annot || $go_annot || $domain_annot;
  $scalars{annotation} = from_tsquery_string($scalars{annotation});
  $scalars{has_marker} = $this->param_to_string('primer_matches_marker') ? 1 : undef;

  return %scalars;
}

=head2 quick_search

Specified in  L<CXGN::Search::WWWQueryI>.

=cut

sub quick_search {
  my( $this, $term ) = @_;

  return unless str_in(identifier_namespace($term),qw/sgn_u cgn_u/) || $term !~ /\D/;
  $term =~ s/\D//g;

  $this->sequence_name("=?",$term);
  return $this;
}


###################### END WEB STUFF

sub DESTROY {
  my $this = shift;
  our @ISA;
  return parricide($this,@ISA);
}

###
1;#do not remove
###
