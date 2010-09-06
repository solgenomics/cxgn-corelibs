package CXGN::Genomic::Search::Clone::Query;
use strict;
use warnings;
use Carp;

use Tie::Function;
our %urlencode;
use Tie::UrlEncoder;

use CXGN::DB::Physical;
use CXGN::People::Project;

use CXGN::Tools::Class qw/parricide/;
use CXGN::Tools::Text qw/to_tsquery_string from_tsquery_string/;
use CXGN::Tools::Identifiers qw/identifier_namespace clean_identifier/;

use CXGN::Page::FormattingHelpers qw/simple_selectbox_html
                                     html_optional_show
                                     info_table_html
				     hierarchical_selectboxes_html
                                     numerical_range_input_html
				     commify_number
				     /;

use CXGN::Genomic::QuerySourceType;

use base qw/ CXGN::Search::DBI::Simple::WWWQuery/;

=head1 NAME

CXGN::Genomic::Search::Query - query for L<CXGN::Genomic::Search::Clone>.

=head1 BASE CLASS(ES)

L<CXGN::Search::Query::DBI::Simple>

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

=over 4

=item none yet

=back

=head1 DESCRIPTION

Search query used with L<CXGN::Genomic::Search::Clone>.

=head1 NORMAL QUERY PARAMETERS (FUNCTIONS)

These are query parameters that act in the normal way defined by
L<CXGN::Search::QueryI>.

TODO: list all the parameters this search can use

=cut

