package MOBYXSLT;

my $TMP_DIR   = '/tmp/';#Where your temporary files will be written
my $XSLTPROC  = '/usr/bin/xsltproc';#Where your xsltproc binary is located
my $XSL_SHEET = '/bioinfo/www/bioinfo/services/biomoby/cgi-bin/Services/LIPM/lib/parseMobyMessage.xsl';#Where your xsltproc style-sheet is located

#$Id: MOBYXSLT.pm,v 1.4 2005/12/15 14:03:41 carrere Exp $

=pod

=head1 NAME

MOBYXSLT - CommonSubs using XSLT

=head1 WHY

Because huge XML message parsing with XML::Dom take too much time.
xsltproc is a binary very  very efficient to parse huge files.


=head1 TO BE EDITED

    Globals variables are defined in this package:
    
	my $TMP_DIR   = '/tmp/'; #Where your temporary files will be written
	my $XSLTPROC  = '/usr/bin/xsltproc'; #Where your xsltproc binary is located
	my $XSL_SHEET = './parseMobyMessage.xsl'; #Where your xsltproc style-sheet is located


=head1 SYNOPSIS

sub MonWebservice
{

    my ($caller, $message) = (@_);

    my $moby_response;

    my $service_name = 'MonWebservice';

    #Message Parsing
    my ($service_notes,$ra_queries) = MOBYXSLT::getInputs($message); #Message Parsing
    
    foreach my $query (@{$ra_queries})
    {
        my $query_id = MOBYXSLT::getInputID($query);#Retrieve Query ID
	    my @a_input_articles = MOBYXSLT::getArticles($query);#Retrieve articles
        
        my ($fasta_sequences, $fasta_namespace, $fasta_id)  = ('','','');

        foreach my $input_article (@a_input_articles)
        {
            my ($article_name, $article) = @{$input_article};

            if (MOBYXSLT::isSimpleArticle($article))
            {
        		my $object_type = MOBYXSLT::getObjectType($article);
                
        		if (IsTheCorrectType($object_type))
                {
                        $fasta_sequences = MOBYXSLT::getObjectContent($article);
			            $fasta_namespace = MOBYXSLT::getObjectNamespace($article);
			            $fasta_id = MOBYXSLT::getObjectId($article);
                }
            }
            elsif (MOBYXSLT::isCollectionArticle($article))
            {
            }

            elsif (MOBYXSLT::isSecondaryArticle($article))
            {
	    	    my ($param_name,$param_value) = MOBYXSLT::getParameter($article);#Retrieve parameters
            }
        }

	######
	#What you want to do with your data
	######
	
	
        my $cmd ="...";

        system("$cmd");

       	
	
	
	#########
	#Send result
	#########
        
        $moby_response .= MOBYXSLT::simpleResponse("<$output_object_type1>$out_data</$output_object_type1>", $output_article_name1, $query_id);
     }
 	
    
    return SOAP::Data->type(
         'base64' => (MOBYXSLT::responseHeader(-authority => $auth_uri, -note => "Documentation about $service_name at $url_doc"))
           . $moby_response
           . MOBYXSLT::responseFooter());

}

=head1 GLOBALS

	my $TMP_DIR   = '/tmp/'; #Where your temporary files will be written
	my $XSLTPROC  = '/usr/bin/xsltproc'; #Where your xsltproc binary is located
	my $XSL_SHEET = './parseMobyMessage.xsl'; #Where your xsltproc style-sheet is located

    
=head1 DESCRIPTION

	Note: many functions have same names as those from MOBY::CommonSubs

=cut


use strict;
use Carp;

=head2 function getInputs

 Title        : getInputs
 Usage        : my ($servicenotes, $ra_queries) = getInputs($moby_message)
 Prerequisite : 
 Function     : Parse Moby message and build Perl structures to access
 		for each query to their articles and objects.
 Returns      : $servicenotes: Notes returned by service provider
 		$ra_queries: ARRAYREF of all queries analysed in MOBY message
 Args         : $moby_message: MOBY XML message
 Globals      : $XSLTPROC: /path/to/xsltproc binary
 		$XSL_SHEET: XSL Sheet for MobyMessage Parsing
		$TMP_DIR: /where

=cut

