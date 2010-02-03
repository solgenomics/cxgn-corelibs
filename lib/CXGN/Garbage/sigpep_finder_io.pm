#!/usr/bin/perl

# sigpep_finder_io: read either a single plaintext sequence or a series of FASTA-formatted sequences
#
# this package is auxiliary to sigpep_finder/input.pl
#
# author: Evan

# SUBROUTINES
#
#one argument: hashref{strdata => $string [AND/OR] infile => $filehandle}
#reads all input into data structures and calls the parsing function
#throws an Error if no input provided
#sub new()
#
#no arguments; in $self->{str_input} should be all the input
#(either a single plaintext sequence or any number of FASTA sequences)
#just a wrapper for the parsing functions
#sub parse_input_string()
#
#no arguments; in $self->{str_input} should be a single plaintext sequence
#returns a hashref to {sequence header => sequence}, 
#or throws an Error if the sequence is invalid in any way
#sub parse_plaintext_string()
#
#no arguments; in $self->{str_input} should be any number of FASTA sequences
#returns a hashref of the form {sequence header => sequence}, 
#or throws an Error if any sequence is invalid in any way
#sub parse_fasta_string()


###############################################################################################################################################
# NOTE: This module will need to be moved into CXGN when it starts being used. I didn't move it because nothing is using it currently. --John #
###############################################################################################################################################


use strict;
#use CXGN::Page;
use Error {try};

package sigpep_finder_io;
return 1;
my $PKG_NAME = "sigpep_finder_io";

#one argument: hashref{strdata => $string [AND/OR] infile => $filehandle}
#reads all input into data structures and calls the parsing function
#throws an Error if no input provided
sub new
{
	my $class = shift(@_);
	my $data = shift(@_);
	my $obj = {};
	$obj->{alphabet} = "ACDEFGHIKLMNPQRSTVWYacdefghiklmnpqrstvwy"; #a list of all acceptable characters
	$obj->{str_input} = "";
	bless($obj, $class);
	if(exists $data->{strdata}) #read from string
	{
		$obj->{str_input} .= $data->{strdata};
	}
	if(exists $data->{infile}) #read from filehandle
	{
		my @lines = <$data->{infile}>;
		$obj->{str_input} .= join('', @lines);
	}
	if(length($obj->{str_input}) == 0)
	{
		throw Error::Simple("Neither string nor filehandle provided for input.");
	}
	return $obj;
}

#no arguments; in $self->{str_input} should be all the input
#(either a single plaintext sequence or any number of FASTA sequences)
#just a wrapper for the parsing functions
sub parse_input_string
{
	my $self = shift(@_);
	if($self->{str_input} =~ m/^\s*>/) #FASTA
	{
		$self->parse_fasta_string();
		$self->{fasta} = 1;
	}
	else
	{
		$self->parse_plaintext_string();
		$self->{fasta} = 0;
	}
}

#no arguments; in $self->{str_input} should be a single plaintext sequence
#returns a hashref to {sequence header => sequence}, 
#or throws an Error if the sequence is invalid in any way
sub parse_plaintext_string
{
	my $self = shift(@_);
	if($self->{str_input} =~ m/^\s*[$self->{alphabet}]+\*?$/) #legal sequence
	{
		return \{("seq 1", $self->{str_input})};
	}
	else
	{
		throw Error::Simple("Illegal unformatted sequence. Please use the IUPAC amino acid alphabet (see link above).");
	}
}

#no arguments; in $self->{str_input} should be any number of FASTA sequences
#returns a hashref of the form {sequence header => sequence}, 
#or throws an Error if any sequence is invalid in any way
sub parse_fasta_string
{
	my $self = shift(@_);
	my $input = $self->str_input;
	while($input =~ s/^\s*>\s*(.*)\s*\n\s*([$self->{alphabet}]+)\*?\s*\n//) #legal FASTA sequence
	{
		if($1 m/\s*/) #no actual description given; create one
		{
			$1 = "seq" . scalar($self->{fasta_info});
		}
		$self->{fasta_info}->{$1} = $2;
		$input = $'; #remove the matching part of the string so we can keep matching the front
	}
	if($input !~ m/^\s*$/) #some part of the input was formatted illegally; there's non-space left
	{
		throw Error::Simple("Illegal FASTA sequence (seq #$badseq). Please use the IUPAC amino acid alphabet (see link above).");
	}
	return $self->{fasta_info};
}
