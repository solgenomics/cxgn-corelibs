#!/usr/bin/perl
use Test::Most tests => 52;  # qw/no_plan/;
use Modern::Perl;

# tests Parser, Tree, and Node modules.

use CXGN::Phylo::Tree;
use CXGN::Phylo::Node;
use CXGN::Phylo::Parser;
use Data::Dumper;

use Carp;

# expression to test the Phylo packages with
#
my $newick_expression = 
	 "(1:0.082376,(2:0.196674,((3:0.038209,6:0.354293):0.026742,5:0.094338):0.064142):0.067562,4:0.295612)";
my $parser = CXGN::Phylo::Parse_newick -> new($newick_expression);

# test tokenizer
#
my @tokens =  $parser -> tokenize($newick_expression);
# print STDERR "\tTOKENS: ".join("|", @tokens)."\n";
is (@tokens, 22, "Token count test");

my $tree = $parser-> parse();

#print STDERR Dumper($tree);

#print STDERR "Total Nodes: ".(keys(%{$tree->{node_hash}}))."\n";
#is (keys(%{$tree->{node_hash}}), 10, "node count test");

# check the number of nodes returned by get_all_nodes
#
is ($tree->get_all_nodes(), 10, "node count test [node_hash]");

# pick an element and verify if it is a CXGN::Phylo::Node object
#
is ( UNIVERSAL::isa(($tree->get_all_nodes())[4], "CXGN::Phylo::Node"), 1, "node id test");

my $n = $tree->get_node(5);
#print STDERR "NODE 5: ".$n->get_name()."\n";
#$n->set_hilited(1);
#print  STDERR "Set node 5 to hilited ".$n->get_hilited()."\n";
#$n->rotate_node();
#$tree->get_root()->rotate_node();
#$n4->set_hidden(1);

#my $subtree_len = $tree->get_root()->calculate_subtree_distances();
#is ($subtree_len, 12, "subtree length test");

# test the leaf functions in two different ways
#
is ($tree->get_leaf_count(), 6, "leaf count test");

my @leaflist = $tree->get_leaf_list();
#   foreach my $leaf (@leaflist) { 
#      print STDERR "Leaf: ".$leaf->get_name()."\n";
#  }

is ($tree->get_root()->is_leaf, 0, "root leaf test");

# foreach my $l (@leaflist) { print STDERR "LEAFLIST: ". ($l->get_name())."\n"; }

is (@leaflist, 6, "leaf list test");


# test the root
#
my $root = $tree->get_root();
is ($root->is_root(), 1, "root test");

# test the subtree node count functions
#
#my @ortho_groups = $tree->get_orthologs();
$tree->get_root()->calculate_subtree_node_count();
my $root_subnode_count = $tree->get_root()->get_subtree_node_count();
my $leaf_subnode_count = $tree->get_node(7)->get_subtree_node_count();
my $inner_node_subnode_count = $tree->get_node(3)->get_subtree_node_count();
is ($root_subnode_count, 9, "root subnode count test");
is ($leaf_subnode_count, 0, "leaf subnode count test");
is ($inner_node_subnode_count, 6, "inner node subnode count test");

# set species information to test subtree_species_count stuff
#
my @species_list = ("coffee", "tomato", "potato", "pepper", "eggplant", "brachypodium");
#my @node_list = values %{$tree->{node_hash}};
my $i = 0;
foreach my $n (values %{$tree->{node_hash}}) {
	next if(scalar $n->get_children() > 0); # skip non-leaves
	$n->set_species($species_list[$i % 6]);
	print "i, species:  $i  ", $n->get_species(), "\n";
	$i++;
}

# test the subtree_species count functions

#$tree->get_root()->recursive_text_render();
#exit;#
$tree->get_root()->recursive_set_leaf_species_count();
#$tree->get_root()->calculate_subtree_species_count();

# pick out a node and test the count
#
print "node keys: ", join(" ", keys %{$tree->{node_hash}}), "\n";
is($tree->get_root()->get_attribute("leaf_species_count"), 6, "subtree leaf species count test");
#is ($tree->get_node(5)->get_attribute("leaf_species_count"), 3, "subtree leaf species count test");

