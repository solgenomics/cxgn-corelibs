
=head1 NAME

CXGN::Marker::PCR::Product

=head1 DESCRIPTION

This class encapsulates the pcr_product and pcr_exp_accession tables. 

PCR experiments can be retrieved from an CXGN::Marker::PCR::Experiment using the get_pcr_products() and get_digest_products() functions. pcr_products retrieves the products of undigested PCR experiments, while get_pcr_products() retrieves the sizes of digested bands and the corresponding enzyme.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 FUNCTIONS

This class implements the following member functions: 

=cut

use strict;

package CXGN::Marker::PCR::Product;


use CXGN::DB::Object;

use base qw | CXGN::DB::Object | ;

=head2 new

 Usage:        Constructor
 Desc:         takes a database handle and product_id as parameters
 Ret:          a CXGN::Marker::PCR::Product object
 Args:         a DBI and an int
 Side Effects:
 Example:

=cut


sub new { 
    my $class =shift;
    my $dbh = shift;
    my $id = shift;

    my $self = $class -> SUPER::new($dbh);
    
    if ($id) { 
	$self->set_pcr_product_id($id);
	$self->fetch();
    }
    return $self;

}

sub fetch { 
    my $self = shift;
    
    my $q = "SELECT pcr_product_id, pcr_product.pcr_exp_accession_id, enzyme_id, multiple_flag, band_size, predicted, pcr_exp_accession.accession_id, pcr_exp_accession.pcr_experiment_id FROM sgn.pcr_product JOIN sgn.pcr_exp_accession using(pcr_exp_accession_id) where pcr_product_id=?";
    my $h = $self->get_dbh()->prepare($q);
    $h->execute($self->get_pcr_product_id());

    while (my ($pcr_product_id, $pcr_exp_accession_id, $enzyme_id, $multiple_flag, $band_size, $predicted, $accession_id, $pcr_experiment_id ) = $h->fetchrow_array()) { 
	$self->set_pcr_product_id($pcr_product_id);
	$self->set_pcr_exp_accession_id($pcr_exp_accession_id);
	$self->set_enzyme_id($enzyme_id);
	$self->set_multiple_flag($multiple_flag);
	$self->set_band_size($band_size);
	$self->set_predicted($predicted);
	$self->set_accession_id($accession_id);
	$self->set_experiment_id($pcr_experiment_id);
    }
}

=head2 store

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store {
    my $self = shift;

    if (!$self->get_pcr_exp_accession_id()) { 
	my $s = "SELECT pcr_exp_accession_id FROM sgn.pcr_exp_accession WHERE accession_id=? and pcr_experiment_id=?";
	my $sh = $self->get_dbh()->prepare($s);
	$sh->execute($self->get_accession_id(), $self->get_experiment_id());
	my ($pcr_exp_accession_id) = $sh->fetchrow_array();
	$self->set_pcr_exp_accession_id($pcr_exp_accession_id);

	if (!$pcr_exp_accession_id) { 
	    my $q = "INSERT INTO sgn.pcr_exp_accession (accession_id, pcr_experiment_id) VALUES (?, ?)";
	    my $h = $self->get_dbh()->prepare($q);
	    print STDERR "ACCESSION: ".$self->get_accession_id()."   experiment_id: ".$self->get_experiment_id()."\n";
	    $h->execute($self->get_accession_id(), $self->get_experiment_id());
	    my $pcr_exp_accession_id = $self->get_dbh()->last_insert_id("pcr_exp_accession", "sgn");
	    $self->set_pcr_exp_accession_id($pcr_exp_accession_id);
	}
    }
    if ($self->get_pcr_product_id()) { 
	my $q = "UPDATE sgn.pcr_product SET pcr_exp_accession_id=?, enzyme_id=?, multiple_flag=?, band_size=?, predicted=? WHERE pcr_product_id=?";
	my $h = $self->get_dbh()->prepare($q);
	$h->execute(
		    $self->get_pcr_exp_accession_id(),
		    $self->get_enzyme_id(),
		    $self->get_multiple_flag(),
		    $self->get_band_size(),
		    $self->get_predicted(),
		    $self->get_pcr_product_id(),
		    );

	return $self->get_pcr_product_id();
    }
    else { 
	my $q = "INSERT INTO sgn.pcr_product (pcr_exp_accession_id, enzyme_id, multiple_flag, band_size, predicted) VALUES (?, ?, ?, ?, ?)";
	my $h = $self->get_dbh()->prepare($q);
	$h->execute(
		    $self->get_pcr_exp_accession_id(),
		    $self->get_enzyme_id(),
		    $self->get_multiple_flag(),
		    $self->get_band_size(),
		    $self->get_predicted()
		    );
	
	my $id = $self->get_dbh()->last_insert_id("pcr_product", "sgn");
	$self->set_pcr_product_id($id);
	return $id;
    }
}



=head2 accessors get_pcr_product_id, set_pcr_product_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_pcr_product_id {
  my $self = shift;
  return $self->{pcr_product_id}; 
}

sub set_pcr_product_id {
  my $self = shift;
  $self->{pcr_product_id} = shift;
}

=head2 accessors get_pcr_exp_accession_id, set_pcr_exp_accession_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_pcr_exp_accession_id {
  my $self = shift;
  return $self->{pcr_exp_accession_id}; 
}

sub set_pcr_exp_accession_id {
  my $self = shift;
  $self->{pcr_exp_accession_id} = shift;
}

=head2 accessors get_enzyme_id, set_enzyme_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_enzyme_id {
  my $self = shift;
  return $self->{enzyme_id}; 
}

sub set_enzyme_id {
  my $self = shift;
  $self->{enzyme_id} = shift;
}

=head2 get_enzyme_name(), set_enzyme_name()

 Usage:        $enzyme_name = $product->get_enzyme_name()
 Desc:         as an alternative to get_enzyme_id(), retrieves
               the name
 Ret:          a string
 Args:         none
 Side Effects: queries the database for enzyme name on the fly
 Example:

=cut

sub get_enzyme_name {
    my $self = shift;
    my $q = "SELECT enzyme_name FROM sgn.enzymes WHERE enzyme_id = ? ";
    my $h = $self->get_dbh()->prepare($q);
    $h->execute($self->get_enzyme_id());
    my ($enzyme_name) = $h->fetchrow_array();
    return $enzyme_name;
}

sub set_enzyme_name { 
    my $self = shift;
    my $name = shift;
    my $q = "SELECT enzyme_id FROM sgn.enzymes WHERE enzyme_name ilike ?";
    my $h = $self->get_dbh()->prepare($q);
    $h->execute($name);
    my ($enzyme_id) = $h->fetchrow_array();
    if (!$enzyme_id) { die "Enzyme with name '$name' does not exist!\n"; }
    $self->set_enzyme_id($enzyme_id);
}
		       



=head2 accessors get_multiple_flag, set_multiple_flag

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_multiple_flag {
  my $self = shift;
  return $self->{multiple_flag}; 
}

sub set_multiple_flag {
  my $self = shift;
  $self->{multiple_flag} = shift;
}
    
=head2 accessors get_band_size, set_band_size

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_band_size {
  my $self = shift;
  return $self->{band_size}; 
}

sub set_band_size {
  my $self = shift;
  $self->{band_size} = shift;
}

=head2 accessors get_predicted, set_predicted

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_predicted {
  my $self = shift;
  return $self->{predicted}; 
}

sub set_predicted {
  my $self = shift;
  $self->{predicted} = shift;
}
    
=head2 accessors get_accession_id, set_accession_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_accession_id {
  my $self = shift;
  return $self->{accession_id}; 
}

sub set_accession_id {
  my $self = shift;
  $self->{accession_id} = shift;
}



=head2 accessors get_accession_name, set_accession_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_accession_name {
  my $self = shift;
  my $q = "SELECT accession_name FROM sgn.accession_names WHERE accession_id = ?";
  my $h = $self->get_dbh()->prepare($q);
  $h->execute($self->get_accession_id);
  my ($accession_name) = $h->fetchrow_array();
  return $accession_name;
}

sub set_accession_name {
  my $self = shift;
  my $name = shift;
  my $q = "SELECT accession_id FROM sgn.accession_names WHERE accession_name = ?";
  my $h = $self->get_dbh()->prepare($q);
  $h->execute($name);
  my ($accession_id) = $h->fetchrow_array();
  if (!$accession_id) { print STDERR "Warning: accession '$name' cannot be found in the database!\n"; }
  $self->set_accession_id($accession_id);
}


=head2 accessors get_experiment_id, set_experiment_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_experiment_id {
  my $self = shift;
  return $self->{experiment_id}; 
}

sub set_experiment_id {
  my $self = shift;
  $self->{experiment_id} = shift;
}
 

=head2 delete

 Usage:        $pcr_product->delete();
 Desc:         removes the pcr_product information from the
               database
 Ret:          nothing
 Args:         none
 Side Effects: the information in the database is hard-deleted.
               ...so be careful!
 Example:

=cut

sub delete {
    my $self = shift;
    if ($self->get_pcr_product_id()) { 
	my $q = "DELETE FROM sgn.pcr_product WHERE pcr_product_id=?";
	my $h = $self->{dbh}->prepare($q);
	$h->execute($self->get_pcr_product_id()); 
    }
    else { 
	print STDERR "This pcr product object has never been stored, cannot delete.\n";
    }
}


=head2 exists_pcr_product

 Usage:        CXGN::Marker::PCR::Product->exists_pcr_product($dbh, $accession_name, $enzyme_name, $size)
 Desc:         
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub exists_pcr_product {
    my $dbh = shift;
    my $accession_name = shift;
    my $enzyme_name = shift;
    my $size = shift;

    my $q = "SELECT pcr_product_id FROM sgn.pcr_product JOIN sgn.accession_names using(accession_id) JOIN enzymes USING(enzyme_id) WHERE enzyme_name =? AND accession_name = ?";
    my $h = $dbh->prepare($q);
    $h->execute($enzyme_name, $accession_name);
    my $products = $h->fetchall_arrayref();
    if (@$products == 1) { return $products->[0]; }
    elsif (!@$products) { 
	return undef;
    }
    else {
	die "pcr product with size $size for accession $accession_name and enzyme $enzyme_name is duplicated!!!!!! Please fix!\n";
    }    
}



return 1;
