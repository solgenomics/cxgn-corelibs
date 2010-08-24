
=head1 NAME

CXGN::People::Person - a class to deal with user data

=head1 SYNOPSIS

 my $p = CXGN::People::Person->new($dbh, $person_id);
 my $fn = $p->get_first_name();
 my $ln = $p->get_last_name();
 #... etc

=head1 DESCRIPTION

This class handles all user data for the CXGN framework and links to things such as user meta data, user comments, user interests, user maps, user preferences, and other data. 

Initially, this class used to create a new database handle for every object created. This was then replaced by a complicated caching scheme that (unfortunately) relied on global variables, which was incompatible with mod_perl (a compatibility issue only visible if there were several virtual host running different instances of CXGN::People::Person. The bug had the effect that database handles were transferred between virtual hosts, with one virtual host suddenly accessing data of the other. Ouch!!!!). 

Another refactoring was undertaken to have the constructor accept a database handle, as most other classes in the CXGN codebase do it, which allows finer control over the number of database connections generated, and easy connection to the database of choice (for example, user objects can easily be instantiated from different databases and compared etc).

This class also handles a lot of the BAC status management, which it probably shouldn't.

=head1 AUTHORS

Lukas Mueller, John Binns, Robert Buels, Evan Herbst.

Copyleft (c) Sol Genomics Network. All rights reversed. Hahaha!


=head1 METHODS

This class implements the following methods:

=cut


package CXGN::People::Person;

use strict;
use Carp qw/ cluck carp confess /;
use Scalar::Util qw/ blessed /;
use namespace::autoclean;

#use CXGN::Class::DBI;

use CXGN::Genomic::Clone;
use CXGN::People::Organism;

#use base qw/CXGN::People::Login CXGN::Class::DBI/;
use base qw | CXGN::People::Login |;


=head1 CLASS METHODS

=head2 function get_curators()

 Usage:    my @curators = CXGN::People::Person::get_curators($dbh);
 Desc:     returns a list with the user ids of the curators in the database.

=cut

sub get_curators { 
    my $dbh = shift;
    my $query = "SELECT sp_person_id FROM sgn_people.sp_person WHERE user_type='curator' ";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @ids = ();
    while (my ($sp_person_id) = $sth->fetchrow_array()) { 
	push @ids, $sp_person_id;
    }
    return @ids;
}


=head1 CONSTRUCTORS

=head2 constructor new()

 Usage:        Constructor. 
 Example:      $p = CXGN::People::Person->new($dbh, $person_id);
 Args:         A database handle and an optional person id.
 Side Effects: The user with person id $person_id is fetched from the 
               database. If $person_id is omitted, an empty object
               is created.
        
 Note:         This is equivalent to calling new_person().
               The database handle has been added as a parameter
               in a refactoring on 4/2009. Please update your scripts.

=cut

sub new {
    my $class=shift;
    my $dbh = shift;
    confess "first param must be a dbh" unless blessed($dbh) &&  $dbh->can('selectall_arrayref');
    my $person_id = shift;
    my $self = CXGN::People::Login->new($dbh, $person_id);
	bless $self, $class;

    $self->set_sql();
    $self->set_sp_person_id($person_id);
    if ( $self->get_sp_person_id() ) {
        $self->fetch( $self->get_sp_person_id() );
    }
    return $self;
}

=head2 constructor new_person()

  Synopsis:	my $p->CXGN::People::Person->new_person($person_id)
  Arguments:	a person_id. Note that the regular constructor new()
                takes a person_id as a parameter, which is highly confusing.
  Returns:	an instance of a CXGN::People::Person object.
  Side effects:	Establishes a connection to the database.
  Description:	
  NOTE: THIS FUNCTION IS DEPRECATED!!!!

=cut

sub new_person {

    die "CXGN::People::Person new_person is not supported anymore!";
    # this is the constructor for which you use the person_id.
    my $class      = shift;
    my $dbh        = shift;
    my $id         = shift;
    my $self = CXGN::People::Login->new($dbh, $id);
    bless $self, $class;
	return $self;
}


=head1 CLASS METHODS

=head2 function get_person_by_username()

 Usage: my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username)
 Desc:  find the sp_person_id of user $username 
 Ret:   sp_person_id
 Args:  $dbh, $username
 Side Effects:
 Example:

