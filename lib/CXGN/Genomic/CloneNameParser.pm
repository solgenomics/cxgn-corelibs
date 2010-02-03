package CXGN::Genomic::CloneNameParser;
use strict;
use English;
use File::Basename;

use Bio::DB::GenBank;

use CXGN::Genomic::CloneIdentifiers qw/parse_clone_ident/;

=head1 NAME

DEPRECATED  Use L<CXGN::Genomic::CloneIdentifiers> instead.

CloneNameParser.pm - DEPRECATED object that knows how to parse clone names,
chromatogram filenames, etc.

DEPRECATED  Use L<CXGN::Genomic::CloneIdentifiers> instead.

=head1 SYNOPSIS

my $parse = new CXGN::Genomic::CloneNameParser;
my $filetype='seqwright_bac_chromat_file';
my $chromat_info = $parse->$filetype($pathname);

=head1 DESCRIPTION

This file contains a number of functions for parsing filenames
that contain library shortnames, plate numbers, well coordinates,
and sequencing primer names.

Each takes a path to a file and returns a hash ref as:

=over 4

  lib       => shortname of the corresponding Library Object
  plate     => plate number,
  row       => row (usually a letter A-Z),
  col       => column number,
  clonetype => shortname of the corresponding CloneType object,
  match     => the substring in the input that contained the parsed name

In addition, parser functions are free to add additional hash keys
to this to add things like file paths, primer names, etc.

Notice that the lib and clonetype entries do not contain the actual
CloneType and Library objects for this clone.  This is a parser, not
a data fetcher.  You will have to restore those objects yourself if you
want them.

=head1 PARSERS

Currently available object methods to parse names are:

=cut

BEGIN {
    use Exporter;
    our $VERSION = 0.3;
    our @EXPORT = qw/is_valid_filename_type list_filename_types chromat_file_suffix_patterns/;
}

		
my @name_types = qw/
		    seqwright_bac_chromat_file
		    AGI_clone_name
		    BAC_end_external_identifier
		    clone_name_with_chromosome
		    clone_sequence_identifier
		    old_cornell_bac_name
		   /;
			
our $sep = '[^a-z\d\/]?';
	
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  ### allocate a hash for the object's data ###
  my $this = {};
  bless $this, $class;

  return $this;
}

=head2 seqwright_bac_chromat_file

Parses BAC chromatogram filenames in some variation of
the form 'LE_HBa_033_O23'.

Returns the following hash keys in addition to the
common keys above:

  path     => the directory path part of the given file name
  primer   => the sequencing primer used
  suffix   => file suffix (the final '.' is taken to be the
              start of the suffix), or '' if none
  filename => basename of the given filename

=cut

sub seqwright_bac_chromat_file {
    my $this = shift;
    my $pathname = shift;
    chomp $pathname;

    my ($filename,$location,$suffix) = fileparse($pathname,
						 $this->chromat_file_suffix_patterns);

    #format the bac name to agree with how we have it in the DB
    my ($bacname,$read_primer) = $filename =~ /([\w\d-]+)-(SP6|T7)/;
    $read_primer || die "Malformed input name '$filename'";
    my %directions = (T7 => 5, SP6 => 3);
    my $direction = $directions{$read_primer}
      or die "Invalid primer '$read_primer'";

    my $firstmatch = $MATCH;
    return undef unless (my $agi_info = $this->AGI_clone_name($bacname));

    return { %$agi_info,
	     path     => $location,
	     suffix   => $suffix,
	     primer   => $read_primer,
	     filename => $filename,
	     match    => $MATCH,
	   };
}

=head2 BAC_end_external_id

Parses BAC end identifiers in approximately the form 'LE_HBa0033_A13_T7_6553'.

=cut

sub BAC_end_external_id {
    my ($this,$name) = @_;

    return parse_clone_ident($name,'bac_end');
}

=head2 AGI_clone_name

Parses AGI clone names in approximately the form 'LE_HBa0033_O23'.

=cut

sub AGI_clone_name {
    my ($this,$name) = @_;

    return parse_clone_ident($name,'agi_bac');
}

=head2 genbank_accession

  Usage: my $parsed = $parser->genbank_accession('CT990638')
  Desc : looks up (via a web service) the given identifier in genbank,
         parses its record to figure out which bac clone it belongs
         to, then returns that information
  Ret  : hashref with all of the common keys above
  Args : a single genbank accession string
  Side Effects: looks things up over the web

=cut

sub genbank_accession {
  my ($self,$accession) = @_;

  $accession =~ s/\.\d+$//; #chop off any genbank version ident

  return parse_clone_ident($accession,'genbank');
}

=head2 old_cornell_bac_name

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

sub old_cornell_bac_name {

    my ($this,$name) = @_;

    return parse_clone_ident($name,'old_cornell');
}

=head2 clone_name_with_chromosome

  Desc: parse a clone name with chromosome, of the form 'C01HBa0111D09'
  Args: a string containing a clone name
  Ret : a hash ref containing whatever we could parse out of it,
        with keys qw/ lib plate row col clonetype chr version fragment/,
        with chr being the chromosome number, version being the sequence
        version (if given), and fragment being the fragment number, if
        this sequence is from an unfinished bac
  Side Effects: none
  Example:

=cut

sub clone_name_with_chromosome {
  my ($this,$name) = @_;

  my $p = parse_clone_ident($name,'versioned_bac_seq','agi_bac_with_chrom')
    or return;

  #now fix up some little impedence mismatches between this old version and the new
  $p->{version} ||= undef;
  $p->{fragment} ||= undef;
  delete $p->{clone_name};
  return $p;
}

=head2 clone_sequence_identifier

  Usage: my $parsed = $parser->clone_sequence_identifier('C02HBa1234A12.17-2');
  Desc : parse a BAC sequence identifier like C02HBa1234A12.17-2
  Ret  : everything clone_name_with chromosome returns,
         plus clone_name, fragment and version
  Args : identifier to parse

=cut

sub clone_sequence_identifier {
  my ($self,$ident) = @_;

  return parse_clone_ident($ident,'versioned_bac_seq');
}


=head1 OTHER FUNCTIONS

Additionally, CloneNameParser.pm exports
by default the following utility functions:

=head2 is_valid_name_type

Given the name of a filename type, returns true if that is a
valid filename type.

=cut

sub is_valid_name_type {
    return (scalar(grep($_[0],@name_types)) != 0);
}


=head2 list_name_types

Returns a list of valid filename types.

=cut

sub list_name_types {
    return @name_types;
}

=head2 chromat_file_suffix_patterns

Returns a list of quoted patterns usable for matching suffixes of chromatogram
filenames.

=cut

sub chromat_file_suffix_patterns {
  ( qr/(\.esd|\.ab.|\.scf)?(\.gz)?$/ )
}

=head1 AUTHOR

    Robert Buels


=cut

####
1; # do not remove
####
