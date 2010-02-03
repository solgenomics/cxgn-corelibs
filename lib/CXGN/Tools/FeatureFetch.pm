package CXGN::Tools::FeatureFetch;
use strict;

use XML::Twig;

use CXGN::Chado::Feature;

use CXGN::Tools::Entrez;
use CXGN::Debug;


=head1 CXGN::Tools::FeatureFetch

get data from the NucleotideCore site and parse the necessary fields to fill a feature object
 
 
=head2


=head1 Authors

Tim Jacobs
Naama Menda (nm249@cornell.edu)

=cut
 
=head2 new

 Usage: my $feature_fetch = CXGN::Tools::FeatureFetch->new($feature_obj);
 Desc:
 Ret:     
 Args: $feature_object 
 Side Effects:
 Example:

=cut  

our $feature_object=undef;
our %tree=(); # (name =>$tree_name , organism=>$tree_organism, taxon_id=>$taxon_id) ;
 
sub new {
    my $class = shift;
    $feature_object= shift;
    
    my $args = {};  
    my $self = bless $args, $class;
    
    $self->set_feature_object($feature_object);  
    
    my $GBaccession= $feature_object->get_name();
    if ($GBaccession) {
	$self->fetch($GBaccession);
    }
    return $self;
}

=head2 fetch

 Usage: CXGN::Tools::featureFetch->fetch($genBank_accession);
 Desc:
 Ret:    
 Args: $genBank_accession
 Side Effects:
 Example:

=cut  

sub fetch {
    my $self=shift;
    my $GBaccession=shift; #GenBank accessions are stored in feature.name!
    
#Entrez display format GBSeqXML:
#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=5&rettype=gb&retmode=xml
#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=8&rettype=gp&retmode=xml


    my $feature_xml = `wget "eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$GBaccession&rettype=xml&retmode=text"  -O -  `;
    
    eval{ 
	my $twig=XML::Twig->new(
			    twig_roots   => 
				{
				    'Textseq-id/Textseq-id_accession'   => \&name,
				    'Textseq-id/Textseq-id_version'     => \&version,
				    'Seq-data_iupacna/IUPACna'          => \&residues, #na sequences
				    'Seq-data_iupacaa/IUPACaa'          => \&residues,  #aa sequence
				    'Seq-inst/Seq-inst_length'          => \&seqlen,
				    'Seqdesc/Seqdesc_title'             => \&description,
				    'Org-ref/Org-ref_taxname'           => \&organism_name,
				    'Org-ref_db/Dbtag/Dbtag_tag/Object-id/Object-id_id'   => \&organism_taxon_id,
				    'PubMedId'                          => \&pubmed_id,
				    'Bioseq_id/Seq-id/Seq-id_gi'        => \&accession,  # accession refers to genBnk GI number
				    'MolInfo/MolInfo_biomol'            => \&molecule_type,
				},
				twig_handlers =>
			    {
				# AbstractText     => \&abstract,
			
			    },
				pretty_print => 'indented',  # output will be nicely formatted
				); 
	
	$twig->parse($feature_xml );

	
	my $feature= $self->get_feature_object();
	my $db_name= 'DB:GenBank_GI';
	$feature->set_db_name($db_name);
	$feature->set_uniquename($feature->get_name() . "." . $feature->get_version() );
	
	
	$feature->d("name= " . $feature->get_name() . "!");
		
	$feature->d("organism name= " . $feature->get_organism_name() . "!");
	$feature->d("taxon_id= " . $feature->get_organism_taxon_id() . "!");
	$feature->d("description=  " . $feature->get_description() . "!");
	$feature->d("version= " . $feature->get_version() . "!");
	$feature->d("uniquname= " . $feature->get_uniquename() . "!");
	$feature->d("molecule type= " . $feature->get_molecule_type() . "!");
	$feature->d("description= " . $feature->get_description() . "!");
	$feature->d("seqlen= " . $feature->get_seqlen() . "!");
	$feature->d("residues= " . $feature->get_residues() . "!");
	
    }; 
    if($@) {
	my $message= "!!NCBI server seems to be down. Please try again later!!.\n $@";
	print STDERR $message;
	$self->get_feature_object()->set_message($message);
    }else { print STDERR "exiting FeatureFetch.pm!\n" ; }
}

sub get_feature_object {
    my $self=shift;
    return $self->{feature_object};
    
}

sub set_feature_object {
    my $self=shift;
    $self->{feature_object}=shift;
}

=head2 get_organism_name
    
  Usage:
  Desc: Retrieve the scientific organism name
  Ret:
  Args:
    Side Effects:
  Example:

=cut

sub get_organism_name {
    my $self=shift;
    return $self->{organism_name};
}

=head2 organism_name

 Usage:
 Desc: Store the scientific organism name in the feature object. This is used only for cleaner error messages.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_name {
    my ($twig, $elt) = @_;
   
    $tree{organism} = $elt->text();
    print STDERR "\n**FeatureFetch found organism name  : '". $elt->text() . "' \n";
    #$twig->purge();
}

