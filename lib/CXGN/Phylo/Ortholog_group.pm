use strict;

=head1 NAME

CXGN::Phylo::Ortholog_group -- a package to deal with ortholog detection

=head1 DESCRIPTION

An ortholog group is constructed by

=head1 VERSION

1e-10, Dec 26, 2005.
0.1 Feb 27, 2008

=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu)
Tom York (tly2@cornell.edu)

=head1 FUNCTIONS

The following functions are available:

=cut


package CXGN::Phylo::Ortholog_group;

=head2 function new

  Synopsis:	 my $ortho_grp = CXGN::Phylo::Ortholog_group->new($ortho_tree, $species_tree, $qRFd_max);
  Arguments:	First argument is a tree with all leaves having distinct species (see Node->collect_orthologs()),
     second argument is a species tree, and the 3rd arg. (default = 0) is a max quasiRF_distance from 
     a subtree to (pruned) species tree for the subtree to be considered conforming.
  Returns:	An ortholog_group object
  Side effects: none.
  Description:	 First the species tree is pruned of any species not found in the ortho tree. Then we find subtrees
whose quasiRF_distance to the species tree is <= qRFd_max.

=cut

sub new{
	my $class = shift;
	my $ortho_tree = shift;
	my $species_tree = shift;
	my $qRFd_max = shift;
	if (!defined $qRFd_max) {
		$qRFd_max = 0;
	}
	my $args = {};
	my $self = bless $args, $class;
	if (!defined $ortho_tree) {
		return $self;
	}
	$self->set_ortholog_tree($ortho_tree);
	if (!defined $species_tree) {
		return $self;
	}
	$self->set_species_tree($species_tree);
	# compare to species tree.
	#
	# collect all the species that occur in ortho_tree
	# then remove from the species tree the species that don't occur in the ortho_tree.
	#
	my %ortho_tree_species = ();
	my @ortho_tree_leaf_list = $ortho_tree->get_leaf_list();
	foreach my $oleaf (@ortho_tree_leaf_list) { 
		my $std_species = $oleaf->get_standard_species();
		$ortho_tree_species{$std_species}=$oleaf;
#print "otree std species: ", $std_species, "<br>\n";
	}

	my $temp_species_tree = $species_tree->copy(); 

	my %s_tree_species = ();
	my @s_tree_leaf_list = $temp_species_tree->get_leaf_list();
	foreach my $sleaf (@s_tree_leaf_list) {
		my $std_species = $sleaf->get_standard_species();
		$s_tree_species{$std_species}=$sleaf;
	}

	foreach my $os (keys %ortho_tree_species) {
		if (!exists ($s_tree_species{$os})) {
			print STDERR "Warning: Species ", $os, " is in an ortholog tree but not in the species tree.\n";
			print STDERR $species_tree->leaf_species_string();
	print "Warning: Species ", $os, " is not in the species tree.\n";
		#	print $species_tree->leaf_species_string();
		}
	}
	
	# remove species that do not occur in the ortho_tree from the species tree.
	# copy the species tree into a temp species tree, so that it 
	# can be manipulated without affecting the species_tree.
	#
	my @leaflist = $temp_species_tree -> get_leaf_list();

	# delete from species tree nodes of species not found in ortho tree. And collapse to
	# eliminate superfluous nodes that may look like topological differences
	#
	foreach my $l (@leaflist) {
		my $std_species = $l->get_standard_species();
		if (!exists($ortho_tree_species{$std_species})) {
			$temp_species_tree->del_node($l);	
			$temp_species_tree->collapse_tree();
			#this collapse tree is so that if you delete all the leaves of a subtree, you will delete the whole 
			# subtree. If e.g. there is a subtree with two leaves, both to be deleted, you want to delete their
			# parent too; by calling collapse_tree after deleting one leaf, the parent (which now has only
			# one child) will be deleted, and when the second leaf is deleted, the subtree is gone.
		}
	}
	
	# do the comparison, by getting the quasiRF_distance (0 -> match)
	#	
	my $qRF_distance; 
	#	if (1) {
	$qRF_distance = $ortho_tree->quasiRF_distance($temp_species_tree, "species"); # $ortho_t->get_root()->recursive_quasiRF_distance() is called from quasiRF_distance.
	#	} else {
	#		($qRF_distance, $ortho_tree) = $ortho_tree->get_root()->quasiRF_distance($temp_species_tree->get_root(), "species"); 
	#		$self->set_ortholog_tree($ortho_tree);
	#	}
	$self->set_conforms_to_species_tree($qRF_distance == 0); # needed ?
	$self->set_distance_to_species_tree($qRF_distance);

	#	$self->set_ortholog_tree($ortho_t);
	$self->generate_conforming_implicit_name_hash($qRFd_max);

	$ortho_tree->recalculate_tree_data(); #do we need this?		

#$ortho_tree->get_root()->print_subtree("<br>\n");

	return $self;
}

