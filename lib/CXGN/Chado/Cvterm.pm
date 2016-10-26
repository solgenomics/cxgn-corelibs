package CXGN::Chado::Cvterm;

=head1 NAME

CXGN::Chado::Cvterm - a class to handle controlled vocabulary terms.

=head1 SYNOPSIS

=head1 AUTHOR

 Naama Menda <nm249@cornell.edu>
 Lukas Mueller <lam87@cornell.edu> (added implementation of Bio::Ontology::TermI)
                                   (added map_to_slim function [March 3, 2008])

=cut


use Data::Dumper;
use CXGN::DB::Connection;
use CXGN::Chado::Dbxref;
use CXGN::Phenome::Population;
use CXGN::Chado::Cvterm::CvtermRanking;
use CXGN::Phenome::Locus;
use CXGN::Phenome::Individual;
use CXGN::Phenome::Qtl::Tools;
use List::MoreUtils qw /uniq/;
use strict;
use warnings;

# This line does not like Modern::Perl, and incurs:
# Inconsistent hierarchy during C3 merge of class 'CXGN::Chado::Cvterm': merging failed on parent 'CXGN::DB::Object' at lib/CXGN/Chado/Dbxref.pm line 40.
use base qw/ CXGN::DB::Object CXGN::Chado::Cvterm::CvtermRanking /;


=head1 IMPLEMENTATION OF THE Bio::Ontology::TermI INTERFACE

=head2 identifier

 Usage:        $t->set_identifier("0000001");
 Desc:         this identifier function maps to the accession.
               it is a synonym for set_accession and get_accession.
               For the go accession GO:000222, this would have to
               be set to 000222, for example.
 Property:     the accession of the term.
 Side Effects:
 Example:

=cut

sub identifier {
    my $self = shift;
    my $identifier = shift;
    $self->set_accession($identifier) if $identifier;
    return $self->get_accession();
}


=head2 name

 Usage:        $t->name($name);
 Desc:         a synonym for the set_cvterm_name/get_cvterm_name accessors
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub name {
    my $self = shift;
    my $name = shift;
    $self->set_cvterm_name($name) if $name;
    return $self->get_cvterm_name();
}

=head2 definition

 Usage:        $t->definition($definition);
 Desc:         a synonym for the set_definition/get_definition
               accessors
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub definition {
    my $self = shift;
    my $definition = shift;
    $self->set_definition($definition) if defined($definition);
    return $self->get_definition();
}

