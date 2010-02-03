
=head1 NAME

CXGN::Tools::File::Fasta

=head1 DESCRIPTION



=head1 OBJECT METHODS

=head2 new



=head2 as_string



=head1 AUTHOR

john binns - John Binns <zombieite@gmail.com>

=cut

package CXGN::Tools::File::Fasta;
use strict;
use CXGN::Tools::Text;
sub new
{
    my $class=shift;
    my $self=bless({},$class);
    ($self->{filename})=@_;
    my($FILE);
    open($FILE,$self->{filename}) or return;
    my %data;
    my $hash_key_name='no_name';
    while(my $line=<$FILE>)
    {
        $line=CXGN::Tools::Text::remove_all_whitespaces($line);
        if(defined($line) and $line ne '')
        {
            #if we are on a new entry 
            if(substr($line,0,1) eq '>')
            {
                substr($line,0,1)='';
                if(defined($line) and $line ne ''){$hash_key_name=$line;}
                else{$hash_key_name='no_name';}
            }
            #else we are on sequence data
            else
            {
                if(defined($data{$hash_key_name})){$data{$hash_key_name}.=$line;}
                else{$data{$hash_key_name}=$line;}                    
            }
        }
    }
    $self->{fasta}=\%data;
    close($FILE);
    return $self;
}
sub sequence_identifiers
{
    my $self=shift;
    return keys(%{$self->{fasta}});
}
1;
