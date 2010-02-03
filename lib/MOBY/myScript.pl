#!/usr/bin/perl -w -Wall
use strict;
use diagnostics;
use lib "C:/Perl/site/lib/MOBY";
use MOBY::Client::Central;
my $v = 1 if ($ARGV[0] && ($ARGV[0] eq "verbose"));

sub TEST {  # test of Registration object
    my ($reg, $test, $expect) = @_;
    die "\a\a\aREG OBJECT MALFORMED" unless $reg;
    if ($reg->success == $expect){
        print "test $test\t\t[PASS] ", ($v?($reg->message):""),"\n";
    } else {
        print "test $test\t\t[FAIL] ",$reg->message,"\n\n";
    }
}
sub TEST2 {  # test of ServiceInstance object listref
  my  ($SI, $REG, $test, $expect) = @_;
    die "\a\a\aServiceInstance Response MALFORMED" if ($SI && !(ref($SI) =~ /array/i));
    if (defined($REG) && $expect){
        print "test $test\t\t[FAIL]\n", $REG->message,"\n";
    } elsif (($SI->[0] && $expect) || (!$SI->[0] && !$expect)) {
        print "test $test\t\t[PASS]\n";
    } else {
		print "test $test\t\t[FAIL]\nExpected to find service; didn't find service\n";
	}

}
my $URL = $ENV{MOBY_SERVER}?$ENV{MOBY_SERVER}:'http://mobycentral.cbr.nrc.ca:8080/cgi-bin/MOBY05/testmobycentral.pl';
my $URI = $ENV{MOBY_URI}?$ENV{MOBY_URI}:'http://mobycentral.cbr.nrc.ca:8080/MOBY/Central';
my $PROXY = $ENV{MOBY_PROXY}?$ENV{MOBY_PROXY}:'No Proxy Server';

my $C = MOBY::Client::Central->new(
Registries => {
  mobycentral => {URL => $URL,
				  URI => $URI}
						}
);

print "TESTING MOBY CLIENT with\n\tURL:  $URL\n\tURI: $URI\n\tProxy: $PROXY\n\n";


#register with two ISA's -> should fail
TEST($C->registerObjectClass(objectType => "HypotheticalObject1",
                description => "a human-readable description of the object",
		contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['Object', 'article1'],
						['Object', 'articleName2']],
					HASA => [
						['Object', 'articleName3']]}
                       ), '1a', 0);

#register with no ISA's -> should fail
TEST($C->registerObjectClass(objectType => "HypotheticalObject1",
                description => "a human-readable description of the object",
		contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					HASA => [
						['Object', 'articleName3']]}
                       ), '1b', 0);

#reg first object class with a single ISA -> should pass
TEST($C->registerObjectClass(objectType => "HypotheticalObject1",
                description => "a human-readable description of the object",
		contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['Object', 'articleName2']],
					HASA => [
						['Object', 'articleName3']]}
                       ), 1, 1);

#reg duplicate object class
TEST($C->registerObjectClass(objectType => "HypotheticalObject1",
                description => "a human-readable description of the object",
				contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['Object', 'article1']
						],
					HASA => [
						['Object', 'articleName3']]}
                       ), 2, 0);

#reg second object class
TEST($C->registerObjectClass(objectType => "HypotheticalObject2",
                description => "a human-readable description of the object",
				contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['Object', 'articleName2']],
					HASA => [
						['Object', 'articleName3']]}
                       ), 3, 1);

TEST($C->registerServiceType(serviceType => "HypotheticalService1",
                description => "a human-readable description of the service",
				contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => ['Retrieval','Analysis']}
                       ), 4, 1);

TEST($C->registerServiceType(serviceType => "HypotheticalService1",
                description => "a human-readable description of the service",
				contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => ['Retrieval','Analysis']}
                       ), 5, 0);

TEST($C->deregisterObjectClass(objectType => "HypotheticalObject1"), 6, 1);
TEST($C->deregisterObjectClass(objectType => "HypotheticalObject1"), 7, 0);
TEST($C->deregisterObjectClass(objectType => "HypotheticalObject2"), 8, 1);
TEST($C->deregisterServiceType(serviceType => "HypotheticalService1"), 9, 1);
TEST($C->deregisterServiceType(serviceType => "HypotheticalService1"), 10, 0);
TEST($C->registerNamespace(
    namespaceType =>'HypotheticalNamespace1',
    authURI => 'your.authority.URI',
    description => "human readable description of namespace",
    contactEmail => 'your@address.here'), 11, 1);
TEST($C->registerNamespace(
    namespaceType =>'HypotheticalNamespace1',
    authURI => 'your.authority.URI',
    description => "human readable description of namespace",
    contactEmail => 'your@address.here'), 12, 0);
TEST($C->deregisterNamespace(namespaceType =>'HypotheticalNamespace1'), 13, 1);


