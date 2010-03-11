
=head1 NAME

Functions for accessing and inserting new publications into the database

=head1 SYNOPSIS


=head1 DESCRIPTION
 

=cut

use strict;


package CXGN::Chado::Publication;

use CXGN::Chado::Dbxref;
use CXGN::Chado::Pubauthor;
use base qw / CXGN::DB::Object  /;


=head2 new

 Usage: my $pub = CXGN::Chado::Publication->new($dbh, $pub_id);
 Desc:
 Ret:    
 Args: $dbh, $pub_id
 Side Effects:
 Example:

=cut


sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the pub_id of the publication 
   
    my $args = {};  
    my $self = $class->SUPER::new($dbh); #bless $args, $class;
    
    $self->set_dbh($dbh);
    $self->set_pub_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
   
    #$self->set_debug(1);
    return $self;
}



sub fetch {
    my $self=shift;

    my $query =  "SELECT  title, volume, series_name, issue, pyear, pages, uniquename, cvterm.name,  abstract, status, curated_by, pub_curator.assigned_to
                          FROM public.pub
                          JOIN public.cvterm ON (public.pub.type_id=public.cvterm.cvterm_id)
                          LEFT JOIN public.pubabstract USING (pub_id)
                          LEFT JOIN phenome.pub_curator USING (pub_id)
                           WHERE pub_id=? ";
    my $sth=$self->get_dbh()->prepare($query);
   
    my $pub_id=$self->get_pub_id();
    $sth->execute( $pub_id);
    
    my ($title, $volume, $series_name, $issue, $pyear, $pages, $uniquename, $cvterm_name,  $abstract, $status, $curated_by, $curator_id)= $sth->fetchrow_array();
    
    $self->set_title($title);
    $self->set_volume($volume);
    $self->set_series_name($series_name);
    $self->set_issue($issue);
    $self->set_pyear($pyear);
    $self->set_pages($pages);
    $self->set_uniquename($uniquename);
    $self->set_cvterm_name($cvterm_name);
    $self->set_abstract($abstract);
    $self->set_status($status);
    $self->set_curated_by($curated_by);
    $self->set_curator_id($curator_id);
}


=head2 store

 Usage:  $pub_object->store()
 Desc:   store a publication object in chado pub module.
         dbxrefs (add_dbxref("db_name:accession")) the accession must be set before calling store! 
         Setting uniquename is also highly recommended. 
         Usually uniquename is 'accession:title' 
         or 'year(pages):title'
 Ret:    database publication ID
 Args:   none
 Side Effects: stores dbxref ids in dbxref (if it is not there already),
               the dbxref_id in the linking table pub_dbxref (with the new pub_id)
               and the text abstract in pubabstract (this table is not part of the chado schema)
    
 Example:

=cut