sub param_def {
  my $this = shift;
  my ($genomic, $sgn, $physical, $sgn_people, $annotation,$metadata,$phenome) =
      qw/genomic sgn physical sgn_people annotation metadata phenome/;

  ### use this 'origins' data structure to figure out what tables and fields 
  ### are needed for each of the data structures
  # param name         => [table name , field name]
  my %origins =
    (
     #get all the columns from the clone table
     #making their parameter names just their column names
     (map {$_ => { type => 'simple', columns => ["$genomic.clone.$_"]}} CXGN::Genomic::Clone->columns),
     library_shortname            => { type => 'simple',
				       columns => ["$genomic.library.shortname"],
				     },

     #add some derived values and columns from other tables
     organism                     => { type => 'simple',
				       columns => ["$sgn.organism.organism_name"],
				     },
     accession_common_name        => { type => 'simple',
				       columns => ["$sgn.accession.common_name"],
				     },

#      blast_defline                 => { columns => ["$dbname.blast_defline.defline"],
# 					sqlexpr => "$dbname.blast_defline.defline",
# 					group   => 1,
# 				      },
#      blast_identifier              => { columns => ["$dbname.blast_defline.identifier"],
# 					sqlexpr => "$dbname.blast_defline.identifier",
# 					group   => 1,
# 				      },
     #meant to be used internally by annotation_text() special query param below
     _blast_defline_fulltext      => { columns => ["$genomic.blast_defline.indentifier_defline_fulltext",
						  ],
				       sqlexpr => "$genomic.blast_defline.identifier_defline_fulltext",
				       group => 1,
				       type => 'simple',
				     },
     # a grouped field must be exclusive.  and its filter is applied in a having clause
     read_ids                     => { columns => ["$genomic.chromat.chromat_id"] ,
				       sqlexpr => "$genomic.chromat.chromat_id",
				       group   => 1,
				       type => 'simple',
				     },
     num_reads                    => { columns => ["$genomic.chromat.chromat_id"] ,
				       sqlexpr => "count(distinct $genomic.chromat.chromat_id)",
				       group   => 1,
				       aggregate => 1,
				       type => 'simple',
				     },
     plausible_overgos           => { columns => ["$physical.oa_plausibility.plausible",
						 ],
				      sqlexpr => "$physical.oa_plausibility.plausible",
				      group   => 1,
				      type => 'simple',
				    },
     computational_marker_id     => { columns => ["$physical.computational_associations.marker_id",
						 ],
				      sqlexpr => "$physical.computational_associations.marker_id",
				      group   => 1,
				      type => 'simple',
				    },
     manual_marker_id            => { columns => ["$physical.manual_associations.marker_id",
						 ],
				      sqlexpr => "$physical.manual_associations.marker_id",
				      group   => 1,
				      type => 'simple',
				    },
     linkage_group_name         => { columns  => ["$sgn.linkage_group.lg_name"],
				     sqlexpr => "$sgn.linkage_group.lg_name",
				     group   => 1,
				     type => 'simple',
				    },
     mapping_offset_cms          => { columns => ["$sgn.marker_location.position"],
				      sqlexpr => "$sgn.marker_location.position",
				      group   => 1,
				      type => 'simple',
				    },
     map_id                     =>  { columns => ["$sgn.map_version.map_id"],
				      sqlexpr => "$sgn.map_version.map_id",
				      group   => 1,
				      type => 'simple',
				    },
     bac_status_log_id           => { type => 'simple', columns => ["$sgn_people.bac_status_log.status"]},
     sequencing_status           => { type => 'simple', columns => ["$sgn_people.bac_status.status"]},
     sequencing_gb_status        => { type => 'simple', columns => ["$sgn_people.bac_status.genbank_status"]},

     clone_id                    => { type => 'simple', columns => ["$genomic.clone.clone_id"]},
     clone_name                  => { columns => ["$genomic.library.shortname",
						  "$genomic.clone.platenum",
						  "$genomic.clone.wellrow",
						  "$genomic.clone.wellcol",
						 ],
				      sqlexpr    =>
				      CXGN::Genomic::Clone::clone_name_sql("$genomic.library.shortname",
									   "$genomic.clone.platenum",
									   "$genomic.clone.wellrow",
									   "$genomic.clone.wellcol",
									  ),
				    },
     seq_project_id              => { columns  => ["$metadata.attribution_to.project_id"],
				      sqlexpr  => "$metadata.attribution_to.project_id",
				      group    => 1, #bacs might be in mult projects
				      type => 'simple',
				    },
     seq_project_name            => { columns  => ["$sgn_people.sp_project.name"],
				      sqlexpr  => "$sgn_people.sp_project.name",
				      group    => 1,
				      type     => 'simple',
				    },
     sequence_name               => { columns  => ["public.feature.name"],
				      sqlexpr  => "public.feature.name",
				      group    => 1, #bacs might have mult fragment
				      type => 'simple',
				    },
     fish_result_id              => { columns  => ["$sgn.fish_result.fish_result_id"],
				      sqlexpr  => "$sgn.fish_result.fish_result_id",
				      group    => 1, #bacs might have mult fish results
				      type => 'simple',
				    },
     genbank_accession           => { columns  => ["public.dbxref.accession"],
				      sqlexpr  => "public.dbxref.accession",
				      group    => 1,
				      type => 'simple',
				    },
     dbxref_db_name              => { columns  => ['public.db.name'],
				      sqlexpr  => 'public.db.name',
				      type => 'simple',
				      group    => 1,
				    },

     il_project_id               => { columns  => ["$sgn_people.sp_project_il_mapping_clone_log.sp_project_id"],
				      type => 'simple',
				      sqlexpr  => "$sgn_people.sp_project_il_mapping_clone_log.sp_project_id",
				      group    => 1,
				    },
     il_chr_num                  => { columns  => ["$sgn_people.clone_il_mapping_bin_log.chromosome"],
				      type => 'simple',
				      sqlexpr  => "$sgn_people.clone_il_mapping_bin_log.chromosome",
				      group    => 1,
				    },
     il_bin_name                 => { columns  => ["$phenome.genotype_region.name"],
				      sqlexpr  => "$phenome.genotype_region.name",
				      type => 'simple',
				      group    => 1,
				    },
     il_bin_map_short_name       => { columns  => ["$sgn.map.short_name"],
				      sqlexpr  => "$sgn.map.short_name",
				      group    => 1,
				      type => 'simple',
				    },
     ver_int_read                => { columns  => ["$sgn_people.clone_verification_log.ver_int_read"],
				      sqlexpr  => "$sgn_people.clone_verification_log.ver_int_read",
				      type => 'simple',
				    },
     ver_bac_end                => { columns  => ["$sgn_people.clone_verification_log.ver_bac_end"],
				      type => 'simple',
				      sqlexpr  => "$sgn_people.clone_verification_log.ver_bac_end",
				    },
    );

  #put aliases here
  $origins{arizona_clone_name} = $origins{clone_name};

  #if single arg, returns single origins entry
  #if mult arg, returns array of origins entry
  #if no arg, returns whole origins hash
    return $origins{+shift} if(@_ == 1);
    return @origins{@_} if(@_);
    return \%origins;
}

=head1 SPECIAL QUERY PARAMETERS

=head2 annotation_fulltext

  Desc: full-text search of this clone's blast annotation identifiers
        and deflines.  Uses MySQL-specific full-text indexing and searching
        functions.  Will need to be changed when we migrate to Postgres.
  Args: text string to search for
  Ret : not specified

