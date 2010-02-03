#$Id: NamespaceResolver.pm,v 1.5 2004/01/15 21:18:50 mwilkinson Exp $
package MOBY::lsid::authority::NamespaceResolver;

require Exporter;
use XML::DOM;
use MOBY::lsid::authority::dbConnect qw(:all);
use MOBY::lsid::authority::RDFConfigure qw(:all);

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    resolve_namespacetype
    );
%EXPORT_TAGS =(all => [qw(
    resolve_namespacetype
    )]);


sub resolve_namespacetype {
    my ($namespace_db_params, $ls) = @_;
    #print STDERR "LSID is $ls\n";
	my $lsid= LS::ID->new($ls)->canonical;
	unless ($lsid) {
		_die('MALFORMED_LSID');
	}

	my $authority= $lsid->authority;
	my $ns= $lsid->namespace;
	my $obj= $lsid->object;
	my $rev= $lsid->revision;
	
	my $mdata;
    my $dbh = dbConnect($namespace_db_params);

    my $sth = $dbh->prepare("select namespace_type, description, authority, contact_email from namespace where namespace_lsid = ?");
    $sth->execute($lsid);
    my ($namespace_type, $description, $authURI, $contact_email) = $sth->fetchrow_array;
    unless ($namespace_type){
        _die('UNKNOWN_LSID');
    }

    # LSID is now fully validated.  Carry on with metadata.
    $RDF_PREFIX?1:1;
    $mdata= $RDF_PREFIX;
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:title',
        $namespace_type
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'rdfs:label',
        $namespace_type
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
        "bioMoby Namespace identifier"
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