# test the remove_child function
#
#print STDERR "before tree copy\n";
my $rm_tree = $tree->copy();
print STDERR 'after $tree->copy() \n';
my @root_children = $rm_tree->get_root()->get_children();
my $n1 = $root_children[1];
my @children =$n1->get_children();
#print STDERR "\tRemove child\nbefore: ".$n->to_string()."\n";
is ($n1->get_children, 2, "get_children test");
#print STDERR "\t(Removing child ".$children[0]->get_node_key().")\n";
$n1->remove_child($children[0]);
is ($n1->get_children(), 1, "remove child test");
#print STDERR "\tafter : ".$n1->to_string()."\n";

my @root_kids = $rm_tree->get_root()->get_children();
is (@root_kids, 3, "root children count test");
$rm_tree->get_root()->remove_child($root_kids[1]);
#print STDERR "\tRemoving child key=".($root_kids[1]->get_name())."\n"; 
#foreach my $c ($rm_tree->get_root()->get_children()) { print "current children = ".$c->get_name()."\n"; }
is ($rm_tree->get_root()->get_children(), 2, "removed one root child test");

# test reset_root
#

#print STDERR $tree->generate_newick();

$tree->reset_root( $tree->get_node(5) );

#print STDERR $tree->generate_newick();

# test the compare function
# initialize two identical trees and compare
# (should return 1)
#
my $species_tree_newick = "((((( tomato_tomato:1, potato_potato:1):1, pepper_pepper:1 ):1, eggplant_eggplant):1, nicotiana_nicotiana:1):1, coffee_coffee:1)";
my $species_tree_parser = CXGN::Phylo::Parse_newick->new($species_tree_newick);
my $species_tree = $species_tree_parser->parse();

my $species_tree_newick2 = "((((( tomato_tomato:5, potato_potato:1):1, pepper_pepper:1 ):1, eggplant_eggplant):1, nicotiana_nicotiana:1):1, coffee_coffee:1)";
my $species_tree_parser2 = CXGN::Phylo::Parse_newick->new($species_tree_newick2);
my $species_tree2 = $species_tree_parser2->parse();

# compare the tree to itself
#
is ($species_tree->compare_rooted($species_tree), 1, "tree self comparison test (tree1-tree1)");
is ($species_tree->compare_rooted($species_tree2), 1, "tree comparison test (tree1-tree2)");
is ($species_tree2->compare_rooted($species_tree2), 1, "tree self comparison test (tree2-tree2)");
is ($species_tree2->compare_rooted($species_tree), 1, "tree comparion test (tree2-tree1)");

# test that a different tree returns 0
#
is($species_tree->compare_rooted($tree), 0, "tree inequality test");

# test that two topologically identical but specified differently match in the comparison
#
my $tree_a = CXGN::Phylo::Parse_newick->new("(A:1, B:1)")->parse();
my $tree_b = CXGN::Phylo::Parse_newick->new("(B:1, A:1)")->parse();
is ($tree_a->compare_rooted($tree_b), 1, "tree topology specification test");


# test the copy function
# 
my $new_tree = $tree->copy();
if ($tree->compare_rooted($new_tree)) {  # should be the same, shouldn't it?
    # print STDERR "Compared tree to newtree and found them to be identical.\n";
}
else  { print STDERR "newtree and tree are not identical. Oops.\n"; }
is ($new_tree->compare_rooted($tree), 1, "copied tree identity check");
isnt ( $new_tree, $tree, "tree pointer non-identity check");

my ($rfd, $symd, $d3) = $tree->RF_distance($new_tree);
is($rfd, 0, "check RF distance between tree and copy is 0.\n");
is($symd, 0, "check RF distance between tree and copy is 0.\n");

# check if I can remove a node in new_tree without affecting $tree
#
#print "node keys: ", join(" ", keys %{$tree->{node_hash}}), "\n";
$new_tree->delete_node(3);


# print $tree->generate_newick(), "\n";
# print $new_tree->generate_newick(), "\n";

is($new_tree->compare_rooted($tree), 0, "changed copied tree identity check");

# test the collapsing function - test a tree with many nodes that
# have only one child.
#
#print STDERR "\tTesting CXGN::Phylo::Node::recursive_collapse_nodes\n";
my $c_tree = (CXGN::Phylo::Parse_newick->new("((((A:1, B:1)C:1)D:1)E:1)"))->parse();

