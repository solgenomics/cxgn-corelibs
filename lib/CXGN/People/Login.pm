package CXGN::People::Login;

=head1 NAME

CXGN::People::Login - a class that deals with user metadata for logins.

=head1 TO DO:

All the functionalities in this class should really be moved to CXGN::People::Person (?? - not sure).

=head1 AUTHORS

Lukas Mueller, John Binns, Robert Buels
.
Copyleft (c) Sol Genomics Network. All rights reversed.

=cut

=head1 CXGN::People::Login Class

This class deals with the login user metadata.

It inherits from L<CXGN::DB::Object>.

=head1 SEE ALSO

L<CXGN::Login>, L<CXGN::People::Person>

=cut


use strict;

use CXGN::DB::Connection;

our $EXCHANGE_DBH = 1;

use base qw | CXGN::DB::Object |;

=head1 CONSTRUCTORS

=head2 constructor new()

  Synopsis:	$p=CXGN::People::Login->new($person_id)
  Arguments:	a login id or undef
  Returns:	the corresponding login object or an empty login object
  Side effects:	establishes a connection to the database
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh   = shift;
    my $id    = shift;
    my $self  = $class->SUPER::new($dbh);
    $self->set_sql();
    if ($id) {
        $self->set_sp_person_id($id);
        $self->sp_login_fetch();
    }
    return $self;
}


=head2 function get_person_by_email()

 Usage: my ($sp_person_id1, $sp_person_id, ...) = CXGN::People::Person->get_person_by_email($dbh, $username)
 Desc:  find the sp_person_id of user $username 
 Ret:   a list of matching sp_person_ids
 Args:  $dbh, $email
 Side Effects:
 Example:

=cut

sub get_login_by_email {
    my $class    = shift;
    my $dbh      = shift;
    my $email = shift;

    print STDERR "getting login by email with $email\n";
    my $login = CXGN::People::Login->new($dbh); # create empty login object
    my $sth    = $login->get_sql("login_from_email");
    $sth->execute($email);
    my @person_ids;
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 

	push @person_ids, $sp_person_id;
    }
    
    return @person_ids;
}

=head2 function get_person_by_email()

 Usage: my ($sp_person_id1, $sp_person_id, ...) = CXGN::People::Person->get_person_by_email($dbh, $username)
 Desc:  find the sp_person_id of user $username 
 Ret:   a list of matching sp_person_ids
 Args:  $dbh, $email
 Side Effects:
 Example:

=cut

sub get_login_by_token {
    my $class    = shift;
    my $dbh      = shift;
    my $token = shift;

    my $person = CXGN::People::Person->new($dbh);  #emtpy object
    my $sth    = $person->get_sql("person_from_token");
    $sth->execute($token);
    my ($sp_person_id) = $sth->fetchrow_array();
    return $sp_person_id;
}


=head2 construtor get_login()

  Synopsis:	$p->get_login("mickey_mouse");
  Arguments:	a username
  Returns:	a login object
  Side effects:	
  Description:	if the username does not exist, an empty object
                is returned.

=cut

sub get_login {

   # alternate constructor generating an sgn_people object when given a username
    my $class    = shift;
    my $dbh      = shift;
    my $username = shift;

    my $sp = CXGN::People::Login->new($dbh);
    unless ($sp) { return undef; }
    chomp($username);
    my $sth = $sp->get_sql('get_login');
    $sth->execute($username);
    my ($sp_person_id) = $sth->fetchrow_array();

    my $self = CXGN::People::Login->new( $dbh, $sp_person_id );
    return $self;
}

=head2 function sp_login_fetch()

Used internally to populate the object from the database.

=cut

sub sp_login_fetch {
    my $self = shift;
    my $sth  = $self->get_sql('fetch');
    $sth->execute( $self->get_sp_person_id() );

    my $hashref = $sth->fetchrow_hashref();
    foreach my $k ( keys(%$hashref) ) {
        $self->{$k} = $$hashref{$k};
    }
}

=head2 function store

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	 store() is used to store the object in the database.
  Description:	 Note that if an sp_person_id is available, an update occurs.
                 If the sp_person_id is undef, an insert occurs.

=cut

