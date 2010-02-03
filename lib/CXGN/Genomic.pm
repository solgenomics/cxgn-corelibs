#import most of the classes in this API
use CXGN::Genomic::Chromat;
use CXGN::Genomic::ReadClass;

use CXGN::Genomic::Clone;

use CXGN::Genomic::GSS;

use CXGN::Genomic::QCReport;

use CXGN::Genomic::Library;
use CXGN::Genomic::CloneType;

use CXGN::BlastDB;
use CXGN::Genomic::BlastQuery;
use CXGN::Genomic::BlastHit;
use CXGN::Genomic::BlastDefline;

use CXGN::Genomic::GenbankSubmission;
use CXGN::Genomic::GSSSubmittedToGenbank;

#search methods
use CXGN::Genomic::Search;

#this is the container package/documentation for the Genomic API classes
package CXGN::Genomic;


=head1 NAME

    Genomic - application programming interface to the SGN
                   genomic database

=head1 SYNOPSIS

  #BASIC USE OF PERSISTENT-TYPE OBJECTS IN THIS API

  #query the database for all objects matching the given SQL 'WHERE'
  #clause, buffering the results inside the Library object
  my @libs = $lib->search(shortname => 'LE_HBa')
    or die scalar(@libs)." genomic libraries found with shortname 'LE_HBa'\n"
     if @libs != 1;

  #iterate through each Library, printing its full name, shortname,
  #and ID
  foreach my $lib (@libs) {
     print "Name: ".$lib->name()."\tShortname: ".$lib->shortname()
           ."\tID: ".$lib->library_id()."\n";
  }

  #get all of the Clone objects that belong to the last Library we
  #found above
  my $lib = $libs[-1];

  my @clones = $lib->clone_objects;
  die scalar(@clones)."Clones found in library '".$lib->shortname()."'\n"
    if @clones < 1;

  #print out the clone names and estimated lengths of all these clones.
  foreach my $clone (@clones) {
    print $clone->clone_name()." ".$clone->estimated_length()."\n";
  }

  #CONDUCTING AN ADVANCED SEARCH FOR GSS OBJECTS
  my $gss_search = CXGN::Genomic::Search::GSS->new;
  my $gss_query = $gss_search->new_query();

  #search for all GSS objects with trimmed sequence length between
  #300 and 500
  $gss_query->trimmed_length("&t >= 300 AND &t <= 500"});
  #and that have an arizona clone name like 'SL*0002A*'
  $gss_query->arizona_clone_name(" LIKE 'SL%0002A%'");

  #perform the search
  my $gss_result = $gss_search->do_search($gss_query);

  #iterate through every CXGN::Genomic::GSS object in the results
  #and print its external identifier and its vector-trimmed sequence
  #in FASTA format
  $gss_result->autopage($gss_query,$gss_search);
  while(my $gss = $gss_result->next_result($gss_search,$gss_query)) {
    print '>'.$gss->chromat_object->chromat_external_identifier."\n".$gss->trimmed_seq."\n";
  }


=head1 DESCRIPTION

This framework contains a number of classes for working with the
Genomic database, which is designed to keep track of genomic survey
sequences such as BAC end sequences, BAC shotgun sequences, etc.
Currently, it is implemented using the L<Class::DBI> framework to
provide a mapping between objects and the relational database.

Most classes in the framework child classes of L<CXGN::CDBI::Class::DBI>
which means that each object is simply an encapsulation of a single row
in a single table in the database, along with methods that operate on that
data.

=head1 SCRIPTS USING THIS API

Look at these relatively simple scripts for examples of how to do things.

=head2 clone_read_info.pl

Web script to display all kinds of things about a single genomic
survey read from a clone.  Currently only knows how to display BAC
ends.

=head2 query-genomic-seqs.pl

Script to dump sequences and optionally their associated quality 

=head1 OBJECT LIST

=head2 L<Class::DBI> objects

Each of these encapsulates data from a single row of a single table in
the Genomic database.

=over 12

=item list coming soon

=back

=head2 Search objects

=over 12

=item L<CXGN::Genomic::Search::Clone>

Advanced search for L<CXGN::Genomic::Clone> objects.

=item L<CXGN::Genomic::Search::GSS>

Advanced search for L<CXGN::Genomic::GSS> objects, based on the
L<CXGN::Search> framework.

=back

=head2 Other objects

=over 12

x=item list coming soon

=back

=head1 BUGS

Erm...yeah, there are probably some.  Don't know of any right now.

=head1 AUTHOR

Robert Buels

=cut

###
1;#do not remove
###
