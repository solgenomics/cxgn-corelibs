#$Id: CommonSubs.pm,v 1.72 2005/11/21 12:19:35 pieter Exp $

=head1 NAME

MOBY::CommonSubs.pm - a set of exportable subroutines that are
useful in clients and services to deal with the input/output from
MOBY Services

=head1 DESCRIPTION

CommonSubs are used to do various manipulations of MOBY Messages.  It is useful
both Client and Service side to construct and parse MOBY Messages, and ensure
that the message structure is valid as per the API.

It DOES NOT connect to MOBY Central for any of its functions, though it does
contact the ontology server, so it will require a network connection.

=head1 SYNTAX

=head2 Client Side Paradigm

not written yet

=head2 Service-Side Paradigm

The following is a generalized architecture for *all*
BioMOBY services showing how to parse incoming messages
using the subroutines provided in CommonSubs

 sub myServiceName {
    my ($caller, $data) = @_;
    my $MOBY_RESPONSE; # holds the response raw XML

        # genericServiceInputParser
        # unpacks incoming message into an array of arrarefs.
        # Each element of the array is a queryInput block, or a mobyData block
        # the arrayref has the following structure:
        # [SIMPLE, $queryID, $simple]
        # the first element is an exported constant SIMPLE, COLLECTION, SECONDARY
        # the second element is the queryID (required for enumerating the responses)
        # the third element is the XML::LibXML for the Simple, Collection, or Parameter block
    my (@inputs)= genericServiceInputParser($data);
        # or fail properly with an empty response
    return SOAP::Data->type('base64' => responseHeader("my.authURI.com") . responseFooter()) unless (scalar(@inputs));

        # you only need to do this if you are intending to be namespace aware
        # some services might not care what namespace the data is in, so long
        # as there is data...
    my @validNS_LSID = validateNamespaces("NCBI_gi");  # returns LSID's for each human-readable

    foreach (@inputs){
        my ($articleType, $qID, $input) = @{$_};
        unless (($articleType == SIMPLE) && ($input)){
                # in this example, we are only accepting SIMPLE types as input
                # so write back an empty response block and move on to the next
            $MOBY_RESPONSE .= simpleResponse("", "", $qID) ;
            next;
        } else {
                # now take the namespace and ID from our input article
                # (see pod docs for other possibilities)
            my $namespace = getSimpleArticleNamespaceURI($input); # get namespace
            my ($identifier) = getSimpleArticleIDs($input);  # get ID (note array output! see pod)

            # here is where you do whatever manipulation you need to do
            # for your particular service.
            # you will be building an XML document into $MOBY_RESPONSE
        }
    }
    return SOAP::Data->type('base64' => (responseHeader("illuminae.com") . $MOBY_RESPONSE . responseFooter));
 }


=head1 EXAMPLE


A COMPLETE EXAMPLE OF AN EASY MOBY SERVICE

This is a service that:

 CONSUMES:  base Object in the GO namespace
 EXECUTES:  Retrieval
 PRODUCES:  GO_Term (in the GO namespace)


 # this subroutine is called from your dispatch_with line
 # in your SOAP daemon


 sub getGoTerm {
    my ($caller, $message) = @_;
    my $MOBY_RESPONSE;
    my (@inputs)= genericServiceInputParser($message); # ([SIMPLE, $queryID, $simple],...)
    return SOAP::Data->type('base64' => responseHeader('my.authURI.com') . responseFooter()) unless (scalar(@inputs));

    my @validNS = validateNamespaces("GO");  # ONLY do this if you are intending to be namespace aware!

    my $dbh = _connectToGoDatabase();
    return SOAP::Data->type('base64' => responseHeader('my.authURI.com') . responseFooter()) unless $dbh;
    my $sth = $dbh->prepare(q{
       select name, term_definition
       from term, term_definition
       where term.id = term_definition.term_id
       and acc=?});

    foreach (@inputs){
        my ($articleType, $ID, $input) = @{$_};
        unless ($articleType == SIMPLE){
            $MOBY_RESPONSE .= simpleResponse("", "", $ID);
            next;
        } else {
            my $ns = getSimpleArticleNamespaceURI($input);
            (($MOBY_RESPONSE .= simpleResponse("", "", $ID)) && (next))
                unless validateThisNamespace($ns, @validNS);  # only do this if you are truly validating namespaces
            my ($accession) = defined(getSimpleArticleIDs($ns, [$input]))?getSimpleArticleIDs($ns,[$input]):undef;
            unless (defined($accession)){
                $MOBY_RESPONSE .= simpleResponse("", "", $ID);
                next;
            }
            unless ($accession =~/^GO:/){
                 $accession = "GO:$accession";  # we still haven't decided on whether id's should include the prefix...
            }
            $sth->execute($accession);
            my ($term, $def) = $sth->fetchrow_array;
            if ($term){
                 $MOBY_RESPONSE .= simpleResponse("
                 <moby:GO_Term namespace='GO' id='$accession'>
                  <moby:String namespace='' id='' articleName='Term'>$term</moby:String>
                  <moby:String namespace='' id='' articleName='Definition'>$def</moby:String>
                 </moby:GO_Term>", "GO_Term_From_ID", $ID)
            } else {
                 $MOBY_RESPONSE .= simpleResponse("", "", $ID)
            }
        }
    }

    return SOAP::Data->type('base64' => (responseHeader("my.authURI.com") . $MOBY_RESPONSE . responseFooter));
 }


=head1 AUTHORS

Mark Wilkinson (markw at illuminae dot com)

BioMOBY Project:  http://www.biomoby.org

=head1 PARSING INPUT

=cut

package MOBY::CommonSubs;
require Exporter;
use XML::LibXML;
use MOBY::CrossReference;
use MOBY::Client::OntologyServer;
use strict;
use warnings;
use MOBY::Client::SimpleArticle;
use MOBY::Client::CollectionArticle;
use MOBY::Client::SecondaryArticle;
use MOBY::MobyXMLConstants;
use constant COLLECTION => 1;
use constant SIMPLE     => 2;
use constant SECONDARY  => 3;
use constant PARAMETER  => 3;    # be friendly in case they use this instead
use constant BE_NICE    => 1;
use constant BE_STRICT  => 0;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(COLLECTION SIMPLE SECONDARY PARAMETER BE_NICE BE_STRICT);
our %EXPORT_TAGS = (
	all => [
		qw(
		  getSimpleArticleIDs
		  getSimpleArticleNamespaceURI
		  getInputArticles
		  getInputs
		  getInputID
		  getArticles
		  getCollectedSimples
		  getNodeContentWithArticle
		  extractRawContent
		  validateNamespaces
		  validateThisNamespace
		  isSimpleArticle
		  isCollectionArticle
		  isSecondaryArticle
		  extractResponseArticles
		  getResponseArticles
		  getCrossReferences
		  genericServiceInputParser
		  genericServiceInputParserAsObject
		  complexServiceInputParser
		  whichDeepestParentObject
		  getServiceNotes
		  simpleResponse
		  collectionResponse
		  complexResponse
		  responseHeader
		  responseFooter
		  COLLECTION
		  SIMPLE
		  SECONDARY
		  PARAMETER
		  BE_NICE
		  BE_STRICT
		  )
	]
);


our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

=head2 genericServiceInputParser

B<function:> For the MOST SIMPLE SERVICES that take single Simple or
Collection inputs and no Secondaries/Parameters this routine takes the
MOBY message and breaks the objects out of it in a useful way

B<usage:>
  my @inputs = genericServiceInputParser($MOBY_mssage));

B<args:> C<$message> - this is the SOAP payload; i.e. the XML document containing the MOBY message

