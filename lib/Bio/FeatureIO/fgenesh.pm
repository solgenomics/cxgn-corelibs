=pod

=head1 NAME

Bio::FeatureIO::fgenesh - FeatureIO parser for FGENESH reports

=head1 SYNOPSIS

  my $feature_in = Bio::FeatureIO->new(-format => 'fgenesh',
                                       -file   => 'myfile.fgenesh',
                                      );

  while(my $feat = $feature_in->next_feature) {
    #do something with the feature
  }


=head1 DESCRIPTION

Parses FGENESH reports into L<Bio::SeqFeature::Annotated> objects,
with subfeatures.  The feature hierarchy is:

      mRNA
        |- five_prime_UTR
        |- CDS
        |- ...
        `- three_prime_UTR
      polyA_signal_site

One or both of the UTRs and/or polyA_signal_site might be missing.
Sometimes FGENESH does not provide them.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR

 Robert Buels, rmb32@cornell.edu

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::FeatureIO::fgenesh;
use strict;

use base qw(Bio::FeatureIO);

use Bio::SeqFeature::Annotated;
use Bio::Annotation::Target;

=head2 new()

  returns a new parser FeatureIO::fgenesh object

=cut

# sub _initialize {
#   my($self,%arg) = @_;

#   $self->SUPER::_initialize(%arg);

#   #init buffers
#   $self->{alignment_buffer} = [];
#   $self->{feature_buffer} = [];

#   #set defaults
#   $arg{-mode} ||= 'pgls';
#   $arg{-attach_alignments} = 0 unless defined $arg{-attach_alignments};

#   #set options
#   $self->mode($arg{-mode});
#   $self->attach_alignments($arg{-attach_alignments});


#   my $alignment_buffer = $self->mode eq 'both_merged' || $self->mode eq 'alignments_merged'
#     ? $self->{feature_buffer}
#     : $self->{alignment_buffer};
#   my @spliced_alignment_twig = $self->mode eq 'pgls'
#     ? ()
#     : (spliced_alignment => sub {
# 	 push @$alignment_buffer,
# 	   $self->_parse_alignment(@_);
# 	 shift->purge;
#        });
#   my @pgl_twig  = $self->mode eq 'alignments' || $self->mode eq 'alignments_merged'
#     ? ()
#     : (predicted_gene_location => sub {
# 	 push @{$self->{feature_buffer}},
# 	   $self->_parse_pgl(@_);
# 	 shift->purge;
#        });

#   #now parse the entire input file, buffering pgls and alignments
#   XML::Twig->new( twig_roots =>
# 		  {
# 		   @spliced_alignment_twig,
# 		   @pgl_twig,
# 		  }
# 		)->parse($self->_fh);
# }

=head2 next_feature()

 Usage   : my $feature = $featureio->next_feature();
 Function: returns the next available gene prediction.
           Predictions will be returned in the same order as they
           appear in the file.
 Returns : a predicted gene feature, of class
           L<Bio::SeqFeature::Annotated>
 Args    : none

=cut

sub next_feature {
  my ($self) = @_;

  #return a buffered feature if we have one
  if($self->{feature_buffer} && @{$self->{feature_buffer}}) {
    return shift @{$self->{feature_buffer}};
  }

  #otherwise, continue parsing
  while(my $line = $self->_readline) {
    if( $self->_match( $line => 'is_prediction_line' )) {
      #must be a prediction line
      $self->_pushback($line);
      my ($mrna,$polya) = $self->_parse_prediction;
      push @{$self->{feature_buffer}},$polya if $polya;
      return $mrna;
    }
    elsif( my ($seqname) = $self->_match( $line => 'capture_seq_name' )) {
      $self->{seqname} = $seqname;
      #save the sequence name for further reference and continue
    }
    elsif( my ($pname) = $self->_match( $line => 'capture_params_name' )) {
      $self->{paramsname} = $pname;
    }
    elsif( $self->_match( $line => 'is_start_proteins' )) {
      #we end our parsing when the predicted protein section begins

      #gotta push it back so we'll hit it again if the user calls
      #next_feature again
      $self->_pushback($line);
      return;
    }
  }
}

#central function for keeping all the regexps used in this parser,
#returns the result of matching the given text against the pattern
#with the given name
sub _match {
  my ($self,$text,$patname) = @_;
  my %pats = ( is_prediction_line => qr/^\s*\d+\s*[+-]/,
	       capture_seq_name   => qr/^\s*Seq(?:uence)?\s*name\s*:\s*(\S+)/i,
	       capture_params_name=> qr/^\s*FGENESH.+prediction.+in (\S+).+DNA/i,
	       is_start_proteins  => qr/^\s*Predicted protein(s):/i,
	     );
  $pats{$patname} or $self->throw("unknown pattern name '$patname'");
  return $text =~ $pats{$patname};
}

sub _parse_prediction {
  my ($self) = @_;

  #store the lines
  my @features;
  my $polya; #< store the polya separately if present

  my $line;

  while($line = $self->_readline and $self->_match($line => 'is_prediction_line')) {
#    warn "parsing line: $line";
    my @data = split /\s+/,$line;
    shift @data until $data[0]; #< get rid of leading whitespace

#    warn "data is: ".join(',',@data)."\n";

    ####  now parse the prediction line in earnest

    my ($prediction_number,$strand) = splice @data,0,2;

    #next thing might be either an exon number or the type
    my $exon_num  = $data[0] =~ /^\d+$/ ? shift(@data) : undef;

    my $type      = shift @data;
    my $start     = shift @data;

    my ($end,$score) = do {
      if($data[0] eq '-') {
	shift @data;
	splice @data,0,2
      } else {
	$start,shift @data #< has no end, thus end is same as start
      }
    };

#     my $orf_start = shift @data;

#     my $orf_end   = shift @data;
#        $orf_end   = shift @data if $orf_end eq '-';

    ### now make a feature out of it
    my %type_map = (
		    TSS  => 'five_prime_UTR',
		    PolA => 'polyA_signal_sequence',
		    CDSi => 'CDS',
		    CDSf => 'CDS',
		    CDSl => 'CDS',
		    CDSo => 'CDS',
		   );
    $type = $type_map{$type} || do {$self->warn("could not convert fgenesh type '$type' to a SOFA type");
				       'region'}; #< default to 'region' and warn about it
    my $pname = $self->{paramsname} ? "_$self->{paramsname}" : '';
    push @features, Bio::SeqFeature::Annotated->new
      ( -start  => $start, -end => $end, -strand => $strand,
	-score  => $score,
	-type   => $type,
	-seq_id => defined $self->{seqname} ? $self->{seqname}
                                            : $self->throw("parse error, no sequence line found before predictions"),
	-source => "FGENESH$pname",
	-annots => { ID => "FGENESH$pname-$self->{seqname}-gene_$prediction_number-$type".($exon_num ? "-$exon_num" : '')},
      );
  }

  ### now go back and correct/add some things
  #make an array with features ordered from transcription start to end
  our $strand = $features[0]->strand;
  @features = reverse @features if $strand == -1;

  #make subs to operate on a feature relative to the direction of transcription
    sub se { #< return start/end string, relative to dir of transcription
      my ($se) = @_;
      return $strand == -1 ? ( $se eq 'start' ? 'end' : 'start' ) : $se;
    }
    sub fse {	#< access feature start/end relative to dir of transcription
      my ($feat,$se,$val) = @_;
      $se = se($se);
      return $feat->$se($val);
    }
    sub add { #< sub to add $a and $b, reversing +/- if on reverse strand
      my ($a,$b) = @_;
      return $strand == -1
	? $a - $b
        : $a + $b;
    }

  #now fix the utrs, operating relative to the dir of transcription

  #set the end of the five_prime_UTR to be next to the beginning of
  #the first CDS
  if($features[0]->type->name eq 'five_prime_UTR') {
    fse($features[0],'end', add(fse($features[1],'start'),-1));
  }
  sub fts {
    my ($feat) = @_;
    join(' ',map {"'$_'"} $feat->type->name,$feat->start,$feat->end)."\n";
  }
  #add 5 to the polyA signal site coordinate if present so that it
  #encompasses the whole poly-A signal sequence
  if($features[-1]->type->name eq 'polyA_signal_sequence') {
    $polya = pop @features;

    #reparent the polya feature to be part of the gene, not the mRNA,
    #in order to conform with SO and SOFA
    #TODO


    fse($polya,'end',  add(fse($polya,'start'),5));
    #make a new three_prime_UTR feature from the end of the last CDS
    #encompassing the polyA signal site
    my $utrid = $polya->get_Annotations('ID')->value;
    $utrid =~ s/gene_(\d+)-.+$/gene_$1-three_prime_UTR/;
    my $utr3 = Bio::SeqFeature::Annotated->new( -feature => $polya,
						-type => 'three_prime_UTR',
						-annots => { ID => $utrid },
					      );
#    $utr3->seq_id('foobar');
    fse($utr3,'start', add(fse($features[-1],'end'),1));
#    warn "adding utr3 ".fts($utr3);
    push @features,$utr3;
  }

  #now reverse again to put it back in the original order
  @features = reverse @features if $strand == -1;

#  warn "\nfeatures are now:\n",map {fts($_)} @features;# if $strand == -1;

  #make all of these subfeatures of a single mRNA feature, with Parent
  #annotations to match
  my $mrna_id = $features[0]->get_Annotations('ID')->value;
  $mrna_id =~ s/gene_(\d+)-.+$/gene_$1-mRNA/;
  my $mrna = Bio::SeqFeature::Annotated->new( -feature => $features[0],
					      -end => $features[-1]->end,
					      -type => 'mRNA',
					      -score => '.',
					      -annots => { ID => $mrna_id},
					    );
  foreach(@features) {
    $_->add_Annotation(Parent => Bio::Annotation::SimpleValue->new(-value => $mrna_id));
    $mrna->add_SeqFeature($_);
  }

  return $mrna,$polya;
}

=head2 write_feature()

Not implemented.

=cut

sub write_feature {
  shift->throw_not_implemented;
}

###
1;# do not remove
###

