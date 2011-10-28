package CXGN::Glossary;
use CXGN::DB::Connection;

=head1 NAME

CXGN::Glossary  -- Helper functions for querying the glossary database.

=head1 SYNOPSIS

Allows a list of definitions for a term to be searched and for the first of
those definitions to be put into a toolip.

=head1 FUNTIONS

All functions are EXPORT_OK.

=over 4

=cut

BEGIN {
    our @ISA = qw/Exporter/;
    use Exporter;
    our $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
    our @EXPORT_OK = qw/  get_definitions get_glossary_tooltip create_tooltips_from_text/;
}
our @ISA;
our @EXPORT_OK;

sub get_definitions{
    my $dbh=CXGN::DB::Connection->new();
    my $term = $_[0];
    $term = lc($term);
    $term =~ s/\s+/ /g;
    $term =~ s/^\s+//;
    $term =~ s/\s+$//;
    my $terms = $dbh->selectall_arrayref("select definition from glossary where ? ilike term", undef, $term);
    my @definitions;
	for(my $i = 0; $i < @{$terms}[$i]; $i++){
	    $definitions[$i] = $terms->[$i][0];
    }
    return @definitions;
}

sub get_glossary_tooltip{
    my $term = $_[0];
    my @defs = get_definitions($term);
    if(@defs == 1){
	return tooltipped_text($term, $defs[0]);
    }
    elsif(@defs > 1){
	return tooltipped_text("<a href = \"glossarysearch.pl?getTerm=$term\">$term</a>",$defs[0]."<br />See link for more definitions.");
    }
    else{
	return $term;
    }
}
#Doesn't work, should take a paragraph of text and make a tooltip for
#every word that is in the database.
sub create_tooltips_from_text{
    my @words = split(" ", $_[0]);
    my $text;
    for $word(@words){
	$text .= " " . get_glossary_tooltip($word);
    }
    return $text;
}

1;
