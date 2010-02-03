package MOBY::RDF::InOutArticlesRDF;
use strict;
use RDF::Core::NodeFactory;
use RDF::Core::Statement;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();

use RDF::Core::Constants qw(:xml :rdf :rdfs);
use constant OBJ => 'http://biomoby.org/RESOURCES/MOBY-S/Objects#';
use constant SRV => 'http://biomoby.org/RESOURCES/MOBY-S/Services#';
use constant NS => 'http://biomoby.org/RESOURCES/MOBY-S/Namespaces#';
use constant MP => 'http://biomoby.org/RESOURCES/MOBY-S/Predicates#';
use constant SI => 'http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances#';
use constant DC => 'http://purl.org/dc/elements/1.1/';

{   # these need to be class variables, since this module is loaded multiple times, but the newResouce counter has to increment nevertheless.
    
    my $inputfactory ||= new RDF::Core::NodeFactory( GenPrefix => '_:input', GenCounter => 0,BaseURI=>'http://www.biomoby.org/nil');# BaseURI=>'http://www.foo.org/');
    my $outputfactory ||= new RDF::Core::NodeFactory( GenPrefix => '_:output', GenCounter => 0,BaseURI=>'http://www.biomoby.org/nil');# BaseURI=>'http://www.foo.org/');
    my $simplefactory ||= new RDF::Core::NodeFactory( GenPrefix => '_:simple', GenCounter => 0,BaseURI=>'http://www.biomoby.org/nil');# BaseURI=>'http://www.foo.org/');
    my $collectionfactory ||= new RDF::Core::NodeFactory( GenPrefix => '_:collection', GenCounter => 0,BaseURI=>'http://www.biomoby.org/nil');# BaseURI=>'http://www.foo.org/');
    my $secondaryfactory ||= new RDF::Core::NodeFactory( GenPrefix => '_:secondary', GenCounter => 0,BaseURI=>'http://www.biomoby.org/nil');# BaseURI=>'http://www.foo.org/');

    sub nextinput {
        return $inputfactory->newResource
    }
    sub nextoutput {
        return $outputfactory->newResource
    }
    sub nextsimple {
        return $simplefactory->newResource
    }
    sub nextcollection {
        return $collectionfactory->newResource
    }
    sub nextsecondary {
        return $secondaryfactory->newResource
    }
    
}



sub type {
    my ($self, @args) = @_;
    $args[0] && ($self->{type} = $args[0]);
    return $self->{type};
}


sub model {
    my ($self, @args) = @_;
    $args[0] && ($self->{model} = $args[0]);
    return $self->{model};
}


sub subject {
    my ($self, @args) = @_;
    $args[0] && ($self->{subject} = $args[0]);
    return $self->{subject};
}


sub articles {
    my ($self, @args) = @_;
    $args[0] && ($self->{articles} = \@args);
    return @{$self->{articles}};
}

sub new {
    my ($caller, %args) = @_;
    return 0 unless $args{'model'} && (ref($args{'model'}) =~ /rdf::core/i);
    return 0 unless $args{'type'} && ( ($args{'type'} =~ /consumes/i) || ($args{'type'} =~ /produces/i) );
    return 0 unless $args{'subject'} && (ref($args{'subject'}) =~ /rdf::core/i);
    return 0 unless $args{'articles'} && (ref($args{'articles'}) =~ /array/i);
    return 1 unless ${$args{'articles'}}[0];  # if there ARE no articles, this is a valid result!
    
    my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;
    
    my $self = bless {}, $class;
    
    $self->type($args{'type'});
    $self->subject($args{'subject'});
    $self->model($args{'model'});
    $self->articles(@{$args{'articles'}});
    my $subject = $self->subject;
    my $model = $self->model;
    

	$self->{Bag} = new RDF::Core::Resource(RDF_NS,'Bag');
    my $Thingy;
    if ($self->type eq 'consumes'){
        $Thingy = &nextinput;  # create a bnode
    } else {
        $Thingy = &nextoutput;  # create a bnode
    }
    my $predicate = $subject->new(MP,$self->type);  # 'consumes' or 'produces'
    my $statement = new RDF::Core::Statement($subject, $predicate, $Thingy);
    $model->addStmt($statement);
    #<service  consumes  bnode1>

    my $type = $Thingy->new(RDF_NS,'type');
    $statement = new RDF::Core::Statement($Thingy, $type, $self->{Bag});
    $model->addStmt($statement);
    # <type  rdf:Bag>

    $self->build($Thingy);    
    return $self;

    
}

