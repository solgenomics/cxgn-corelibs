
=head1 NAME

CXGN::Sunshine::Browser - a class that implements a network browser for SGN loci.

=head1 DESCRIPTION

=head1 AUTHOR(S)

Lukas Mueller <lam87@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut



use strict;

package CXGN::Sunshine::Browser;

use GD;
use JSON;
use Graph;
use CXGN::DB::Object;
use CXGN::Sunshine::Node;
use CXGN::Phenome::Locus;
#use CXGN::Phenome::Locus2Locus;


use base qw | CXGN::DB::Object |;


our $PI=3.1415692;

=head2 include_on_page

 Usage:        CXGN::Sunshine::Browser->include_on_page("locus", $id)
 Desc:         includes the browser on the respective page
               by including its javascript code
 Ret:          nothing
 Args:         the type of object, and an object id
 Side Effects: prints the browser code to STDOUT
 Example:

=cut

sub include_on_page {


    my $type = shift;
    my $name = shift;


return <<JAVASCRIPT;

<table><tr><td height="450" width="450"><div id=\"network_browser\" >\[loading...\]</div></td><td width="250"><div id="relationships_legend">[Legend]</div><br /><div id="level_selector">[Levels]</div></td></tr></table>

    <script language="javascript" type="text/javascript">
    
//    document.write('HELLO FROM JAVASCRIPT');

    var nb = new CXGN.Sunshine.NetworkBrowser();

    nb.setLevel(2);
    nb.setType('$type');
    nb.setName('$name');
    nb.fetchRelationships();
    //nb.setHiddenRelationshipTypes(''); 
    nb.initialize();



//document.write("....ANOTHER HELLO FROM JS");



</script>

JAVASCRIPT

}



=head2 new

 Usage:        my $browser = CXGN::Sunshine::Browser->new($dbh)
 Desc:         constructor
 Ret:          a CXGN::Sunshine::Browser object
 Args:         a database handle
 Side Effects: connects to the database
 Example:

=cut

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $self = $class->SUPER::new($dbh);

    # set a standard image size
    #
    $self->set_image_width(400);
    $self->set_image_height(400);
    $self->set_level_depth(1);

    $self->set_hide_relationships( () ) ;

    $self->fetch_relationships();

    $self->set_image(GD::Image->new($self->get_image_width(), $self->get_image_height(), 1));
    
    $self->get_image()->filledRectangle(0, 0, $self->get_image_width(), $self->get_image_height(), $self->get_image()->colorAllocate(255, 255, 255));



    return $self;
}

=head2 accessors get_graph, set_graph

 Usage:        $b->set_graph($graph)
 Desc:         The Graph object that this instance should
               work with.
 Property      a L<Graph> object
 Side Effects: 
 Example:

=cut

sub get_graph {
  my $self = shift;
  return $self->{graph}; 
}

sub set_graph {
  my $self = shift;
  $self->{graph} = shift;
}


=head2 build_graph

 Usage:        $b->build_graph($ref_node_name, $ref_node_type, $graph)
 Desc:         builds the graph $graph for node ref_node_name, and the 
               type $type.
 Ret:          nothing
 Args:
 Side Effects: the graph $graph is modified and database access is possible
               for certain types.
 Example:

=cut

sub build_graph {
    my $self = shift;
    my $ref_node_name = $self->get_ref_node_name();
    my $ref_node_type = $self->get_ref_node_type();

    my $graph = Graph::Undirected->new();

    # recursively get all the connection to the reference node.
   
    $self->d("TYPE IS $ref_node_type. NAME IS $ref_node_name.\n");
    if ($ref_node_type eq "test") { 
#	$self->d("Getting test data...\n");
	$self->get_test_graph($graph);
    }
    elsif ($ref_node_type eq "locus") { 
	$self->d("GETTING LOCUS INFORMATION...\n");
	$self->get_locus_graph($ref_node_name, $graph, $self->get_level_depth());
    }
    $self->set_graph($graph);
}


