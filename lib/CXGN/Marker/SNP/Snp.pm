=head1 NAME

CXGN::Marker::SNP - a class to deal with SNP information.

=head1 DESCRIPTION

This class deals with a single SNP (Simple Nucleotide Polymorphism) - it can be used to store, modify, or delete information about a SNP. The term SNP is interpreted broadly and includes indels as well as polymorphisms that may include several nucleotides.

For SNP querying of aggregate information, use the L<CXGN::SNP::Query> class [not yet implemented].

It inherits from L<CXGN::DB::ModifiableI>.

SNPs are linked to sequences and accessions, and specify the base change. In addition, SNPs can be linked to markers that exploit that SNP, and to other meta information, such as who submitted the information, if it is experimentally verified, and the method of discovery.

=head1 AUTHOR

Homa Teramu <hst28@cornell.edu>

=head1 FUNCTIONS

This class implements the following methods:

=cut


use strict;
use warnings;

package CXGN::Marker::SNP::Snp;

use base qw | CXGN::DB::ModifiableI | ;
use base qw | CXGN::DB::Object |;
use CXGN::Marker::SNP::Schema;
use Carp;



=head2 new

 Usage: my $row_obje = CXGN::SNP::Snp->new($schema, $id)
 Desc:  creates a new Snp row object
 Ret:   CXgN::SNP::Snp object
 Args:  a $schema object and 
        $id 
 Side Effects:  none
 Example:

=cut
sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    #bless the class to create the object and set the schema into the object.
    my $self = $class-> SUPER::new($schema);
    $self->set_schema($schema);
    
    my $row_obje;
    if(defined $id){
	if ($id =~ m/^\d+$/){
	    $row_obje = $self->get_resultset('Snp')->find({snp_id=>$id});
	}else {
	    croak("DATA TYPE ERROR: The id: ($id) is not an integer for CXGN::SNPSN");
	}
    }else{
	#creating an emplty row object
	$row_obje = $self->get_resultset('Snp')->new({});
    }
	$self->set_object_row($row_obje);
    return $self;
}

=head2 store 

 Usage: $self->store()
 Desc:  store a new SNP 
        Update if has a snp_id
        Do nothing is the snp_id exists
 Ret:  list of snp row objects
 Arg:  none  
 Side Effects: none
 Example:

=cut
sub store{
    my $self = shift;
    my $id = $self->get_snp_id();
    my $schema = $self->get_schema(); 
      
    if(!$id){
	my $new_row = $self->get_object_row()->insert();
	$id = $new_row->get_column('snp_id');
	$self->set_object_row($new_row);
    }else{
	my $exists = $self->exists_in_database();
	if($exists =~ m/^\d+$/){
	 my  $id_of_existing_row = $self->get_object_row()->update()->insert()->discard_change();
	    $self->set_row($id_of_existing_row);
	    print"Updateing SNP!\n";
	}else{
	    croak("Dosn't exist in the database");
	}
    }
    return $self->get_snp_id();
}

=head2 exists in database

  Usage: $self->exixtes_in_database
  Desc:  $check if the snp_id exists in the snp table
  Ret:   Database id or undef 
  Args:  none
  Side Effects: none
  Example:

=cut
sub exists_in_database{
    my $self = shift;
    #retriving a single row 
    my $snp = $self->get_resultset('Snp')->search(
	{snp_id =>{'ilike'=>$self->get_snp_id()}
	
	}                                         )->single();
    return $snp->get_snp_id() if $snp;
    return undef;
}

=head2 accessors object_row

 Usage:my row_object = $self->get_object_row();
       $self->set_object_row($self->get_schema->resultset($source)->new({})
 Desc: Get/Set a result set object into a snp_object 
 Ret:  a row object, a schema object(CXGN::Marker::SNP::Schema::Snp).
 Args: Get=>none
       Set=>a new row object, a schema object(CXGN::Marker::SNP::Schema::Snp)
 Side Effects:
 Example: my $row_obje = $self->get_object_row();
          $self->set_object_row($row_obje);

=cut
sub get_object_row{
    my $self = shift;
    return $self->{object_row};
}

sub set_object_row{
    my $self = shift;
    my $obj_row = shift || croak ("FUNCTION PARAMETER ERROR: undefined row object value");
    if (ref($obj_row) ne 'CXGN::Marker::SNP::Schema::Snp'){
	croak("SET_METADATA_ROW ARGUMENT ERROR: The obiect is not a row object");
    }

    $self->{object_row} = $obj_row;
}

=head2 get_resultset

 Usage:$self->getresultset(ModuleName::TableName)
 Desc: Get a ResultSet object for source_name
 Ret:  a ResultSet object
 Args: Get=> a source name
       Set=> none 
 Side Effects: none
 Example:

=cut
sub get_resultset{
    my $self = shift;
    my $source = shift || croak("FUNCTION PARAMETER ERROR: unknown source value");
    return $self->get_schema()->resultset("$source");
}

=head2 accessors snp_id

 Usage:my $snp_id = $snp->get_snp_id();
       $snp->set_snp_id($snp_id);
 Desc: Get/set a snp_id in snp object. 
 Ret:  Get=>$snp_id, a scaler
       Set=>none
 Args: Get=>none 
       Set=>$snp_id,a scaler(constraint: it must be an integer) 
 Side Effects: none
 Example: my $snp_id = $snp->get_snp_id();

=cut
sub get_snp_id{
    my $self = shift;
    return $self->get_object_row()->get_column('snp_id');
}

sub set_snp_id{
    my $self   = shift;
    my $snp_id = shift || croak("FUNCTION PARAMETER ERROR: undifined SNP ID value") ;
    if ($snp_id =~ m/^\d+$/){
	my $new_row_obje = $self->get_object_row();
        $new_row_obje->set_column(snp_id => $snp_id);
	$self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The snp_id ($snp_id) for CXGN::Marker::SNP::Snp->set_snp_id()IS NOT AN INTEGER");
    }  
   
}
=head2 accessors unigene_id

 Usage:my $unigene_id = $snp->get_unigene_id();
       $snp->set_unigene_id($unigene_id);
 Desc: Get/Set a unigene_id in snp object. 
 Ret:  Get=>$unigene_id, a scaler
       Set=>none
 Args: Get=>none 
       Set=>$unigene_id,a scaler(constraint: it must be an integer) 
 Side Effects: none
 Example: my $unigene_id = $snp->get_unigene_id();

=cut
sub get_unigene_id{
    my $self = shift;
    return $self->get_object_row()->get_column('unigene_id');
}

sub set_unigene_id{
    my $self = shift;
    my $unigene_id = shift || croak("FUNCTION PARAMETER ERROR: undefined unigene id value");
    if($unigene_id =~ m/^\d+$/){
	my $new_unigene_id = $self->get_object_row();
        $new_unigene_id->set_column(unigene_id => $unigene_id);
	$self->set_object_row($new_unigene_id);
    }else{
	croak("DATA TYPE ERROR: The unigene_id ($unigene_id) for CXGN::Marker::SNP::Snp->set_unigene_id() IS NOT AN INTEGER");
    }

}
=head2 accessors unigene_position

 Usage:my $unigene_position = $snp->get_reference_position();
       $snp->set_unigene_position($unigene_position);
 Desc: Get/Set a unigene_position in Snp object.
 Ret:  Get=>unigene_position, a scalar
       Set=>none
 Args: Get=>none
       Set=>$unigene_position, a scalar(constraint: it must be an integer) 
 Side Effects: none
 Example: my $position = $snp->get_unigene_position();

=cut
sub get_unigene_position{
    my $self = shift;
    return $self->get_object_row()->get_column('unigene_position');
}

sub set_unigene_position{
    my $self = shift;
    my $unigene_position = shift || croak("FUNCTION PARAMETER ERROR: undifined unigene position value");
    if ($unigene_position =~ m/^\d+$/){
	my $new_row_obje = $self->get_object_row();
        $new_row_obje->set_column(unigene_position => $unigene_position);
	$self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The unigene_positionios ($unigene_position) for CXGN::Markers::SNP::Snp->set_unigene_position() IS NOT AN INTEGER");
    }     
}
=head2 accessors region

 Usage:my $region = $snp->get_reference_position();
       $snp->set_region($region);
 Desc: Get/Set a region in Snp object.
 Ret:  Get=>region, a scalar
       Set=>none
 Args: Get=>none
       Set=>$region, a scalar(constraint: it must be an integer) 
 Side Effects: none
 Example: my $region = $snp->get_unigene_position();

=cut
sub get_region{
    my $self = shift;
    return $self->get_object_row()->get_column('region');
}

sub set_region{
    my $self = shift;
    my $region = shift || croak("FUNCTION PARAMETER ERROR: undefind neucleotide region value");
 #WE CAN MORE RESTRICT THIS METHOD BY ADDING MORE IF AND ELSE FOR 5',3' AND CDS


  #  if ($region =~ m/^\w+$/){
  #     my $new_row_obje = $self->get_object_row();
  #	$new_row_obje->set_column(region => $region);
  #    $self->set_object_row($new_row_obje);
  # }
 
    if ($region =~ m/.*$/){
        my $new_row_obje = $self->get_object_row();
	$new_row_obje->set_column(region => $region);
        $self->set_object_row($new_row_obje);

    }else {
	croak("DATA TYPE ERROR: The neuclotied region ($region) for CXGN::Markers::SNP::Snp->set_region() IS NOT A CHARACTER, 5' or 3' WRONG DATA TYPE ");
    } 
   

}

=head2 accessors primer_left_id

 Usage:my $reference_position = $snp->get_reference_position();
       $snp->set_reference_position($reference_position);
 Desc: Get/Set a reference_position in Snp object.
 Ret:  Get=>$primer_left_id, a scalar
       Set=>none
 Args: Get=>none
       Set=>$primer_left_id, a scalar(constraint: it must be an integer) 
 Side Effects: none
 Example: my $primer_left_id = $snp->get_primer_left_id();

=cut
sub get_primer_left_id{
    my $self = shift;
    return $self->get_object_row()->get_column('primer_left_id');
}

sub set_primer_left_id{
    my $self = shift;
    my $primer_left_id = shift || croak("FUNCTION PARAMETER ERROR:undefined primer left id value");
    if ($primer_left_id =~ m/^\d+$/){
	my $new_row_obje= $self->get_object_row();
	$new_row_obje->set_column(primer_left_id => $primer_left_id);
	$self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The primer_left_id ($primer_left_id) for CXGN::Marker::SNP::Snp->set_primer_left_id() IS NOT AN INTEGER");
    }    
}

=head2 accessor primer right id

 Usage:my $primer_right_id = $snp->get_primer_right_id();
       $snp->set_primer_right_id($primer_right_id)
 Desc: Get/Set a primer_right_id in Snp table 
 Ret:  Get=>returns primer_right_id , scaler
       Set=>none
 Args: Get=>none 
       Set=>primery_right_id to be seted , a scalar(constraint: it must be an integer) 
 Side Effects:
 Example:

=cut
sub get_primer_right_id{
    my $self = shift;
    return $self->get_object_row()->get_column('primer_left_id');
}

sub set_primer_right_id{
    my $self = shift;
    my $primer_right_id = shift || croak("FUNCTION PARAMETER ERROR: undefined primer right id value");
    if ($primer_right_id =~ m/^\d+$/){
	my $new_row_obje = $self->get_object_row();
        $new_row_obje->set_column(primer_right_id => $primer_right_id);
	$self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The primer_right_id ($primer_right_id) for CXGN::Marker::SNP::Snp->set_primer_right_id() IS NOT AN INTEGER");
    }
   
}

=head2 accessor accession id

 Usage:my $accesion_id = $snp->get_reference_accession_id();
       $snp->set_reference_accession_id($accesion_id)
 Desc: Get/Set a reference_accession_id in Snp table 
 Ret:  Get=>returns reference_accession_id, scalar 
       Set=> none
 Args: Get=>none
       Set=>reference_accession_id to be seted, a scaler(constraint: it must be an integer)
 Side Effects: none
 Example:

=cut
sub get_accession_id{
    my $self = shift;
    return $self->get_object_row()->get_column('accession_id');
}

sub set_accession_id{
    my $self = shift;
    my $accession_id = shift || croak ("FNCTION PARAMETER ERROR: undefined reference accession id value");
    if ($accession_id =~ m/^\d+$/){
	my $new_row_obje = $self->get_object_row();
	$new_row_obje->set_column(accession_id => $accession_id);
	$self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The accession id($accession_id) for CXGN::Marker::SNP::Snp->set_accession_ide() IS NOT AN INTEGER");
    }
   
}

=head2 accessor snp accession id

 Usage:my accession_id = $snp->get_snp_accession_id();
       $self->set_snp_accession_id($accession_id)
 Desc: Get/Set a snp_accession_id in Snp table 
 Ret:  Get/returns snp_accession_id, $scalar
       Set/none
 Args: Get/none 
       Set/snp_accession_id to be seted, a scalar(constraints: it must be an integer)
 Side Effects: none
 Example:

=cut
sub get_snp_accession_id{
    my $self = shift;
    return $self->get_object_row()->get_column('snp_accession_id');
}

sub set_snp_accession_id{
    my $self = shift;
    my $snp_accession_id = shift || croak("FUNCTION PARAMETER ERROR: undefined snp accession id value");
    if ($snp_accession_id =~ m/^\d+$/){
	$self->get_object_row()->set_column(snp_accession_id => $snp_accession_id);	
    }else{
	croak("The snp_accession_id is not an integer");
    }
   
}
=head2 accessor reference nucleotied

 Usage:my $refeence_nucleotied = $snp->get_reference_nucleotied();
       $snp->set_reference_nucleotied($reference_nucleotied)
 Desc: Get/Set a reference_neucleotied in Snp table 
 Ret:  Get/returns reference_neucleotied, scalar
       Set/none
 Args: Get/none
       Set/reference_neucleotied to be seted, a scalar(constraints: it must be a chatacter)
 Side Effects: none
 Example:

=cut
sub get_reference_nucleotide{
    my $self = shift;
    return $self->get_object_row()->get_column('reference_nucleotide');
}

sub set_reference_nucleotide{
    my $self = shift;
    my $reference_nucleotide = shift || croak("FUNCTION PARAMETER ERROR: undifined reference nucleotide value");
    if ($reference_nucleotide =~ m/^\w$/){
	my $new_row_obje = $self->get_object_row();
	$new_row_obje->set_column(reference_nucleotide => $reference_nucleotide);
	$self->set_object_row($new_row_obje);
    }else {
	croak ("The reference nucleotide is not a character");
    }     
}

=head2 accessor snp nuleotied

 Usage:my $snp_nucleotied = $snp->get_snp_nucleotied();
       $snp->set_snp_nucleotied($snp_nucleotied);
 Desc: get/set a snp_neucleotied in Snp table 
 Ret:  Get=>returns snp_neucleotied, scaler
       Set=> none
 Args: Get=>none 
       Set=>snp_neucleotied to be seted,  a scalar(constraint: it must be a character) 
 Side Effects: none
 Example:

=cut
sub get_snp_nucleotide{
    my $self = shift;
    return $self->get_object_row()->get_column('snp_nucleotide');
}

sub set_snp_nucleotide{
    my $self = shift;
    my $snp_nucleotide = shift || croak("FUNCTION PARAMETER ERROR: undefind snp nucleotide value");
    if ($snp_nucleotide =~ m/^\w$/){
	my $new_row_obje = $self->get_object_row();
	$new_row_obje->set_column(snp_nucleotide => $snp_nucleotide);
        $self->set_object_row($new_row_obje);
    }else {
	croak("DATA TYPE ERROR: The snp_nucleotied ($snp_nucleotide) for CXGN::Markers::SNP::Snp->set_snp_nucleotied() IS NOT AN INTEGER");
    } 
   
}

=head2 accessor snp person id

 Usage:my $person_id = $snp->get_snp_person_id();
       $snp->set_snp_person_id($person_id);
 Desc: get/set a snp_person_id in Snp table 
 Ret:  Get=>returns snp_person_id, scaler
       Set=> none
 Args: Get=>none
       Set=>snp_person_id to be seted, a scalar(constraint: it must be an integer) 
 Side Effects: none
 Example:

=cut
sub get_sp_person_id{
    my $self = shift;
    return $self->get_object_row()->get_column('sp_person_id');
}

sub set_sp_person_id{
    my $self = shift;
    my $sp_person_id = shift || croak("FUNCTION PARAMETER ERROR: undefind snp person id value");
    if ($sp_person_id =~ m/^\d+$/){
	my $new_obje_row = $self->get_object_row();
        $new_obje_row->set_column(sp_person_id => $sp_person_id);
        $self ->set_object_row($new_obje_row);	
    }else{
	croak("DATA TYPE ERROR: The sp_person_id ($sp_person_id) for CXGN::Marker::SNP::Snp->set_sp_person_id() IS NOT AN INTEGER");
    }
   
}
=head2 accessor mqs

 Usage:my $mqs = $snp->get_mqs();
       $snp->set_mqs($mqs);
 Desc: get/set mns in Snp table 
 Ret:  Get=>returns mqs, scalar
       Set=> none
 Args: get=> none 
       Set=> mqs to be seted, scalar(constraints: it must be an integer)
 Side Effects: none
 Example: my $mqs = $snp->get_mqs();

=cut
sub get_mqs{
    my $self = shift;
    return $self->get_object_row()->get_column('mqs');

}
sub set_mqs{
    my $self = shift;
    my $mqs = shift || croak("FUNCTION PARAMETER ERROR: undefind mqs value");
    if($mqs =~ m/^\d+$/){
	my $new_obje_row = $self->get_object_row();
	$new_obje_row->set_column(mqs => $mqs);
	$self->set_object_row($new_obje_row);
    }else{
	croak("DATA TYPE ERROR: The mqs($mqs) for CXGN::Marker::SNP::Snp->set_mqs() IS NOT AN INTEGER");
    }
}
=head2 accessor mns

 Usage:my $mns = $snp->get_mns();
       $snp->set_mns($mns);
 Desc: get/set mns in Snp table 
 Ret:  Get=>returns mns, scalar
       Set=> none
 Args: get=>none 
       Set=> mns to be seted, scalar(constraints: it must be an integer)
 Side Effects: none
 Example: my $mns = $snp->get_mns();

=cut
sub get_mns{
    my $self = shift;
    return $self->get_object_row()->get_column('mns');
}
sub set_mns{
    my $self = shift;
    my $mns = shift || croak("FUNCTION PARAMETER ERROR: undefind mns value");
    if($mns =~ m/^\d+$/){
	my $new_obje_row = $self->get_object_row();
	$new_obje_row->set_column(mns => $mns);
	$self->set_object_row($new_obje_row);
    }else{
	croak("DATA TYPE ERROR: The mns($mns) for CXGN::Marker::SNP::Snp->set_mns() IS NOT AN INTEGER");
    }
}

=head2 accessor confirmed

 Usage:$confirmed = $snp->get_confirmed();
       $snp->set_confirmed($confirmed);
 Desc: get/set confirmesd in Snp table 
 Ret:  Get=>returns confirmed (yes/no), scalar
       Set=> none
 Args: get=>none 
       Set=> confirmed to be seted, scalar
 Side Effects: none
 Example: my $confirmed = $snp->get_confirmed();

=cut
sub get_confirmed{
    my $self = shift;
    return $self->get_object_row()->get_column('confirmed');
}

sub set_confirmed{
    my $self = shift;
    my $confirmed = shift || croak("FUNCTION PARAMETER ERROR: undefind confirmed value ");
    if($confirmed =~ m/^\w+$/){
	my $new_row_obje = $self->get_object_row();
	$new_row_obje ->set_column(confirmed => $confirmed);
	$self->set_object_row($new_row_obje);
    }else{
	croak("DATA TYPE ERROR: The confirmed ($confirmed) for CXGN::Marker::SNP::Snp->set_confirmed() IS NOT AN INTEGER");
    }
}

=head2 accessor modified date

 Usage:$modified_date = $snp->get_modified_date();
       $snp->set_modified_date($modified_date);
 Desc: get/set a obsolet in Snp table 
 Ret:  Get=>returns modified_date, scalar
       Set=> none
 Args: get=>none 
       Set=> a modified date date to be seted, scalar
 Side Effects: none
 Example: my $modified_date=$$snp->get_modified_date();

=cut
sub get_modified_date{
    my $self = shift;
    return $self->get_object_row()->get_column('modified_date');
}

sub set_modified_date{
    my $self = shift;
    my $modified_date = shift || croak("FUNCTION PARAMETER ERROR: undefind modified_date value");
    my $new_row_obje =  $self->get_object_row();
    $new_row_obje->set_column(modified_date => $modified_date);
    $self->set_object_row($new_row_obje);
}

=head2 accessor create date

 Usage:$my new_date = $snp->get_create_date();
       $snp->set_create_date($my_new_date)
 Desc: get/set a obsolet in Snp table 
 Ret:  Get=>returns create_date 
       Set=>none
 Args: Get=>none 
       Set=>a new date to be seted 
 Side Effects: none
 Example:

=cut
sub get_create_date{
    my $self = shift;
    return $self->get_object_row()->get_column('create_date');
}

sub set_create_date{
    my $self = shift;
    my $create_date = shift || croak("FUNCTION PARAMETER ERROR: undefind create_date value");
    my $new_row_obje = $self->get_object_row();
    $new_row_obje->set_column(create_date => $create_date);
    $self->set_object_row($new_row_obje);
}

=head2 accessor obsolete

 Usage:my $obsolete = $snp->get_obsolete();
       $snp->set_obsolete($obsolete)
 Desc: Get/Set a obsolet in Snp table 
 Ret:  Get/returns obsolete 
       Set/none
 Args: Get/none 
       Set/ obsolete to be seted 
 Side Effects: none
 Example:

=cut
sub get_obsolete{
    my $self = shift;
    return $self->get_object_row()->get_column('obsolete');
}

sub set_obsolete{
    my $self = shift;
    my $obsolete = shift || croak("FUNCTION PARAMETER ERROR: undefind obsolete value");
    if($obsolete eq 'true' && $obsolete eq 'false'){
	croak("DATA TYPE ERROR: The obsolete ($obsolete) for CXGN::SNP::snp->set_obsolete() HAS DIFFERENT VALUE FROM true OR false.\n\n");

    }else{
	my $new_row_obje = $self->get_object_row();
        $new_row_obje->set_column(obsolete => $obsolete);
	$self->set_object_row($new_row_obje);
    }
}

#########
return 1#
#########
  
