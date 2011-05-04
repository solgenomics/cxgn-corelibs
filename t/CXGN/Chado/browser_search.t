#!/usr/bin/perl

use Modern::Perl;

use CXGN::Chado::Cvterm;
use XML::Twig;

my $dbh = CXGN::DB::Connection->new();
my $cv_term = CXGN::Chado::Cvterm->new_with_accession( $dbh, "PO:0004518" );

# Get roots of database
my @roots_list = ();
my @roots = CXGN::Chado::Cvterm::get_roots( $dbh, $cv_term->get_db_name() );
foreach my $new_root (@roots) {
    push( @roots_list, $new_root );
}
my $rootNumber = scalar(@roots_list);

# Paths will be stored as an array of arrays
my @paths = ();

# Explicitly initialize the first array, the rest will be dynamic
my @init = ();
push( @init, [ $cv_term, undef ] );
unshift( @paths, \@init );

# Monitor variables
my $complete = "false";

# Will become true if and only if every path traces back to a root
my $doneCounter = 0;

# Monitors how many paths are done -- when all are done, complete becomes true

# If searching for a root, the path is already done
FINDIFROOT: for ( my $i = 0 ; $i < scalar(@roots_list) ; $i++ ) {
    if ( $init[0]->[0]->get_accession() eq $roots_list[$i]->get_accession() ) {
        unshift( @init, "done" );
        $paths[0] = \@init;
        $doneCounter++;
        $complete = "true";
        last FINDIFROOT;
    }
}

# Find paths
while ( $complete ne "true" ) {

    # Identify latest term in each path
    my $pathNumber = scalar(@paths);
    for ( my $i = 0 ; $i < $pathNumber ; $i++ ) {
        my $pathArrayRef = $paths[$i];
        my @workingPath  = @$pathArrayRef;

        my $nextTerm = "done";
        if ( ref( $workingPath[0] ) eq "ARRAY" ) {
            $nextTerm = $workingPath[0]->[0];
        }

        # Read only paths that are not done, this saves time
        if ( $nextTerm ne "done" ) {
            my @parents      = $nextTerm->get_parents();
            my $parentNumber = scalar(@parents);

            if ( $parentNumber > 1 ) {

# Take out the original path, then push copies of the original path with new parents into the paths list
                my $index = $i;
                my $originalPath = splice( @paths, $index, 1 );

              ROOTCHECKER: for ( my $j = 0 ; $j < $parentNumber ; $j++ ) {
                    my @nextPath = @$originalPath;

                    unshift( @nextPath, $parents[$j] );
                    for ( my $k = 0 ; $k < scalar(@roots_list) ; $k++ ) {
                        if ( $nextPath[0]->[0]->get_accession() eq
                            $roots_list[$k]->get_accession() )
                        {
                            $nextPath[0] = [ $roots_list[$k], undef ];
                            unshift( @nextPath, "done" );
                            push( @paths, \@nextPath );
                            $doneCounter++;
                            last ROOTCHECKER;
                        }
                    }
                    push( @paths, \@nextPath );
                }
            }

            else {

             # Simple: put the parent in the array and see if it's a root or not
                unshift( @workingPath, $parents[0] );

              ROOTCHECK: for ( my $j = 0 ; $j < scalar(@roots_list) ; $j++ ) {
                    if ( $workingPath[0]->[0]->get_accession() eq
                        $roots_list[$j]->get_accession() )
                    {
                        $workingPath[0] = [ $roots_list[$j], undef ];
                        unshift( @workingPath, "done" );
                        $doneCounter++;
                        last ROOTCHECK;
                    }
                }
                $paths[$i] = \@workingPath;
            }
        }
    }

    my $test = scalar(@paths);
    if ( $doneCounter == $test ) {
        $complete = "true";
    }
}
##########################################################################################################################
# Print paths and parents for testing
my $counter = 0;
foreach my $ref (@paths) {
    $counter++;
    my @path = @$ref;
    print "Path " . $counter . "\n";
    for ( my $j = 1 ; $j < scalar(@path) ; $j++ ) {

        # Skip first term -- always the "done" keyword
        print $path[$j]->[0]->get_db_name() . ":"
          . $path[$j]->[0]->get_accession() . " -- "
          . $path[$j]->[0]->get_cvterm_name() . "\n";
    }
    print "\n";
}

