#$Id: RDFConfigure.pm,v 1.4 2004/01/15 21:26:02 mwilkinson Exp $

package MOBY::lsid::authority::RDFConfigure;
use strict;
use base 'Exporter';
require Exporter;
use MOBY::lsid::authority::Error;

our $SERVICE_CGI= 'http://localhost:80/cgi-bin/authority/metadata.pl';
our $RDF_PREFIX="<?xml version='1.0'?>
<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
xmlns:rdfs='http://www.w3.org/2000/01/rdf-schema#'
xmlns:dc='http://purl.org/dc/elements/1.1/'
xmlns:i3cp='urn:lsid:i3c.org:predicates:'
xmlns:mobyp='urn:lsid:biomoby.org:rdfpredicate:'
xmlns:i3csp='urn:lsid:i3c.org:services:'>\n\n";
our $RDF_SUFFIX= "</rdf:RDF>";

sub _die {
    MOBY::lsid::authority::Error::lsid_die(@_);
}

sub rdfLiteral {
	my ($subj, $pred, $obj)= @_;
	return "<rdf:Description rdf:about='$subj'>
\t<$pred>$obj</$pred>
</rdf:Description>\n";
}

sub rdfResource {
	my ($subj, $pred, $obj)= @_;
	return "<rdf:Description rdf:about='$subj'>
\t<$pred rdf:resource='$obj'/>
</rdf:Description>\n";
}

sub rdfBnode {
	my ($subj, $pred, $id)= @_;
	return "<rdf:Description rdf:about='$subj'>
\t<$pred rdf:nodeID='$id'/>
</rdf:Description>\n";
}

sub rdfBnodeResource {
	my ($subj, $pred, $obj)= @_;
	return "<rdf:Description rdf:nodeID='$subj'>
\t<$pred rdf:resource='$obj'/>
</rdf:Description>\n";
}

sub rdfBnodeLiteral {
	my ($subj, $pred, $obj)= @_;
	return "<rdf:Description rdf:nodeID='$subj'>
\t<$pred>$obj</$pred>
</rdf:Description>\n";
}

sub rdfBnodeBnode {
	my ($subj, $pred, $id)= @_;
	return "<rdf:Description rdf:nodeID='$subj'>
\t<$pred rdf:nodeID='$id'/>
</rdf:Description>\n";
}



our @EXPORT_OK = qw(
    $SERVICE_CGI
    $RDF_PREFIX
    $RDF_SUFFIX
    rdfLiteral
    rdfResource
    rdfBnode
    rdfBnodeResource
    rdfBnodeLiteral
    rdfBnodeBnode
    _die
    );
our %EXPORT_TAGS =(all => [qw(
    $SERVICE_CGI
    $RDF_PREFIX
    $RDF_SUFFIX
    rdfLiteral
    rdfResource
    rdfBnode
    rdfBnodeResource
    rdfBnodeLiteral
    rdfBnodeBnode
    _die
    )]);

1;
