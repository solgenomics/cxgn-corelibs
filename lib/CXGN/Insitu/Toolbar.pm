
use strict;

package CXGN::Insitu::Toolbar;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw / display_toolbar /;  # symbols to export on request



use CXGN::Page::FormattingHelpers qw/page_title_html modesel/;

sub display_toolbar { 
    my $hilite = shift;

#    my $page = CXGN::Page->new();
    my @tabs = (
		["/insitu/", "Home"],
		["/insitu/search.pl", "Search"],
		["/insitu/manage.pl", "Manage"],
		["/insitu/help.pl", "Help"]
		);
    
#     my @tabfuncs = (
# 		    \&home
# 		    \&unigene_tab,
# 		    \&marker_tab,
# 		    \&bac_tab,
# 		    \&annotation_tab,
# 		    \&est_tab,
# 		    \&directory_tab,
# 		    );
    
    #get the search type
#    my ($search) = $page -> get_arguments("search");
#    $search ||= 'unigene'; #default
    
    my $tabsel =
	($hilite=~ //i)          ? 0
	: ($hilite =~ /home/i)     ? 0
	: ($hilite =~ /search/i)     ? 1
	: ($hilite =~ /manage/i)        ? 2
	: ($hilite =~ /help/i) ? 3
	
    
	: print STDERR "Invalid search type.";


    print modesel(\@tabs,$tabsel); #print out the tabs
    
}    
    
 #    my $hilite = shift;
    
#     my $home = "Insitu home";
#     my $search = "Search";
#     my $manage = "Manage";
#     my $help = "Help";

#     my %links = (
# 		 "$home" => "/insitu/",
# 		 "$search" => "/insitu/search.pl",
# 		 "$manage" => "/insitu/manage.pl",
# 		 "$help"   => "/insitu/help.pl",
# 		 );
#     my @link_order   = ( $home, $search, $manage, $help );

#     print qq { 	<table><tr> };

#     foreach my $k (@link_order) { 
# 	my $bgcolor = "#FFFFFF";
# 	if ($hilite eq $k) { 
# 	    $bgcolor="#FFFF00";
# 	}
# 	print qq { <td bgcolor="$bgcolor"><a href="$links{$k}">$k</a></td><td>|</td> }
#     }
#     print qq { </tr></table><br /><br /> };
# }

return 1;