=head2 function get_ortholog_tree

  Synopsis:	the tree property stores the Ortholog_group's ortholog tree object.
  Arguments:	none.
  Returns:	the Ortholog_group's ortholog_tree object.
  Side effects: none.
  Description:	

=cut

sub get_ortholog_tree { 
	my $self=shift;
	return $self->{ortholog_tree};
}

=head2 function set_ortholog_tree

  Synopsis:	
  Arguments:	tree to be set as the Ortholog_group's ortholog tree object
  Returns:	nothing
  Side effects:	
  Description:	

=cut

sub set_ortholog_tree { 
	my $self=shift;
	$self->{ortholog_tree}=shift;
}

=head2 function get_species_tree

  Synopsis:	 $tree = $ortho_group->get_species_tree()
  Arguments:	none
  Returns:	the Ortholog_group's species tree object
  Side effects:	none
  Description:	

=cut

sub get_species_tree { 
	my $self=shift;
	return $self->{species_tree};
}

=head2 function set_species_tree

  Synopsis:	
  Arguments:	a tree to set as the Ortholog_group's species object
  Returns:	nothing
  Side effects:	
  Description:	

=cut

sub set_species_tree { 
	my $self=shift;
	$self->{species_tree}=shift;
}

=head2 function get_conforms_to_species_tree

  Synopsis:	
  Arguments:	
  Returns:	1 if the Ortholog_group conforms to the species tree
                0 if it does not.
  Side effects:	
  Description:	

=cut

sub get_conforms_to_species_tree { 
	my $self=shift;
	return $self->{conforms_to_species_tree};
}

=head2 function set_conforms_to_species_tree

  Synopsis:	
  Arguments:	1 if the Ortholog group conforms to the species tree
                0 if it does not
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_conforms_to_species_tree { 
	my $self=shift;
	$self->{conforms_to_species_tree}=shift;
}



=head2 function get_distance_to_species_tree

  Synopsis:	 $tree1->get_distance_to_species_tree()
  Arguments:	
  Returns:	Returns a sort of asymmetric distance from the ortholog group's tree (tree1), to the species
      tree (tree2) with which the ortholog group is compared (the argument in the constructor).  which depends on the
topologies and on the branch lengths of $tree1 but not on the branch lengths of tree2.
This is calculated by 
  Side effects:	
  Description:	 
See also: Phylo::Tree->quasiRF_distance

=cut

sub get_distance_to_species_tree { 
	my $self=shift;
	return $self->{distance_to_species_tree};
}

=head2 function set_distance_to_species_tree

  Synopsis:	
  Arguments:	The asymmetric distance to the species tree topology
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_distance_to_species_tree { 
	my $self=shift;
	$self->{distance_to_species_tree}=shift;
}


sub print{
	my $self = shift;
	print($self->og_string());
}



=head2 function og_string1

   Synopsis:	
   Arguments:	none
   Returns:	A string describing the ortholog group
   Side effects:	
   Description:	 Suitable for printing to a terminal

