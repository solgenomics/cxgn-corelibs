#$Id: ClassResolver.pm,v 1.5 2004/01/15 21:18:50 mwilkinson Exp $
package MOBY::lsid::authority::ClassResolver;

require Exporter;
use XML::DOM;
use MOBY::lsid::authority::dbConnect qw(:all);
use MOBY::lsid::authority::RDFConfigure qw(:all);

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    resolve_classtype
    );
%EXPORT_TAGS =(all => [qw(
    resolve_classtype
    )]);


sub resolve_classtype {
    my ($class_db_params, $ls) = @_;
	my $lsid= LS::ID->new($ls)->canonical;
	unless ($lsid) {
		_die('MALFORMED_LSID');
	}

	my $authority= $lsid->authority;
	my $ns= $lsid->namespace;
	my $obj= $lsid->object;
	my $rev= $lsid->revision;
	
	my $mdata;
    my $dbh = dbConnect($class_db_params);
    # e.g. urn:lsid:biomoby.org:objectclass:text-base64
    my $sth = $dbh->prepare("select object_type, description, authority, contact_email from object where object_lsid = ?");
    $sth->execute($lsid);
    my ($object_type, $description, $authURI, $contact_email) = $sth->fetchrow_array;
    unless ($object_type){
        _die('UNKNOWN_LSID');
    }

    # LSID is now fully validated.  Carry on with metadata.
    $RDF_PREFIX?1:1;
    $mdata= $RDF_PREFIX;
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:title',
        $object_type
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'rdfs:label',
        $object_type
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:description',
        $description
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:contributor',
        $authURI
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:type',
        "bioMoby Class Ontology term"
    );
    $mdata.= rdfResource(
        $contact_email,
        'dc:label',
        $contact_email
    );
    $mdata.= $RDF_SUFFIX;
    $RDF_SUFFIX?1:1;

	unless ($mdata) {
		_die ('NO_METADATA_AVAILABLE');
	}
	return $mdata;
}
