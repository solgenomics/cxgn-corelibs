package CXGN::Genomic::Search::GSS::Query;
use strict;
use English;
use Carp;

use CXGN::Tools::Class qw/parricide/;

use CXGN::Genomic::QuerySourceType;

use base qw/CXGN::Search::DBI::Simple::Query/;

=head1 NAME

CXGN::Genomic::Search::Query - query for L<CXGN::Genomic::Search::GSS>.

=head1 BASE CLASS(ES)

L<CXGN::Search::Query::DBI::Simple>

=head1 SYNOPSIS

coming soon

=head1 SUBCLASSES

=over 4

=item none yet

=back

=head1 DESCRIPTION

Search query used with L<CXGN::Genomic::Search::GSS>.

=head1 NORMAL QUERY PARAMETERS (FUNCTIONS)

These are query parameters that act in the normal way defined by
L<CXGN::Search::QueryI>.

=head2 library_shortname

=cut

sub param_def {
  my $this = shift;

  our $dbname ||= 'genomic';

  ### use this 'origins' data structure to figure out what tables and fields
  ### are needed for each of the data structures
  my %origins =
    (
     (map {($_ => {type => 'simple', columns => ["$dbname.gss.$_"]})} CXGN::Genomic::GSS->columns),
     (map {($_ => {type => 'simple', columns => ["$dbname.clone.$_"]})} CXGN::Genomic::Clone->columns),

     library_shortname           => {type => 'simple', columns => ["$dbname.library.shortname"]}       ,
     library_id                  => {type => 'simple', columns => ["$dbname.clone.library_id"]}        ,
     trimmed_length              => {type => 'simple', columns => ["$dbname.qc_report.hqi_length"]}    ,
     length                      => { columns => ["$dbname.gss.seq"],
				      sqlexpr => "length($dbname.gss.seq)",
				    },
     clone_id                    => {type => 'simple', columns => ["$dbname.clone.clone_id"]}          ,
     primer                      => {type => 'simple', columns => ["$dbname.chromat.primer"]}          ,
     clone_name                  => { columns    => ["$dbname.library.shortname",
						     "$dbname.clone.platenum",
						     "$dbname.clone.wellrow",
						     "$dbname.clone.wellcol",
						    ],
				      type => 'simple',
				      sqlexpr    =>
				      CXGN::Genomic::Clone::clone_name_sql("$dbname.library.shortname",
									   "$dbname.clone.platenum",
									   "$dbname.clone.wellrow",
									   "$dbname.clone.wellcol",
									  ),
				    },
     blast_annot_db_id           => {type => 'simple', columns => ["$dbname.blast_query.blast_db_id"]},
     blast_annot_db_filename     => {type => 'simple', columns => ["$dbname.blast_db.file_basename"]},
     blast_annot_last_updated    => {type => 'simple', columns => ["$dbname.blast_query.last_updated"]},
     gss_submitted_to_genbank_id => {type => 'simple', columns => ["$dbname.gss_submitted_to_genbank.gss_submitted_to_genbank_id"]},
     genbank_date_sent           => {type => 'simple', columns => ["$dbname.genbank_submission.date_sent"]},
    );

  #aliases here
  $origins{arizona_clone_name} = $origins{clone_name};

  #closure to keep the above 'in the family'
  #if single arg, returns single origins entry
  #if mult arg, returns array of origins entry
  #if no arg, returns whole origins hash
    return $origins{+shift} if @_ == 1;
    return @origins{@_} if(@_);
    return \%origins;
}

=head1 SPECIAL QUERY PARAMETERS

=cut

#############################################
######### parameters accessors ##############
#############################################

=head2 flags_set

  Desc:
  Args:
  Ret :

=cut

sub flags_set {
  my $this = shift;
  $this->_generic_flags_query('flags',0,@_);
}

=head2 flags_not_set

  Desc:
  Args:
  Ret :

=cut

sub flags_not_set {
  my $this = shift;
  $this->_generic_flags_query('flags',1,@_);
}

=head2 status_set

  Desc:
  Args:
  Ret :

=cut

sub status_set {
  my $this = shift;
  $this->_generic_flags_query('status',0,@_);
}

=head2 status_not_set

  Desc:
  Args:
  Ret :

=cut

sub status_not_set {
  my $this = shift;
  $this->_generic_flags_query('status',1,@_);
}