sub build {
    my ($self, $Thingy) = @_;
    my $model = $self->model;
    my @articles = $self->articles;
    my $Bag = $self->{Bag};

#    my $li = 0;
    foreach my $IN(@articles){
        my $input = &nextsimple;
		if ($IN->isSimple){
			my $LI = $Thingy->new(MP, "SimpleArticle");  # <rdf:li> nodes - need to be numbered :_1, :_2, etc
			my $statement = new RDF::Core::Statement($Thingy, $LI, $input);			
	        $model->addStmt($statement);
		} elsif ($IN->isCollection){
			my $LI = $Thingy->new(MP, "CollectionArticle");  # <rdf:li> nodes - need to be numbered :_1, :_2, etc
			my $statement = new RDF::Core::Statement($Thingy, $LI, $input);
	        $model->addStmt($statement);
		} elsif ($IN->isSecondary){
			my $LI = $Thingy->new(MP, "SecondaryArticle");  # <rdf:li> nodes - need to be numbered :_1, :_2, etc
			my $statement = new RDF::Core::Statement($Thingy, $LI, $input);			
	        $model->addStmt($statement);
		} else {
            print STDERR "the InOutArticlesRDF got a service instance input or output that was not a simple, collection, nor secondary???\n";
			return;
		}
#        ++$li;
        #my $LI = $Thingy->new(RDF_NS, "_$li");  # <rdf:li> nodes - need to be numbered :_1, :_2, etc
        #my $statement = new RDF::Core::Statement($Thingy, $LI, $input);
        #$model->addStmt($statement);
            #<Description about bnode1>
            # 	<rdf:_1 bnode2>

        if ($IN->isSimple){
            &_addSimple($model, $input, $IN);
        } elsif ($IN->isCollection) {   # COLLECTION - is just a bag of simples
            my $type = $input->new(RDF_NS,'type');
            my $statement = new RDF::Core::Statement($input, $type, $Bag);
            $model->addStmt($statement);
            # <type  rdf:Bag>
            _addClassLiteral($model, MP, $input, 'articleName',  $IN->articleName) if $IN->articleName; # the bag has an articlename
    
            my $simps = $IN->Simples;
            my $lli=0;
            foreach my $simp(@{$simps}){
                ++$lli;
                my $LI = $input->new(RDF_NS, "_$lli");  # <rdf:li> nodes - need to be numbered :_1, :_2, etc; these connect to the individual simples
                my $collection_member = &nextcollection;
                my $statement = new RDF::Core::Statement($input, $LI, $collection_member);
                $model->addStmt($statement);
                

                &_addSimple($model, $collection_member, $simp);
            }
        } elsif ($IN->isSecondary) {
            &_addSecondary($model, $input, $IN);
        }
    }
}

sub _addSimple {
    my ($model, $article, $ART) = @_;  #  (RDF::COre::Model,  $RDF::Core::Resource,  $MOBY::Client::SimpleArticle)
    _addClassLiteral($model, MP, $article, 'article_name',  $ART->articleName) if $ART->articleName;
    my $objecttype = $ART->objectType;
    $objecttype = ($objecttype =~ /urn:lsid.*:(\S+)$/)?$1:$objecttype;
    
    _addResource($model, MP, 'object_type', $article, OBJ, $objecttype);
    
    my $namespaces = $ART->namespaces();
    foreach (@{$namespaces}){
        my $namespace = _addClassResource($model, NS, "$_", '');        
        my $inNamespace = $article->new(MP, 'namespace_type');
        my $statement = new RDF::Core::Statement($article, $inNamespace, $namespace);
        $model->addStmt($statement);
    }
}


