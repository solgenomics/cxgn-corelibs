#$Id: PredicateResolver.pm,v 1.3 2004/01/15 20:59:38 mwilkinson Exp $
package MOBY::lsid::authority::PredicateResolver;

require Exporter;
use XML::DOM;
use MOBY::lsid::authority::RDFConfigure qw(:all);

@ISA = qw(Exporter);
@EXPORT_OK = qw(
    resolve_mobyPredicate
    );
%EXPORT_TAGS =(all => [qw(
    resolve_mobyPredicate
    )]);

my $known_predicates = {
    mobyOntology => 'A phrase representing one of the bioMoby ontologies.',
    mobyontology => 'A phrase representing one of the bioMoby ontologies.',
};

sub resolve_mobyPredicate {
    my ($ls) = @_;
	my $lsid= LS::ID->new($ls)->canonical;
	unless ($lsid) {
		_die('MALFORMED_LSID');
	}

	my $authority= $lsid->authority;
	my $ns= $lsid->namespace;
	my $obj= $lsid->object;
	my $rev= $lsid->revision;
	# e.g. urn:lsid:biomoby.org:rdfpredicates:mobyOntology

    unless ($known_predicates->{$obj}){
        _die('UNKNOWN_LSID');
    }

    # LSID is now fully validated.  Carry on with metadata.
    $RDF_PREFIX?1:1;
    $mdata= $RDF_PREFIX;
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:description',
        $known_predicates->{$obj}
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:contributor',
        'markw@illuminae.com'
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:type',
        "bioMoby predicate"
    );
    $mdata.= rdfLiteral(
        $lsid->as_string,
        'dc:label',
        $obj
    );
    $mdata.= $RDF_SUFFIX;
    $RDF_SUFFIX?1:1;

	unless ($mdata) {
		_die ('NO_METADATA_AVAILABLE');
	}
	return $mdata;
}
