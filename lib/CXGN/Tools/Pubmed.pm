
package CXGN::Tools::Pubmed;
use strict;
use XML::Twig;
use CXGN::Chado::Publication;
use CXGN::Chado::Pubauthor;

=head1 CXGN::Tools::Pubmed

get data from pubmed and parse the fields that should be loaded in Chado schema
 
 
=head2


=head1 Author

Naama Menda

=cut
 
=head2 new

 Usage: my $pubmed = CXGN::Tools::Pubmed->new($publication_obj);
 Desc:
 Ret:    
 Args: $publication_object 
 Side Effects:
 Example:

=cut  

our $pub_object=undef;

sub new {
    my $class = shift;
    $pub_object= shift;
 
    
    my $args = {};  
    my $self = bless $args, $class;
    
      
    $self->set_pub_object($pub_object);  
   

          
    my $accession= $pub_object->get_accession();
    if ($accession) {
	$self->fetch($accession);
    }
    
    return $self;
}
	

sub fetch {
    my $self=shift;
    my $accession=shift;
    
    my $pub_xml = `wget "eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$accession&rettype=xml&retmode=text"  -O -  `;
    
    eval {
	my $twig=XML::Twig->new(
				twig_roots   => 
				{
				    'Article/ArticleTitle'    => \&title,
				    'JournalIssue/Volume'     => \&volume,
				    'JournalIssue/Issue'      => \&issue,
				    'DateCompleted/Year'      => \&pyear,
				    'PubDate/Year'            => \&pyear,
				    'Pagination/MedlinePgn'   => \&pages,
				    'Journal/Title'           => \&journal_name,
				    'PublicationTypeList/PublicationType'  => \&pub_type,
				    'Abstract/AbstractText'   => \&abstract,
				    Author       => \&author, 
				},
				twig_handlers =>
				{
				    # AbstractText     => \&abstract,
				},
				
				pretty_print => 'indented',  # output will be nicely formatted
				); 
	
	$twig->parse($pub_xml ); # build it
	
	
	my $uniquename= $accession . ":" . $self->get_pub_object->get_title();
	if (!$pub_object->get_uniquename() ) { $pub_object->set_uniquename($uniquename); }
	#$pub_object->set_db_name('PMID');
	if (!$pub_object->get_cvterm_name) {
	    $pub_object->set_cvterm_name('journal');
	    $pub_object->d("!No cvtermname found for publication $accession. Setting to default 'journal'! ");
	}
	#$pub_object->store(); #store from the code..
	$pub_object;
    };
     if($@) {
	my $message= "Error in transaction or NCBI server seems to be down. Please check your input for accession $accession or try again later.\n $@";
	$pub_object->set_message($message);
    }else { return undef ; }
}

=head2 get_pub_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pub_object {
  my $self=shift;
  return $self->{pub_object};

}

=head2 set_pub_object

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_pub_object {
  my $self=shift;
  $self->{pub_object}=shift;
}

=head2 get_title

 Usage:
 Desc: get the title of the article
 Ret:
 Args:
 Side Effects:
 Example:

=cut  

sub get_title {
    my $self=shift;
    return $self->{articleTitle};
}

=head2 title

 Usage:
 Desc: set the title of the article
 Ret:
 Args:
 Side Effects:
 Example:

=cut  

sub title {

     my ($twig, $elt)= @_;
     $pub_object->set_title($elt->text) ;
     $twig->purge;
 }


=head2 volume

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub volume {
    my ($twig, $elt)= @_;
    $pub_object->set_volume($elt->text) ;
    $twig->purge;
}


=head2 get_issue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_issue {
  my $self=shift;
  return $self->{issue};

}

=head2 issue

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub issue {
    my ($twig, $elt)= @_;
    $pub_object->set_issue($elt->text) ;

    $twig->purge;
}

=head2 get_pyear

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pyear {
  my $self=shift;
  return $self->{pyear};

}

=head2 pyear

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub pyear {
    my ($twig, $elt)= @_;
    my $pyear = $elt->text;
    $pub_object->set_pyear($pyear) if !$pub_object->get_pyear() ;
    #$pub_object->d("DEBUG:pyear is '$pyear'!!!!"); 
    $twig->purge;
}

=head2 get_pages

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pages {
  my $self=shift;
  return $self->{pages};

}

=head2 pages

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub pages {
    my ($twig, $elt)= @_;
    $pub_object->set_pages($elt->text) ;

    $twig->purge;
}


 

=head2 get_journal_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_journal_name {
  my $self=shift;
  return $self->{journal_name};

}

=head2 journal_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub journal_name {
    my ($twig, $elt)= @_;
    $pub_object->set_series_name($elt->text) ;

    $twig->purge;
}

=head2 get_pub_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_pub_type {
  my $self=shift;
  return $self->{pub_type};

}

=head2 pub_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub pub_type {
    my ($twig, $elt)= @_;
    my $pub_type= $elt->text;
    if ($pub_type =~ m/Journal/i) { 
	$pub_type = 'journal' ; 
	$pub_object->set_cvterm_name($pub_type) ;
	$pub_object->d("DEBUG:found pub_type '$pub_type' . Setting cvterm_name to 'journal' !!\n");

    }else {
	#$pub_object->d("DEBUG:pub_type $pub_type is not a recognizeable cvterm!!\n");
    }
    $twig->purge;
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

=head2 abstract

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub abstract {
    my ($twig, $elt)= @_;
    $pub_object->set_abstract($elt->text) ;

    $twig->purge
}



=head2 author

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub author {
    my ($twig, $elt)= @_;
    
    my $lastname=$elt->children_text('LastName');
    my $initials=$elt->children_text('Initials');  #sometimes the firstname has no initials but full first name 'ForName'..
  
    if (!$initials) {  $initials=$elt->children_text('ForeName') || $elt->children_text('FirstName') ; }
    
    
    my $author_data=  $lastname ."|" . $initials ; #.",".$initials ;
    
    $pub_object->add_author($author_data) ;
    print STDERR "author $author_data\n";
    #$rank ++;
    $twig->purge
}


return 1;
