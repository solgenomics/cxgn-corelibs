use strict;
use CXGN::DB::Connection;
use CXGN::Tools::Text;
use CXGN::DB::SQLWrappers;
package CXGN::Accession;

=head1 NAME

CXGN::Accession

=head1 DESCRIPTION

Gets accession data from the sgn.accession and sgn.accession_names tables.

Note: will be soon deprecated in favor of the chado stock table.

=head1 AUTHOR

john binns - John Binns <zombieite@gmail.com>

Code and POD style reformatting by Lukas.


=head1 OBJECT METHODS

This class implements the following methods:

=cut


=head2 new

Takes an accession id or an accession name and returns a new accession object. With no accession id or name, it creates an empty accession object.

    use CXGN::Accession;
    my $accession=CXGN::Accession->new($dbh,$accession_name);

=cut 

sub new {
    my $class=shift;
    my($dbh,$accession)=@_;
    unless(CXGN::DB::Connection::is_valid_dbh($dbh)){die"Invalid DBH.";}
    my $self=bless({},$class);
    $self->{dbh}=$dbh;
    if($accession) {
        my $id_query;
        if($accession=~/^\d+$/) {
            $id_query=$self->{dbh}->prepare('select accession_id from accession where accession_id=?');
        }
        else {
	    $accession = '%'.$accession.'%';
            $id_query=$self->{dbh}->prepare('select accession_id from accession_names where accession_name ilike ?');
        }
        $id_query->execute($accession);
        ($self->{accession_id})=$id_query->fetchrow_array();
        if($self->{accession_id}) {
            my $accession_query=$self->{dbh}->prepare('select organism.organism_id,organism_name,common_name.common_name_id,common_name.common_name,accession.common_name,accession.accession_name_id,accession_names.accession_name from accession inner join accession_names using (accession_name_id) inner join organism on (accession.organism_id=organism.organism_id) inner join common_name using (common_name_id) where accession.accession_id=?');
            $accession_query->execute($self->{accession_id});
            ($self->{organism_id},$self->{organism_name},$self->{organism_common_name_id},$self->{organism_common_name},$self->{accession_common_name},$self->{preferred_name_id},$self->{preferred_name})=$accession_query->fetchrow_array();
            my @aliases;
            my $aliases_query=$self->{dbh}->prepare('select accession_name from accession_names where accession_id=? and accession_name!=?');
            $aliases_query->execute($self->{accession_id},$self->{preferred_name});
            while(my($alias)=$aliases_query->fetchrow_array)
            {
                push(@aliases,$alias);
            }
            $self->{aliases}=\@aliases;
        }
        else {
            return undef;
        }
    }
    return $self;  
}

=head2 all_accessions

 Usage:        my %hash = CXGN::Accession->all_accessions($dbh);
 Desc:         class method that returns all the accessions
               as a hash of class_ids and accession names.
 Author:       added by Lukas 10/2009

=cut

sub all_accessions {
    my $class = shift;
    my $dbh = shift;
    
    my $q = "SELECT accession_id, organism_name, accession_name FROM sgn.accession join sgn.accession_names using(accession_id) join sgn.organism using(organism_id)";
    my $h = $dbh->prepare($q);
    $h->execute();
    my %hash = ();
    while (my ($accession_id, $organism_name, $accession_name) = $h->fetchrow_array()) { 
	$hash{$accession_id} = "$organism_name ($accession_name)";
    }

    return %hash;

}

=head2 accession_id

    my $id=$accession->accession_id();

=cut

sub accession_id {
    my $self=shift;
    return $self->{accession_id};
}

=head2 preferred_name

    my $accession_name=$accession->preferred_name();

=cut

sub preferred_name {
    my $self=shift;
    if(@_)
    {
        ($self->{preferred_name})=@_;
    }
    return $self->{preferred_name};
}

=head2 other_names

    my @aliases=@{$accession->other_names()};

=cut

sub other_names {
    my $self=shift;
    return @{$self->{aliases}};
}

=head2 accession_common_name

    my $acn=$accession->accession_common_name();

=cut

sub accession_common_name {
    my $self=shift;
    if(@_) {
        ($self->{accession_common_name})=@_;
    }
    return $self->{accession_common_name};
}

=head2 organism_name

    my $org_name=$accession->organism_name();

=cut

sub organism_name {
    my $self=shift;
    if(@_)
    {
        ($self->{organism_name})=@_;
    }
    return $self->{organism_name};
}

=head2 organism_common_name

    my $org_cn=$accession->organism_common_name();

=cut

sub organism_common_name {
    my $self=shift;
    if(@_)
    {
        ($self->{organism_common_name})=@_;
    }
    return $self->{organism_common_name};
}

=head2 verbose_name

    my $verbose_name = $accession->verbose_name();

=cut

sub verbose_name {
    my $self=shift;
    my $verbose_name=$self->{organism_name}." ".$self->{preferred_name};
    $verbose_name=CXGN::Tools::Text::abbr_latin($verbose_name);
    $verbose_name=~s/ \(.*\)//;
    return $verbose_name;
}

=head2 extra_verbose_name

    my $xvn=$accession->extra_verbose_name();

=cut

sub extra_verbose_name {
    my $self=shift;
    my @extra_verbose_name;
    if($self->{organism_common_name}) {
        push(@extra_verbose_name,"<b>".$self->{organism_common_name}."</b>");
    }
    if($self->{organism_name}) {
        push(@extra_verbose_name,$self->{organism_name});
    }
#     if($self->{accession_common_name})
#     {
#         push(@extra_verbose_name,$self->{accession_common_name});
#     }
    if($self->{preferred_name}) {
        push(@extra_verbose_name,$self->{preferred_name});
    }
    if(@{$self->{aliases}}[0]) {
        push(@extra_verbose_name,'('.join(', ',@{$self->{aliases}}).')');
    }
    my $extra_verbose_name=join(' ',@extra_verbose_name);
    $extra_verbose_name=CXGN::Tools::Text::abbr_latin($extra_verbose_name);
    return $extra_verbose_name;
}

1;