sub getInputs
{
    my ($moby_message) = (@_);

    my $tmp_file       = 'MOBYXSLT' . $$ . $^T;
    my $header_with_ns = "<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' ";

    $moby_message =~ s/xmlns:moby/xmlns:moby2/;

    $moby_message =~ s/<moby:MOBY/$header_with_ns/;

    open(TMP, ">$TMP_DIR$tmp_file") || confess("$! :$TMP_DIR$tmp_file");
    print TMP $moby_message;
    close TMP;

    my $parsed_message = `$XSLTPROC $XSL_SHEET $TMP_DIR$tmp_file`;
    
#    open (PARSED, ">$TMP_DIR$tmp_file" . ".xsl");
#    print PARSED "$XSLTPROC $XSL_SHEET $TMP_DIR$tmp_file\n\n\n";
#    print PARSED "$parsed_message";
#    close PARSED;

    my $servicenotes = '';
    my @a_queries    = ();

    my $servicenotes_tag = '#XSL_LIPM_MOBYPARSER_SERVICENOTES#';

    if ($parsed_message =~ /$servicenotes_tag(.+)$servicenotes_tag/)
    {
        ($servicenotes) = ($parsed_message =~ /$servicenotes_tag(.+)$servicenotes_tag/);
    }

    my $mobydata_tag = '#XSL_LIPM_MOBYPARSER_DATA_START#';
    my ($header, @a_mobydata_blocs) = split($mobydata_tag, $parsed_message);

    my $query_count = 0;

    foreach my $mobydata_bloc (@a_mobydata_blocs)
    {

        my $queryid_tag = '#XSL_LIPM_MOBYPARSER_QUERYID#';
        my ($queryid) = ($mobydata_bloc =~ /$queryid_tag(.+)$queryid_tag/);

        my $article_start_tag = '#XSL_LIPM_MOBYPARSER_ARTICLE_START#';
        my ($header_article, @a_article_blocs) = split($article_start_tag, $mobydata_bloc);

        my @a_input_articles = ();

        foreach my $article_bloc (@a_article_blocs)
        {
            my $articlename_tag = '#XSL_LIPM_MOBYPARSER_ARTICLENAME#';
            my ($articlename) = ($article_bloc =~ /$articlename_tag(.+)$articlename_tag/);

            my $articletype_tag = '#XSL_LIPM_MOBYPARSER_ARTICLETYPE#';
            my ($articletype) = ($article_bloc =~ /$articletype_tag(.+)$articletype_tag/);
            $articletype =~ s/^moby://;

            my $simple_start_tag = '#XSL_LIPM_MOBYPARSER_SIMPLE_START#';

            my $article_objects = '';
            if (_IsCollection($articletype))
            {
                my ($header_collec, @a_simple_blocs) = split($simple_start_tag, $article_bloc);
                my @a_simple_objects = ();
                foreach my $simple_bloc (@a_simple_blocs)
                {
                    my $rh_simple = _AnalyseSimple($simple_bloc);
                    push(@a_simple_objects, $rh_simple);
                }
                $article_objects = \@a_simple_objects;
            }
            elsif (_IsSimple($articletype))
            {
                my ($header_collec, $simple_bloc) = split($simple_start_tag, $article_bloc);
                $article_objects = _AnalyseSimple($simple_bloc);
            }
            elsif (_IsSecondary($articletype))
            {

                my $secondary_start = '#XSL_LIPM_MOBYPARSER_SECONDARY_START#';
                my $secondary_end   = '#XSL_LIPM_MOBYPARSER_SECONDARY_END#';
                my $secondary_sep   = '#XSL_LIPM_MOBYPARSER_SECONDARY_SEP#';
                my (@a_param) = ($article_bloc =~ /$secondary_start(.+)$secondary_sep(.+)$secondary_end/);
                $article_objects = \@a_param;
            }

            my %h_input_article = (
                                   'article_type'    => $articletype,
                                   'article_name'    => $articlename,
                                   'article_objects' => $article_objects
                                   );

            push(@a_input_articles, \%h_input_article);

        }

        my %h_query = (
                       'query_id'       => $queryid,
                       'query_articles' => \@a_input_articles
                       );

        push(@a_queries, \%h_query);

    }

    unlink("$TMP_DIR$tmp_file");
    return ($servicenotes, \@a_queries);
}