=cut

	sub og_string1{
		my $self = shift;
		my $ogstring = "";
		if ($self->get_ortholog_tree()->get_leaf_count()>1) {
			$ogstring .= ("Leaf names: " . join (", ",(map ($_->get_name(), $self->get_ortholog_tree()->get_leaf_list())))."     ");
			my $sp_string =  join(", ",(map ($_->get_shown_species(), $self->get_ortholog_tree()->get_leaf_list())));
			$ogstring .= "Species:  " . $sp_string. "     "; #. join (", ",(map ($_->get_species(), $self->get_ortholog_tree()->get_leaf_list())))."     ");
			#		$ogstring .= ("qRFd:  [" . join (",",(map ($_->get_attribute("qRF_distance"), $self->get_ortholog_tree()->get_leaf_list())))."]     ");
			#	if (defined $self->get_conforms_to_species_tree()) {
			#				if ($self->get_conforms_to_species_tree()) {
			my $root_impl_name = join("\t", @{$self->get_ortholog_tree()->get_root()->get_implicit_names()});
			my $qRFd = $self->get_ortholog_tree()->get_root()->get_attribute("qRF_distance");
			if (defined $qRFd) {			
				if (defined $self->get_conforming_node($root_impl_name)) { #conforming means qRFd < qRFd_max (arg to recursive_get_ortho_subtrees
					$ogstring .= "CONFORMS (d = 0)\n";
				} else {
					$ogstring .= "VIOLATES (d = ".$qRFd.")\n"; # $self->get_distance_to_species_tree().")\n";
				}
			} else {
				$ogstring .= "[no species tree]\n";
			}
		} else {
			$ogstring .= "***Isolated leaf: ". join  (" ",(map ($_->get_name(), $self->get_ortholog_tree()->get_leaf_list())))." \n";
		}
		return $ogstring;
	}


=head2 function og_string

   Synopsis:	
   Arguments:	none
   Returns:	A string describing the ortholog group
   Side effects:	
   Description:	 Suitable for printing to a terminal

=cut

	sub og_string{
		my $self = shift;
		my $ogstring = "";
		if ($self->get_ortholog_tree()->get_leaf_count()>1) {
			my @namelist = map ($_->get_name(), $self->get_ortholog_tree()->get_leaf_list());
			my @specieslist = map ($_->get_shown_species(), $self->get_ortholog_tree()->get_leaf_list());
			my @namespeclist = ();
			if (scalar @namelist == scalar @specieslist) {
				for (my $i = 0; $i < scalar @namelist; $i++) {
					my $namespec = $namelist[$i]."[species=".$specieslist[$i]."]";
					push @namespeclist, $namespec;
				}
			}

		#	$ogstring .= ("Leaf names: " . join (", ", @namelist)."     ");
		#	my $sp_string =  join(", ", @specieslist);
	#		$ogstring .= "Species:  " . $sp_string. "     "; #. join (", ",(map ($_->get_species(), $self->get_ortholog_tree()->get_leaf_list())))."     ");
$ogstring .= join(", ", @namespeclist);

			#		$ogstring .= ("qRFd:  [" . join (",",(map ($_->get_attribute("qRF_distance"), $self->get_ortholog_tree()->get_leaf_list())))."]     ");
			#	if (defined $self->get_conforms_to_species_tree()) {
			#				if ($self->get_conforms_to_species_tree()) {
			my $root_impl_name = join("\t", @{$self->get_ortholog_tree()->get_root()->get_implicit_names()});
			my $qRFd = $self->get_ortholog_tree()->get_root()->get_attribute("qRF_distance");
			if (defined $qRFd) {			
				if (defined $self->get_conforming_node($root_impl_name)) { #conforming means qRFd < qRFd_max (arg to recursive_get_ortho_subtrees
					$ogstring .= "   Conforms to species tree (d = 0)\n";
				} else {
					$ogstring .= "   Violates species tree (d = ".$qRFd.")\n"; # $self->get_distance_to_species_tree().")\n";
				}
			} else {
				$ogstring .= "[no species tree]\n";
			}
		} else {
			$ogstring .= "***Isolated leaf: ". join  (" ",(map ($_->get_name(), $self->get_ortholog_tree()->get_leaf_list())))." \n";
		}
		return $ogstring;
	}