sub store {

# store updates the record if an id is defined, or inserts a new row if $id is undefined.
    my $self   = shift;
    my $action = '';
    if ( $self->get_sp_person_id() ) {
        $action = 'updated';
        $self->get_dbh->do(
            <<EOQ, undef,
                           UPDATE sgn_people.sp_person
                           SET   username      = ?
                               , private_email = ?
                               , pending_email = ?
                               , confirm_code  = ?
                               , disabled      = ?
                               , user_type     = ?
	                       , organization  = ?
                           WHERE
                               sp_person_id = ?
EOQ
            $self->get_username,
            $self->get_private_email,
            $self->get_pending_email,
            $self->get_confirm_code,
            $self->get_disabled,
            $self->get_user_type,
            $self->get_organization,
            $self->get_sp_person_id,
        );
	$self->add_role($self->get_user_type()); 
	

    }
    else {
        $action = 'inserted';

        my $un    = $self->get_username();
        my $prive = $self->get_private_email();
        my $pende = $self->get_pending_email();
        my $pwd   = $self->get_password();
        my $cc    = $self->get_confirm_code();
        my $dsa   = $self->get_disabled();
        my $fn  = '<a href="/solpeople/contact-info.pl">[click to update]</a>';
        my $ln  = '<a href="/solpeople/contact-info.pl">[click to update]</a>';
	my $org = $self->get_organization();
        my $sth = $self->get_sql("insert");

        $sth->execute( $un, $prive, $pende, $pwd, $cc, $dsa, $fn, $ln, $org );
        my $person_id =
          $self->get_dbh()->last_insert_id( undef, 'sgn_people', 'sp_person', 'sp_person_id' );
        $self->{sp_person_id} = $person_id;
        print STDERR "NEW USER SP_PERSON_ID: ".$person_id."\n";
	$self->add_role($self->get_user_type());
    }
    return 1;
}


# this is for the use case where the password needs to be verified again
# even after login, such as for a password or username change.
#
sub verify_password { 
    my $self = shift;
    my $password = shift;
    
    my $h = $self->get_sql('verify_password');
    $h->execute($self->get_username(), $password);
    
    my ($flag) = $h->fetchrow_array();

    print STDERR "Checked password $password with result $flag.\n";
    return $flag;
}

sub update_password { 
    my $self = shift;
    my $password = shift;
    
    if (!$self->get_sp_person_id()) { 
	die "NEED TO STORE PERSON OBJECT BEFORE UPDATING PASSWORD!";
    }
    my $q = "UPDATE sgn_people.sp_person SET password = crypt('$password', gen_salt('bf')) WHERE sp_person_id=? RETURNING sp_person_id";
    my $h = $self->get_dbh()->prepare($q);
    print STDERR "Updating password with $password for id ".$self->get_sp_person_id()."\n";
    $h->execute($self->get_sp_person_id());
    my ($flag) = $h->fetchrow_array();
    
    print STDERR "Checked password $password with result $flag.\n";
    return $flag;
    
}

=head2 update_confirm_code

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub update_confirm_code { 
    my $self = shift;
    my $confirm_code = shift;
    
    if (!$self->get_sp_person_id()) { 
	die "NEED TO STORE PERSON OBJECT BEFORE UPDATING PASSWORD!";
    }
    my $q = "UPDATE sgn_people.sp_person SET confirm_code = '$confirm_code' WHERE sp_person_id=? RETURNING sp_person_id";
    my $h = $self->get_dbh()->prepare($q);
    print STDERR "Updating confirm_code with $confirm_code for id ".$self->get_sp_person_id()."\n";
    $h->execute($self->get_sp_person_id());
    my ($flag) = $h->fetchrow_array();
    
    return $flag;
    
}

=head2 accessors get_sp_person_id(), set_sp_person_id()

  Synopsis:	my $person_id = $p->get_sp_person_id()
  Arguments:	none
  Returns:	the sp_person_id (primary key of that object)
  Side effects:	none
  Description:	

=cut

sub get_sp_person_id {
    my $self = shift;
    return $self->{sp_person_id};
}

sub set_sp_person_id {
    my $self = shift;
    $self->{sp_person_id} = shift;
}

# =head2 function get_password()

#   Synopsis:	my $password = $p->get_password()
#   Arguments:	none
#   Returns:	the password for login object $p.
#                 Note that passwords are being stored as BF encoded hash
#                 plus salt the database.
#   Side effects:	none
#   Description:	Accessor for the password property.

# =cut

# only here for storage of the password - should not be used in any other way.

sub get_password {
     my $self = shift;
     return $self->{password};
 }

