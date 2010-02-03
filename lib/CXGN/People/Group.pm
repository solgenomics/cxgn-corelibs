package CXGN::People::Group;
use strict;

=head1 CXGN::People::Group
 
 A module for dealing with groups of people on SGN. Mostly abstracts 
 sgn_people.sp_group table, but also does handling with sp_group_member 
 in matters regarding group membership.


=head1 Usage

 You can use this framework to access an existing group and its membership
 or create an entirely new one:

 my $group = CXGN::People::Group->new("BioFools");
 my @members = $group->members();
 foreach(@members){  #CXGN::People::Group::Member objects
 	$_->sp_person_id;
	$_->get_private_email
	$_->set_password("blank");
 }

 #New group creation
 my $group = CXGN::People::Group->new();
 $group->add_member(425);
 $group->add_member(333);
 $group->add_member($member);
 $group->name("BioFools");
 $group->description("Paving the way to a greener future");
 $group->store();

=cut

use base qw/CXGN::Class::DBI/;
use Class::MethodMaker
	[	scalar => 
	 	[qw/ 	
			sp_group_id 
			name 
			description 
			dbh			
		/], 
		array => 
		[qw/ 
			members 
			removed_members 
			added_members 
		/]
	];	

BEGIN {
	__PACKAGE__->required_search_paths(qw/sgn_people/);	
	our %q = (
		
		fetch =>

			"
				SELECT sp_group_id
				FROM sp_group
				WHERE name=?
			",

		create_group =>

			"
				INSERT INTO sp_group 
					(name, description) 
				VALUES 
					(?, ?)
			",

		update_group =>

			"
				UPDATE sp_group 
				SET name=?, description=?
			",

		remove_group =>

			"
				DELETE FROM sp_group_member 
				WHERE 
					sp_person_id=? 
					AND sp_group_id=?
			",

		add_group_member =>

			"
				INSERT INTO sp_group_member 
					(sp_person_id, sp_group_id) 
				VALUES 
					(?, ?)
			",
	);

	while(my($k,$v) = each %q){
		__PACKAGE__->set_sql($k,$v);
	}

}

sub new {
	my $class = shift;
	my ($dbh, $name) = @_;
	my $self = bless {}, $class;
	if($name){
		my $id_q = $self->get_sql('fetch');
		$id_q->execute($name);
		my $row = $id_q->fetchrow_hashref;
		$self->sp_group_id($row->{sp_group_id});
		$self->fetch();
	}
	return $self;
}

sub fetch {
	my $self = shift;
	return unless _have_id($self);	
	return unless _have_dbh($self);

	my $dbh = $self->dbh;
	my $gq = $dbh->prepare("SELECT name, description FROM sp_group WHERE sp_group_id=?");
	my $mq = $dbh->prepare("SELECT sp_person_id, status FROM sp_group_member WHERE sp_group_id=?");

	$gq->execute();
	my $group_row = $gq->fetchrow_hashref;
	$self->name($group_row->{name});
	$self->description($group_row->{description});
	
	$mq->execute();
	while(my $row = $mq->fetchrow_hashref){
		my $member = CXGN::People::Group::Member->new({
			dbh => $self->dbh,
			sp_person_id => $row->{sp_person_id}, 
			sp_group_id => $self->sp_group_id, 
			status => $row->{status}
		});
		$self->add_member($member);
	}

}	

sub store {
	my $self = shift;
	return unless _have_dbh($self);
	my $dbh = (ref $self)->DBH();
	my $make_group_q = $self->get_sql("create_group");
	my $update_group_q = $self->get_sql("update_group");

	#See if we are making a new group:
	unless(_have_id($self)){
		$make_group_q->execute($self->name, $self->description);
		$self->sp_group_id($dbh->last_insert_id("sgn_people.sp_group"));
	}
	else {
		$update_group_q->execute($self->name, $self->description);
	}


	my $add_q = $self->get_sql('add_group_member');
	my $remove_q = $self->get_sql('remove_group');
	foreach($self->added_members){
		$add_q->execute($_->sp_person_id, $self->sp_group_id);
	}
	foreach($self->removed_members){
		$remove_q->execute($_->sp_person_id, $self->sp_group_id);
	}
}

sub remove_member {
	my $self = shift;
	my $member_arg = shift;
	my $member_target;
	my @current = ();
	foreach my $m ($self->members){
		if(ref($member_arg) eq "HASH" && $m==$member_arg){
			$member_target = $m;
		}
		elsif($m->sp_person_id == $member_arg){
			$member_target = $m;
		}
		else{
			push(@current, $m);
		}
	}
	unless($member_target){
		print STDERR "Member $member_arg not found";
		return;
	}
	my @removed = $self->removed_members;	
	push(@removed, $member_target);
	$self->removed_members(@removed);
	$self->members(@current);
}

sub get_member_by_id {
	my $self = shift;
	my $id = shift;
	foreach my $member ($self->members){
		return $member if ($id == $member->sp_person_id);
	}
}

sub add_member {
	my $self = shift;
	my $member_arg = shift;
	if(ref($member_arg) eq "HASH"){
		my @current = $self->members;
		push(@current, $member_arg);
		$self->members(@current);
		my @added = $self->added_members;
		push(@added, $member_arg);
		$self->added_members(@added);
	}
	else { #you can add member by sp_person_id, also
		my $member = CXGN::People::Group::Member->new({
			dbh => $self->dbh,
			sp_person_id => $member_arg,
			sp_group_id => $self->sp_group_id,
		});
		$self->add_member($member) if $member->is_sp_person;
	}

}

sub _have_id {
	my $self = shift;
	unless($self->{sp_group_id}){
		print STDERR "Attempted operation on group with no sp_group_id\n";
		return 0;
	}
	return 1;
}

sub _have_dbh {
	my $self = shift;
	unless($self->{dbh}){
		print STDERR "Attempted operation on group with no database handle!\n";
		return 0;
	}
	return 1;
}


####
1;##
####