=cut

sub annotation_fulltext {
  my $this = shift;
  my $searchstring = shift
    or croak "Must specify a search string for annotation_fulltext";

  $searchstring = to_tsquery_string($searchstring);

  $this->_blast_defline_fulltext(" @@ to_tsquery(?)",$searchstring);
}


#################################################
########## SQL GENERATION STUFF #################
#################################################

__PACKAGE__->selects_class_dbi('CXGN::Genomic::Clone');

=head2 joinstructure

  See joinstructure documentation in L<CXGN::Search::QueryI>.

=cut

sub joinstructure {
  my $this = shift;

  #make some vars to hold long-form table names so we don't have to
  #write them all out ourselves
  my ($dbname, $sgn, $physical, $sgn_people, $annotation,$metadata,$phenome) =
      qw/genomic sgn physical sgn_people annotation metadata phenome/;
  my ($gss,$chr,$cln,$lib,$qcr,$bq,$bdb,$bh,$bd,$gsub,$sub) =
    map {"$dbname.$_"} 
      qw/gss chromat clone library qc_report blast_query blast_db blast_hit blast_defline
         gss_submitted_to_genbank genbank_submission
        /;
  my $bacstats = "$sgn_people.bac_status";
  #physical databases
  my ($passocs,$pplaus,$ppmarkers,$povgp,$pcompassocs,$pmanassocs) = map {"$physical.$_"} qw/overgo_associations oa_plausibility probe_markers overgo_plates computational_associations manual_associations/;
  #sgn databases
  my ($smarker,$smexp,$smloc,$smapver,$slgroup) = map {"$sgn.$_"} qw/marker marker_experiment marker_location map_version linkage_group/;
  #metadata databases
  my ($m_att,$m_att_to) = map {"$metadata.$_"} qw/attribution attribution_to/;

  #need to look up the proper blast query source type id for GSS blast annotations
  my $blast_query_sourcetype = $this->_bq_sourcetype;

  #cache these from query to query
  our $overgo_version ||= CXGN::DB::Physical::get_current_overgo_version(our $physical_dbconn ||= CXGN::DB::Connection->new);
  our $overgo_map_id ||= CXGN::DB::Physical::get_current_map_id();


  my %jstructure = ( root      => $cln,
		     joinpaths => [ [ [$lib, "$cln.library_id = $lib.library_id"],
				    ],
				    [ [$chr, "$cln.clone_id = $chr.clone_id"],
				      [$gss, "$chr.chromat_id = $gss.chromat_id"],
				      [$qcr, "$qcr.gss_id=$gss.gss_id"],
				    ],
				    [ [$chr, "$cln.clone_id = $chr.clone_id"],
				      [$gss, "$chr.chromat_id = $gss.chromat_id"],
				      [$gsub, "$gss.gss_id=$gsub.gss_id"],
				      [$sub, " $sub.genbank_submission_id=$gsub.genbank_submission_id"],
				    ],
				    [ [$bacstats, "$cln.clone_id=$bacstats.bac_id"],
				    ],
				    [ [$passocs,   "$cln.clone_id=$passocs.bac_id AND $passocs.overgo_version=$overgo_version" ],
				      [$pplaus,    "$pplaus.overgo_assoc_id=$passocs.overgo_assoc_id AND $pplaus.map_id=$overgo_map_id"],
				      [$ppmarkers, "$passocs.overgo_probe_id=$ppmarkers.overgo_probe_id"],
				      [$smarker,   "$smarker.marker_id=$ppmarkers.marker_id"],
				      [$smexp,     "$smexp.marker_id=$smarker.marker_id"],
				      [$smloc,     "$smloc.location_id=$smexp.location_id"],
				      [$slgroup,   "$slgroup.lg_id=$smloc.lg_id"],
				      [$smapver,   "$smapver.map_version_id=$slgroup.map_version_id AND $smapver.current_version = true"],
				    ],
				    [ [$pcompassocs, "$cln.clone_id=$pcompassocs.clone_id"],
				    ],
				    [ [$pmanassocs,  "$cln.clone_id=$pmanassocs.clone_id"],
				    ],
				    [ [$chr, "$cln.clone_id = $chr.clone_id"],
				      [$gss, "$chr.chromat_id = $gss.chromat_id"],
				      [$bq,  "$bq.source_id=$gss.gss_id AND $bq.query_source_type_id=$blast_query_sourcetype"],
				      [$bh,  "$bq.blast_query_id=$bh.blast_query_id" ],
				      [$bd,  "$bh.blast_defline_id=$bd.blast_defline_id"],
 				    ],
				    [ [$lib, "$cln.library_id = $lib.library_id"],
				      [$m_att, "$m_att.row_id = $cln.clone_id"],
				      [$m_att_to, "$m_att_to.attribution_id = $m_att.attribution_id"],
				      ['sgn_people.sp_project', "$m_att_to.project_id = sgn_people.sp_project.sp_project_id"],
				    ],
				    [ ['genomic.clone_feature', "genomic.clone_feature.clone_id=$cln.clone_id"],
				      ['public.feature','public.feature.feature_id=genomic.clone_feature.feature_id'],
				    ],
				    [ ['genomic.clone_feature', "genomic.clone_feature.clone_id=$cln.clone_id"],
				      ['public.feature_dbxref','public.feature_dbxref.feature_id=genomic.clone_feature.feature_id'],
				      ['public.dbxref','public.dbxref.dbxref_id=public.feature_dbxref.dbxref_id'],
				      ['public.db','public.dbxref.db_id=public.db.db_id'],
				    ],
				    [ ["$sgn.fish_result", "$sgn.fish_result.clone_id=$cln.clone_id"],
				    ],
				    [ ["$sgn_people.sp_project_il_mapping_clone_log","$sgn_people.sp_project_il_mapping_clone_log.clone_id = $cln.clone_id and $sgn_people.sp_project_il_mapping_clone_log.is_current = true"],
				    ],
				    [ ["$sgn_people.clone_il_mapping_bin_log","$sgn_people.clone_il_mapping_bin_log.clone_id = $cln.clone_id and $sgn_people.clone_il_mapping_bin_log.is_current = true"],
				      ["$phenome.genotype_region","$sgn_people.clone_il_mapping_bin_log.genotype_region_id = $phenome.genotype_region.genotype_region_id and $phenome.genotype_region.type='bin'"],
				      ["$sgn.linkage_group as lg2","lg2.lg_id = $phenome.genotype_region.lg_id"],
				      ["$sgn.map_version as mv2","lg2.map_version_id=mv2.map_version_id"],
				      ["$sgn.map as m2","mv2.map_id=m2.map_id"],
				    ],
				    [ ["$sgn_people.clone_verification_log","$sgn_people.clone_verification_log.clone_id = $cln.clone_id and $sgn_people.clone_verification_log.is_current = true"],
				    ],
				  ],
		   );

  return \%jstructure;
}

#get and cache the blast query sourcetype for GSS annotations
sub _bq_sourcetype {
  my $this = shift;
  return our $stcache ||=
    do {
      my ($type) = CXGN::Genomic::QuerySourceType->search(shortname => 'gss');
      ref($type)
	or die "Cannot find query_source_type_id for shortname 'gss'.  Is there an entry for it in the query_source_type table?\n";
      $type->query_source_type_id;

    };
}

=head2 quick_search

Specified in L<CXGN::Search::WWWQueryI>.

Searches for clones with names ILIKE '%'.$term.'%' .

=cut

sub quick_search {
  my ($this, $search_string) = @_;

  #don't quick-search for things that are too vague
  return unless $search_string =~ /\d/ && $search_string =~ /\w/;

  $this->clone_name('ILIKE ?','%'.$search_string.'%');
  return $this;
}

=head2 to_html

Specified in L<CXGN::Page::WebFormI>.

=cut

sub to_html {
  my $this = shift;

  $this->make_pname;
  our %pname;

  #use Tie::Function so I can use hash syntax to call this function,
  #thereby letting me interpolate function calls into strings.
  tie my %webvalue, 'Tie::Function', sub { $this->data(@_) };

  my %scalars = $this->_to_scalars;

  my $seqstatus_html = simple_selectbox_html(name     => $pname{seqstatus},
 					     selected => $scalars{seqstatus},
					     choices  => [
							  ['','-'],
							  ['in_progress','in progress'],
							  'complete',
							 ],
					    );

  my $chromonum_input = simple_selectbox_html( name   => $pname{chromonum},
					       selected => $scalars{chromonum},
					       choices => [ ['','-'], 'unmapped', 1..12 ],
					     );

  #change check boxes to checked html text if they're true
  my @checkboxes = qw/has_bad_clone has_endseq has_overgo has_comp_markers has_manual_markers has_gbrowse has_fish ver_int_read ver_bac_end/;
  @scalars{@checkboxes} =  map {$_ ? 'checked="checked" ' : ''} @scalars{@checkboxes};


  my @maplist;
  my %all_lgs;
  my %lgchoices;
  my $lastmap = 0;
  my $sgn = 'sgn';
  foreach my $row (@{CXGN::Genomic::Clone->db_Main->selectall_arrayref(<<EOSQL)}) {
SELECT m.map_id, m.short_name, lg.lg_name
FROM $sgn.map m
JOIN $sgn.map_version mv
  USING(map_id)
JOIN $sgn.linkage_group lg
  USING(map_version_id)
WHERE mv.current_version = true
ORDER BY m.short_name,lg.lg_order
EOSQL

    my ($mapid,$mapname,$lg) = @$row;
    push @maplist,[$mapid,$mapname] if $lastmap != $mapid;
    $lgchoices{$mapid} ||= [''];
    push @{$lgchoices{$mapid}},$lg;
    $all_lgs{$lg} = 1;
    $lastmap = $mapid;
  }

  my ($mapselect,$lgselect,$map_lg_javascript) =
    hierarchical_selectboxes_html( childsel =>  { name     => $pname{linkage_group_name},
						  selected => $scalars{linkage_group_name},
#						  choices  => ['',@linkage_groups],
						},
				   parentsel => { name     => $pname{map_id},
						  selected => $scalars{map_id},
						  choices  => [ ['','-'],
							        @maplist,
							      ],
						},
				   childchoices => [ ['', sort {my ($an,$bn) = map{/(\d+)/} ($a,$b);
                                                                no warnings 'uninitialized';
								$an <=> $bn || $a cmp $b
							      } keys %all_lgs
						     ],
						     @lgchoices{map {$_->[0]} @maplist},
						   ],
				 );

  my $estlen_input = numerical_range_input_html( compare => [$pname{estlenrange}, $scalars{estlenrange} ],
						 value1  => [$pname{estlen1},     commify_number($scalars{estlen1}) ],
						 value2  => [$pname{estlen2},     commify_number($scalars{estlen2}) ],
						 units   => 'bp',
					       );
  my $map_offset_input = numerical_range_input_html( compare => [$pname{offsetrange}, $scalars{offsetrange} ],
						     value1  => [$pname{offset1},     commify_number($scalars{offset1}) ],
						     value2  => [$pname{offset2},     commify_number($scalars{offset2}) ],
						     units   => 'cM',
						   );



  #scalar used as a boolean to tell whether or not the advanced
  #search should be shown by default.  we want it to be shown
  #if any of these parameters are set
  my $show_advanced_search =
    grep {defined($_) && $_} @scalars{qw( estlen1 has_bad_clone
					  has_endseq has_overgo has_comp_markers has_manual_markers
                                          has_gbrowse has_fish
					  seqstatus linkage_group_name
					  offset1 map_id full_annotation end_annotation
					  chromonum
					  genbank_accession
					  ver_bac_end
					  ver_int_read
					  il_bin_name
					  il_project_id
					  il_chr_num
					)};
  #avoid warnings
  $scalars{$_} ||= '' foreach qw/id full_annotation end_annotation/;

  my $advanced_search =
    html_optional_show('advanced_search',
		       'More criteria',
		       qq|<div class="minorbox">\n|
		       .qq|<table width="100%"><tr><td>|
		       .info_table_html(
					'Seq. center reported status' => $seqstatus_html,
					'Estimated length' => $estlen_input,
					'GenBank accession (version insensitive)' =>
					qq|<input type="text" name="$pname{genbank_accession}" value="$webvalue{genbank_accession}" size="15" />|
					.qq| <span class="ghosted">e.g. AP009318.1 or AP009318</span>|,
					__border => 0,
				       )
		       .qq|</td><td>|
		       .info_table_html(
					'Sequencing on Chromosome' => $chromonum_input,
					'Show only clones with' => <<EOH,
      <input type="checkbox" id="has_bad_clone_check" name="$pname{has_bad_clone}" $scalars{has_bad_clone} /><label for="has_bad_clone_check">known contamination</label><br />
      <input type="checkbox" id="has_endseq_check" name="$pname{has_endseq}" $scalars{has_endseq} /><label for="has_bad_clone_check">end sequence(s)</label> <br />
      <input type="checkbox" id="has_overgo_check" name="$pname{has_overgo}" $scalars{has_overgo} /><label for="has_overgo_check">overgo probe matches to markers</label> <br />
      <input type="checkbox" id="has_comp_markers_check" name="$pname{has_comp_markers}" $scalars{has_comp_markers} /><label for="has_comp_markers_check">computational matches to markers</label> <br />
      <input type="checkbox" id="has_manual_markers_check" name="$pname{has_manual_markers}" $scalars{has_manual_markers} /><label for="has_manual_markers_check">manual matches to markers</label> <br />
      <input type="checkbox" id="has_gbrowse_check" name="$pname{has_gbrowse}" $scalars{has_gbrowse} /><label for="has_gbrowse_check">full sequence available</label> <br />
      <input type="checkbox" id="has_fish_check" name="$pname{has_fish}" $scalars{has_fish} /><label for="has_fish_check">FISH results available</label><br />
EOH
#currently disabled because of instability - searches for terms that match 
#a lot of things can take basically forever
					__border     => 0,
				       )
		       .qq|</td></tr></table>|
		       .info_table_html(
				       'Annotations' =>
					info_table_html(
# 							'Full Sequence (via Gbrowse)' =>
# 							 qq|<input name="$pname{full_annotation}" value="$scalars{full_annotation}" size="30" /><br /><span class="ghosted">e.g.'E231589'</span>|,
							 'End Sequences' =>
							 qq|<input type="text" name="$pname{end_annotation}" value="$scalars{end_annotation}" size="30" /><br /><span class="ghosted">e.g. crystallin</span>|,
							 __border     => 0,
							 __sub        => 1,
							 __multicol   => 2,
							 __tableattrs => 'width="100%"',
						       ),
					'Overgo match to marker <a class="context_help" href="/maps/physical/overgo_process_explained.pl">what\'s this?</a>' =>
					info_table_html ('Map' => $mapselect,
							 'Chromosome / Linkage&nbsp;Group' => $lgselect,
							 'Map position' => $map_offset_input,
							 __border       => 0,
							 __sub          => 1,
							 __multicol     => 2,
							 __tableattrs   => 'width="100%"',
							),
					__border     => 0,
					__tableattrs => 'width="100%"',
				       )
		       .info_table_html(
					'IL Bin Mapping' =>
					info_table_html( 'Assigned to project' => simple_selectbox_html( choices => [['','-'],@{CXGN::People::Project->distinct_country_projects(CXGN::Genomic::Clone->db_Main)}],
													 selected => $scalars{il_project_id},
													 name => $pname{il_project_id},
												       ),
							 'Mapped to bin' => simple_selectbox_html( choices =>
												   [['','-'],['any','any'],
												    @{CXGN::Genomic::Clone->db_Main->selectcol_arrayref("select distinct name from phenome.genotype_region where type='bin'")}],
												   selected => $scalars{il_bin_name},
												   name => $pname{il_bin_name},
												 ),
							 'Mapped to chr' => simple_selectbox_html( choices =>
												   [['','-'],['any','any'],
												    1..12
												   ],
												   selected => $scalars{il_chr_num},
												   name => $pname{il_chr_num},
												 ),
							 __border     => 0,
							 __multicol   => 2,
							 __sub        => 1,
						       ),
					'Verification' => qq|<input type="checkbox" id="ver_int_read_check" name="$pname{ver_int_read}" $scalars{ver_int_read} /><label for="ver_int_read_check">verified with internal read resequencing</label><br /><input type="checkbox" id="ver_bac_end_check" name="$pname{ver_bac_end}" $scalars{ver_bac_end} /><label for="ver_bac_end_check">verified by bac end resequencing</label>|,
					__border     => 0,
					__multicol   => 2,
					__tableattrs => 'width="100%"',
				       )
		       ."</div>\n"
		       ,$show_advanced_search);
  my $rethtml = <<EOHTML;
     <input type="hidden" name="$pname{page}" value="0" />
     <div align="center" style="margin-bottom: 2em">
       <label style="font-weight: bold" for="bacsearchnameinput">Name contains</label> <span style="position: relative"><span style="position: absolute; left: 0.2em; top: 2em; font-size: 80%; white-space: nowrap; text-align: left; color: gray; width: 300px">full names, partial names, or lists of both</span><input id="bacsearchnameinput" type="text" size="50" name="$pname{id}" value="$webvalue{id}" /><input type="submit" value="Search" />
</span>
     </div>
       $advanced_search
<script language="JavaScript" type="text/javascript">
<!--
$map_lg_javascript
-->
</script>
EOHTML
  return $rethtml;
}