=head2 ontology

 Usage:        $t->ontology( CXGN::Chado::Ontology->new_with_name($dbh, "gene_ontology");
 Desc:         setter/getter for the ontology object this terms belongs to
 Property:     a CXGN::Chado::Ontology object.
 Side Effects:
 Example:

=cut

sub ontology {
    my $self = shift;
    my $ontology = shift;
    if ($ontology) {
	$self->set_cv_id($ontology->identifier());
    }
    else {
	return CXGN::Chado::Ontology->new($self->get_dbh(), $self->get_cv_id());
    }

}

=head2 version

 Usage:        my $v = $t->version($version)
 Desc:         synonym for get/set_version . See L<Bio::Ontology::OntologyI>.
 Ret:          $self->get_version()
 Args:         $version
 Side Effects:
 Example:

=cut

sub version {
    my $self = shift;
    my $version = shift;
    $self->set_version($version) if defined($version);
    return $self->get_version();
}

=head2 comment

 Usage:        $cvterm->comment("This is a useful term!");
               my $comment = $cvterm->comment();
 Desc:         setter/getter for the comment
 Args/Ret:     the comment, a string.
 Side Effects: accesses the database and retrieves/stores comments
               on the fly. Thus, the cvterm needs to be stored in the
               database and have a legal cvterm_id. The function emits
               a warning and does nothing if that is not the case.
 Example:

=cut

sub comment {
    my $self = shift;
    my $comment = shift;
    my $type_id=CXGN::Chado::Cvterm::get_cvterm_by_name($self->get_dbh(), "comment")->get_cvterm_id();
    if (!$type_id) {
	$self->d("WARNING. Cvterm has not yet been stored. Skipping the comment update.\n");
	return undef;
    }
    if ($comment) {
	# check if there is already a comment associated with this term.
	my $query = "SELECT cvtermprop_id from cvtermprop WHERE cvterm_id=? and value=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id(), $comment);
	my %props; #hash of arrays for cvtermprop_id => comment  pairs
	my ($cvtermprop_id) = $sth->fetchrow_array();
        #my @comments=();
	#while (my ($value) = $sth->fetchrow_array()) { push @comments , $value; }
	# if yes, update it
	#if ($cvtermprop_id) {
	#    my $update = "UPDATE cvtermprop SET value=? WHERE cvtermprop_id=?";
	#    my $update_h = $self->get_dbh()->prepare($update);
	#    $update_h->execute($comment, $cvtermprop_id);

	# if does not exist-  insert a new one.
	if (!$cvtermprop_id) {
	    my $insert = "INSERT INTO cvtermprop (cvterm_id, type_id, value, rank)
                          VALUES (?, ?, ?, ?)";
	    my $insert_h = $self->get_dbh()->prepare($insert);
	    $insert_h->execute($self->get_cvterm_id(),
			       $type_id,
			       $comment,
			       0);
	}

    }
    else {
	# query the comment out of the database
	my $query = "SELECT value FROM cvtermprop WHERE cvterm_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id());
	my ($comment) = $sth->fetchrow_array();
	return $comment;
    }
}

=head2 get_dblinks

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dblinks {
    my $self = shift;
    return $self->get_dbxref_id();
}


=head1 ORIGINAL CXGN::Chado::Cvterm functions

=cut



=head2 get_roots

 Usage:        my @roots = CXGN::Chado::Cvterm::get_roots($dbh, "PO");
 Desc:         a static function that returns a list of root
               terms for a given namespace such as "GO" or "PO"

 Ret:          a list of cvterm objects that are roots of ontologies
 Args:         $dbh and a namespace
 Side Effects:
 Example:

=cut

sub get_roots {
    my $dbh = shift;
    my $namespace = shift;

    my $query = "select cvterm.cvterm_id, cvterm.name from cv join cvterm using (cv_id) join dbxref using(dbxref_id) join db using(db_id) left join cvterm_relationship on (cvterm.cvterm_id=cvterm_relationship.subject_id) where cvterm_relationship.subject_id is null and is_obsolete=0 and is_relationshiptype =0 and db.name=? order by cvterm.name asc";
    my $sth = $dbh->prepare($query);
    $sth->execute($namespace);
    my @roots = ();
    while (my ($cvterm_id) = $sth->fetchrow_array())  {
	push @roots, CXGN::Chado::Cvterm->new($dbh, $cvterm_id);
    }
    return @roots;

}


=head2 get_namespaces

 Usage:         my @namespaces = CXGN::Chado::Cvterm::get_namespaces($dbh)
 Desc:          currently provides a list of supported namespaces that
                are hardcoded. Needs to be refactored somehow to
                get the useful namespaces from the database (public.db table).
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_namespaces {
    my $dbh = shift;

    return ("PO", "GO", "SP", "SO", "PATO");

}




=head2 new

 Usage: my $cvterm = CXGN::Chado::Cvterm->new($dbh, $cvterm_id);
 Desc:  an object for handling controlled vocabullary term objects
 Ret:
 Args:$dbh a database handle
      $cvterm_id = an id of a controlled vocabulary term (from chado cvterm table)
 Side Effects:
 Example:

=cut


sub new {
    my $class = shift;
    my $dbh=shift;
    my $cvterm_id = shift; #id of the cvterm

    my $self= $class->SUPER::new($dbh);

    if ($cvterm_id) {
	$self->set_cvterm_id($cvterm_id);
	$self->fetch();
	if (!$self->get_cvterm_id()) { # the cvterm supplied was not one that exists
	    return undef;
	}
    }

    return $self;
}

=head2 new_with_term_name

 Usage:        my $isa = CXGN::Chado::Cvterm->new_with_term_name($dbh, "isa", $cv_id);
 Desc:         useful for getting the term objects for relationship terms.
               limited usefulness for any other type of term.
 Ret:          a term object
 Args:         a database handle, a term name and a cv_id
 Side Effects:
 Example:

=cut

sub new_with_term_name {
    my $class = shift;
    my $dbh = shift;
    my $name = shift;
    my $cv_id = shift;

    if (!$name && !$cv_id) { die "[Cvterm.pm] new_with_term_name: Need name and cv_id."; }

    my $query = "SELECT cvterm_id from cvterm where name ilike ? and cv_id=?";
    my $sth = $dbh->prepare($query);
    $sth->execute($name, $cv_id);
    my ($cvterm_id) = $sth->fetchrow_array();

    my $self = CXGN::Chado::Cvterm->new($dbh, $cvterm_id);
    return $self;
}

=head2 new_with_accession

 Usage:        my $t = CXGN::Chado::Cvterm->new_with_accession($dbh, "InterPro:IPR000001", $cv_id);
 Desc:         an alternate constructor using the accession to define the term.
 Ret:
 Args:         a database handle [CXGN::DB::Connection], an accession [string], cv_id (optional. Can be useful if you think the accession might exist in another other cv)
 Side Effects:
 Example:

=cut

sub new_with_accession  {
    my $class = shift;
    my $dbh = shift;
    my $accession = shift;
    my $cv_id = shift;

    my ($name_space, $id) = split "\:", $accession;

    if ($accession =~ m/^IPR*/ ) {
	$name_space = 'InterPro';
	$id= $accession;
    }

    my $query = "SELECT cvterm_id FROM cvterm join dbxref using(dbxref_id) JOIN db USING (db_id)  WHERE db.name=? AND dbxref.accession ilike ?";
    $query .= " AND cv_id = $cv_id" if $cv_id;

    my $sth = $dbh->prepare($query);
    $sth->execute($name_space, $id);

    my ($cvterm_id) = $sth->fetchrow_array();

    my $self = $class->new($dbh, $cvterm_id);
    return $self;
}


sub fetch {
    my $self=shift;

    my $cvterm_query = $self->get_dbh()->prepare("SELECT  cvterm.cvterm_id, cv.cv_id, cv.name, cvterm.name, cvterm.definition, cvterm.dbxref_id, cvterm.is_obsolete, cvterm.is_relationshiptype, dbxref.accession, db.name  FROM public.cvterm join public.cv using(cv_id) join public.dbxref using(dbxref_id) join public.db using (db_id) WHERE cvterm_id=?  ");

    $cvterm_query->execute( $self->get_cvterm_id() );


    my ($cvterm_id, $cv_id, $cv_name, $cvterm_name, $definition, $dbxref_id, $obsolete,$is_rel,$accession, $db_name)=$cvterm_query->fetchrow_array();
    $self->set_cvterm_id($cvterm_id);
    $self->set_cv_id($cv_id);
    $self->set_cv_name($cv_name);
    $self->set_cvterm_name($cvterm_name);
    $self->set_definition($definition);
    $self->set_dbxref_id($dbxref_id);
    $self->set_obsolete($obsolete);
    $self->set_is_relationshiptype($is_rel);
    $self->set_accession($accession);
    $self->set_db_name($db_name);
}

=head2 store

 Usage: $self->store()
 Desc:  store a new cvterm. Update if cvterm_id exists
 Ret:   cvterm_id
 Args:  none
 Side Effects: store a new dbxref for the cvterm if does not exists already
 Example:

=cut

sub store {
    my $self = shift;
    my $cvterm_id=$self->get_cvterm_id();

    if ($cvterm_id) {
	#check if exists:
	my $existing_cvterm_id=$self->cvterm_exists();
	if ($existing_cvterm_id) {
	    $self->d( "Cvterm.pm found existing cvterm_id $existing_cvterm_id.. can't update term " .$self->get_cvterm_id() . "! \n");
	}else {
	    # update
	    my $query = "UPDATE cvterm set cv_id=?, name=?, dbxref_id=?, definition=?, is_obsolete=? WHERE cvterm_id=?";
	    my $sth = $self->get_dbh()->prepare($query);
	    $sth->execute($self->get_cv_id(), $self->get_cvterm_name(), $self->get_dbxref_id(), $self->get_definition(), $self->get_obsolete(), $self->get_cvterm_id());
	}
    }else {
	if (!$self->get_dbxref_id()) {
	    if (!$self->get_accession()) { die "Need an accession for a CV term!"; }
	    my $dbxref = CXGN::Chado::Dbxref->new($self->get_dbh());
	    $dbxref->set_accession($self->get_accession());
	    $dbxref->set_version($self->get_version());
	    $dbxref->set_description($self->definition());
	    my $db_name = $self->get_db_name();
	    if ($db_name) { $dbxref->set_db_name($db_name); }
	    else { die "Need a DB name to store cvterm object.\n"; }

	    my $dbxref_id = $dbxref->store();
	    $self->set_dbxref_id($dbxref_id);
            $self->d("Inserted new dbxref for accession " . $self->get_db_name() . ":" . $self->get_accession ."\n");
	}

	my $query = "INSERT INTO cvterm (cv_id, name, dbxref_id, definition, is_obsolete, is_relationshiptype) VALUES (?, ?, ?, ?,?,?)";

	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_cv_id(), $self->get_cvterm_name(), $self->get_dbxref_id(), $self->get_definition(), $self->get_obsolete(), $self->get_is_relationshiptype());

	$cvterm_id =  $self->get_dbh()->last_insert_id("cvterm", "public");
	$self->set_cvterm_id($cvterm_id);
    }
    return $cvterm_id;

}



