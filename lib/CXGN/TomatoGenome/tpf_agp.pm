#this file just contains several subroutines shared by the tpf and agp scripts
package CXGN::TomatoGenome::tpf_agp;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
		    format_validation_report
		    filename
		    published_ftp_download_links
		    tabdelim_to_html
		    tabdelim_to_array
		    modtime_string
		    other_resources_html
		   );

use POSIX;

use HTML::Entities;

use CXGN::TomatoGenome::BACPublish qw/tpf_agp_files/;
use CXGN::Tools::List qw/max str_in/;
use CXGN::Tools::Identifiers qw/link_identifier/;

sub modtime_string {
  my ($filename) = @_;
  return $filename ?
      "last modified ".asctime(gmtime((stat($filename))[9])).' GMT'
    : '';
}

sub format_validation_report {
  my @errors = @_;
  return "<ul>\n".join('',map {"<li>".HTML::Entities::encode($_)."</li>\n"} @errors)."</ul>\n";
}

sub filename {
  my ($chr,$type) = @_;
  our $vhost ||= CXGN::VHost->new;
  $chr = sprintf("chr%02d",$chr);
  return File::Spec->catfile( $vhost->get_conf('ftpsite_root') || die('no ftpsite_root set'),
			      'tomato_genome',
			      $type,
			      "$chr.$type",
			    );
}
sub published_ftp_download_links {
  my ($chr) = @_;
  our $vhost ||= CXGN::VHost->new;
  my $ftp_root = $vhost->get_conf('ftpsite_root');
  my $ftp_url = $vhost->get_conf('ftpsite_url');
  my @files = tpf_agp_files($chr);
  $_ =~ s/^$ftp_root/$ftp_url/e foreach @files;
  return map {$_ ? qq|<a href="$_">[download]</a>| : undef} @files;
}

#given a filename for a tab-delimited file, render the file into
#HTML.  if the file is not there, render it as a 'file not found'
#HTML message
sub tabdelim_to_html {
  my ($filename,$headings,$styler) = @_;
  my @data = tabdelim_to_array($filename);
  unless(@data) {
    warn "'$filename' was empty\n";
    return "<center><b>File is empty</b></center>"
  }
  my $cols = max(map {scalar(@$_)} @data); #find the number of cols in our input data
  return join "\n",
    ( '<center>',
      '<table width="90%">',
      (
       map {
	 my $r = $_;
	 if (@$r > 1) {
	   #rows that are more than 1 col, but which don't have
	   #enough cols are padded to the number of cols in the rest
	   #of em
	   if (@$r < $cols) {
	     $_ = '&nbsp;' foreach @{$r}[scalar(@$r)..($cols-1)];
	   }
	   join( '',
		 '<tr>',
		 ( map { my $style = ref $styler ? $styler->($_) : '';
			 $style &&= qq| style="$style"|;
			 $_ = link_identifier($_) || $_;
			 "<td$style>$_</td>"
		       } @$r
		 ),
		 '</tr>'
	       )
	 } else {
	   my $style = ref $styler ? $styler->($r->[0]) : '';
	   $style &&= qq| style="$style"|;
	   $r->[0] = link_identifier($r->[0]) || $r->[0];
	   qq|<tr><td colspan="$cols"$style>$r->[0]</td></tr>|
	 }
       } @data
      ),
      '</table>',
      '</center>',
    );
}

#given a filename, read it into a 2-d array assuming it's a tab-delimited file
#does no checking to see whether it's actually tab-delimited
sub tabdelim_to_array {
  my ($filename) = @_;

  die "1MB file size limit exceeded" if -s $filename > 1_000_000;

  open my $fh,$filename
    or die "Could not open '$filename' for reading: $!";

  my @array;
  while(<$fh>) {
    push @array, [/^\s*#/ ? ($_) : split];
  }
  return @array;
}


###
1;#do not remove
###
