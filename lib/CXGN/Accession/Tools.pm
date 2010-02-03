
=head1 NAME

CXGN::Accession::Tools

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Non-object-oriented tools for dealing with accession data.

=head2 all_accessions_extra_verbose

    print CXGN::Accession::Tools::all_accessions_extra_verbose();

=head2 partial_name_to_ids

    #get all accession ids for accessions with name like...
    my @accession_ids=CXGN::Accession::Tools::partial_name_to_ids('LA7');

=head2 insert_accession

    CXGN::Accession::Tools::insert_accession($dbh,$accname,$species,$common_name);

=cut

use strict;
use CXGN::DB::Connection;
use CXGN::Accession;

package CXGN::Accession::Tools;

sub all_accessions
{
    my ($dbh)=@_;
    my @accessions;
    my $accession_query=$dbh->prepare('select accession_id from accession');
    $accession_query->execute();
    while(my ($accession_id) = $accession_query->fetchrow_array())
    {
	#warn"$accession_id\n";
        my %hash;
        $hash{accession_id}=$accession_id;
        my $accession=CXGN::Accession->new($dbh,$accession_id);
        $hash{verbose_name}=$accession->verbose_name();
        #warn"$hash{verbose_name}\n";
        push(@accessions,\%hash);
    }
    return @accessions;    
}

sub partial_name_to_ids
{
    my($dbh,$partial_name)=@_;
    $partial_name=$dbh->quote('%'.$partial_name.'%');
    my $query="select accession_id from accession_names where accession_name ilike $partial_name";
    my $id_query=$dbh->prepare($query);
    $id_query->execute();
    my @ids;
    while(my($id)=$id_query->fetchrow_array()){push(@ids,$id);}
    return @ids;    
}

sub insert_accession {

  my ($dbh, $accname, $species, $common) = @_;

  # does the common name exist? if not, insert it.
  my $common_id;
  ($common_id) = $dbh->selectrow_array("SELECT common_name_id FROM common_name WHERE common_name.common_name ilike '$common'");

  unless ($common_id) {
    $dbh->do("INSERT INTO common_name (common_name) VALUES ('$common')");
    $common_id = $dbh->last_insert_id('common_name','sgn');
    warn "inserting $common\n";
  }

  warn "using $common ($common_id)\n";
  
  # does the species exist? if not, insert it.
  my $organism_id;
  ($organism_id) = $dbh->selectrow_array("SELECT organism_id FROM organism WHERE organism_name ilike '$species\%'");
  
  unless($organism_id){
    $dbh->do("INSERT INTO organism (organism_name) VALUES ('$species')");
    $organism_id = $dbh->last_insert_id('organism','sgn');
    
    warn "inserting $species\n";
  }

  warn "using $species ($organism_id)\n";

  # does there exist an accession with this name? If so, do nothing
  # and return.
  my $accession_name_id;
  ($accession_name_id) = $dbh->selectrow_array("SELECT accession_name_id FROM accession_names WHERE accession_name ILIKE '$accname'");

  if($accession_name_id){

    # the accession is already in there, so no problem!
    warn "found $accname ($accession_name_id)\n";
    return; 

  } else {
    # If not, insert the name and the accession.


    $dbh->do("INSERT INTO accession_names (accession_name) VALUES ('$accname')");
    $accession_name_id = $dbh->last_insert_id('accession_names','sgn');
    warn "using $accname ($accession_name_id)\n";
    $dbh->do("INSERT INTO accession (organism_id, accession_name_id) VALUES ($organism_id, $accession_name_id)");
    my $accession_id = $dbh->last_insert_id('accession','sgn');
    $dbh->do("UPDATE accession_names SET accession_id = $accession_id WHERE accession_name_id = $accession_name_id");

  }


}

1;