$c_tree->set_renderer(CXGN::Phylo::Text_tree_renderer->new($c_tree));

#print STDERR "The original tree: \n";
#$c_tree->render();
#print STDERR "=====\n\n";

is ($c_tree->get_all_nodes(), 6, "node count before collapse");

$c_tree->collapse_tree();
#print STDERR "The collapsed tree:\n";
#$c_tree->render();
#print STDERR "=====\n\n";

is ($c_tree->get_all_nodes(), 3, "node count after collapse");

#$new_tree->set_renderer(CXGN::Phylo::Text_tree_renderer->new($new_tree));
#$new_tree->render();

#if(1 || $c_tree->get_all_nodes() != 3){
#$c_tree->print_node_keys();
#$c_tree->get_root()->print_subtree();
#}exit; 

# test a more complex case for collapsing
#
$c_tree = (CXGN::Phylo::Parse_newick->new("((((A:1, B:1)C:1)D:1)E:1, (((G:1, F:1)H:1)I:1)J:1)"))->parse();
$c_tree->set_renderer(CXGN::Phylo::Text_tree_renderer->new($c_tree));
$c_tree->collapse_tree();

# test a tree collapsing with a tree that has branch lengths of zero.
#
my $z_tree = (CXGN::Phylo::Parse_newick->new("((((A:1, B:0)C:0)D:0)E:1, (((G:1, F:1)H:0)I:1)J:1)"))->parse();
print STDERR "Testing the recursive_collapse_zero_branches() function...\nOriginal tree:\n";
$z_tree->get_root()->print_subtree();

my $z_tree_node_count = $z_tree->get_node_count();
$z_tree ->get_root()->recursive_collapse_zero_branches();

is ($z_tree->get_node_count(), $z_tree_node_count-4, "recursive_collapse_zero_nodes test");

# check the delete node function
# first, check if we can delete an internal node...
#
print STDERR "\tDeleting internal node (key=4)...\n";
my $ind_tree = (CXGN::Phylo::Parse_newick->new("((((A:1, B:1)C:1)D:1)E:1, (((G:1, F:1)H:1)I:1)J:1)"))->parse();
my $ind_tree_copy = $ind_tree->copy();
$ind_tree->delete_node(4);
is ($ind_tree_copy->get_all_nodes(), ($ind_tree->get_all_nodes()+1), "node count after delete test");
is ($ind_tree->get_node(4), undef, "has node really disappeared test");

# let's delete a leaf node...
#
print STDERR "\tDeleting a leaf node (key=2)...\n";
$ind_tree->delete_node(2);
#$ind_tree->render();
is ($ind_tree_copy->get_all_nodes(), ($ind_tree->get_all_nodes()+2), "node count after leaf node deletion");

# test the newick generation from the node
#
my $original_newick = "((((A:1,B:1)C:1)D:1)E:1,(((G:1,F:1)H:1)I:1)J:1)";
my $t = (CXGN::Phylo::Parse_newick->new($original_newick))->parse();
my $new = $t->get_root()->recursive_generate_newick();
# print STDERR "Original: $original_newick\n";
# print STDERR "Regenerated newick = $new\n";
my $t2 = (CXGN::Phylo::Parse_newick->new($new))->parse();
is($t->compare_rooted($t2), 1, "Newick regeneration from tree test");


my $incorp_tree = $tree->copy();
$incorp_tree->incorporate_nodes(CXGN::Phylo::Node->new());
is($incorp_tree->get_all_nodes(), 11, "Incorporate Node Test");

my $b_tree = $tree->copy();
is($b_tree->get_all_nodes(), 10, "Binary tree test: copy");
$b_tree->make_binary();
my @nodes = $b_tree->get_all_nodes();
is(@nodes, 11, "Binary tree test: node count");
my $binary_fail = 0;
foreach(@nodes){
	my @children = $_->get_children();
	$binary_fail = 1 if @children > 2;
}
isnt($binary_fail, 1, "Binary tree test: all children count <= 2");

# render the tree
#
# $tree->get_layout()->set_image_width(500);
# $tree->get_layout()->set_image_height(300);

