=head1 NAME

CXGN::UserList::List - a handle for working with a list of list_items, representative of a row in the table "list"

=head1 SYNOPSIS

This object represents a user's list, which contains references to ListItems. 

=cut

package CXGN::UserList::List;
use CXGN::DB::Connection;
use CXGN::UserList::ListItem;
use strict;
use Carp;

=head2 new

 Usage:		my $list = CXGN::UserList::List->new($dbh, $list_id)
 Desc:		creates a new CXGN::UserList::List object
 Ret:		A handle for dealing with a list.
 Args:		- a database handle created from CXGN:DB::Connection
 			- a list_id, from which the entry will be fetched.
			  if the entry in the DB doesn't exist, confess will be called

=cut

sub new {
	my $class = shift;
	my $dbh = shift;
	my $list_id = shift;
	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){confess "Invalid DBH passed to CXGN::UserList";}
	$self->{list_id} = $list_id;
	$self->{dbh} = $dbh;
	$self->fetch(); #load up content from list table.  If an invalid list_id was sent, fetch() will confess, and the calling script will die
	return $self;
}

=head2 create_new

 Usage:		my $list = CXGN::UserList::List->create_new($dbh, $sp_person_id, "My New List", "(Description)")
 Desc:		creates a new CXGN::UserList::List object AND a new entry in the list table 
 Ret:		A handle for dealing with a list.
 Args:		- a database handle created from CXGN:DB::Connection
 			- an sp_person_id, the owner of the new list.  If the person doesn't
			  exist, confess will be called
			- (optional) a name for the new list
			- (optional) a description for the new list

=cut

sub create_new {
	my $class = shift;
	my $dbh = shift;
	my $sp_person_id = shift;
	my $name = shift;
	my $description = shift;
	$name ||= "Untitled List";
	$description ||= "";

	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){confess "Invalid DBH passed to CXGN::UserList";}
	unless(defined $sp_person_id) { #create a new list!
		confess "sp_person_id not sent to List->create_new()";		
	}
	my $person_checkq = $dbh->prepare("SELECT sp_person_id FROM sp_person WHERE sp_person_id=?");
	$person_checkq->execute($sp_person_id);
	unless($person_checkq->fetchrow_arrayref()){ confess "sp_person_id: $sp_person_id does not exist in sp_person"; }
	
# 	$dbh->do("BEGIN create_list");
	my $create_q = $dbh->prepare("INSERT INTO list (owner, name, description) VALUES (?, ?, ?)");
	$create_q->execute($sp_person_id, $name, $description) or confess("Could not create new list in database");
	$self->{list_id} = $dbh->last_insert_id("list", "sgn_people");
# 	$dbh->do("COMMIT create_list"); 
	$self->{dbh} = $dbh;
	$self->{owner} = $sp_person_id;
	$self->{name} = $name;
	$self->{desc} = $description;
	return $self;
}

=head2 fetch

 Usage:		$listItem->fetch();
 Desc:		fetches current value from database and stores to internal data structure $list->{name}, etc...
 			also, $list->{items} will contain an array reference to ListItem instances
 Ret:		Nothing.  Confess called if fetch fails.
 Args:		- none

=cut

sub fetch {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	my $fetchq = $dbh->prepare("SELECT name, description, sent_by, is_hotlist, owner FROM list WHERE list_id=?");
	$fetchq->execute($self->{list_id}) or confess "Fetch SQL error";
	( 	$self->{name}, 
		$self->{desc}, 
		$self->{sent_by}, 
		$self->{is_hotlist}, 
		$self->{owner} 
	) = $fetchq->fetchrow_array();
	if(!defined $self->{owner}) { confess "Owner undefined for list_id: $self->{list_id}" }
	my $itemq = $dbh->prepare("SELECT list_item_id FROM list_item WHERE list_id=?");
	$itemq->execute($self->{list_id}) or confess "List Item Fetch SQL Error";
	my @items = ();
	while(my ($list_item_id) = $itemq->fetchrow_array()){
		push(@items, CXGN::UserList::ListItem->new($dbh, $list_item_id));
	}
	$self->{items} = \@items;
}

=head2 store

 Usage:		$listItem->store();
 Desc:		stores current list object state into the database and cascades ListItem-store()
 Ret:		Nothing.  Confess called if store fails.
 Args:		- none

=cut

sub store {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	my $liststoreq = $dbh->prepare("UPDATE list SET name=?, description=?, sent_by=?, owner=?, WHERE list_item_id=?");
	$liststoreq->execute($self->{name}, $self->{desc}, $self->{sent_by}, $self->{owner}, $self->{list_item_id}) or confess "Store SQL error";

	foreach my $item (@{$self->{items}}){
		$item->store();
	}
	#note that we don't have to do anything with $self->{items}, because:
	# 1) When items are deleted and created, the database is affected
	# 2) When these actions occur, $self->{items} is adjusted appropriately
}

=head2 delete

 Usage:		$list->delete();
 Desc:		deletes list from database, sets $self->{deleted} = 1 for benefit of Handle
 Ret:		Nothing.  Confess called if delete fails.
 Args:		- none

=cut

sub delete {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	if($self->{is_hotlist}) { confess "Can't delete the Hotlist!"; }
	my $deleteq = $dbh->prepare("DELETE FROM list WHERE list_id=?");
	$deleteq->execute($self->{list_id}) or confess "Delete SQL error";
	$self->{deleted} = 1;
}


=head2 add_items

 Usage:		$list->add_items($item_content1, $item_content2, etc...);
 Desc:		Adds list items with sent content to list
 Ret:		Reference to array of added ListItem instances
 Args:		- One or more list item contents