B<returns:> C<@inputs> - the structure of @inputs is a list of listrefs.

Each listref has three components:

=over 4

=item *
COLLECTION|SIMPLE (i.e. constants 1, 2)

=item *
queryID

=item *
$data - the data takes several forms

=over 4

=item *
$article XML::LibXML node for Simples  <mobyData...>...</mobyData>

=item *
\@article XML:LibXML nodes for Collections

=back

=back

For example, the input message:

  <mobyData queryID = '1'>
      <Simple>
         <Object namespace=blah id=blah/>
      </Simple>
  </mobyData>
  <mobyData queryID = '2'>
      <Simple>
         <Object namespace=blah id=blah/>
      </Simple>
  </mobyData>
will become:
            (note that SIMPLE, COLLECTION, and SECONDARY are exported constants from this module)

            @inputs = ([SIMPLE, 1, $DOM], [SIMPLE, 2, $DOM]) # the <Simple> block

For example, the input message:

    <mobyData queryID = '1'>
        <Collection>
        <Simple>
           <Object namespace=blah id=blah/>
        </Simple>
        <Simple>
           <Object namespace=blah id=blah/>
        </Simple>
        </Collection>
    </mobyData>

will become:

 @inputs = ( [COLLECTION, 1, [$DOM, $DOM]] ) # the <Simple> block

=cut

sub genericServiceInputParser {
  my ( $message ) = @_;    # get the incoming MOBY query XML
  my @inputs;              # set empty response
  my @queries = getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
  foreach my $query ( @queries ) {
    my $queryID = getInputID( $query ); # get the queryID attribute of the mobyData
    my @input_articles =
      getArticles( $query )
	; # get the Simple/Collection/Secondary articles making up this query <Simple>...</Simple> or <Collection>...</Collection> or <Parameter>...</Parameter>
    foreach my $input ( @input_articles ) {    # input is a listref
      my ( $articleName, $article ) = @{$input};   # get the named article
      if ( isCollectionArticle( $article ) ) {
	my @simples = getCollectedSimples( $article );
	push @inputs, [ COLLECTION, $queryID, \@simples ];
      } elsif ( isSimpleArticle( $article ) ) {
	push @inputs, [ SIMPLE, $queryID, $article ];
      } elsif ( isSecondaryArticle( $article ) )
	{    # should never happen in a generic service parser!
	  push @inputs, [ SECONDARY, $queryID, $article ];
	}
    }
  }
  return @inputs;
}

=head2 serviceInputParser

DO NOT USE!!

B<function:> to take a MOBY message and break the objects out of it.
This is identical to the genericServiceInputParser method above,
except that it returns the data as Objects rather than XML::LibXML
nodes.  This is an improvement!

B<usage:> C<my @inputs = serviceInputParser($MOBY_mssage));>

B<args:> C<$message> - this is the SOAP payload; i.e. the XML document containing the MOBY message

B<returns:> C<@inputs> - the structure of @inputs is a list of listrefs.

Each listref has three components:

                1. COLLECTION|SIMPLE|SECONDARY (i.e. constants 1, 2, 3)
                2. queryID (undef for Secondary parameters)
                3. $data - either MOBY::Client::SimpleArticle, CollectionArticle, or SecondaryArticle

=cut

sub serviceInputParser {
  my ( $message ) = @_;    # get the incoming MOBY query XML
  my @inputs;              # set empty response
  my @queries = getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
  
  # mark, this doesn't work for complex services.  We need to allow more than one input per invocation
  foreach my $query ( @queries ) {
    my $queryID = getInputID( $query );    # get the queryID attribute of the mobyData
    # get the Simple/Collection articles making up this query
    #  <Simple>...</Simple> or <Collection>...</Collection> 
    # or <Parameter>...</Parameter    
    my @input_articles = getArticlesAsObjects( $query );
    foreach my $article ( @input_articles ) {    # input is a listref
      if ( $article->isCollection ) {
	my @simples = getCollectedSimples( $article->XML );
	push @inputs, [ COLLECTION, $queryID, \@simples ];
      } elsif ( $article->isSimple ) {
	push @inputs, [ SIMPLE, $queryID, $article ];
      } elsif ( $article->isSecondary ) {
	push @inputs, [ SECONDARY, $queryID, $article ];
      }
    }
  }
  return @inputs;
}

=head2 complexServiceInputParser

B<function:> For more complex services that have multiple articles for
each input and/or accept parameters, this routine will take a MOBY
message and extract the Simple/Collection/Parameter objects out of it
in a useful way.

B<usage:> C<my $inputs = complexServiceInputParser($MOBY_mssage));>

B<args:> C<$message> - this is the SOAP payload; i.e. the XML document containing the MOBY message

B<returns:> C<$inputs> is a hashref with the following structure:

            $inputs->{$queryID} = [ [TYPE, $DOM], [TYPE, $DOM], [TYPE, $DOM] ]

=head3  Simples

For example, the input message:

      <mobyData queryID = '1'>
          <Simple articleName='name1'>
             <Object namespace=blah id=blah/>
          </Simple>
          <Parameter articleName='cutoff'>
             <Value>10</Value>
          </Parameter>
      </mobyData>

will become: (note that SIMPLE, COLLECTION, and SECONDARY are exported constants from this module)

            $inputs->{1} = [ [SIMPLE, $DOM_name1], # the <Simple> block
                             [SECONDARY, $DOM_cutoff]  # $DOM_cutoff= <Parameter> block
                           ]

Please see the XML::LibXML pod documentation for information about how to parse XML DOM objects.

=head3            Collections 

With inputs that have collections these are presented as a listref of
Simple article DOM's.  So for the following message:

   <mobyData>
       <Collection articleName='name1'>
         <Simple>
          <Object namespace=blah id=blah/>
         </Simple>
         <Simple>
          <Object namespace=blah id=blah/>
         </Simple>
       </Collection>
       <Parameter articleName='cutoff'>
          <Value>10</Value>
       </Parameter>
   </mobyData>

will become

            $inputs->{1} = [ [COLLECTION, [$DOM, $DOM] ], # $DOM is the <Simple> Block!
                             [SECONDARY, $DOM_cutoff]  # $DOM_cutoff = <Parameter> Block
                           ]

Please see the XML::LibXML pod documentation for information about how to parse XML DOM objects.

=cut

sub complexServiceInputParser {
	my ( $message ) = @_;    # get the incoming MOBY query XML
	my @inputs;              # set empty response
	my @queries = getInputs( $message );   # returns XML::LibXML nodes <mobyData>...</mobyData>
	my %input_parameters;      # $input_parameters{$queryID} = [
	foreach my $query ( @queries ) {
	  my $queryID =  getInputID( $query );    # get the queryID attribute of the mobyData
		my @input_articles =
		  getArticles( $query )
		  ; # get the Simple/Collection/Secondary articles making up this query <Simple>...</Simple> or <Collection>...</Collection> or <Parameter>...</Parameter>
		foreach my $input ( @input_articles ) {    # input is a listref
			my ( $articleName, $article ) = @{$input};   # get the named article
			if ( isCollectionArticle( $article ) ) {
				my @simples = getCollectedSimples( $article );
				push @{ $input_parameters{$queryID} },
				  [ COLLECTION, \@simples ];
			} elsif ( isSimpleArticle( $article ) ) {
				push @{ $input_parameters{$queryID} }, [ SIMPLE, $article ];
			} elsif ( isSecondaryArticle( $article ) ) {
				push @{ $input_parameters{$queryID} }, [ SECONDARY, $article ];
			}
		}
	}
	return \%input_parameters;
}

=head2 getArticles

B<function:> get the Simple/Collection/Parameter articles for a single mobyData

B<usage:> C<@articles = getArticles($XML)>

B<args:> raw XML or XML::LibXML of a queryInput, mobyData, or queryResponse block (e.g. from getInputs)

B<returns:> a list of listrefs; each listref is one component of the
queryInput or mobyData block a single block may consist of one or more
named or unnamed simple, collection, or parameter articles.  The
listref structure is thus C<[name, $ARTICLE_DOM]>:

    e.g.:  @articles = ['name1', $SIMPLE_DOM]

generated from the following sample XML:

                <mobyData>
                    <Simple articleName='name1'>
                      <Object namespace=blah id=blah/>
                    </Simple>
                </mobyData>

    or  :  @articles = ['name1', $COLL_DOM], ['paramname1', $PARAM_DOM]

generated from the following sample XML:

  <mobyData>
      <Collection articleName='name1'>
        <Simple>
         <Object namespace=blah id=blah/>
        </Simple>
        <Simple>
         <Object namespace=blah id=blah/>
        </Simple>
      </Collection>
      <Parameter articleName='e value cutoff'>
         <default>10</default>
      </Parameter>
  </mobyData>

=cut

sub getArticles {
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef
    unless ( ($moby->nodeType == ELEMENT_NODE)
	     && ( $moby->nodeName =~ /^(moby:|)(queryInput|queryResponse|mobyData)$/ ) );
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless ( ($child->nodeType == ELEMENT_NODE)    # ignore whitespace
		    && ( $child->nodeName =~ /^(moby:|)(Simple|Collection|Parameter)$/ ) );
      my $articleName = _moby_getAttribute($child, 'articleName' );
      # push the named child DOM elements (which are <Simple> or <Collection>, <Parameter>)
      push @articles, [ $articleName, $child ];
    }
  return @articles;    # return them.
}
#################################################
##################################
##################################
# COMMON SUBROUTINES for Clients and Services
##################################
##################################
#################################################

=head2 getSimpleArticleIDs

B<function:> to get the IDs of simple articles that are in the given namespace

B<usage:> 

  my @ids = getSimpleArticleIDs("NCBI_gi", \@SimpleArticles);
  my @ids = getSimpleArticleIDs(\@SimpleArticles);

B<args:> 

C<$Namespace>  - (optional) a namespace stringfrom the MOBY namespace ontology, or undef if you don't care

C<\@Simples>   - (required) a listref of Simple XML::LibXML nodes i.e. the XML::LibXML representing an XML structure like this:

      <Simple>
          <Object namespace="NCBI_gi" id="163483"/>
      </Simple>

Note : If you provide a namespace, it will return *only* the ids that
are in the given namespace, but will return 'undef' for any articles
in the WRONG namespace so that you get an equivalent number of outputs
to inputs.

Note that if you call this with a single argument, this is assumed to
be C<\@Articles>, so you will get ALL id's regardless of namespace!

=cut


sub getSimpleArticleIDs {
  my ( $desired_namespace, $input_nodes ) = @_;
  if ( $desired_namespace && !$input_nodes )
    {    # if called with ONE argument, then these are the input nodes!
      $input_nodes       = $desired_namespace;
      $desired_namespace = undef;
    }
  $input_nodes = [$input_nodes]
    unless ref( $input_nodes ) eq 'ARRAY';    # be flexible!
  return undef unless scalar @{$input_nodes};
  my @input_nodes = @{$input_nodes};
  my $OS          = MOBY::Client::OntologyServer->new;
  my ( $s, $m, $namespace_lsid );
  if ( $desired_namespace ) {
    ( $s, $m, $namespace_lsid ) =
      $OS->namespaceExists( term => $desired_namespace ); # returns (success, message, lsid)
    unless ( $s ) {    # bail if not successful
      # Printing to STDERR is not very helpful - we should probably return something that can be dealt iwth programatically....
      die("MOBY::CommonSubs: the namespace '$desired_namespace' "
	   . "does not exist in the MOBY ontology, "
	   . "and does not have a valid LSID");
#      return undef;
    }
    $desired_namespace = $namespace_lsid; # Replace namespace with fully-qualified LSID
  }
  my @ids;
  foreach my $in ( @input_nodes ) {
    next unless $in;
    #$in = "<Simple><Object namespace='' id=''/></Simple>"
    next unless $in->nodeName =~ /^(moby:|)Simple$/;    # only allow simples
    my @simples = $in->childNodes;
    foreach ( @simples ) {    # $_ = <Object namespace='' id=''/>
      next unless $_->nodeType == ELEMENT_NODE;
      if ( $desired_namespace ) {
	my $ns = _moby_getAttributeNode($_, 'namespace' ); # get the namespace DOM node
	unless ( $ns ) {    # if we don't get it at all, then move on to the next input
	    push @ids, undef;    # but push an undef onto teh stack in order
	    next;
	  }
	$ns = $ns->getValue;    # if we have a namespace, then get its value
	( $s, $m, $ns ) = $OS->namespaceExists( term => $ns );
	# A bad namespace will return 'undef' which makes for a bad comparison (Perl warning).
	# Better to check directly for success ($s), THEN check that namespace is the one we wanted.
	unless ( $s && $ns eq $desired_namespace )
	  { # we are registering as working in a particular namespace, so check this
	    push @ids, undef;    # and push undef onto the stack if it isn't
	    next;
	  }
      }

      # Now do the same thing for ID's
      my $id = _moby_getAttributeNode($_, 'id' );
      unless ( $id ) {
	push @ids, undef;
	next;
      }
      $id = $id->getValue;
      unless ( defined $id ) {    # it has to have a hope in hell of retrieving something...
	  push @ids, undef;    # otherwise push undef onto the stack if it isn't
	  next;
	}
      push @ids, $id;
    }
  }
  return @ids;
}

=head2 getSimpleArticleNamespaceURI

B<function:> to get the namespace of a simple article

B<usage:> C<my $ns = getSimpleArticleNamespaceURI($SimpleArticle);>

B<args:> C<$Simple> - (required) a single XML::LibXML node
representing a Simple Article i.e. the XML::LibXML representing an XML
structure like this:

      <Simple>
          <Object namespace="NCBI_gi" id="163483"/>
      </Simple>

=cut


sub getSimpleArticleNamespaceURI {

# pass me a <SIMPLE> input node and I will give you the lsid of the namespace of that input object
  my ( $input_node ) = @_;
  return undef unless $input_node;
  my $OS = MOBY::Client::OntologyServer->new;

  #$input_node = "<Simple><Object namespace='' id=''/></Simple>"
  my @simples = $input_node->childNodes;
  foreach ( @simples )
    { # $_ = <Object namespace='' id=''/>   # should be just one, so I will return at will from this routine
      next unless $_->nodeType == ELEMENT_NODE;
      my $ns = _moby_getAttributeNode($_, 'namespace' );     # get the namespace DOM node
	return undef unless ( $ns ); # if we don't get it at all, then move on to the next input
      my ( $s, $m, $lsid ) =
	$OS->namespaceExists( term => $ns->getValue );   # if we have a namespace, then get its value
      return undef unless $s;
      return $lsid;
    }
}

sub _string_to_DOM {
# Convert string to DOM.
# If DOM passed in, just return it (i.e., this should be idempotent)
# By Frank Gibbons, Aug. 2005
# Utility subroutine, not for external use (no export), widely used in this package.
  my $XML = shift;
  my $moby;
  return $XML if ( ref($XML) =~ /^XML\:\:LibXML/ );

  my $parser = XML::LibXML->new();
  my $doc;
  eval { $doc = $parser->parse_string( $XML ) };
  die("CommonSubs couldn't parse XML '$XML' because\n\t$@") if $@;
  return $doc->getDocumentElement();
}

=head2 getInputs

B<function:> get the mobyData block(s) as XML::LibXML nodes

B<usage:> C<@queryInputs = getInputArticles($XML)>

B<args:> the raw XML of a <MOBY> query, or an XML::LibXML document

B<returns:> a list of XML::LibXML::Node's, each is a queryInput or mobyData block.

B< Note:> Remember that these blocks are enumerated!  This is what you
pass as the third argument to the simpleResponse or collectionResponse
subroutine to associate the numbered input to the numbered response

=cut

sub getInputs {
  my ( $XML ) = @_;
  my $moby =  _string_to_DOM($XML);
  my @queries;
  foreach my $querytag qw( queryInput moby:queryInput mobyData moby:mobyData )
    {
      my $x = $moby->getElementsByTagName( $querytag );    # get the mobyData block
      for ( 1 .. $x->size() ) {    # there may be more than one mobyData per message
	push @queries, $x->get_node( $_ );
      }
    }
  return @queries;    # return them in the order that they were discovered.
}

=head2 getInputID

B<function:> get the value of the queryID element

B<usage:> C<@queryInputs = getInputID($XML)>

B<args:> the raw XML or XML::LibXML of a queryInput or mobyData block (e.g. from getInputs)

B<returns:> integer, or ''

B< Note:> Inputs and Responses are coordinately enumerated!  The
integer you get here is what you pass as the third argument to the
simpleResponse or collectionResponse subroutine to associate the
numbered input to the numbered response

=cut

sub getInputID {
  my ( $XML ) = @_;
  my $moby = _string_to_DOM($XML);
  return '' unless ( $moby->nodeName =~ /^(moby:|)queryInput|mobyData$/ );
  my $qid =  _moby_getAttribute($moby, 'queryID' );
  return defined( $qid ) ? $qid : '';
}

=head2 getArticlesAsObjects

  DO NOT USE!!

B<function:> get the Simple/Collection articles for a single mobyData
or queryResponse node, rethrning them as SimpleArticle,
SecondaryArticle, or ServiceInstance objects

B<usage:> C<@articles = getArticles($XML)>

B<args:> raw XML or XML::LibXML of a moby:mobyData block

B<returns:>

=cut

sub getArticlesAsObjects {
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef unless $moby->nodeType == ELEMENT_NODE;
  return undef
    unless ($moby->nodeName =~ /^(moby:|)(queryInput|queryResponse|mobyData)$/);
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
      next
	unless ( $child->nodeName =~ /^(moby:|)(Simple|Collection|Parameter)$/ );
      my $object;
      if ( $child->nodeName =~ /^(moby:|)Simple$/ ) {
	$object = MOBY::Client::SimpleArticle->new( XML_DOM => $child );
      } elsif ( $child->nodeName =~ /^(moby:|)Collection$/ ) {
	$object = MOBY::Client::CollectionArticle->new( XML_DOM => $child );
      } elsif ( $child->nodeName =~ /^(moby:|)Parameter$/ ) {
	$object = MOBY::Client::SecondaryArticle->new( XML_DOM => $child );
      }
      next unless $object;
      push @articles, $object;  # take the child elements, which are <Simple/> or <Collection/>
    }
  return @articles;    # return them.
}

=head2 getCollectedSimples

B<function:> get the Simple articles collected in a moby:Collection block

B<usage:> C<@Simples = getCollectedSimples($XML)>

B<args:> raw XML or XML::LibXML of a moby:Collection block

B<returns:> a list of XML::LibXML nodes, each of which is a moby:Simple block

=cut

sub getCollectedSimples {
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  return undef unless $moby->nodeType == ELEMENT_NODE;
  return undef unless ( $moby->nodeName =~ /^(moby\:|)Collection$/ );
  my @articles;
  foreach my $child ( $moby->childNodes )
    { # there may be more than one Simple/Collection per input; iterate over them
      next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
      next unless ( $child->nodeName =~ /^(moby\:|)Simple$/ );
      push @articles, $child; # take the child elements, which are <Simple/> or <Collection/>
    }
  return @articles;    # return them.
}

=head2 getInputArticles


B<function:> get the Simple/Collection articles for each input query, in order

B<usage:> C<@queries = getInputArticles($XML)>

B<args:> the raw XML of a moby:MOBY query

B<returns:> a list of listrefs, each listref is the input to a single
query.  Remember that the input to a single query may be one or more
Simple and/or Collection articles.  These are provided as XML::LibXML
nodes.

            i.e.:  @queries = ([$SIMPLE_DOM_NODE], [$SIMPLE_DOM_NODE2])
            or  :  @queries = ([$COLLECTION_DOM_NODE], [$COLLECTION_DOM_NODE2])

The former is generated from the following XML:

                ...
              <moby:mobyContent>
                <moby:mobyData>
                    <Simple>
                      <Object namespace=blah id=blah/>
                    </Simple>
                </moby:mobyData>
                <moby:mobyData>
                    <Simple>
                      <Object namespace=blah id=blah/>
                    </Simple>
                </moby:mobyData>
              </moby:mobyContent>
                 ...

=cut

sub getInputArticles {
  my ( $moby ) = @_;
  $moby = _string_to_DOM($moby);
  my $x;
  foreach ( 'queryInput', 'moby:queryInput', 'mobyData', 'moby:mobyData' ) {
    $x = $moby->getElementsByTagName( $_ );    # get the mobyData block
    last if $x->get_node( 1 );
  }
  return undef unless $x->get_node( 1 );   # in case there was no match at all
  my @queries;
  for ( 1 .. $x->size() ) {  # there may be more than one mobyData per message
    my @this_query;
    foreach my $child ( $x->get_node( $_ )->childNodes )
      { # there may be more than one Simple/Collection per input; iterate over them
	next unless $child->nodeType == ELEMENT_NODE;    # ignore whitespace
	push @this_query, $child;  # take the child elements, which are <Simple/> or <Collection/>
      }
    push @queries, \@this_query;
  }
  return @queries;    # return them in the order that they were discovered.
}

=head2 extractRawContent

B<function:> pass me an article (Simple, or Collection) and I'll give
you the content AS A STRING - i.e. the raw XML of the contained MOBY
Object(s)

B<usage:> C<extractRawContent($simple)>

B<input:> the one element of the output from getArticles

B<returns:> string

=cut

sub extractRawContent {
  my ( $article ) = @_;
  return "" unless ( $article || (ref( $article ) =~ /XML\:\:LibXML/) );
  my $response;
  foreach ( $article->childNodes ) {
    $response .= $_->toString;
  }
#  print STDERR "RESPONSE = $response\n";
  return $response;
}

=head2 getNodeContentWithArticle

B<function:> a very flexible way to get the stringified content of a
node that has the correct element and article name or get the value of
a Parameter element.

B<usage:> C<@strings = getNodeContentWithArticle($node, $tagname, $articleName)>

B<args:> (in order)

C<$node>        - an XML::LibXML node, or straight XML.  It may even be the entire mobyData block.
C<$tagname>     - the tagname (effectively from the Object type ontology),  or "Parameter" if you are trying to get secondaries
C<$articleName> - the articleName that we are searching for.  to get the content of the primary object, leave this field blank!


B<returns:> an ARRAY of the stringified text content for each
node that matched the tagname/articleName specified; one
array element for each matching node.  Newlines are NOT considered
new nodes (as they are in normal XML).

B<notes:> This was written for the purpose of getting the values of
String, Integer, Float, Date_Time, and other such primitives.

For example, in the following XML:

             ...
             <moby:mobyContent>
                <moby:mobyData>
                    <Simple>
                      <Sequence namespace=blah id=blah>
                           <Integer namespace='' id='' articleName="Length">3</Integer>
                           <String namespace='' id='' articleName="SequenceString">ATG</String>
                      </Sequence>
                    </Simple>
                </moby:mobyData>
             </moby:mobyContent>
             ...

would be analysed as follows:

              # get $input - e.g. from genericServiceInputParser or complexServiceInputParser
              @sequences = getNodeContentWithArticle($input, "String", "SequenceString");

For Parameters, such as the following

             ...
             <moby:mobyContent>
                <moby:mobyData>
                    <Simple>
                      <Sequence namespace=blah id=blah>
                           <Integer namespace='' id='' articleName="Length">3</Integer>
                           <String namespace='' id='' articleName="SequenceString">ATG</String>
                      </Sequence>
                    </Simple>
                    <Parameter articleName='cutoff'>
                        <Value>24</Value>
                    </Parameter>
                </moby:mobyData>
             </moby:mobyContent>
             ...

You would parse it as follows:

              # get $input - e.g. from genericServiceInputParser or complexServiceInputParser
              @sequences = getNodeContentWithArticle($input, "String", "SequenceString");
              @cutoffs = getNodeContentWithArticle($input, "Parameter", "cutoff");


 EXAMPLE  :
           my $inputs = complexServiceInputParser($MOBY_mssage));
               # $inputs->{$queryID} = [ [TYPE, $DOM], [TYPE, $DOM], [TYPE, $DOM] ]
           my (@enumerated) = keys %{$inputs};
           foreach $no (@enumerated){
             my @articles = @{$inputs->{$no}};
             foreach my $article(@articles){
                my ($type, $DOM) = @{$article};
                if ($type == SECONDARY){
                    ($cutoff) = getNodeContentsWithArticle($DOM, "Parameter", "cutoff");
                } else {
                   @sequences = getNodeContentWithArticle($DOM, "String", "SequenceString");
                }
             }
           }

=cut

sub getNodeContentWithArticle {
  # give me a DOM, a TagName, an articleName and I will return you the content
  # of that node **as a string** (beware if there are additional XML tags in there!)
  # this is meant for MOBYesque PRIMITIVES - things like:
  # <String articleName="SequenceString">TAGCTGATCGAGCTGATGCTGA</String>
  # call _getNodeContentsWithAttribute($DOM_NODE, "String", "SequenceString")
  # and I will return "TACGATGCTAGCTAGCGATCGG"
  # Caveat Emptor - I will NOT chop off leading and trailing whitespace or
  # carriage returns, as these might be meaningful!
  my ( $node, $element, $articleName ) = @_;
  my @contents;
  return () unless ( (ref( $node ) =~ /XML\:\:LibXML/) &&  $element);


  my $nodes = $node->getElementsByTagName( $element );
  unless ( $nodes->get_node( 1 ) ) {
    $nodes = $node->getElementsByTagName("moby:$element");
  }
  $node = $nodes->get_node(1);  # this routine should only ever be called if there is only one possible answer, so this is safe
  
  unless ($articleName){  # the request is for root node if no articleName
    my $resp;
    foreach my $child($node->childNodes){
      next unless ($child->nodeType == TEXT_NODE
		   || $child->nodeType == CDATA_SECTION_NODE);
      $resp .= $child->nodeValue;
    }
    push @contents, $resp;
    return @contents;
  }

  # if there is an articleName, then get that specific node
  for ( 1 .. $nodes->size() ) {
    my $child = $nodes->get_node( $_ );
    if ( _moby_getAttribute($child, "articleName")
	 && ( $child->getAttribute("articleName") eq $articleName )
       )
      {
	# now we have a valid child, get the content... stringified... regardless of what it is
	if ( isSecondaryArticle( $child ) ) {
	  my $resp;
	  my $valuenodes = $child->getElementsByTagName('Value');
	  unless ( $valuenodes->get_node( 1 ) ) {
	    $valuenodes = $child->getElementsByTagName("moby:Value");
	  }
	  for ( 1 .. $valuenodes->size() ) {
	    my $valuenode = $valuenodes->get_node( $_ );
	    foreach my $amount ( $valuenode->childNodes ) {
	      next unless ($amount->nodeType == TEXT_NODE
			   || $amount->nodeType == CDATA_SECTION_NODE);
	      $resp .= $amount->nodeValue;
	    }
	  }
	  push @contents, $resp;
	} else {
	  my $resp;
	  foreach ( $child->childNodes ) {
	    next unless ($_->nodeType == TEXT_NODE
			 || $_->nodeType == CDATA_SECTION_NODE);
	    $resp .= $_->nodeValue;
	  }
	  push @contents, $resp;
	}
      }
  }
  return @contents;
}

*getResponseArticles = \&extractResponseArticles;
*getResponseArticles = \&extractResponseArticles;

=head2 getResponseArticles (a.k.a. extractResponseArticles)

B<function:> get the DOM nodes corresponding to individual Simple or Collection outputs from a MOBY Response

B<usage:> C<($collections, $simples) = getResponseArticles($node)>

B<args:> C<$node> - either raw XML or an XML::LibXML::Document to be searched

B<returns:> an array-ref of Collection article XML::LibXML::Node's or  an array-ref of Simple article XML::LibXML::Node's

=cut

sub extractResponseArticles {
	my ( $result ) = @_;
	return ( [], [] ) unless $result;
	my $moby;
	unless ( ref( $result ) =~ /XML\:\:LibXML/ ) {
		my $parser = XML::LibXML->new();
		my $doc    = $parser->parse_string( $result );
		$moby = $doc->getDocumentElement();
	} else {
		$moby = $result->getDocumentElement();
	}
	my @objects;
	my @collections;
	my @Xrefs;
	my $success = 0;
	foreach my $which ( 'moby:queryResponse', 'queryResponse',
			    'mobyData', 'moby:mobyData' )
	{
		my $responses = $moby->getElementsByTagName( $which );
		next unless $responses;
		foreach my $n ( 1 .. ( $responses->size() ) ) {
			my $resp = $responses->get_node( $n );
			foreach my $response_component ( $resp->childNodes ) {
				next unless $response_component->nodeType == ELEMENT_NODE;
				if ( $response_component->nodeName =~ /^(moby:|)Simple$/ )
				  {
					foreach my $Object ( $response_component->childNodes ) {
						next unless $Object->nodeType == ELEMENT_NODE;
						$success = 1;
						push @objects, $Object;
					}
				} elsif ( $response_component->nodeName =~ /^(moby:|)Collection$/ )
				{
					my @objects;
					foreach my $simple ( $response_component->childNodes ) {
						next unless $simple->nodeType == ELEMENT_NODE;
						next unless ( $simple->nodeName =~ /^(moby:|)Simple$/ );
						foreach my $Object ( $simple->childNodes ) {
							next unless $Object->nodeType == ELEMENT_NODE;
							$success = 1;
							push @objects, $Object;
						}
					}
					push @collections, \@objects
					  ;  #I'm not using collections yet, so we just use Simples.
				}
			}
		}
	}
	return ( \@collections, \@objects );
}



=head1 IDENTITY AND VALIDATION

This section describes functionality associated with identifying parts of a message,
and checking that it is valid.

=head2 isSimpleArticle, isCollectionArticle, isSecondaryArticle

B<function:> tests XML (text) or an XML DOM node to see if it represents a Simple, Collection, or Secondary article

