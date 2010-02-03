#!/usr/bin/perl

use strict;
use File::Temp; 

use CXGN::Phylo::Configuration;

package CXGN::Phylo::Tree_browser;

sub new { 
    my $class = shift;
	my $directives = shift;

    my $args= {};
    my $self = bless $args, $class;
    
    # set the default using the setter functions
    #
    $self->set_tree(undef);
	#want this to work outside of mod_perl: (ccarpita)
	unless($directives->{no_apache}){
	    $self->set_temp_file(undef);
	}
    $self->set_temp_url(undef);
    $self->set_tree_string(undef);
    $self->set_temp_dir(undef);
    $self->set_hilite(0);
    
    # build the function hash
    #
    $self->add_code_table("r", "function_rotate_node", 2);
    $self->add_code_table("h", "function_hide_node", 2);
    $self->add_code_table("s", "function_prune_to_subtree", 1);
    $self->add_code_table("t", "function_reset_root", 1);

    return $self;
}

=head2 function get_tree()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_tree { 
    my $self=shift;
    return $self->{tree};
}

=head2 function set_tree

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_tree { 
    my $self=shift;
    $self->{tree}=shift;
}

sub create_temp_file { 
    my $self = shift;
    
    my $tempdir = $self->get_temp_dir();
    #print STDERR "TEMPDIR: $tempdir\n";
    my ($tempfh, $tempfile) = File::Temp::tempfile("tree-XXXXXX", DIR=>$tempdir);
    print $tempfh $self->get_tree_string();
    $tempfh->close();
    
    my $temp_url = $tempfile;
    $temp_url =~ s/.*(tempfiles.*$)/$1/;
    
    $temp_url = "/documents/$temp_url";

    $self->set_temp_url($temp_url);
    $self->set_temp_file($tempfile);

    return ($tempfile, $temp_url);
}

sub read_temp_file { 
    my $self = shift;

    my $file_contents="";

    if( open my $fh, $self->get_temp_file() ) {
      while (<$fh>) { 
	chomp;
	$file_contents .= $_;
      }
      close $fh;
    }

    $self->set_tree_string($file_contents);
}


=head2 function get_temp_url()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_temp_url { 
    my $self=shift;
    if (!$self->{temp_url}) { 
	my $url = $self->get_temp_file();
	$url = File::Basename::basename($url);
	$url = "/documents/tempfiles/tree_browser/$url";
	$self->{temp_url}=$url;
    }
    return $self->{temp_url};
}

=head2 function set_temp_url()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_temp_url { 
    my $self=shift;
    $self->{temp_url}=shift;
}

=head2 function get_temp_file()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_temp_file { 
    my $self=shift;

    my $tf = $self->{temp_file};

    print STDERR "in Tree_browser::get_temp_file(), temp_file: [", $tf, "]\n";

    return $self->{temp_file};
}

=head2 function set_temp_file()

  Synopsis:	$browser->set_temp_file($filename);
  Arguments:	a valid filename
  Returns:	nothing
  Side effects:	tries to read the tree string from $filename
                and sets it using set_tree_string()
  Description:	

=cut

sub set_temp_file { 
    my $self=shift;
    $self->{temp_file}=shift;
    if (!$self->get_tree_string()) { $self->read_temp_file(); }
}

=head2 function get_tree_string()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_tree_string { 
    my $self=shift;
    return $self->{tree_string};
}

=head2 function set_tree_string()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_tree_string { 
    my $self=shift;
    $self->{tree_string}=shift;
}

=head2 function get_temp_dir

  Synopsis:	
  Arguments:	none
  Returns:	a temp directory. If the directory was not set using 
                set_temp_dir(), it tries to come up with a good guess.
  Side effects:	the temp_dir property is used to write the temporary files
                to. If it is not correct, the browser won\'t work.
  Description:	

=cut

sub get_temp_dir { 
    my $self=shift;
    
    if (!exists($self->{temp_dir}) || !$self->{temp_dir}) { 
	$self->{temp_dir} = CXGN::Phylo::Configuration->new()->get_temp_dir();
    }
    return $self->{temp_dir};
}

=head2 function set_temp_dir

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_temp_dir { 
    my $self=shift;
    $self->{temp_dir}=shift;
}

=head2 function recursive_manage_labels()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub recursive_manage_labels { 
    my $self = shift;
    my $node = shift;
    
    # check the shortest branch length on this node
    #
    my $shortest = 1e200;
    foreach my $c ($node->get_children()) { 
	if ($c->get_branch_length() < $shortest) { 
	    $shortest=$c->get_branch_length();
	}
    }
    # 
    my $scaling_factor = $self->get_tree()->get_layout()->get_horizontal_scaling_factor();
    if ( ($shortest * $scaling_factor) > (length($node->get_name())*5) )  {
	$node->get_label()->set_hidden(0);
    }
    elsif ($node->get_hilited()) { 
	$node->get_label()->set_hidden(0);
    }
    elsif ($node->is_leaf()) { 
	$node->get_label()->set_hidden(0);
    }
    elsif ($node->get_label()->get_hilite()) { 
	$node->get_label()->set_hidden(0);
    }
    elsif ($node->get_hidden()) {
	$node->get_label()->set_hidden(0);
    }
    else { 
	$node->get_label()->set_hidden(1);
    }

    foreach my $c ($node->get_children()) { 
	$self->recursive_manage_labels($c);
    }

}
	