=head2 function getInputID

 Title        : getInputID
 Usage        : my $query_id =getInputID($rh_query);
 Prerequisite : 
 Function     : Return query_id of a query from getInputs
 Returns      : $query_id
 Args         : $rh_query: query HASHREF structure from getInputs
 Globals      : none

=cut

sub getInputID
{
    my $rh_query = shift();
    return $rh_query->{'query_id'};
}

=head2 function getArticles

 Title        : getArticles
 Usage        : my @a_input_articles =getArticles($rh_query);
 Prerequisite : 
 Function     : For a query from getInputs, retrieve list of articles 
 		represented by a ARRAYREF corresponding to REF(articleName, articlePerlStructure)
 Returns      : @a_input_articles: ARRAY of articles ARRAYREF
 Args         : $rh_query: query HASHREF structure from getInputs
 Globals      : none

=cut

sub getArticles
{
    my $rh_query         = shift();
    my @a_input_articles = ();

    foreach my $rh_input_article (@{$rh_query->{'query_articles'}})
    {
        my @a_input_article = ($rh_input_article->{'article_name'}, $rh_input_article);
        push(@a_input_articles, \@a_input_article);
    }
    return (@a_input_articles);
}

=head2 function getCollectedSimples

 Title        : getCollectedSimples
 Usage        : my @a_simple_articles =getCollectedSimples($rh_collection_article);
 Prerequisite : 
 Function     : For a collection query from getArticles, retrieve list of 
 		simple articles
 Returns      : @a_simple_articles: ARRAY of articles HASHREF
 Args         : $rh_collection_article: collection article HASHREF structure from getArticles
 Globals      : none

=cut

sub getCollectedSimples
{
    my $rh_collection_article = shift();
    return @{$rh_collection_article->{'article_objects'}};
}

=head2 function getCrossReferences

 Title        : getCrossReferences
 Usage        : my @a_crossreferences =getCrossReferences($rh_simple_article);
 Prerequisite : 
 Function     : Takes a simple article structure (from getArticles or getCollectedSimples)
 		and retrieve the list of crossreferences HASHREF
 Returns      : @a_crossreferences: ARRAY of crossreferences HASHREF
 Args         : $rh_simple_article: simple article HASHREF structure from getArticles or getCollectedSimples
 Globals      : none

=cut

sub getCrossReferences
{
    my $rh_simple_article = shift();

    if ($rh_simple_article->{'object_crossreference'} ne '')
    {
        return (@{$rh_simple_article->{'object_crossreference'}});
    }
    else
    {
        return ();
    }
}

=head2 function getObjectHasaElements

 Title        : getObjectHasaElements
 Usage        : my @a_hasa_elements =getObjectHasaElements($rh_simple_article);
 Prerequisite : 
 Function     : Takes a simple article structure (from getArticles or getCollectedSimples)
 		and retrieve the list of "HASA" element HASHREF
 Returns      : @a_hasa_elements: ARRAY of "HASA" element HASHREF
 Args         : $rh_object: simple article HASHREF structure from getArticles or getCollectedSimples
 Globals      : none

=cut

sub getObjectHasaElements
{
    my $rh_simple_article = shift();

    if (defined $rh_simple_article->{'article_objects'})
    {
        if ($rh_simple_article->{'article_objects'}->{'object_hasa'} ne '')
        {
            return (@{$rh_simple_article->{'article_objects'}->{'object_hasa'}});
        }
        else
        {
            return ();
        }
    }
    else
    {
        if ($rh_simple_article->{'object_hasa'} ne '')
        {
            return @{$rh_simple_article->{'object_hasa'}};
        }
        else
        {
            return ();
        }
    }

#    if ($rh_object->{'object_hasa'} ne '')
#    {
#       return (@{$rh_object->{'object_hasa'}});
#    }
#    else
#    {
#        return ();
#    }
}

=head2 function getObjectType

 Title        : getObjectType
 Usage        : my $object_type =getObjectType($rh_object);
 Prerequisite : 
 Function     : Returns object MOBY class/type
 Returns      : $object_type: object MOBY class/type
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectType
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_type'});
    }
    else
    {
        return $rh_object->{'object_type'};
    }
}

=head2 function getObjectName

 Title        : getObjectName
 Usage        : my $object_name =getObjectName($rh_object);
 Prerequisite : 
 Function     : Returns object moby:articleName
 Returns      : $object_name:  moby:articleName
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectName
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_name'});
    }
    else
    {
        return $rh_object->{'object_name'};
    }
}

=head2 function getObjectNamespace

 Title        : getObjectNamespace
 Usage        : my $object_namespace =getObjectNamespace($rh_object);
 Prerequisite : 
 Function     : Returns object moby:namespace
 Returns      : $object_name:  moby:namespace
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectNamespace
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_namespace'});
    }
    else
    {
        return $rh_object->{'object_namespace'};
    }
}

=head2 function getObjectContent

 Title        : getObjectContent
 Usage        : my $object_content =getObjectContent($rh_object);
 Prerequisite : 
 Function     : Returns object content (using HTML::Entities::decode)
 		Warning: this content could contain emptylines if
			your objects contains Crossreferences or Hasa Elements ...
 Returns      : $object_content:  object content (decoded using HTML::Entities::decode)
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectContent
{
    use HTML::Entities ();
    my $rh_object       = shift();
    my $encoded_content = '';
    if (defined $rh_object->{'article_objects'})
    {
        $encoded_content = $rh_object->{'article_objects'}->{'object_content'};
    }
    else
    {
        $encoded_content = $rh_object->{'object_content'};
    }
    my $decoded_object = HTML::Entities::decode($encoded_content);
    return ($decoded_object);
}

=head2 function getObjectXML

 Title        : getObjectXML
 Usage        : my $object_xml =getObjectXML($rh_object);
 Prerequisite : 
 Function     : Returns full object moby:xml string
 Returns      : $object_xml:  object moby:xml string
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectXML
{
    my $rh_object = shift();
    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_xml'});
    }
    else
    {
        return $rh_object->{'object_xml'};
    }

}

=head2 function getObjectId

 Title        : getObjectId
 Usage        : my $object_id =getObjectId($rh_object);
 Prerequisite : 
 Function     : Returns object moby:id
 Returns      : $object_id:  moby:id
 Args         : $rh_object: simple article (object) HASHREF structure from getArticles,getCollectedSimples or getObjectHasaElements
 Globals      : none

=cut

sub getObjectId
{
    my $rh_object = shift();

    if (defined $rh_object->{'article_objects'})
    {
        return ($rh_object->{'article_objects'}->{'object_id'});
    }
    else
    {
        return $rh_object->{'object_id'};
    }
}

=head2 function getParameter

 Title        : getParameter
 Usage        : my ($parameter_name,$parameter_value) =getParameter($rh_article);
 Prerequisite : 
 Function     : Returns parameter name an value for a Secondary aricle
 Returns      : $parameter_name
 		$parameter_value
 Args         : $rh_article: secondary article HASHREF structure from getArticles
 Globals      : none

=cut

sub getParameter
{
    my $rh_article = shift();
    if (_IsSecondary($rh_article->{'article_type'}))
    {
        return (@{$rh_article->{'article_objects'}});
    }

    return;
}

=head2 function getNodeContentWithArticle

 Title        : getNodeContentWithArticle
 Usage        : my $content = getNodeContentWithArticle($rh_query, $article_type, $article_name)
 Prerequisite : 
 Function     : inside a mobyData bloc (structured in $rh_query),
 		look for an article of a defined type (Simple, Collection or Parameter).
		Foreach matching article, search for an object named $article_name.
		If found, return its content.
 Returns      : $content: content of article requested
 Args         : $rh_query: query HASHREF structure from getInputs
 		$article_type: 'Simple/Collection/Parameter'
		$article_name: attribute moby:articleName 
 Globals      : 

=cut

sub getNodeContentWithArticle
{
    my ($rh_query, $article_type, $article_name) = (@_);

    foreach my $rh_article (@{$rh_query->{'query_articles'}})
    {
        if (   (_IsSecondary($article_type))
            && ($rh_article->{'article_type'} =~ /^$article_type$/i)
            && ($article_name eq $rh_article->{'article_name'}))
        {
            my ($article_name, $article_value) = @{$rh_article->{'article_objects'}};
            return $article_value;
        }
        elsif (_IsSimple($article_type))
        {
            if ($rh_article->{'article_type'} =~ /^$article_type$/i)
            {

                if ($rh_article->{'article_name'} eq $article_name)
                {
                    return $rh_article->{'article_objects'}->{'object_content'};
                }
                elsif ($rh_article->{'article_objects'}->{'object_hasa'} ne '')
                {
                    foreach my $rh_object (@{$rh_article->{'article_objects'}->{'object_hasa'}})
                    {
                        if ($rh_object->{'object_name'} eq $article_name)
                        {
                            return $rh_object->{'object_content'};
                        }
                    }
                }
            }
        }
        elsif (_IsCollection($article_type))
        {
            if ($rh_article->{'article_type'} =~ /^$article_type$/i)
            {
                if ($rh_article->{'article_name'} eq $article_name)
                {
                    my $content = '';
                    foreach my $rh_object (@{$rh_article->{'article_objects'}})
                    {
                        $content .= $rh_object->{'object_content'};
                    }
                    return $content;
                }
                else
                {
                    foreach my $rh_object (@{$rh_article->{'article_objects'}})
                    {
                        if ($rh_object->{'object_name'} eq $article_name)
                        {
                            return $rh_object->{'object_content'};
                        }
                    }
                }

            }
        }
    }

    return;
}

=head2 function isSimpleArticle

 Title        : isSimpleArticle
 Usage        : isSimpleArticle($rh_article)
 Prerequisite : 
 Function     : Test if an article is a moby:Simple
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isSimpleArticle
{
    my $rh_article = shift();
    my $response   = _IsSimple($rh_article->{article_type});
    return $response;
}

=head2 function isCollectionArticle

 Title        : isCollectionArticle
 Usage        : isCollectionArticle($rh_article)
 Prerequisite : 
 Function     : Test if an article is a moby:Collection
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isCollectionArticle
{
    my $rh_article = shift();
    my $response   = _IsCollection($rh_article->{article_type});
    return $response;
}

=head2 function isSecondaryArticle

 Title        : isSecondaryArticle
 Usage        : isSecondaryArticle($rh_article)
 Prerequisite : 
 Function     : Test if articleType is moby:Parameter (secondary article)
 Returns      : $response: BOOLEAN
 Args         : $rh_article: article HASHREF structure from getArticles
 Globals      : none

=cut

sub isSecondaryArticle
{
    my $rh_article = shift();
    my $response   = _IsSecondary($rh_article->{article_type});
    return $response;
}