=cut

sub get_person_by_username {
    my $class = shift;
    my $dbh= shift;
    my $username=shift;
    
    my $person = CXGN::People::Person->new($dbh);
    my $sth=$person->get_sql("person_from_username");
    $sth->execute($username);
    my ($sp_person_id) = $sth->fetchrow_array();
    return $sp_person_id;
}


=head1 METHODS

=head2 function get_bacs_associated_with_person()

  Synopsis:	$p->get_bacs_associated_with_person();
  Arguments:	none
  Returns:	a list of a list containing BAC status and attribution 
                information. The inner list contains: 
                bac_id, project_name, arizona name
  Side effects:	
  Description:	
  Notes:        

=cut


sub get_bacs_associated_with_person 
{
    my $self=shift;
    my $chr = shift || 1;
    my $person_id=$self->get_sp_person_id(); 
    my $bacs_query;

    if($self->get_user_type() eq 'sequencer')
    {
		$bacs_query = $self->get_sql('sequencer_bacs');
        $bacs_query->execute($person_id);
    }

    elsif($self->get_user_type() eq 'curator')
    {
		$bacs_query = $self->get_sql("curator_bacs");	
        $bacs_query->execute($chr);
    }
    else
    {
        return;
    }
    my $answer=$bacs_query->fetchall_arrayref();

    #HACK! physical.bacs is now restructured as genomic.clone.
    for my $row(@{$answer})
    {
        my($row_id,$project_id,$az_name)=@{$row};
        unless(defined($az_name))
        {
            eval
            {
                require CXGN::Genomic::Clone;#grrrr this cannot be simply "used" at the top since it is so prone to failure at the moment, for instance when there is no database connectivity
            };
            if($@)
            {
                $row->[2]='Database connection not available.';
            }
            else
            {
                $row->[2]=CXGN::Genomic::Clone->retrieve($row_id)->arizona_clone_name();
            }
        }
    }
    #END HACK!
    return $answer;
}

sub get_projects_associated_with_person {
    my $self = shift;

    if( $self->get_user_type() eq 'curator' ) {
		my $sth = $self->get_sql('all_projects');
		$sth->execute();
		my $ary = $sth->fetchall_arrayref;
		return map { $_->[0] } @$ary;
    }

    my $sth = $self->get_sql('projects_for_person');
    $sth->execute($self->get_sp_person_id(), '%Tomato%Unmapped%');
    my $answer=$sth->fetchall_arrayref();
    if($answer) {
        return map { $_->[0] } @{$answer};
    }
    else {
        return;
    }
}

=head2 function is_person_associated_with_project()

  Synopsis:	$p->is_person_associated_with_project();
  Arguments:	project_id
  Returns:	true if person_id is associated with project_id 
  Side effects:	
  Description:	

=cut

sub is_person_associated_with_project {
    my $self = shift;
    my ( $project_id ) = @_;
    return 1 if($self->get_user_type() eq 'curator');

    our ($unmapped_project_id) ||= do {
      my $sth = $self->get_sql('project_by_name');
      $sth->execute('%Tomato%unmapped%');
      $sth->fetchrow_array();
    };
    return 1 if $project_id == $unmapped_project_id;

    my $person_id = $self->get_sp_person_id();
    
	my $project_person_query = $self->get_sql("check_if_person_on_project");
    $project_person_query->execute( $person_id, $project_id );
    my @project_person_result = $project_person_query->fetchrow_array();
    $project_person_query->finish();

    return 1 if($project_person_result[0]);
	return 0;
}

# function fetch() is used internally to populate the instance from the
# database.
#
sub fetch {
    my $self = shift;

    my $sth = $self->get_sql("fetch");
    $sth->execute( $self->get_sp_person_id() );

    my $hashref = $sth->fetchrow_hashref();
    foreach my $k ( keys(%$hashref) ) {
        $self->{$k} = $$hashref{$k};
    }

}

=head2 function store()

  Synopsis:	    Store all non-account-related person info. For username, password,
                etc, see People::Login::store().
  Arguments:	
  Returns:	
  Side effects:	function store() is used to store the object to the database
                backend store.
  Description:  Note that objects that have no primary key 
                assigned cause a database entry to be inserted, while objects 
                with a primary key cause a database entry to be updated.