=head2 Class properties

The following class properties have accessors (get_cvterm_id, set_cvterm_id...):

    cvterm_id
    cv_id
    cv_name
    cvterm_name
    definition
    dbxref_id
    accession
    version
    db_name
    obsolete
    is_relationshiptype

=cut

sub get_cvterm_id {
  my $self=shift;
  return $self->{cvterm_id};
}

sub set_cvterm_id {
  my $self=shift;
  $self->{cvterm_id}=shift;
}

sub get_cv_id {
  my $self=shift;
  return $self->{cv_id};
}


sub set_cv_id {
  my $self=shift;
  $self->{cv_id}=shift;
}

sub get_cv_name {
  my $self=shift;
  return $self->{cv_name};
}


sub set_cv_name {
  my $self=shift;
  $self->{cv_name}=shift;
}

sub get_cvterm_name {
  my $self=shift;
  return $self->{cvterm_name};

}

sub set_cvterm_name {
  my $self=shift;
  $self->{cvterm_name}=shift;
}

sub get_definition {
  my $self=shift;
  return $self->{definition};
}


sub set_definition {
  my $self=shift;
  $self->{definition}=shift;
}


sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};

}

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}

=head2 get_dbxref

 Usage: my $self->get_dbxref();
 Desc:  get a dbxref object associated with the cvterm
 Ret:   a dbxref object
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_dbxref {
    my $self = shift;
    return CXGN::Chado::Dbxref->new($self->get_dbh(), $self->get_dbxref_id());
}

sub get_accession {
  my $self=shift;
  return $self->{accession};
}

sub set_accession {
  my $self=shift;
  $self->{accession}=shift;
}
sub get_version {
  my $self=shift;
  return $self->{version};
}

sub set_version {
  my $self=shift;
  $self->{version}=shift;
}

sub get_db_name {
  my $self=shift;
  return $self->{db_name};
}


sub set_db_name {
  my $self=shift;
  $self->{db_name}=shift;
}

sub get_obsolete {
  my $self=shift;
  return $self->{obsolete};
}

sub set_obsolete {
  my $self=shift;
  $self->{obsolete}=shift;
}


sub get_is_relationshiptype {
  my $self=shift;
  return $self->{is_relationshiptype} || 0;
}


sub set_is_relationshiptype {
  my $self=shift;
  $self->{is_relationshiptype}=shift;
}


=head2 get_full_accession

 Usage: $self->get_full_accession()
 Desc:  Usse this accessor to find the full accession of your cvterm
        instead of concatenating db_name and accession (e.g. GO:0001234)
 Ret:   db_name:accession
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_full_accession {
    my $self=shift;
    return $self->get_db_name() . ":" . $self->get_accession();
}


