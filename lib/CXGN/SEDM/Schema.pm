=head1 NAME

CXGN::SEDM::Schema.

Version:1.0

=head1 DESCRIPTION

 This class was created by DBIx::Class::Schema::Loader v0.03009 @ 2009-05-06 16:33:22

=head1 AUTHOR

Aureliano Bombarely <ab782@cornell.edu>


=head1 ADDITIONAL METHODS


=cut 


package CXGN::SEDM::Schema;

# Created

use strict;
use warnings;
use Carp;

use Module::Find;
use Bio::Chado::Schema;
use base 'DBIx::Class::Schema';


### Testing the use of other schemas

my (@sedm_classes, @chado_classes);
my @sedm_modules = findallmod 'CXGN::SEDM::Schema';
foreach my $sedm_module (@sedm_modules) {
   $sedm_module =~ s/CXGN::SEDM::Schema:://;
   push @sedm_classes, $sedm_module;
}
my @chado_modules = findallmod 'Bio::Chado::Schema';
foreach my $chado_module (@chado_modules) {
   $chado_module =~ s/Bio::Chado::Schema:://;
   push @chado_classes, $chado_module;
}

#print "\n@sedm_classes\n\n@chado_classes\n";


## __PACKAGE__->load_classes(@sedm_classes, { 'Bio::Chado::Schema' => [@chado_classes]}); #(to use in a future)
__PACKAGE__->load_classes();


#__PACKAGE__->source('SampleDbxref')->add_relationship( 'dbxref', 
#                                                       "Bio::Chado::Schema::General::Dbxref", 
#                                                       { 'foreign.dbxref_id' => 'self.dbxref_id' },);

=head2 get_last_primary_keys

  Usage: my @last_primary_keys = $self->get_last_primary_keys($tablename);
  Desc: Get the last primary id
  Ret: An array, the last primary id. If return 0 is that the table is not populated
  Args: $tablename, the name of the table
  Side_Effects: Return 0 if the table is empty
  Example: my ($last_platform_id) = $platform->get_last_primary_keys('platform')

=cut

sub get_last_primary_keys {
    my $self = shift;
    my $tablename = shift || 
	croak("DATA ARGUMENT ERROR: None tablename argument was supplied to the CXGN::SEDM::Schema->get_last_primary_keys method\n");
    my @last_values_for_primary_keys;
    my @resultsetname;
    if ($tablename =~ m/_/) {
	@resultsetname = split (/_/, $tablename);
    } else {
	push @resultsetname, $tablename;
    }
    my @source;
    foreach my $element (@resultsetname) {
	push @source, ucfirst($element);
    }
    my $source = join('', @source);
    my @primary_keys = $self->source($source)->primary_columns();
    foreach my $primary_key (@primary_keys) {
	my $order_by_name = $primary_key . ' DESC';
	my ($last_row) = $self->resultset($source)->search( undef, { order_by => $order_by_name, 
								     rows     => 1
								   } );
	my $last_primary_id;
	if (defined $last_row) {
	    ($last_primary_id) = $last_row->get_column($primary_key);
	} else {
	    $last_primary_id = 0;
	}
	push @last_values_for_primary_keys, $last_primary_id;
    }
    return @last_values_for_primary_keys;
}
=head2 exists_data

 Usage: $class->exist_data($table, $column, $data);
 Desc: This method check if exists or not a concrete data in a concrete table
 Ret: 0 for false and 1 for true
 Args: $table, a scalar, table name;
       $colum, a scalar, the name of the column
       $data, a scalar, data to check
 Side Effects: None
 Example: CXGN::SEDM::Schema->exists_data('platforms', 'platform_id', 1);

=cut

sub exists_data {
    my $self = shift;
    my $table = shift;
    my $column = shift;
    my $data = shift;

    unless (defined $table) {
	return 0;
    } else {
	my @source_names = $self->sources();
	my $match = 0;
	foreach my $source (@source_names) {
	    if ($source eq $table) {
		$match = 1;
	    }
	}
	if ($match == 0) {
	    return 0;
	} else {
	    unless (defined $column) {
		return 0;
	    } else {
		my $source_name;
		my @source_name = split(/_/, $table);
		foreach my $subsource_name (@source_name) {
		    $source_name .= ucfirst($subsource_name);
		}
		unless ( $self->source($source_name)->has_column($column) ) {
		    return 0;
		} else {
		    unless ( defined($self->resultset($source_name)->search( $column => $data)) ) {
			return 0;
		    } else {
			return 1;
		    }
		}
	    }
	}
    }
}




1;

