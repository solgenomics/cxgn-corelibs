=head1 NAME

 People -- classes to deal with community data, login, user comments etc
          for the SGN website.

=head1 SYNOPSIS

=head1 AUTHORS

 Lukas Mueller, John Binns, Robert Buels.
 Copyleft (c) Sol Genomics Network. All rights reversed.

=cut

=head1 Package CXGN::People

 This is a base class that establishes the connection to the database.

=cut

use strict;
use CXGN::DB::Connection;
use CXGN::Tools::PgCatalog;
use POSIX;

package CXGN::People;

use CXGN::People::Person;
use CXGN::People::Login;
use CXGN::People::Organism;
use CXGN::People::Project;
use CXGN::People::Organization;

use base qw | CXGN::DB::Object |;

#use this string to find sequencing projects in sgn_people.sp_project.name
my $tomato_comparison_string = 'Tomato Chromosome % Sequencing Project';
my @chromosome_graph_lengths =
  ( 0, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200 ); #first number (for chromosome 0) is a dummy value because there is no chromosome 0
my @number_bacs_to_complete =
  ( 0, 246, 268, 274, 193, 111, 213, 277, 175, 164, 108, 135, 113 ); #first number (for chromosome 0) is a dummy value because there is no chromosome 0

=head2 new()

  Synopsis:     $p=CXGN::People->new();	
  Arguments:	none
  Returns:	an instance of class People
  Side effects:	establishes the database connection
  Description:	

=cut

sub new {
    my $class = shift;
	my $dbh = shift;
	my $self = bless {}, $class;
	$self->{dbh} = $dbh;
    return $self;
}

###
1;#do not remove
###
