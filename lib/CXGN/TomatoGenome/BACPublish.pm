package CXGN::TomatoGenome::BACPublish;
use strict;
use warnings;
use English;
use Carp;

use File::Basename;
use File::Spec;
use File::Path qw/mkpath/;
use File::Temp qw/tempdir/;

use Cache::File;

use Memoize;

use Storable qw/freeze thaw/;

use CXGN::Tools::List qw/flatten/;
use CXGN::Publish qw/parse_versioned_filepath/;
use CXGN::Tools::Run;
use CXGN::Tools::Wget qw/wget_filter/;

use CXGN::TomatoGenome::Config;

use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident clone_ident_glob assemble_clone_ident/;

=head1 NAME

CXGN::TomatoGenome::BACPublish - utility functions for publishing BACs to the FTP site

=head1 SYNOPSIS

coming soon

=head1 DESCRIPTION

coming soon

=head1 FUNCTIONS

All functions listed below are EXPORT_OK.

=cut

BEGIN {
  our @EXPORT_OK = qw(
		      parse_filename
		      publishing_locations
		      sequencing_files
		      bac_publish
		      publisher
		      resource_file
		      aggregate_filename
		      glob_pattern
		      tpf_agp_files
		      find_submissions
		      tpf_file
		      agp_file
		      contig_file
		      seq_name_to_genbank_acc
		      genbank_acc_to_seq_name
		      cached_validation_text
		      cached_validation_errors
		      valcache
		      find_new_submissions
		     );
}
our @EXPORT_OK;
use base qw/Exporter/;


#these are regexps for use with File::Basename::fileparse,
#which preserve the sequence version as part of the filename's
#base, not its suffixes
# NOTE that this is an array ref, not an array
use constant bac_suffixes =>  [  qr/(?<=\.\d{5})\..+$/,
				 qr/(?<=\.\d{4})\..+$/,
				 qr/(?<=\.\d{3})\..+$/,
				 qr/(?<=\.\d{2})\..+$/,
				 qr/(?<=\.\d)\..+$/,
				 qr/\..*[a-z].*$/i,
			      ];
#if the perl regexp engine could do variable-length lookbehind
#assertions, i would not have to resort to that tomfoolery


=head2 find_new_submissions

  Usage: my @submissions = find_new_submissions($upload_root_dir);
  Desc : looks in the (optional) given upload root for new bac
         submissions, returns a list of filenames that look like they
         are BAC submissions
  Args : (optional) upload root directory 
         (defaults to  conf:country_uploads_path)
  Ret  : list of filenames, possibly empty
  Side Effects: none

=cut

sub find_submissions {
  my ( $self, $upload_dir ) = @_;
  $upload_dir ||= _conf()->{'country_uploads_path'};

  my @submissions =
    # and of these, find the ones that look like actual bac submission
    # file names
    grep parse_filename($_),
      # map them into the list of possible submissions in them
      map glob(File::Spec->catfile($_,'upload','C{0,1}*.tar.gz')),
	# start with list of upload dirs
	map File::Spec->catdir($upload_dir,$_),
	  qw( agencourt-bacs
	      argentina
	      china
	      china11
	      jianfeng-ren
	      france
	      italy
	      india
	      india-iari
	      japan
	      korea
	      manual
	      netherlands
	      seqwright-bacs
	      spain
	      sym-bio
	      uk
	      us
	    );

  return @submissions;
}


=head2 parse_filename

  Usage: my $info = parse_filename('/foo/C02HBa0001.tar.gz');
  Desc : parse the filename of a BAC submission into its component
         parts, returning a hash of them
  Ret  : nothing if not a parsable filename, or a hashref as:
         {  filename  	 => the filename you passed in, unaltered,
            basename  	 => the filename, minus any directories,
            full_unversioned => filename you passed in, without version info,
            lib       	 => shortname of the corresponding Library Object
            plate     	 => plate number,
            row       	 => row (usually a letter A-Z),
            col       	 => column number,
            chr       	 => chromosome number, or 'unmapped'
            clone_name   => the substring in the input that probably contains
                            the clone name,
            seq_name     => the substring in the input that contained the
                      	    parsed sequence name (BAC name plus seq version),
            seq_version  => (optional) the sequence version, if included
                            in the filename,
            file_version => (optional) the version, if published using
                            L<CXGN::Publish>,
            finished  	 => 1 if the file name and path indicate that the
                      	    submission is finished, 0 if they indicate
                            that it is unfinished, or undef if it could
                            not be determined
         }
  Args : a single filename, with or without path, with or without
         versioning extensions
  Side Effects: none
  Example:

=cut