=head2 function set_password()

  Synopsis:	$p->set_password("hallo");
  Arguments:	the password in clear text. Will be stored as a BF encoded hash.
  Returns:	nothing
  Side effects:	account defined by $p will require $password to login
  Description:	note that passwords are stored unencrypted. 

=cut

sub set_password {
    my $self = shift;
    $self->{password} = shift;
}


=head2 functions get_username(), set_username()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	Accessors for the username property

=cut

sub get_username {
    my $self = shift;
    return $self->{username};
}

sub set_username {
    my $self = shift;
    $self->{username} = shift;
}

=head2 function get_private_email(), set_private_email

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	accessors for the get_private_email property
  Description:	

=cut

sub get_private_email {
    my $self = shift;
    return $self->{private_email};
}

sub set_private_email {
    my $self = shift;
    $self->{private_email} = shift;
}

=head2 function get_pending_email(), set_pending_email()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	accessors for the pending_email property.
                This is the address the confirmation email will be 
                sent to. After that, it has no function, but is 
                not removed from the database (afaikoc) 

=cut

sub get_pending_email {
    my $self = shift;
    return $self->{pending_email};
}

sub set_pending_email {
    my $self = shift;
    $self->{pending_email} = shift;
}

=head2 function set_confirm_code(), get_confirm_code()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	accessors for the confirm_code property. This
                code is set before a confirmation email is sent out
                to activate an account.

=cut

sub set_confirm_code {
    my $self = shift;
    $self->{confirm_code} = shift;
}

sub get_confirm_code {
    my $self = shift;
    return $self->{confirm_code};
}

=head2 functions get_disabled(), set_disabled()

  Synopsis:	$p->set_disabled(1);
  Arguments:	boolean value, 1=account disabled, 0=account enabled.
  Returns:	nothing
  Side effects:	
  Description:	accessors for the diabled property. If disabled 
                is set to 1, the account is ignored by searches.

=cut

sub set_disabled {
    my $self = shift;
    $self->{disabled} = shift;
}

sub get_disabled {
    my $self = shift;
    return $self->{disabled};
}

=head2 accessors get_organization(), set_organization()

=cut

sub get_organization {
    my $self = shift;
    return $self->{organization};
}

sub set_organization {
    my $self = shift;
    $self->{organization} = shift;
}


=head2 new_role

 Usage:        $p->new_role($role)
 Desc:         creates the role $role, without associating it to $p.
               (see add_role()).
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new_role {
    my $self = shift;
    my $role = shift;
    my $sp_role_id = $self->exists_role($role);
    if (!$sp_role_id) { 
	my $q = "INSERT INTO sgn_people.sp_roles (name) VALUES (?) RETURNING sp_role_id";
	my $s = $self->get_dbh()->prepare($q);
	$s->execute(lc($role));
	($sp_role_id) = $s->fetchrow_array();
    }
    return $sp_role_id;
}

=head2 exists_role

 Usage:        $p->exists_role($role)
 Desc:         returns true if the role $role exists (also outside of $p).
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_role {
    my ( $self, $role ) = @_;

    my ($sp_role_id) = $self->get_dbh->selectrow_array(<<'', undef, $role );
SELECT sp_role_id
FROM sgn_people.sp_roles
WHERE name ILIKE ?

    return $sp_role_id;
}



