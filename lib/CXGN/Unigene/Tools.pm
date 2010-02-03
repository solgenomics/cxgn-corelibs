package CXGN::Unigene::Tools;
use strict;

=head1 NAME

CXGN::Unigene::Tools

=head1 AUTHOR

John Binns <zombieite@gmail.com>

=head1 DESCRIPTION

Tools for dealing with unigenes.

=head2 cgn_id_to_sgn_id

Coffee unigenes can now be found in SGN. However if you have their old ID you must convert it to an SGN ID.

    my $sgn_id=CXGN::Unigene::Tools::cgn_id_to_sgn_id($cgn_id);

=cut

sub cgn_id_to_sgn_id
{
    my($dbh,$cgn_id)=@_;
    my $q="select unigene_id from unigene where database_name='CGN' and sequence_name=?";
    my $sth=$dbh->prepare($q);
    $sth->execute($cgn_id);
    my($sgn_id)=$sth->fetchrow_array();
    return $sgn_id;
}

sub sgn_id_to_cgn_id
{
    my($dbh,$sgn_id)=@_;
    my $q="select sequence_name from unigene where database_name='CGN' and unigene_id=?";
    my $sth=$dbh->prepare($q);
    $sth->execute($sgn_id);
    my($cgn_id)=$sth->fetchrow_array();
    return $cgn_id;
}

1;
