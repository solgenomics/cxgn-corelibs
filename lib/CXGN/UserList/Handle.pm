=head1 NAME

CXGN::UserList::Handle - creates a handle for working with hotlists and custom user-lists of things like Indentifiers, Text Globs, Images, etc.

=head1 SYNOPSIS

This module was designed to make working with hotlists especially easy, but also improving the manageability of User Lists applications.  Every conceivable User List operation can be performed with subroutines in this module.  This module is designed to work with the "list" and "list_item" tables in sgn_people.
The handle provides many wrappers for subroutines which can be directly operated upon List, Hotlist, and ListItem (such as 'set_list_name'), for the sake of convenience.

You should take note of the fact that fetch() retrieves EVERYTHING related to a user's list_items from the database, so it may be a somewhat long operation.  The only time when it needs to be called is at the beginning, and this is automatic under new().  Store() also causes a cascade in which List, Hotlist, and ListItem call their store functions.  

It will almost always be unnecessary to call $handle->store() and $handle->fetch(), since operations involving both are time consuming and therefore worked-around in some ways.  For example, in $handle->create_list(), I manually change the $handle->{lists} object array reference instead of using the store() -> fetch() method, since this is a much quicker method to use on the fly.  Also, it's a very convenient method since $handle->{lists} is the only data structure of $handle that needs to be updated due to operations through the handle.

=cut

package CXGN::UserList::Handle;
use CXGN::DB::Connection;
use CXGN::UserList::List;
use CXGN::UserList::Hotlist;
use CXGN::UserList::ListItem;
use strict;
use Carp;

=head2 new

 Usage:		my $listh = CXGN::UserList::Handle->new($dbh, $sp_person_id)
 Desc:		creates a new CXGN::UserList::Handle object
 Ret:		A handle for dealing with $sp_person_id's list.
 Args:		* a database handle created from CXGN:DB::Connection
 		* the sp_person_id for the current user.  The handle will
			  only apply to this particular user, but you can provide
			  some operations with other user's lists (for transferrals)

=cut

sub new {
	my $class = shift;
	my $dbh = shift;
	$dbh->do("SET search_path=sgn_people");
	my $sp_person_id = shift;
	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){die "Invalid DBH passed to CXGN::UserList";}
	unless(defined $dbh && defined $sp_person_id && $sp_person_id=~/^\d+$/) { 
		die "Database Handle and integeric sp_person_id must be passed";
	}
	my $user_q = $dbh->prepare("SELECT sp_person_id FROM sgn_people.sp_person WHERE sp_person_id=?");
	$user_q->execute($sp_person_id);
	unless($user_q->fetchrow_arrayref){
		die "Invalid sp_person_id passed to CXGN::UserList";
	}
	$self->{owner} = $sp_person_id;
	$self->{dbh} = $dbh;
	$self->fetch();
	return $self;
}

=head2 fetch

 Usage:		$listh->fetch();
 Desc:		Grabs everything belonging to the user in the database, creating all Hotlist, List, and ListItem instances 
 			in cascade fashion.  We see that using the Handle module is ideal if we need almost all of the information
			about a user's list items in one script or subroutine.
 Ret:		Nothing
 Args:		 None

=cut

sub fetch {
	my $self = shift;
	my $dbh = $self->{dbh};
	$self->{hotlist} = CXGN::UserList::Hotlist->new($dbh, $self->{owner});
	my $fetch_id_q = $dbh->prepare("SELECT list_id FROM list WHERE owner = ? AND is_hotlist!=TRUE");
	$fetch_id_q->execute($self->{owner}) or confess "Getting the list_id's didn't work...";

	my @lists = ();	
	while(my ($list_id) = $fetch_id_q->fetchrow_array()){
		push(@lists, CXGN::UserList::List->new($dbh, $list_id));
	}
	$self->{lists} = \@lists;
}

=head2 store

 Usage:		$listh->fetch();
 Desc:		Triggers a cascade of stores, in which the Hotlist and Lists will call their own store functions,
 			which will cause list items to call theirs.
 Ret:		Nothing
 Args:		 None

=cut

sub store {
	my $self = shift;
	my $dbh = $self->{dbh};
	$self->{hotlist}->store();
	foreach my $list (@{$self->{lists}}) {
		$list->store();
	}
}

=head2 get_hotlist

 Usage:		my $hotlist = $listh->get_hotlist();
 Ret:		Returns a reference to an instance of CXGN::UserList::Hotlist for this user
 Args:		 None

=cut

sub get_hotlist {
	my $self = shift;
	return $self->{hotlist};
}

=head2 get_lists

 Usage:		my $array_ref = $listh->get_lists();
 Ret:		returns a reference to an array of List instances 
 Args:		 None

=cut

sub get_lists {
	my $self = shift;
	return $self->{lists};
}