print "\nParents of term:\n";
my @test = $cv_term->get_parents();
foreach my $a (@test) {
    print $a->[0]->get_cvterm_name() . "\n";
}
print "\n\n";

#
##
######### Path finding is complete and working correctly, barring a database problem with synonyms, on 7/18/07.
##
#
##########################################################################################################################

# Generate XML tree
print "\n\n\nXML TREE\n";
my $xmlRoot        = XML::Twig::Elt->new('specific');
my $treeRootTag    = "term";
my %termIndentHash = ();

for ( my $i = 0 ; $i < scalar(@paths) ; $i++ ) {
    my $pathRef = $paths[$i];
    my @path    = @$pathRef;

    for ( my $j = 1 ; $j < scalar(@path) ; $j++ ) {
        my $treeRootContent =
            $paths[$i]->[$j]->[0]->get_db_name() . ":"
          . $paths[$i]->[$j]->[0]->get_accession();
        my $fullName = $treeRootContent;
        $treeRootContent .= ' -- ' . $paths[$i]->[$j]->[0]->get_cvterm_name();

        my $elementID = $j . "--" . $fullName;

        my $next = XML::Twig::Elt->new( $treeRootTag, $treeRootContent );
        $next->set_att( id     => $fullName );
        $next->set_att( divID  => $elementID );
        $next->set_att( indent => $j );

        my $childNumber = $paths[$i]->[$j]->[0]->count_children();
        $next->set_att( children => $childNumber );

        if ( scalar( $xmlRoot->descendants() ) > 0 ) {
            my $newElement = "true";

            my $text = $next->text;
            my $startIndex = index( $text, ":" ) + 1;
            $text = substr( $text, $startIndex - 3, $startIndex + 7 );

            print "Current term: $text: $j\n";
            for my $term ( keys %termIndentHash ) {
                print "$term: @{$termIndentHash{$term}}\n";
            }
            print "\n\n";

            if ( scalar( grep( $text, keys(%termIndentHash) ) ) != 0 ) {
                if ( scalar( grep( $j, @{ $termIndentHash{$text} } ) ) == 0 ) {
                    push( @{ $termIndentHash{$text} }, $j );

                }
                else {
                    $newElement = "false";
                }
            }
            else {
                my @arrayValues = ();
                push( @arrayValues, $j );
                $termIndentHash{$text} = [@arrayValues];
            }

            my $element = $xmlRoot;
            while ( $element = $element->next_elt('#ELT') ) {
                if ( $newElement eq "true" ) {
                    if ( $next->att('indent') - $element->att('indent') == 1 ) {
                        eval { $next->paste( 'last_child', $element ) };
                        my @arrayValues = ();
                        push( @arrayValues, $j );
                        $termIndentHash{$text} = [@arrayValues];
                    }
                }
            }
        }
        else {
            $next->paste($xmlRoot);
            %termIndentHash = ();
            my @arrayValues = ();
            push( @arrayValues, 1 );
            $termIndentHash{ substr( $next->trimmed_text, 0, 10 ) } =
              [@arrayValues];
        }
    }
}

for my $term ( keys %termIndentHash ) {
    print "$term: @{$termIndentHash{$term}}\n";
}

# Format and print XML tree
my $text = $xmlRoot->sprint;

$text =~ s|>|>\n|g;    # Put newlines after tag boundaries
$text =~ s|<|\n<|g;    # Put newlines before tag boundaries
$text =~
  s|>\n([A-Z])|>$1|g;    # Remove newlines when they come before an accession

my $newLineIndex = 0
  ; # Remove blank lines by removing extra newlines; go through the string multiple
while ( $newLineIndex != -1 ) {    # times if necessary
    $text =~ s|\n\n|\n|g;
    $newLineIndex = index( $text, "\n\n" );
}

$text =~ s|(<term[A-Za-z0-9 _\,\<\>\+\=\/\'\"\:\t-]*)\n(</term>)|$1$2|g;

# Condense the final term of each path, and its end tag, onto one line for easy identification

print $text;