=head2 request_to_params

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

sub request_to_params {

  my ($this) = shift;
  my %request = @_;

  #whitespace-trim all the parameters
  foreach my $key (keys %request) {
    if( $request{$key} ) {
      $request{$key} = CXGN::Tools::Text::trim($request{$key});
    }
  }

  #clone_id
  if( $request{clone_id} ) {
    $this->clone_id('=?',$request{clone_id});
  } elsif( $request{id} ) {
    $this->debug(1);
    my @ids = split /[\s,]+/,$request{id};
    my @exact_ids;
    my @likes;
    foreach my $id (@ids) {
      if( my $clone = CXGN::Genomic::Clone->retrieve_from_clone_name($id) ) {
	push @exact_ids,$clone->clone_id;
      } else {
	$id =~ s/^\s*P(\d)/LE_HBa$1/;
	#if people enter an ID with too few plate digits, add a leading zero
	$id =~ s/^\s*([^\d]+)(\d{1,3}[A-Za-z]\d+)/${1}0$2/;
	push @likes,$id;
      }
    }
    if(@exact_ids) {
      $this->clone_id('IN('.join(',',map '?',@exact_ids).')',@exact_ids);
    }
    if(@likes) {
      my @like_binds = map "%$_%",@likes;
      $this->clone_name(join(' OR ',map '&t ILIKE ?',@likes),@like_binds);
    }
    if(@exact_ids && @likes) {
      $this->compound('&t OR &t','clone_id','clone_name');
    }
  }

  #genbank accession
  if( $request{genbank_accession} ) {
    my $gbacc = $request{genbank_accession};
    $gbacc =~ s/\.\d+$//; #< cut off any version
    $this->genbank_accession('~ ?',$gbacc.'\.\d+');
    $this->dbxref_db_name('=?','DB:GenBank_Accession');
  }

  #sequencing status
  if( $request{seqstatus} ) {
    $this->sequencing_status("= ?",$request{seqstatus});
  }

  #estimated length
  if($request{estlen1} ) {
    $this->ranged_parameter_from_scalars('estimated_length',
					 @request{ qw/estlenrange estlen1 estlen2/ }
					);
  }

  #contamination check box
  if( $request{has_bad_clone} ) {
    $this->bad_clone('!= 0');
  }

  #end sequences check box
  if( $request{has_endseq} ) {
    $this->read_ids('!= 0');
  }

  #overgo check box
  if( $request{has_overgo} ) {
    $this->plausible_overgos('>0');
  }

  #computational markers check box
  if( $request{has_comp_markers} ) {
    $this->computational_marker_id('>0');
  }

  #manual markesr check box
  if( $request{has_manual_markers} ) {
    $this->manual_marker_id('>0');
  }

  #structural annotation check box
  if( $request{has_gbrowse} ) {
    $this->sequence_name('IS NOT NULL');
  }

  #FISH results check box
  if( $request{has_fish} ) {
    $this->fish_result_id('IS NOT NULL');
  }

  #ver_int_read check box
  if( $request{ver_int_read} ) {
    $this->ver_int_read('= true');
  }

  #ver_bac_end check box
  if( $request{ver_bac_end} ) {
    $this->ver_bac_end('= true');
  }

  #chromosome assignment
  if( $request{chromonum} ) {
    if( $request{chromonum} eq 'unmapped' ) {
      $this->seq_project_name("ilike 'Tomato ' || ? || ' Clones Sequencing Project'",'unmapped'); #< it's nice to put 'unmapped' in the bindval, makes other code simpler
    } else {
      $request{chromonum} += 0; 
      $this->seq_project_name("ilike '%Tomato Chromosome ' || ? || ' %'",$request{chromonum});
    }
  }

  #page number
  if( defined($request{page}) ) {
    $this->page($request{page});
  }

  #page size
  if( defined($request{page_size}) ) {
    $this->page_size($request{page_size});
  }

  #overgo probes - maps, markers, mapping offsets
  if($request{map_id} ){
    $this->map_id(" = ?",$request{map_id});
  }
  if($request{linkage_group_name} ) {
    $this->linkage_group_name(" = ?",$request{linkage_group_name});
  }
  if($request{offset1} ) {
    $this->ranged_parameter_from_scalars('mapping_offset_cms',
					  @request{ qw/offsetrange offset1 offset2 / }
					 );
  }

  #blast defline
  if($request{end_annotation}) {
    $this->annotation_fulltext($request{end_annotation});
  }

  #gbrowse annotations
  if( defined($request{full_annotation}) ) {
    $this->annotated_with_name($request{full_annotation});
  }

  #il_project_id
  if( $request{il_project_id} ) {
    $this->il_project_id('= ?',$request{il_project_id});
  }

  #il_chr_num
  if( $request{il_chr_num} ) {
    if( $request{il_chr_num} eq 'any' ) {
      $this->il_bin_name('is not null');
      $this->il_chr_num('is not null');
    } else {
      $this->il_chr_num('= ?',$request{il_chr_num});
      $request{il_bin_name} = $request{il_chr_num}.'-';
    }
    $this->compound('&t or &t','il_chr_num','il_bin_name');
  }
  if( $request{il_bin_name} ) {
    if( $request{il_bin_name} eq 'any' ) {
      $this->il_bin_name('is not null');
    } else {
      $this->il_bin_name("like (? || '%')",$request{il_bin_name});
    }
  }

  #use all inner joins, because we can with the features we use in the web search
  #$this->natural_joins(1);

  1;
}