# return a string for an html table row for an ortholog group
sub table_row_string{
	my $self = shift;
	my $row_string =  "<tr><td>";
	my $cell_spacer = "</td><td>";
	my $row_end = "</td></tr>";
	my $name_string =  join(", ", sort (map ($_->get_name(), $self->get_ortholog_tree()->get_leaf_list())));
	$row_string .= "_" . $name_string . $cell_spacer;
	my $sp_string = join(", ", sort (map ($_->get_shown_species(), $self->get_ortholog_tree()->get_leaf_list())));

	$row_string .= $sp_string . $cell_spacer; # join("\t",(map ($_->get_species(), $self->get_ortholog_tree()->get_leaf_list()))) . $cell_spacer;
	my $qRFd = $self->get_ortholog_tree()->get_root()->get_attribute("qRF_distance");
	my $root_impl_name = join("\t", @{$self->get_ortholog_tree()->get_root()->get_implicit_names()});
	if (defined $qRFd) {			
		if (defined $self->get_conforming_node($root_impl_name)) { #conforming means qRFd < qRFd_max (arg to recursive_get_ortho_subtrees
			$row_string .= "Yes" . $cell_spacer . $qRFd;
		} else {
			$row_string .= "No" . $cell_spacer .  $qRFd;
		}
	} else {
		$row_string .= "[no species tree]" . $cell_spacer .  "[no species tree]";
	}
	$row_string .= $row_end;

	my @alphabet = qw (a b c d e f g h i j k l m n o p q r s t u v w x y z);
	if (!defined $self->get_conforming_node($root_impl_name)) { # whole ortho group is non-conforming, consider subtrees
		my @cnins = $self->get_conforming_node_implicit_names();
		my $cognumber = 0;
		foreach my $s (@cnins) {
			$row_string .= "<tr><td>" .  $alphabet[$cognumber] . "_";
			my $conforming_node = $self->get_conforming_node($s);
			my $sp_string =  join(", ",(map ($_->get_shown_species(), $conforming_node->recursive_leaf_list())));
			my $qRFd = $self->get_conforming_node($s)->get_attribute("qRF_distance");
			$row_string .= $s . $cell_spacer;
			$row_string .= $sp_string . $cell_spacer . "." . $cell_spacer . $qRFd.$row_end;
			$cognumber++;
		}
	}
	return $row_string;
}


# argument is a string with the (tab joined) implicit name string, returns the corresponding node
sub get_conforming_node{
	my $self = shift;
	my $string = shift;
	my $node = ${$self->{"conforming_implicit_name_hash"}}{$string};
	return $node;
}


sub generate_conforming_implicit_name_hash{
	my $self = shift;
	my $qRFd_max  = shift;
	if (!defined $qRFd_max) {
		$qRFd_max = 0;
	}
	$self->get_ortholog_tree()->get_root()->recursive_implicit_names();
	my @conforming_nodes = $self->get_ortholog_tree()->get_root()->recursive_get_ortho_subtrees($qRFd_max);
	foreach my $n (@conforming_nodes) {
		my $implname =  join("\t", @{$n->get_implicit_names()});
		${$self->{"conforming_implicit_name_hash"}}{$implname} = $n;
	}
}

sub get_conforming_node_implicit_names{
	my $self = shift;		
	return keys %{$self->{"conforming_implicit_name_hash"}};
}


#	sub calculate_conforming_subtrees{
#		my $self = shift;
#		$self->set_conforming_nodes

1;
