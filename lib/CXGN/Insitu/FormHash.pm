
use strict;


=head1

<HTML>

Name: $form{name}

=cut

use strict;
require Tie::Hash;

package CXGN::Insitu::Form;

use base qw( Tie::Hash );

sub TIEHASH { 
    my $class = shift;
    return bless {}, $class;
}

sub STORE { 
    my $self = shift;
    my $key = shift;
    my $value = shift;
    $self->{$key}=$value;
}

sub FETCH { 
    my $self = shift;
    my $key = shift;

    if (exists($self->{$key})) { 
	return "Haha!".$self->{$key};
    }
    else { 
	return undef;
    }
}

sub FIRSTKEY { 
    my $self = shift;
    return (keys(%$self))[0];
}


sub NEXTKEY { 
    my $self = shift;
    my $lastkey = shift;
    my @keys = keys(%$self);
    for (my $i=0; $i<@keys; $i++) { 
	if ($lastkey eq $keys[$i]) { 
	    return $keys[$i+1];
	}
    }
	    
}


return 1;