# my $PNG_tree_renderer = CXGN::Phylo::PNG_tree_renderer -> new($tree);
# $tree->get_layout()->set_left_margin(50);
# $tree->get_layout()->set_right_margin(40);
# $PNG_tree_renderer->render();

# my $renderer = CXGN::Phylo::Text_tree_renderer -> new($tree);
# $renderer->render();


# test tree root resetting, and tree comparison 
#
# Get tree from newick expression. Reset root so as to minimize maximum root-leaf distance.
# copy a tree, then, for each branch, reset the root to a point along the branch,
# compare  to original tree in both rooted and unrooted senses, 
# unrooted comparison should give 1, rooted 0, except for branches to orig. root.
# Then reset root again so as to minimize max distance to leaves from root, and should
# recover original tree. Check that rooted and unrooted compares both give 1.

# $tree = CXGN::Phylo::Parse_newick->new("(A:1, (B:1, C:1):1)")->parse();
$newick_expression = "(A:0.082376,(B:0.196674,((C:0.038209,F:0.354293):0.026742,E:0.094338):0.064142):0.067562,D:0.295612)";
#my $newick_expression = "(A:1,(B:1,((C:2,F:4):1,E:1):2.02):1,D:2)";
#my $newick_expression =  "((A:1, D:2):1, (B:1, C:2, E:3):2)";
#my  $newick_expression = "((A:0.89, D:1.2):1.4, (B:1, C:1.1, E:0.9):1)";
#my $newick_expression = "(C:1, D:3, (A:5, B:2): 1)"; 
#my $newick_expression = "(A:3, ((B:1, C:2):1.5):1)"; 
$tree = CXGN::Phylo::Parse_newick->new($newick_expression)->parse();
ok($tree->test_tree(), "tree test 1");
$tree->get_root()->recursive_collapse_single_nodes();
ok($tree->test_tree(), "tree test 2");


#my ($mldv_node, $mldv_dist_above, $min_var) = $tree->min_leaf_dist_variance_point();
#$tree->reset_root_to_point_on_branch($mldv_node, $mldv_dist_above); 

$tree->reset_root_to_point_on_branch($tree->min_leaf_dist_variance_point()); 
#	print("tree initially rerooted at min variance point, (i.e. before loop): \n");


$tree->get_root()->recursive_implicit_names();
# $tree->get_root()->print_subtree("\n");
# readline stdin;
#$tree->reset_root_min_max_root_leaf_distance();

#my ($anode, $adist, $avar) = $tree->min_leaf_dist_variance_point();
#print("opt node name, dist above, variance, stddev: ", $anode->get_name(), "  ", $adist, "  ", $avar, "  ", sqrt($avar), "\n");
##exit();

my $total_branch_length = subtree_branch_length($tree->get_root());
 $new_tree = $tree->copy();
my ($new_root, $da) = $new_tree->min_leaf_dist_variance_point();
#exit;

my $count_compare_rooted1 = 0;
my $count_compare_unrooted1 = 0;
my $count_compare_rooted2 = 0;
my $count_compare_unrooted2 = 0;
my $count_treetesta_ok = 0;
my $count_treetestb_ok = 0;
my @node_list = $tree->get_root()->recursive_subtree_node_list();

my $max_branch_length_change = -1.0;
my $blc;
my ($comp_rooted1, $comp_unrooted1, $comp_rooted2, $comp_unrooted2) = (-1, -1, -1, -1);

