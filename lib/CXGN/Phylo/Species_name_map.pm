use strict;

=head1 NAME

CXGN::Phylo::Species_name_map - a package that handles variant species names (e.g. tomato, Lycopersicon_esculentum, Solanum_lycopersicum)

=head1 DESCRIPTION

This is for handling different species names that may be used. There is a  hash whose keys are variants, and
values are the standard versions of the species names.
A default hash is set up in new. You can add other variant/standard pairs. The keys are all
in a standard format with words separated by _, initial letter uc, others lc. e.g. if $sname = POTATO
get_standard_name($sname) will transform this to Potato, and return the value corresponding to this key,
which would be Solanum_tuberosum. 

=head1 AUTHOR

Tom York (tly2@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

package  CXGN::Phylo::Species_name_map;
# this is a class to map variant species names to standard species names

=head2 function new()

  Synopsis:	$snm->CXGN::Phylo::Species_name_map->new();
  Arguments:	none.
  Returns:	ref to newly constructed Species_name_map object with a default set of key/value (species/std species) pairs.
  Description: The objects hash has a key name_hash, whose corresponding value is a reference to a hash whose
    keys are variant species names and values are standard species names. Both the keys and values of name_hash are
    in a standard format using _ as separator, and all lowercase except first char. which is uppercase (see to_standard_format).

=cut

sub new{
	my $class = shift;
	my $args = {};
	my $self = bless $args, $class;

	%{$self->{name_hash}} = ();
	#list of default standard names
	my @std_species = ('Solanum_lycopersicum',  'Solanum_tuberosum', 'Solanum_melongena',  'Capsicum_annuum', 
										 'Nicotiana_tabacum',  'Petunia', 'Coffea_arabica',  'Coffea_canephora',  'Antirrhinum',  
										 'Arabidopsis_thaliana', 'Ipomoea_batatas', 'Oryza_sativa', 'Brachypodium_distachyon');

	# first set up some standard name associations
	foreach my $s (@std_species) {
		$self->set_standard_name($s, $s);
	}

	$self->set_standard_name('tomato', 'Solanum_Lycopersicum');
	$self->set_standard_name('potato', 'Solanum_Tuberosum');
	$self->set_standard_name('eggplant', 'Solanum_Melongena');
	$self->set_standard_name('pepper', 'Capsicum_Annuum');
	$self->set_standard_name('tobacco', 'Nicotiana_Tabacum');
	$self->set_standard_name('petunia', 'Petunia'); # species?
	$self->set_standard_name('sweet_potato', 'Ipomoea_batatas');
	$self->set_standard_name('coffee', 'Coffea'); #what about C. canephora?
	#	$self->set_standard_name('coffee', 'Coffea_Arabica'); #what about C. canephora?
	$self->set_standard_name('rice', 'Oryza_sativa');
	$self->set_standard_name('brachypodium', 'Brachypodium_distachyon');

	$self->set_standard_name('snapdragon', 'Antirrhinum'); #species Majus?
	$self->set_standard_name('arabidopsis', 'Arabidopsis_Thaliana');

	$self->set_standard_name('Solanum betaceum', 'Solanum_Betaceum');
	$self->set_standard_name('tamarillo', 'Solanum_Betaceum');

	$self->set_standard_name('Physalis philadelphica', 'Physalis_Philadelphica');
	$self->set_standard_name('tomatillo', 'Physalis_Philadelphica');

	$self->set_standard_name('Lycopersicon Esculentum', $self->get_standard_name('tomato'));
#	$self->set_standard_name('Ipomoea_batatas', $self->get_standard_name('sweet_potato'));

# print STDOUT "in CXGN::Phylo::Species_name_map->new(). tomato std name: ", $self->get_standard_name("tomato"), "\n";
	return $self;
}

=head2 function set_standard_name

  Synopsis:	 $snm->set_standard_name("tomatillo", "Physalis philadelphica")
  Arguments: List of two strings; the second becomes the standard species name corresponding to the first.
  Returns:	nothing
  Side effects: Stores a key value pair in the hash
  Description:	 The first argument is transformed by to_standard_format, and this becomes a key with value set equal to the second arg.

=cut

sub set_standard_name{
	my $self=shift;
	my $var = shift;
	my $std = shift;
	$var = CXGN::Phylo::Species_name_map->to_standard_format($var); #so hash keys are in standard format e.g. " solanum  LYCOPERSICUM " ->  "Solanum_lycopersicum"
	$std = CXGN::Phylo::Species_name_map->to_standard_format($std); # so hash vals are in standard format
	$self->{name_hash}->{$var} = $std;
}

=head2 function get_standard_name

  Synopsis:	 my $std_species = $snm->get_standard_name("tomatillo")
  Arguments: A species name string;
  Returns:	The corresponding standard name.
  Description:	 The argument is transformed by to_standard_format, and this becomes a key for which the value is returned.

=cut

sub get_standard_name{
	my $self = shift;
	my $var = shift;
	$var = CXGN::Phylo::Species_name_map->to_standard_format($var); #e.g. " solanum  LYCOPERSICUM " ->  "Solanum_lycopersicum"
	return $self->{name_hash}->{$var};
}

=head2 function copy()

  Synopsis:	 my $snm_copy = $snm->copy()
  Arguments:	a Species_name_map object
  Returns:	a Species_name_map object, a copy of $snm
  Description:	 Starts with a new default object, and copies the  hash to it

=cut

sub copy{												# just copy the hash
	my $self = shift;
	my $new = CXGN::Phylo::Species_name_map->new();
	foreach my $k (keys %$self) {
		$new->set_standard_name($k, $self->get_standard_name($k));
	}
	return $new;
}

=head2 function to_standard_format

  Synopsis:	 my $str = CXGN::Phylo::Species_name_map->to_standard_format($sp_name);
  Arguments:	A string.
  Returns:	A string put into a standard format by removing leading and trailing whitespace, splitting at whitespace or _,
      making lc, joining with _, then make first char uc. E.g.: "   solanum _TUBEROSUM  "  becomes "Solanum tuberosum". 
Note that applying this multiple times gives same result as applying once.
  Description:	 The idea is to have all the hash keys of a Species_name_map be in this format, so that some minor variations
      (e.g. potato, Potato) would share the same key

=cut

sub to_standard_format{					# remove initial, final whitespace,  replace whitespace and _ with single space separating pieces which are ucfirst lc
	my $self = shift;
	my $species = shift;
	if (defined $species) {
		$species =~ s/^\s+//;				# remove initial whitespace 
		$species =~ s/\s+$//;				# remove final whitespace
		my @species_list = split(/[\s_]+/, $species);
		map($_ = lc $_, @species_list); # -> all lowercase
		$species = join(" ", @species_list); # join with _'s
		#	return ucfirst $species;	
		$species = ucfirst $species;
	}
	return $species;
}

=head2 function get_map_string

  Synopsis: 	my $str = $snm->get_map_string()
  Arguments:	a Species_name_map object
  Returns:	A string with the keys and values (standard species) of the hash in form:
         (potato => Solanum_tuberosum, tomato => Solanum_lycopersicum)
  Description:	 

=cut

sub get_map_string{
	my $self = shift;
	my $string = "(";
	foreach my $s (keys %{$self->{name_hash}}) {
		$string .= $s . " => " . $self->get_standard_name($s) . ",  ";
	}
	$string =~ s/,\s*$//g; # eliminate final comma and whitespace
	$string .= ")";
	return $string;
}


1;