=head2 _to_scalars

Specified in L<CXGN::Search::DBI::Simple::WWWQuery>.

=cut

sub _to_scalars {

  my ($this) = @_;
  my %scalars;

  $scalars{id} = ( join( ' ',
			 (map {warn "clone_id is $_\n"; CXGN::Genomic::Clone->retrieve($_)->clone_name} $this->param_bindvalues('clone_id')),
			 (map {s/%//g; $_} $this->param_bindvalues('clone_name'))
		       )
		 );
    
  $scalars{seqstatus} =
    do {
      my ($statstring) = $this->param_bindvalues('sequencing_status');

      #now return this value
      !defined($statstring)         ? undef :
       $statstring =~ /in.progress/ ? 'in_progress' :
       $statstring =~ /complete/    ? 'complete'    :
	                               undef; #default
    };

  $scalars{has_bad_clone} = $this->pattern_match_parameter('bad_clone', qr/!=\s*0/);
  $scalars{has_endseq} = $this->pattern_match_parameter('read_ids', qr/!=\s*0/);
  $scalars{has_overgo} = $this->pattern_match_parameter('plausible_overgos',qr/>\s*0/);
  $scalars{has_comp_markers} = $this->pattern_match_parameter('computational_marker_id',qr/>\s*0/);
  $scalars{has_manual_markers} = $this->pattern_match_parameter('manual_marker_id',qr/>\s*0/);
  $scalars{has_gbrowse} = $this->pattern_match_parameter('sequence_name', qr/IS NOT NULL/);
  $scalars{has_fish} = $this->pattern_match_parameter('fish_result_id', qr/IS NOT NULL/);
  $scalars{ver_int_read} = $this->pattern_match_parameter('ver_int_read', qr/true/);
  $scalars{ver_bac_end} = $this->pattern_match_parameter('ver_bac_end', qr/true/);

  ($scalars{genbank_accession}) = $this->param_bindvalues('genbank_accession');
  $scalars{genbank_accession} =~ s/\\\.\\d\+$// if defined $scalars{genbank_accession};

  ($scalars{chromonum}) = $this->param_bindvalues('seq_project_name');

  $scalars{page} = $this->page;
  $scalars{page_size} = $this->page_size if $this->page_size_isset;

  @scalars{qw/estlenrange estlen1 estlen2/} = $this->ranged_parameter_to_scalars('estimated_length');

  ($scalars{linkage_group_name}) = $this->param_bindvalues('linkage_group_name');#, qr/'([^']+)'/);

  @scalars{qw/offsetrange offset1 offset2/} = $this->ranged_parameter_to_scalars('mapping_offset_cms');

  ($scalars{map_id}) = $this->param_bindvalues('map_id');

  ($scalars{end_annotation}) = $this->param_bindvalues('_blast_defline_fulltext');
  $scalars{end_annotation} = from_tsquery_string($scalars{end_annotation});
  ($scalars{full_annotation}) = $this->param_bindvalues('_annotated_with_name');
  $scalars{full_annotation} =~ s/%//g if $scalars{full_annotation};

  #il_project_id
  ($scalars{il_project_id}) = $this->param_bindvalues('il_project_id');

  #il_chr_num
  ($scalars{il_chr_num}) = $this->param_bindvalues('il_chr_num');
  $scalars{il_chr_num} = 'any' if $this->pattern_match_parameter('il_chr_num',qr/not null/i);

  #il_bin_name
  ($scalars{il_bin_name}) = $this->param_bindvalues('il_bin_name');
  $scalars{il_bin_name} = 'any' if ( $this->pattern_match_parameter('il_bin_name',qr/not null/i) && ! $scalars{il_chr_num} );

  return %scalars;
}

=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###

