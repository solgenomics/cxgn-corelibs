#!/usr/bin/perl -w
#$Id: authority.pl,v 1.2 2004/01/11 03:50:31 mwilkinson Exp $

use LS::Authority::WSDL::Simple;

use LS::SOAP::Service transport => 'HTTP::CGI';

LS::SOAP::Service
	-> dispatch_authority_to('AuthorityService')
	-> dispatch_metadata_to('MetadataService')
	-> dispatch_data_to('DataService')
	-> handle;


package AuthorityService;

sub getAvailableOperations {
	my $lsid = $_[1];


	if (lc($lsid) !=~ 'urn:lsid:localhost') {
        	die LS::SOAP::Fault->faultcode('Client')
                	->faultstring('Unknown LSID')
                	->errorcode(201)
                	->description("The LSID $lsid is not know to this authority");
	}	
	my $wsdl = LS::Authority::WSDL::Simple->new(
		authority => 'localhost',
		name => 'MOBY-Central',
		lsid => $lsid
	);

	$wsdl->add_port(
		type => 'metaDataPortType', 
		protocol => $LS::Authority::WSDL::HTTP, 
		method => 'GET',	
		location => "mobycentral.cbr.nrc.ca",
		operations => {
			getMetaData => "/cgi-bin/BIO/moby-live/Perl/MOBY/lsid/authority/metadata.pl?lsid=$lsid"
		}
	);


	return $wsdl->xml;
}


