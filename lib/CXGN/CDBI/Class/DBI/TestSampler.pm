package CXGN::CDBI::Class::DBI::TestSampler;

=head1 NAME

    CXGN::CDBI::Class::DBI::TestSampler - little thing to help test individual
                                   classes based on L<CXGN::CDBI::Class::DBI>

=head1 DESCRIPTION

Little class to automate picking random rows from the table
that your Class::DBI thing uses and testing your Class::DBI
class with them.

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
  our @EXPORT = qw/test_class/;
}
use base qw/Exporter CXGN::DB::Connection/;

use Carp;

=head2 new

  Desc: make a new tester thing
  Args: none
  Ret : a new CXGN::CDBI::Class::DBI::TestSampler object
  Side Effects:
  Example:


=cut


sub new {
    my $class = shift;
    my $p = shift;
    $_[0]->{dbargs} = {AutoCommit => 1};
    return $class->SUPER::new(@_);
}

=head2 test_class

  Desc: picks a bunch of random rows from a table,
        and runs your
  Args: name of class we're testing,
        number of times to repeat the test, each with a different row
        reference to your test subroutine
  Ret : 1
  Side Effects:
  Example:

=cut

sub test_class {
  my ($this,$packagename,$num_repeats,$test_sub) = @_;

  #check the types of arguments
  my @typechecks = (__PACKAGE__ , $this,
		    CODE        => $test_sub,
		   );
  while(my ($type,$val) = splice @typechecks,0,2) {
    UNIVERSAL::isa($val,$type)
	or croak "Invalid arguments to ".__PACKAGE__."::test_class";
  }

  no strict 'refs';

  my $tablename = $packagename->table;
  my $primarycols = join (',',$packagename->primary_columns);

  my $random_sql = $this->dbtype eq 'mysql' ? 'ORDER BY rand()' : 'ORDER BY random()';

  #choose some clones at random
  my @ids = @{$this->selectcol_arrayref(<<EOSQL,{Columns => [1]})};
SELECT $primarycols
FROM $tablename
LIMIT $num_repeats
EOSQL

  #for each clone, test a bunch of things
  foreach my $id (@ids) {
    #diag "Using row with id $id...\n";
    $test_sub->($this,$id);
  }

  1;
}


###
1;#do not remove
###


=head1 AUTHOR

Robert Buels

=cut