srand(132456);
for (my $i = 0; $i < @node_list; $i++) {
	my $new_tree = $tree->copy();

	my @new_node_list = $new_tree->get_root()->recursive_subtree_node_list();
	my $n = $new_node_list[$i];
	my $small = 0.000001;
	my $dab = ($small +(1.0 - 2*$small)*rand())*$n->get_branch_length();  #random point on ith branch

	$new_tree->reset_root_to_point_on_branch($n, $dab);
	$count_treetesta_ok += $new_tree->test_tree();

	$count_compare_rooted1 += $comp_rooted1 = $tree->compare_rooted($new_tree);	# compare_rooted should be true only for $n a child of $new_tree's root.
	$count_compare_unrooted1 += $comp_unrooted1 = $tree->compare_unrooted($new_tree); # compare_unrooted should be true

#put in some RF distance tests here.

	$blc = abs($total_branch_length - subtree_branch_length($new_tree->get_root()));
	if ($blc > $max_branch_length_change) {
		$max_branch_length_change = $blc;
	}

	#	my ($new_root, $da, $var) = $new_tree->min_leaf_dist_variance_point();
	#	$new_tree->reset_root_to_point_on_branch($new_root, $da);

	$new_tree->reset_root_to_point_on_branch($new_tree->min_leaf_dist_variance_point());
	$count_treetestb_ok += $new_tree->test_tree();

	$count_compare_rooted2 += $comp_rooted2 = $tree->compare_rooted($new_tree);
	$count_compare_unrooted2 += $comp_unrooted2 = $tree->compare_unrooted($new_tree);

	if (!$comp_rooted2 || !$comp_unrooted2) {
		print("tree : \n");
		$tree->get_root()->print_subtree("\n");
		print("new_tree: \n");
		$new_tree->get_root()->print_subtree("\n");
		# exit;
	}

	my $subtree_bl = subtree_branch_length($new_tree->get_root());
	$blc = abs($total_branch_length - $subtree_bl);
	if ($blc > $max_branch_length_change) {
		$max_branch_length_change = $blc;
#		print STDERR "tbl, stbl: $total_branch_length,  $subtree_bl \n";
	}	
}
ok($max_branch_length_change < 5.0e-15*$total_branch_length, "Test that resetting root leaves total branch length unchanged.");
# print($count_compare_rooted1, "  ", $count_compare_unrooted1, "  ", $count_compare_rooted2, "  ", $count_compare_unrooted2, ".\n");
is($count_treetesta_ok,  @node_list, "tree_test ok on trees rooted at random points.");
is($count_treetestb_ok,  @node_list, "tree_test ok on trees rooted at min variance point.");
is($count_compare_rooted1, scalar $tree->get_root()->get_children(), "tree reset_root and compare test 1.");
is($count_compare_unrooted1, @node_list, "tree reset_root and compare test 2.");
is($count_compare_rooted2, @node_list, "tree reset_root and compare test 3.");
is($count_compare_unrooted2, @node_list, "tree reset_root and compare test 4.");

# Test pre- in- post- order traversals.
my $t_tree = (CXGN::Phylo::Parse_newick->new("((((A:1, B:1):1, C:1):1, D:1):1, E:1)"))->parse();

my $preorder_names_by_hand = "node: .\n" . "node: \n" . "node: \n" . "node: \n" . "node: A\n" . "node: B\n"
	. "node: C\n" . "node: D\n" . "node: E\n";
#print STDERR "$preorder_names_by_hand\n";
$t_tree->{node_names} = undef;
$t_tree->preorder_traversal( \&traverse_test_function ); 
my $preorder_names = $t_tree->{'node_names'};
is($preorder_names, $preorder_names_by_hand, "preorder traversal test.");


my $inorder_names_by_hand = "node: A\n" . "node: \n" . "node: B\n" . "node: \n" . "node: C\n" . "node: \n"
        . "node: D\n" . "node: .\n" . "node: E\n";
#print STDERR "$inorder_names_by_hand\n";
$t_tree->{node_names} = undef;
$t_tree->inorder_traversal( \&traverse_test_function );
my $inorder_names = $t_tree->{'node_names'};
is($inorder_names, $inorder_names_by_hand, "inorder traversal test.");


$t_tree->{node_names} = undef;
my $postorder_names_by_hand = "node: A\n" . "node: B\n" . "node: \n" . "node: C\n" . "node: \n" . "node: D\n"
        . "node: \n" . "node: E\n" . "node: .\n";
#print STDERR "$postorder_names_by_hand \n";
$t_tree->postorder_traversal( \&traverse_test_function );
#       print STDERR "after. \n";
        #sub{ my $node = shift; my $str = "node: " . $node->get_name() . "\n";  print STDERR $node->get_name(), "\n"; return $str;} );
my $postorder_names = $t_tree->{'node_names'};
is($postorder_names, $postorder_names_by_hand, "postorder traversal test.");


