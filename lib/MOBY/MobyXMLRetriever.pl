#!/usr/bin/perl -w
use XML::LibXML;
my $parser = XML::LibXML->new;

## Parsing large CDATA sections is very slow, so replace each
## CDATA section with a placeholder tag before parsing the document.
my $xml = '';

my @cdata;
$xml =~ s{<!\[CDATA\[((?>[^\]]+))\]\]>}
{
  push @cdata, $1;
  '<cdata/>';
}eg;

my $doc = eval { $parser->parse_string($xml) };
if ($@)
{
  $@ =~ s/ at \S+ line \d+$//;
  die $@;
}

## <document>
my $root_node = $doc->getDocumentElement;

## Replace the cdata placeholder tag with a CDATASection node.
for my $cdata_node ($root_node->getElementsByTagName('cdata'))
{
  $cdata_node->replaceNode(XML::LibXML::CDATASection->new(shift @cdata));
}