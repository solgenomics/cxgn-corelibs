#!/usr/bin/perl -w

=head1 WHAT IS THIS

This is a script that is supposed to be able to register a new moby service and moby namespace

=head1 AUTHOR

Robert Buels

=cut

use MOBY::Client::Central;

my $v = 1 if ($ARGV[0] && ($ARGV[0] eq "verbose"));

my $URL = $ENV{MOBY_SERVER}?$ENV{MOBY_SERVER}:'http://mobycentral.icapture.ubc.ca/cgi-bin/MOBY05/mobycentral.pl';
my $URI = $ENV{MOBY_URI}?$ENV{MOBY_URI}:'http://mobycentral.icapture.ubc.ca/MOBY/Central';
my $PROXY = $ENV{MOBY_PROXY}?$ENV{MOBY_PROXY}:'No Proxy Server';

my $C = MOBY::Client::Central->new(
Registries => {
  mobycentral => {URL => $URL,
				  URI => $URI}
						}
);

# $C->registerNamespace(
# 		      namespaceType =>'SGN-CloneRead',
# 		      authURI => 'sgn.cornell.edu',
# 		      description => "SGN external genomic clone read identifier, e.g. LE_HBa0031A19_SP6_139417",
# 		      contactEmail => 'lam87@cornell.edu',
# 		     );


$C->registerService(
		    serviceName  => "GetSGNTrimmedCloneReadSequenceByCloneReadIdentifier",
		    serviceType  => "Retrieval",
		    authURI      => "www.sgn.cornell.edu",
		    contactEmail => 'lam87@cornell.edu',
		    description => "retrieve a vector and quality-trimmed clone read sequence from SGN, given a clone read ID (e.g. LE_HBa0031A19_SP6_139417)",
		    category  =>  "moby",
		    URL    =>  "http://www.sgn.cornell.edu/moby/dispatcher.pl",
		    input =>[
			     ['read_name', [Object => ['SGN-CloneRead']]], # Simple
			    ],
		    output =>[
			      ['trimmed_seq', [Object => ['DNASequence']]], # Simple
			     ],
		   );

