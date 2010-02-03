package CXGN::Tools::Tsearch;
use strict;
use warnings;

=head1 NAME

Functions for working with the Postgres tsearch module used for text indexing 

=head1 SYNOPSIS


=head1 DESCRIPTION
 
=head1 Authors

Naama Menda (nm249@cornell.edu)

=cut


=head2 process_string

 Usage: CXGN::Tsearch::process_string('some string' , 1)  
 Desc:  a class function for preparing a string for matching to a tsvector field
 Ret:   a processed string
 Args:  string , and optional flag for removing spaces and dots      
 Side Effects:
 Example:

=cut

sub process_string {
    my $string = shift;
    my $spaces=shift;
   
    if ($spaces) {  
	print STDERR "process string about to replace spaces and dots for string $string ...\n";
	$string =~ s/\s//g;  #replace spaces with nothing
	$string =~ s/\.//g;  #replace dots with nothing - important for a multiple synonym string
    }

    $string =~ s/\(.*?\)//g;
    $string =~ s/\s/&/g;
    $string =~ s/:/&/g;
    $string =~ s/&+/&/g;
    $string =~ s/((\`.*?&)|(\'.*?&))/&/g;
    $string =~ s/((\`.*?$)|(\'.*?$))//g;
    $string =~ s/^&|&$//;
    $string =~ s/\(|\)//g;
    $string =~ s/\^//g;

    #$cvterm_hash->{name} =~ s/(.+?)\s\b(\w*)\/(\w*)\b/$1&$2|$1&$3/;
    return $string;
}


=head2 do_insert

 Usage: $cvterm->do_insert($match_type, [pub_id, rank, headline] )
 Desc:  insert a new cvterm_pub_rank  or a locus_pub_rank
 Ret:   number of lines stored in _pub_rank table
 Args:  match_type and list of lists
 Side Effects: calls the store function
 Example:

=cut

sub do_insert {
    my $self=shift;
    my $match_type=shift;
    my $array_ref=shift;
    my @array = @$array_ref;
    my $count=0;
    
    for my $ref(@array)  {
	my $pub_id = @$ref[0];
	my $rank= @$ref[1];
	my $headline=@$ref[2];
	
	#Check that there is not already a locus-publication link with this match type:
	#Look at the match_type of each row where locus_id and pub_id match the current ones.
	#If any of these are "name_abstract" then we do not insert our result into the table.
	$self->set_pub_id($pub_id);
	$self->set_rank($rank);
	$self->set_match_type($match_type);
	
	$headline =~ s/\'//g; #gets rid of single quotes from headline text
	$self->set_headline($headline);
	my $store= $self->store(); #store function should call exists function!
	if ($store) { $count++ ; }
    }
    #if (!$array) { $array=0 ; }
    print STDERR "Found " .scalar(@array) . " lines. Inserted $count $match_type rows into _pub_ranking table**\n";
    return $count;
}


return 1;
