package CXGN::Garbage::Arguments;

###################################################################
#
#  Package : Argument
#  Author  : Robert Ahrens
#  Version : 1.0
#  
#  This Perl package is designed to quickly and effectively parse
#  the arguments given to any particular piece of code and return
#  a hash of those arguments.  It flags an error if unknown arguments
#  are entered.
#
#  Usage:
#  my %settings = Argument:parse( 'arg1', 'arg2', 'SWITCH:arg3' );
#  defined %settings or die "USAGE myprog.pl arg1 arg2 [arg3]";
#
#  Arguments which are preceded with the SWITCH: statement will be 
#  handled specially.  If such an argument is given to the program
#  then its hash value will be returned as 1 if it is present or 0 if
#  not.  
#
#  If unexpected arguments are received then the program prints an
#  error message and returns an empty hash.  Hence the die test and
#  the usage message format above allow this to be easily added to
#  other perl programs.
#
#  PLAN: For v1.1, a REQUIRE:statement will cause failure if certain
#  arg's are NOT received.  For now, you will have to look for them
#  using grep {blah blah blah} (split, $settings{'UNDEF'});
#
##################################################################

use strict;

sub parse {

    my @acceptable = @_;
    my %settings=();
    my @switches;
    my @required;
    my $i;

    # Parse input to list switch values.
    $i = 0;
    foreach (@acceptable) {
	if (/^SWITCH:(.+)/) {
	    splice @acceptable, $i, 1, ($1);
	    push @switches, ($1);
	} elsif (/^REQUIRE:(.+)/) {
	    push @required, ($1);
	}
	$i ++;
    }

    # Hash the values received.
    foreach (@ARGV) {

	my @ar = split '=', $_;

	if ($ar[0] =~ /^-+([^-]+)/) {
	    $ar[0] = $1;
	}

	if (defined $settings{$ar[0]}) {
	    print "Argument: $ar[0] found twice.\n";
	    return ();
	} else {
	    $settings{$ar[0]} = $ar[1];
	}

    }

    # Check the hash against the list of acceptable arguments.
    foreach my $thisarg (keys %settings) {

	$i = 0;
	grep {
	    if (/$thisarg/) {
		splice @acceptable, $i, 1; 
		next;
	    } else {
		$i ++;
	    }
	} (@acceptable);
	
	print "Argument: $thisarg not valid.\n";
	return ();

    }

    # Set present switches to have value 1, unpresent 0.
    foreach my $switch (@switches) {
	grep {
	    if (/$switch/) {
		$settings{$switch} = 1;
		next;
	    } else {
		$settings{$switch} = 0;
	    } 
	} (keys %settings);
    }

    # Check that all REQUIREd arguments are present.
    foreach (@required) {
	
	if (not defined $settings{$_}) {
	    print "Argument $_ is REQUIRED and not found.\n";
	    return ();
	}

    }

    # List all undefined, acceptable arguments in UNDEF.
    foreach (@acceptable) {

	if (not defined $settings{$_}) {
	    $settings{'UNDEF'} .= shift @acceptable;
	    $settings{'UNDEF'} .= " ";
	}

    }

    return %settings;

}

return 1;
