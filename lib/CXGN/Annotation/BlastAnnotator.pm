package CXGN::Annotation::BlastAnnotator;
use strict;
use warnings;
use Carp;
use English;
use POSIX;

use Bio::SearchIO;
use Bio::SearchIO::FastHitEventBuilder;

use CXGN::Genomic::BlastQuery;
use CXGN::Genomic::BlastDefline;
use CXGN::Genomic::QuerySourceType;

########## CONFIGURATION VARS ###############

#maximum number of hits to store in the database
#for a single BLAST query
my $max_stored_hits = 30;

#############################################

use Class::MethodMaker
  [ new    => [qw/-init new/],
    scalar => [ +{-type=>'CXGN::Genomic::QuerySourceType'}, '_source_type',
	      ],
  ];

use constant DEBUG => 0;
sub dbp(@) {
  if(DEBUG) {
    $|=1;
    print @_;
  }
  1;
}

=head2 new

  Desc: creates a new BlastAnnotator object. calls the init method,
        passes all of its arguments to the init method
  Args: none
  Ret :

  Implemented with Class::MethodMaker.

=head2 init

  Desc: does nothing right now.  Can add things here to initialize
        this object's state.
  Args: none
  Ret :

=cut

sub init {
} #init does nothing right now

=head2 db

  Desc: get/set the CXGN::DB::Connection used by this object
  Args: optionally, the new CXGN::DB::Connection to use here
  Ret : the currently set CXGN::DB::Connection

  This method is implemented with Class::MethodMaker.

=head2 source_type_shortname

  Desc: get/set the shortname of the type of things we
        are annotating.
  Args: none
  Ret : the current/new

=cut

sub source_type_shortname {
  my ($this,$new_st) = @_;

  if( $new_st ) {
    my ($st) = CXGN::Genomic::QuerySourceType->search( shortname => $new_st )
      or croak "source type '$new_st' not found in database";
    $this->_source_type($st);
  }

  return $this->_source_type ? $this->_source_type->shortname : undef;
}

# =head2 add_source_type

#   Desc:
#   Args:
#   Ret :

# =cut

# sub add_source_type {
#   my ($this,$name,$shortname) = @_;

#   ### check that the source type doesn't already exist ###
#   ###    if similar types found, print them out ###

#   ### add the source type and return its source_type_id ###
# }

=head2 record_hits

  Desc: Record SearchIO (Blast) hits efficiently in a Blast Annotation database
        for later reference
  Args: BlastDB object, SearchIO parser handle, (optional) subroutine reference
        for blast hit callback (see below), (optional) subroutine reference for
        blast query callback
  Ret : nothing meaningful

  If a subroutine reference is provided as a hit callback or a query callback,
  as the last argument, it will be called with two arguments: the BioPerl
  result object as returned by the SearchIO->next_result method, and the
  BioPerl hit object as returned by the result->next_hit method

=cut

