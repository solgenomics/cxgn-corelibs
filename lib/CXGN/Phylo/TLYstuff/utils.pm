#!/usr/bin/perl
use strict;
use warnings;

package Utils;

# read fasta from file with file handle $filehandle
# # read $max_sequences sequences at concatenate to $chunk_sequence
# # unless hit eof
# # return the chunk sequence, first line of next chunk (which is undef if no next chunk)
# chunk_sequences keeps the newlines as in input


sub get_next_chunk{
	my $filehandle = shift;
	my $max_sequences = shift;
	my $chunk_sequence = shift;
	$chunk_sequence ||= "";
	my $seqs_in_chunk = ($chunk_sequence eq "")? 0: 1;

	while (<$filehandle>) {
		if (/^\s*>/) {                                          # next id line
			$seqs_in_chunk++;  
			if ($seqs_in_chunk > $max_sequences) { # this id belongs to the next chunk
				return ($chunk_sequence, $_);
			}
		}
		$chunk_sequence .= $_;
	}
	return ($chunk_sequence, undef);
}



1;