=head2 get_locus_graph

 Usage:        called by build_graph() if graph type is 'locus'.
 Desc:         builds a graph in the Graph object (a Perl class).
 Ret:          nothing, but changes the datastructure in graph.
 Args:         a locus_id [int], a graph [Graph], and level [int]
               the level will determine how 'deep' the graph will be.
 Side Effects: 
 Example:

=cut

sub get_locus_graph { 
    my $self = shift;
    my $locus_id = shift;
    my $graph = shift;
    my $max_level = shift;
    
    my $reference_locus = CXGN::Phenome::Locus->new($self->get_dbh(), $locus_id);
    my $reference_node = CXGN::Sunshine::Node->new($locus_id);

    $reference_node->set_name($reference_locus->get_locus_symbol());
    $reference_node->set_unique_id($locus_id);
    
    $self->add_node_list($reference_node);


    my (@loci) = ($locus_id);
    my (@related_loci);
    my %already_processed = ( );
    my %loci_cache = ();
#    my %associations = ();
    my @loci_list = ();
    my %relationship_cache = ();

    my $level = 1;

    my %loci_list = ();
    my $continue = 1;
#    foreach my $l (1..($level)) { 
#	$self->d("PROCESSING LEVEL $l...\n");
    while ($continue) { 

	foreach my $r (@loci) {
	    %loci_list =();
	    #$self->d("...processing locus $r\n");

	    if (exists($already_processed{$r})) { # ||
		#( $r == $reference_node && $level ==1)) { 
		$self->d("......this locus was already processed. Skipping.\n");
		next; 
	    }

	    if (! exists($loci_cache{$r})) { 
		$loci_cache{$r}  = CXGN::Phenome::Locus->new($self->get_dbh(), $r);
	    }
	    

	    #######my @object_loci = $loci_cache{$r}->get_object_locus2locus_objects();
	    my @locus_groups= $loci_cache{$r}->get_locusgroups();
	    
#	    print STDERR "HIDDEN RELTYPES: ".(join ", ", ($self->get_hide_relationships()));
#	    print STDERR "\n";
	

	    # go through all loci and build a list with some meta information
	    #
	   
	    my %all_groups=();
	    
	    foreach my $group (@locus_groups) {
		if (!$self->relationship_hidden($group->get_relationship_id())) { 
		    my @members=$group->get_locusgroup_members();
		    $all_groups{ $group->get_locusgroup_id() } =  $group;
		    foreach my $member(@members) {
			my $member_id = $member->get_column('locus_id');
			my $member_locus=CXGN::Phenome::Locus->new($self->get_dbh(), $member_id);
			my @member_groups = $member_locus->get_locusgroups();
			foreach my $mg (@member_groups) {
			    if (!defined $all_groups{ $mg->get_locusgroup_id() } ) { 
				$all_groups{ $mg->get_locusgroup_id } = $mg;
			    }
			}
		    }
		}else { 
		    $self->d("Relationship ".($group->get_relationship_id())." currently hidden!\n");
		}
	    }
	    foreach my $locusgroup_id( keys %all_groups ) {
		my $group= $all_groups{$locusgroup_id};
		if (!$self->relationship_hidden($group->get_relationship_id())) { 
		    
		    my @members=$group->get_locusgroup_members();
		    foreach my $member (@members) {
			my $member_id = $member->get_column('locus_id');
			if ($member_id == $locus_id) { next() ; } 
			my @list = ($member->get_column('locus_id'), $group->get_relationship_id());
			$loci_list{ join "-", @list } = \@list;
		    }
		}
	    }
	    
	    foreach my $a (values %loci_list) { 
		
		
		if (!exists($loci_cache{$a->[0]})) { 
		    $loci_cache{$a->[0]} = CXGN::Phenome::Locus->new($self->get_dbh(), $a->[0]);
		    
		}
		
		if (!defined($loci_cache{$a->[0]}->get_locus_id())) { 
		    #    die "The locus (".($a->[0]).") is not defined... Skipping.\n";
		    next();
		}
		
		my $node = CXGN::Sunshine::Node->new($loci_cache{$a->[0]}->get_locus_id());
		
		$node->set_level($level);
		$node->set_name($loci_cache{$a->[0]}->get_locus_symbol());
		$self->add_node_list($node);
		
		$node->set_unique_id($loci_cache{$a->[0]}->get_locus_id());
		
		
		
		$graph->add_vertex($loci_cache{$a->[0]}->get_locus_id());
		
		if (!exists($loci_cache{$r}) || !defined($loci_cache{$r}->get_locus_id())) { 
		    die  "Locus $r does not exist... \n";
		    #next();
		}
		
		# check if either of the nodes fall outside of the currently viewable levels
		#
		if ($level <= ($max_level) || $self->get_node($loci_cache{$a->[0]}->get_locus_id())->get_level() <=$max_level) { 
		    $self->d("Generating the edge from ".($loci_cache{$a->[0]}->get_locus_symbol())." and ".($loci_cache{$r}->get_locus_symbol())."\n");
		    $graph->add_edge($loci_cache{$r}->get_locus_id(), $loci_cache{$a->[0]}->get_locus_id()); 
		    $graph->set_edge_attribute($loci_cache{$r}->get_locus_id(), $loci_cache{$a->[0]}->get_locus_id(), "relationship_type", $a->[1]);
		}
	    }
	    $already_processed{$r}=1;		
	}
	
	$continue = @loci != values(%loci_list);
	$level++;
	
	@loci =  map { $_->[0] } values(%loci_list) ;
    }
}