sub record_hits {
  my $this = shift;
  my ($bdb,$bp,$hit_callback,$query_callback) = @_;

  ### check input ###
  $this->_source_type
    or croak 'Must provide a source type shortname via the source_type_shortname method first';
  UNIVERSAL::isa($bdb,'CXGN::BlastDB')
      or croak 'First argument to record_hits must be a BlastDB object';
  UNIVERSAL::isa($bp,'Bio::SearchIO')
      or croak 'Second argument to record_hits should be a bioperl SearchIO object';
  $hit_callback && ref $hit_callback ne 'CODE'
    and croak 'Must provide a subroutine reference for the hit callback subroutine, not a '.ref $hit_callback;
  $query_callback && ref $query_callback ne 'CODE'
    and croak 'Must provide a subroutine reference for the query callback subroutine, not a '.ref $query_callback;

  warn "      parsing SearchIO output and recording annotations...\n"; #progress message

  #do not parse the individual HSPs, just hits
  $bp->attach_EventHandler( Bio::SearchIO::FastHitEventBuilder->new );

  while ( my $result = $bp->next_result ) {
    my $sourceid = $result->query_name;
    dbp "Parsing results for source ID $sourceid...\n";
    $sourceid =~ /^\d+$/
      or croak "Invalid query identifier '$sourceid'.  This should be a number, corresponding to a database primary key.";

    ###  init an appropriate blastQuery object, or load an existing one ###
    my $blast_query = do {
      if ( my @blastqs = CXGN::Genomic::BlastQuery->search( source_id            => $sourceid,
							    query_source_type_id => $this->_source_type,
							    blast_db_id          => $bdb->blast_db_id,
							    {
							     order_by => 'last_updated' },
							  )
	 ) {

	
	#using an existing blast query
	@blastqs == 1
	  or die scalar(@blastqs)." rows in blast_query table match condition ("
	    .join(',',$sourceid,$this->_source_type->query_source_type_id,$bdb->blast_db_id).")";

	#delete any old blast hits associated with it
	foreach( $blastqs[0]->blast_hit_objects ) {
	  dbp "deleted old hit ".$_->blast_hit_id."\n";
	  $_->delete;
	}

	dbp "Using existing blast query ".$blastqs[0]->blast_query_id."\n";
	#return the existing one
	$blastqs[0]
      } else {
	#TODO: set defaults for total_hits and stored_hits to 0
	#make a new query and insert it into the database
	my $newq = CXGN::Genomic::BlastQuery->create({ source_id            => $sourceid,
						       query_source_type_id => $this->_source_type,
						       blast_db_id          => $bdb->blast_db_id,
						     });
	dbp "Made new blast query ".$newq->blast_query_id."\n";
	$newq;
      }
    };

    #call the query callback function
    $query_callback->($result) if $query_callback;

    ### make all the BlastHit objs and BlastDefline objs for this query ###
    my @hit_data;
    my ($total_hits,$stored_hits) = (0,0);
    while ( my $hit = $result->next_hit ) {
      my $hitstr = join('',(map {"\t$_"} ('hit',$hit->name,$hit->score,$hit->significance)));
      dbp $hitstr,"\n";

      #call the hit callback function if given
      $hit_callback->($result,$hit) if $hit_callback;

      if ( @hit_data < $max_stored_hits ) {
	my $identity_percentage;
	eval {
	  #there is some kind of bug in frac_identical that dies sometimes
	  $identity_percentage = $hit->frac_identical('query');
	}; if( $EVAL_ERROR ) {
	  $identity_percentage = 0;
	  warn "Warning: Could not get identity percentage for query ".$result->query_name.", hit ($hitstr).\n";
	  dbp "BioPerl error was:\n$EVAL_ERROR\nContinuing...";
	}
	my $newdata = { identifier          => $hit->name,
			evalue              => $hit->significance,
			score               => $hit->score,
			#not sure about which frac_* method to use (see Bio::Search::Hit::GenericHit docs)
			#it's not clear what BLAST's tabular output (used in the SGN unigene blast annots) does
			#in this regard
			identity_percentage => $identity_percentage,
			align_start         => $hit->start('query'),
			align_end           => $hit->end('query'),
			blast_defline_id    => $this->_get_defline_id($bdb,$hit),
			blast_query_id      => $blast_query,
		      };
	CXGN::Genomic::BlastHit->create( $newdata );
	$stored_hits++;
      }
      $total_hits++;
    }

    #now update the blast_query object with the hit counts, and update its
    #last_updated field
    $blast_query->set( total_hits           => $total_hits,
		       stored_hits          => $stored_hits,
		       last_updated         => strftime("%Y-%m-%d %H:%M:%S",localtime),
		     );
    $blast_query->update;
  }

  #delete any blast deflines that have now been made obsolete
  CXGN::Genomic::BlastDefline->delete_unreferenced;
}

sub _load_result {
  my ($this,$result, $hit_callback, $query_callback) = @_;

}


=head2 _get_defline_id

  Desc: Internal method to look up the index of a particular defline in the DB, or store
        it and return the new index if it's not already there
  Args: BlastDB object, blast hit object
  Ret : blast_defline_id of a defline for this hit, creating it in the DB if necessary

=cut

sub _get_defline_id {
  my ($this,$bdb,$hit) = @_;

  ##check input##
  UNIVERSAL::isa($hit,'Bio::Search::Hit::GenericHit')
      or die 'passed hit object must be a Bio::Search::Hit::GenericHit';

  my $defline_id;
  if( my @dls = CXGN::Genomic::BlastDefline->search( identifier  => $hit->name,
						     blast_db_id => $bdb,
						     defline     => $hit->description  )
    ) {
    @dls != 1 and die scalar(@dls)." BlastDefline objects match condition";
#   print "using existing defline ".Dumper($blastdl);
    $defline_id = $dls[0]->blast_defline_id;
  } else {
    my $newdl = CXGN::Genomic::BlastDefline->create({ blast_db_id => $bdb,
						      identifier  => $hit->name,
						      defline     => $hit->description,
						    });
    $defline_id = $newdl->blast_defline_id;

    die "Class::DBI insert id stuff apparently does not work (got new defline_id '$defline_id')"
      if $defline_id eq 'default' or $defline_id == 0 or ! $defline_id;
  }

  return $defline_id or die "something is wrong with this code ($defline_id)";
}

###
1;#do not remove
###