#| secondary_input_id  | int(10) unsigned                            |      | PRI | NULL    | auto_increment |
#| default_value       | text                                        | YES  |     | NULL    |                |
#| maximum_value       | decimal(10,0)                               | YES  |     | NULL    |                |
#| minimum_value       | decimal(10,0)                               | YES  |     | NULL    |                |
#| enum_value          | text                                        | YES  |     | NULL    |                |
#| datatype            | enum('String','Integer','DateTime','Float') | YES  |     | NULL    |                |
#| article_name        | varchar(255)                                | YES  |     | NULL    |                |
#| service_instance_id | int(10) unsigned                            |      |     | 0       |                |
sub _addSecondary {
    my ($model, $article, $ART) = @_;  #  (RDF::COre::Model,  $RDF::Core::Resource,  $MOBY::Client::SimpleArticle)
    _addClassLiteral($model, MP, $article, 'article_name',  $ART->articleName) if $ART->articleName;
    _addClassLiteral($model, MP, $article, 'default_value',  $ART->default) if $ART->default;
    _addClassLiteral($model, MP, $article, 'datatype',  $ART->datatype) if $ART->datatype;
    _addClassLiteral($model, MP, $article, 'max',  $ART->max) if $ART->max;
    _addClassLiteral($model, MP, $article, 'min',  $ART->min) if $ART->min;
    my @enums = @{$ART->enum};
    foreach my $enum(@enums){
        _addClassLiteral($model, MP, $article, 'enum',  $enum) if defined $enum;
    }
        
}

sub _addResource {
    my ($model, $ns, $predicate, $subject, $ons, $object) = @_;

    $predicate = $subject->new($ns, $predicate);
    $object = new RDF::Core::Resource($ons, $object);
    my $statement = new RDF::Core::Statement($subject, $predicate, $object);
    $model->addStmt($statement);

}
    
    
# these should also be stripped out into their own module
sub _addClassResource {
   my ($model, $ns, $thing, $def) = @_;
    my ($subject, $statement, $class, $label, $type);
    
    $label = ($thing =~ /urn:lsid.*:(\S+)$/)?$1:$thing;

    unless (ref($thing) =~ /RDF/){
        $subject = new RDF::Core::Resource($ns, $thing);
    }
    
    $type = $subject->new(RDF_NS,'type');
    $class = new RDF::Core::Resource(RDFS_NS,'Class');
    $statement = new RDF::Core::Statement($subject, $type, $class);
    $model->addStmt($statement);

    $type = $subject->new(RDFS_NS,'label');
    $label = new RDF::Core::Literal($label,"en", "http://www.w3.org/2001/XMLSchema#string");
    $statement = new RDF::Core::Statement($subject, $type, $label);
    $model->addStmt($statement);

    return $subject unless $def;

    $type = $subject->new(RDFS_NS,'comment');
    $label = new RDF::Core::Literal($def, "en", "http://www.w3.org/2001/XMLSchema#string");
    $statement = new RDF::Core::Statement($subject, $type, $label);
    $model->addStmt($statement);
    
    return $subject;
}

sub _addClassLiteral {
    my ($model, $pns, $subject, $predicate,  $value) = @_;
    
    $predicate = $subject->new($pns, $predicate);
    $value = new RDF::Core::Literal($value, "en", "http://www.w3.org/2001/XMLSchema#string");
    my $statement = new RDF::Core::Statement($subject, $predicate, $value);
    $model->addStmt($statement);

}

1;