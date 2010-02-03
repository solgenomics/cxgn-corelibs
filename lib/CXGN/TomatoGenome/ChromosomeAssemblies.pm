package CXGN::TomatoGenome::ChromosomeAssemblies;
use strict;
use warnings;
use English;
use Carp;

=head1 NAME

CXGN::TomatoGenome::ChromosomeAssemblies - functions for working with
chromosome assemblies of the Tomato genome, as represented by their
AGP files

=head1 SYNOPSIS

  # get the set of named contigs from the currently published tomato
  # chromosome 4 AGP file
  my %contigs = named_contigs(4);

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use CXGN::TomatoGenome::BACPublish qw/ agp_file /;
use CXGN::Publish;
use CXGN::BioTools::AGP qw/ agp_contigs agp_parse /;
use CXGN::Publish;

use List::Util qw/max min/;

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw(
		      named_contigs
		      contig_features
		     );
}
our @EXPORT_OK;


=head2 named_contigs

  Usage:  my %contigs = named_contigs(4, agp_file => 'filename.agp');
  Desc :  get the set of named sequence contigs for a given
          chromosome, based on its currently published agp file
  Args :  chromosome number,
          optional hash-style list of options:
             agp_file => force the agp file to parse,
                         defaults to the currently published AGP file
                         for that chromosome
             version  => force the given chromosome version to appear in
                         the contig names, not compatible with include_old
             include_old => if true, old chromosome AGP files will also
                            be parsed
  Ret  :  nothing if file could not be opened,
          or hash-style list of contigs, like:
           C04.23_contig1 => [ agp_file_line, agp_file_line, ... ],
           C04.23_contig2 => [ agp_file_line, agp_file_line, ... ],
           ...

          each of the agp_file_lines is a parsed AGP file line hashref
          as returned by CXGN::BioTools::AGP::agp_parse.

=cut

sub named_contigs {
  my ($chrnum,%options) = @_;

  my $primary_agp_file = $options{agp_file} || agp_file($chrnum);
  $primary_agp_file && -r $primary_agp_file
    or return;

  my @files_to_parse = ($primary_agp_file);
  if( $options{include_old} ) {
    $options{version} && croak "cannot specify both version and include_old in call to named_contigs";
    my $pub = CXGN::Publish::published_as( $primary_agp_file );
    #warn "pub is ".Dumper $pub;
    if( $pub ) {
      push @files_to_parse, map $_->{fullpath}, @{ $pub->{ancestors} };
    }
  }

  #warn "files_to_parse is ",Dumper(\@files_to_parse);

  return map {
    my $agp_file = $_;

    my $p = CXGN::Publish::parse_versioned_filepath($agp_file);

    #extract the contigs from the AGP file
    my @contigs = agp_contigs( agp_parse($agp_file) );

    my $fileversion = $options{version} || do {
      $p ? $p->{version} : 0
    };

    _contigs_in_file( $chrnum, $agp_file, $fileversion );
  } @files_to_parse;
}

sub _contigs_in_file {
  my ( $chrnum, $agp_file, $version ) = @_;

  #extract the contigs from the AGP file
  my @contigs = agp_contigs( agp_parse($agp_file) );

  #name the contigs
  my $serial;
  return map {
    sprintf('C%02.0f.%d_contig%d',$chrnum,$version || 0,++$serial) => $_
  } @contigs;
}


=head2 contig_features

  Usage: my %ctg_features = contig_features( named_contigs( 4 ) );
  Desc : transform the AGP lines in the data returned by named_contigs()
         into features showing the location of each component in the contig
  Args : hash-style list as returned by named_contigs() above,
         plus optional hashref as
         {  source_name => name to use for the feature source name, default 'AGP',
            component_type => type to use for a component feature, default 'supercontig',
            contig_type    => type to use for a contig feature, default 'ultracontig'
         }
  Ret  : list of contig features
  Side Effects: none

=cut

sub contig_features {
  my (@contigs) = @_;

  my $opts = ref($contigs[-1]) eq 'HASH' ? pop @contigs : {};

  $opts->{source_name} ||= 'AGP';
  $opts->{contig_type} ||= 'ultracontig';
  $opts->{component_type} ||= 'supercontig';

  my @features;
  while( my ($name,$lines) = splice @contigs, 0, 2 ) {
    my $contig_feature = Bio::SeqFeature::Annotated->
      new( -start => min( map $_->{ostart}, @$lines ),
	   -end   => max( map $_->{oend}, @$lines ),
	   -type  => $opts->{contig_type},
	   -source => $opts->{source_name},
	   -seq_id => $lines->[0]->{objname},
	   -annots => { ID => $name,
		      },
	 );
    my @subfeatures;
    foreach my $line (@$lines ) {
      next if $line->{comment};
      push @subfeatures,
	  Bio::SeqFeature::Annotated->new( -start => $line->{ostart},
					   -end   => $line->{oend},
					   #-score => undef,
					   -type  => $opts->{component_type},
					   -source => $opts->{source_name},
					   -seq_id => $line->{objname},
					   -target => { -start => $line->{cstart},
							-end   => $line->{cend},
							-target_id => $line->{ident},
						      },
					   -annots => { ID => "$name-$line->{ident}",
						      },
					 );
    }

    foreach (@subfeatures) {
      $contig_feature->add_SeqFeature( $_ );
      $_->add_Annotation( Parent => Bio::Annotation::SimpleValue->new(-value => $name))
    }

    push @features, $contig_feature;
  }
  return sort { $a->start <=> $b->start } @features;
}




=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