=head2 get_list_names

 Usage:		my $name_ref = $listh->get_list_names();
 Ret:		returns a reference to a HASH of list names for given list_ids  ($name_ref->{list_id} = "name"}
 Args:		None 

=cut

sub get_list_names {
	my $self = shift;
	my %list_names;
	foreach my $list (@{$self->{lists}}) {
		$list_names{$list->get_id()} = $list->get_name();
	}
	return \%list_names;
}

=head2 get_list_descriptions

 Usage:		my $desc_ref = $listh->get_list_descriptions();
 Ret:		returns a reference to a HASH of list descriptions for given list_ids  ($desc_ref->{list_id} = "description"}
 Args:		None 

=cut

sub get_list_descriptions {
	my $self = shift;
	my %list_descs;
	foreach my $list (@{$self->{lists}}) {
		$list_descs{$list->get_id()} = $list->get_description();
	}
	return \%list_descs;
}

=head2 get_list_sent_bys

 Usage:		my $sent_by_ref = $listh->get_list_sent_bys();
 Ret:		returns a reference to a HASH of list sent_by info for given list_ids  ($sent_by_ref->{list_id} = sp_person_id (numeric)}
 Args:		None 

=cut

sub get_list_sent_bys {
	my $self = shift;
	my %list_sent_bys;
	foreach my $list (@{$self->{lists}}) {
		$list_sent_bys{$list->get_id()} = $list->get_sent_by();
	}
	return \%list_sent_bys;
}

=head2 set_list_description

 Usage:		$listh->set_list_description($list_id, "These genes relate to my SRP-pathogen interaction project");
 Ret:		1 if successful, otherwise confess
 Args:		-A valid list_id
 			-A textual description, provided by the user

=cut

sub set_list_description {
	my $self = shift;
	my $list_id = shift;
	my $description = shift;
	if(!defined $list_id || !defined $description) { confess ("set_list_description requires list_id AND description arguments");}
	my $dbh = $self->{dbh};

	foreach my $list (@{$self->{lists}}) {
		if ($list_id == $list->get_id()){
			$list->set_description($description);
		}
	}
	return 1;
}

=head2 set_list_name

 Usage:		$listh->set_list_name($list_id, "Delicious List")
 Ret:		1 if successful, otherwise confess
 Args:		-A valid list_id
 			-A name, provided by the user

=cut

sub set_list_name {
	my $self = shift;
	my $list_id = shift;
	my $name = shift;
	if(!defined $list_id || !defined $name) { confess ("set_list_name requires list_id AND name arguments");}

	my $dbh = $self->{dbh};

	foreach my $list (@{$self->{lists}}) {
		if ($list_id == $list->get_id()){
			$list->set_name($name);
		}
	}
	return 1;
}

=head2 set_item_content

 Usage:		$listh->set_item_content($item_id, "AT1G01010.1")
 Desc:		Sets item content, given item_id
 Ret:		1 if successful, otherwise confess
 Args:		* A valid item_id
 		* New content for the item

=cut

sub set_item_content {
	my $self = shift;
	my $item_id = shift;
	my $content = shift;
	if(!defined $item_id || !defined $content) { confess ("set_list_name requires item_id AND content arguments");}
	foreach my $list (@{$self->{lists}}) {
		foreach my $item (@{$list->get_items()}) {
			if($item->get_id() == $item_id){
				$item->set_content($content);
			}
		}
	}
	return 1;
}

=head2 move_items

 Usage:		$listh->move_items(list_id_target, $list_item_id1, $list_item_id2, etc...);
 Desc:		Move list item(s) from one list to another. The source_list_id isn't necessary.
 Ret:		1 if successful for all items, otherwise confess
 Args: 		* A valid list_id TO which we will move item(s) 
 		* One or more list_item_ids

=cut

sub move_items {
	my $self = shift;
	my $list_id_target = shift;
	if(!@_) { die("set_list_description requires list_id_target and at least one list_item_id");}

	#Find the matching item objects by ID and change their list membership
	foreach my $item_id (@_) {
		foreach my $list (@{$self->{lists}}){
			foreach my $item (@{$list->get_items()}) {
				if($item->get_id() == $item_id) {
					$item->set_list_id($list_id_target);
				}
			}
		}
	}
	return 1;
}

=head2 list_absorb

 Usage:		$listh->list_absorb(list_id_absorber, $list_item_absorbee);
 Desc:		Merge lists by moving items to the first list argument, then deleting second list
 Ret:		1 if successful, otherwise confess
 Args: 		* A valid list_id that will absorb second list
 		* A valid list_id to be absorbed

=cut