=cut

sub store {
    my $self         = shift;
    my $return_value = "";
	 
	{
	 my $sos = "";
	 foreach my $o ($self->get_organisms())
	 {
	 	if($o->is_selected()) {$sos .= $o->get_sp_organism_id() . " ";}
		else {$sos .= "(" . $o->get_sp_organism_id() . ") ";}
	 }
	}

    #print STDERR "STORING PERSON DATA...\n";
    #
    # if an id is available, we update the existing record
    #
    my $s= $self->get_sql("person_count");
    $s->execute($self->get_sp_person_id());
    my $rows = ( $s->fetchrow_array() )[0];

    #print STDERR "ROWS: $rows\n";
    if ( $rows > 1 ) {
        die("Too many people associated with one login!\n");
    }
    my $action='';
    if ($rows) {
        $action='updated';
        #print STDERR "Updating person record ".$self->get_sp_person_id()."\n";
        my $sth = $self->get_sql("update");
        $sth->execute(
            $self->get_censored(),
	    $self->get_salutation(),
            $self->get_last_name(),
	    $self->get_first_name(),
            $self->get_organization(),
	    $self->get_address(),
            $self->get_country(),
	    $self->get_phone_number(),
            $self->get_fax(),
	    $self->get_contact_email(),
            $self->get_webpage(),
	    $self->get_research_keywords(),
            $self->get_user_format(),
	    $self->get_research_interests(),
	    $self->get_contact_update(),
            $self->get_sp_person_id()
        );
        $return_value = $sth->rows();

        #print STDERR "Affected rows: $return_value\n";
    }

    #
    # if an id is not available, we insert a new record
    #
    else {
        $action='inserted';
        #print STDERR "inserting into sp_person...\n";
        my $sth = $self->get_sql("insert");
	my @time = (localtime())[3..5];
        $sth->execute(
            $self->get_censored(),
	    $self->get_salutation(),
            $self->get_last_name(),
	    $self->get_first_name(),
            $self->get_organization(),
	    $self->get_address(),
            $self->get_country(),
	    $self->get_phone_number(),
            $self->get_fax(),
	    $self->get_contact_email(),
            $self->get_webpage(),
	    $self->get_research_keywords(),
            $self->get_user_format(),
	    $self->get_research_interests(),
	    $self->get_contact_update(),
            sprintf("%s-%02s-%02s", 1900+$time[2], $time[1]+1, $time[0])
	    );
#        my $query2 = "SELECT last_insert_id() FROM sp_person";
       	my ($last) = $sth->fetchrow_array;
        $self->{sp_person_id} = $last;
        $return_value = $self->get_sp_person_id();
    }

    #my $subject="[People.pm] New person data $action for ".$self->get_first_name()." ".$self->get_last_name();
    #my $body="New data has been entered. Just thought you'd like to know.\n\n";
    #CXGN::Contact::send_email($subject,$body,'email');

    # store organism links
    #
    $self->store_organism_links();

    # store organization links
    #
    $self->store_organization_links();

    # store project links
    #
    $self->store_project_links();

    return $return_value;
}

# function store_organization_links() is used internally to store the 
# organization links to the database. 
#
sub store_organization_links {
    my $self = shift;

    # verify if links already exist...

    my $h = $self->get_sql('count_organization_links');

    foreach my $o ( @{ $self->{sp_organization} } ) {
        $h->execute( $o->get_sp_organization_id() );
        if ( !$h->rows() ) {

            # insert connection

        }
    }
}

sub store_project_links {
}

