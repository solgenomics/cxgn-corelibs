####
=head1 Page_comment.pm

Page_comment.pm -- a package for adding user comments to database detail pages.

=head1 Synopsys

my $page_comment_obj = CXGN::People::PageComment->new($dbh, "map", $map_id);

print $page_comment_obj->get_html();

=head1 Description

Handles the addition and deletion of user comments to SGN pages. Users have to be logged in using SGN's login system to post/delete messages. 

=head1 Dependencies

The current implementation depends on CXGN::People::Forum.pm

=head1 Functions

=cut
#####


use strict;


package CXGN::People::PageComment;

use CXGN::Page;
use CXGN::Login;
use CXGN::People;
use CXGN::People::Forum;

use base qw | CXGN::DB::Object |;
1;


=head2 function new

Synopsis: my $pc = CXGN::People::PageComment -> new($dbh, "map", 9);
Arguments: 
    (1) A database handle
    (2) A type, one of "BAC", "EST", "unigene", "marker", "map", "bac_end"
    (3) the object\'s ID (an integer value that specifies the page).
Returns: a handle to a Page_comment object
Side effects: Accesses the sgn_people database through the Forum.pm interface to search for comments for the specified type/ID and caches them.
Description:	

=cut



sub new { 
    my $class = shift;
    my $dbh = shift;
    my $type = shift;
    my $id = shift;
    my $args = {};

    my $self = $class->SUPER::new($dbh);

    $self->set_type($type);
    $self->set_id($id);
    
    # get a page object to decide if a user is logged in.
    my $page= CXGN::Page->new("", "Lukas");
    $self->set_user_id(CXGN::Login->new($self->get_dbh())->has_session());
    $self->set_refering_page($page->{request}->uri()."?".$page->{request}->args());
    #print STDERR "Referer: ".($self->get_refering_page())."\n";
			     
    @{$self->{posts}}= ();
    $self->fetch_page_comments();
    
    return $self;
}

sub fetch_page_comments { 
    #
    # fetch the page comments using a function in the Topic class
    #
    my $self = shift;
    #print STDERR "TYPE: ".$self->get_type.", ID: ".$self->get_id()."\n";
    my $topic = CXGN::People::Forum::Topic->new_page_comment($self->get_dbh(), $self->get_type(), $self->get_id());
    #print STDERR "TOPIC ID: ".$topic->get_forum_topic_id()."\n";
        
    $self->set_topic($topic);
    if ($self->get_topic()->get_forum_topic_id()) { 
	#print STDERR "Topic_id: ".$self->get_topic()->get_forum_topic_id()."\n";
	my @posts = $self->get_topic()->get_all_posts();
#	foreach my $p (@posts) { print STDERR "POSTS: ".($p->get_subject())."\n"; }
	$self->set_posts(@posts);
	
    }
    else { 
	#print STDERR "No topic could be found corresponding to type=".$self->get_type()." and id=".$self->get_id()."\n";
    }
    
}

sub set_refering_page { 
    my $self = shift;
    $self->{refering_page} = shift;
}

sub get_refering_page { 
    my $self = shift;
    return $self->{refering_page};
}

sub set_topic { 
    my $self = shift;
    $self->{topic}=shift;
}

sub get_topic { 
    my $self = shift;
    return $self->{topic};
}

sub set_posts { 
    my $self = shift;
    @{$self->{posts}} = @_;
}

sub get_posts {
    my $self = shift;
    return @{$self->{posts}};
}

sub set_type { 
    my $self = shift;
    $self->{type}=shift;
}

sub get_type { 
    my $self = shift;
    return $self->{type};
}

sub set_id { 
    my $self = shift;
    $self->{id}=shift;
}

sub get_id  {
    my $self = shift;
    return $self->{id};
}

sub set_user_id { 
    my $self = shift;
    $self->{user_id}=shift;
}

sub get_user_id { 
    my $self = shift;
    return $self->{user_id};
}

###
=head2 function get_html

  Synopsis:  print $cp -> get_html();
 Arguments:  none
  Returns:   a string containing html code containing the user comments
    Side effects:	
  Description:	

=cut
###


sub get_html { 

  my ($self, $passed_referer) = @_;
  
  my @posts = $self->get_posts();    
  
  # We want to eventually return the user to the page they came from
  #my $encoded_url = url_encode($self->get_refering_page());
  
  # ...but if a referer is provided, we'll use that instead (helpful 
  # with ajax)
  my $encoded_url = url_encode($self->get_refering_page()) || url_encode($passed_referer);
#  warn "UNENCODED URL IS $passed_referer";
#  warn "ENCODED URL IS $encoded_url";
  
  my $s;
  my $subtitle;
  if (!@posts) { 
    #$subtitle ="<span class=\"ghosted\">No user comments.</span>";
  }
  else 
    {
      $s .= "<div class=\"indentedcontent\"><table width=\"700\" summary=\"\" cellpadding=\"3\" cellspacing=\"0\" border=\"0\" >";    
      foreach my $p (@posts) { 
	my $subject = $p->get_subject();
	my $person_id = $p -> get_person_id();
	my $person = CXGN::People::Person -> new($self->get_dbh(), $person_id);
	my $sp_person_id = $person -> get_sp_person_id();
	my $name = $person->get_first_name()." ".$person->get_last_name();
	my $user_type = $person->get_user_type();
	if($user_type and $user_type ne 'user'){
	  $user_type=" ($user_type)";
	} else {
	  $user_type='';
	}
	my $text = $p -> get_post_text();
	my $date = $p -> get_formatted_post_time();
	my $remove_link = "&nbsp;";
	
	if (($self->get_user_id() == $sp_person_id) && $sp_person_id) { 
	  $remove_link = "<a href=\"/forum/forum_post_delete.pl?post_id=".($p->get_forum_post_id())."&amp;refering_page=$encoded_url\">Delete</a>\n"; 
	}
    	
	$s .= "<tr><td><div class=\"boxbgcolor2\">
                 
                   <table summary=\"\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\"><tr><td>Posted by <b><a href=\"/solpeople/personal-info.pl?action=view&amp;sp_person_id=$sp_person_id\">$name</a>$user_type</b> on $date  </td><td class=\"right\">$remove_link&nbsp;</td></tr></table></div>";
	$s .= "<div class=\"boxbgcolor5\"><div class=\"indentedcontent\">$text</div></div></td></tr>";
      }
      $s .= "</table>";
    }	
  
  $subtitle .= "<a href=\"/forum/add_post.pl?page_type=".$self->get_type()."&amp;page_object_id=".$self->get_id()."&amp;refering_page=$encoded_url\">[Add comment]</a>";
  

  return CXGN::Page::FormattingHelpers::info_section_html(title   => 'User comments',
							  collapsible => 1,
							  subtitle=>$subtitle,
							  contents =>$s  ,
							 );
}


sub url_encode {
    my $theURL = $_[0];
   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}
