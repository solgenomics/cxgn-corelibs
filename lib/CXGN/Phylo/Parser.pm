=head1 Package CXGN::Phylo::Abstract_tree_parser

Essentially implements a tree parsing interface. There should be at least two functions: new() and parse().

=cut

use strict; 
use URI::Escape;

use CXGN::Phylo::Tree;
use CXGN::Phylo::Node;

package CXGN::Phylo::Abstract_tree_parser;

=head2 function new()

  Synopsis:	constructor of abstract class
  Arguments:	none
  Returns:	(should not be instanciated).
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $args = {};
    my $self = bless $args, $class;
    return $self;
}

=head2 function parse()

  Synopsis:	abstract function parse
  Arguments:	if subclassed, parseshould take a string as an 
                argument that it parses
  Returns:	a tree data structure as a Tree object
  Side effects:	parses the tree data in string and generates the
                Tree data.
  Description:	

=cut

sub parse { 
    my $self = shift;
    
}

=head1 Package CXGN::Phylo::Parse_newick

A parser for newick formatted tree files.
Generates a tree object when parse() is called.
Inherits from Abstract_tree_parser.

=cut

package CXGN::Phylo::Parse_newick;

use base qw/ CXGN::Phylo::Abstract_tree_parser /;

=head2 function new()

  Synopsis:	
  Arguments:	A string that represents a Newick formatted tree
  Returns:	an instance of a Parse_newick object
  Side effects:	
  Description:	

=cut

sub new { 
    my $class = shift;
    my $string = shift;
    
    my $do_set_error = shift;
$do_set_error = 1 unless(defined $do_set_error); # can speed up parsing by setting this to 0 to skip.
# print "XXXX [$do_set_error]\n"; 
 my $self = $class->SUPER::new();
    $self->{do_set_error} = $do_set_error; 
    $self->set_string($string);
    $self->{tree} = CXGN::Phylo::Tree->new("");
    return $self;
}

=head2 function parse()

  Synopsis:	my $tree = $parser->parse();
  Arguments:	none
  Returns:	a Tree object
  Side effects:	
  Description:	

=cut