=head2 get_recursive_parents

 Usage: my @parents = $self->get_recursive_parents()
 Desc:  a method for finding all the parents up to the root of the  cvterm, and the cvterm-parent relationship
 Ret:   a list of listrefs containing CXGN::Chado::Cvterm objects and relationship types
 Args:  none
 Side Effects: none
 Example:

=cut


sub get_recursive_parents {
    my $self=shift;

    my $parents_q =  "SELECT distinct(cvtermpath.object_id)
                       FROM cvtermpath
                       JOIN cvterm ON (cvtermpath.object_id = cvterm_id)
                       WHERE cvtermpath.subject_id =? AND cvterm.is_obsolete=0 AND pathdistance>0";

    my $type_q = "SELECT type_id FROM cvterm_relationship
                  WHERE subject_id = ? AND object_id = ?";
    my $type_sth = $self->get_dbh->prepare($type_q);
    my $parents_sth = $self->get_dbh()->prepare($parents_q);

    $parents_sth->execute($self->get_cvterm_id() );
    my @parents = ();
    while (my ($parent_term_id) = $parents_sth->fetchrow_array()) {
	my $parent_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $parent_term_id);
        $type_sth->execute($self->get_cvterm_id, $parent_term_id);
        my ($type_id) = $type_sth->fetchrow_array();
        my $relationship_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $type_id);

	push @parents, [ $parent_term, $relationship_term ];
    }
    return (@parents);
}


=head2 get_parents

 Usage: $self->get_parents
 Desc: find the direct parents of the cvterm
 Ret:  a list of listrefs containing CXGN::Chado::Cvterm objects and relationship types
 Args: none
 Side Effects: none
 Example:

=cut

sub get_parents {
    my $self=shift;
    my $parents_q =  "SELECT object_id , type_id
                       FROM cvterm_relationship
                      WHERE subject_id = ? ";
    my $parents_sth = $self->get_dbh()->prepare($parents_q);
    $parents_sth->execute($self->get_cvterm_id() );
    my @parents = ();
    while (my ($parent_term_id, $type_id) = $parents_sth->fetchrow_array()) {
	my $parent_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $parent_term_id);
	my $relationship_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $type_id);

	push @parents, [ $parent_term, $relationship_term ];
    }
    return (@parents);
}


=head2 get_children

  Usage: my @children = $self->get_children()
  Desc:  a method for finding all the child terms of a cv term and their relationship
  Ret:   a list of lists with two elements: a cvterm object for the child and a
         cvterm object for the relationship
  Args:  none
  Side Effects:
  Example:

=cut

sub get_children {

    my $self=shift;

    my $children_q = "select subject_id , type_id , name from cvterm_relationship join cvterm on (subject_id = cvterm_id ) where cv_id = ? AND object_id =? ";

    my $children_sth= $self->get_dbh()->prepare($children_q);
    $children_sth->execute( $self->get_cv_id, $self->get_cvterm_id() );

    $self->d( "Parent cvterm id = ".$self->get_cvterm_id()."\n" );
    my @children = ();
    while (my ($child_term_id, $type_id, $cvterm_name) = $children_sth->fetchrow_array()) {
	$self->d( "retrieved child $child_term_id, $type_id\n" );
	my $child_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $child_term_id);
	my $relationship_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $type_id);
	push @children, [ $child_term, $relationship_term ];
    }
    return (@children);
}


=head2 get_recursive_children

 Usage: $self->get_recursive_children
 Desc: find all  recursive child terms of this cvterm
 Ret:   a list of lists with two elements: a cvterm object for the child and a
         cvterm object for the relationship
 Args: none
 Side Effects: none
 Example:

=cut

sub get_recursive_children {
    my $self=shift;
    my $q =  "SELECT distinct(cvtermpath.subject_id)
                       FROM cvtermpath
                       JOIN cvterm ON (cvtermpath.object_id = cvterm_id)
                       WHERE cvtermpath.object_id =? AND cvterm.is_obsolete=0 AND pathdistance>0 ";

    my $sth = $self->get_dbh()->prepare($q);
    $sth->execute($self->get_cvterm_id() );

    my $type_q = "SELECT type_id FROM cvterm_relationship
                  WHERE subject_id = ? AND object_id = ?";
    my $type_sth = $self->get_dbh->prepare($type_q);

    my @children = ();
    while (my ($child_term_id) = $sth->fetchrow_array()) {
	my $child_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $child_term_id);
        $type_sth->execute($child_term_id, $self->get_cvterm_id);
        my ($type_id) = $type_sth->fetchrow_array();
	my $relationship_term = CXGN::Chado::Cvterm->new($self->get_dbh(), $type_id);
	push @children, [ $child_term, $relationship_term ];
    }
    return (@children);
}


=head2 count_children

 Usage: my $childrenNumber = $self->count_children()
 Desc:  a method for fetching the number of children of a cvterm
 Ret:   the number of children for the current db name (this is to avoid counting InterPro children of GO terms)
 Args:  none
 Side Effects: none
 Example:

=cut

sub count_children {
    my $self = shift;
    my $childNumber = 0;

    my $child_sth = $self->get_dbh()->prepare("SELECT count( cvterm_relationship.subject_id )FROM cvterm_relationship join cvterm on cvterm.cvterm_id = cvterm_relationship.subject_id JOIN dbxref USING (dbxref_id)  WHERE cvterm_relationship.object_id= ? and cvterm.is_obsolete = 0 ");
    $child_sth->execute($self->get_cvterm_id() );
    ($childNumber) = $child_sth->fetchrow_array();
    return $childNumber;
}