sub store {
    my $self = shift;
    my $pub_id=$self->get_pub_id();
    
    #If accession is not in dbxref- do an insert (for pubmed db.name is PMID)
    #my $db_name= 'PMID'; Tools::Pubmed should have taken care of setting the db_name  
    if (!$self->get_uniquename() ) {
	my $uniquename = $self->get_pyear() . "(". $self->get_pages(). "): " . $self->get_title();   
	$self->set_uniquename($uniquename);
    }
    my $existing_pub_id= $self->get_pub_by_uniquename();
    
    if ($pub_id) { #update the publication
	#unless ($self->get_db_name() eq 'PMID') {  #don't update if using Tools::Pubmed.pm
	my $pub_sth = $self->get_dbh()->prepare (" UPDATE pub SET title=?,
                                                                  volume=?,
                                                                  series_name=?,
                                                                  issue=?,
                                                                  pyear=?,
                                                                  pages=?
						 WHERE pub_id=$pub_id");
	$pub_sth->execute($self->get_title(), $self->get_volume(), $self->get_series_name(), $self->get_issue(), $self->get_pyear(), $self->get_pages());
	
	my $abstract_sth = $self->get_dbh()->prepare("UPDATE pubabstract SET abstract=? WHERE pub_id = $pub_id");
	$abstract_sth->execute($self->get_abstract());
	
	#delete the existing authors before storing the ones from the object (see publication.pl:set_author_string)
	$self->remove_existing_authors();
	
    }elsif (!$existing_pub_id) {
	#store new publication
	my $pub_sth= $self->get_dbh()->prepare(
					       "INSERT INTO pub (title, volume, series_name, issue, pyear, pages, uniquename, type_id)                      VALUES (?,?,?,?,?,?,?, (SELECT cvterm_id FROM cvterm WHERE name = ?))");
	$pub_sth->execute($self->get_title, $self->get_volume, $self->get_series_name, $self->get_issue, $self->get_pyear, $self->get_pages(), $self->get_uniquename(), $self->get_cvterm_name());
	####
	$pub_id= $self->get_currval("public.pub_pub_id_seq");
	$self->set_pub_id($pub_id);
	my @dbxrefs=$self->get_stored_dbxrefs();
	# this is for adding a default dbxref (see chado/publication.pl)
	
 	if (!$self->{dbxrefs}) {     
	    @dbxrefs =  ($self->get_db_name().":" . $self->get_title() . " (" .$self->get_pyear() .")")  ; 
	    
	}
	foreach (@dbxrefs) {
	    my ($db_name, $accession) = split ':' , $_;
	    if (!$db_name) { warn "No db_name found for this dbxref (accession = $accession)", next();  } 
	    #see if the accession is already in dbxref table
	    my $dbxref_id= CXGN::Chado::Dbxref::get_dbxref_id_by_accession($self->get_dbh(), $accession, $db_name);
	    my $dbxref=CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
	    if (!$dbxref_id) {  #store a new dbxref
		$dbxref->set_accession($accession);
		$dbxref->set_db_name($db_name);
		$dbxref_id=$dbxref->store();
		
		$self->d( "*** Inserting new dbxref $dbxref_id for accession  $accession...\n");
	    } else { 	$self->d( "^^^ dbxref ID $dbxref_id already exists...\n"); }
	    
	    #this statement is for inserting into pub_dbxref table 
	    my $pub_dbxref_sth= $self->get_dbh()-> prepare("INSERT INTO pub_dbxref (pub_id, dbxref_id) VALUES (?, ?)");
	    $pub_dbxref_sth->execute($pub_id, $dbxref_id);
	    $self->d("*** Inserting new publication dbxref ID= $dbxref_id\n");
	}
	#insert the abstract of the publication
	my $abstract_sth= $self->get_dbh()->prepare("INSERT INTO pubabstract (pub_id, abstract) VALUES (?,?)");
	$abstract_sth->execute($pub_id, $self->get_abstract());
    }else {
	$self->d( "Publication " . $self->get_uniquename() . " already exists in db with pub_id $existing_pub_id ! \n"); 
	$self->set_pub_id($existing_pub_id);
	return $existing_pub_id;
    }
    
    #$self->get_authors() ;
    #auhors are stored for both new and existing publications:
    my $rank=1;
    foreach my $author ( @{$self->{authors}} )   {
	my $author_obj= CXGN::Chado::Pubauthor->new($self->get_dbh());
	$author_obj->set_pub_id($pub_id);
	my ($surname, $givennames)= split  '\|', $author; 
	$author_obj->set_rank($rank);
	$author_obj->set_surname($surname);
	$author_obj->set_givennames($givennames);
	$author_obj->store();
	$rank++;
    }
    #find matching loci and cvterms
    
    return $pub_id;
}


sub get_pubauthors_ids {
  my $self=shift;
  my $pub_id = $self->get_pub_id();
  my @pubauthors_ids;
  my $pubauthor_id;

  my $q = "SELECT pubauthor_id FROM public.pubauthor WHERE pubauthor.pub_id=? ORDER BY rank ";
  my $sth = $self->get_dbh->prepare($q);
  $sth->execute($pub_id);
  
  while (($pubauthor_id) = $sth->fetchrow_array()) {
      push @pubauthors_ids, $pubauthor_id;
  }

  return @pubauthors_ids;

}

=head2 accessors available in this class: 

pub_id
title
volume
series_name
issue
pyear
pages
uniquename
dbxref_id
db_id
db_name 

=cut


sub get_pub_id {
  my $self=shift;
  return $self->{pub_id};

}

sub set_pub_id {
  my $self=shift;
  $self->{pub_id}=shift;
}


sub get_title {
  my $self=shift;
  return $self->{title};

}

sub set_title {
  my $self=shift;
  $self->{title}=shift;
}


sub get_volume {
  my $self=shift;
  return $self->{volume};

}

sub set_volume {
  my $self=shift;
  $self->{volume}=shift;
}


sub get_series_name {
  my $self=shift;
  return $self->{series_name};

}

sub set_series_name {
  my $self=shift;
  $self->{series_name}=shift;
}

sub get_issue {
  my $self=shift;
  return $self->{issue};

}

sub set_issue {
  my $self=shift;
  $self->{issue}=shift;
}


sub get_pyear {
  my $self=shift;
  return $self->{pyear};

}


sub set_pyear {
  my $self=shift;
  $self->{pyear}=shift;
}

sub get_pages {
  my $self=shift;
  return $self->{pages};

}


sub set_pages {
  my $self=shift;
  $self->{pages}=shift;
}


sub get_uniquename {
  my $self=shift;
  return $self->{uniquename};

}


sub set_uniquename {
  my $self=shift;
  $self->{uniquename}=shift;
}


sub get_dbxref_id {
  my $self = shift;
  return $self->{dbxref_id}; 
}

sub set_dbxref_id {
  my $self = shift;
  $self->{dbxref_id} = shift;
}

sub get_db_id {
  my $self = shift;
  return $self->{db_id}; 
}

sub set_db_id {
  my $self = shift;
  $self->{db_id} = shift;
}

sub get_db_name {
  my $self = shift;
  return $self->{db_name}; 
}

sub set_db_name {
  my $self = shift;
  $self->{db_name} = shift;
}


=head2 get_cvterm_name

 Usage: $self->get_cvterm_name()
 Desc:  a getter for the publication type (book or journal- stored in chado cvterm table) 
 Ret:   
 Args:  none
 Side Effects:
 Example:

=cut

sub get_cvterm_name {
  my $self=shift;
  return $self->{cvterm_name};

}

=head2 set_cvterm_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_cvterm_name {
  my $self=shift;
  $self->{cvterm_name}=shift;
}


=head2 get_abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_abstract {
  my $self=shift;
  return $self->{abstract};

}

=head2 set_abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_abstract {
  my $self=shift;
  $self->{abstract}=shift;
}



=head2 accessors set_accession, get_accession

 Usage: these accessors are currently used just for fetching publications from pubmed.
    Use add_dbxref for storing a dbxref accessions (from pubmed or any other database you wish) 
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_accession {
  my $self=shift;
  return $self->{accession};

}

sub set_accession {
  my $self=shift;
  $self->{accession}=shift;
}

=head2 get_dbxref_id_by_db

 Usage: $self->get_dbxref_id_by_db('db_name')
 Desc: find the dbxref_id from db 'db_name' 
 Ret: a dbxref_id
 Args: a db_name
 Side Effects: none
 Example:
  
=cut

sub get_dbxref_id_by_db {
  my $self=shift;
  my $db_name= shift;
  my $query = "SELECT dbxref_id FROM pub_dbxref
               JOIN dbxref USING (dbxref_id) 
               JOIN db USING (db_id) 
               WHERE pub_id = ? AND db.name = ?";
  my $sth=$self->get_dbh()->prepare($query);
  $sth->execute($self->get_pub_id(), $db_name);
  my ($dbxref_id) = $sth->fetchrow_array();
  return $dbxref_id;
}


=head2 add_author

 Usage: $self->add_author($author_data)
 Desc:  a method for storing authors in an array. 
        Each author should have the following data: 
        'last name'|'first_name, initials'
 Ret:  
 Args: $author_data:  a scalar  variable with the  last name, first name
 Side Effects:
 Example:

=cut

sub add_author {
    my $self=shift;
    my $author = shift; 
    push @{ $self->{authors} }, $author;

}

=head2 get_authors

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_authors {
  my $self=shift;
  if($self->{authors}){
      return @{$self->{authors}};
  }
  return undef;
}


=head2 remove_existing_auhors

 Usage: $self->remove_existing_authors()
 Desc:  call this function for deleting the authors of the publication from the database
         use the function only if you are about to update with a new list of authors!
         this function is being called from the object store function when updating a publication,
         and assumes the user already called add_author or set_author_as_string, which populates
         $self->{authors}. The store function will then call Pubauthor->store() for each author in the new list.
 Ret:    nothing
 Args:   none
 Side Effects: DELETES EXISTING AUTHORS FROM THE DATABASE
 Example:

=cut

sub remove_existing_authors {
    my $self=shift;
    my @authors=$self->get_authors(); #the list of authors from the object
    my $query="DELETE FROM pubauthor WHERE pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    if (@authors) { $sth->execute($self->get_pub_id()); }
    else { $self->d( "No authors were added to this object... Nothing was changed in the database!"); }
}


=head2 get_pub_by_uniquename
 Usage:  $self->get_pub_by_uniquename()
 Desc:  check if a publication is already stored in the database
        the check is performed by using the 'uniquename' field which has the format : 'accession#: title'
 Ret:   $pub_id: a database id
 Args: none
 Side Effects:
 Example: 

=cut

sub get_pub_by_uniquename {
    my $self = shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  WHERE uniquename=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_uniquename );
    my ($pub_id) = $sth->fetchrow_array();

    return $pub_id;
}

=head2 set_author_string

 Usage: my $self->set_author_string($author_list)
 Desc:  parses authors from a string and adds each one to the publication object
 Ret:   nothing
 Args:  a string in the following format: "surname1, firstname1. surname2, firstname2. surname3, firstname3"
        trailing spaces are truncated from surname and firstname
 Side Effects: calls $self->add_author()
 Example:

=cut

sub set_author_string {
    my $self=shift;
    my $list = shift;
    print STDERR "found author list $list ! \n";
    my @authors = split '\.', $list;
    foreach my $a(@authors) {
	my ($surname, $givennames)= split  ',', $a;
	print STDERR "surname = $surname, givennames= $givennames \n";
	$surname =~ s/^\s+|\s+$//g;
	$givennames =~ s/^\s+|\s+$//g;
	
	my $author_string=  $surname ."|" . $givennames ;
	$self->add_author($author_string);
	print STDERR "author $author_string\n";
    }
}


=head2 publication_exists

 Usage:  $self->publication_exists($dbxref_accession)
 Desc:  check if a publication is already stored in the database 
        the check is performed by using a pubmed accession
 Ret:   $pub_id: a database id
 Args: pubmed accession number (PMID) 
 Side Effects:
 Example: 

=cut

sub publication_exists {
    my $self = shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  JOIN pub_dbxref USING (pub_id)
                  JOIN public.dbxref USING (dbxref_id)
                  WHERE dbxref.accession=? " ;
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_accession );
    my ($pub_id) = $sth->fetchrow_array();
    $self->set_pub_id($pub_id);
    return $pub_id;
}