# the store_organism_links is used internally to store the organism links 
#
sub store_organism_links {
    my $self = shift;

    #
    # save the new organisms if they don't exist already
    #
    foreach my $o ( $self->get_organisms() ) {
        $o->store();
    }

    #
    # store the associated organisms
    #
    # test if the connections are already available...
    #
    #print STDERR "Storing associated organisms...\n";
    my $sel = $self->get_sql('select_organism');
    my $ins = $self->get_sql('insert_organism');
    my $del = $self->get_sql('delete_organism');

    my $sp_person_id = $self->get_sp_person_id();
#### deanx - I claim this is bug - jan 21 2008 
###    foreach my $o ( @{ $self->{organisms} } ) {
      foreach my $o (  $self->get_organisms  ) {
### deanx
        my $id = $o->get_organism_id();

        $sel->execute( $sp_person_id, $id );

#print STDERR $o->get_organism_name()." ".$o->is_selected()." ".$sel->rows()."\n";
#
# add new associations
#
        if ( $sel->rows() == 0 && $o->is_selected() ) {

            #print STDERR "Adding association person - organism\n";
            $ins->execute( $sp_person_id, $id );
        }

        #
        # remove associations that are not current anymore
        #
        if ( $sel->rows() > 0 && !$o->is_selected() ) {

            #print STDERR "Removing association $sp_person_id, $id\n";
            $del->execute( $sp_person_id, $id );
        }
    }
}

=head2 functions get_sp_person_id(), set_sp_person_id()

  Synopsis:	$p->get_sp_person_id()
  Arguments:	for the setter, sp_person_id. 
  Returns:	
  Side effects:	this will get/set the person_id of the object. 
                If there is already an object in the database, store
  Description:	accessors for the primary key of the person object. 

=cut

sub get_sp_person_id {
    my $self = shift;
    return $self->{sp_person_id};
}

=head2 Class properties

The following class properties have accessors:

  sp_person_id
  sp_person_id 
  censor       
  salutation   
  last_name    
  first_name   
  organization 
  address      
  country      
  phone_number 
  fax                
  contact_email      
  webpage            
  research_keywords  
  user_format        
  research_interests
  contact_update     
  research_update    

The censor property is user-settable. If it is true, information 
will not be displayed on the web.

=cut


sub set_sp_person_id {
    my $self = shift;
    $self->{sp_person_id} = shift;
}

sub get_censored {
    my $self = shift;
    return $self->{censor};
}

sub get_salutation {
    my $self = shift;
    return $self->{salutation};
}

sub get_last_name {
    my $self = shift;
    return $self->{last_name};
}

sub get_first_name {
    my $self = shift;
    return $self->{first_name};
}

sub get_organization {
    my $self = shift;
    return $self->{organization};
}

sub get_address {
    my $self = shift;
    return $self->{address};
}

sub get_country {
    my $self = shift;
    return $self->{country};
}

sub get_phone_number {
    my $self = shift;
    return $self->{phone_number};
}

sub get_fax {
    my $self = shift;
    return $self->{fax};
}

sub get_contact_email {
    my $self = shift;
    return $self->{contact_email};
}

sub get_webpage {
    my $self = shift;
    return $self->{webpage};
}

sub get_research_keywords {
    my $self = shift;
    return $self->{research_keywords};
}

sub get_user_format {
    my $self = shift;
    return $self->{user_format} || 'auto';
}

sub get_research_interests
{
	my $self = shift;
	return $self->{research_interests};
}

sub get_contact_update {
    my $self = shift;
    return $self->{contact_update};
}

sub get_research_update {
    my $self = shift;
    return $self->{research_update};
}

sub set_censor {
    my $self = shift;
    $self->{censor} = (shift(@_) ? 1 : 0);
}

sub set_salutation {
    my $self = shift;
    $self->{salutation} = shift;
}

sub set_last_name {
    my $self = shift;
    $self->{last_name} = shift;
}

sub set_first_name {
    my $self = shift;
    $self->{first_name} = shift;
}

sub set_organization {
    my $self = shift;
    $self->{organization} = shift;
}

sub set_address {
    my $self = shift;
    $self->{address} = shift;
}

sub set_country {
    my $self = shift;
    $self->{country} = shift;
}

sub set_phone_number {
    my $self = shift;
    $self->{phone_number} = shift;
}

sub set_fax {
    my $self = shift;
    $self->{fax} = shift;
}

sub set_contact_email {
    my $self = shift;
    $self->{contact_email} = shift;
}

sub set_webpage {
    my $self = shift;
    $self->{webpage} = shift;
}

sub set_research_keywords {
    my $self = shift;
    $self->{research_keywords} = shift;
}

sub set_user_format {
    my $self = shift;
    $self->{user_format} = shift;
}

