package CXGN::Tools::Wget::ResourceFile;
use strict;
use warnings;

use Carp qw/ cluck confess croak / ;
use File::Temp qw/ tempfile /;

use CXGN::Tools::Run;
use CXGN::Tools::Wget::ResourceExpression;

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('resource_file');
__PACKAGE__->columns(All => qw/ resource_file_id name expression /);

# the SQL table definition is here just for reference
my $creation_statement = <<EOSQL;

create table resource_file (
   resource_file_id serial primary key,
   name varchar(40) not null unique,
   expression text not null
);

comment on table resource_file is
'each row defines a composite dataset, downloadable at the url cxgn-resource://name, that is composed of other downloadable datasets, according to the expression column.  See CXGN::Tools::Wget for the accompanying code'
;

EOSQL

=head2 fetch

  Usage: $resourcefile->fetch( $destination_file );
  Desc : assemble this composite resource file from its components
  Args : filename in which to store the complete
         assembled file
  Ret  : full path to the complete assembled file

=cut

sub fetch {
  my ( $self, $destfile ) = @_;

  return CXGN::Tools::Wget::ResourceExpression::fetch_expression( $self->expression, $destfile );
}

=head2 test_fetch()

  Usage: $resourcefile->test_fetch()
  Desc : just test this resource and its components, see
         if they are all fetchable
  Args : none
  Ret  : true if successful, false if not
  Side Effects: dies with an error if fetch was unsuccessful

=cut

sub test_fetch {
  my ( $self ) = @_;
  return CXGN::Tools::Wget::ResourceExpression::test_fetch_expression( $self->expression );
}


=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
