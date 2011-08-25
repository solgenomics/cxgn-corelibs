


=head1 NAME

Functions for accessing ogranism names and their identifiers

=head1 SYNOPSIS


=head1 DESCRIPTION
 

=cut


=head2 get_all_organisms

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_all_organisms($dbh, %return_hash_flag);
 Desc:         This is a static function. Retrieves distinct organism names and IDs from sgn.common_name
 Ret:          Returns two arrayrefs. One array contains all the
               organism names, and the other all the organism ids
               with corresponding array indices
               or a hash {common_name}=common_name_id if 2nd argument is provided

 Args:         a database handle, a boolean (optional)
 Side Effects:
 Example:

=cut

package CXGN::Tools::Organism;

use strict;
use warnings;




sub get_all_organisms {
    my $dbh = shift;
    my $return_hash = shift;
    #this query should be changed to work with chado's organism table after sgn.common_name is replaced with it.
    my $query = "SELECT common_name, common_name_id 
                   FROM sgn.common_name ORDER BY upper(common_name) desc";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
     my %common_names=();
    while (my($common_name, $common_name_id) = $sth->fetchrow_array()) { 
	push @names, $common_name;
	push @ids, $common_name_id;
	$common_names{$common_name}= $common_name_id;
    }
    return %common_names if $return_hash;
    return (\@names, \@ids);
}


=head2 get_existing_organisms

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_existing_organisms($dbh , return_hash_flag);
 Desc:         This is a static function. Selects the distinct organism names and their IDs from phenome.locus.
               Useful for populating a unique drop-down menu with only the organism names that exist in the table.
 Ret:          Returns two arrayrefs. One array contains all the
               organism names, and the other all the organism ids with corresponding array indices.
              or a hash {common_name}=common_name_id if 2nd argument is provided
 Args:         a database handle, and a boolean (optional)
 Side Effects:
 Example:

=cut

sub get_existing_organisms {
    my $dbh= shift;
    my $return_hash = shift;
    my $query = "SELECT distinct(common_name), common_name_id FROM phenome.locus 
                 JOIN sgn.common_name using(common_name_id) 
                 WHERE obsolete = 'f'";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    my %common_names=();
    while (my($common_name, $common_name_id) = $sth->fetchrow_array()) { 
	push @names, $common_name;
	push @ids, $common_name_id;
	$common_names{$common_name}= $common_name_id;
    }
    return %common_names if $return_hash;
    return (\@names, \@ids);
}

=head2 get_all_populations

 Usage:        my ($names_ref, $ids_ref) = CXGN::Tools::Organism::get_all_populations($dbh);
 Desc:         This is a static function. Retrieves distinct population names and IDs from phenome.population
 Ret:          Returns two arrayrefs. One array contains all the
               population names, and the other all the population ids
               with corresponding array indices.
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_populations {
    my $dbh = shift;
   
    my $query = "SELECT name, population_id 
                   FROM phenome.population";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @names = ();
    my @ids = ();
    while (my($name, $population_id) = $sth->fetchrow_array()) { 
	push @names, $name;
	push @ids, $population_id;
    }
    return (\@names, \@ids);
}


=head2 organism_id_specie

 Usage: $id = CXGN::Tools::Organism::organism_id_specie($dbh, $specie);
 Desc: retrieves the organism id from sgn.organism
 Ret: organism id
 Args: db handle, specie name (eg. solanum lycopersicum)
 Side Effects: access db
 Example:

=cut

sub organism_id_specie {
    my $dbh = shift;
    my $specie = shift;

    print STDERR "specie_tax: $specie\n";

    my $sth = $dbh->prepare("SELECT organism_id 
                                    FROM sgn.organism
                                    WHERE specie_tax ILIKE ?"
                           );
    $sth->execute($specie);
    my $id;
    while (my $id_1 = $sth->fetchrow_array()) {
	$id = $id_1;
    }
    return $id;
    
}




return 1;
