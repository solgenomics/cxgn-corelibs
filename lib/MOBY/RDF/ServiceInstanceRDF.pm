package MOBY::RDF::ServiceInstanceRDF;
use strict;
use MOBY::RDF::InOutArticlesRDF;
use RDF::Core::Statement;
use RDF::Core::Model::Serializer;

require Exporter;
use RDF::Core::Constants qw(:xml :rdf :rdfs);
use constant OBJ => 'http://biomoby.org/RESOURCES/MOBY-S/Objects#';
use constant SRV => 'http://biomoby.org/RESOURCES/MOBY-S/Services#';
use constant NS => 'http://biomoby.org/RESOURCES/MOBY-S/Namespaces#';
use constant MP => 'http://biomoby.org/RESOURCES/MOBY-S/Predicates#';
use constant SI => 'http://biomoby.org/RESOURCES/MOBY-S/ServiceInstances#';
use constant DC => 'http://purl.org/dc/elements/1.1/';

our @ISA = qw(Exporter);
our @EXPORT = qw(OBJ SRV NS MP SI DC xmlNamespaces serialize);
our @EXPORT_OK = qw(OBJ SRV NS MP SI DC xmlNamespaces serialize);


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


sub serialize {
    my ($self) = @_;
    my $xml = '';
    
    my $serializer = new RDF::Core::Model::Serializer(
        Model=>$self->model,
        Output=>\$xml,
        getNamespaces => \&xmlNamespaces,  # this only works with a patch!!!!!!!!!!!!!!!!
                                                   );
    $serializer->serialize;
    return $xml;
}

sub model {
    my ($self, @args) = @_;
    $args[0] && ($self->{model} = $args[0]);
    return $self->{model};
}


sub service_instance {
    my ($self, @args) = @_;
    $args[0] && ($self->{service_instance} = $args[0]);
    return $self->{service_instance};
}

sub new {
    my ($caller, %args) = @_;
    
    return 0 unless $args{'model'} && (ref($args{'model'}) =~ /rdf::core/i);
    return 0 unless $args{'service_instance'} && (ref($args{'service_instance'}) =~ /serviceinstance/i);
    
    my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;
    
    my $self = bless {}, $class;
    
    $self->model($args{'model'});
    $self->service_instance($args{'service_instance'});
    
    $self->build;    
    return $self;

    
}

sub build {
    my ($self) = @_;

    my $service = $self->service_instance;
    my $model = $self->model;
    
	my $Bag = new RDF::Core::Resource(RDF_NS,'Bag');

    my $auth = $service->authority;
    my $name = $service->name;
    my $desc = $service->description;
    my $authoritative = $service->authoritative?"authoritative":"non-authoritative";
    my $subject = _addClassResource($model, SI, "$auth,$name", $desc);
    _addClassLiteral($model, DC, $subject, 'title',  $name); # dublin core title
    _addClassLiteral($model, DC, $subject, 'creator',  $service->contactEmail); # dublin core creator
    _addClassLiteral($model, DC, $subject, 'publisher',  $auth); # dublin core publisher
    _addClassLiteral($model, DC, $subject, 'coverage',  $authoritative); # dublin core coverage
    _addClassLiteral($model, DC, $subject, 'category',  $service->category); # dublin core coverage
    _addClassLiteral($model, DC, $subject, 'identifier',  $service->URL); # dublin core identifier (this is a stretch!)
    _addResource($model, MP, 'performs_task', $subject, SRV, $service->type); # dublin core title

    my @inputs = @{$service->input};
    push @inputs, @{$service->secondary};
    
    my @outputs = @{$service->output};


    my $InputArticles = MOBY::RDF::InOutArticlesRDF->new(
                                                         model => $model,
                                                         type => 'consumes',
                                                         subject => $subject,
                                                         articles => \@inputs,
                                                        );

    my $OutputArticles = MOBY::RDF::InOutArticlesRDF->new(
                                                         model => $model,
                                                         type => 'produces',
                                                         subject => $subject,
                                                         articles => \@outputs,
                                                        );

}

# these should be stripped out into their own module...
sub _addResource {
    my ($model, $ns, $predicate, $subject, $ons, $object) = @_;

    $predicate = $subject->new($ns, $predicate);
    $object = new RDF::Core::Resource($ons, $object);
    my $statement = new RDF::Core::Statement($subject, $predicate, $object);
    $model->addStmt($statement);

}
    
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