# Test the species bit hash using a bigger tree
my $species_tree_newick_expression = "( chlamydomonas[species=Chlamydomonas_reinhardtii]:1, ( physcomitrella[species=Physcomitrella_patens]:1, ( selaginella[species=Selaginella_moellendorffii]:1, ( loblolly_pine[species=Pinus_taeda]:1, ( amborella[species=Amborella_trichopoda]:1, ( date_palm[species=Phoenix_dactylifera]:1, ( ( foxtail_millet[species=Setaria_italica]:1, ( sorghum[species=Sorghum_bicolor]:1, maize[species=Zea_mays]:1 ):1 ):1, ( rice[species=Oryza_sativa]:1, ( brachypodium[species=Brachypodium_distachyon]:1, ( (wheat[species=Triticum_aestivum]:1, wheat_x[species=Triticum_aestivum_x]:1):1, barley[species=Hordeum_vulgare]:1 ):1 ):1 ):1 ):1):1):1):1):1):1)";
$species_tree = CXGN::Phylo::Parse_newick -> new($species_tree_newick_expression)->parse();

my $gene_tree_newick_expression = "( chlamydomonas[species=Chlamydomonas_reinhardtii]:1, ( physcomitrella[species=Physcomitrella_patens]:1, ( selaginella[species=Selaginella_moellendorffii]:1, ( loblolly_pine[species=Pinus_taeda]:1, ( amborella[species=Amborella_trichopoda]:1, ( date_palm[species=Phoenix_dactylifera]:1, ( ( foxtail_millet[species=Setaria_italica]:1, ( sorghum[species=Sorghum_bicolor]:1, maize[species=Zea_mays]:1 ):1 ):1, ( rice[species=Oryza_sativa]:1, ( brachypodium[species=Brachypodium_distachyon]:1, ( wheat[species=Triticum_aestivum]:1, barley[species=Hordeum_vulgare]:1 ):1 ):1 ):1 ):1):1):1):1):1):1)";
my $gene_tree = CXGN::Phylo::Parse_newick -> new($gene_tree_newick_expression)->parse();

$gene_tree->show_newick_attribute('species');
my $nwck = $gene_tree->generate_newick(); #print $nwck, "\n";
 
my $spec_bithash = $gene_tree->get_species_bithash($species_tree);
my $spec_bithash_got = '';
	foreach (sort keys %$spec_bithash){
		$spec_bithash_got .= $_ . "   " . $spec_bithash->{$_} . " \n";
}
#print $spec_bithash_got, "\n";

my $spec_bithash_expected = 
"Amborella_trichopoda   1 \n" . 
"Brachypodium_distachyon   2 \n" .
"Chlamydomonas_reinhardtii   4 \n" .
"Hordeum_vulgare   8 \n" .
"Oryza_sativa   16 \n" .
"Phoenix_dactylifera   32 \n" .
"Physcomitrella_patens   64 \n" .
"Pinus_taeda   128 \n" .
"Selaginella_moellendorffii   256 \n" .
"Setaria_italica   512 \n" .
"Sorghum_bicolor   1024 \n" .
"Triticum_aestivum   2048 \n" .
#"Triticum_aestivum_x   4096 \n" .
"Zea_mays   4096 \n";

is($spec_bithash_got, $spec_bithash_expected, "Species bithash test 1.");


$gene_tree_newick_expression = "( chlamydomonas[species=Chlamydomonas_reinhardtii]:1, ( physcomitrella[species=Physcomitrella_patens]:1, ( selaginella_x[species=Selaginella_moellendorffii_x]:1, ( loblolly_pine[species=Pinus_taeda]:1, ( amborella[species=Amborella_trichopoda]:1, ( date_palm[species=Phoenix_dactylifera]:1, ( ( foxtail_millet[species=Setaria_italica]:1, ( sorghum[species=Sorghum_bicolor]:1, maize[species=Zea_mays]:1 ):1 ):1, ( rice[species=Oryza_sativa]:1, ( brachypodium[species=Brachypodium_distachyon]:1, ( wheat[species=Triticum_aestivum]:1, barley[species=Hordeum_vulgare]:1 ):1 ):1 ):1 ):1):1):1):1):1):1)";
$gene_tree = CXGN::Phylo::Parse_newick -> new($gene_tree_newick_expression)->parse();