B<usage:> 

  if (isSimpleArticle($node)){do something to it}

or

  if (isCollectionArticle($node)){do something to it}

or

 if (isSecondaryArticle($node)){do something to it}

B< input :> an XML::LibXML node, an XML::LibXML::Document or straight XML

B<returns:> boolean

=cut

sub isSimpleArticle {
  my ( $DOM ) = @_;
  eval { $DOM = _string_to_DOM($DOM) };
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ($DOM->nodeName =~ /^(moby:|)Simple$/) ? 1 : 0; #Optional 'moby:' namespace prefix
}

sub isCollectionArticle {
  my ( $DOM ) = @_;
  eval {$DOM = _string_to_DOM($DOM) };
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ( $DOM->nodeName =~ /^(moby\:|)Collection$/ ) ? 1 : 0; #Optional 'moby:' prefix
}

sub isSecondaryArticle {
  my ( $XML ) = @_;
  my $DOM;
  eval {$DOM = _string_to_DOM($XML)} ;
  return 0 if $@;
  $DOM = $DOM->getDocumentElement if ( $DOM->isa( "XML::LibXML::Document" ) );
  return ($DOM->nodeName =~ /^(moby\:|)Parameter$/) ? 1 : 0; #Optional 'moby:' prefix
}


=head2 validateNamespaces

B<function:> checks the namespace ontology for the namespace lsid

B<usage:> C<@LSIDs = validateNamespaces(@namespaces)>

B<args:> ordered list of either human-readable or lsid presumptive namespaces

B<returns:> ordered list of the LSID's corresponding to those
presumptive namespaces; undef for each namespace that was invalid

=cut

sub validateNamespaces {
  # give me a list of namespaces and I will return the LSID's in order
  # I return undef in that list position if the namespace is invalid
  my ( @namespaces ) = @_;
  my $OS = MOBY::Client::OntologyServer->new;
  my @lsids;
  foreach ( @namespaces ) {
    my ( $s, $m, $LSID ) = $OS->namespaceExists( term => $_ );
    push @lsids, $s ? $LSID : undef;
  }
  return @lsids;
}

=head2 validateThisNamespace

B<function:> checks a given namespace against a list of valid namespaces

B<usage:> C<$valid = validateThisNamespace($ns, @validNS);>

B<args:> ordered list of the namespace of interest and the list of valid NS's

B<returns:> boolean

=cut

sub validateThisNamespace {
  my ( $ns, @namespaces ) = @_;
  return 1 unless scalar @namespaces; # if you don't give me a list, I assume everything is valid...
  @namespaces = @{$namespaces[0]}  # if you send me an arrayref I should be kind... DWIM!
    if ( ref $namespaces[0] eq 'ARRAY' );
  return grep /$ns/, @namespaces;
}


=head1 ANCILIARY ELEMENTS

This section contains subroutines that handle processing of optional message elements containing
meta-data. Examples are the ServiceNotes, and CrossReference blocks.

=head2 getServiceNotes

B<function:> to get the content of the Service Notes block of the MOBY message

B<usage:> C<getServiceNotes($message)>

B<args:> C<$message> is either the XML::LibXML of the MOBY message, or plain XML

B<returns:> String content of the ServiceNotes block of the MOBY Message

=cut

sub getServiceNotes {
  my ( $result ) = @_;
  return ( "" ) unless $result;
  my $moby = _string_to_DOM($result);

  my $responses = $moby->getElementsByTagName( 'moby:serviceNotes' )
    || $moby->getElementsByTagName( 'serviceNotes' );
  my $content;
  foreach my $n ( 1 .. ( $responses->size() ) ) {
    my $resp = $responses->get_node( $n );
    foreach my $response_component ( $resp->childNodes ) {
      #            $content .= $response_component->toString;
      $content .= $response_component->nodeValue
	if ( $response_component->nodeType == TEXT_NODE );
      $content .= $response_component->nodeValue
	if ( $response_component->nodeType == CDATA_SECTION_NODE );
    }
  }
  return ( $content );
}

=head2 getCrossReferences

B<function:> to get the cross-references for a Simple article

B<usage:> C<@xrefs = getCrossReferences($XML)>

B<args:> C<$XML> is either a SIMPLE article (<Simple>...</Simple>) or an
object (the payload of a Simple article), and may be either raw XML or
an XML::LibXML node.

B<returns:> an array of MOBY::CrossReference objects