sub set_research_interests
{
	my $self = shift;
	$self->{research_interests} = shift;
}

sub set_contact_update {
    my $self = shift;
    $self->{contact_update} = shift;
}

sub set_research_update {
    my $self = shift;
    $self->{research_update} = shift;
}

sub add_organization {

# this is different from set_organization, which sets the organization field in the
# people record. This function will add a link to an entry in the organization table.

    my $self         = shift;
    my $organization = shift;

    push @{ $self->{sp_organization} }, $organization;
}

sub get_organizations {
    my $self = shift;
    return @{ $self->{sp_organization} };
}

sub add_project {
    my $self    = shift;
    my $project = shift;
    push @{ $self->{sp_project} }, $project;
}

sub get_projects {
    my $self = shift;
    return @{ $self->{sp_project} };
}

sub get_organisms {
    my $self = shift;

    #print STDERR "get_organisms()\n";
    #if (!($self->get_dbh()->isa("CXGN::DB::Connection"))) { die "dbh is not defined here."; }
    unless( $self->{organisms} )  {
      my @fetched = CXGN::People::Organism->all_organisms($self->get_dbh(), $self->get_sp_person_id() );
      $self->{organisms} = \@fetched;
    }
    return @{$self->{organisms}};
}

sub add_organism {
    my $self     = shift;
    my $organism = shift;

    #check if organism does not yet exist
    my $flag = 0;
    foreach my $o ( $self->get_organisms ) {
        if ( $o->get_organism_name() eq $organism->get_organism_name() ) {
            $flag = 1;

        }
    }
    if ( !$flag ) { push @{ $self->{organisms} }, $organism; }
}

=head2 get_organism_id_string

Ret: string of organism IDs of all selected organisms, separated by \0

Meant for use with the form framework

=cut

sub get_organism_id_string {
	my $self = shift;
	my @ids = ();
	foreach my $o ($self->get_organisms()) {
		if($o->is_selected()) {
			push @ids, $o->get_organism_id();
		}
	}
	return join("\0", @ids);
}

=head2 add_organisms

Args: string containing names (not IDs) of new (ie unlisted) organisms, separated by \0

Meant for use with the form framework

=cut

sub add_organisms {
	my ($self, $organism_names_str) = @_;
	foreach (split(/\0/, $organism_names_str)) {
		my $organism = CXGN::People::Organism->new($self->get_dbh());
		$organism->set_organism_name($_);
		$organism->set_selected(1);
		$self->add_organism($organism);
	}
}

=head2 hard_delete

 Usage:        $p->hard_delete()
 Desc:         completely removes a user from the database
               TO BE USED WITH EXTREME CAUTION.
               Added for the testing framework.
 Args:
 Side Effects:
 Example:

=cut

sub hard_delete {
    my $self = shift;
    if (! $self->get_sp_person_id()) { 
	cluck "This person object is not yet persistent. Can't delete.\n";
	return;
    }

    eval { 
	my $pdq = "DELETE FROM sgn_people.sp_person where sp_person_id=?";
	my $pdqh= $self->get_dbh()->prepare($pdq);
	$pdqh->execute($self->get_sp_person_id());
	
    };
    if ($@) { 
	die "An error occurred during hard delete: $@";
    }
    else { 
	$self->get_dbh()->commit();
    }
    
}