=head2 get_organism_taxon_id

 Usage:
 Desc: Retrieve the organisms genbank-given taxon_id
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_organism_taxon_id {
    my $self=shift;
    return $self->{organism_taxon_id};
}

=head2 organism_taxon_id

 Usage:
 Desc: Store the genbank taxon_id in the feature object
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_taxon_id {
    my ($twig, $elt) = @_;
    print STDERR "calling organism_taxon_id!!\n";
    $tree{taxon_id} = $elt->text();
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {	
	$feature_object->set_organism_taxon_id($elt->text);
	print STDERR "**the organism taxon id is : '". $feature_object->get_organism_taxon_id() . "' \n";
	
    }

    #$twig->purge();
}

sub get_name {
    my $self=shift;
    return $self->{name};
}

sub name {
    my ($twig, $elt)= @_;
    print STDERR "Calling name!! organism = " . $tree{organism} . ". taxon_id= " . $tree{taxon_id} .  "\n";
    my $name_data=  $elt->text;
 
    my $fname= $feature_object->get_name();
    print STDERR "fname = $fname , name_data = $name_data******#####\n";
    if (lc($fname) eq lc($name_data)) { 
	print STDERR "calling name with $name_data!!!!!!!!!!!!!!\n";
	$tree{name} = $name_data; 
	$feature_object->set_organism_name($tree{organism}) ;
	$feature_object->set_organism_taxon_id($tree{taxon_id});
	
	$twig->purge;
	
    } else { $tree{name}= undef; }
     
    #$twig->purge;
}

sub get_accession {
    my $self=shift;
    return $self->{accession};
}

sub accession {
    my ($twig, $elt)= @_;
    #print STDERR "Calling accession!! Found: " .  $elt->text() . " \n";
    my $accession_data=  $elt->text;
 
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {	
	$feature_object->set_accession($elt->text);
    }
    #$twig->purge;
}




sub pubmed_id {
    my ($twig, $elt)= @_;
    my $pubmed_id = $elt->text;
    print STDERR "Calling pubmed_id";
    my @pubmed_ids = $feature_object->get_pubmed_ids();
    
    my @already_exists = grep(/$pubmed_id/, @pubmed_ids);

    if(!@already_exists){
	$feature_object->add_pubmed_id($pubmed_id);
	print STDERR "***Adding pubmed_id to array: $pubmed_id \n";
    }
    $twig->purge;
}

sub get_version {
    my $self=shift;
    return $self->{version};
}

sub version {
    my ($twig, $elt)= @_;
    print STDERR "Calling version!!\n";
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {
	$feature_object->set_version($elt->text);
    }
    
    $twig->purge;
}

sub get_residues {
    my $self=shift;
    print STDERR "Calling residues!!\n";
    return $self->{residues};
}

sub residues {
    my ($twig, $elt)= @_;
    print STDERR "CAlling residues!! \n";
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {
	$feature_object->set_residues($elt->text);
    }
    $twig->purge;
}

sub get_seqlen {
    my $self=shift;

    return $self->{seqlen}
}

sub seqlen {
    my ($twig, $elt)= @_;
    print STDERR "calling seqlen!!\n";
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {
	$feature_object->set_seqlen($elt->text() ) ;
    }
    $twig->purge;
}


sub description {
    my ($twig, $elt)= @_;
    print STDERR "calling description!!\n";

    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {
	$feature_object->set_description($elt->text);
    }
    
    $twig->purge;
}

sub get_description {
    my $self = shift;
    return $self->{description};
}

sub get_molecule_type {
    my $self=shift;
    print STDERR "calling molecule_type!!\n";
    
    return $self->{molecule_type}
}

sub molecule_type {
    my ($twig, $elt)= @_;
    
    my %mol_hash = (
		    'mRNA'        => 'mRNA',
		    '3'           => 'mRNA',
		    'rRNA'        => 'rRNA',
		    '4'        => 'rRNA',
		    'scRNA'       => 'scRNA',
		    '7'       => 'scRNA',
		    'genomic DNA' => 'genomic_clone',
		    'genomic clone' => 'genomic_clone',
		    '1' => 'genomic_clone',
		    'genomic RNA' => 'RNA',
		    'Pre-RNA'     => 'PRE-RNA',
		    'unassigned DNA' => 'DNA',
		    'unassigned RNA' => 'RNA',
		    'ss-RNA'      => 'RNA',
		    'RNA'         => 'RNA',
		    'DNA'         =>'DNA',
		    'snRNA'       =>'snRNA',
		    '8'           => 'protein'
		    );
    my $mol_text= ($elt->text);
    my $molecule = $mol_hash{$mol_text};
    if (!$molecule) {warn "no molecule type found for type $mol_text!!\n";} 
    else {  print STDERR "molecule type = $molecule\n"; }
    
    if (lc($tree{name}) eq lc($feature_object->get_name()) ) {
	$feature_object->set_molecule_type($molecule);
    }
    $twig->purge;
}

#### DO NOT REMOVE
return 1;
####