B<example:>

   my (($colls, $simps) = getResponseArticles($query);  # returns DOM nodes
   foreach (@{$simps}){
      my @xrefs = getCrossReferences($_);
      foreach my $xref(@xrefs){
          print "Cross-ref type: ",$xref->type,"\n";
          print "namespace: ",$xref->namespace,"\n";
          print "id: ",$xref->id,"\n";
          if ($xref->type eq "Xref"){
             print "Cross-ref relationship: ", $xref->xref_type,"\n";
          }
      }
   }

=cut

sub getCrossReferences {
  my ( $XML ) = @_;
  $XML = _string_to_DOM($XML);
  my @xrefs;
  my @XREFS;
  return () if ( $XML->nodeName =~ /^(moby:|)Collection$/ );
  if ( $XML->nodeName =~ /^(moby:|)Simple$/ ) {
    foreach my $child ( $XML->childNodes ) {
      next unless $child->nodeType == ELEMENT_NODE;
      $XML = $child;
      last;    # enforce proper MOBY message structure
    }
  }
  foreach ( $XML->childNodes ) {
    next unless (($_->nodeType == ELEMENT_NODE)
		 || ($_->nodeName =~ /^(moby:|)CrossReference$/) );
    foreach my $xref ( $_->childNodes ) {
      next unless ( ($xref->nodeType == ELEMENT_NODE)
		    || ($xref->nodeName =~ /^(moby:|)(Xref|Object)$/) );
      push @xrefs, $xref;
    }
  }
  foreach ( @xrefs ) {
    my $x;
    if ($_->nodeName =~ /^(moby:|)Xref$/) { $x = _makeXrefType( $_ ) }
    elsif ($_->nodeName =~ /^(moby:|)Object$/) { $x = _makeObjectType( $_ ) }
    push @XREFS, $x if $x;
  }
  return @XREFS;
}


=head1 CONSTRUCTING OUTPUT

This section describes how to construct output, in response to an
incoming message. Responses come in three varieties:

=over 4

=item *
Simple     - Only simple article(s)

=item *
Collection - Only collection(s) of simples

=item *
Complex    - Any combination of simple and/or collection and/or secondary articles.

=back

=head2 simpleResponse

B<function:> wraps a simple article in the appropriate (mobyData) structure.
Works only for simple articles. If you need to mix simples with collections and/or 
secondaries use complexReponse instead.

B<usage:> C<$responseBody = simpleResponse($object, $ArticleName, $queryID);>

B<args:> (in order)
C<$object>      - (optional) a MOBY Object as raw XML.
C<$articleName> - (optional) an article name for this article.
C<$queryID>     - (optional, but strongly recommended) the query ID value for the mobyData block to which you are responding.

B<notes:> As required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling simpleResponse(undef, undef, $queryID) with
no arguments.

=cut

sub simpleResponse {
  my ( $data, $articleName, $qID ) = @_;    # articleName optional
  $qID = _getQueryID( $qID )
    if ref( $qID ) =~ /XML\:\:LibXML/;    # in case they send the DOM instead of the ID
  $data        ||= '';    # initialize to avoid uninit value errors
  $articleName ||= "";
  $qID         ||= "";
  if ( $articleName || $data) { # Linebreaks in XML make it easier for human debuggers to read!
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
  } else {
    return "
        <moby:mobyData moby:queryID='$qID'/>
	";
  }
}


=head2 collectionResponse

B<function:> wraps a set of articles in the appropriate mobyData structure. 
Works only for collection articles. If you need to mix collections with simples and/or 
secondaries use complexReponse instead.

B<usage:> C<$responseBody = collectionResponse(\@objects, $articleName, $queryID);>

B<args:> (in order)
C<\@objects>    - (optional) a listref of MOBY Objects as raw XML.
C<$articleName> - (optional) an artice name for this article.
C<$queryID>     - (optional, but strongly recommended) the ID of the query to which you are responding.

B<notes:> as required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling collectionResponse(undef, undef, $queryID).

=cut

sub collectionResponse {
  my ( $data, $articleName, $qID ) = @_;    # articleName optional
  my $content = "";
  $data ||= [];
  $qID  ||= '';
  # The response should only be completely empty when the input $data is completely empty.
  # Testing just the first element is incorrect.
  my $not_completely_empty = 0;
  foreach (@{$data}) { $not_completely_empty += defined $_ }
  unless ( ( ref($data) eq 'ARRAY' ) && $not_completely_empty )
    {    # we're expecting an arrayref as input data, and it must not be empty
      return "<moby:mobyData moby:queryID='$qID'/>";
    }
  foreach ( @{$data} ) { # Newlines are for ease of human reading (pretty-printing). 
    # It's really hard to keep this kind of thing in sync with itself, but for what it's worth, let's leave it in.
    if ( $_ ) {
      $content .= "<moby:Simple>$_</moby:Simple>\n";
    } else {
      $content .= "<moby:Simple/>\n";
    }
  }
  if ( $articleName ) {
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>
                $content
            </moby:Collection>
        </moby:mobyData>
        ";
  } else {
    return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>$content</moby:Collection>
        </moby:mobyData>
        ";
  }
}

=head2 complexResponse

B<function:> wraps articles in the appropriate (mobyData) structure. 
Can be used to send any combination of the three BioMOBY article types - 
simple, collection and secondary - back to a client.

B<usage:> C<$responseBody = complexResponse(\@articles, $queryID);>

B<args:> (in order)

C<\@articles>   - (optional) a listref of arrays. Each element of @articles is
itself a listref of [$articleName, $article], where $article is either
the article's raw XML for simples and secondaries or a reference to an array containing 
[$articleName, $simpleXML] elements for a collection of simples.

C<$queryID> - (optional, but strongly recommended) the queryID value for
the mobyData block to which you are responding

B<notes:> as required by the API you must return a response for every
input.  If one of the inputs was invalid, you return a valid (empty)
MOBY response by calling complexResponse(undef, $queryID) with no
arguments.

=cut

sub complexResponse {
  my ( $data, $qID ) = @_;
  #return 'ERROR:  expected listref [element1, element2, ...] for data' unless ( ref( $data ) =~ /array/i );
  return "<moby:mobyData moby:queryID='$qID'/>\n"
    unless ( ref( $data ) eq 'ARRAY' );
  $qID = _getQueryID( $qID )
    if ref( $qID ) =~ /XML\:\:LibXML/;    # in case they send the DOM instead of the ID
  my @inputs = @{$data};
  my $output = "<moby:mobyData queryID='$qID'>";
  foreach ( @inputs ) {
    #return 'ERROR:  expected listref [articleName, XML] for data element' unless ( ref( $_ ) =~ /array/i );
    return "<moby:mobyData moby:queryID='$qID'/>\n" 
      unless ( ref($_) eq 'ARRAY' );
    while ( my ( $articleName, $XML ) = splice( @{$_}, 0, 2 ) ) {
      if ( ref($XML) ne 'ARRAY' ) {
        $articleName ||= "";
        $XML         ||= "";
        if ( $XML =~ /\<(moby:|)Value\>/ ) {
          $output .=
            "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>\n";
        } else {
          $output .=
            "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
        }
      # Need to do this for collections also!!!!!!
      } else {
        my @objs = @{$XML};
        $output .= "<moby:Collection moby:articleName='$articleName'>\n";
        foreach ( @objs ) {
          $output .= "<moby:Simple>$_</moby:Simple>\n";
        }
        $output .= "</moby:Collection>\n";
      }
    }
  }
  $output .= "</moby:mobyData>\n";
  return $output;
}

=head2 responseHeader

B<function:> print the XML string of a MOBY response header +/- serviceNotes

B<usage:> 

  responseHeader('illuminae.com')

  responseHeader(
                -authority => 'illuminae.com',
                -note => 'here is some data from the service provider')

B<args:> a string representing the service providers authority URI, OR
a set of named arguments with the authority and the service provision
notes.

B< caveat   :>

B<notes:>  returns everything required up to the response articles themselves. i.e. something like:
 
 <?xml version='1.0' encoding='UTF-8'?>
    <moby:MOBY xmlns:moby='http://www.biomoby.org/moby'>
       <moby:Response moby:authority='http://www.illuminae.com'>

=cut

sub responseHeader {
  use HTML::Entities ();
  my ( $auth, $notes ) = _rearrange( [qw[AUTHORITY NOTE]], @_ );
  $auth  ||= "not_provided";
  $notes ||= "";
  my $xml =
    "<?xml version='1.0' encoding='UTF-8'?>"
      . "<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' xmlns='http://www.biomoby.org/moby'>"
	. "<moby:mobyContent moby:authority='$auth'>";
  if ( $notes ) {
    my $encodednotes = HTML::Entities::encode( $notes );
    $xml .= "<moby:serviceNotes>$encodednotes</moby:serviceNotes>";
  }
  return $xml;
}

=head2 responseFooter

B<function:> print the XML string of a MOBY response footer

B<usage:> 
 
 return responseHeader('illuminae.com') . $DATA . responseFooter;

B<notes:>  returns everything required after the response articles themselves i.e. something like:

  </moby:Response>
     </moby:MOBY>

=cut

sub responseFooter {
  return "</moby:mobyContent></moby:MOBY>";
}



=head1 MISCELLANEOUS

This section contains routines that didn't quite seem to fit anywhere else.

=cut

=head2 _moby_getAttributeNode, _moby_getAttribute

B<function:> Perform the same task as the DOM routine
getAttribute(Node), but check for both the prefixed and un-prefixed
attribute name (the prefix in question being, of course,
"moby:"). 

B<usage:>

  $id = _moby_getAttribute($xml_libxml, "id");

where C<id> is an attribute in the XML block given as C<$xml_libxml>

B<notes:> This function is intended for use internal to this package
only. It's not exported.

=cut

sub _moby_getAttributeNode {
  # Mimics behavior of XML::LibXML method getAttributeNode, but if the unqualified attribute cannot be found,
  # we qualify it with "moby:" and try again.
  # We do this so often this module, it's worth having a separate subroutine to do this.
  my ($xref, $attr) = @_;
  my ($package, $filename, $line) = caller;
  if ( !(ref($xref) =~ "^XML\:\:LibXML") ) {
    warn "_moby_getAttributeNode: Looking for attribute '$attr'"
      . "Can't parse non-XML argument '$xref',\n"
	. " called from line $line";
    return '';
  }
  if (!defined $attr) {
    warn "_moby_getAttributeNode: Non-empty attribute is required"
      . "\n called from line $line";
    return '';
  }
  return ( $xref->getAttributeNode($attr) || $xref->getAttributeNode( "moby:$attr" ) );
}

sub _moby_getAttribute {
  # Mimics behavior of XML::LibXML method getAttribute, but if the unqualified attribute cannot be found,
  # we qualify it with "moby:" and try again.
  # We do this so often this module, it's worth having a separate subroutine to do this.
  my ($xref, $attr) = @_;
  my ($package, $filename, $line) = caller;
  if ( !(ref($xref) =~ "^XML\:\:LibXML")) {
    warn "_moby_getAttribute: Looking for attribute '$attr', "
    ."can't parse non-XML argument '$xref'\n"
      . "_moby_getAttribute called from line $line";
    return '';
  }
  if (!defined $attr) {
    warn "_moby_getAttribute: Non-empty attribute is required"
    . "\n called from line $line";
    return '';
  }
  return (   $xref->getAttribute($attr) || $xref->getAttribute("moby:$attr") );
}

=head2 whichDeepestParentObject

B<function:> select the parent node from nodeList that is closest to the querynode

B<usage:> 

  ($term, $lsid) = whichDeepestParentObject($CENTRAL, $queryTerm, \@termList)

B<args:> 

C<$CENTRAL> - your MOBY::Client::Central object

C<$queryTerm> - the object type I am interested in

C<\@termlist> - the list of object types that I know about

B<returns:> an ontology term and LSID as a scalar, or undef if there is
no parent of this node in the nodelist.  note that it will only return
the term if you give it term names in the @termList.  If you give it
LSID's in the termList, then both the parameters returned will be
LSID's - it doesn't back-translate...)

