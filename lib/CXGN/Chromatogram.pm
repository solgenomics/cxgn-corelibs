#!/usr/bin/perl
package CXGN::Chromatogram;
use CXGN::Chromatogram::Draw;
use SGN::Context;
use strict;
use warnings;

BEGIN {
    our @ISA = qw/Exporter/;
    use Exporter;
    our $VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)/g;
    our @EXPORT_OK = qw/create_image_file render_chromat_image/;
}
our @ISA;
our @EXPORT_OK;

sub create_image_file 
{
    my($chromat_file,$temp_image_filename,$width,$height,$temp_path_for_output,$temp_path_for_display,$phred_path)=@_;
    my $message='';
    if(!$temp_image_filename)
    {
        die("create_image_file: No temporary image filename specified");
    }
    $height||=120;
    $width||=720;
    my $context = SGN::Context->new;
    my $website_path= $context->get_conf('basepath');
    $temp_path_for_display ||= $context->tempfiles_subdir('traceimages');
    $temp_path_for_output  ||= $website_path.$temp_path_for_display;
    $phred_path||='/usr/bin/';
    #image may already exist
    if(-f($temp_path_for_output.$temp_image_filename))
    {
        return($temp_path_for_display.$temp_image_filename);
    }
    #execute image creation script. if it returns a positive number (error code)...
    if(CXGN::Chromatogram::Draw::ABI_Display('-a',$chromat_file,'-o',$temp_path_for_output.$temp_image_filename,'-t',$temp_path_for_output,'-h',$height,'-w',$width,'-phred_path',$phred_path))#if(system("$website_path/programs/ABI_Display.pl -a $chromat_file -o $temp_path_for_output$temp_image_filename -t $temp_path_for_output -h $height -w $width -phred_path $phred_path"))
    {
        #then try it without phred. if it returns a positive number (error code)...
        if(CXGN::Chromatogram::Draw::ABI_Display('-a',$chromat_file,'-o',$temp_path_for_output.$temp_image_filename,'-t',$temp_path_for_output,'-h',$height,'-w',$width))#if(system("$website_path/programs/ABI_Display.pl -a $chromat_file -o $temp_path_for_output$temp_image_filename -t $temp_path_for_output -h $height -w $width"))
        {
            die("CXGN::Chromatogram::Draw::ABI_Display failed.");
        }
    }
    #check to make sure the image file is really there before returning a path to it
    if(-f($temp_path_for_output.$temp_image_filename))
    {
        return($temp_path_for_display.$temp_image_filename);
    }
    else
    {
        die("ABI_Display.pl executed successfully but temporary image file not found.");
    }    
}

#to tell if we have an abi chromatogram we can display, we must do the following:
#
#1. see if there is a database entry claiming we have one
#2. use the incomplete filename in the database entry to guess what the full filename is (find_chromat_file)
#3. uncompress it if it is compressed (uncompress_if_necessary)
#4. figure out if the uncompressed file is indeed an abi file (is_abi_file)
sub has_abi_chromatogram
{
    my($read_id)=@_;
    my $context = SGN::Context->new;
    my $trace_basepath=$context->get_conf('trace_path');
    my $temp_image_path=$context->tempfiles_subdir('traceimages');
    if(!defined($read_id)||$read_id!~m/^[0-9]+$/){return;}
    my $dbh=CXGN::DB::Connection->new();
    my $traceq=$dbh->prepare("SELECT trace_location,trace_name from seqread where read_id=?");
    $traceq->execute($read_id);
    my($path,$name)=$traceq->fetchrow_array();
    unless($path and $name)
    {
        return;
    }
    my $basename=$trace_basepath."/$path/$name";
    my $full_pathname=CXGN::Chromatogram::find_chromat_file($basename); 
    if(!$full_pathname) 
    {
        #CXGN::Apache::Error::notify("could not find an abi chromatogram","Can't find chromatogram file at $path for trace $name, read id $read_id. Data in seqread table appears incorrect.\n");
        return;
    }
    my $tmp_tracename="SGN-T$read_id.mct";#"mct"="mystery chromatogram type" ;-) --john
    CXGN::Chromatogram::uncompress_if_necessary($full_pathname,$context->get_conf('basepath')."$temp_image_path/$tmp_tracename");
    return CXGN::Chromatogram::is_abi_file($context->get_conf('basepath')."$temp_image_path/$tmp_tracename");    
}

#chromats are hidden with obscure names and unspecified extensions, and we must try to find them. yay!
sub find_chromat_file
{
    my ($basename)=@_;
    # KONI's explanation of this: 
    # "The actual extension used should have been stored in the database, but it
    # was not. This is because most chromatograms we had at the start did not have
    # an extension. Overtime, it became clear that preserving the facility's 
    # specified filename is necessary, thus conventions for file extenstions are
    # not standardized. This nested loop below wastes some time, but is arguably
    # robust and easily extended to new types.
    #
    # find the actual file location using the partially specified filename by looking through all possible extensions
    my $full_pathname; 
    TYPELOOP:
    foreach my $type_ext('',qw/.ab1 .abi .esd .SCF .scf/)
    {
        foreach my $comp_ext('',qw/.gz .Z .bz2/)
        {
            if(-f($basename.$type_ext.$comp_ext))
            {
                $full_pathname=$basename.$type_ext.$comp_ext;
                last TYPELOOP;
            }
        }
    }
    return $full_pathname;
}

#chromats are usually zipped but i don't know if they always will be
sub uncompress_if_necessary
{
    my ($source,$dest)=@_;
    #if unzipping returns an error, it is usually because it is not zipped
    if(system("gzip -dc $source > $dest"))
    {
        #so try to copy it instead
        my $copy_command="cp $source $dest";
        if(system($copy_command))
        {
            die "could not copy chromatogram, Could not do '$copy_command': $!";
        }
    }
}

#code snippet excised from ABI_Display.pl. 
sub is_abi_file
{
    my($file)=@_;
    open(ABIFile,$file) or return;
    binmode ABIFile,":raw";
    my $CheckString;
    seek ABIFile,0,0;
    read(ABIFile,$CheckString,4);
    if($CheckString eq 'ABIF')
    {
        close ABIFile;
        return $file;
    }
    else 
    {
        seek ABIFile,128,0;
        read(ABIFile,$CheckString,3);
        if($CheckString eq 'ABI') 
        {
            close ABIFile;
	    return $file;
        }     
        else 
        {
            close ABIFile;
            return;
        }
    }
}
###
1;# do not remove
###
