package CXGN::Phylo::TreePlus;

use base qw/ CXGN::Phylo::Tree /;

=head1 NAME

CXGN::Phylo::TreePlus

=head1 SYNOPSIS

This is a subclass of Tree that has more advanced 
functionality, such as a BayesTraits method

=cut
use strict;
use CXGN::Tools::Cluster::BayesTraits;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $tree = CXGN::Phylo::Tree->new(@_);
	while(my ($k, $v) = each %$tree){
		$self->{$k} = $v;
	}
	return $self;	
}

=head2 function calculate_bayes_traits()

 Args: List of trait names, numerically valued attributes of leaf nodes
 Ret: Nothing
 Effect:  Runs a BayesTraits Cluster process on all nodes, determining
          ancestral characteristics and setting attributes at each node

=cut

sub calculate_bayes_traits {
	my $self = shift;
	my @trait_names = @_;

	my @leaves = $self->get_leaf_list();
	
	my $data = {};

	foreach my $l (@leaves){
		my $id = $l->get_name();
		my $traits = {};
		foreach my $tn (@trait_names){
			my $v = $l->get_attribute($tn);
			$v ||= "-";
			$traits->{$tn} = $v;	
		}
		$data->{$id} = $traits;
	}

	my $binary_tree = $self->copy();
	$binary_tree->make_binary();
	
	my $proc = CXGN::Tools::Cluster::BayesTraits->new({ 
					tree => $binary_tree, 
					data => $data,
					model => "continuous",
					auto_mla => 1,
					all_nodes => 1
					});
	
	$proc->add_command("delta", "lambda", "kappa");

	$proc->submit();
	$proc->spin();

	my $results = $proc->results();

	while(my ($node_key, $value_hash) = each %$results){
		my $node = $self->get_node($node_key);
		foreach my $tn (@trait_names){
			$node->set_attribute($tn, $value_hash->{$tn});
			$node->set_attribute($tn . "_var", $value_hash->{$tn . "_var"});
			$node->set_attribute("bayes_lh", $value_hash->{likelihood});
		}
	}
}


1;