=head2 add_role

 Usage:        $p->add_role($role)
 Desc:         adds role $role to person $p. Creates a new role if 
               the role does not exist.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_role {
    my $self = shift;
    my $role = shift;

    if (!$role) { return; }

    my $sp_role_id = $self->exists_role($role);
    
    if (!$sp_role_id) { 
	#warn "INSERTING NEW ROLE $role...\n";
	$sp_role_id =$self->new_role($role);
    }
    my $exists = $self->get_dbh()->do("SELECT count(*)  
                                       FROM sgn_people.sp_person_roles
                                       JOIN sgn_people.sp_roles using(sp_role_id) WHERE name='$role'");

    if ($exists>1) { return; }

    my $q = "INSERT INTO sgn_people.sp_person_roles (sp_person_id, sp_role_id) VALUES (?, ?)";
    my $s = $self->get_dbh()->prepare($q);
    $s->execute($self->get_sp_person_id(), $sp_role_id);
    return $sp_role_id;
}


=head2 remove_role

 Usage:        $p->remove_role($role);
 Desc:         removes the association of role $role from the person $p.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub remove_role {
    my $self = shift;
    my $role = shift;
    if (my $sp_role_id = $self->exists_role($role)) { 
	my $q = "DELETE FROM sgn_people.sp_person_roles WHERE sp_person_id=? AND sp_role_id=?";
	my $s = $self->get_dbh()->prepare($q);
	my $count = $s->execute($self->get_sp_person_id(), $sp_role_id);
	#warn "role $role removed ($count).\n";
    }
    else { 
	warn "Role $role not associated with person ".$self->get_sp_person_id()."\n";
    }
}

=head2 has_role

 Usage:        $p->has_role('curator')
 Desc:         returns true if $p is a curator, false otherwise
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub has_role {
    my $self = shift;
    my $role = shift;
    my @roles = $self->get_roles();
    foreach my $r (@roles) { 
	if ($r eq $role) { 
	    return 1;
	}
    }
    return 0;
}

=head2 get_roles

 Usage:
 Desc:         returns a list of roles.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_roles {
    my $self = shift;
    my $q = "SELECT name FROM sgn_people.sp_person_roles JOIN sgn_people.sp_roles USING (sp_role_id) WHERE sp_person_id=? order by sp_role_id";
    my $s = $self->get_dbh()->prepare($q);
    $s->execute($self->get_sp_person_id);
    my @roles = ();
    while (my ($r) = $s->fetchrow_array()) {
	push @roles, $r;
    }
    return @roles;
}


=head2 get_first_name

 Usage:
 Desc:         returns the user's first name.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_first_name {
    my $self = shift;
    return $self->{first_name};
}

=head2 get_last_name

 Usage:
 Desc:         returns the user's last name.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_last_name {
    my $self = shift;
    return $self->{last_name};
}

=head2 get_user_type

 Usage:
 Desc:          this get_user_type has been re-wired to get the 
                highest ranking role (with the loweste id) to make it
                compatible with the new roles system.
                THIS FUNCTION IS DEPRECATED. use get_roles() or has_role()
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_user_type {
    my $self = shift;
    if ($self->{user_type}) { 
	return $self->{user_type};
    }
    my @roles = $self->get_roles();
    my $user_type =  shift(@roles);
    # return the 'lowest' role
    if (!$user_type) { return 'user'; }
    else { return $user_type; }

}

=head2 set_user_type

 Usage:        this sets a user_type, which will be stored as a role 
               in store(). Access as $p->{user_type}.
               THIS FUNCTION IS DEPRECATED. Use add_role()
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_user_type {
    my $self = shift;
    my $role = shift;
    
    $self->{user_type}=$role;
}

sub set_sql {
    my $self = shift;

    $self->{queries} = {

        fetch =>

          "
			SELECT 
				sp_person_id, username, private_email, pending_email, 
				password, confirm_code, disabled, first_name, last_name
			FROM sgn_people.sp_person 
			WHERE sp_person_id=?
		",

        insert =>

          "
            INSERT into sgn_people.sp_person 
            (
                username, 
                private_email, 
                pending_email, 
                password, 
                confirm_code, 
                disabled, 
                first_name, 
                last_name,
                organization
            ) 
            VALUES (?,?,?,crypt(?, gen_salt('bf')),?,?,?,?,?)
        ",

        get_login =>

          "
			SELECT sp_person_id 
			FROM sgn_people.sp_person 
			WHERE username ilike ?
		",

        user_from_cookie =>

          "
			SELECT sp_person_id
			FROM sgn_people.sp_person
			WHERE cookie_string=?
		",
	verify_password => 
	" SELECT count(*) FROM sgn_people.sp_person WHERE username = ? AND  (password = crypt( ?, password))",
	
	update_password => 
	" UPDATE sgn_people.sp_person SET password = crypt(?, gen_salt('bf')) WHERE sp_person_id=?",
	
		login_from_email => 
                        "       SELECT sp_person_id 
                                FROM sgn_people.sp_person
                                WHERE private_email ilike ?",

	person_from_token => 
                       "        SELECT sp_person_id
                                FROM sgn_people.sp_person
                                WHERE confirm_code = ? AND disabled IS NULL",



    };

    while ( my ( $name, $sql ) = each %{ $self->{queries} } ) {
        $self->{query_handles}->{$name} = $self->get_dbh()->prepare($sql);
    }
}

sub get_sql {
    my $self = shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}

###
1;    #do not remove
###
