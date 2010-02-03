package CXGN::Garbage::cmdline_args;
use strict;

sub get_options {
    my ($validopt_ref, $argv_ref) = @_;
    my ($option, $error);

    if (! @{$argv_ref}) {
	print "No command line options\n";
	return 0;
    }

    while(@{$argv_ref}>0) {
	$option = shift @{$argv_ref};

	if (! defined($validopt_ref->{$option})) {
	    print STDERR "Unknown option $option\n";
	    $error = 1;
	    next;
	}

	if ($validopt_ref->{$option}->[1]) {
	    # Option which requires argument, shift in the next argument from
	    # the command line
	    ${$validopt_ref->{$option}->[0]} = shift @{$argv_ref};
	} else {
	    # Boolean flag: invert default value
	    if (${$validopt_ref->{$option}->[0]}) {
	         ${$validopt_ref->{$option}->[0]} = 0;
            } else {
                 ${$validopt_ref->{$option}->[0]} = 1;
            }
        }
    }

    return $error;
}
return 1;
