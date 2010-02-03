=head1 NAME

CXGN::UserList::Hotlist - a handle for more easily working with a hotlists.  
This is a subclass of CXGN::UserList::List, so all of the methods are the same, save the constructor, which verifies the presence of one and only one hotlist, creating a hotlist for the user (specified by Handle module) if a sp_person_id is not passed.  
If you want to, you can still use the List module for working with Hotlists, but this makes it easier and ensures that every user has a hotlist, plus it keeps you from doing dumb things like deleting a user's Hotlist.

=head1 SYNOPSIS

This object represents a user's hotlist, which contains references to ListItems.  There is only one hotlist for each user, and every user who doesn't have one will get one whenever CXGN::UserList::Handle is called

=cut



package CXGN::UserList::Hotlist;
use strict;
use CXGN::UserList::ListItem;
use base('CXGN::UserList::List');
use Carp;

=head2 new

 Usage:		my $hotlist = CXGN::UserList::Hotlist->new($dbh, $sp_person_id)
 Desc:		creates a new CXGN::UserList::Hotlist object
 Ret:		A handle for dealing with the user's Hotlist.
 Args:		* a database handle created from CXGN:DB::Connection
 		* An sp_person_id, hotlist owner.  If the user doesn't have a hotlist,
			a new one will be created automatically

=cut

sub new {
	my $class = shift;
	my $dbh = shift;
	my $sp_person_id = shift;
	my $self = bless({}, $class);
	unless(CXGN::DB::Connection::is_valid_dbh($dbh)){confess "Invalid DBH passed to CXGN::UserList";}
	unless(defined $sp_person_id) { 
		confess "No sp_person_id sent to Hotlist->new()."	
	}
	
	$self->{dbh} = $dbh;
	$self->{owner} = $sp_person_id;
	#if the hotlist doesn't exist, fetch() will make sure a new hotlist is created.	
	$self->fetch(); 	
	return $self;
}

=head2 create_new

 Usage:		Don't use this, overrides List->create_new()
 Desc:		creates a new CXGN::UserList::Hotlist object AND a new hotlist entry for the user, if one does not exist.
 			UNLIKE the List module, calling Hotlist->new() will ensure that this function gets called, so there is
			no reason to call this function explicitly!  
			Just use Hotlist->new() everytime, and don't worry about this subroutine.
 Ret:		Nothing, unlike List!
 Args:		* none

=cut

sub create_new {
	my $self = shift;  ## Once again, notice that this is an instance function and not a class function, unlike with List
	if(ref($self) ne "CXGN::UserList::Hotlist") { confess "Hotlist->create_new() is an instance function, not a class function"; }
	my $extramagic = shift;
	if($extramagic ne "4815162342") { confess "You really shouldn't call this function directly, hence the extra magic needed (2nd parameter)!" }
	my $dbh = $self->{dbh};
	my $sp_person_id = $self->{owner};
	
	#create a new hotlist!
# 	$dbh->do("BEGIN create_hotlist");
	my $create_q = $dbh->prepare("INSERT INTO list (owner, name, is_hotlist) VALUES (?, ?, TRUE)");
	$create_q->execute($sp_person_id, "Hotlist") or confess("Could not create new hotlist in database");
	$self->{list_id} = $dbh->last_insert_id("list", "sgn_people");
# 	$dbh->do("COMMIT create_hotlist");
}

=head2 fetch

 Usage:		$hotlist->fetch();
 Desc:		fetches current value from database and stores to internal data structure $hotlist->{items}
 Ret:		Nothing
 Args:		* none

=cut

sub fetch {
	my $self = shift;
	my $dbh = $self->{dbh}; 
	# We should make sure that the User has one and only one hotlist
	my $checkq = $dbh->prepare("SELECT list_id FROM list WHERE is_hotlist = TRUE AND owner=?");
	$checkq->execute($self->{owner}) or confess "Hotlist_id probe failed";
	my @hotlist_id = $checkq->fetchrow_array();
	if(!$hotlist_id[0]){
		$self->create_new("4815162342");	
	}
	else {
		my @double_id = $checkq->fetchrow_array();
		if(defined @double_id) { warn "User $self->{owner} has multiple hotlists, check into this"; }
		$self->{list_id} = $hotlist_id[0];
	}	
	my $itemq = $dbh->prepare("SELECT list_item_id FROM list_item WHERE list_id=?");
	$itemq->execute($self->{list_id}) or confess "Hotlist Item Fetch SQL Error";
	my @items = ();
	while(my ($list_item_id) = $itemq->fetchrow_array()){
		push(@items, CXGN::UserList::ListItem->new($dbh, $list_item_id));
	}
	$self->{items} = \@items;
	$self->{name} = "Hotlist";
	$self->{desc} = "The default list.  Every user has one Hotlist.";
	$self->{is_hotlist} = 1;
}

=head2 store

 Usage:		$hotlist->store();
 Desc:		Nothing needs to be stored regarding the Hotlist object, but all of its items will call their store subroutines
 			Pretty much unnecessary, unless ListItems don't auto-store their set data due to later changes in the code
 Ret:		Nothing
 Args:		* none

=cut

sub store {
	my $self = shift;
	foreach my $item (@{$self->{items}}) {
		$item->store();
	}
}	

=head2 delete

 Usage:		$hotlist->delete();
 Desc:		Dummy function that overrides very harmful List->delete(). Does nothing
 Ret:		Nothing
 Args:		* none

=cut

sub delete {
	#You cannot delete the hotlist
	warn "Hotlist cannot be deleted";
}

##All other functions in List module apply in the same way, or are at least harmless

####
1;###
####


=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut
