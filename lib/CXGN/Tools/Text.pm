
=head1 NAME

CXGN::Tools::Text

=head1 DESCRIPTION

Various tools for interpreting and displaying text strings.

=head1 FUNCTIONS

=head2 list_to_string

Takes a list, puts it into a string with commas and the word "and" before the last item.

=head2 is_all_letters

Takes a string, returns 1 if the string is all letters, 0 if not.

=head2 is_number

Takes a string, tests to see if it meets this pattern: optional + or
-, 0 or more digits, followed by either: "." and one or more digits,
or, just one or more digits. This should catch most normal ways that a
user would enter a number. This function might be improved by
returning the number that was contained in the string instead of just
"1" (in case perl can't cast it on its own... i've never checked to
see if perl can parse an initial "+" for instance)

=head2 trim

Takes a string and returns the string without leading or trailing
whitespaces.

=head2 remove_all_whitespaces

Takes a string and returns it without any whitespaces in it at all
anymore. If you sent in a spaced sentence, your spaces would be
removed.

=head2 strip_unprintables

[NOT YET IMPLEMENTED -apparently as of March 2009] This function is
still under development. It is meant to clean input of escape
characters in preparation for display, database insertion,
etc. However, different machines apparently are working with different
character sets, so the higher characters cannot be cleaned reliably
(when i tried to clean higher characters, this function produced
different output on my machine than it did on the devel machine). For
now, it just cleans out the lower characters.


=head2 abbr_latin

  Desc: abbreviate some latin words in your string and return
        the new abbreviated version
  Args: string
  Ret : string with abbreviations
  Side Effects: none
  Example:

   my $tomato = 'Lycopersicon esculentum';
   my $abbr = abbr_latin($tomato);
   print $abbr,"\n";
   #will print 'L. esculentum'

  Currently abbreviates Solanum, Lycopersicon, Capsicum, Nicotiana,
  and Coffea.

=cut

package CXGN::Tools::Text;
use strict;
use Carp;

BEGIN {
    our @EXPORT_OK = qw/
      list_to_string
      is_all_letters
      is_number
      is_garbage
      trim
      commify_number
      remove_all_whitespaces
      strip_unprintables
      abbr_latin
      to_tsquery_string
      from_tsquery_string
      parse_pg_arraystr
      sanitize_string
      truncate_string
      /;
}
our @EXPORT_OK;
use base qw/Exporter/;