=head2 get_synonyms

 Usage: my @synonyms = $self->get_synonyms()
 Desc:  a method for fetching all synonyms of a cvterm
 Ret:   an array  of  synonyms
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_synonyms {
    my $self=shift;

    my $cvterm_id= $self->get_cvterm_id();
    my $query=  "SELECT synonym FROM cvtermsynonym WHERE cvterm_id= ?";

    my $synonym_sth = $self->get_dbh()->prepare($query);

    $synonym_sth->execute($cvterm_id);
    my @synonyms = ();
    while (my ($synonym) = $synonym_sth->fetchrow_array()) {
	push @synonyms, $synonym;
    }
    return @synonyms;
}

=head2 get_uppercase_synonym

 Usage: my $uppercase_synonym = $self->get_uppercase_synonym;
 Desc: a method for fetching the simplest,uppercase synonym
 Ret:  a single uppercase synonym
 Args: none
 Side Effects:
 Example:

=cut

sub get_uppercase_synonym {
    my $self=shift;
    my $cvterm_id= $self->get_cvterm_id();

    my $query=  "SELECT synonym FROM cvtermsynonym WHERE cvterm_id= ? AND upper(synonym) = synonym";
    my $synonym_sth = $self->get_dbh()->prepare($query);
    $synonym_sth->execute($cvterm_id);

    my $uppercase_synonym = $synonym_sth->fetchrow_array();
    return $uppercase_synonym;
}


=head2 add_synonym

 Usage:        $t->add_synonym($new_synonym);
 Desc:         adds the synonym $new_synonym to the term $t.
               If the synonym $new_synonym already exists,
               nothing is added.
               Note that in order to call add_synonym(), the
               term needs to be stored in the database, otherwise
               an error will occur.
 Side Effects: accesses the database. Debug message.
 Example:

=cut

sub add_synonym {
    my $self = shift;
    my $synonym = shift;
    if (!$self->has_synonym($synonym)) {
	my $query = "INSERT INTO cvtermsynonym (cvterm_id, synonym) VALUES (?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id(), $synonym);
	$self->d( "Cvterm.pm: adding synonym '$synonym' to cvterm ". $self->get_cvterm_name() ."\n") ;
    }
    else {
	$self->d("$synonym is already a synonym of term ".($self->get_cvterm_name())."\n");
    }
}



=head2 has_synonym

 Usage:        my $flag = $t->has_synonym("gobbledegook");
 Desc:         returns true if the synonym exists, false otherwise
 Ret:          1 or 0
 Args:         a synonym name
 Side Effects: none
 Example:

=cut

