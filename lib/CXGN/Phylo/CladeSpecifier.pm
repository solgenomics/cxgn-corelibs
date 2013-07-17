package CXGN::Phylo::CladeSpecifier;
use strict;
use List::Util qw ( min max sum );

# to define a clade by specifying that it contains certain species, and keep track of
# whether this specification is satisfied as the species belonging to a clade are entered.
# Actually specification of clade can be more general, e.g. 
# 'monocots,3;Selaginella_moellendorffii,1' would specify that there are at least 3 distinct monocot species, 
# and Selaginella, but doesn't specify which monocot species must be present.


sub new {
  my $class = shift;
  my $self = bless {}, $class;

  my $clade_spec_file_or_string = shift;
  my $predefined_taxon_groups = shift || {}; 
  my $clade_spec_string;
  if( -f $clade_spec_file_or_string ){
    open my $fh, "<", "$clade_spec_file_or_string";
    $clade_spec_string = join("", <$fh>); # does this work?
  }else{
    $clade_spec_string = $clade_spec_file_or_string;
  }
  # something like:  'monocots,1;(Selaginella_moellendorfii, Physcomitrella_patens),1'
  $clade_spec_string =~ s/\s+//g; # remove whitespace
  my @taxon_groups = split(";", $clade_spec_string);
  my %group_taxa = (); # keys are taxon group names, values are hashrefs of all taxon names in group
  my %group_required_count = ();
  my $taxon_group_number = 1;
  for my $tgroup (@taxon_groups) { # $tgroup is something like  'monocots,1'  or (Selaginella_moellendorfii, Physcomitrella_patens),1
#    print "tgroup $tgroup \n";
    my $taxon_group_name = "taxon_group_$taxon_group_number";
    my @taxa = ();
    my $required_count;
    if ($tgroup =~ /\((.*)\),(\d+)/) { # parens around multi taxa or groups
      @taxa = split(",", $1);
      $required_count = $2;
    } elsif ($tgroup =~ /([^,]+),(\d+)/) { # single taxon or taxon group (e.g. 'monocots')parens not needed.
      @taxa = ($1);
  $required_count = $2;
    } else {
      warn "problem parsing expression $clade_spec_string \n";
    }

    for my $taxon_or_group (@taxa) {
      if (exists $predefined_taxon_groups->{$taxon_or_group}) { # it is a group of taxa.
	for (keys  %{$predefined_taxon_groups->{$taxon_or_group}}) {
	  $group_taxa{$taxon_group_name}->{$_}++;
	}
      } else {
	$group_taxa{$taxon_group_name}->{$taxon_or_group}++;
      }
      $group_required_count{$taxon_group_name} = $required_count;
    }

    $taxon_group_number++;
  }
  $self->{group__taxa} = \%group_taxa; # key: taxon group id. value: hashref (keys are taxa, values > 0 (really just care whether key exists )
  $self->{group__required_taxon_count} = \%group_required_count; # 

  $self->reset();

  return $self;
}				# end of constructor


sub store{
  my $self = shift;
  my $taxon = shift;
  my %group_required_count = %{$self->{group__required_taxon_count}}; # the number of taxa which are required in the group.

  my %group_observed_taxa = %{$self->{group__observed_taxa}}; 
  my %group_observed_taxon_count = %{$self->{group__observed_taxon_count}}; # counts the number of distinct taxa which are present in the group.
  my %satisfied_groups = %{$self->{satisfied_groups}};

  while ( my ($group, $taxa_hashref) = each %{$self->{group__taxa}}) {
    if (exists $taxa_hashref->{$taxon}) { # if it is one of the taxa in the group ...
      $group_observed_taxa{$group}->{$taxon}++; # count taxon observed in group 
      $group_observed_taxon_count{$group} = scalar keys %{$group_observed_taxa{$group}}; # increment count of distinct observed taxa in group.
#      die "observed taxon count inconsistency.\n" if($group_observed_taxon_count{$group} != scalar keys %{$group_observed_taxa{$group}});
 #     my ($min_required_count, $max_required_count) = $group_required_count{$group}@{};
      
      if ($group_observed_taxon_count{$group} >= $group_required_count{$group}) {
	$satisfied_groups{$group}++; # This group is satisfied now.
      }
    }
  }
  $self->{group__observed_taxa} = \%group_observed_taxa;
  $self->{group__observed_taxon_count} = \%group_observed_taxon_count;
  $self->{satisfied_groups} = \%satisfied_groups;
  return (scalar keys %satisfied_groups >= scalar keys %group_required_count)? 1: 0; # 1 -> clade requirements all satisfied.
}

sub is_ok{
  my $self = shift;
  my $group_observed_taxon_count = $self->{group__observed_taxon_count};
  my $group_required_count = $self->{group__required_taxon_count};
  for (keys %$group_observed_taxon_count) {
    if ($group_observed_taxon_count->{$_} < $group_required_count->{$_}) {
      return 0;
    }
  }
  return 1;
}

sub as_string{
  my $self = shift;
  my $group_taxa = $self->{group__taxa};
  my $group_observed_taxon_count = $self->{group__observed_taxon_count};
  my $group_required_count = $self->{group__required_taxon_count};
  my $string = '';
  for (keys %$group_taxa) {
    my @taxa =  keys %{$group_taxa->{$_}};
    $string .= "$_.  " . $group_required_count->{$_} . " of the following " . scalar @taxa . " species required: " . join(",", @taxa) . "\n";
  }
  return $string;
}

sub reset{ # resets to state where no taxa have been stored.
  my $self= shift;
  for (keys  %{$self->{group__required_taxon_count}}){
    $self->{group__observed_taxon_count}->{$_} = 0;
    $self->{group__observed_taxa}->{$_} = {};
  }
  $self->{satisfied_groups} = {};
}

1;
