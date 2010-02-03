#!/usr/bin/perl -w
#$Id: metadata.pl,v 1.5 2004/07/29 17:49:18 mwilkinson Exp $

use CGI qw/:standard/;
use lib "/usr/local/apache2/cgi-bin/BIO/moby-live/Perl";
use strict;
use CGI::Carp;

use LS::ID;
use LS::Authority::WSDL::Simple;
use MOBY::lsid::authority::Error;

use MOBY::lsid::authority::RDFConfigure qw(:all);

use MOBY::lsid::authority::dbConfigure qw(
	$servicedb
	$namespacedb
	$objectdb
	$centraldb
	$relationshipdb
	);

use MOBY::lsid::authority::NamespaceResolver qw(:all);
use MOBY::lsid::authority::ClassResolver qw(:all);
use MOBY::lsid::authority::ServiceResolver qw(:all);
use MOBY::lsid::authority::RelationshipResolver qw(:all);
use MOBY::lsid::authority::PredicateResolver qw(:all);
use MOBY::lsid::authority::ServiceInstanceResolver qw(:all);

my %known_types = (  # switch on/off various LSID-namespace resolvers.
    'NamespaceType' => 1,
    'ObjectClass' => 1,
    'ServiceType' => 1,
    'ServiceRelation' => 1,
    'ObjectRelation' => 1,
    'ServiceInstance' => 1,
    'MOBYSPredicate' => 1,
                  );

MetaData();


sub MetaData {
    my $lsid = param('lsid');
    
    print header(-type => 'x-application/rdf+xml', -expires => 'now');  # both tags are required by the spec
    my $rdf = validate_lsid($lsid);
    _die("RDF creation failed") unless ($rdf);
    print $rdf;
    exit 1;
}

sub validate_lsid {
    my $lsid = shift;
    unless ($lsid) {
		_die('MALFORMED_LSID');
	}
    unless ($lsid =~ /biomoby.org/){
		_die('UNKNOWN_LSID');
	}
    unless ($lsid =~ /^urn:lsid/i){
		_die('MALFORMED_LSID');
	}
    unless ($lsid =~ /biomoby.org\:(\S+?)\:/){
		_die('MALFORMED_LSID');
	}
    unless ($known_types{$1}){
		_die("UNKNOWN_LSID");
	}
    
    return resolve_namespacetype($namespacedb,$lsid) if $1 =~ /namespacetype/i;
    return resolve_classtype($objectdb,$lsid) if $1 =~ /objectclass/i;
    return resolve_servicetype($servicedb,$lsid) if $1 =~ /servicetype/i;
    return resolve_relationshiptype($relationshipdb,$lsid) if $1 =~ /objectrelation/i;
    return resolve_relationshiptype($relationshipdb,$lsid) if $1 =~ /servicerelation/i;
    return resolve_mobyPredicate($lsid) if $1 =~ /rdfpredicate/i;
    return resolve_ServiceInstance($lsid) if $1 =~ /serviceinstance/i;
    
}