sub list_absorb {
	my $self = shift;
	my $list_id_absorber = shift;
	my $list_id_enveloped = shift;
	if(!defined $list_id_enveloped) { die("set_list_description requires list_id_absorber and list_item_absorbee");}
	if($list_id_enveloped == $self->{hotlist}->get_id()) { die("Can't absorb hotlist into something else") }
	foreach my $list (@{$self->{lists}}) {
		if ($list->get_id() == $list_id_enveloped) {
			foreach my $list_item ( @{ $list->get_items() } ) {
				$list_item->set_list_id($list_id_absorber);
			}
		}
	}
	$self->delete_list($list_id_enveloped);
	return 1;
}

=head2 create_list

 Usage:		$listh->create_list($name);
 Desc:		Create a list entry.  If a name is not provided, we will use a default name
 Ret:		1 if successful, otherwise 0 or confess
 Arg:		-A name, si vouz plais

=cut

sub create_list {
	my $self = shift;
	my $name = shift;	
	$name ||= "Untitled List";
	my $newlist = CXGN::UserList::List->create_new($self->{dbh}, $self->{owner}, $name);	
	push (@{$self->{lists}}, $newlist);  #once again, much quicker than store() -> fetch(), despite it's "improperness"
	return 1;
}

=head2 hotlist_add

 Usage:		$listh->hotlist_add($item1_content, $item2_content, etc..);
 Desc:		Add item to the hotlist
 Ret:		1 if successful, otherwise 0 or confess
 Arg: 		-One more more textual list items (unigene, agi, etc.)...

=cut

sub hotlist_add {
	my $self = shift;
	if(!@_) { warn "Nothing to add to hotlist"; return }
	$self->{hotlist}->add_items(@_);
	return 1;	
}

=head2 hotlist_remove

 Usage:		$listh->hotlist_remove(list_content1, list_content2, etc...);
 Desc:		Delete item(s) from the hotlist
 Ret:		1 if successful, otherwise 0 or confess 
 Args:		-One or more list content fields to remove from hotlist.  
 			
=cut

sub hotlist_remove {
	my $self = shift;
	if(!@_) { warn "Nothing to remove from hotlist"; return }
	$self->{hotlist}->remove_items(@_);
	return 1;	
}

=head2 copy_items

 Usage:		$listh->copy_items(list_id_target, list_item_id1, list_item_id2, etc...);
 Desc:		Copy item from one list to another	
 Ret:		1 if successful, otherwise 0 or confess
 			-A valid list_id TO which we will copy items
 			-One or more list_item_id's

=cut

sub copy_items {  
	my $self = shift;  
	my $list_id_target = shift;

	foreach my $item_id (@_) {
		foreach my $list (@{$self->{lists}}) {
			foreach my $item (@{$list->get_items()}) {
				if ($item->get_id() == $item_id){
					CXGN::UserList::ListItem->create_new($self->{dbh}, $list_id_target, $item->get_content());
				}
			}
		}
	}
	return 1;
}

=head2 copy_list

 Usage:		$listh->copy_list($list_id_source, $alternate_owner);
 Desc:		Copy a list, such that two copies exist. The use of the alternate_owner parameter allows a user to
 			send a copy of his or her list to another user.
 Ret:		1 if successful, otherwise 0 or confess
 Args:		-A valid list_id that serves as the copy source
 			-(optional) an alternate owner (sp_person_id), used for sending copies of lists.  Since we can make
			textual list items, in theory, we can employ these methods as a messaging system, where other list
			items are the "attachments".  

=cut

sub copy_list {  
	my $self = shift;  
	my $list_id_source = shift;
	my $newOwner = shift;
	$newOwner ||= $self->{owner};
	
	foreach my $source_list (@{$self->{lists}}){
		if($source_list->get_id() == $list_id_source){
			my $newlist = CXGN::UserList::List->create_new($self->{dbh}, $newOwner, $source_list->get_name(), $source_list->get_description());
			if($newOwner != $self->{owner}) { $newlist->set_sent_by($self->{owner}) }
			my $item_id_list = $source_list->get_item_ids();
			$self->copy_items($newlist->get_id(), @$item_id_list);	
		}
	}
	return 1;	
}

=head2 delete_list

 Usage:		$listh->delete_list(list_id);
 Desc:		Delete list, which will destroy list_items by postgres CASCADE
 Ret:		1 if successful, otherwise 0 or confess 
 Args:		-A valid list_id for a list to be deleted

=cut

sub delete_list {  
	my $self = shift;  
	my $list_id = shift;

	my @newlistrefs = ();
	foreach my $list ( @{ $self->{lists} } ) {
		if($list->get_id() == $list_id) {
			$list->delete();
		}
		else {
			push(@newlistrefs, $list);
		}
	}
	#I know this looks improper, but it's much more efficient than storing and refetching everything
	$self->{lists} = \@newlistrefs;
	return 1;
}

###
1;#do not remove
###

=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut



