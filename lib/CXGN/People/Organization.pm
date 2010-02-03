=head1 NAME

People -- classes to deal with community data, login, user comments etc
          for the SGN website.

=head1 SYNOPSIS

 my $o = CXGN::People::Organization->new($dbh);

=head1 AUTHORS

Lukas Mueller, John Binns, Robert Buels.
Copyleft (c) SOL Genomics Network. All rights reversed.

=cut

=head1 Package CXGN::People::Organization

Class that deals with organizations. 

=cut

package CXGN::People::Organization;

use strict;

use base qw |  CXGN::People::Login |;

sub new {
    my $class           = shift;
    my $dbh             = shift;
    my $organization_id = shift;

    my $self            = $class->SUPER::new($dbh);    
    $self->set_sql();

    if ($organization_id) { $self->fetch($organization_id); }
    return $self;
}

sub fetch {

    my ( $self, $org_id ) = @_;
    my $sth = $self->get_sql('fetch');
    $sth->execute($org_id);

    my $hashref = $sth->fetchrow_hashref();
    foreach my $k ( keys(%$hashref) ) {
        $self->{$k} = $$hashref{$k};
    }
}

sub store {
    my $self = shift;
    #not implemented
    die 'not implemented';
}

sub get_sp_organization_id {
    my $self = shift;
    return $self->{sp_organization_id};
}

sub get_name {
    my $self = shift;
    $self->fetch();
    return $self->{name};
}

sub set_name {
    my $self = shift;
    $self->{name} = shift;
}

sub get_department {
    my $self = shift;
    return $self->{department};
}

sub set_department {
    my $self = shift;
    $self->{department} = shift;
}

sub get_unit {
    my $self = shift;
    return $self->{unit};
}

sub set_unit {
    my $self = shift;
    $self->{unit} = shift;
}

sub get_address {
    my $self = shift;
    return $self->{address};
}

sub set_address {
    my $self = shift;
    $self->{address} = shift;
}

sub get_country {
    my $self = shift;
    return $self->{country};
}

sub set_country {
    my $self = shift;
    $self->{country} = shift;
}

sub get_upload_account_name {
    my $self = shift;
    return $self->{upload_account_name};
}

sub set_upload_account_name {
    my $self = shift;
    $self->{upload_account_name} = shift;
}

sub get_phone_number {
    my $self = shift;
    return $self->{phone_number};
}

sub set_phone_number {
    my $self = shift;
    $self->{phone_number} = shift;
}

sub get_fax {
    my $self = shift;
    return $self->{fax};
}

sub set_fax {
    my $self = shift;
    $self->{fax} = shift;
}

sub get_contact_email {
    my $self = shift;
    return $self->{contact_email};
}

sub set_contact_email {
    my $self = shift;
    $self->{contact_email} = shift;
}

sub get_description {
    my $self = shift;
    return $self->{description};
}

sub set_description {
    my $self = shift;
    $self->{description} = shift;
}

sub get_shortname {
    my $self = shift;
    return $self->{shortname};
}

sub set_shortname {
    my $self = shift;
    $self->{shortname} = shift;
}

sub get_webpage {
    my $self = shift;
    return $self->{webpage};
}

sub set_webpage {
    my $self = shift;
    $self->{webpage} = shift;
}

sub set_sql { 
    my $self = shift;
    $self->{queries} = { "fetch" => "
		SELECT 
			sp_organization_id, name, department, unit, 
			address, country, phone_number, 
			fax, contact_email, webpage, 
			upload_account_name, shortname 
		FROM 
			sp_organization 
		WHERE 
			sp_organization_id=?"
    };

    foreach my $k (%{$self->{queries}}) { 
	$self->{query_handles}->{$k}=$self->get_dbh()->prepare($self->{queries}->{$k});
    }
}

sub get_sql { 
    my $self = shift;
    my $name = shift;
    return $self->{query_handles}->{$name};
}



###
1;#do not remove
###
