

=head1 NAME

CXGN::People::Organism - a class to deal with the favorite organisms of SGN users

=head1 DESCRIPTION

The SGN user database can store people's favorite organisms, which are maintained in a table called 'organism' in the sgn_people schema - a table which should be re-named (TO DO!). This class is an interface to the favorite organisms table.

=head1 AUTHORS

Lukas Mueller, John Binns, Robert Buels.

Copyleft (c) Sol Genomics Network. All rights reversed.

=head1 METHODS

This class implements the following methods:

=head1 CONSTRUCTORS

=cut

use strict;

package CXGN::People::Organism;

use base qw | CXGN::DB::Object |;

=head2 constructor new()

 Usage:        my $o = CXGN::People::Organism->new($dbh, $id);
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $selected = shift;

    my $self = $class->SUPER::new($dbh);
    
    $self->set_sql();

    if ($id) {
        my $success = $self->fetch($id);
        if ( !$success ) { return undef; }
    }
    $self->{is_selected} = $selected;
    return $self;
}

#
# alternate constructor that generates a list of organism objects that have the is_selected already
# set for the sp_person_id supplied
#

=head2 constructor all_organisms()

 Usage:        my @org_objs = CXGN::People::Organisms->all_organisms();
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub all_organisms {
    my $class = shift;
    my $dbh = shift;
    my $sp_person_id = shift;

    my $self = $class->SUPER::new($dbh);

    $self->set_sql();

    my @organisms = ();

    my $sth = $self->get_sql("all");
    $sth->execute($sp_person_id);
    while ( my ( $id, $name, $selected ) = $sth->fetchrow_array() ) {
        my $o = CXGN::People::Organism->new($self->get_dbh(), $id);
        if ($selected) {
            $o->set_selected(1);

            #print STDERR $o->get_organism_name() ." is selected.\n";
        }
        else { $o->set_selected(0); }

   #print STDERR "ORGANISM: ".$o->get_organism_name()." SELECTED: $selected.\n";
        push @organisms, $o;
    }
    return @organisms;
}

sub fetch {
	my $self = shift;
	my ($id) = @_;
	my $sth = $self->get_sql('fetch');
	$sth->execute($id);
	my $hashref = $sth->fetchrow_hashref();
	foreach my $k ( keys(%$hashref) ) {
		$self->{$k} = $$hashref{$k};
	}
	return $sth->rows();
}

=head2 get_sp_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_sp_organism_id {
    my $self = shift;
    return $self->{organism_id};
}

=head2 is_selected(), set_selected()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub is_selected {
    my $self = shift;
    return $self->{is_selected};
}

sub set_selected {
    my $self = shift;
    $self->{is_selected} = shift;
}

sub store {
    my $self = shift;
    if ( $self->get_organism_id() ) {

# if there is a organism id already we do nothing because we assume the names to be immutable.

    }
    else {

        # check to see if such an organism is already defined.
        my $sqh = $self->get_sql('id_from_name');
        $sqh->execute( $self->get_organism_name() );
        if ( $sqh->rows() > 0 ) {
            $self->{organism_id} = ( $sqh->fetchrow_array() )[0];
        }
        else {
            my $sqh = $self->get_sql("insert");
            $sqh->execute( $self->get_organism_name() );
     	    my $id = $self->get_dbh()->last_insert_id('sp_organisms', 'sgn_people');
	    $self->{organism_id} = $id;


        }
    }
    return $self->{organism_id};
}

=head2 get_organism_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_id {
    my $self = shift;
    return $self->{organism_id};
}

=head2 accessors get_organism_name(), set_organism_name()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_name {
    my $self = shift;
    return $self->{organism_name};
}

sub set_organism_name {
    my $self = shift;
    $self->{organism_name} = shift;
}


# SQL helper functions
#
sub set_sql { 
    my $self =shift;
    $self->{queries} = {

		fetch=>

			"
				SELECT organism_id, organism_name 
				FROM sgn_people.sp_organisms 
				WHERE organism_id=?
			",

		id_from_name =>
			
			"
				SELECT organism_id 
				FROM sgn_people.sp_organisms 
				WHERE organism_name=?
			",

		insert =>

			"
				INSERT INTO sgn_people.sp_organisms 
					(organism_name) 
					VALUES (?)
			",

		all => 
	
			"	
				SELECT 
					sp_organisms.organism_id, organism_name, 
					CASE WHEN sp_person_id IS NULL THEN 0 ELSE 1 END 
				FROM 
					sgn_people.sp_organisms 
				LEFT JOIN 
					sgn_people.sp_person_organisms 
					ON (
						sp_person_id=? 
						AND 
						sgn_people.sp_person_organisms.organism_id=sgn_people.sp_organisms.organism_id
					)
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
