#$Id: RelationshipResolver.pm,v 1.5 2004/01/15 21:18:50 mwilkinson Exp $
package MOBY::lsid::authority::RelationshipResolver;

require Exporter;
use XML::DOM;
use MOBY::lsid::authority::dbConnect qw(:all);
use MOBY::lsid::authority::RDFConfigure qw(:all);

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    resolve_relationshiptype
    );
%EXPORT_TAGS =(all => [qw(
    resolve_relationshiptype
    )]);


sub resolve_relationshiptype {
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
    # e.g. urn:lsid:biomoby.org:objectrelation:isa
    my $sth = $dbh->prepare("select relationship_type, description, authority, contact_email, ontology from relationship where relationship_lsid = ?");
    $sth->execute($lsid);
    my ($relationship_type, $description, $authURI, $contact_email, $ontology) = $sth->fetchrow_array;
    unless ($relationship_type){
        _die('UNKNOWN_LSID');
    }

    # LSID is now fully validated.  Carry on with metadata.
    $RDF_PREFIX?1:1;
    $mdata= $RDF_PREFIX;
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:title',
        $relationship_type
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'rdfs:label',
        $relationship_type
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
        "bioMoby Relationship Ontology term"
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'mobyp:mobyOntology',
        uc_first($ontology)
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
