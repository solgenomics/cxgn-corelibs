#$Id: ServiceInstanceResolver.pm,v 1.4 2004/07/29 00:36:54 mwilkinson Exp $
package MOBY::lsid::authority::ServiceInstanceResolver;

require Exporter;
use XML::DOM;
use MOBY::lsid::authority::RDFConfigure qw(:all);
use MOBY::Client::Central;
use MOBY::RDF::ServiceInstanceRDF;

use RDF::Core;
use RDF::Core::Model;
use RDF::Core::Literal;
use RDF::Core::Statement;
use RDF::Core::Model::Serializer;
use RDF::Core::Storage::Memory;
use RDF::Core::Constants qw(:xml :rdf :rdfs);
use constant OBJ => 'http://biomoby.org/RESOURCES/MOBY-S/Objects#';
use constant SRV => 'http://biomoby.org/RESOURCES/MOBY-S/Services#';
use constant NS => 'http://biomoby.org/RESOURCES/MOBY-S/Namespaces#';
use constant MP => 'http://biomoby.org/RESOURCES/MOBY-S/Predicates#';
use constant SI => 'http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances#';
use constant DC => 'http://purl.org/dc/elements/1.1/';

sub xmlNamespaces {
    return {
        RDF_NS() => 'rdf',
        RDFS_NS() => 'rdfs',
        OBJ() => 'mobyObject',
        NS() => 'mobyNamespace',
        SRV() => 'mobyService',
        MP() => 'mobyPred',
        SI() => 'serviceInstances',
        DC() => 'dc',
    }
}


@ISA = qw(Exporter);
@EXPORT_OK = qw(
    resolve_ServiceInstance
    );
%EXPORT_TAGS =(all => [qw(
    resolve_ServiceInstance
    )]);

sub _serialize {
    my ($model) = @_;
    my $xml = '';
    
    my $serializer = new RDF::Core::Model::Serializer(
        Model=>$model,
        Output=>\$xml,
        getNamespaces => \&xmlNamespaces,  # this only works with a patch!!!!!!!!!!!!!!!!
                                                   );
    $serializer->serialize;
    print "$xml\n";
}

sub resolve_ServiceInstance {
	
    my ($ls) = @_;
	my $lsid= LS::ID->new($ls)->canonical;
	unless ($lsid) {
		_die('MALFORMED_LSID');
	}

	my $authority= $lsid->authority;
	my $ns= $lsid->namespace;
	my $obj= $lsid->object;
	my $rev= $lsid->revision;
	# e.g. urn:lsid:biomoby.org:serviceinstance:www.illuminae.com,genbankcompletesequenceretrieve
    unless ($obj =~ /(.*)\,(.*):?/){
        _die('MALFORMED_LSID');
    }
    my $auth = $1; my $sname = $2;
    my $M = MOBY::Client::Central->new;
    my ($si, $reg) = $M->findService(authURI => $auth, serviceName => $sname);
    
    unless ($si && ${$si}[0]){
        _die('UNKNOWN_LSID');
    }

	my $storage = new RDF::Core::Storage::Memory;
	my $model = new RDF::Core::Model (Storage => $storage);
    
	foreach my $service(@{$si}){
        my $ServInstRDF = MOBY::RDF::ServiceInstanceRDF->new(
                                                             model => $model,
                                                             service_instance => $service,
                                                            );
    }

	print header(-type => 'application/rdf+xml', -expires => 'now');
	_serialize($model);
	exit 1;
}

1;