=head2 is_associated_publication

 Usage: $self->is_assocated_publication('locus', $locus_id)
 Desc: Check to see if the publication corresponding to the given pub_id is associated with the object of the given type in our database
 Ret: 0 if the publication is not already associated with this object in our databases, 1 if it is.
 Args: object type and object id 
 Side Effects:
 Example:

=cut

sub is_associated_publication {
    my $self = shift;
    my $type = shift;
    my $type_id = shift;

    my $dbxref_id= $self->get_dbxref_id_by_db('PMID');
       
    my ($locus, $allele, $pop);
    if ($type eq 'locus') {
	$locus= CXGN::Phenome::Locus->new($self->get_dbh(), $type_id);
    }
    elsif ($type eq 'allele'){
	$allele=CXGN::Phenome::Allele->new($self->get_dbh(), $type_id);
    } elsif ($type eq 'population'){
	$pop=CXGN::Phenome::Population->new($self->get_dbh(), $type_id);
    }
    ##dbxref object...
    my $dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    my ($associated_publication, $obsolete);
    if ($type eq 'locus') {
	$associated_publication= $locus->get_locus_dbxref($dbxref)->get_object_dbxref_id() || "";
	$obsolete = $locus->get_locus_dbxref($dbxref)->get_obsolete();
    }elsif ($type eq 'allele' ) {
	$associated_publication= $allele->get_allele_dbxref($dbxref)->get_allele_dbxref_id();
	$obsolete = $allele->get_allele_dbxref($dbxref)->get_obsolete();  
    }elsif ($type eq 'population' ) {
	$associated_publication= $pop->get_population_dbxref($dbxref)->get_population_dbxref_id();
	$obsolete = $pop->get_population_dbxref($dbxref)->get_obsolete();  
    }
    if  ($associated_publication && $obsolete eq 'f') {
	return 1;		   
	
    }else{  ##the publication is not associated with the object
	return 0; 
    }    
}