=head2 function _AnalyseSimple

 Title        : _AnalyseSimple
 Usage        : _AnalyseSimple($simple_bloc)
 Prerequisite : 
 Function     : Analyse a "Simple Bloc" from XSL transformation parsing
 		Build a $rh_simple_article structure with fields:
			'object_name'		=> moby:articleName
			'object_type'		=> moby:Class
			'object_namespace'	=> moby:namespace
			'object_id'		=> moby:id
			'object_content'	=> text content of simple article
			'object_xml'		=> full xml content of article
			'object_hasa'		=> ARRAYREF of hasa elements 
						   (each one is structured in a same 
						   structured hash (recursivity)
			'object_crossreference' => ARRAYREF of crossreferences objects 
						   (each one is structured in a hash with fields
						   'type', 'id', 'namespace')
			
 Returns      : $rh_simple: article HASHREF
 Args         : $simple_bloc: from parsing of a "simple" XSLT transformation
 Globals      : none

=cut

sub _AnalyseSimple
{
    my $simple_bloc = shift();
    my @a_crossref  = ();
    my @a_hasa      = ();

    my ($object_type,$object_name,$object_id,$object_namespace) = ('','','','');
    my $object_type_tag = '#XSL_LIPM_MOBYPARSER_OBJECTTYPE#';
    
    if ($simple_bloc =~ /$object_type_tag(.+)$object_type_tag/)
    {
        $object_type = $1;
        $object_type =~ s/^moby://i;
    }

    my $object_namespace_tag = '#XSL_LIPM_MOBYPARSER_OBJECTNAMESPACE#';
    
    if ($simple_bloc =~ /$object_namespace_tag(.+)$object_namespace_tag/)
    {
        $object_namespace = $1;
    }
    
    my $object_id_tag = '#XSL_LIPM_MOBYPARSER_OBJECTID#';
    
    if ($simple_bloc =~ /$object_id_tag(.+)$object_id_tag/)
    {
        $object_id = $1;
    }
    
    my $object_name_tag = '#XSL_LIPM_MOBYPARSER_OBJECTNAME#';

    if ($simple_bloc =~ /$object_name_tag(.+)$object_name_tag/)
    {
        $object_name = $1
    }
    
    my $crossref_start_tag = '#XSL_LIPM_MOBYPARSER_CROSSREF_START#';
    my $crossref_end_tag   = '#XSL_LIPM_MOBYPARSER_CROSSREF_END#';
    my $crossref_sep_tag   = '#XSL_LIPM_MOBYPARSER_CROSSREF_SEP#';

    while ($simple_bloc =~ m/$crossref_start_tag(.*)$crossref_sep_tag(.*)$crossref_sep_tag(.*)$crossref_end_tag/g)
    {
        my %h_crossref = ('type' => $1, 'id' => $2, 'namespace' => $3);
        push(@a_crossref, \%h_crossref);
    }

    my $ra_crossref = \@a_crossref;
    if ($#a_crossref < 0)
    {
        $ra_crossref = '';
    }

    my $object_content_tag = '#XSL_LIPM_MOBYPARSER_OBJECTCONTENT#';
    my ($before, $object_content, $after) = ('','','');
    ($before, $object_content, $after) = split($object_content_tag, $simple_bloc);

    my $object_hasa_start_tag = '#XSL_LIPM_MOBYPARSER_OBJECTHASA_START#';

    if ($simple_bloc =~ /$object_hasa_start_tag/)
    {
        my (@a_hasa_blocs) = split($object_hasa_start_tag, $simple_bloc);

        foreach my $hasa_bloc (@a_hasa_blocs)
        {
            if ($hasa_bloc ne '')
            {
                my $rh_hasa = _AnalyseSimple($hasa_bloc);
                push(@a_hasa, $rh_hasa);
            }
        }
    }

    my $ra_hasa    = \@a_hasa;
    my $object_xml = '';

    if ($#a_hasa < 0)
    {
        $ra_hasa    = '';
        $object_xml =
          "<moby:$object_type moby:id='$object_id' moby:namespace='$object_namespace'>$object_content</moby:$object_type>";
    }
    else
    {
        $object_xml = "<moby:$object_type moby:id='$object_id' moby:namespace='$object_namespace'>\n";
        foreach my $rh_hasa (@a_hasa)
        {
            $object_xml .= $rh_hasa->{'object_content'} . "\n";
        }
        $object_xml .= "</moby:$object_type>";
    }

    my %h_simple = (
                    'object_name'           => $object_name,
                    'object_type'           => $object_type,
                    'object_namespace'      => $object_namespace,
                    'object_id'             => $object_id,
                    'object_content'        => $object_content,
                    'object_xml'            => $object_xml,
                    'object_crossreference' => $ra_crossref,
                    'object_hasa'           => $ra_hasa
                    );

    return \%h_simple;
}

=head2 simpleResponse (stolen from MOBY::CommonSubs)

 name     : simpleResponse
 function : wraps a simple article in the appropriate (mobyData) structure
 usage    : $resp .= &simpleResponse($object, 'MyArticleName', $queryID);
 args     : (in order)
            $object   - (optional) a MOBY Object as raw XML
            $article  - (optional) an articeName for this article
            $query    - (optional, but strongly recommended) the queryID value for the
                        mobyData block to which you are responding
 notes    : as required by the API you must return a response for every input.
            If one of the inputs was invalid, you return a valid (empty) MOBY
            response by calling &simpleResponse(undef, undef, $queryID) with no arguments.

=cut

sub simpleResponse
{
    my ($data, $articleName, $qID) = @_;    # articleName optional

    $data        ||= '';                    # initialize to avoid uninit value errors
    $qID         ||= "";
    $articleName ||= "";
    if ($articleName)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
    }
    elsif ($data)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Simple moby:articleName='$articleName'>$data</moby:Simple>
        </moby:mobyData>
        ";
    }
    else
    {
        return "
        <moby:mobyData moby:queryID='$qID'/>
	";
    }
}

=head2 collectionResponse (stolen from MOBY::CommonSubs)

 name     : collectionResponse
 function : wraps a set of articles in the appropriate mobyData structure
 usage    : return responseHeader . &collectionResponse(\@objects, 'MyArticleName', $queryID) . responseFooter;
 args     : (in order)
            \@objects - (optional) a listref of MOBY Objects as raw XML
            $article  - (optional) an articeName for this article
            $queryID  - (optional, but strongly recommended) the mobyData ID
                        to which you are responding
 notes    : as required by the API you must return a response for every input.
            If one of the inputs was invalid, you return a valid (empty) MOBY
            response by calling &collectionResponse(undef, undef, $queryID).

=cut

sub collectionResponse
{
    my ($data, $articleName, $qID) = @_;    # articleName optional
    my $content = "";
    $data ||= [];
    $qID  ||= '';
    unless ((ref($data) =~ /array/i) && $data->[0])
    {                                       # we're expecting an arrayref as input data,and it must not be empty
        return "<moby:mobyData moby:queryID='$qID'/>";
    }

    foreach (@{$data})
    {
        if ($_)
        {
            $content .= "
                <moby:Simple>$_</moby:Simple>
            ";
        }
        else
        {
            $content .= "
                <moby:Simple/>
            ";
        }
    }
    if ($articleName)
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>
                $content
            </moby:Collection>
        </moby:mobyData>
        ";
    }
    else
    {
        return "
        <moby:mobyData moby:queryID='$qID'>
            <moby:Collection moby:articleName='$articleName'>$content</moby:Collection>
        </moby:mobyData>
        ";
    }
}