#returns the contents of the array in a string of the form "$_[0], $_[1],...., and $_[end]"
sub list_to_string {
        ( @_ == 0 ) ? ''
      : ( @_ == 1 ) ? $_[0]
      : ( @_ == 2 ) ? join( " and ", @_ )
      :               join( ", ", @_[ 0 .. ( $#_ - 1 ) ], "and $_[-1]" );
}

#test a string to see if it is one continuous string of letters
sub is_all_letters {
    my ($string) = @_;
    if ( defined($string)
        && $string =~ /^[A-Za-z]+$/i
      )    #if there are one or more letters with no spaces in the string
    {
        return 1;
    }
    else { return 0; }
}

#test a string to see if it is a number
sub is_number {
    my ($string) = @_;
    if ( defined($string)
        && $string =~ /^([+\-]?)\d*(\.\d+|\d+)$/
      ) #optional + or -, 0 or more digits, followed by (. and one or more digits) or (just one or more digits)
    {
        return 1;
    }
    else { return 0; }
}

#trim whitespace from string
sub trim {
    my ($string) = @_;
    $string =~ s/^\s+|\s+$//g if defined $string;
    return $string;
}

#remove_all all whitespace in string
sub remove_all_whitespaces {
    my ($string) = @_;
    if ( defined($string) ) {
        $string =~ s/\s+//g;
    }
    return $string;
}

sub abbr_latin {
    my ($string) = @_;
    if ( defined($string) ) {
        $string =~ s/Solanum/S\./g;
        $string =~ s/Lycopersicon/L\./g;
        $string =~ s/Capsicum/C\./g;
        $string =~ s/Nicotiana/N\./g;
        $string =~ s/Coffea/C\./g;
    }
    return $string;
}

=head2 sanitize_string

 Usage:        my $sanitized = sanitize_string($dirty)
 Desc:         removes {, }, <, >, and ; characters from 
               string $dirty and returns the sanitized 
               string.
 Side Effects:
 Example:

=cut

sub sanitize_string {
    my $s = shift;
    $s = trim($s);
    $s =~ s/\}|\{|\>|\<|\;//g;
    return $s;
}


=head2 function format_field_text()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	formats a post or topic text for display. 
                Note that it converts certain embedded tags to 
                html links. This function does not assure security
                - use the get_encoded_arguments in the CXGN::Page 
                object for that purpose.
                
               Tags supported: 
               [url][/url]
               [link][ref][\ref][\link]     the difference between [link] and [ilink] is that [link] add 
               [ilink][ref][\ref][\ilink]   http:// if do not find it. [ilink] not.
               [i][/i]
               \n

=cut


sub format_field_text { 
    my $post_text = shift;
  
    # support vB script url tag
    while ($post_text =~ /\[url\](.*?)\[\/url\]/g ) { 
	my $link = $1;
	my $replace_link = $link;
	if ($link !~ /^http/i) { 
	    $replace_link = "http:\/\/$link"; 
	}
	$link=~ s/\?/\\?/g;
	$post_text =~ s/\[url\]$link\[\/url\]/\<a href=\"$replace_link\"\>$replace_link\<\/a\>/g;
       
    }
    while ($post_text =~ /\[link\](.*?)\[ref\](.*?)\[\/ref\]\[\/link\]/g ) { 
	my $link = $1;
	my $ref=$2;
	my $replace_link = $link;
	if ($link !~ /^http/i) { 
	    $replace_link = "http:\/\/$link"; 
	}
	$link=~ s/\?/\\?/g;
	$post_text =~ s/\[link\]$link\[ref\]$ref\[\/ref\]\[\/link\]/\<a href=\"$replace_link\"\>$ref<\/a\>/g;
    }
    ## New tag, internal link. [ilink] that works in the same way that link but do not any http:// if do not find it
    while ($post_text =~ /\[ilink\](.*?)\[ref\](.*?)\[\/ref\]\[\/ilink\]/g ) {
        my $link = $1;
        my $ref=$2;
        my $replace_link = $link;
        $link=~ s/\?/\\?/g;
        $post_text =~ s/\[ilink\]$link\[ref\]$ref\[\/ref\]\[\/ilink\]/\<a href=\"$replace_link\"\>$ref<\/a\>/g;
    }
    # italics tag
    while ($post_text =~ /\[i\](.*?)\[\/i\]/g ) { 
	my $itext = $1;
	my $replace_text = $itext;
	
	$itext=~ s/\?/\\?/g;
	$post_text =~ s/\[i\]$itext\[\/i\]/\<i\>$replace_text\<\/i\>/g;
    }
    # convert newlines to <br /> tags
    #
    $post_text =~ s/\n/\<br \/\>/g;
    return $post_text;
}



=head2 to_tsquery_string

  Desc: format a plain-text string for feeding to Postgres to_tsquery
        function
  Args: list of strings to convert
  Ret : in scalar context: the first converted string,
        in list context:   list of converted strings
  Side Effects: none
  Example:

    my $teststring = 'gi|b4ogus123|blah is bogus & I hate it!';
    to_tsquery_string($teststring);
    #returns 'gi\\|b4ogus123\\|blah|is|bogus|\\&|I|hate|it\\!'

=cut

sub to_tsquery_string {
    ($_) = @_;

    $_ = trim($_);

    # Escape pipes
    s/\|/\\\|/g;

    # Escape ampersands and exclamation points
    s/([&!])/\\\\$1/g;

    # Escape parentheses and colons.
    s/([():])/\\$1/g;

    # And together all strings
    s/\s+/&/g;
    return $_;
}

=head2 from_tsquery_string

  Desc: attempt to recover the original string from the product
        of to_tsquery_string()
  Args: list of strings
  Ret : list of de-munged strings
  Side Effects: none
  Example:

=cut

sub from_tsquery_string {
    my @args = @_;

    foreach (@args) {
        next unless defined $_;
        s/(?<!\\)&/ /g;        #& not preceded by backslashes is a space
        s/\\\\([^\\])/$1/g;    #anything double-backslashed
        s/\\(.)/$1/g;          #anything single-backslashed
    }
    return wantarray ? @args : $args[0];
}

=head2 parse_pg_arraystr

  Usage: my $arrayref = parse_pg_arraystr('{1234,543}');
  Desc : parse the string representation of a postgres array, returning
         an arrayref
  Args : string representation of postgres array
  Ret  : an arrayref
  Side Effects: none

=cut

sub parse_pg_arraystr {
    my ($str) = @_;

    return [] unless $str;

    my $origstr = $str;

    #remove leading and trailing braces
    $str =~ s/^{//
      or croak "malformed array string '$origstr'";
    $str =~ s/}$//
      or croak "malformed array string '$origstr'";

    return [
        do {
            if ( $str =~ /^"/ ) {
                $str =~ s/^"|"$//g;
                split /","/, $str;
            }
            else {
                split /,/, $str;
            }
          }
    ];
}


=head2 commify_number

  Args: a number
  Ret : a string containing the commified version of it

  Example: commify_number(230400) returns '230,400'

=cut

sub commify_number {
  local $_  = shift;
  return undef unless defined $_;
  1 while s/^(-?\d+)(\d{3})/$1,$2/;
  $_;
}


=head2 truncate_string

  Desc:	truncate a string that might be long so that it fits in a manageable
        length, adding an arbitrary string (default '&hellip;') to the end if
        necessary.  If the string is shorter than the given truncation
        length, simply returns the string unaltered.  If the truncated
        string would have whitespace between the end of the given
        string and the addon string, drops that whitespace.
  Args: string to truncate, optional truncation length (default 50),
        optional truncation addon (default '...')
  Ret :	in scalar context:   truncated string
        in list context:     (truncated string,
			      boolean telling whether string was truncated)

  Example:
    truncate_string('Honk if you love ducks',6);
    #would return
    'Honk i&hellip;'

    truncate_string('Honk if you love cats',5);
    #would return
    'Honk&hellip;'
    #because this function drops trailing whitespace

=cut

sub truncate_string {
  my ($string,$length,$addon) = @_;
  $length ||= 50;
  $addon ||= '...';

  my $was_truncated = 0;
  if( length($string) > $length) {
    $string = substr($string,0,$length).$addon;
    $was_truncated = 1;
  }

  return wantarray ? ($string,$was_truncated) : $string;
}

=head1 AUTHOR

john binns - zombieite@gmail.com
Robert Buels - rmb32@cornell.edu

=cut

###
1;    #do not remove
###