=head2 get_pub_by_accession

  Usage: my $pub=CXGN::Chado::Publication->get_pub_by_accession($dbh, $accession);
 Desc:  get a publication object with an accession
 Ret: a publication object
 Args: publication accession (pubmed ID)
 Side Effects:
 Example:
=cut

sub get_pub_by_accession {
    my $self=shift;
    my $dbh=shift;
    my $accession=shift;
    my $query = "SELECT pub_id
                  FROM public.pub
                  JOIN pub_dbxref USING (pub_id)
                  JOIN public.dbxref USING (dbxref_id)
                  WHERE dbxref.accession=? " ;
    my $sth = $dbh->prepare($query);
    $sth->execute($accession );
    my ($pub_id) = $sth->fetchrow_array();
    if ($pub_id) { 
	my $publication= CXGN::Chado::Publication->new($dbh, $pub_id);
	return $publication;
    }
    else { return undef; }
}


=head2 get_loci

 Usage: $publication->get_loci()
 Desc: find all the associated loci with the publication
 Ret: an array of locus objects
 Args: none
 Side Effects:
 Example:

=cut

sub get_loci {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT locus_id FROM phenome.locus_dbxref
                                          
                                           JOIN public.pub_dbxref USING (dbxref_id)
                                           JOIN pub using (pub_id)
                                           WHERE pub.pub_id= ? AND phenome.locus_dbxref.obsolete='f'");
    $query->execute($self->get_pub_id());
    my @loci;
    while (my ($locus_id) = $query->fetchrow_array()) {
	my $locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
	push @loci, $locus;
    }
    return @loci;
}

=head2 get_curator_ref

 Usage: get_curator_ref($dbh)
 Desc:  static function for finding the dbxref id of the default 'curator' pub entry
 Ret:  a dbxref_id
 Args:  dbh
 Side Effects: none
 Example:

=cut

sub get_curator_ref {

    my $dbh=shift;
    my $query = "SELECT dbxref_id FROM public.dbxref JOIN cvterm USING (dbxref_id) JOIN pub on (type_id= cvterm_id)
                 WHERE title = ?";
    my $sth= $dbh->prepare($query);
    $sth->execute('curator');
    my ($dbxref_id) = $sth->fetchrow_array();
    return $dbxref_id;
}

=head2 get_authors_as_string

 Usage: $self->get_authors_as_string()
 Desc:  get all the authors of the publication as a string
 Ret:   a string "lastname1, firstname1. lastname2, firstname2."...
 Args: none
 Side Effects: none
 Example:

=cut

sub get_authors_as_string {
    my $self=shift;
    my $pub_id = $self->get_pub_id();
    my $string;
    my $query = "SELECT pubauthor_id FROM public.pubauthor WHERE pubauthor.pub_id=? ORDER BY rank ";
    my $sth = $self->get_dbh->prepare($query);
    $sth->execute($pub_id);
    
    while (my ($id) = $sth->fetchrow_array()) {
	my  $pubauthor = CXGN::Chado::Pubauthor->new($self->get_dbh, $id);
	my $last_name  = $pubauthor->get_surname();
	my $first_names = $pubauthor->get_givennames();

	my ($first_name, $same) = split (/,/, $first_names);
	if ($same) {
	    $string .="$last_name, $same. ";
	} else { $string .= "$last_name, $first_name. "; }
    }
    chop $string;
    chop $string;
    return $string;
}

#####

=head2 get_pub_info

 Usage: CXGN::Chado::Publication::get_pub_info($dbxref,$db)
 Desc:  A class function for printing publication info on a web page
 Ret:  html
 Args: dbxref object, db_name
 Side Effects:
 Example:

=cut


