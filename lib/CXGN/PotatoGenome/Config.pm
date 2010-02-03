package CXGN::PotatoGenome::Config;
use base 'CXGN::Config';
my $defaults =
    {

     repository_path    => '/data/prod/public/potato_genome/bacs',
     bac_publish_subdir => 'potato_genome/bacs',

     # and so on
    };
sub defaults { shift->SUPER::defaults( $defaults, @_ )}
1;