sub has_synonym {
    my $self = shift;
    my $putative_synonym = shift;
    my $synonym_sth = $self->get_dbh()->prepare("SELECT synonym FROM cvtermsynonym WHERE
                                                   cvterm_id= ? and synonym ilike ?");
    $synonym_sth->execute($self->get_cvterm_id(), $putative_synonym);
    my ($synonym) = $synonym_sth->fetchrow_array();
    if ($synonym) {
	return 1;
    }
    else {
	return 0;
    }
}

=head2 delete_synonym

 Usage: $cvterm->delete_synonym($synonym)
 Desc:  delete synonym $synonym from cvterm object
  Ret:  nothing
 Args: $synonym
 Side Effects: accesses the database
 Example:

=cut

sub delete_synonym {
    my $self=shift;
    my $synonym=shift;
    my $query = "DELETE FROM cvtermsynonym WHERE cvterm_id= ? AND synonym = ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $synonym);
}



=head2 term_is_obsolete

 Usage: my $obsolete = $self->term_is_obsolete($cvterm_id);
 Desc:  a method for determining if a term is obsolete
 Ret:   false if not obsolete, true if obsolete
 Args:  $cvterm_id - an id of a controlled vocabulary term
 Side Effects: none
 Example:

=cut

sub term_is_obsolete {
    my $self=shift;

    my $cvterm_id=shift;
    my $obsolete_sth = $self->get_dbh()->prepare("SELECT is_obsolete FROM cvterm WHERE cvterm_id= ?");
    $obsolete_sth->execute($self->get_cvterm_id() );
    my ($obsolete) = $obsolete_sth->fetchrow_array();

    if( $obsolete == 1 ) {
	return "true";
    } else {
	return "false";
    }
}

=head2 associate_feature

 Usage:        $cvterm->associate_feature($feature_id, $pub_id)
 Desc:         associates the feature with $feature_id to the
               cvterm.
 Ret:          nothing
 Args:         feature_id and a pub_id
 Side Effects:  accesses the database
 Example:

=cut

sub associate_feature {
    my $self = shift;
    my $feature_id = shift;
    my $pub_id = shift;
    if (!($pub_id && $feature_id)) {
	die "[CXGN::Chado::Cvterm] associate_feature(): Need feature_id and pub_id\n";
    }

    my $query = "INSERT INTO cvterm_feature (cvterm_id, feature_id, pub_id) VALUES (?, ?, ?)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $feature_id, $pub_id);
}

=head2 get_features

 Usage:        my @features = $cvterm->get_features()
 Desc:         returns a list of feature objects that are associated to this
               cvterm using cvterm_feature table.
 Ret:          a list of CXGN::Chado::Feature objects
 Args:         none
 Side Effects: accesses the database
 Example:

=cut

sub get_features {
    my $self = shift;
    my $query = "SELECT feature_id FROM cvterm_feature WHERE cvterm_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id());
    my @features = ();
    while (my ($feature_id) = $sth->fetchrow_array()) {
	push @features, CXGN::Chado::Feature->new($self->get_dbh(), $feature_id);
    }
    return @features;
}

=head2 add_secondary_dbxref

 Usage: $self->add_secondary_dbxref(accession)
 Desc:  add an alternative id to cvterm. Stores in cvterm_dbxref
 Ret:   nothing
 Args:  an alternative id (i.e. "GO:0001234")
 Side Effects: stors a new dbxref if accession is not found in dbxref table
 Example:

=cut

sub add_secondary_dbxref {
    my $self=shift;
    my $accession=shift;
    my ($db_name, $acc) = split (/:/, $accession);
    my $db=CXGN::Chado::Db->new_with_name($self->get_dbh(), $db_name);
    if ( !($db->get_db_id()) ) {
	$db->set_db_name($db_name);
	$self->d( "Cvterm.pm: Storing a new DB: $db_name\n");
	$db->store();
    }
    #check is $accession exists:
    my $dbxref_id= CXGN::Chado::Dbxref::get_dbxref_id_by_db_id($self->get_dbh(), $acc, $db->get_db_id());
    if (!$dbxref_id) {
        $self->d("No dbxref_id found for db_name '$db_name' accession '$acc' adding new dbxref...\n");
	my $dbxref=CXGN::Chado::Dbxref->new($self->get_dbh());
	$dbxref->set_accession($acc);
	$dbxref->set_db_name($db->get_db_name());
	$dbxref->store();
	$dbxref_id=$dbxref->get_dbxref_id();
    }
    if (!$self->has_secondary_dbxref($dbxref_id) ) {
	my $query = "INSERT INTO cvterm_dbxref (cvterm_id, dbxref_id) VALUES (?,?)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id(), $dbxref_id);
	$self->d( "Cvterm.pm: adding secondary id '$accession' to cvterm ". $self->get_cvterm_name() . "\n");
    }else {
	$self->d("Cvterm.pm: $dbxref_id ($accession) is already a secondary id of term '".($self->get_cvterm_name())."'\n");
    }
}

=head2 has_secondary_dbxref

 Usage: $self->has_secondary_dbxref($dbxref_id)
 Desc:  checks in the database if dbxref_id os already associated with the cvterm
 Ret:   1 or 0
 Args:  dbxref_id
 Side Effects: none
 Example:

=cut

sub has_secondary_dbxref {
    my $self=shift;
    my $dbxref_id=shift;
    my $query = "SELECT cvterm_dbxref_id FROM cvterm_dbxref WHERE cvterm_id= ? AND dbxref_id= ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $dbxref_id);
    my ($id) = $sth->fetchrow_array();
    if ($id) { return 1; }
    else { return 0; }
}

=head2 get_secondary_dbxrefs

 Usage: $self->get_secondary_dbxrefs()
 Desc:  find all secondary accessions associated with the cvterm
         These are stored in cvterm_dbxref table as dbxref_ids
 Ret:    an array of accessions (PO:0001234)
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_secondary_dbxrefs {
    my $self=shift;
    my $query= "SELECT dbxref_id FROM cvterm_dbxref WHERE cvterm_id=? AND is_for_definition = 0";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id() );
    my @secondary;
    while (my ($dbxref_id) = $sth->fetchrow_array() ) {
	my $dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(),$dbxref_id);
	my $accession = $dbxref->get_db_name() . ":" . $dbxref->get_accession();
	push  @secondary, $accession;
    }
    return @secondary;
}

=head2 delete_secondary_dbxref

 Usage: $self->delete_secondary_dbxref()
 Desc:  delete a cvterm_dbxref from the database
 Ret:   nothing
 Args:  accession (PO:0001234)
 Side Effects:
 Example:

=cut

sub delete_secondary_dbxref {
    my $self=shift;
    my $accession=shift;
    my ($db_name, $acc) = split (/:/, $accession);
    my $query= "DELETE FROM cvterm_dbxref where cvterm_id=? AND is_for_definition = 0
                AND dbxref_id=(SELECT dbxref_id FROM dbxref WHERE db_id= (SELECT db_id FROM db WHERE name =?)
                AND accession = ?)";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id(), $db_name, $accession);

}


=head2 add_def_dbxref

 Usage: $self->add_def_dbxref($dbname, $accession)
 Desc:  add a cvterm definition dbxref to cvterm_dbxref
 Ret:   nothing
 Args:   a db name and a dbxref accession
 Side Effects: stores a new db and a new dbxref if $dbname or $accession
                do not exist in db and/or dbxref tables
 Example:

=cut

sub add_def_dbxref {
    my $self=shift;
    my $dbname=shift;
    my $accession=shift;
    #check if $dbname exist:
    my $db=CXGN::Chado::Db->new_with_name($self->get_dbh(), $dbname);
    if ( !($db->get_db_id()) ) {
	$db->set_db_name($dbname);
	$self->d( "Cvterm.pm: Storing a new DB: $dbname\n");
	$db->store();
    }
    #check is $accession exists:
    my $dbxref_id= CXGN::Chado::Dbxref::get_dbxref_id_by_db_id($self->get_dbh(), $accession, $db->get_db_id());
    if (!$dbxref_id) {
	my $dbxref=CXGN::Chado::Dbxref->new($self->get_dbh());
	$dbxref->set_db_name($db->get_db_name());
	$dbxref->set_accession($accession);
	$self->d( "Cvterm.pm: Storing a new Dbxref for db $dbname: $accession\n");

	$dbxref_id=$dbxref->store();
    }
    if (!$self->has_secondary_dbxref($dbxref_id)) {
	my $query = "INSERT INTO cvterm_dbxref (cvterm_id, dbxref_id, is_for_definition)
                 VALUES (?,?,1)";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id(), $dbxref_id);
	$self->d( "Cvterm.pm: Storing a new definition dbxref ($dbname:$accession) for cvterm". $self->get_cvterm_name() . "\n");
    }
    else {
	my $query = "UPDATE cvterm_dbxref set is_for_definition=1
                 WHERE cvterm_id=? and dbxref_id=?";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id(), $dbxref_id);

    }
}