#reg first object class 
TEST($C->registerObjectClass(objectType => "HypotheticalObject1",
                description => "a human-readable description of the object",
		contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['Object', 'article1']]}
                       ), 14, 1);

#reg duplicate object class
TEST($C->registerObjectClass(objectType => "HypotheticalObject2",
                description => "a human-readable description of the object",
				contactEmail => 'your@email.address',
                authURI => "blah.blah.blah",
			    Relationships => {
					ISA => [
						['HypotheticalObject1', 'article1']]}
                       ), 15, 1);

TEST($C->deregisterObjectClass(objectType => "HypotheticalObject1"), 16, 0);

TEST($C->registerNamespace(
    namespaceType =>'HypotheticalNamespace1',
    authURI => 'your.authority.URI',
    description => "human readable description of namespace",
    contactEmail => 'your@address.here'), 17, 1);

TEST($C->registerService(
    serviceName  => "myfirstservice",  
    serviceType  => "Retrieval",  
    authURI      => "www.illuminae.com",      
    contactEmail => 'your@mail.address',      
    description => "this is my first service", 
    category  =>  "moby",
    URL    =>  "http://illuminae/cgi-bin/service.pl",
	input =>[
        ['articleName1', [Object => ['HypotheticalNamespace1']]], # Simple
	        ],
	output =>[
        ['articleName2', [String => ['HypotheticalNamespace1']]], # Simple
	         ],
	secondary => {
        parametername1 => {
            datatype => 'Integer',
    		default => 0,
			max => 10,
			min => -10,
			enum => [-10, 10, 0]}}), 18, 1);

TEST($C->registerService(
    serviceName  => "myfirstservice",  
    serviceType  => "Retrieval",  
    authURI      => "www.illuminae.com",      
    contactEmail => 'your@mail.address',      
    description => "this is my first service", 
    category  =>  "moby",
    URL    =>  "http://illuminae/cgi-bin/service.pl",
	input =>[
        ['articleName1', [Object => ['HypotheticalNamespace1']]], # Simple
	        ],
	output =>[
        ['articleName2', [String => ['HypotheticalNamespace1']]], # Simple
	         ],
	), 19, 0);

TEST($C->registerService(
    serviceName  => "myfirstservice2",  
    serviceType  => "Retrieval",  
    authURI      => "www.illuminae.com",      
    contactEmail => 'your@mail.address',      
    description => "this is my first service", 
    category  =>  "moby",
    URL    =>  "http://illuminae/cgi-bin/service.pl",
	input =>[
#        ['articleName1', [[Object => ['HypotheticalNamespace1']]]], # Collection
	        ['articleName1', [Object => ['HypotheticalNamespace1']]], # Simple
	        ],
	output =>[
        ['articleName2', [String => ['HypotheticalNamespace1']]], # Simple
	         ],
	), 20, 1);


TEST2($C->findService(
     serviceName  => "myfirstservice2",
     serviceType  => "Retrieval",
     authURI      => "www.illuminae.com",
     authoritative => 0,
     category  =>  "moby",
	 expandObjects => 1,
     input =>[
              ["Object"], # Simple
              ]), 21, 1);

TEST2($C->findService(
     serviceName  => "myfirstservice2",
	), 22, 1);

TEST2($C->findService(
     input =>[
              ["BlahObject"], # Simple
              ]), 23, 0);

TEST2($C->findService(
     input =>[
              ["Object", ['HypotheticalNamespace1']], # Simple
              ]), 24, 1);

my ($si, $reg) = $C->findService(
     serviceName => "myfirstservice2"
);

$si = $si->[0];
my $wsdl = $C->retrieveService($si);
print $wsdl;
if ($wsdl && ($wsdl =~ /\<definitions/)){
        print "test 25\t\t[PASS]\n";
} else {
        print "test 25\t\t[FAIL]\tWSDL was not retrieved\n\n";
}



TEST($C->deregisterService(
    serviceName  => "myfirstservice2",  
    authURI      => "www.illuminae.com",      
    ), 26, 1);
TEST($C->deregisterService(
    serviceName  => "myfirstservice2",  
    authURI      => "www.illuminae.com",      
    ), 27, 0);
TEST($C->deregisterService(
    serviceName  => "myfirstservice",  
    authURI      => "www.illuminae.com",      
    ), 28, 1);
#TEST($C->deregisterService(
#    serviceName  => "getDragonSimpleAnnotatedImages",  
#    authURI      => "www.illuminae.com",      
#    ), 29, 0);  # cant deregister a service with a signatureURL

TEST($C->deregisterObjectClass(objectType => "HypotheticalObject2"), 30, 1);
TEST($C->deregisterObjectClass(objectType => "HypotheticalObject1"), 31, 1);
TEST($C->deregisterNamespace(namespaceType =>'HypotheticalNamespace1'), 32, 1);

exit 0;