sub get_pub_info {
    my ($dbxref, $db)=@_;
    my $pub_info;
    my $accession= $dbxref->get_accession();
    my $pub=$dbxref->get_publication();
    my $pub_title=$pub->get_title();
    my $pub_id= $pub->get_pub_id();
    my $abstract_info= $pub->get_abstract() ."<b> <i>" . $pub->get_authors_as_string() ."</i>" .  $pub->get_series_name() . $pub->get_pyear. $pub->get_volume() . "(" .  $pub->get_issue() .")" . $pub->get_pages() ." </b>" ;
    $pub_info = qq|<a href="/chado/publication.pl?pub_id=$pub_id" >$db:$accession</a> $pub_title |;
    return ($pub_info, $abstract_info);
}

=head2 print_pub_ref

 Usage: $self->print_pub_ref()
 Desc:  printing a reference string for your publication 
 Ret:  string
 Args: none
 Side Effects:
 Example:

=cut


sub print_pub_ref {
    my $self=shift;
   
    my $accession= $self->get_accession();
    my $title=$self->get_title();
    my $series=$self->get_series_name();
    my $pages=$self->get_pages();
    my $vol=$self->get_volume();
    my $issue= $self->get_issue();
    my $pyear=$self->get_pyear();
    my @authors=$self->get_authors() ;
    my $author_string= join (', ' , @authors) || $self->get_authors_as_string(); ;
    my $ref= $author_string . ". (" . $pyear . ") " . $title . ". " .  $series . ". " . $issue . ":" . $pages . "." ;
    return $ref;
}
      

=head2 print_mini_ref

 Usage: $self->print_mini_ref()
 Desc:  printing a truncated reference string for your publication 
 Ret:  string
 Args: none
 Side Effects:
 Example:

=cut


sub print_mini_ref {
    my $self=shift;
    my $accession= $self->get_accession();
    my $title=$self->get_title();
    my $series=$self->get_series_name();
 
    my $pyear=$self->get_pyear();
    my @authors=$self->get_authors() || ( split(/\./ , $self->get_authors_as_string() ) )  ;
    my $author_string= $authors[0];
    if (scalar(@authors) == 2 ) { $author_string .= " and " . $authors[1] ; }
    elsif (scalar(@authors) > 2 ) { $author_string .= " et al., " ; } 
    my $ref= $author_string . ".  " . $title .  " (" . $pyear . ") " .  $series ;
    return $ref;
}

=head2 get_dbxrefs

 Usage: my @dbxrefs=$self->get_dbxrefs();
 Desc:  find the dbxrefs associated with the publication
 Ret:   a list of dbxref objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_dbxrefs {
    my $self=shift;
    my $query = "SELECT dbxref_id FROM pub_dbxref WHERE pub_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_pub_id());
    my @dbxrefs;
    while (my ($id) = $sth->fetchrow_array() ) {
	my $dbxref = CXGN::Chado::Dbxref->new($self->get_dbh(), $id);
	push @dbxrefs, $dbxref;
    }
    return @dbxrefs;
}

=head2 add_dbxref

 Usage: $self->add_dbxref($full_accession)
 Desc:  a method for storing dbxrefs in an array. 
        Each accession should be in the following format:
        'db_name:accession'
 Ret:  
 Args: $full_accession:  a scalar  variable with the  db_name and accession
 Side Effects:
 Example:

=cut

sub add_dbxref {
    my $self=shift;
    my $full_accession = shift; 
    push @{ $self->{dbxrefs} }, $full_accession;

}

=head2 get_stored_dbxrefs

 Usage: $self->get_stored_dbxrefs()
 Desc:  get the list of dbxrefs stored in the publication object
 Ret:   list of full accessions (db_name:accession) or undef if none are found
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_stored_dbxrefs {
  my $self=shift;
  if($self->{dbxrefs}){
      return @{$self->{dbxrefs}};
  }
  return undef;
}


=head2 delete

 Usage: $self->delete()
 Desc:  delete the current publication from pub, pub_dbxref, pubauthor and pubabstract
 Ret:   nothing
 Args:  none
 Side Effects: access the database
 Example:

=cut