sub parse {
    my $self = shift;
    my $root = $self->{tree}->get_root();
    my $current_node = $root;


    my $string = $self->get_string();
    if (!$string) { 
	print STDERR "The string to be parsed has to be set in the constructor.\n";
	return undef;
    }
		$string =~ /^[^\(]*(.*)/; #drop everthing before the first left paren.
$string = $1;
# print STDERR "In Parser::parse. string to parse: [", $string, "]\n";
    #warn "String is $string\n";
    my @tokens = $self->tokenize($string);
    #print join "\n", @tokens;
    for (my $i=0; $i<@tokens; $i++) { 
	$self->set_error(\@tokens, $i) if($self->{do_set_error});
	my $t = $tokens[$i];
	next unless ($t =~ /\S/); # skip tokens with only whitespace
	if ($t eq "(")  {
	    #print STDERR "Encountered (. Creating a new child node [parent=".$current_node->get_name()."\n";
	    my $child = $current_node->add_child();
	    $current_node=$child;
	}
	elsif ($t eq ")") { 
	    #print STDERR  "encountered: ) Moving up to the parent node.\n";
	    my $parent_node;
	    eval { $parent_node=$current_node->get_parent();  };
	    if ($@) { print STDERR  "Illegal Expression Type 1 Error.\n";  return undef; }
	    $current_node=$parent_node;
	    #print STDERR "current node is now: ".$current_node->get_name()."\n";
	}
	elsif ($t eq ",") { 
	    #print STDERR "encountered: , generating a sister node.\n";
	    my $parent_node=$current_node->get_parent();
	    my $sibling;
	    eval { $sibling = $parent_node->add_child(); };
	    if ($@) { print STDERR "Illegal Expression Type 4 Error.\n"; return undef; }
	    $current_node = $sibling;
	    #print STDERR "current node is now ".$current_node->get_name()."\n";
	}
	elsif ( $t=~/\;/ ) { 
	    if (!defined($current_node) || !$current_node->is_root()) { 
		print STDERR "Illegal Expression Error Type 2.\n"; return undef;
	    }
	    return $self->{tree}; 
	}
	else { 
	    #print STDERR "encountered token $t\n";

		#Strip out extended specification (see below) first, so that we
		#can use colons within the extended specs, such as for links.
		my ($extended) = $t =~ /(\[.*\])/;
# print "in Parse_newick->parse. extended: [", $extended, "]\n";	
	#	print STDERR "in Parser. token: [$t] \n";
	$t =~ s/\Q$extended\E// if $extended;
	#	print STDERR "in Parser::parse. t: [$t] \n";
	    my ($name, $distance) = split /\s*\:\s*/, $t;
#		print STDERR "in Parse_newick->parse. name,distance: [$name][$distance] \n";
		$name =~ s/^\s*(.+)\s*$/$1/;
	#	$distance =~ s/^\s*(.+)\s*$/$1/; # eliminate initial and final whitespace - but doesn't work
		$distance =~ s/\s//g; # eliminate all whitespace from $distance.
#print STDERR "name, distance: ", $name, "    ", $distance, "\n";

		
	    # check for our own extended specification. Additional information can be 
	    # added after the node name in [] with embedded tags. Currently supported 
	    # are the "species" tag and the "link" tag. Multiple tag/value pairs are separated
	    # by a pipe (|). String containing the characters : ( ) have to be quoted. Example:
	    # (Arabidopsis [link="http://www.arabidopsis.org/"|species=Arabidopsis thaliana]:0.45)
	    #
	    eval {
		if ($extended) {

		  	$extended =~ s/^\[(.*)\]$/$1/; #strip bracket caps
		  	my @attributes = split /\|/, $extended;
			
			foreach my $attr_string (@attributes){
		 #	  print "attribute string: $attr_string \n";
				my ($attr, $value) = $attr_string =~ /\s*(.*?)\s*=\s*(.*)\s*/;
		#	  print "attr, value: [$attr], [$value].\n";
				unless($attr && defined $value){
					print STDERR "Malformed attribute string: $attr_string \n";
					next;
				}
				if($attr =~ /link/i){
#					print STDERR "Setting link to $value\n";		
					$current_node->get_label()->set_link(URI::Escape::uri_unescape($value));
				}
				elsif($attr =~ /species/i){
				#	print STDERR "Setting species to $value\n";
				#	print URI::Escape::uri_unescape($value), "\n";
					$current_node->set_species(URI::Escape::uri_unescape($value));
#print "curr node species: ", $current_node->get_species(), "\n";
				}
				else{
#					print STDERR "Setting '$attr' to '$value'\n";
					$attr = lc($attr);
					$current_node->set_attribute($attr, $value);
				}
			}
			
# 			if ($additional_info=~/link\=(.*?)(\||\])/i) { 
# 		    }
# 		    if ($additional_info=~/species\=(.*?)(\||\])/i) { 
# 		    }


		  #  #if ($additional_info=~/hidden\=(.*?)(\||\])/i)  { 
		##	$current_node->set_hidden($1);
		 #   }
		}
		$name =~ s/\'//g;
		$current_node->set_name($name); 
	    };
	    if ($@) { 
			print STDERR  "Illegal Expression Type 3 Error.\n"; 
			return undef; 
		}
	    if (($distance!=0 && !$distance)) { 
			print STDERR "No distance information.\n"; 
			return undef;  
		}
# print("distance: ", $distance, "\n");
	    $current_node->set_branch_length($distance);
	    #print STDERR "current node is now: ".$current_node->get_name()."\n";
	}
    }
    if (!defined($current_node) || !$current_node->is_root()) { 
		print STDERR "Illegal Expression Error Type 2.\n"; return undef;
    }

	#Post-process tree.  
	#If none of the nodes have a branch_length property, then we are looking 
	#at a relational tree, so we set all distances to unit length of 1.
	my $bl_found = 0;
	my @desc = $self->{tree}->get_root()->get_descendents();
	foreach(@desc){
		$bl_found = 1 if $_->get_branch_length();
	}
	unless($bl_found){
		print STDERR "Relational tree (no distance information).  Setting all branches to length 1\n";
		$_->set_branch_length(1) foreach @desc;
		$self->{tree}->get_root()->set_branch_length(0);
	}

	$self->{tree}->set_unique_node_key( scalar $self->{tree}->get_all_nodes() );
    return $self->{tree};
}

sub set_error { 
    my $self = shift;
    my $token_ref = shift;
    my $error_token=shift;
    my $left = "";
    my $right = "";
    for (my $i=0; $i<($error_token); $i++) {
	$left .= $$token_ref[$i];
    }
    for (my $i=$error_token+1; $i<@$token_ref; $i++) { 
	$right .= $$token_ref[$i];
    }
    $self->{error_string}="$left<b><font color=\"red\">$$token_ref[$error_token]</font></b>$right";

}

sub get_error { 
    my $self =shift;
    return $self->{error_string};
}

sub tokenize { 
    my $self = shift;
    my $string = shift;

    # the following regular expression works to tokenize a string, using parenthesis and comma as delimiters
    # and returning the tokens as well as the delimiters in order. However, it produces some
    # empty elements in the process, which are cleaned up below.
    #
    my @tokens = split /([^\(\)\,]+)?(\(|\)|\,)/, $string;
    my @result = ();
    foreach my $t (@tokens) { 
	if ($t) { push @result, $t; }
    }
    return @result;
}

=head2 function get_string()

  Synopsis:	my $s = $parser->get_string();
  Arguments:	none
  Returns:	the string that was set to be parsed.
  Side effects:	none
  Description:	

=cut

sub get_string { 
    my $self=shift;
    return $self->{string};
}

=head2 function set_string()

  Synopsis:	$parser->set_string($newick_tree);
  Arguments:	a newick formatted tree in a string.
  Returns:	
  Side effects:	this will be the string that will be parsed
                by the parse() method.
  Description:	

=cut

sub set_string { 
    my $self=shift;
    my $s = shift;
    $s =~ s/\r//g;
    $s =~ s/\n//g;
    $self->{string}=$s;
}


package CXGN::Phylo::Parse_ncbi_taxo_file;

use base qw/ CXGN::Phylo::Abstract_tree_parser /;

=head1 Package CXGN::Phylo::Tree

This class deals with generating and manipulating tree objects.

=cut

sub new { 
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self ;

}

sub parse { 
    my $self = shift;
    my $file = shift;

    my $tree = CXGN::Phylo::Tree->new();

    open (F, "<$file") || die "Can't open file $file\n";
    while (<F>) {
	chomp;
	my ($id, $name, $parent_id) = split /\t/;
	my $parent_node;
	my $node;
	if (exists(${$tree->{node_hash}}{$parent_id})) { 
	    $parent_node=$tree->get_node($parent_id);
	}
	else {
	    $parent_node=CXGN::Phylo::Node->new();
	    $parent_node->set_tree($tree);
	    $parent_node->set_node_key($parent_id);
	    $tree->add_node_hash($parent_node, $parent_id);
	}
	# the child node may also already exist...
	if (exists(${$tree->{node_hash}}{$id})){ 
	    $node=$tree->get_node($id);
	}
	else { 
	    $node = CXGN::Phylo::Node->new();
	 
	    $node->set_tree($tree);
	    $node->set_node_key($id);
	    $tree->add_node_hash($node, $id);
	}
	$node->set_branch_length(1);
	$node->set_name($name);
	$node->set_hide_label();
	my @children = $parent_node->get_children();
	push @children, $node;
	$parent_node->set_children(@children);

    }
    
    my $top_node = $tree->get_node(91827);      # 4070); # Solanaceae  #71240); # the Magnoliophytae node
    
    $top_node->set_parent(undef);
    $tree->set_root($top_node);

    #print STDERR "Done parsing file!\n";
    
    my $renderer = Text_tree_renderer->new($tree);
    $renderer->render();

    return $tree;
}


1;
