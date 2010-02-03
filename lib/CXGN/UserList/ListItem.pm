=head1 NAME

CXGN::UserList::ListItem - a handle for working with an individual list item, representative of a row in the table "list_item"

=head1 SYNOPSIS

This object represents an individual item in a users lists.  It is designed to be generally used by the List and Hotlist objects, but it may have some direct use to the scripter, since you can set the content of a ListItem.

=cut

package CXGN::UserList::ListItem;
use CXGN::DB::Connection;
use strict;
use Carp;

=head2 new

 Usage:		my $listItem = CXGN::UserList::ListItem->new($dbh, $list_item_id)
 Desc:		creates a new CXGN::UserList::ListItem object
 Ret:		A handle for dealing with a list item.
 Args:		* a database handle created from CXGN:DB::Connection
 		* a list_item_id, from which the entry will be fetched.
			  if the entry in the DB doesn't exist, throw an error

=cut

sub new {
	my $class = shift;
	my $dbh = shift;
	my $list_item_id = shift;
	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){confess "Invalid DBH passed to CXGN::UserList";}
	unless(defined $list_item_id) { 
		confess "No list_item_id sent to ListItem->new()";	
	}
	$self->{list_item_id} = $list_item_id;
	$self->{dbh} = $dbh;
	$self->fetch(); #load up content from list_item table.  If an invalid list_item_id was sent, fetch() will confess, and the calling script will die
	return $self;
}

=head2 create_new

 Usage:		my $listItem = CXGN::UserList::ListItem->new($dbh, $list_id)
 Desc:		creates a new CXGN::UserList::ListItem object AND inserts a new item in the database
 Ret:		A handle for dealing with a list item.
 Args:		* a database handle created from CXGN:DB::Connection
 		* a list_id of which the new item will be a member.  confess if list_id invalid
		* (optional) content for the new list_item

=cut

sub create_new {
	my $class = shift;
	my $dbh = shift;
	my $list_id = shift;
	my $content = shift;
	$content ||= "Undefined";
	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){confess "Invalid DBH passed to CXGN::UserList";}
	unless(defined $list_id) {confess "list_id not sent to ListItem->create_new()" }

	my $listcheck_q = $dbh->prepare("SELECT list_id FROM list WHERE list_id=?");
	$listcheck_q->execute($list_id);
	unless($listcheck_q->fetchrow_arrayref()) { confess "list_id invalid" }

# 	$dbh->do("BEGIN create_item");
	my $create_q = $dbh->prepare("INSERT INTO list_item (list_id, content) VALUES (?, ?)");
	$create_q->execute($list_id, $content) or confess("Could not create new list_item in database");
	$self->{list_item_id} = $dbh->last_insert_id("list_item", "sgn_people");
# 	$dbh->do("COMMIT create_item"); 
	$self->{dbh} = $dbh;
	$self->{content} = $content;
	$self->{list_id} = $list_id;
	return $self;
}



=head2 fetch

 Usage:		$listItem->fetch();
 Desc:		fetches current value from database and stores to internal data structure $listItem->{content}
 Ret:		Nothing
 Args:		* none

=cut

sub fetch {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	my $fetchq = $dbh->prepare("SELECT content, list_id FROM list_item WHERE list_item_id=?");
	$fetchq->execute($self->{list_item_id}) or confess "Fetch SQL error";
	my ($content, $list_id) = $fetchq->fetchrow_array();
	if(!defined $content || !defined $list_id) { confess "Content or list_id undefined for list_item_id: $self->{list_item_id}" }
	$self->{content} = $content;	
	$self->{list_id} = $list_id;
}

=head2 store

 Usage:		$listItem->store();
 Desc:		stores current object state into the database (affects only content)
 Ret:		Nothing
 Args:		* none

=cut

sub store {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	my $storeq = $dbh->prepare("UPDATE list_item SET content=?, list_id=? WHERE list_item_id=?");
	$storeq->execute($self->{content}, $self->{list_id}, $self->{list_item_id}) or confess "Store SQL error";
}

=head2 delete

 Usage:		$listItem->delete();
 Desc:		deletes list item from database, sets $self->{deleted} = 1 for benefit of List and Hotlist modules
 Ret:		Nothing
 Args:		* none

=cut

sub delete {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	my $deleteq = $dbh->prepare("DELETE FROM list_item WHERE list_item_id=?");
	$deleteq->execute($self->{list_item_id}) or confess "Delete SQL error";
	$self->{deleted} = 1;
}

=head2 get_id

 Usage:		$listItem->get_id();
 Desc:		accessor for list_item_id
 Ret:		list_item_id #
 Args:		* none

=cut

sub get_id {
	my $self = shift;
	return $self->{list_item_id};
}

=head2 get_content

 Usage:		$listItem->get_content();
 Desc:		accessor for content
 Ret:		content (text)
 Args:		* none

=cut

sub get_content {
	my $self = shift;
	return $self->{content};
}

=head2 get_list_id

 Usage:		$listItem->get_list_id();
 Desc:		accessor for list_id for which ListItem is a member
 Ret:		list_id #
 Args:		* none

=cut

sub get_list_id {
	my $self = shift;
	return $self->{list_id};
}

=head2 is_deleted

 Usage:		$listItem->is_deleted();
 Desc:		accessor for deletion flag
 Ret:		1 or undef
 Args:		* none

=cut

sub is_deleted {
	my $self = shift;
	return $self->{deleted};
}

=head2 set_content

 Usage:		$listItem->set_content($agitext);
 Desc:		setter for content
 Ret:		none
 Args:		* textual content

=cut

sub set_content {
	my $self = shift;
	my $content = shift;
	$self->{content} = $content;
	$self->store(); ##Auto-Store(?)
}

=head2 set_list_id

 Usage:		$listItem->set_list_id($list_id);
 Desc:		setter for list_id, essentially moves an item from one list to another
 Ret:		none
 Args:		* a valid list_id

=cut

sub set_list_id {
	my $self = shift;
	my $list_id = shift;
	$self->{list_id} = $list_id;
	$self->store();
}


####
1;####  Importante, cholo
####


=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut
