
=head1 NAME

CXGN::Tools::File::Spreadsheet

=head1 DESCRIPTION

Loads a tab delimited (or comma delimited or whatever) and newline delimited file (such as an xls spreadsheet exported to csv) into a structure in memory and provides random access to it.

This module makes several assumptions about the structure of your delimited text file spreadsheet:

- There must be a row of values, before all actual values, which can serve as labels for every column

- There must be a column of values, before all actual values, which can serve as labels for every row

- All columns must be separated by tabs or some other delimiter

- All rows must be separated by newlines

- Quoted values, especially quoted values containing the delimiter, are not supported

- All columns must be labeled, including the column which contains the row labels (the first column in the spreadsheet, that is, usually)

- Unlabeled columns (or values which go beyond the column labels) are not supported and in this case the object's behavior may be bizarre

- Duplicated column names are not supported and in this case the object's behavior may be bizarre 

=head1 OBJECT METHODS

=head2 new

    my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($TAB_DELIMITED_FILE_NAME);
    #optional additional parameters are:
    # - rows to skip before we hit the row containing the column names
    # - columns to skip throughout the spreadsheet
    # - delimiter which separates data on individual lines (line delimiter is currently assumed to be newline)

=head2 as_string

    print $spreadsheet->as_string();
    #this string is not an exact duplicate of the file you used to load the object:
    # - skipped rows and columns will not be present 
    # - row names are sorted
    # - delimiters, newlines, etc. may not be exactly the same

=head2 column_labels

    print join("\n",$spreadsheet->column_labels());

=head2 row_labels

    print join("\n",$spreadsheet->row_labels());

=head2 value_at

    print $spreadsheet->value_at('At5g67620.1','pepper');

=head2 is_garbage

Send in a string, and it returns 1 if the string contains useless stuff, or 0 if it is useful. This may be extended someday so you can define what "garbage" means to you. Right now it just takes spaces and/or hyphens as garbage.

=head1 AUTHOR

john binns - John Binns <zombieite@gmail.com>

=cut

package CXGN::Tools::File::Spreadsheet;
use strict;
use CXGN::Tools::Text;
sub new
{
    my $class=shift;
    my $self=bless({},$class);
    ($self->{filename},$self->{skip_rows},$self->{skip_columns},$self->{delimiter})=@_;
    $self->{skip_rows}||=0;
    $self->{skip_columns}||=0;
    $self->{delimiter}||="\t";
    $self->{skip_rows}>=0 or die"Skip rows ('$self->{skip_rows}') cannot be negative";
    $self->{skip_columns}>=0 or die"Skip columns ('$self->{skip_columns}') cannot be negative";
    my($FILE,$column_counter,$column_name,$line_string,@line);
    open($FILE,$self->{filename}) or die"Cannot open file '$self->{filename}'";
    #skip any header rows, but not column names
    for(1..$self->{skip_rows})
    {
        $line_string=<$FILE>;
    }
    #get column names from top line
    @line=$self->_grab_line($FILE);
    $column_counter=0;
    while($column_name=shift(@line))
    {
        $self->{column_labels}->[$column_counter]=$column_name;
        $column_counter++;
    }
    $column_counter>0 or die"No columns found in spreadsheet file '$self->{filename}'";
    #get data from spreadsheet 
    my $row=0;
    while(@line=$self->_grab_line($FILE))
    {
        $row++;
        my $row_label=$line[0];
        $row_label or die"Row found without a row label in spreadsheet file '$self->{filename}' line $row";
        for(0..$#{$self->{column_labels}})
        {
            $self->{spreadsheet}{$row_label}{$self->{column_labels}[$_]}=$line[$_];
        }
    }
    close($FILE);
    return $self;
}
sub _grab_line
{
    my $self=shift;
    my($FILE)=@_;
    my $line_string=<$FILE> or return;
    chomp($line_string);
    my @line=split(/$self->{delimiter}/,$line_string);
    #remove skipped columns
    for(1..$self->{skip_columns})
    {
        shift(@line);
    }
    #clean up what's left
    for(0..$#line)
    {
        $line[$_]=CXGN::Tools::Text::trim($line[$_]);
        if(&is_garbage($line[$_]))
        {
            $line[$_]='';
        }
    }
    return @line;
}
#test a string to see if it just has hyphens and/or white spaces from start to finish. REPEAT: HYPHENS COUNT AS GARBAGE.
sub is_garbage
{
    my($string)=@_;
    if(!defined($string) or $string=~/^[\s\-]*$/)
    {
        return 1;
    }
    else{return 0;}    
}
sub as_string
{    
    my $self=shift;
    my $spreadsheet='';
    $spreadsheet.=join($self->{delimiter},@{$self->{column_labels}})."\n";
    for my $row_label(sort {$a cmp $b} keys(%{$self->{spreadsheet}}))
    {
        for(0..$#{$self->{column_labels}})
        {
            $spreadsheet.=($self->{spreadsheet}{$row_label}{$self->{column_labels}[$_]} or '');
            if($_<$#{$self->{column_labels}})
            {
                $spreadsheet.=$self->{delimiter};
            }
            else
            {
                $spreadsheet.="\n";
            }
        }
    }
    return $spreadsheet;
}
sub column_labels
{
    my $self=shift;
    return @{$self->{column_labels}};
}
sub row_labels
{
    my $self=shift;
    return sort {$a cmp $b} keys(%{$self->{spreadsheet}});
}
sub value_at
{
    my $self=shift;
    my($row_label,$column_label)=@_;
    unless(exists($self->{spreadsheet}{$row_label})){die"Row label '$row_label' does not exist in spreadsheet '$self->{filename}'";}
    unless(exists($self->{spreadsheet}{$row_label}{$column_label})){die"Column label '$column_label' does not exist in spreadsheet '$self->{filename}'";}
    return $self->{spreadsheet}{$row_label}{$column_label};
}
1;
