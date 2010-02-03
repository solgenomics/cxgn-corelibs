package CXGN::Tools::File::Text;
use strict;
use CXGN::Tools::Text;
sub txt_convert#convert a file from pc or mac text file format to unix
{
    my($filename)=@_;
    my $FILE;
    open($FILE,"<$filename") or die("Cannot open $filename for reading.\n");
    local $/=undef;
    my $file_contents=<$FILE>;
    close $FILE;
    $file_contents=~s/\r\n/\n/g;#replace \r\n with \n
    $file_contents=~s/\r/\n/g;#replace any remaining \r with \n
    open($FILE,">$filename") or die("Cannot open $filename to overwrite.\n");
    print $FILE $file_contents;
    close $FILE;
}
1;