=head2 function get_hilite

  Synopsis:	
  Arguments:	
  Returns:	the node key (NOT a node object) of the hilited node
  Side effects:	
  Description:	

=cut

sub get_hilite { 
    my $self=shift;
    return $self->{hilite};
}

=head2 function set_hilite

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_hilite { 
    my $self=shift;
    my $hilite = shift;
    
    # if hilite is undefined, everything will be hilited,
    # which is not the desired behavior.
    #
    if (!defined($hilite)) { $hilite=""; }

    $self->{hilite}=$hilite;
}

sub get_node_operations { 
    my $self=shift;
    if (!exists($self->{node_operations})) { @{$self->{node_operations}}=(); }
    return @{$self->{node_operations}};
}

=head2 function toggle_node_operation()

  Synopsis:	 $a_tree_browser->toggle_node_operation($the_operation);
  Arguments:	A node operation. 
  Returns:	
  Side effects:	 Removes the operation from the node_operation list, if initially present,
      and pushes in onto the list if not initially present.
  Description:	node operations have to be played back in the same order 
                as they were generated by the user. The node operations 
                are therefore stored in an array. (in a first version,
                they were stored in a hash which caused play back problems).

=cut

sub toggle_node_operation {
	my $self=shift;
	my $operation = shift;
	if (!exists($self->{node_operations})) { #initialize node operations array to empty list
		@{$self->{node_operations}}=();
	}
	my $exists = 0;
	for (my $i=0; $i<@{$self->{node_operations}}; $i++) { # loop over node operations in the list
		if (${$self->{node_operations}}[$i] =~ /^$operation$/i) {
			$exists=1;
			splice @{$self->{node_operations}}, $i, 1;		
		}
	}
	if (!$exists) {
		push @{$self->{node_operations}}, $operation;
	}
}

sub add_code_table {
    my $self = shift;
    my $code = shift;
    my $function = shift;
    my $priority = shift;
    ${$self->{op_code}}{$code}=$function;
    ${$self->{op_code_priority}}{$code}=$priority;
}
    
sub get_code_table { 
    my $self = shift;
    my $code = shift;
	return unless $code;
    my $function;
    if (exists(${$self->{op_code}}{$code})) { 
	return (${$self->{op_code}}{$code}, ${$self->{op_code_priority}}{$code});
    }
    else { 
	print STDERR "tree_browser.pm: $code is not a recognized function.\n";
	return undef;
    }
}

=head2 function play_back_operations()

  Synopsis:	$browser->play_back_operations();
  Arguments:	none
  Returns:	nothing
  Side effects:	takes the operations as set by set_node_operations() and 
                executes the commands on the tree data structure. 
                It is important that the operations are played back in the
                exact order they were initiated by the user.
  Description:	

=cut

sub play_back_operations { 
    my $self  = shift;

    my @node_operations = $self->get_node_operations();
    #print STDERR "Operations: ".(join "|", @node_operations)."\n";

    foreach my $priority (1, 2) { 
	foreach my $operation (@node_operations) { 
	    my $code=""; my $node_key=0;
	    if ($operation =~ m/([a-z]+)(\d+)/i) { 
		$code=$1;
		$node_key=$2;
	    }
	    
	    #print STDERR "OPERATION: $code ON NODE $node_key\n";
	    my $node = $self->get_tree()->get_node($node_key);
	    
	    if ($code && !$self->get_code_table($code)) { print STDERR "Operation $code is undefined!\n"; next; }
	    my ($operation_sub, $operation_priority) = $self->get_code_table($code);
	    #print STDERR "Executing function $code on node $node_key\n";
	    if ($node)  { 
		if ($priority == $operation_priority)  { 
		    $self->$operation_sub($node);  
		}
	    }
	}
    }
    
    # recalculate tree parameters
    #
    $self->get_tree()->regenerate_node_hash($self->get_tree()->get_root());
    $self->get_tree()->get_root()->calculate_distances_from_root();
    
    $self->get_tree()->calculate_leaf_list();
    $self->get_tree()->get_root()->recursive_propagate_properties();
    
}

sub function_rotate_node { 
    my $self = shift;
    my $node = shift;
    #print STDERR "sub function_rotate_node: Rotating node: ".$node->get_node_key()."\n";
    $node->rotate_node();
}

sub function_hide_node { 
    my $self = shift;
    my $node = shift;
    $node->set_hidden(1);
}

sub function_prune_to_subtree { 
    my $self = shift;
    my $node = shift;
    $self->get_tree->prune_to_subtree($node);
}

sub function_reset_root { 
    my $self = shift;
    my $node = shift;
    $self->get_tree()->reset_root($node);
}

	
1;