sub set_sql {
    my $self = shift;
    $self->{queries} = {
	
	fetch =>
	
	"
				SELECT 
					sp_person_id, censor, salutation, last_name, 
					first_name, organization, address, country, 
					phone_number, fax, contact_email, webpage, 
					research_keywords, user_format, research_interests, 
					contact_update, research_update 
				FROM 
					sgn_people.sp_person 
				WHERE 
					sp_person_id=?
			",
	
	person_from_username =>
	
	"
				SELECT sp_person_id 
				FROM sgn_people.sp_person 
				WHERE username=?
			",
	
	person_count =>
	
	"	SELECT COUNT(*) FROM sgn_people.sp_person WHERE sp_person_id=? ",
	
	update =>
	
	"
				UPDATE sgn_people.sp_person 
				SET censor=?, salutation=? , last_name=?, first_name=?, 
					organization=?, address=?, country=?, phone_number=?, 
					fax=?, contact_email=?, webpage=?, research_keywords=?,
					user_format=?, research_interests=?, contact_update=?, 
					research_update=NOW() 
				WHERE sp_person_id=?
			",
	
	insert =>
	
	"
				INSERT INTO sgn_people.sp_person 
					(	censor, salutation, last_name, first_name, organization, 
						address, country, phone_number, fax, contact_email, 
						webpage, research_keywords, user_format, 
						research_interests, contact_update, research_update
						)
				VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                                RETURNING sp_person_id
			",
	
	select_organism =>
	
	"
				SELECT sp_person_organisms_id 
				FROM sgn_people.sp_person_organisms 
				WHERE sp_person_id=? and organism_id=?
			",
	
	
	insert_organism =>
	
	"	
				INSERT INTO sgn_people.sp_person_organisms 
					(sp_person_id, organism_id) 
				VALUES (?, ?)
			",
	
	delete_organism =>
	
	"
				DELETE FROM sgn_people.sp_person_organisms 
				WHERE 
					sp_person_id=? 
					AND organism_id=?
			",
	
	
	sequencer_bacs =>
	
	#note the left join because some bacs are not in physical, they are only in genomic. these will show up with no names! FIXME! physical.bacs is now restructured as genomic.clone.
	"     
				SELECT 
                	row_id,
                	project_id,
	                arizona_clone_name 
	            FROM 
	                sgn_people.sp_person 
	                inner join sgn_people.sp_project_person on (sp_person.sp_person_id=sp_project_person.sp_person_id) 
	                inner join metadata.attribution_to on (sp_project_id=project_id) 
	                inner join metadata.attribution using (attribution_id) 
	                left join physical.bacs on (metadata.attribution.row_id=physical.bacs.bac_id) 
	            WHERE 
	                (
	                    (metadata.attribution.database_name='physical' and metadata.attribution.table_name='bacs') 
	                    OR
						(metadata.attribution.database_name='genomic' and metadata.attribution.table_name='clone')
	                )
	                AND sp_person.sp_person_id=?
	            ORDER BY 
	                project_id,
	                arizona_clone_name",
	
	curator_bacs =>
	
			"
	            SELECT 
	                row_id,
	                project_id,
	                arizona_clone_name 
				FROM 
	                metadata.attribution_to 
	                inner join metadata.attribution using (attribution_id) 
	                left join physical.bacs on (metadata.attribution.row_id=physical.bacs.bac_id) 
	            WHERE 
	                (
	                    (
							metadata.attribution.database_name='physical' 
							AND metadata.attribution.table_name='bacs'
						) 
	                    OR
						(
							metadata.attribution.database_name='genomic' 
							AND metadata.attribution.table_name='clone'
						)
	                ) 
					AND project_id = ?
	            ORDER BY 
	                project_id,
	                arizona_clone_name",
	
	all_projects =>
	
	"
				SELECT sp_project_id FROM sgn_people.sp_project

			",
	
	
	projects_for_person =>
	
	"
				SELECT sp_project_id 
				FROM sgn_people.sp_project_person 
				WHERE sp_person_id=?
			UNION
				SELECT sp_project_id
				FROM sgn_people.sp_project
				WHERE name ilike ?
			",
	
	project_by_name =>
	
	"
				SELECT sp_project_id
				FROM sgn_people.sp_project
				WHERE name ilike ?
			",
	
	
	check_if_person_on_project =>
	
	"
				SELECT sp_project_person_id 
				FROM sgn_people.sp_project_person 
				WHERE 
					sp_person_id=? 
					AND sp_project_id=?
			",
	count_organization_links =>
	
	"
                                SELECT count(sp_person_organization.sp_organization_id)
                                FROM sgn_people.sp_person left join sgn_people.sp_person_organization on sp_person_id
                                WHERE
                                        sp_person_organization.sp_organization_id = ?
                       ",
	
	
	};
    
    while(my($name,$sql) = each %{$self->{queries}}) {
	$self->{query_handles}->{$name}=$self->get_dbh()->prepare($sql);
    }

}

sub get_sql { 
    my $self = shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}



###
1;#do not remove
###
