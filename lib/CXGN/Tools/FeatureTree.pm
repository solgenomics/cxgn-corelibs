package CXGN::Tools::FeatureTree;
use strict;

use XML::Twig;

use CXGN::Chado::Feature;

use CXGN::Tools::Entrez;



=head1 CXGN::Tools::FeatureTree

get data from the NucleotideCore site and parse the necessary fields to fill  feature objects
 
 
=head2


=head1 Authors


Naama Menda (nm249@cornell.edu)

=cut
 
=head2 new

 Usage: my $feature_fetch = CXGN::Tools::FeatureTree->new($GBaccession);
 Desc:
 Ret:     
 Args: genbank accession
 Side Effects:
 Example:

=cut  

#our $feature_object=undef;
our @Ftree=();

sub new {
    my $class = shift;
    my $gb= shift;
    
    my $args = {};  
    my $self = bless $args, $class;
            
    if ($gb) {
	@Ftree=();
	$self->fetch($gb);
    }
    return $self;
}

sub fetch {
    my $self=shift;
    my $gb=shift; #GenBank accessions are stored in feature.name!
    
    my $feature_xml = `wget "eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$gb&rettype=xml&retmode=text"  -O -  `;
    
    eval{ 
	my $twig=XML::Twig->new(
			    twig_roots   => 
				{
				    'Textseq-id/Textseq-id_accession'   => \&name,
				    'Textseq-id/Textseq-id_version'     => \&version,
				    'Seq-data_iupacna/IUPACna'  => \&residues,
				    'Seq-inst/Seq-inst_length'          => \&seqlen,
				    'Seqdesc/Seqdesc_title'             => \&description,
				    'Org-ref/Org-ref_taxname'       => \&organism_name,
				    'Org-ref_db/Dbtag/Dbtag_tag/Object-id/Object-id_id'   => \&organism_taxon_id,
				    'PubMedId'                     => \&pubmed_id,
				    'Bioseq_id/Seq-id/Seq-id_gi'   =>\&accession,  # accession refers to genBnk GI number
				    'MolInfo/MolInfo_biomol'       =>\&molecule_type,
				},
				twig_handlers =>
			    {
				# AbstractText     => \&abstract,
			
			    },
				pretty_print => 'indented',  # output will be nicely formatted
				); 
	
	$twig->parse($feature_xml );
    }; 
    if($@) {
	my $message= "!!NCBI server seems to be down. Please try again later!!.\n $@";
	print STDERR $message;
	return $message;
    }else { 
	print STDERR "exiting FeatureTree.pm!\n";
	return undef ; 
    }
}

sub get_feature_list {
    my $self=shift;
    return @Ftree;
}

=head2 organism_name

 Usage:
 Desc: Store the scientific organism name. This is used only for cleaner error messages.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_name {
    my ($twig, $elt) = @_;
    my $o_name=$elt->text;
    push @ {$Ftree[0] }, $o_name;
    $twig->purge();
}


=head2 organism_taxon_id

 Usage:
 Desc: Store the genbank taxon_id 
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub organism_taxon_id {
    my ($twig, $elt) = @_;
    my $o_taxon_id=$elt->text;
    push @ {$Ftree[1] }, $o_taxon_id;
    $twig->purge();
}

sub name {
    my ($twig, $elt)= @_;
    
    my $name_data=  $elt->text;
    push @{ $Ftree[2] }, $name_data;
    #print STDERR "**name (genbank accession) $name_data\n";
    $twig->purge;
}


sub accession {
    my ($twig, $elt)= @_;
    
    my $gi=  $elt->text;
    push @{ $Ftree[3] }, $gi if (!grep{/^$gi$/ } @{ $Ftree[3] } );
    $twig->purge;
}

sub pubmed_id {
    my ($twig, $elt)= @_;
    my $pubmed_id = $elt->text;
    
   # my @pubmed_ids = $feature_object->get_pubmed_ids();
   # my @already_exists = grep(/$pubmed_id/, @pubmed_ids);
    #if(!@already_exists){
    #	$feature_object->add_pubmed_id($pubmed_id);
    push @ { $Ftree[4] }, $pubmed_id if (!grep{/^$pubmed_id$/ } @{ $Ftree[4] } );
    $twig->purge;
}


sub version {
    my ($twig, $elt)= @_;
    my $version= $elt->text;
    push @ { $Ftree[5] }, $version;
    $twig->purge;
}


sub residues {
    my ($twig, $elt)= @_;
    my $res=$elt->text;
    push @ { $Ftree[6] } , $res;
    $twig->purge;
}


sub seqlen {
    my ($twig, $elt)= @_;
    my $seqlen=$elt->text;
    push @ { $Ftree[7] } , $seqlen;
    $twig->purge;
}

sub description {
    my ($twig, $elt)= @_;
    my $desc=$elt->text;
    push @ { $Ftree[8] } , $desc;

    $twig->purge;
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
    if (!$molecule) {
	warn "no molecule type found for type $mol_text!!\n";} 
    else { 
	print STDERR "molecule type = $molecule\n\n"; 
	push @ { $Ftree[9] } , $molecule;
    }
    $twig->purge;
}

#### DO NOT REMOVE
return 1;
####