=cut

sub whichDeepestParentObject {
	my ( $CENTRAL, $queryTerm, $termlist ) = @_;
	return ( undef, undef )
	  unless ( $CENTRAL && $queryTerm 
		   && $termlist && ( ref( $termlist ) eq 'ARRAY' ) );
	my %nodeLSIDs;
	my $queryLSID = $CENTRAL->ObjLSID( $queryTerm );
	foreach ( @$termlist ) {    # get list of known LSIDs
	  my $lsid = $CENTRAL->ObjLSID( $_ );
	  return ( $_, $lsid )
	    if ( $lsid eq $queryLSID );   # of course, if we find it in the list, then return it right away!
	  $nodeLSIDs{$lsid} = $_;
	}
	return ( undef, undef ) unless keys( %nodeLSIDs );
	my $isa =
	  $CENTRAL->ISA( $queryTerm, 'Object' )
	  ;       # set the complete parentage in the cache if it isn't already
	return ( undef, undef )
	  unless $isa;    # this should return true or we are in BIIIG trouble!
	my @ISAlsids =
	  $CENTRAL->ISA_CACHE( $queryTerm )
	  ;    # returns **LSIDs** in order, so we can shift our way back to root
	while ( my $thislsid = shift @ISAlsids ) {    # @isas are lsid's
		return ( $nodeLSIDs{$thislsid}, $thislsid ) if $nodeLSIDs{$thislsid};
	}
	return ( undef, undef );
}


sub _makeXrefType {
  my ( $xref ) = @_;
  my $ns = _moby_getAttributeNode($xref, 'namespace' );
  return undef unless $ns;
  my $id = _moby_getAttributeNode($xref, 'id' );
  return undef unless $id;
  my $xr = _moby_getAttributeNode($xref, 'xref_type' );
  return undef unless $xr;
  my $ec = _moby_getAttributeNode($xref, 'evidence_code' );
  return undef unless $ec;
  my $au = _moby_getAttributeNode($xref, 'authURI' );
  return undef unless $au;
  my $sn = _moby_getAttributeNode($xref, 'serviceName' );
  return undef unless $sn;
  my $XREF = MOBY::CrossReference->new(
				       type          => "xref",
				       namespace     => $ns->getValue,
				       id            => $id->getValue,
				       authURI       => $au->getValue,
				       serviceName   => $sn->getValue,
				       evidence_code => $ec->getValue,
				       xref_type     => $xr->getValue
				      );
  return $XREF;
}


sub _makeObjectType {
  my ( $xref ) = @_;
  my $ns = _moby_getAttributeNode($xref, 'namespace' );
  return undef unless $ns;
  my $id = _moby_getAttributeNode($xref, 'id');
  return undef unless $id;
  my $XREF = MOBY::CrossReference->new(
				       type      => "object",
				       namespace => $ns->getValue,
				       id        => $id->getValue,
				      );
}

=head2 _rearrange (stolen from BioPerl ;-) )

B<usage:>   
         $object->_rearrange( array_ref, list_of_arguments)

B<Purpose :> Rearranges named parameters to requested order.

B<Example:> 
   $self->_rearrange([qw(SEQUENCE ID DESC)],@param);
Where C<@param = (-sequence => $s,  -desc     => $d,  -id       => $i);>

B<returns:> C<@params> - an array of parameters in the requested order.

The above example would return ($s, $i, $d).
Unspecified parameters will return undef. For example, if
       C<@param = (-sequence => $s);>
the above _rearrange call would return ($s, undef, undef)

B<Argument:> C<$order> : a reference to an array which describes the desired order of the named parameters.

C<@param :> an array of parameters, either as a list (in which case the function
simply returns the list), or as an associative array with hyphenated
tags (in which case the function sorts the values according to
@{$order} and returns that new array.)  The tags can be upper, lower,
or mixed case but they must start with a hyphen (at least the first
one should be hyphenated.)

B< Source:> This function was taken from CGI.pm, written by
Dr. Lincoln Stein, and adapted for use in Bio::Seq by Richard Resnick
and then adapted for use in Bio::Root::Object.pm by Steve Chervitz,
then migrated into Bio::Root::RootI.pm by Ewan Birney.

B<Comments:>
Uppercase tags are the norm, (SAC) This method may not be appropriate
for method calls that are within in an inner loop if efficiency is a
concern.

Parameters can be specified using any of these formats:
  @param = (-name=>'me', -color=>'blue');
  @param = (-NAME=>'me', -COLOR=>'blue');
  @param = (-Name=>'me', -Color=>'blue');
  @param = ('me', 'blue');

A leading hyphenated argument is used by this function to indicate
that named parameters are being used.  Therefore, the ('me', 'blue')
list will be returned as-is.

Note that Perl will confuse unquoted, hyphenated tags as function
calls if there is a function of the same name in the current
namespace:  C<-name => 'foo'> is interpreted as C<-&name => 'foo'>

For ultimate safety, put single quotes around the tag: C<('-name'=>'me', '-color' =>'blue');>

This can be a bit cumbersome and I find not as readable as using all
uppercase, which is also fairly safe:C<(-NAME=>'me', -COLOR =>'blue');>

Personal note (SAC): I have found all uppercase tags to be more
managable: it involves less single-quoting, the key names stand out
better, and there are no method naming conflicts.  The drawbacks are
that it's not as easy to type as lowercase, and lots of uppercase can
be hard to read. Regardless of the style, it greatly helps to line the parameters up
vertically for long/complex lists.

=cut

sub _rearrange {
	#    my $dummy = shift;
	my $order = shift;
	return @_ unless ( substr( $_[0] || '', 0, 1 ) eq '-' );
	push @_, undef unless $#_ % 2;
	my %param;
	while ( @_ ) {
		( my $key = shift ) =~ tr/a-z\055/A-Z/d;    #deletes all dashes!
		$param{$key} = shift;
	}
	map { $_ = uc( $_ ) } @$order;  # for bug #1343, but is there perf hit here?
	return @param{@$order};
}

sub _getQueryID {
  my ( $query ) = @_;
  $query = _string_to_XML($query);
  return '' unless ( $query->nodeName =~ /^(moby:|)(queryInput|mobyData)$/ ); #Eddie - unsure
  return _moby_getAttribute($query, 'queryID' );
}

