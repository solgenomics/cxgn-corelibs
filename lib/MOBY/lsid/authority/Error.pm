#$Id: Error.pm,v 1.5 2004/01/15 21:34:23 mwilkinson Exp $
package MOBY::lsid::authority::Error;
use base 'Exporter';
require Exporter;
use CGI qw(:all);
my %errors = (
    200, 'MALFORMED_LSID',
    #A syntactically invalid LSID provided.
    201, 'UNKNOWN_LSID',
    #An unknown LSID provided.
    202, 'CANNOT_ASSIGN_LSID',
    #No LSID can be created from the given properties.

    #Error codes dealing with data retrieval
    ###############################################

    300, 'NO_DATA_AVAILABLE',
    #No data exists for the given LSID.
#An exception with this code is raised when there could be data attached
#to the given LSID but they are not available in the time of the request.
#The exception should not raised when the LSID identifies an abstract
#concept in which case there are never any concrete data attached to it.

    301, 'INVALID_RANGE',
    # The requested starting position of data range is not
#valid.
    
    #Error codes dealing with metadata retrieval
    ###############################################
    400, 'NO_METADATA_AVAILABLE',
    # No metadata exists for the given LSID -
#at the moment. The same data retrieval service may be successful
#next time. The exception should not be raised if there are no
#metadata at all, at any time.

    401, 'NO_METADATA_AVAILABLE_FOR_FORMATS',
    #No metadata exists this time,
#or any time for the requested format. The exception cannot be raised
#if the requested format includes wild-chars.

    402, 'UNKNOWN_SELECTOR_FORMAT',
    #The format of the metadata selector is
#not supported by the service.
    
    #General error codes
    ###############################################

    500, 'INTERNAL_PROCESSING_ERROR',
    #A generic catch-all for
#errors not specifically mentioned elsewhere in this list.

    501, 'METHOD_NOT_IMPLEMENTED',
    #A requested method is not implemented.
#Note that the method in question must exist otherwise it may be
#caught already by the underlying protocol and reported differently -
#but it has no implementation.The implementation may extend the set
#of error codes in order to include implementation-specific codes. If
#it does so it should use numbers above 20 in each of the groups,
#or any number above 700. In other words, the free codes are:
#    221-299, 321-399, 421-499, 521-599, 701-above).
             );

my %errornames;  # flip it
while (my ($n, $m) = each %errors){
    $errornames{$m} = $n;
}


our @EXPORT_OK = qw(
    lsid_die
    );
our @EXPORT = qw(
    lsid_die
    );
our %EXPORT_TAGS =(all => [qw(
    lsid_die
    )]);

sub clientFault {}

sub serverFault {}

sub lsid_die {
    my $m = shift;
    my $n = $errornames{$m};
    print header(
        -status=>"$n $m",
                );
    exit 1;
}

1;