=head2 fetch_relationships

 Usage: my $json = $b->fetch_relationships()
 Desc:         retrieves all relationship ids from the database (cvterms)
               and returns them as a json string.
 Ret:
 Args: none
 Side Effects:
 Example:

=cut


sub fetch_relationships {
    my $self = shift;
    my $q = "SELECT distinct(cvterm_id), locusgroup.locusgroup_id FROM phenome.locusgroup JOIN cvterm on(locusgroup.relationship_id=cvterm_id)";
    my $h = $self->get_dbh()->prepare($q);
    $h->execute();
   
    while (my ($cvterm_id, $lg_id) = $h->fetchrow_array()) { 
	$self->{relationship_ids}->{$lg_id}= CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    }
}


=head2 get_relationship_menu_info

 Usage:     
 Desc:      
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_relationship_menu_info { 
    my $self = shift;
    my $q = "SELECT DISTINCT(relationship_id), cvterm_id FROM phenome.locusgroup JOIN public.cvterm on (locusgroup.relationship_id=cvterm_id)";
    my $h = $self->get_dbh()->prepare($q);
    $h->execute();
    my @relationship_menu_info = ();
    while (my ($relationship_id, $cvterm_id) = $h->fetchrow_array()) { 
	my $cvterm = CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
	push @relationship_menu_info, {"id"=>$relationship_id, "name"=>$cvterm->get_cvterm_name(), "color"=>join(",",$self->get_relationshiptype_color($relationship_id))};
    }

    
    my $json = JSON->new();
    my $jobj = $json->objToJson(\@relationship_menu_info);
    return $jobj;
}

=head2 relationship_hidden

 Usage:        my $hidden = $b->relationship_hidden($relationship_id)
 Desc:         returns true if the relationship with relationship_id 
               $relationship_id is hidden, false otherwise.
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub relationship_hidden {
    my $self = shift;
    my $id = shift;
    foreach my $r ($self->get_hide_relationships()) { 
	if ($r == $id) { 
	    return 1;
	}
    }
    return 0;
}


