
=head1 NAME

CXGN::Phylo::File - a class to read different tree files.

=head1 DESCRIPTION

my $file = CXGN::Phylo::File->new($filename);
my @node_names = $file->get_node_names();
my $tree_string = $file -> get_tree_string();


=head1 AUTHOR

Lukas Mueller (lam87@cornell.edu)

=cut

package CXGN::Phylo::File;

sub new { 
    my $class = shift;
    my $file = shift;

    my $args={};
    my $self = bless $args, $class;

    my $newick="";    
    my %ids;
    my $in_translation=0;
	my $in_tree = 0;
    $self->set_file_type($self->determine_filetype($file));

    if ($self->get_file_type() eq "nexus") { 
		print STDERR "READING a NEXUS FILE!\n\n";
		open (F, "<$file") || die "Can't open file \"$file\".\n";
		while (<F>) { 
		    chomp;
		    if (/^>/) { next; }  # skip lines that start with >
		    if (/^\#/) { next; } # and #
		    if (/^\[|^\]/) { next; } # and [ or ]
		    if (/Translate/i) { $in_translation = 1;} # lets get the node names
		    if (/^\s+\;/ && $in_translation) { $in_translation = 0; }    # until that section is over
		    if (($in_translation) && /^\s*(\d+)\s+(.[A-Za-z._\-0-9]+),?/) { $ids{$1}=$2; }  # the leaf node names are coded with a number
		    if (/^\s*tree/i)  { $in_tree = 1; } # finally, the tree!
		    if (/^\s*End;/i) { $in_tree = 0; }
			if ($in_tree) { $newick .= $_ }  #allow newick to span multiple lines (forgiving)
		}
		close(F);
		
		# throw away trash chars before the newick expression begins
		#
		#translate the newick:
		if(keys %ids > 0){
			foreach my $k (keys %ids){
				my $v = $ids{$k};
				$newick =~ s/\b$k\b/$v/;
			}
		}
		$newick =~ s/\n|\r//g;
		$newick =~ s/^(tree.*?)(\(.*)$/$2/;
	
		$self->set_node_names(\%ids);
    }
    else {
#	print STDERR "Reading plain newick file $file...\n";
	open (F, "<".$file) || die "Can't open file $file\n";
	while (<F>) { 
	    chomp;
	    $newick .=$_;
	}
	close(F);
    }
    $self->set_tree_string($newick);

    return $self;
}

=head2 function determine_filetype()

  Synopsis:	
  Arguments:	a filename, possibly including a path
  Returns:	"nexus" if the file is of type nexus
                "newick" if the file contains a plain newick expression
  Side effects:	none
  Description:	

=cut

sub determine_filetype { 
    my $self = shift;
    my $filename = shift;
    open(TEST, "<$filename") || die "Can't open file $filename ..."; 
    my $line = <TEST>;
    close(TEST);
    if ($line =~ /NEXUS/i) { return "nexus"; }
    if ($line =~ /\(/)  { return "newick"; }
    return undef;
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

=head2 function get_file_type()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_file_type { 
    my $self=shift;
    return $self->{file_type};
}

=head2 function set_file_type()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_file_type { 
    my $self=shift;
    $self->{file_type}=shift;
}

=head2 function get_node_names()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_node_names { 
    my $self=shift;
    return $self->{node_names};
}

=head2 function set_node_names()

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub set_node_names { 
    my $self=shift;
    $self->{node_names}=shift;
}

=head2 function get_tree()

  Synopsis:	
  Arguments:	
  Returns:	a tree object
  Side effects:	
  Description:	

=cut

sub get_tree { 
    my $self=shift;
    my $tree_parser=CXGN::Phylo::Parse_newick->new($self->get_tree_string());
    $self->{tree}=$tree_parser->parse();
    # if it was a nexus file, replace the node names with the actual
    # names which are available through get_node_names().
    #
    my $trans_hash_ref = $self->get_node_names();
    foreach my $k (keys %$trans_hash_ref) { 
		my $node = $self->{tree}->get_node_by_name($k);
		if ($node) {
		    $node->set_name($$trans_hash_ref{$k});
		}
    }
    return $self->{tree};
}




1;