=head2 get_def_dbxref

 Usage:   $self->get_def_dbxref();
 Desc:    find the definition dbxrefs of the cvterm (stored in cvterm_dbxref)
 Ret:      an array of dbxref object
 Args:     none
 Side Effects: none
 Example:

=cut

sub get_def_dbxref {
    my $self=shift;

    my $query = "SELECT dbxref_id FROM cvterm_dbxref WHERE cvterm_id=? and is_for_definition =1";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cvterm_id());
    my @dbxrefs=();
    while (my ($dbxref_id) = $sth->fetchrow_array() ) {
	my $dbxref=CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
	push @dbxrefs, $dbxref;
    }
    return @dbxrefs;
}


=head2 delete_def_dbxref

 Usage: $self->delete_def_dbxref($dbxref)
 Desc:   remove from the database a cvterm_dbxref
 Ret:    nothing
 Args:   dbxref object
 Side Effects: accesses the database
 Example:

=cut

sub delete_def_dbxref {
    my $self=shift;
    my $dbxref=shift;
    my $query = "DELETE FROM cvterm_dbxref WHERE cvterm_id=? AND dbxref_id=? AND is_for_definition = 1";
    my $sth=$self->get_dbh()->prepare($query);

    $sth->execute($self->get_cvterm_id(), $dbxref->get_dbxref_id());
}

=head2 get_cvterm_by_name

 Usage: CXGN::Chado::Cvterm::get_cvterm_by_name($dbh, $name)
 Desc:  get a cvterm object with name $name
 Ret:   cvterm object. Empty object if name does not exist in cvterm table
 Args:  database handle and a cvterm name (and '1' if you want to check for an existing relationship type! )
 Side Effects: none
 Example:

=cut

sub get_cvterm_by_name {
    my $dbh=shift;
    my $name=shift;
    my $is_rel=shift; #optional!
    my $query = "SELECT cvterm_id FROM public.cvterm WHERE name ilike ?";
    $query .=" AND is_relationshiptype =1 " if $is_rel;
    my $sth=$dbh->prepare($query);
    $sth->execute($name);
    my ($cvterm_id) = $sth->fetchrow_array();
    my $cvterm= CXGN::Chado::Cvterm->new($dbh, $cvterm_id);
    return $cvterm;
}

=head2 cvterm_exists

 Usage: $self->cvterm_exists()
 Desc:   check if another cvterm exists with the same cv_id, name, and is_obsolete value
         prior to updating
 Ret:    cvterm_id or undef if no other cvterm exists
 Args:   non
 Side Effects: none
 Example:

=cut

sub cvterm_exists {

    my $self=shift;
    my $cvterm_id= $self->get_cvterm_id();
    my $query="SELECT cvterm_id FROM public.cvterm WHERE cv_id=? AND  name=? AND is_obsolete=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_cv_id(), $self->get_cvterm_name(), $self->get_obsolete());
    my ($existing_cvterm_id) = $sth->fetchrow_array();
    if ($cvterm_id == $existing_cvterm_id) { return undef; }
    else { return $existing_cvterm_id ; }
}



=head2 obsolete

 Usage: $self->obsolete()
 Desc:   set a cvterm is_obsolete = 1
 Ret:   nothing
 Args:  none
 Side Effects: accesses the database
 Example:

=cut

sub obsolete {
    my $self=shift;
    if ($self->get_cvterm_id() ) {
	my $query= "UPDATE public.cvterm SET is_obsolete = 1 WHERE cvterm_id=?";
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_cvterm_id() );
    }else {
	$self->d( "Trying to obsolete a term that hasn't been stored yet! \n");
    }
}

=head2 get_alt_id

 Usage: $self->get_alt_id();
 Desc:  find the alternative id of a term. Meant to be used for finding
        an alternative cvterm for an obsolete term
 Ret:   list of dbxref_ids or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_alt_id {
    my $self=shift;
    my $query = "SELECT cvterm.dbxref_id FROM cvterm WHERE cvterm_id IN
                 (SELECT cvterm_id FROM cvterm_dbxref WHERE dbxref_id= ?)";
    my @alt_ids;
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_dbxref_id() );
    while (my ($alt_id) = $sth->fetchrow_array()) {
	push @alt_ids, $alt_id ;
    }
    return @alt_ids || undef ;
}

=head2 map_to_slim

 Usage:        my @match_list = $cvterm->map_to_slim(@term_list)
 Desc:         returns a list of terms in the @term_list that
               are parents of the term object. This function is
               useful for mapping terms to a slim vocabulary.
 Ret:          a list of term identifiers
 Args:         a list of term identifiers that are in the slim vocabulary
 Side Effects: accesses the database
 Note:         the db name is stripped off if provided (GO:0003832 is
               given as 0003832)
 Example:

=cut