=head2 accessors get_hide_relationships, set_hide_relationships

 Usage:        $b->set_hide_relationships($relationship_id1, ... )
 Desc:         the relationships with $relationship_id1 and other 
               listed relationships will not be shown on the browser.
 Property    
 Side Effects: the specified list of relationship types will be 
               hidden in the browser. The list of relationship types
               will have the corresponding relationships unchecked.
 Example:

=cut

sub get_hide_relationships {
  my $self = shift;
  return @{$self->{hide_relationships}};
}

sub set_hide_relationships {
  my $self = shift;
  @{$self->{hide_relationships}} = @_;
}

sub get_pathway_graph { 
    my $self = shift;
    my $graph = shift;
    
    open (F, "data/lycocyc_dump.txt");

    while (<F>) { 
	chomp;
	my ($pathway, $ec, $reaction, $unigene) = split /\t/;

    }
    
}


sub get_test_graph { 
    my $self = shift;
    my $graph = shift;
    
    my @connections = ();

    my $center = CXGN::Sunshine::Node->new("0");
    $self->add_node_list($center);
    for my $i (1..5) { 
	$connections[$i] = CXGN::Sunshine::Node->new($i);

	$self->add_node_list($connections[$i]);
	$graph->add_vertex($i);

	$graph->add_edge($i, $center->get_unique_id());
	if ($i>1)  { $graph->add_edge($i, $i-1);}
    }

    for my $i (6..10) { 
	$connections[$i] = CXGN::Sunshine::Node->new($i);
	$self->add_node_list($connections[$i]);
	$graph->add_vertex($i);
	$graph->add_edge($i, $i-5);
    }
}

