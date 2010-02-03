=head1 Name

CXGN::UserPrefs

=head1 Synopsis

A module for handling user preferences (setting and retrieving) using
a long ( <= 4KB ) cookie string in the user table.  This module MUST
be used BEFORE HTTP Headers are sent to the browser, cuz we got
cookies to set, cuz.

WARNING: unix epoch time comparison is used, so implementation of this
code on a Macintosh server will require some changes!! [search for
time()]

=head1 AUTHOR

Chris Carpita <csc32@cornell.edu>

=cut

package CXGN::UserPrefs;

use CXGN::DB::Connection;
use CXGN::Login;
use CXGN::Cookie;

use base qw | CXGN::DB::Object |;

=head2 new()
	
	Creates a new UserPrefs object which allows receiving and setting individual preferences.  The string is set to the database on $handle->store();
	If a session is found, the string will be auto-fetched.
	Usage: my $handle = CXGN::UserPrefs->new( $dbh );

=cut

sub new {
    my $class=shift;
    my $dbh = shift;
    my $sp_person_id = shift; #should be provided for initializing on just_logged_in
    my $self = $class->SUPER::new($dbh);
    my $loginh = CXGN::Login->new($self->get_dbh());
    if($sp_person_id > 0) {
	$self->{sp_person_id} = $sp_person_id;
    }
    else {
	$self->{sp_person_id} = $loginh->has_session();
    }
    unless($self->{sp_person_id}) {  #anonymous user
	$self->{sp_person_id} = 0;
	$self->{user_pref_string} = CXGN::Cookie::get_cookie("user_prefs");
	$self->{direct_set} = 0;
	$self->_build_preferences_hash();
	return $self 
    }
    $self->{direct_set} = 0; #flag for direct setting of user_pref string
    $self->fetch();
    unless($self->{preferences}->{sp_person_id} && $self->{preferences}->{timestamp}) {
	$self->store();  ##ensures that a user will get her cookie worked-over if the proper values don't exist
    }
    return $self;
}

=head2 fetch()

	Grabs the user_prefs string from the sp_person table and creates a hash for manipulating individual preferences.  This subroutine
	gets called automatically if a session is found in the constructor.

=cut

sub fetch {
	my $self = shift;
	if(!$self->{sp_person_id}) { return }
	my $query = $self->get_dbh()->prepare("SELECT user_prefs FROM sp_person WHERE sp_person_id=?");
	$query->execute($self->{sp_person_id});
	my @result = $query->fetchrow_array();
	$self->{user_pref_string} = $result[0];
	$self->_build_preferences_hash();
	$self->_exchange_user_prefs();
}

=head2 _build_preferences_hash

Builds the hash from the current user_pref_string to be referenced by $self->{preferences}

=cut

sub _build_preferences_hash {
	my $self = shift;	
	my @prefs = split /:/, $self->{user_pref_string};
	my %prefhash;
	foreach my $pref (@prefs) {
		my ($name, $val) = split /=/, $pref;
		$prefhash{$name} = $val;
	}
	$self->{preferences} = \%prefhash;
}

=head2 _exchange_user_prefs

Negotiates precedence of browser cookie vs. database cookie string and gets both on the same page, so to speak.  No need to call this directly.  Exchanging will only occur where the UserPrefs module is actually used.

=cut

sub _exchange_user_prefs {
	my $self = shift;
	my $user_prefs = CXGN::Cookie::get_cookie("user_prefs");
	my $cookie_precedence = 0;

	if(length($user_prefs)>2){  #userpref string exists in some form a=1 (?)
		my ($person_id_check) = $user_prefs =~ /sp_person_id=(\d+)/;
		my ($cookie_timestamp) = $user_prefs =~ /timestamp=(\d+)/;
#		die $cookie_timestamp . ">" . $self->{preferences}->{timestamp} . "?";
		if($person_id_check == $self->{sp_person_id} && $cookie_timestamp >= $self->{preferences}->{timestamp}) {
			$cookie_precedence = 1;	
		}
	}
	#cookie string is the newer one
	if($cookie_precedence){
		my $query = $self->get_dbh()->prepare("UPDATE sp_person SET user_prefs=? WHERE sp_person_id=?");
		$query->execute($user_prefs, $self->{sp_person_id}) or die "Store Failed: $@";
		$self->{user_pref_string} = $user_prefs;
		$self->_build_preferences_hash();
	}
	#database string is the newer one
	else { 
		$self->store();	 #for updating the time-stamp
		CXGN::Cookie::set_cookie("user_prefs", $self->{user_pref_string});
	}
}

=head2 store()

	Usage: $handle->store();
	Creates the cookie user_prefs string based on set preferences in the hash and updates the database, unless the
	cookie string has been directly set with get_user_pref_string, in which case it is not recreated from the hash.

=cut

sub store {
	my $self = shift;
	if(!$self->{sp_person_id}) { return }
	my $newstring = "";
	unless($self->{direct_set}){
		my $j = 0;
		$self->{preferences}->{timestamp} = 1000*time();  #better to multiply in perl than divide in javascript.
		$self->{preferences}->{sp_person_id} = $self->{sp_person_id};
		while (my ($key, $value) = each %{$self->{preferences}}) {
			if($j) { $newstring .= ":" }
			$newstring .= $key . "=" . $value;
			$j++;
		}
		$self->{user_pref_string} = $newstring;
	}
	$self->{direct_set} = 0;
	CXGN::Cookie::set_cookie('user_prefs', $self->{user_pref_string});
	my $query = $self->get_dbh()->prepare("UPDATE sp_person SET user_prefs=? WHERE sp_person_id=?");
	$query->execute($self->{user_pref_string}, $self->{sp_person_id}) or die "Store Failed: $@";
}	

=head2 get_user_pref_string()

	Returns the user_prefs string, which should be set to a javascript global variable in the header.  Otherwise,
	there is really no need to use this function.

=cut

sub get_user_pref_string {
	my $self = shift;
	return $self->{user_pref_string};
}

=head2 set_user_pref_string()

	Sets the user_prefs string, which allows quick writing of the user's existing cookie to the database.  If this subroutine is
	called, then another variable will be set indicating that this method has precedence over setting the individual hash elements
	before the next store().

=cut

sub set_user_pref_string {
	my $self = shift;
	my $newstring = shift;
	$self->{direct_set} = 1;
	$self->{user_pref_string} = $newstring;
}

=head2 set_pref($name, $value)

	Usage: $handle->set_pref('skin', 'aqua'); # not a real setting ;)
	Sets the proper value in the preferences hash.  To actually update this in the database, call $handle->store();

=cut

sub set_pref {
	my $self = shift;
	my ($name, $value) = @_;
	$self->{preferences}->{$name} = $value;
}

=head2 get_pref($name)
	
	Usage: $handle->get_pref('searchHidden');
	Returns the preference value.  We will use this one a lot ;)

=cut

sub get_pref {
	my $self = shift;
	my $name = shift;
	return $self->{preferences}->{$name};
}	


####
1;###
####