sub _generic_flags_query {
  my ($this,$field,$not,@args) = @_;

  foreach (@args) {
    croak 'This particular parameter accessor is special, and takes only a string argument.  See the documentation'
      if ref $_;
  }

  my $mask_subroutine_call = "CXGN::Genomic::GSS::gen_${field}_mask(\@args)";

  my $mask = eval $mask_subroutine_call;
  die $EVAL_ERROR if $EVAL_ERROR;

  my $op = $not ? '=' : '!=';

  $this->$field("& $mask $op 0");
}

=head2 needs_genbank_submit

  Desc: SPECIAL CASE: restrict this query to find only GSS that
        need to be submitted to Genbank's dbGSS database
  Args: none
  Ret : 1

=cut

sub needs_genbank_submit {
  my $this = shift;

  $this->gss_submitted_to_genbank_id(' IS NULL');
}

=head2 needs_auto_annot

  Desc: SPECIAL CASE: will add conditions to the join ON clause
        to find GSS that need to be annotated against
        a certain blast database, based on the database name
        and the database's modification timestamp
  Args: database id and database modification unix timestamp
  Ret : supplied database ID, or the currently set database ID (if any)
        if no args given

=cut

sub needs_auto_annot {
  my $this = shift;

  if(@_) {
    ### check input ###
    my $bad = @_ != 2; #check that we have two args
    #check that each arg is true, is not a ref, and is a number
    $bad ||= !$_ || ref || $_ !~ /^\d+$/  foreach @_;
    croak 'needs_auto_annot takes two scalar numerical args' if $bad;

    my ($dbid,$db_mtime) = @_;
    $this->{auto_annot_db_id} = $dbid;
    $this->blast_annot_db_id("&t = $dbid OR &t IS NULL");
    $this->blast_annot_last_updated("EXTRACT(EPOCH FROM &t) < $db_mtime OR &t IS NULL");
  }
  $this->{auto_annot_db_id};
}

#################################################
########## SQL GENERATION STUFF #################
#################################################

=head2 joinstructure

  Desc:
  Args:
  Ret :

=cut

#some variables to make writing the structure easier
sub joinstructure {
  my $this = shift;
  my $bq_sourcetype = $this->_bq_sourcetype;

  our $dbname ||= 'genomic';

  my ($gss,$chr,$cln,$lib,$qcr,$bq,$bdb,$gsub,$sub) =
    map {"$dbname.$_"}
      qw/gss chromat clone library qc_report blast_query blast_db
         gss_submitted_to_genbank genbank_submission
        /;

  my %jstructure = ( root      => $gss,
		     joinpaths => [ [ [$chr, "$gss.chromat_id = $chr.chromat_id"],
				      [$cln, "$cln.clone_id=$chr.clone_id"],
				      [$lib, "$lib.library_id=$cln.library_id"],
				    ],
				    [ [$qcr, "$qcr.gss_id=$gss.gss_id"],
				    ],
				    [ [$gsub, "$gss.gss_id=$gsub.gss_id"],
				      [$sub, "$sub.genbank_submission_id=$gsub.genbank_submission_id"],
				    ],
				  ],
		   );
  if ( my $needs_annot_id = $this->{auto_annot_db_id} ) {
    push @{$jstructure{joinpaths}},  [ [$bq, join(' AND ', ("$gss.gss_id=$bq.source_id",
							    "$bq.query_source_type_id=$bq_sourcetype",
							    "$bq.blast_db_id=$needs_annot_id",
							   )
						  )
				       ],
				       [$bdb, "$bdb.blast_db_id=$bq.blast_db_id"],
				     ];
  }

  \%jstructure;
}

__PACKAGE__->selects_class_dbi('CXGN::Genomic::GSS');

{ #get and cache the blast query sourcetype for GSS annotations
  my $stcache;
  sub _bq_sourcetype {
    my $this = shift;
    $stcache ||=
      do {
	my ($type) = CXGN::Genomic::QuerySourceType->search(shortname => 'gss');
	ref($type)
	  or die "Cannot find query_source_type_id for shortname 'gss'.  Is there an entry for it in the query_source_type table?\n";
	$type->query_source_type_id;

      };
  }
}


=head1 OTHER METHODS

sub DESTROY {
  my $this = shift;
  return parricide($this,our @ISA);
}

=head1 AUTHOR(S)

    Robert Buels

=cut

###
1;#do not remove
###