=head2 responseHeader (stolen from MOBY::CommonSubs)

 name     : responseHeader
 function : print the XML string of a MOBY response header +/- serviceNotes
 usage    : responseHeader('illuminae.com')
            responseHeader(
                -authority => 'illuminae.com',
                -note => 'here is some data from the service provider')
 args     : a string representing the service providers authority URI,
            OR a set of named arguments with the authority and the
            service provision notes.
 caveat   : 
 notes    :  returns everything required up to the response articles themselves.
             i.e. something like:
 <?xml version='1.0' encoding='UTF-8'?>
    <moby:MOBY xmlns:moby='http://www.biomoby.org/moby'>
       <moby:Response moby:authority='http://www.illuminae.com'>
        

=cut

sub responseHeader
{
    use HTML::Entities ();
    my ($auth, $notes) = &_rearrange([qw[AUTHORITY NOTE]], @_);
    $auth  ||= "not_provided";
    $notes ||= "";
    my $xml =
        "<?xml version='1.0' encoding='UTF-8'?>"
      . "<moby:MOBY xmlns:moby='http://www.biomoby.org/moby' xmlns='http://www.biomoby.org/moby'>"
      . "<moby:mobyContent moby:authority='$auth'>";
    if ($notes)
    {
        my $encodednotes = HTML::Entities::encode($notes);
        $xml .= "<moby:serviceNotes>$encodednotes</moby:serviceNotes>";
    }
    return $xml;
}

=head2 responseFooter (stolen from MOBY::CommonSubs)

 name     : responseFooter
 function : print the XML string of a MOBY response footer
 usage    : return responseHeader('illuminae.com') . $DATA . responseFooter;
 notes    :  returns everything required after the response articles themselves
             i.e. something like:
  
  </moby:Response>
     </moby:MOBY>

=cut

sub responseFooter
{
    return "</moby:mobyContent></moby:MOBY>";
}

=head2 function _IsCollection

 Title        : _IsCollection
 Usage        : _IsCollection($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'collection'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsCollection
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^collection$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 function _IsSimple

 Title        : _IsSimple
 Usage        : _IsSimple($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'simple'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsSimple
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^simple$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 function _IsSecondary

 Title        : _IsSecondary
 Usage        : _IsSecondary($article_type)
 Prerequisite : 
 Function     : Compares a string to string 'parameter'
 		Remove namespace 'moby:' from parameter string 
		Case insensitive
 Returns      : BOOLEAN
 Args         : $articletype: a string
 Globals      : none

=cut

sub _IsSecondary
{
    my $articletype = shift();

    $articletype =~ s/^moby://;
    if ($articletype =~ /^parameter$/i)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

=head2 _rearrange (stolen from MOBY::CommonSubs)


=cut

sub _rearrange
{

    #    my $dummy = shift;
    my $order = shift;

    return @_ unless (substr($_[0] || '', 0, 1) eq '-');
    push @_, undef unless $#_ % 2;
    my %param;
    while (@_)
    {
        (my $key = shift) =~ tr/a-z\055/A-Z/d;    #deletes all dashes!
        $param{$key} = shift;
    }
    map {$_ = uc($_)} @$order;                    # for bug #1343, but is there perf hit here?
    return @param{@$order};
}

1;