=cut

sub add_items {
	my $self = shift;
	my @newitems;
	foreach my $item_content (@_) {	
		## Enforce uniqueness if item does not begin with 'comment:'
		my $unique = 1;
		foreach my $item (@{$self->{items}}) {
			if($item->get_content() eq $item_content){
				$unique = 0;
			}
		}
		next unless ($unique || $item_content =~ /^comment:/);
		my $new_item = CXGN::UserList::ListItem->create_new($self->{dbh}, $self->{list_id}, $item_content);
		push(@{$self->{items}}, $new_item);
		push(@newitems, $new_item);
	}
	return \@newitems;
}

=head2 remove_items

 Usage:		$list->remove_items($item_content1, $item_content2, etc...);
 Desc:		Removes first list item with matching content from list, for each sent content item
 Ret:		Reference to array of deleted list item instances.  This allows some in-script rollback capabilities.
 Args:		- One or more list item contents

=cut

sub remove_items {
	my $self = shift;
	my @deletedItems;
	my @keptItems;
	foreach my $item_content (@_) {	
		my $matched_already = 0;
		foreach my $item (@{$self->{items}}) {	
			if(($item->get_content() eq $item_content) && !$matched_already){
				push(@deletedItems, $item);
				$item->delete();  # causes deletion of item from database, so store() call isn't necessary
				#if multiple identical identifiers exist, delete them all.  If it's a comment, delete only one instance
				if($item_content =~ /^comment:/) {$matched_already = 1;}  
			}
			else {
				push (@keptItems, $item);
			}
		}
	}
	$self->{items} = \@keptItems;
	return \@deletedItems;
}

=head2 get_items

 Usage:		my $array_listItem = $list->get_items();
 Desc:		Use this to grab a reference to an array of ListItems currently in list
 Ret:		Reference to array of ListItem instances
 Args:		- None

=cut

sub get_items {
	my $self = shift;
	return $self->{items};
}

=head2 get_list_size

 Usage:		my $list_size = $list->get_list_size();
 Desc:		Gets the size of the list, based on number of entries in $self->{items}
 Ret:		A numeric list-size
 Args:		- None

=cut

sub get_list_size {
	my $self = shift;
	my $list_size = @{$self->{items}};	
	return $list_size;
}


=head2 get_item_ids

 Usage:		my $array_item_ids = $list->get_item_ids();
 Desc:		Use this to grab a reference to an array of item_ids currently in list
 Ret:		Reference to array of item_id's
 Args:		- None

=cut

sub get_item_ids {
	my $self = shift;
	my @item_ids = ();
	foreach my $item (@{$self->{items}}) {
		push(@item_ids, $item->get_id());
	}
	return \@item_ids;
}

=head2 get_item_contents

 Usage:		my $array_item_contents = $list->get_item_contents();
 Desc:		Use this to grab a reference to an array of item contents currently in list
 Ret:		Reference to array of item_id's
 Args:		- None

=cut

sub get_item_contents {
	my $self = shift;
	my @item_contents = ();
	foreach my $item (@{$self->{items}}) {
		push(@item_contents, $item->get_content());
	}
	return \@item_contents;
}

=head2 get_id

 Usage:		my $list_id = $list->get_id();
 Ret:		list_id for this list

=cut

sub get_id {
	my $self = shift;
	return $self->{list_id};
}

=head2 get_description

 Usage:		my $list_description = $list->get_description();
 Ret:		description for this list

=cut

sub get_description {
	my $self = shift;
	return $self->{desc};
}

=head2 set_description

 Usage:		$list->set_description("Live every week like it's shark week");
 Arg:		-description for this list

=cut

sub set_description {
	my $self = shift;
	my $newdesc = shift;
	$self->{desc} = $newdesc;
	$self->store();
}


=head2 get_name

 Usage:		my $list_name = $list->get_name();
 Ret:		The name of this list

=cut

sub get_name {
	my $self = shift;
	return $self->{name};
}

=head2 set_name

 Usage:		$list->set_name("Ghostfaced Killa");
 Arg:		-name for this list

=cut

sub set_name {
	my $self = shift;
	my $newname = shift;
	$self->{name} = $newname;
	$self->store();
}

=head2 get_owner

 Usage:		my $owner = $list->get_owner();
 Ret:		The owner (sp_person_id) of this list

=cut

sub get_owner {
	my $self = shift;
	return $self->{owner};
}

=head2 set_owner

 Usage:		$list->set_owner(320);
 Arg:		-sp_person_id of new owner

=cut

sub set_owner {
	my $self = shift;
	my $newowner = shift;
	$self->{owner} = $newowner;
	$self->store();
}

=head2 get_sent_by

 Usage:		my $sent_by = $list->get_sent_by();
 Ret:		The sender (sp_person_id) of this list

=cut

sub get_sent_by {
	my $self = shift;
	return $self->{sent_by};
}

=head2 set_sent_by

 Usage:		$list->set_sent_by(320);
 Arg:		-sp_person_id of sender

=cut

sub set_sent_by {
	my $self = shift;
	my $sent_by = shift;
	$self->{sent_by} = $sent_by;
	$self->store();
}

=head2 is_hotlist

 Usage:		if($list->is_hotlist()) { ...
 Ret:		TRUE if this list is a hotlist, otherwise FALSE or undef

=cut

sub is_hotlist {
	my $self = shift;
	return $self->{is_hotlist};
}

=head2 is_deleted

 Usage:		if($list->is_deleted()) { ...
 Ret:		1 if this list is deleted, undefined otherwise 

=cut

sub is_deleted {
	my $self = shift;
	return $self->{deleted};
}

###
1;###
###


=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut
