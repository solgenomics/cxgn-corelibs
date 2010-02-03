package CXGN::Genomic::Config;
use base qw/ CXGN::Config /;

# just a stub for now, no defaults to add yet
my $defaults =
  {

   dbsearchpath             => [qw[
                                   genomic
                                   metadata
                                   public
                                   sgn_people
                               ]],
  };

sub defaults { shift->SUPER::defaults( $defaults, @_ )}
1;