$gene_tree->show_newick_attribute('species');
$nwck = $gene_tree->generate_newick(); #print $nwck, "\n";
 
$spec_bithash = $gene_tree->get_species_bithash($species_tree);
$spec_bithash_got = '';
	foreach (sort keys %$spec_bithash){
		$spec_bithash_got .= $_ . "   " . $spec_bithash->{$_} . " \n";
}
#print $spec_bithash_got, "\n";

$spec_bithash_expected = 
"Amborella_trichopoda   1 \n" . 
"Brachypodium_distachyon   2 \n" .
"Chlamydomonas_reinhardtii   4 \n" .
"Hordeum_vulgare   8 \n" .
"Oryza_sativa   16 \n" .
"Phoenix_dactylifera   32 \n" .
"Physcomitrella_patens   64 \n" .
"Pinus_taeda   128 \n" .
#"Selaginella_moellendorffii   256 \n" .
"Setaria_italica   256 \n" .
"Sorghum_bicolor   512 \n" .
"Triticum_aestivum   1024 \n" .
#"Triticum_aestivum_x   2048 \n" .
"Zea_mays   2048 \n";

is($spec_bithash_got, $spec_bithash_expected, "Species bithash test 2.");


$gene_tree_newick_expression = "( chlamydomonas[species=Chlamydomonas_reinhardtii]:1, ( physcomitrella[species=Physcomitrella_patens]:1, ( selaginella_x[species=Selaginella_moellendorffii_x]:1, ( loblolly_pine[species=Pinus_taeda]:1, ( amborella[species=Amborella_trichopoda]:1, ( date_palm_x[species=Phoenix_dactylifera_x]:1, ( ( foxtail_millet[species=Setaria_italica]:1, ( sorghum[species=Sorghum_bicolor]:1, maize[species=Zea_mays]:1 ):1 ):1, ( rice[species=Oryza_sativa]:1, ( brachypodium_x[species=Brachypodium_distachyon_x]:1, ( wheat[species=Triticum_aestivum]:1, barley[species=Hordeum_vulgare]:1 ):1 ):1 ):1 ):1):1):1):1):1):1)";
$gene_tree = CXGN::Phylo::Parse_newick -> new($gene_tree_newick_expression)->parse();

$gene_tree->show_newick_attribute('species');
$nwck = $gene_tree->generate_newick(); #print $nwck, "\n";
 
$spec_bithash = $gene_tree->get_species_bithash($species_tree);
$spec_bithash_got = '';
	foreach (sort keys %$spec_bithash){
		$spec_bithash_got .= $_ . "   " . $spec_bithash->{$_} . " \n";
}
#print $spec_bithash_got, "\n";

$spec_bithash_expected = 
"Amborella_trichopoda   1 \n" . 
#"Brachypodium_distachyon   2 \n" .
"Chlamydomonas_reinhardtii   2 \n" .
"Hordeum_vulgare   4 \n" .
"Oryza_sativa   8 \n" .
#"Phoenix_dactylifera   32 \n" .
"Physcomitrella_patens   16 \n" .
"Pinus_taeda   32 \n" .
#"Selaginella_moellendorffii   256 \n" .
"Setaria_italica   64 \n" .
"Sorghum_bicolor   128 \n" .
"Triticum_aestivum   256 \n" .
#"Triticum_aestivum_x   2048 \n" .
"Zea_mays   512 \n";

is($spec_bithash_got, $spec_bithash_expected, "Species bithash test 3.");

exit;


sub subtree_branch_length{
	my $self = shift; # node
	my @node_list = $self->recursive_subtree_node_list();
	my $total_branch_length = 0.0;
	foreach my $n (@node_list) {
		$total_branch_length += $n->get_branch_length();
	}
	return $total_branch_length;
}


sub traverse_test_function{
my $node = shift;
my $tree = $node->get_tree();
#my $new_node_names = (defined $tree->{'node_names'})? $tree->{'node_names'}: '';
#$new_node_names .= "node: [" . $node->get_name() . "]\n"; print STDERR "node: [", $node->get_name(), "]\n";
#$tree->{'node_names'} = $new_node_names;
$tree->{'node_names'} .= "node: " . $node->get_name() . "\n"; 
}