# =head2 get_locus2locus_connections

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_locus2locus_connections { 
#     my $self = shift;
#     my $graph = shift;
#     my $node = shift;
#     my @connections = $node->get_associated_loci();
#     $graph->add_vertex($node->get_locus_id());
#     $self->add_node_list($node);
    
#     my @more_connections = ();
#     foreach my $c (@connections) { 
# 	 @more_connections = $self->get_locus2locus_connections($graph, $c);
#     }
#     @connections = (@connections, @more_connections);
#     return @connections;
# }

=head2 add_node_list

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub add_node_list { 
    my $self = shift;
    my $node = shift;
    if (exists($self->{nodes}->{$node->get_unique_id()})) { 
	#warn "Node named ".$node->get_unique_id()." already exists!";
	return 1;
    }
    $self->{nodes}->{$node->get_unique_id()}=$node;
}

=head2 get_node_list

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_node_list { 
    my $self = shift;
    return values(%{$self->{nodes}});
}

=head2 get_node

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_node { 
    my $self  =shift;
    my $id = shift;
    return $self->{nodes}->{$id};
}


=head2 get_level_depth, set_level_depth

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_level_depth {
  my $self=shift;
  return $self->{level_depth};

}

sub set_level_depth {
  my $self=shift;
  $self->{level_depth}=shift;
}

=head2 accessors get_reference_object, set_reference_object

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_reference_object {
  my $self = shift;
  return ($self->{reference_object_id}, $self->{reference_object_type});
}

sub set_reference_object {
  my $self = shift;
  my $id = shift;
  my $type = shift;
  $self->{reference_object_id} = $id;
  $self->{reference_object_type} = $type;
}


=head2 accessors get_reference_node, set_reference_node

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_reference_node {
  my $self = shift;
  return $self->{reference_node}; 
}

sub set_reference_node {
  my $self = shift;
  my $node = shift;
  
  # return an error if the node is not part of the graph
  if (!exists($self->{nodes}->{$node->get_unique_id()})) { 
      return 1;
  }
  $self->{reference_node} = $node;
  
}



=head2 generate_page

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub generate_page { 
    my $self = shift;
    my $image = shift;
    
    
}

=head2 layout

 Usage:        $b->layout()
 Desc:         lays out the graph
 Ret:          nothing
 Args:         none

=cut

sub layout {
    my $self = shift;
    
    # get the smaller dimension
    my $dimension = $self->get_image_height();
    if ($self->get_image_width() < $self->get_image_height()) { 
	$dimension = $self->get_image_width();
    }

    # define the positions of all the other nodes.
    my $radius = $dimension / $self->get_level_depth() / 2.5;
    $self->set_radius($radius);
    my @n = $self->get_graph()->neighbours($self->get_reference_node()->get_unique_id());

    $self->d("Checking graph...\n");
    foreach my $n (@n) { 
	$self->d("Retrieved neighbour $n\n");
	if ($n eq $self->get_reference_node()->get_unique_id()) { 
	    die "The reference node is among the linked nodes, you fool!\n";
	}
    }

    $self->calculate_nodes_by_level();

    # define the position of the reference node
    #
    $self->get_reference_node()->set_X(int($self->get_image_width()/2));
    $self->get_reference_node()->set_Y(int($self->get_image_height()/2));
    
    # deal with the nodes on the other levels
    #
    foreach my $level (0..$self->get_level_depth()) { 

	my @n = $self->get_nodes_by_level($level);

	#print STDERR "Layout: level $level, laying out nodes ".(join " ", @n)."\n";

	for (my $i=0; $i<@n; $i++) { 

	    # calculate the angle as the circumference of the circle divided by n,
            # and adding a little offset to each level so that we don't get
            # exact alignments on the same grid (lines cross too much and make 
            # the whole picture less clear)
	    #
	    my $angle = (2 * $PI * $i + $level * $level * 0.1 * $PI )/ scalar(@n); # 
	    my ($x, $y) = $self->deg2coords($radius * $level, $angle);
	    
	    $self->get_node($n[$i])->set_X($x + int($self->get_image_width()/2));
	    $self->get_node($n[$i])->set_Y($y + int($self->get_image_height()/2));
	    #print STDERR "Node $i:\n";
	    #print STDERR "X: ".$self->get_node($n[$i])->get_X()."\n";
	    #print STDERR "Y: ".$self->get_node($n[$i])->get_Y()."\n";
	}
    }
}

				       
=head2 calculate_nodes_by_level

 Usage:        $b->calculate_nodes_by_level()
 Desc:         calculates which nodes are on which level 
               the levels are defined as containing loci with
               direct relationships to the previous level. Level 0
               is the reference entity.
               The nodes on each level calculated here can be 
               retrieved using get_nodes_by_level() (see below).
 Ret:          nothing
 Args:         none
 Side Effects:
 Example:

=cut

sub calculate_nodes_by_level {
    my $self = shift;
    
    my $level = $self->get_level_depth();

    my $ref = $self->get_reference_node()->get_unique_id();

    my %previous_level_nodes = ($ref => 1);
    
    my @level_nodes = (); # an array for each level, containing a hash for the elements
    
    $level_nodes[0]->{$ref} =1;
    
    foreach my $l (1..$level) { 
	#print STDERR "Generating the unique nodes for level $l...\n";

	foreach my $n (keys (%{$level_nodes[$l-1]})) { 
	    foreach my $neighbor ($self->get_graph()->neighbours($n)) { 
		#print STDERR "NEIGHBOR of $n is $neighbor\n";
		$level_nodes[$l]->{$neighbor}=1;
	    }
	}
	
	# remove the nodes that occur in the previous levels
	foreach my $k (keys %previous_level_nodes) { 
	    if (exists($level_nodes[$l]->{$k})) { 
		delete($level_nodes[$l]->{$k});
	    }
	}

# 	# add this level to the previous level nodes
# 	# to exclude relationships in the next iteration
 	foreach my $k (keys(%{$level_nodes[$l]})) { 
 	    $previous_level_nodes{$k}=1;
 	}

    }
    $self->{nodes_by_level} = \@level_nodes;
    %{$self->{all_nodes}} = %previous_level_nodes;

    # reorder the current level of the graph such that nodes with 
    # connections to nodes of the previous level are close the those
    # nodes
    #
   
   #  foreach my $l (0..$level-1) { 
# 	#foreach my $x (1..2) { 
# 	if ($l>=1) { 
# 	    for(my $m=0; $m<@{$nodes->[$l]}; $m++) { 
# 		for (my $n=0; $n<@{$nodes->[$l]}; $n++) { 
# 		    if ($self->get_graph()->has_edge($nodes->[$l]->[$m], 
# 						     $nodes->[$l+1]->[$n]
# 						     && ($n !=$m ))) { 
# 			print STDERR "Swapping nodes $nodes->[$l]->[$m] and $nodes->[$l]->[$n]...\n";
# 			($nodes->[$l]->[$n], $nodes->[$l]->[$m]) = 
# 			    ($nodes->[$l]->[$m], $nodes->[$l]->[$n]);
			
# 		    }
# 		}
# 		@{$self->{nodes_by_level}->[$l]}=@{$nodes->[$l]};
# 	    }
	    
# 	}
#     }
}


=head2 get_nodes_by_level

 Usage:        my @nodes = $b->get_nodes_by_level($level)
 Desc:         returns the nodes that belong to level $level.
 Ret:          a list of CXGN::Sunshine::Node objects
 Args:         a level [int]

=cut



sub get_nodes_by_level { 
    my $self = shift;
    my $level = shift;
    if (!exists($self->{nodes_by_level}->[$level])) { 
	$self->{nodes_by_level}->[$level] = {};
    }
    return keys %{$self->{nodes_by_level}->[$level]};
}

=head2 accessors get_previously_clicked_nodes, set_previously_clicked_nodes

 Usage:         [not yet implemented]
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_previously_clicked_nodes {
  my $self = shift;
  return @{$self->{previously_clicked_nodes}};
}

sub set_previously_clicked_nodes {
  my $self = shift;
  @{$self->{previously_clicked_nodes}} = @_;
}

=head2 accessors get_hilited_nodes, set_hilited_nodes

 Usage:        [ not yet implemented]
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_hilited_nodes {
  my $self = shift;
  return $self->{hilited_nodes}; 
}

sub set_hilited_nodes {
  my $self = shift;
  $self->{hilited_nodes} = shift;
}

=head2 function get_relationshiptype_color()

 Usage:        ($r, $g, $b) = $b->get_relationshiptype_color($rel)
 Desc:         returns the color in red, green and blue components
               used for the relationshiptype given by $rel.
 Ret:          three values defining a color
 Args:         the relationshiptype_id [int]

=cut

sub get_relationshiptype_color {
    my $self = shift;
    my $relationship_id = shift;
    
    
    my %color = ( 39638 => [ 255, 0, 0 ],
		  39639 => [ 0, 255, 0 ],
		  39640 => [ 0, 0, 255 ],
		  39642 => [ 255, 255, 0 ],
		  39649 => [ 0, 255, 255 ], 
		  39650 => [ 255, 0, 255 ],
		  );
    if (!defined($color{$relationship_id})) { return (0, 0, 0); }
    return @{$color{$relationship_id}};
}



=head2 function render()

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub render {
    my $self = shift;

    my $reference_node = $self->get_reference_node();
    $reference_node->render($self->get_image());

    my $gray = $self->get_image()->colorAllocate(200,200,200);
    my $black = $self->get_image()->colorAllocate(0, 0, 0);
    my $blue = $self->get_image()->colorAllocate(0, 0, 255);

    my @include_nodes = ();
    foreach my $level (0..$self->get_level_depth()) { 
	my @nodes = $self->get_nodes_by_level($level);
    }

    my @edges = $self->get_graph()->edges();
    foreach my $c (@edges) { 
	
	my ($start, $end) = ($c->[0], $c->[1]);
	
	my $start_node = $self->get_node($start);
	my $end_node = $self->get_node($end);
	    
	if (!$start_node || !$end_node) { 
	    die "$start and /or  $end don't exist!\n";
	    
	}
	my $relationship_id = $self->get_graph()->get_edge_attribute($start_node->get_unique_id(), $end_node->get_unique_id(), "relationship_type");
	#print STDERR "RELATIONSHIP_ID = $relationship_id\n";
	
	
	
	my $color = $self->get_image()->colorAllocate($self->get_relationshiptype_color($relationship_id ));
	$self->get_image()->setAntiAliased($color);
	$self->get_image()->line($start_node->get_X(), 
				 $start_node->get_Y(), 
				 $end_node->get_X(), 
				 $end_node->get_Y(),
				 gdAntiAliased);
    
    }
    
    foreach my $level (0..$self->get_level_depth()) { 
	#print STDERR "Rendering level $level...\n";
	

	$self->get_image->arc($self->get_reference_node()->get_X(),
			      $self->get_reference_node()->get_Y(),
			      2 * $level * $self->get_radius(),
			      2 * $level * $self->get_radius(),
			      0,
			      360,
			      $gray
			  
		);

	foreach my $n ($self->get_nodes_by_level($level)) { 
	    my $node = $self->get_node($n);
	    my $unique_id = $node->get_unique_id();
	    my $ref_node_type = $self->get_ref_node_type();
	    my $show_levels = $self->get_level_depth();
	    my $hidden_relationships = join ", ", $self->get_hide_relationships();
	    if (!$hidden_relationships) { $hidden_relationships=0; }
	    $node->set_url("javascript:nb.getImage($unique_id, '$ref_node_type' , $show_levels, $hidden_relationships)");
	    #print STDERR " [$level]: node node\n";
	    $node->render($self->get_image());
	}
	
    }
    
}


sub get_image_map { 
    my $self = shift;
    my $map_name = shift;

    my $map = qq { <map name="$map_name" > };
    foreach my $n ($self->get_node_list()) { 
	$map .= $n->get_image_map() ."\n";
    }
    $map .= qq { </map>\n };
    return $map; 
}

sub render_string { 
    my $self =shift;
    $self->render();
    
    return $self->get_image()->png();
}
    
sub render_png { 
    my $self = shift;
    my $filename = shift;
    
    $self->render();
    my $png = $self->get_image->png();

    open (my $F, ">$filename") || die "Can't open $filename"; 
    print F $png;
    close(F);
}

=head2 accessors get_radius, set_radius

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_radius {
  my $self = shift;
  return $self->{radius}; 
}

sub set_radius {
  my $self = shift;
  $self->{radius} = shift;
}

=head2 accessors get_image_width, set_image_width

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_image_width {
  my $self = shift;
  return $self->{image_width}; 
}

sub set_image_width {
  my $self = shift;
  $self->{image_width} = shift;
}

=head2 accessors get_image_height, set_image_height

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_image_height {
  my $self = shift;
  return $self->{image_heigth}; 
}

sub set_image_height {
  my $self = shift;
  $self->{image_heigth} = shift;
}


=head2 accessors get_image, set_image

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_image {
  my $self = shift;
  return $self->{image}; 
}

sub set_image {
  my $self = shift;
  $self->{image} = shift;
}

=head2 deg2coords

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub deg2coords { 
    my $self = shift;
    my $radius = shift;
    my $degrees = shift;

    my $x = sin($degrees)* $radius;
    my $y = cos($degrees)* $radius;

    return ($x, $y);

}

=head2 accessors get_ref_node_name, set_ref_node_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_ref_node_name {
  my $self = shift;
  return $self->{ref_node_name}; 
}

sub set_ref_node_name {
  my $self = shift;
  $self->{ref_node_name} = shift;
}

=head2 accessors get_ref_node_type, set_ref_node_type

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_ref_node_type {
  my $self = shift;
  return $self->{ref_node_type}; 
}

sub set_ref_node_type {
  my $self = shift;
  $self->{ref_node_type} = shift;
}


return 1;
