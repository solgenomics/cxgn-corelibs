=head1 NAME

CXGN::People::Login - a class that deals with user metadata for logins.

=head1 TO DO:

All the functionalities in this class should really be moved to CXGN::People::Person (?? - not sure).

=head1 AUTHORS

Lukas Mueller, John Binns, Robert Buels
.
Copyleft (c) SOL Genomics Network. All rights reversed.

=cut

=head1 CXGN::People::Login Class

This class deals with the login user metadata.

It inherits from L<CXGN::DB::Object>.

=head1 SEE ALSO

L<CXGN::Login>, L<CXGN::People::Person>

=cut

package CXGN::People::Login;

use strict;

use CXGN::DB::Connection;
#use CXGN::Class::DBI;
our $EXCHANGE_DBH = 1;

use base qw | CXGN::DB::Object |;
#use base qw /CXGN::Class::DBI/;


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
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    $self->set_sql();
    if ($id) {
	$self->set_sp_person_id($id);
        $self->sp_login_fetch(); 
    }
    return $self;
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

    my $sp       = CXGN::People::Login->new($dbh);
    unless($sp){return undef;}
    chomp($username);
    my $sth   = $sp->get_sql('get_login');
    $sth->execute($username);
	 my ($sp_person_id) = $sth->fetchrow_array();

    my $self = CXGN::People::Login->new($dbh, $sp_person_id);
    return $self;
}

=head2 function sp_login_fetch()

Used internally to populate the object from the database.

=cut

sub sp_login_fetch {
    my $self  = shift;
    my $sth = $self->get_sql('fetch');
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
    my $self = shift;
    my $action='';
    #print STDERR "Preparing to store.\n";
    if ( $self->get_sp_person_id() ) {
        $action='updated';
        #print STDERR "Updating login record.\n";
        my $sth = $self->get_sql("update");
	  $sth->execute(
			$self->get_username(),      $self->get_private_email(),
			$self->get_pending_email(), $self->get_password(),
			$self->get_confirm_code(),  $self->get_disabled(),
			$self->get_user_type(),     $self->get_sp_person_id()
		       );
#print STDERR "VALUES: ".$self->get_username(), $self->get_private_email(), $self->get_pending_email(), $self->get_password(), $self->get_confirm_code(), $self->get_disabled()."\n";
#        if ( $sth->state() ) { return 0; }
#        else { return 1; }

    }
    else {
        $action='inserted';
        #print STDERR "Adding new login record...\n";
        my $un=$self->get_username();
        my $prive=$self->get_private_email();
        my $pende=$self->get_pending_email();
        my $pwd=$self->get_password();
        my $cc=$self->get_confirm_code();  
        my $dsa=$self->get_disabled();
        my $ut=$self->get_user_type();
        my $fn='<a href=\"/solpeople/contact-info.pl\">[please update</a>';
        my $ln='<a href=\"/solpeople/contact-info.pl\">name info]</a>';
        
		my $sth = $self->get_sql("insert");
#		my $DBH = $self->DBH();
        #print STDERR "Preparing to execute login insert\n";
        $sth->execute($un,$prive,$pende,$pwd,$cc,$dsa,$ut,$fn,$ln);
        my $person_id=$self->get_dbh()->last_insert_id('sp_person','sgn_people');
        #print STDERR "Executed login insert";
        $self->{sp_person_id} = $person_id;
    }
    return 1;
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
    my $self =shift;
    $self->{sp_person_id}=shift;
}

=head2 function get_password()

  Synopsis:	my $password = $p->get_password()
  Arguments:	none
  Returns:	the password for login object $p.
                Note that passwords are being stored unencrypted in
                the database. The obtained password is clear text.
  Side effects:	none
  Description:	Accessor for the password property.

=cut

sub get_password {
    my $self = shift;
    return $self->{password};
}

=head2 function set_password()

  Synopsis:	$p->set_password("hallo");
  Arguments:	the password
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

=head2 functions get_user_type(), set_user_type()

  Synopsis:	$p->set_user_type("sequencer");
  Arguments:	the desired user type. Different types of users have
                different access rights. Currently defined user types
                are\: user (default), submitter, curator (has all access
                rights, kind of the root user), sequencer (can set BAC 
                sequencing statuses).
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_user_type {
    my $self = shift;
    if (exists ($self->{user_type})) {
	return $self->{user_type};
    } else {
	return "user";
    }
}

sub set_user_type {
    my $self = shift;
    $self->{user_type} = shift;
}

sub set_sql { 
    my $self = shift;

    $self->{queries} = {

	fetch =>

		"
			SELECT 
				sp_person_id, username, private_email, pending_email, 
				password, confirm_code, disabled, user_type 
			FROM sgn_people.sp_person 
			WHERE sp_person_id=?
		",

	update =>

		"
			UPDATE sgn_people.sp_person 
			SET 
				username=?, private_email=? , pending_email=?, password=?, 
				confirm_code=?, disabled=?, user_type=? 
			WHERE 
				sp_person_id = ?
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
                user_type, 
                first_name, 
                last_name
            ) 
            VALUES (?,?,?,?,?,?,?,?,?)
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

	};

	while(my($name,$sql) = each %{$self->{queries}}){
		$self->{query_handles}->{$name} = $self->get_dbh()->prepare($sql);
	}
}

sub get_sql { 
    my $self =shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}



###
1;#do not remove
###
