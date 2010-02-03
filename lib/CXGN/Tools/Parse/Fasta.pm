
package CXGN::Tools::Parse::Fasta;
use strict;

use base qw/CXGN::Tools::Parse/;

=head1 CXGN::Tools::Parse::Fasta

 Two reasons for SGN to have its own Fasta parser:
 1) CXGN Identifier/Species convention: i.e.: >AT1G01010.1 / Arabidopsis T.
 2) BioPerl sucks


=head1 Author

C. Carpita

=cut


sub next {
	my $self = shift;
	my $data = $self->{data_to_parse};
	my $fh = $self->{fh};
	my $entry = { id => '', species => '', seq => '' };
	
	if($fh){
		my $entry_filled = 0;
		until($entry_filled){
			my $line = "";
			if($self->{previous_line}){
				$line = $self->{previous_line};
				$self->{previous_line} = "";
			}
			else{
				$line = <$fh>;
				last unless $line;
			}
			next if $line =~ /^\s*$/;
			unless ($entry->{id}) {
				chomp $line;
				my ($id) = $line =~ /^>([^\/\s]+)/;
				my ($species) = $line =~ /^>\Q$id\E\s*\/\s*([^|]*)/;
				my $annotation = " "; 
				($annotation) = $line =~ /^>\Q$id\E\s*(.*)$/;
#print "annotation [$annotation] \n";
				$annotation =~ s/\s*\/\s*\Q$species\E// if($annotation  and  $species); # don't do if empty string - to avoid warning messages
				$entry->{id} = $id if $id;
				$entry->{species} = $species if $species;
				$entry->{annotation} = $annotation if $annotation;
				$entry->{defline} = $line;
			}
			else {
				chomp $line;
				if ($line =~ /^>/){
					$self->{previous_line} = $line;
					$entry_filled = 1;
				}
				else {
					$line =~ s/\s+//g;
					$line =~ s/\*//g; #ends protein sequences sometimes...
					$entry->{seq} .= $line;  #eehhh, probably a sequence
				}
			}
		}
	}
	elsif($data){
		my ($id) = $data =~ /^.*>([^\/\s]+)/;
# print "In fasta next. data $data id [$id]\n"; 
		my ($species) = $data =~ /^.*>\Q$id\E\s*\/\s*(.*?)\n/;
# print "In fasta next. data $data species [$species]\n"; 
		$data =~ s/^.*>\Q$id\E.*?\n//;
		return unless $id;
		$entry->{id} = $id if $id;
		$entry->{species} = $species if $species;
		my ($seq) = $data =~ /([\w\n\-\*]+)/;
		$seq =~ s/\n//g;
		$seq =~ s/\*//g;
		$data =~ s/[\w\n\-\*]+//;
		$entry->{seq} = $seq;
		$entry->{data_to_parse} = $data;
	}
	return $entry if ($entry->{id} && $entry->{seq});
}

sub parse_all_data {
	return undef;
}


1;
