package CXGN::BlastWatch::Config;
use base 'CXGN::Config';
my $defaults =
    {

     mail_from => 'sgn-feedback@sgn.cornell.edu',

    };
sub defaults { shift->SUPER::defaults( $defaults, @_ )}
1;
