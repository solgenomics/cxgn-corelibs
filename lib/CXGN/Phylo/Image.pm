#!/usr/bin/perl

=head1 NAME

Image.pm - a front-end class to the Phylo library to easily generate tree images.

=head1 DESCRIPTION

This class provides some simple functions to generate a tree images in PNG format directly from a tree
definition file provided in the constructor and can embed the file on any html page using generate_html().
The image width and the image height can be set using set_image_width() and set_image_height().

A standard set of links is created in the file. There is currently not much control over how the program
generates these links. They essentially point to the SGN tree browser, so that the tree can be explored
interactively.

=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu)

=cut

use strict;

use CXGN::Page;
use CXGN::Phylo;
use CXGN::Phylo::Tree_browser;

package CXGN::Phylo::Image;

sub new { 
    my $class = shift;
    my $hash_ref = shift;
    my $args={};
    my $self = bless $args, $class;
    
    $self->set_file($hash_ref->{file});
    $self->set_file_type($hash_ref->{type});
    $self->set_image_width(150);
    $self->set_image_height(150);
    return $self;
}

=head2 function get_file

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_file { 
    my $self=shift;
    return $self->{file};
}

=head2 function set_file

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_file { 
    my $self=shift;
    $self->{file}=shift;
}

=head2 function get_file_type

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_file_type { 
    my $self=shift;
    return $self->{file_type};
}

=head2 function set_file_type

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_file_type { 
    my $self=shift;
    $self->{file_type}=shift;
}



sub set_view { 
    my $self = shift;
    $self->{view}=shift;
}

sub get_view { 
    my $self = shift;
    return $self->{view};
}

=head2 function get_image_width

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_image_width { 
my $self=shift;
return $self->{image_width};
}

=head2 function set_image_width

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_image_width { 
    my $self=shift;
    $self->{image_width}=shift;
}

=head2 function get_image_height

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_image_height { 
    my $self=shift;
    return $self->{image_height};
}

=head2 function set_image_height

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_image_height { 
    my $self=shift;
    $self->{image_height}=shift;
}

=head2 function read_file()

  Synopsis:	$image->read_file($filename);
  Arguments:	
  Returns:	a newick formatted string
  Side effects:	sets the tree_string property
  Description:	it reads either a tre file or a file with no particular
                format that contains a newick string. It the file type that
                is available through get_file_type() to determine what file 
                type the file is. It also looks at the extension: files with a
                suffix of .tre are assumed to be of tre format.

=cut

sub read_file { 
    my $self = shift;
    my $file = shift;
    my $type = shift;
    my $tree_file_obj = CXGN::Phylo::Tree->new(file => $file, type=>$type);
    return $tree_file_obj->get_tree_string();
}

=head2 function get_tree_string

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_tree_string { 
    my $self=shift;
    return $self->{tree_string};
}

=head2 function set_tree_string

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_tree_string { 
    my $self=shift;
    $self->{tree_string}=shift;
}


sub generate_html {
    my $self = shift;
# read asterids definition file
#
    open (F, "<".$self->get_file()) || die "Can't open file\n";
    my $newick="";
    while (<F>) {
	chomp;
	$newick .=$_;
    }
    close(F);

   print STDERR "Newick String: $newick\n";
    my $parser = CXGN::Phylo::Parse_newick->new($newick);
    my $tree = $parser->parse( CXGN::Phylo::Tree->new("") );

    

     if (!$tree) { exit(-1); }
    if (!$self->get_view()) { 
	$self->set_view("asterid");
    }
    
# retrieve some key nodes
#
    my ($sol) = $tree->search_node_name("Solanaceae");
    my ($con) = $tree->search_node_name("Convolvulaceae");
    my ($ros) = $tree->search_node_name("Asterids");
    my ($mon) = $tree->search_node_name("Monocots");
    
    if ($self->get_view() eq "asterid") { 
	
	$sol->set_hidden(1);
	
	$con->set_hidden(1);
	
	$ros->set_hidden(1);
	
	$mon->set_hidden(1);
    }
    
    if ($self->get_view() eq "solanaceae") { 
	$tree->set_root($sol);
	$tree->get_layout()->set_image_height($self->get_image_height());
	$tree->get_layout()->set_image_width($self->get_image_width());
    }    
    
# render image
#
    my $browser=CXGN::Phylo::Tree_browser->new();
    my ($tempfile, $temp_url) = $browser->create_temp_file();
    my $renderer = CXGN::Phylo::PNG_tree_renderer->new($tree);
    $renderer->get_layout()->set_top_margin(20);
    $renderer->get_layout()->set_bottom_margin(20);
    
    $renderer->render_png($tempfile.".png");
    my $html_image_map = $renderer->get_html_image_map("map");  
    
    #
    # output link
    print "<img src=\"$temp_url.png\" usemap=\"#map\" /> " ;
    print "$html_image_map";
    
}

1;


