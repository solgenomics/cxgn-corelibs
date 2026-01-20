package CXGN::Phylo::IdTaxonMap;

use strict;
use List::Util qw ( min max sum );

my %default_map =
  (
   '^AT' => 'arabidopsis',
   '^Bradi' => 'brachypodium',
   '^(?:X_)?\d{5}[.]m\d{6}' => 'castorbean', # can have X_ prefix or not
   '^GSVIV' => 'grape',
   '^(?:GRMZM|AC\d{6})' => 'maize',
   '^IMGA[|_](?:Medtr|AC|CU)' => 'medicago',
   '^evm' => 'papaya',
   '^POPTR' => 'poplar',
   '^LOC_Os' => 'rice',
   '^jgi_Selmo' => 'selaginella',
   '^Sb' => 'sorghum',
   '^Glyma' => 'soybean',
   '^Solyc' => 'tomato'
  );


sub  new {
  my $class = shift;
  my $arg = shift; # hash ref, keys are regular expressions, values are corresponding taxon names.
  my $args= {};
  my $self = bless $args, $class;

  my %map = ();
  foreach (keys %default_map) {
    $map{$_} = $default_map{$_};
  }

  foreach (keys %$arg) {
    $map{$_} = $arg->{$_};
  }

  $self->{map} = \%map;
  return $self;
}

sub get_map{
  my $self = shift;
  return $self->{map};
}


sub add_idregex_taxonname{
  my $self = shift;
  my $idregex = shift;
  my $taxonname = shift;
  $self->{map}->{$idregex} = $taxonname;
}


sub id_to_taxonname{
  my $self = shift;
  my $id = shift;

  my $map = $self->get_map();
  foreach (keys %$map) {
#   print "id regex: $_\n";
    return $map->{$_} if($id =~ /$_/);
  }
  warn "No taxon name found for id: $id\n";
  return;
}

1;