sub parse_filename {
  my ($filename) = @_;

  my $pub = CXGN::Publish->new;
  $pub->suffix(bac_suffixes);
  my $versioned = $pub->parse_versioned_filepath($filename);
  my ($basename,$path,$ext) = fileparse($filename,@{bac_suffixes()});

  return unless $basename;

  my $ident = $versioned ? $versioned->{name} : $basename;
  #warn "$filename -> $ident\n";
  my $parsed = parse_clone_ident($ident,'versioned_bac_seq','agi_bac_with_chrom')
    or return;

#  use Data::Dumper;
  #warn "got parsed:\n",Dumper($parsed);

  #if the parser didn't return a clone_name, assume it's the same ident
  $parsed->{clone_name} ||= $ident;

  #switch around some things from the parser
  delete($parsed->{clonetype});
  delete($parsed->{fragment});
  $parsed->{seq_version} = $parsed->{version};
  delete($parsed->{version});
  $parsed->{seq_name} = $parsed->{match};
  delete($parsed->{match});

  #add some things from the Publish parser
  $parsed->{file_version} = $versioned ? $versioned->{version} : undef;
  $parsed->{full_unversioned} = $versioned->{fullpath_unversioned};

  #add the filename, basename, etc
  $parsed->{filename}  = $filename;
  $parsed->{basename} = $basename.$ext;
  $parsed->{finished} = do {
    if($path && $path =~ m|(un)?finished/*$|) {
      $1 ? 0 : 1;
    } else {
      undef
    }
  };

  return $parsed;
}

=head2 publishing_locations

  Usage: my $files_hr = publishing_locations($pubdir,$sequence_name,$is_finished);
  Desc : get a hashref containing where in a publishing structure you
         should publish this submission
  Ret  : a hashref containing publishing locations, like:
         {  seq => 'full path for publishing the seq file',
            tar => 'full path for publishing the tar file',
            annot_merged => [ merged game file, merged gff3 file],
            annot_<name> => [ game file, gff3 file, (optional) other files...],
            annot_<name> => [ game file, gff3 file, (optional) other files...],
            ...
            obsolete => { the same kind of hash, except these are the names
                          of other files which may be published in other locations
                          or by other names that should be obsoleted by these files.
                          All elements of this array are arrayrefs
                        }
         }
         There are too many to mention here.  Pass the output
         to Data::Dumper or read this code for the full list.
  Args : path to the base publishing directory,
         bac name (with chromosome) or bac sequence name (with chromosome),
         flag whether the BAC is finished,
  Side Effects: none

=cut

#TODO: add functions to generate list of other files that should be removed
#if encountered

#given submission, returns hash ref of places to put files for publishing
#if an optional second argument is given ('finished' or 'unfinished'),
#forces this to make the filenames as if this submission were finished or unfinished
sub publishing_locations {
  my ($pubdir,$seqname,$is_finished) = @_;
  @_ == 3 or croak 'Invalid arguments to publishing_locations';

  my $parsedname = parse_clone_ident($seqname,'versioned_bac_seq','agi_bac_with_chrom')
    or return {};
  $parsedname->{clone_name} ||= $seqname;
  $parsedname->{chr} = 0 if $parsedname->{chr} eq 'unmapped';

#  warn "got seqname $seqname\n";

  sub _files {
    my ($pubdir,$parsedname,$is_finished,$seqversion,$chromosome) = @_;
    my %newname = %$parsedname;
    $newname{chr} = $chromosome;
    $newname{version} = $seqversion;

    my $chrdir = sprintf('chr%02d',$newname{chr});

    my $fin = $is_finished ? 'finished' : 'unfinished';

    my $seqname = assemble_clone_ident( $seqversion ? 'versioned_bac_seq' : 'agi_bac_with_chrom',
					\%newname
				      );

    my @common = ($pubdir,$chrdir,$fin);
    return { seq           => File::Spec->catfile(@common, "$seqname.seq"),
	     tar           => File::Spec->catfile(@common, "$seqname.tar.gz"),
	     annot_merged  =>
	     [ File::Spec->catfile(@common, "$seqname.all.xml"),
	       File::Spec->catfile(@common, "$seqname.all.gff3"),
	     ],
	     annot_GeneSeqer_SGN_E_tomato  =>
	     [ File::Spec->catfile(@common, 'annotation', 'geneseqer',
				   "$seqname.geneseqer.sgne_tomato.xml"),
	       File::Spec->catfile(@common, 'annotation','geneseqer',
				   "$seqname.geneseqer.sgne_tomato.gff3"),
	       File::Spec->catfile(@common, 'annotation','geneseqer',
				   "$seqname.geneseqer.sgne_tomato"),
	     ],
	     annot_GeneSeqer_SGN_U_tomato  =>
	     [ File::Spec->catfile(@common, 'annotation', 'geneseqer',
				   "$seqname.geneseqer.sgnu_tomato.xml"),
	       File::Spec->catfile(@common, 'annotation','geneseqer',
				   "$seqname.geneseqer.sgnu_tomato.gff3"),
	       File::Spec->catfile(@common, 'annotation','geneseqer',
				   "$seqname.geneseqer.sgnu_tomato"),
	     ],
	     annot_GenomeThreader_SGN_E_tomato  =>
	     [ File::Spec->catfile(@common, 'annotation', 'genomethreader',
				   "$seqname.gth.sgne_tomato.xml"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgne_tomato.gff3"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgne_tomato.out.xml"),
	     ],
	     annot_GenomeThreader_SGN_E_tomato_potato  =>
	     [ File::Spec->catfile(@common, 'annotation', 'genomethreader',
				   "$seqname.gth.sgne_tomato_potato.xml"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgne_tomato_potato.gff3"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgne_tomato_potato.out.xml"),
	     ],
	     annot_GenomeThreader_SGN_U_tomato  =>
	     [ File::Spec->catfile(@common, 'annotation', 'genomethreader',
				   "$seqname.gth.sgnu_tomato.xml"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgnu_tomato.gff3"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgnu_tomato.out.xml"),
	     ],
	     annot_GenomeThreader_SGN_markers  =>
	     [ File::Spec->catfile(@common, 'annotation', 'genomethreader',
				   "$seqname.gth.sgn_markers.xml"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgn_markers.gff3"),
	       File::Spec->catfile(@common, 'annotation','genomethreader',
				   "$seqname.gth.sgn_markers.out.xml"),
	     ],
	     annot_RepeatMasker =>
	     #WARNING: ITAG PIPELINE 'repeats' ANALYSIS DEPENDS ON
	     #THESE FILENAMES, UPDATE IT IF YOU CHANGE
	     [ File::Spec->catfile(@common, 'annotation', 'repeatmasker',
				   "$seqname.repeatmasker.xml"),
	       File::Spec->catfile(@common, 'annotation','repeatmasker',
				   "$seqname.repeatmasker.gff3"),
	       File::Spec->catfile(@common, 'annotation','repeatmasker',
				   "$seqname.repeatmasker.gff2"),
	       File::Spec->catfile(@common, 'annotation','repeatmasker',
				   "$seqname.repeatmasker.out"),
	       File::Spec->catfile(@common, 'annotation','repeatmasker',
				   "$seqname.repeatmasker.masked_seq.seq"),
	     ],
	     annot_tRNAscanSE =>
	     [ File::Spec->catfile(@common, 'annotation', 'tRNAscan-SE',
				   "$seqname.trnascanse.xml"),
	       File::Spec->catfile(@common, 'annotation','tRNAscan-SE',
				   "$seqname.trnascanse.gff3"),
	       File::Spec->catfile(@common, 'annotation','tRNAscan-SE',
				   "$seqname.trnascanse.out"),
	     ],
	     annot_BLAST_tomato_bac_ends =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.tomato_bac_ends.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_bac_ends.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_bac_ends.out"),
	     ],
	     annot_BLAST_nr =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.genbank_nr.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.genbank_nr.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.genbank_nr.out"),
	     ],
	     annot_BLAST_ath_pep =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.arabidopsis_peptides.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.arabidopsis_peptides.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.arabidopsis_peptides.out"),
	     ],
	     annot_BLAST_E_coli_K12 =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.e_coli.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.e_coli.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.e_coli.out"),
	     ],
	     annot_BLAST_tomato_chloroplast =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.tomato_chloroplast.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_chloroplast.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_chloroplast.out"),
	     ],
	     annot_BLAST_tomato_bacs =>
	     [ File::Spec->catfile(@common, 'annotation', 'BLAST',
				   "$seqname.tomato_bacs.xml"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_bacs.gff3"),
	       File::Spec->catfile(@common, 'annotation','BLAST',
				   "$seqname.tomato_bacs.out"),
	     ],
	     annot_Cross_match_vector =>
	     [ File::Spec->catfile(@common, 'annotation', 'vector',
				   "$seqname.xml"),
	       File::Spec->catfile(@common, 'annotation','vector',
				   "$seqname.gff3"),
	       File::Spec->catfile(@common, 'annotation','vector',
				   "$seqname.out"),
	     ],
	     annot_AUGUSTUS_tom_ugs =>
	     [ File::Spec->catfile(@common, 'annotation',
				   'AUGUSTUS_tom_ugs',
				   "$seqname.AUGUSTUS_tom_ugs.xml"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_ugs',
				   "$seqname.AUGUSTUS_tom_ugs.gff3"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_ugs',
				   "$seqname.AUGUSTUS_tom_ugs.hints.psl"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_ugs',
				   "$seqname.AUGUSTUS_tom_ugs.hints.gff"),
	     ],
	     annot_AUGUSTUS_tom_pot_cdna =>
	     [ File::Spec->catfile(@common, 'annotation',
				   'AUGUSTUS_tom_pot_cdna',
				   "$seqname.AUGUSTUS_tom_pot_cdna.xml"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_pot_cdna',
				   "$seqname.AUGUSTUS_tom_pot_cdna.gff3"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_pot_cdna',
				   "$seqname.AUGUSTUS_tom_pot_cdna.hints.psl"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_pot_cdna',
				   "$seqname.AUGUSTUS_tom_pot_cdna.hints.gff"),
	     ],
	     annot_AUGUSTUS_tom_cdna =>
	     [ File::Spec->catfile(@common, 'annotation',
				   'AUGUSTUS_tom_cdna',
				   "$seqname.AUGUSTUS_tom_cdna.xml"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_cdna',
				   "$seqname.AUGUSTUS_tom_cdna.gff3"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_cdna',
				   "$seqname.AUGUSTUS_tom_cdna.hints.psl"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_tom_cdna',
				   "$seqname.AUGUSTUS_tom_cdna.hints.gff"),
	     ],
	     annot_AUGUSTUS_ab_initio =>
	     [ File::Spec->catfile(@common, 'annotation',
				   'AUGUSTUS_ab_initio',
				   "$seqname.AUGUSTUS_ab_initio.xml"),
	       File::Spec->catfile(@common, 'annotation','AUGUSTUS_ab_initio',
				   "$seqname.AUGUSTUS_ab_initio.gff3"),
	     ],
	     annot_Contigs =>
	     [ File::Spec->catfile(@common, 'annotation','Contigs',"$seqname.Contigs.xml"),
	       File::Spec->catfile(@common, 'annotation','Contigs',"$seqname.Contigs.gff3"),
	     ],
	     annot_PolyBayes =>
	     [ File::Spec->catfile(@common, 'annotation','polybayes_snps',"$seqname.polybayes_snps.xml"),
	       File::Spec->catfile(@common, 'annotation','polybayes_snps',"$seqname.polybayes_snps.gff3"),
	       File::Spec->catfile(@common, 'annotation','polybayes_snps',"$seqname.polybayes_snps.out"),
	       File::Spec->catfile(@common, 'annotation','polybayes_snps',"$seqname.polybayes_snps.align.gz"),
	       File::Spec->catfile(@common, 'annotation','polybayes_snps',"$seqname.polybayes_snps.ace.gz"),
	     ],
	   };
  }

  #make the set of different finished/unfinished and seqversion files
  #that might exist in the publication dir, with the primary ones (the
  #ones we're actually publishing) first then, we'll put the rest of
  #them in the 'obsolete' part of the return

  #note that we're not generating versions that would be _later_ than
  #this one, meaning that an update of the files for an old sequence
  #version will not supersede the new sequence version, as long as the
  #version number has been set to the right version
  my @args;
  $parsedname->{version} ||= 1;
  my $current_chr = defined $parsedname->{chr} ? $parsedname->{chr} : -1;
  foreach my $chromosome ($current_chr, grep $_ != $current_chr, 0..12) {
    foreach my $finished ($is_finished, !$is_finished) {
      foreach my $version ( reverse( 1..$parsedname->{version} ), undef ) {
	push @args, [$finished,$version,$chromosome];
      }
    }
  }

  #use Data::Dumper;
  #warn "got perturbed args:\n",Dumper(\@args);

  #make our primary list of files
  my $primary = _files($pubdir,$parsedname,@{shift @args});
  #warn "primary is:\n",Dumper($primary);
  #warn "and first obsolete is\n",Dumper($args[0]);

  #now fill its obsolete entry with all possible other versions
  #that this one would supersede
  foreach my $argset (@args) {
    my $files = _files($pubdir,$parsedname, @$argset);
    foreach my $fileset (keys %$files) {
      $primary->{obsolete}->{$fileset} ||= [];
      push @{$primary->{obsolete}->{$fileset}}, flatten $files->{$fileset};
    }
  }

  return $primary;
}

#make a constant hash of the aggregate files and patterns for the things that go into them
#list of all the different aggregate files we make, and patterns for the files that go into them
#the actual work of putting together these files is done in bsub_aggregate_files.pl
memoize('agfiles_pats');
sub agfiles_pats {
  #calculate some variables for the repetitive bits of these globs
  my $chrnum = '{'.join(',',map{sprintf '%02d',$_}(0..12)).'}'; #< bsd glob for nums 01-12
  my $allchrs = "chr$chrnum";                                   #< bsd glob for chr01-chr12
  my $allfins = '{finished,unfinished}';                        #< bsd glob for 'finished' or 'unfinished'
  my $bacname = clone_ident_glob('agi_bac_with_chrom')         #< bsd glob for clone identifiers
    or die 'no glob for agi_bac_with_chrom';

  my $bac_seqs = "$bacname.*.seq";
  my $rm_seqs  = "annotation/repeatmasker/$bacname.*.masked_seq.seq"; #< bsd glob to find repeatmasked seqs in a chromosome dir
  my $bac_gff3s = "$bacname.*.all.gff3";
  my $bac_accs = $bac_seqs; #< the accessions are in the fasta headers of the seq files

  #now here's the hash
  {
   all_seqs          => ['bacs.seq',
			 "$allchrs/$allfins/$bac_seqs",
			],

   all_rm_seqs       => ['bacs_repeatmasked.seq',
			 "$allchrs/$allfins/$rm_seqs",
			],

   all_gff3          => ['bacs.all.gff3',
			 "$allchrs/$allfins/$bac_gff3s",
			],

   all_accs          => ['bacs_accessions.txt',
			 "$allchrs/$allfins/$bac_accs",
			],

   finished_seqs     => ['finished_bacs.seq',
			 "$allchrs/finished/$bac_seqs",
			],

   finished_rm_seqs  => ['finished_bacs_repeatmasked.seq',
			 "$allchrs/finished/$rm_seqs",
			],

   finished_gff3     => ['finished_bacs.all.gff3',
			 "$allchrs/finished/$bac_gff3s",
			],

   finished_accs     => ['finished_bacs_accessions.txt',
			 "$allchrs/finished/$bac_accs",
			],

   #per-chromosome aggregate files
   map {
     my $chrstr = sprintf('chr%02d',$_);
     (
      "chr${_}_finished_seqs"    =>
      [ "$chrstr/finished/finished_bacs.seq",
	"$chrstr/finished/$bac_seqs",
      ],
      "chr${_}_finished_rm_seqs"    =>
      [ "$chrstr/finished/finished_bacs_repeatmasked.seq",
	"$chrstr/finished/$rm_seqs",
      ],
      "chr${_}_finished_gff3"    =>
      [ "$chrstr/finished/finished_bacs.all.gff3",
	"$chrstr/finished/$bac_gff3s",
      ],
      "chr${_}_finished_accs"     =>
      [ "$chrstr/finished/finished_bacs_accessions.txt",
	"$chrstr/finished/$bac_accs",
      ],
     )
   } (0..12)
 }
}


=head2 glob_pattern

  Usage: my $pat = glob_pattern()
  Desc : get a string for use with glob() that matches a set of files in
         the publishing directory
  Args : tagname of the set of files you want.  available tags are:
            all_seqs
            all_rm_seqs
            all_gff3
            all_acc
            finished_seqs
            finished_rm_seqs
            finished_gff3
            chr1_finished_seqs
            chr1_finished_rm_seqs
            chr1_finished_gff3
            <similarly for other chromosomes>
  Ret  : a string usable as a glob pattern
  Side Effects: dies on error (like if you pass an unknown tag name)

=cut

sub glob_pattern {
  _agfile_pat(1,@_);
}

=head2 aggregate_filename

  Usage: my $ags = aggregate_filename('all_seqs','/data/prod/ftpsite/tomato_genome/bacs');
  Desc : get the full (unversioned) path to one of the aggregate files
         in the given bac publishing directory
  Args : tagname of the file you want, one of:
            all_seqs
            all_rm_seqs
            all_gff3
            all_acc
            finished_seqs
            finished_rm_seqs
            finished_gff3
            chr1_finished_seqs
            chr1_finished_rm_seqs
            chr1_finished_gff3
            <similarly for other chromosomes>
         (optional) publishing dir, defaults to <ftpsite_root>/tomato_genome/bacs,
                    where ftpsite_root is a value from the CXGN VHost conf
  Ret  : an unversioned file name (with path)
  Side Effects: dies on error

=cut

sub aggregate_filename {
  _agfile_pat(0,@_);
}
sub _agfile_pat {
  my ($fn_or_pat,$name,$pubdir) = @_;
  $fn_or_pat ||= 0;
  $pubdir ||= do {
    my $ftp_root = _conf()->{'ftpsite_root'};
    File::Spec->catdir($ftp_root,'tomato_genome','bacs');
  };
  $pubdir =~ /^\// or confess "malformed pubdir '$pubdir'";
  my $bundle = agfiles_pats()->{$name} #< arrayref of [filename,glob_pattern]
    or croak "unknown file tag '$name'";
  return File::Spec->catfile($pubdir,$bundle->[$fn_or_pat]);
}

=head2 bac_publish

wrapper for CXGN::Publish::publish that tweaks the publishing settings
specially for BACs.  Same usage as that function.

=cut

sub bac_publish {
  my $pub = publisher();
  eval {$pub->publish(@_)};
  croak $EVAL_ERROR if $EVAL_ERROR;
}


=head2 publisher

  Get a CXGN::Publish object that's set up for BAC filenames.

=cut

sub publisher {
  my $pub = CXGN::Publish->new;
  $pub->suffix(bac_suffixes);
  return $pub;
}

=head2 resource_file

  DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED

       use CXGN::Tools::Wget instead, and define a cxgn-resource in
       the public.resource_file table

  DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED

  Usage: my $ests_seq_filename = resource_file('sgn_ests');
  Desc : get a read-only copy of a file that we use as a resource for BAC analysis and publishing
  Ret  : the filename of a local copy of the file, usually a temp file
  Args : the key name of the resource file you want.  available keys are:
           - lycopersicum_combined_unigene_seqs
               FASTA file of the current Lycopersicon combined unigenes
           - repeats_master
               FASTA file of the current tomato genome master repeats set
           - sgn_ests_tomato
               FASTA file of all current SGN tomato ESTs
           - sgn_ests_potato
               FASTA file of all current SGN potato ESTs
  Side Effects: may fetch the file from an external location, may stash it in a temp file.
                files are fetched only the first time they are requested.  thereafter, the
                same local file is returned each time it is requested

  DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED

       use CXGN::Tools::Wget instead, and define a cxgn-resource in
       the public.resource_file table

  DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED

=cut

sub resource_file {
  my ($filetag) = @_
    or croak "must specify the tag of the resource you want";

  my %name_map =  ( lycopersicum_combined_unigene_seqs => 'tomugs' );

  return wget_filter('cxgn-resource://bacpublish_'.($name_map{$filetag} || $filetag));
}

{ my $conf;
  sub _conf {
      $conf ||= CXGN::TomatoGenome::Config->load;
  }
}


=head2 tpf_agp_files

  DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED   DEPRECATED
  DEPRECATED in favor of tpf_file() and agp_file()

  Usage: my ($tpf,$agp) = tpf_agp_files(3);
  Desc : get filesystem paths to the most recent TPF and AGP files for the
         given tomato chromosome.  A value of undef means the file is not present.
  Ret  : two-element list, containing the path to the tpf file (or undef if not present),
         and the path to the agp file (or undef if not present)
  Args : desired chromosome number
  Side Effects: looks in the filesystem

=cut

sub tpf_agp_files {
  my ($chr) = @_;

  return ( tpf_file($chr), agp_file($chr) );
}

=head2 tpf_file

  Usage: my $chr4_tpf = tpf_file(4);
  Desc : get the filename for the TPF file associated with the given
         chromosome number, if present
  Args : chromosome number,
         (optional) true value to return the unpublished filename
                    target for the TPF file,
         (optional) path to TPF publishing dir
  Ret  : filename, or undef if not present
  Side Effects: dies on error

=cut

sub tpf_file {
  my ($chr,$unpublished,$tpf_dir) = @_;

  $chr <= 12 && $chr >= 1
    or croak "chromosome number must be between 1 and 12";

  $chr = sprintf("chr%02d",$chr);

  $tpf_dir ||= File::Spec->catdir( _conf()->{'ftpsite_root'} || die('no ftpsite_root set in VHost config'),
				   'tomato_genome', 'tpf' );

  my $fname = File::Spec->catfile( $tpf_dir, "$chr.tpf" );
  return $fname if $unpublished;

  my $published = CXGN::Publish::published_as($fname);
  return $published && -f $published->{fullpath} ? $published->{fullpath} : undef
}

=head2 agp_file


  Usage: my $chr4_agp = agp_file(4);
  Desc : get the filename for the AGP file associated with the given
         chromosome number, if present
  Args : chromosome number,
         (optional) true value to return the unpublished filename
                    target for the AGP file,
         (optional) path to AGP publishing dir
  Ret  : filename, or undef if not present
  Side Effects: dies on error

=cut

sub agp_file {
  my ($chr,$unpublished,$agp_dir) = @_;

  $chr <= 12 && $chr >= 0
    or croak "chromosome number must be between 0 and 12";

  $chr = sprintf("chr%02d",$chr);

  $agp_dir ||= File::Spec->catdir( _conf()->{'ftpsite_root'} || die('no ftpsite_root set in VHost config'),
				   _conf()->{'agp_publish_subdir'} );

  my $fname = File::Spec->catfile( $agp_dir, "$chr.agp" );
  return $fname if $unpublished;

  my $published = CXGN::Publish::published_as($fname);
  return $published && -f $published->{fullpath} ? $published->{fullpath} : undef
}

=head2 contig_file

  Usage: my $file = contig_file($chr,$unpublished,$contig_dir)
  Desc : get the filesystem path to the most recent published version
         of the contigs file for the given chromosome
  Args : chromosome number or 'all',
         (optional) true value to return the unpublished filename,
         (optional) path to contig publishing directory
  Ret  : list of (contigs filename, pseudomolecule filename, assembly gff3) or undef if not present
  Side Effects: dies on error

=cut

sub contig_file {
  my ( $chr, $unpublished, $contig_dir ) = @_;

  $chr eq 'all' || $chr <= 12 && $chr >= 0
    or croak "chromosome number must be 'all', or between 0 and 12";

  $chr = sprintf("chr%02d",$chr) unless $chr eq 'all';

  $contig_dir ||= File::Spec->catdir( _conf()->{'ftpsite_root'} || die('no ftpsite_root set in VHost config'),
				      _conf()->{'contigs_publish_subdir'},
				    );

  my $contigsfile = File::Spec->catfile( $contig_dir, "$chr.contigs.fasta.gz" );
  my $pmfile = File::Spec->catfile( $contig_dir, "$chr.pseudomolecule".($chr eq 'all' ? 's' : '').'.fasta.gz' );
  my $gff3file = File::Spec->catfile( $contig_dir, "$chr.gff3.gz" );

  return ($contigsfile,$pmfile, $gff3file) if $unpublished;

  return map {
    my $published = CXGN::Publish::published_as($_);
    $published && -f $published->{fullpath} ? $published->{fullpath} : undef
  } ($contigsfile, $pmfile, $gff3file);
}


=head2 genbank_acc_to_seq_name

  Usage: my $name = genbank_acc_to_seq_name('AC123456.1');
  Desc : convert a genbank accession (with or without version)
         to a sequence name
  Ret  : a clone sequence name, or undef if not found
  Args : the genbank accession to look up,
         dbh to use for lookup
  Side Effects: looks things up in the chado db

=cut

sub genbank_acc_to_seq_name {
  my ($acc,$dbh) = @_;
  $dbh or croak "dbh param required";

  my $like;
  unless($acc =~ /\.\d+$/) {
      $like = '~';
      $acc .= '.[0-9]+';
  } else {
      $like = '=';
  }

  my ($seqname) = $dbh->selectrow_array(<<EOQ,undef,('DB:GenBank_Accession',$acc) x 2);
     select f.name, f.timeaccessioned as t
     from public.db db
          join public.dbxref dbx using(db_id)
          join public.feature_dbxref fd using(dbxref_id)
          join public.feature f using(feature_id)
     where
         db.name = ?
       and
         dbx.accession $like ?
   UNION
     select f.name, f.timeaccessioned as t
     from public.db
          join public.dbxref dbx using(db_id)
          join public.feature f using(dbxref_id)
     where
         db.name = ?
       and
         dbx.accession $like ?
   ORDER BY t desc
EOQ
  return $seqname;
}

=head2 seq_name_to_genbank_acc

  Usage: my $acc = seq_name_to_genbank_acc('C01HBa0001A01.1')
  Desc : convert a VERSIONED sequence name to a versioned genbank accession
  Ret  : the versioned genbank accession, or undef if none found
  Args : sequence name,
         dbh to use for lookup
  Side Effects: looks things up in the chado db

=cut

sub seq_name_to_genbank_acc {
  my ($seqname,$dbh) = @_;
  $dbh or croak "dbh param required";

  my ($acc) = $dbh->selectrow_array(<<EOQ,undef,('DB:GenBank_Accession',$seqname) x 2);
   select dbx.accession
   from public.feature f
   join public.feature_dbxref fd using(feature_id)
   join public.dbxref dbx on fd.dbxref_id = dbx.dbxref_id
   join public.db db using(db_id)
   where
       db.name = ?
     and
       f.name = ?
   UNION
   select dbx.accession
   from public.feature f
   join public.dbxref dbx using(dbxref_id)
   join public.db db using(db_id)
   where
       db.name = ?
     and
       f.name = ?
EOQ
  return $acc;
}


=head2 cached_validation_text

  Usage: my $t = cached_validation_text('C01HBa0001A01.tar.gz');

  Desc : get the contents of the BAC pipeline validation cache.
         If a submission on the filesystem has been checked
         before, its validation result will be stored in this cache.
  Args : a filename
  Ret  : if invalid, a string containing the validation text
            (see CXGN::TomatoGenome::BACSubmission::validation_text())
         if valid, an empty string
         if unknown, undef
  Side Effects: none
  Example:

=cut

use constant VALIDATION_VERSION => 2; #< when the BAC validation
                                      # criteria are changed, we can
                                      # just increment this number and
                                      # all thof the current validation
                                      # cache entries are magically
                                      # invalidated

sub cached_validation_text {
  my $val = valcache(@_)
    or return;
  return $val->{text};
}

=head2 cached_validation_errors

  Usage: my @e = cached_validation_errors('C01HBa0001A01.tar.gz');
  Desc : get the contents of the BAC pipeline validation cache.
         If a submission on the filesystem has been checked
         before, its validation result will be stored in this cache.
  Args : a filename
  Ret  : a possibly empty list of CXGN::TomatoGenome::BACSubmission validation error
         constants
  Side Effects: none
  Example:

=cut

sub cached_validation_errors {
  my $val = valcache(@_)
    or return;
  return $val->{errors} ? @{$val->{errors}} : ();
}


#get/set the real contents of the validation cache, only to be used
#from  CXGN::TomatoGenome::BACSubmission
sub valcache {
  my ($filename,$validation) = @_;

  #if the cache dir isn't there, just don't do any caching
  my $cache_dir = File::Spec->catdir( _conf->{'bac_pipeline_dir'},
				      _conf->{'bac_validation_cache'},
				    );
  mkpath($cache_dir); #< attempt to make the dir if not present
  #warn "cache dir is '$cache_dir'";
  return unless $cache_dir && -d $cache_dir && -w $cache_dir;
  return if -f "$cache_dir/expheap.db" && ! -w "$cache_dir/expheap.db";
  #otherwise, continue...

  #normalize the filename used for lookups
  $filename = File::Spec->rel2abs($filename);

  #open our cache if we haven't already
  our $validation_cache ||= Cache::File->new
    (
     cache_root => _conf->{'bac_validation_cache'},
     default_expires => '48 hours',

     #function that tells whether an entry is still valid
     validate_callback => sub {
       my ($entry) = @_;
       my $mtime = (stat $entry->key)[9];
       my $cache_validity = VALIDATION_VERSION.'_'.$mtime;
       return $entry->validity eq $cache_validity;
     }
    );

  return unless $validation_cache;

  if($validation) {
    -f $filename
      or croak "can't find file '$filename'";
#    warn "setting\n";
    my $mtime = (stat $filename)[9];
    my $cache_validity = VALIDATION_VERSION.'_'.$mtime;
    $validation_cache->set($filename,freeze($validation));
    $validation_cache->set_validity($filename,$cache_validity);
  }
#  warn "getting\n";
  return thaw $validation_cache->get($filename);
}

=head2 sequencing_files

  Usage: my %files = sequencing_files( $clone_object, '/path/to/ftpsite/filesystem/root' );
  Desc : get a hash of filesystem paths to sequencing files for this clone
  Ret  : hash-style list as:
         (  seq  => '/data/prod/ftpsite/tomato_genome/bacs/chrXX/CXXblahblah.seq',
            tar  => the tarfile,
            gff3    => the gff3 file of all automatic annotations to this clone,
            gamexml => the gamexml file of all automatic annotations to this clone,

            <analysis_name>_gff3 => gff3 file containing the output from that analysis,
            <analysis_name>_gamexml => game xml file containing the output from that analysis,
         )
         or nothing if the files can't be found
  Args : clone object, root directory of ftp site
  Side Effects: looks things up in the filesystem

=cut

sub sequencing_files {
  my ($clone, $ftp_path) = @_;
  $ftp_path
    or croak "ftp site root path must be passed";

  #get all the files that are published from a bac submission
  my $seqname = $clone->latest_sequence_name
    or return;

  #chop off any fragment ident, AND, this tells us whether the
  #sequences were finished
  my $is_finished =  $seqname !~ s/-\d+$// && ( !$clone->seqprops->{htgs_phase} || $clone->seqprops->{htgs_phase} == 3);
  my %pubfiles = %{publishing_locations("$ftp_path/tomato_genome/bacs",$seqname,$is_finished)};

#   use Data::Dumper;
#   warn Dumper(\%pubfiles);

  #get a BAC publishing object
  my $bacpublisher = publisher();

  #now use the publishing object to resolve the publishing locations
  #to real versioned files.  recall: the iterator variable in a
  #foreach loop is an lvalue, so you can assign to it to modify the
  #contents of the array
  foreach my $pubrecord (values %pubfiles) {
    if( ref($pubrecord) eq 'ARRAY' ) {
      foreach (@$pubrecord) {
	#resolve
#	warn "looking for annot file $_\n";
	my $p = $bacpublisher->published_as($_);
	$_ = $p ? $p->{fullpath} : undef;
      }
    } elsif(! ref $pubrecord) {
      #resolve
#      warn "looking for other file $pubrecord\n";
      my $p = $bacpublisher->published_as($pubrecord);
      $pubrecord = $p ? $p->{fullpath} : undef;
    } else {
      #delete other stuff we don't understand
      $pubrecord = undef;
    }

  }

  #now transform this hash to have the structure specified in the docs
  #for this function
  my %analysis_names_map = (merged => '');
  foreach my $name ( keys %pubfiles ) {
    my $newname = $name;
    if( $newname =~ s/^annot_// ) { #get rid of the annot_ prefix
      #change the name of this analysis if necessary
      $newname = defined($analysis_names_map{$newname})
	? $analysis_names_map{$newname} : $newname;
      $newname &&= $newname.'_';

      my $val = delete $pubfiles{$name};
      @pubfiles{$newname.'gamexml',$newname.'gff3'} = @$val;
    }
  }
  return %pubfiles;
}


=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