sub delete {
    my $self=shift;
    my $query="DELETE FROM pub WHERE pub_id=?"; #ON DELETE CASCADE in pub_dbxref, pubabstract and pubauthor tables
    my $sth=$self->get_dbh()->prepare($query);
    my @dbxrefs=$self->get_dbxrefs();
    foreach my $dbxref(@dbxrefs) {
	my @loci= $self->get_loci();
	my @alleles;
	my @populations;
	if (@loci || @alleles || @populations) { 
	    return "The publication is associated with other database objects. Cannot delete.!"
	    }
    }
    #if (!$associated) {
    $sth->execute($self->get_pub_id() );
    #}
    return undef;
}

=head2 get_message

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_message {
  my $self=shift;
  return $self->{message};

}

=head2 set_message

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_message {
  my $self=shift;
  $self->{message}=shift;
}



=head2 get_pub_rank
 
 Usage: my @name_title= CXGN::Chado::Publication::get_pub_rank($dbh, $name, $source);
         adding a pub_id as a 4th argument will match the $name string against the one publication
 Desc:  find the related pub_ids, ranks and headlines for string $name 
        using tsearch2 vector on the title field
 Ret:   arrayref of an arrayref [pub_id, rank, headline]
 Args:  database handle, a string to match , and the source to lookup (title or abstract)
 Side Effects:  none
 Example:

=cut

sub get_pub_rank {
    my $dbh=shift;
    my $string=shift;
    my $lookup=shift;
    my $pub_id= shift;
    $dbh->do("set search_path=public,tsearch2");
    my $query;
    if ($lookup eq "title") {
	$query= "SELECT public.pub.pub_id,  tsearch2.rank(public.pub.title_tsvector, q),  tsearch2.headline(public.pub.title, q) FROM public.pub, tsearch2.to_tsquery('$string'::Text) as q WHERE public.pub.title_tsvector @@ q";
    }elsif ($lookup eq "abstract") {
	$query= "SELECT public.pubabstract.pub_id,  tsearch2.rank(public.pubabstract.abstract_tsvector, q),  tsearch2.headline(public.pubabstract.abstract, q) FROM public.pubabstract, tsearch2.to_tsquery('$string'::Text) as q WHERE public.pubabstract.abstract_tsvector @@ q";
    }else { warn "must call get_pub_rank with 'title' or 'abstract' as third argument!!"; }
    if ($pub_id) { $query .= "  AND pub_id = $pub_id" };
    
    my $sth=$dbh->prepare($query);
    $sth->execute();
    my @result; 
    while (my ($pub_id, $rank, $headline)= $sth->fetchrow_array()) {
	push @result, [$pub_id, $rank, $headline];
    }
    return \@result;
}

=head2 get_ranked_loci

 Usage: find the associated loci from locus_pub_rank table
 Desc:  publications are indexed and associated with loci descriptors. 
    This method accesses the ranked loci for the publication object 
 Ret: hash ref locus_id=>ranked_score
 Args: none
 Side Effects:
 Example:

=cut

sub get_ranked_loci { 
    my $self=shift;
    my $pub_id = $self->get_pub_id();
 
    my $query = "SELECT locus_id, rank,match_type, headline, validate
                 FROM locus_pub_ranking 
                 LEFT JOIN locus_pub_ranking_validate USING (locus_id, pub_id) 
                 WHERE pub_id =? ORDER BY rank desc";
  
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($pub_id);
    my $total_locus_pub_rank={};
    my $locus_pub_rank={};
   
    while (my @pub = $sth->fetchrow_array() ) {
	my $validate= $pub[4] || "";
	#if ($validate ne "no") {
	    $locus_pub_rank->{$pub[0]} += $pub[1]; # total rank for this publication
	#}
    }
    #sort the hash by the total rank, descending
    $locus_pub_rank= $locus_pub_rank->{$b} <=> $locus_pub_rank->{$a};
    return $locus_pub_rank || undef;
}

=head2 title_tsvector_string

 Usage: $self->title_tsvector_string();
 Desc:  get the list of indexed words from the 'title' field. Can be parsed later and used for pther purposes, 
        such as querying the locus table for possible word matches.
 Ret:   a string (e.g. 'determin' 'trans-act' 'pseudorecombin' ) 
 Args: none
 Side Effects: none
 Example:

=cut

sub title_tsvector_string {
    my $self=shift;
    my $query = "SELECT strip(to_tsvector(title) ) FROM pub where pub_id = ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_pub_id());
    my ($string) = $sth->fetchrow_array();
    return $string;
}

=head2 abstract_tsvector_string

 Usage: $self->abstract_tsvector_string();
 Desc:  get the list of indexed words from the 'abstract' field. Can be parsed later and used for pther purposes, 
        such as querying the locus table for possible word matches.
 Ret:   a string (e.g. 'geminivirus' 'pseudorecombin' 'whitefly-associ' ) 
 Args: none
 Side Effects: none
 Example:

=cut

sub abstract_tsvector_string {
    my $self=shift;
    my $query = "SELECT strip(to_tsvector(abstract) ) FROM pubabstract where pub_id = ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_pub_id());
    my ($string) = $sth->fetchrow_array();
    return $string;
}

=head2 store_pub_curator

 Usage: $self->store_pub_curator()
 Desc:  store a new pub_curator, or update pub_curtor status
 Ret:   pub_curator_id
 Args:  none (your program should set sp_person_id (the person loading the publication) , status, and curated_by (the person who curated the publication
 Side Effects: 
 Example:

=cut

sub store_pub_curator {
    my $self=shift;
    my $id= $self->get_pub_curator_id();
    my ($query, $sth);
    #if the publication is not stored in pub_curator table
    if (!$id) {
	$query = "INSERT INTO phenome.pub_curator (pub_id, sp_person_id, assigned_to, status,  curated_by)
                 VALUES (?,?,?,?,?)";
	$sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_pub_id(), $self->get_sp_person_id(), $self->get_curator_id(), $self->get_status(), $self->get_curated_by());
	$id= $self->get_currval("phenome.pub_curator_pub_curator_id_seq");
	
    }else { #the publication is in pub_curator- need to update! 
	$query = "UPDATE phenome.pub_curator SET status=?,
                   date_curated=now(), assigned_to=?, 
                    curated_by = ?
                  WHERE pub_id = ?";
	$sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_status(), $self->get_curator_id(), $self->get_curated_by(), $self->get_pub_id());
    }
    return $id;
}

=head2 get_pub_curator_id

 Usage: $self->get_pub_curator_id()
 Desc:  find the database id of pub_curator table for this publication (there should be only one)
 Ret:   database id or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_pub_curator_id {
    my $self=shift;
    my $query= "SELECT pub_curator_id FROM phenome.pub_curator WHERE pub_id = ?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_pub_id());
    my ($id) = $sth->fetchrow_array();
    return $id;
}

=head2 is_curated

 Usage: $self->is_curated()
 Desc:  Check if the publication is stored in pub_curator table
 Ret:   a database id or undef
 Args:  none
 Side Effects: none
 Example:

=cut

sub is_curated {
    my $self=shift;
    my $q="SELECT pub_curator_id FROM pub_curator WHERE pub_id=?";
    my $sth=$self->get_dbh()->prepare($q);
    $sth->execute($self->get_pub_id);
    my ($id) = $sth->fetchrow_array();
    return $id || undef;
}



=head2 accessors get_curator_id, set_curator_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_curator_id {
  my $self = shift;
  return $self->{curator_id}; 
}

sub set_curator_id {
  my $self = shift;
  $self->{curator_id} = shift;
}


=head2 accessors get_curated_by, set_curated_by

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_curated_by {
  my $self = shift;
  return $self->{curated_by}; 
}

sub set_curated_by {
  my $self = shift;
  $self->{curated_by} = shift;
}

=head2 accessors get_status, set_status

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_status {
  my $self = shift;
  return $self->{status}; 
}

sub set_status {
  my $self = shift;
  $self->{status} = shift;
}

=head2 accessors get_sp_person_id, set_sp_person_id

 Usage: $self->set_sp_person_id()
 Desc:  owner of a pblication can only be used for pub_curator table. 
 Property
 Side Effects:
 Example:

=cut

sub get_sp_person_id {
  my $self = shift;
  return $self->{sp_person_id}; 
}

sub set_sp_person_id {
  my $self = shift;
  $self->{sp_person_id} = shift;
}

return 1;
