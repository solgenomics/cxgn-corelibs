#ANALYSIS SUPERCLASS
package CXGN::TomatoGenome::BACSubmission::Analysis;

use Carp qw/confess croak/;

use Bio::Annotation::SimpleValue;
use Bio::SeqFeature::Annotated;

use List::MoreUtils qw/ all /;

sub new {
    bless {}, shift;
}

#maintains list of analysis packages to run at submission
our %run_at_submission;
sub run_for_new_submission {
  my ($class,$newval) = @_;
  my $name = $class->analysis_name;
  $run_at_submission{$name} = $newval if defined $newval;
}

#return list of analysis packages to run, sorted by their run_at_submission values
sub analyses_to_run {
  sort { $run_at_submission{$a} <=> $run_at_submission{$b} || $a cmp $b}
    grep { $run_at_submission{$_} }
      keys %run_at_submission
}

#the last part of the package name is the name of the analysis
sub analysis_name {
    my $self = shift;
    my $pkg = ref $self || $self;
    my $thispkg = __PACKAGE__;
    my ($name) = $pkg =~ /${thispkg}::(.+)/
        or die "could not parse pkg name '$pkg' as sub-namespace of '$thispkg'";
    $name =~ s/::/_/g;
    return $name;
}

sub check_ok_to_run {
  return 1;
}

sub list_params {
  return ();
}

sub analysis_generated_file {
  my ($self,$submission,$file) = @_;
  @_ == 3 or confess "analysis_generated_file takes 2 arguments";
  $submission or confess "submission argument must be defined!";

  my $analysis_dir = File::Spec->catdir($submission->_tempdir,$self->analysis_name);
  -d $analysis_dir or mkdir $analysis_dir
    or die "Could not mkdir $analysis_dir: $!";

#   my %valid_names =
#     (  GeneSeqer => [qw(
# 			out
# 			err
# 			game_xml
# 			gff3
# 		       )],
#        GenomeThreader => [qw( un_xed_seqs
# 			      out
# 			      err
# 			      game_xml
# 			      gff3
# 			    )],
#        tRNAscanSE => [qw( out err game_xml gff3 )],
#        RepeatMasker => [qw( out err game_xml gff3)],
#     );

#   #TODO: verify that the requested filename is valid for the analysis

  return File::Spec->catfile($analysis_dir,$file);
}

sub already_run {
  my ( $self, $submission ) = @_;
  return all {-f} $self->output_files($submission);
}
sub output_files {
  return ('not implemented');
}

#given a stem, make a ID that's unique to this analysis
#by appending a number to the stem
sub _unique_bio_annotation_id {
  my ($self,$idstem)  = @_;
  $self->{uniq_id_ctrs} ||= {};
  return Bio::Annotation::SimpleValue->new(-value => $idstem.'_'.++$self->{uniq_id_ctrs}{$idstem});
}

#take a feature hierarchy, manufacture ID and Parent tags to encode
#the hierarchical relationships, adding them to the features
sub _make_gff3_id_and_parent {
  my ($self,$feat,$parent_ID) = @_;

  $feat->add_Annotation('Parent',Bio::Annotation::SimpleValue->new(-value => $parent_ID))
    if defined $parent_ID;

  #make a unique id for this thing, keeping our id counters on a
  #per-analysis level
  $self->{uniq_id_ctr} ||= {};
  if(my $idstem = $self->_feature_id($feat,$parent_ID)) {
    my $uniqid = $self->_unique_bio_annotation_id($idstem);
    $feat->add_Annotation('ID',Bio::Annotation::SimpleValue->new(-value => $uniqid));
    #recursively ID and Parent all the subfeatures, if any
    $self->_make_gff3_id_and_parent($_,$uniqid) for $feat->get_SeqFeatures;
  }

}

#take a self,a feature, and an optional ID of its parent feature,
#return a string that's the new unique ID the feature should have
sub _feature_id { die 'implement in subclasses'} #just a stub, returning nothing.  implement in subclasses

#return the string name of the sequence database(s) this analysis is
#using.  used mostly for giving the database_name to gamexml
#generation
sub _dbname {''}

#recursively set the source on a feature and its subfeatures
sub _recursive_source {
  my ($self,$feature,$newsource) = @_;
  $feature->source($newsource);
  $self->_recursive_source($_,$newsource) for $feature->get_SeqFeatures;
}
#make a gff3-compliant feature start, end, and strand
#from a gamexml-style start and end that might be backwards
sub _start_end_strand(@) {
  my ($start,$end) = @_;
  $start && $end or confess "invalid start,end ($start,$end)";
  if($start > $end) {
    return ($end,$start,-1);
  } else {
    return ($start,$end,1);
  }
}

#object method to create a new feature object, with some defaults and
#automation of the more repetitive bits (like adding targets and
#subfeatures)
sub new_feature(@) {
  my ($self,%a) = @_;

  UNIVERSAL::isa($self,__PACKAGE__)
      or croak('_new_feature is an object method, silly');

  #replace spaces in source with underscores
  $a{-source} ||= $self->analysis_name;
  $a{-source} =~ s/\s+/_/g;

  #if no strand is given, make the proper strand and flip start and
  #end if necessary
  if( $a{-feature} ) {

  } elsif($a{-start} && $a{-end} && !$a{-strand}) {
    @a{qw/-start -end -strand/} = _start_end_strand(@a{qw/-start -end/});
  }

  #now make the feature and add all its targets and subfeatures and annotations
  return Bio::SeqFeature::Annotated->new(%a);
}


###
1;#do not remove
###
