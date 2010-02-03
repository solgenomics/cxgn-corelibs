use strict;

use Test::More tests => 1;
#use Bio::SeqIO;

use_ok('CXGN::Cluster::Match');

# my $in = Bio::SeqIO->new(-format=>"fasta", -file=>"chr1.fas"); #"C01HBa0163B20.1.v3.seq");
# my $bac = $in->next_seq();
# my $subject = $bac->seq();
# my $query = "GTGAAGAGGGAAAGAAACCCAATACCATGCTTGGGAAACATA"; #"ATTACATATAGCATATCATTCTTTGAGCACTCAGGAATAACCCTTATCA"; #GGGATGGAGCACTCAGGG";
# #my $subject = "CCCCCCATGGAGCACTCACAGCCCCCCCCCCCCCCC";

# my $align = CXGN::Cluster::Match->new(1);
# $align -> set_word_size(12);
# $align -> set_query($query);
# $align -> set_subject($subject);

# my @matches = $align->match_sequences();

# print "\n\nReport\n\nQuery  : $query\nSubject: \$subject\n\nCommon substrings: \n";
# foreach my $m (@matches) { 
#     print join ", ", @$m;
#     print "\n";
# }
#     print "\nDone.\n";