sub map_to_slim {
    my $self = shift;
    my @slim = @_;

    my %slim_counts = ();
    for (my $i=0; $i<@slim; $i++) {

	# strip db name off id
	#
	$slim[$i]=~s/.*?(\d+).*/$1/;

	# make a unique list of slim terms
	#
	$slim_counts{$slim[$i]}=0;
    }
    $self->get_slim_counts(\%slim_counts);

    print Data::Dumper::Dumper(\%slim_counts);

    my @matches = ();
    foreach my $k (keys %slim_counts) {
	if ($slim_counts{$k}>0) { push @matches, $k; }
    }
    return @matches;
}

sub get_slim_counts {
    my $self = shift;
    my $slim_counts = shift;

    my $id = $self->identifier();

    if (exists($slim_counts->{$id}) && defined($slim_counts->{$id})) {
	$slim_counts->{$id}++;
	return;
    }

    foreach my $p ($self->get_parents()) {
	$p->[0]->get_slim_counts($slim_counts);
    }
}



=head2 has_loci

 Usage: $self->has_loci();
 Desc:  find the number of loci associated with the cvterm or with any of its children
 Ret:   loci count or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub has_loci {
    my $self=shift;

    my $q = "SELECT count(distinct locus_id)
             FROM cvtermpath
              JOIN cvterm ON (cvtermpath.object_id = cvterm.cvterm_id
                           OR cvtermpath.subject_id = cvterm.cvterm_id)
             JOIN phenome.locus_dbxref USING (dbxref_id )
             JOIN phenome.locus USING (locus_id)
             WHERE (cvtermpath.object_id = ?)
                   AND locus_dbxref.obsolete = 'f'
                   AND locus.obsolete = 'f'
                   AND pathdistance > 0";

    my $sth = $self->get_dbh->prepare($q);
    $sth->execute($self->get_cvterm_id);

    my ($locus_count) = $sth->fetchrow_array ;
    return $locus_count || undef;

}

=head2 has_stocks

 Usage: $self->has_stocks();
 Desc:  find the number of stocks associated with the cvterm or with any of its children
 Ret:   stock count or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub has_stocks {
    my $self=shift;
    my $q = "SELECT count(distinct stock_id)
             FROM cvtermpath
             JOIN cvterm on (cvtermpath.object_id = cvterm.cvterm_id
                         OR cvtermpath.subject_id = cvterm.cvterm_id )
             JOIN stock_cvterm on (stock_cvterm.cvterm_id = cvterm.cvterm_id)
             JOIN stock USING (stock_id)
             WHERE cvtermpath.object_id = ?
             AND stock.is_obsolete = ?
             AND pathdistance > 0
            AND 0 = ( SELECT COUNT(*)
                      FROM stock_cvtermprop p
                      WHERE type_id IN ( SELECT cvterm_id FROM cvterm WHERE name = 'obsolete' )
                           AND p.stock_cvterm_id = stock_cvterm.stock_cvterm_id
                           AND value = '1')";

    my $sth = $self->get_dbh->prepare($q);
    $sth->execute($self->get_cvterm_id, "f");

    my ($stock_count) = $sth->fetchrow_array ;
    return $stock_count || undef;

}

=head2 has_phenotypes

 Usage: $self->has_phenotypes();
 Desc:  find the number of phenotyped stocks associated with the cvterm or with any of its children
 Ret:   stock count or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub has_phenotypes {
    my $self=shift;
    my $q = "SELECT count(distinct stock_id)
             FROM cvtermpath
               JOIN cvterm ON (cvtermpath.object_id = cvterm.cvterm_id
                            OR cvtermpath.subject_id = cvterm.cvterm_id )
               JOIN phenotype on cvterm.cvterm_id = phenotype.observable_id
               JOIN nd_experiment_phenotype USING (phenotype_id)
               JOIN nd_experiment_stock USING (nd_experiment_id)
             WHERE pathdistance > 0
             AND cvtermpath.object_id = ?";

    my $sth = $self->get_dbh->prepare($q);
    $sth->execute($self->get_cvterm_id);

    my ($stock_count) = $sth->fetchrow_array ;
    return $stock_count || undef;

}



=head2 has_phenotyping_trials

 Usage: $self->has_phenotyping_trials();
 Desc:  find the number of phenotyping trials associated with the cvterm or with any of its children
 Ret:   trial count or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub has_phenotyping_trials {
    my $self=shift;

    my $q = "SELECT count(project_id)
             FROM public.project
              JOIN nd_experiment_project USING (project_id)
              JOIN nd_experiment_stock USING (nd_experiment_id)
              JOIN nd_experiment_phenotype USING (nd_experiment_id)
              JOIN phenotype USING (phenotype_id)
              JOIN cvterm on cvterm.cvterm_id = phenotype.observable_id
             WHERE observable_id = ?  ";


    my $sth = $self->get_dbh->prepare($q);
    $sth->execute($self->get_cvterm_id);

    my ($trial_count) = $sth->fetchrow_array ;
    return $trial_count || undef;

}

=head2 get_image_ids

 Usage: $self->get_image_ids
 Desc:  find image IDs associated with a cvterm
 Ret:   list of md_image_ids
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_image_ids {
    my $self = shift;
    my $q = "SELECT image_id FROM metadata.md_image_cvterm
             WHERE obsolete = 'f' AND cvterm_id = ? " ;

    my $sth = $self->get_dbh()->prepare($q);
    $sth->execute($self->get_cvterm_id());
    my @image_ids = ();
    while (my ($image_id) = $sth->fetchrow_array()) {
 	push @image_ids, $image_id;
    }
    return @image_ids;
}



###
1;#do not remove
###
