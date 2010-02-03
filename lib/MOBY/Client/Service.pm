#$Id: Service.pm,v 1.24 2006/01/31 22:19:02 fgibbons Exp $

=head1 NAME

MOBY::Client::Service - an object for communicating with MOBY Services

=head1 SYNOPSIS

 use MOBY::Client::Service;
 
 my $Service = MOBY::Client::Service->new(service => $WSDL);
 my $result = $Service->execute(@args);

=head1 DESCRIPTION

Deals with all SOAPy rubbish required to communicate with a MOBY Service.
The object is created using the WSDL file returned from a
MOBY::Client::Central->retrieveService() call.  The only useful method call
in this module is "execute", which executes the service.

=head1 AUTHORS

Mark Wilkinson (markw@illuminae.com)

BioMOBY Project:  http://www.biomoby.org

=head1 METHODS

=head2 new

 Usage     :	$Service = MOBY::Client::Service->new(@args)
 Function  :	create a service connection
 Returns   :	MOBY::Client::Service object, undef if no wsdl.
 Args      :	service : string ; required
                          a WSDL file defining a MOBY service
                uri     : string ; optional ; default NULL
                          if the URI of the soap call needs to be personalized
                          this should almost never happen...

=cut

package MOBY::Client::Service;
use SOAP::Lite;

#use SOAP::Lite + 'trace';
use strict;
use Carp;
use Cwd;
use URI::Escape;
use vars qw($AUTOLOAD @ISA);
my $debug = 0;
if ( $debug ) {
	open( OUT, ">/tmp/ServiceCallLogOut.txt" ) || die "cant open logfile\n";
	close OUT;
}

sub BEGIN {
}
{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #     				DEFAULT    	ACCESSIBILITY
	  (
		service      => [ undef, 'read/write' ],
		uri          => [ undef, 'read/write' ],
		serviceName  => [ undef, 'read/write' ],
		_soapService => [ undef, 'read/write' ],
		smessageVersion => ['0.87', 'read'	],
	  );

	#_____________________________________________________________
	# METHODS, to operate on encapsulated class data
	# Is a specified object attribute accessible in a given mode
	sub _accessible {
		my ( $self, $attr, $mode ) = @_;
		$_attr_data{$attr}[1] =~ /$mode/;
	}

	# Classwide default value for a specified object attribute
	sub _default_for {
		my ( $self, $attr ) = @_;
		$_attr_data{$attr}[0];
	}

	# List of names of all specified object attributes
	sub _standard_keys {
		keys %_attr_data;
	}
	my $queryID = 0;

	sub _nextQueryID {
		return ++$queryID;
	}
}

sub new {
	my ( $caller, %args ) = @_;
	my $caller_is_obj = ref( $caller );
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ( $caller_is_obj ) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for( $attrname );
		}
	}

	#my $dir = cwd;
	# seems to be a bug in SOAP::Lite that the WSDL document
	# fails a parse if it is passed as a scalar rather than a file
	# this section can be removed when this bug is fixed
	#open (OUT, ">$dir/Service.wsdl") || die "cant open dump of wsdl file";
	#print OUT $self->service;
	#close OUT;
	# ________________________________________
	my $wsdl = 
	  URI::Escape::uri_escape( $self->service );    # this seems to fix the bug
	return undef unless $wsdl;
	my $soap = SOAP::Lite->service( "data:,$wsdl" );
	if ( $self->uri ) { $soap->uri( $self->uri ) }
	$self->serviceName( &_getServiceName( $soap ) );
	$self->_soapService( $soap );
	return $self;
}

=head2 execute

 Usage     :	$result = $Service->execute(%args)
 Function  :	execute the MOBY service
 Returns   :	whatever the Service provides as output
 Args      :	XMLinputlist => \@data
 Comment   :    @data is a list of single invocation inputs; the XML goes between the
                <queryInput> tags of a servce invocation XML.
Each element of @data is itself a listref of [articleName, $XML].
                articleName may be undef if it isn't required.
                $XML is the actual XML of the Input object

=head3 Examples 

There are several ways in which you can execute a service. You may
wish to invoke the service on several objects, and get the response
back in a single message. You may wish to pass in a collection of
objects, which should be treated as a single entity. Or you may wish
to pass in parameters, along with data. In each case, you're passing in 

   XMLinputlist => [ ARGS ]

The structure of @ARGS helps MOBY to figure out what you want.

=over 4 

=item Iterate over multiple Simples

To have the service iterate over multiple equivalent objects, and
return all the results in a single message, use this syntax (ARGS =
([...], [...], ...):

  $Service->execute(XMLinputlist => [ 
                        ['object1', '<Object namespace="blah" id="123"/>'],
                        ['object2', '<Object namespace="blah" id="234"/>']
                            ]);

This would invoke the service twice (in a single message) the first
time with an object "123" and the second time with object "234". 

=item Process a Collection

To pass in a Collection, you need this syntax (ARGS = [ '', [..., ..., ...] ]):

  $Service->execute(XMLinputlist => [
                 ['', [
                     '<Object namespace="blah" id="123"/>',
                     '<Object namespace="blah" id="234"/>']
              ]);

This would invoke the service once with a collection of inputs that
are not required to be named ('').

=item Process multiple Simple inputs

To pass in multiple inputs, to be considered neither a Collection nor sequentially evaluated, use this syntax (ARGS = [..., ..., ...])

  $Service->execute(XMLinputlist => [
            [
             'input1', '<Object namespace="blah" id="123"/>',
             'input2', '<Object namespace="blah" id="234"/>',
            ]
		     ]);

This would cause a single invocation of a service requiring two input
parameters named "input1" and "input2"

=item Parameters

Finally, MOBY will recognize parameters by virtue of their having been
declared when the service was registered. You need to specify the name
correctly.

  $Service->execute(XMLinputlist => [
                 [
             'input1', '<Object namespace="blah" id="123"/>',
             'input2', '<Object namespace="blah" id="234"/>',
             'param1', '<Value>0.001</Value>',
             ]
              ]);

This would cause a single invocation of a service requiring two input
parameters named "input1" and "input2", and a parameter named 'param1'
with a value of 0.001

=back

=cut

sub execute {
  # The biggest unanswered question for this subroutine is how it should respond in the event 
  # that there is a problem with the service. 
  # It should probably die() rather than just return strings as error messages.
  my ( $self, %args ) = @_;
  die "ERROR:  expected listref for XMLinputlist"
    unless ( ref( $args{XMLinputlist} ) eq 'ARRAY' );
  my @inputs = @{ $args{XMLinputlist} };
  my $data;
  foreach ( @inputs ) {
    die "ERROR:  expected listref [articleName, XML] for data element"
      unless ( ref( $_ ) eq 'ARRAY' );
    my $qID = $self->_nextQueryID;
    $data .= "<moby:mobyData queryID='$qID'>";
    while ( my ( $articleName, $XML ) = splice( @{$_}, 0, 2 ) ) {
      $articleName ||= "";
      if (  ref( $XML ) ne 'ARRAY' ) {
	$XML         ||= "";
	if ( $XML =~ /\<(moby\:|)Value\>/ )
	  {
	    $data .=
	      "<moby:Parameter moby:articleName='$articleName'>$XML</moby:Parameter>";
	  } else {
	    $data .=
	      "<moby:Simple moby:articleName='$articleName'>\n$XML\n</moby:Simple>\n";
	  }
	
	# need to do this for collections also!!!!!!
      } elsif ( ref( $XML ) eq 'ARRAY' ) {
	my @objs = @{$XML};
	$data .= "<moby:Collection moby:articleName='$articleName'>\n";
	foreach ( @objs ) {
	  $data .= "<moby:Simple>$_</moby:Simple>\n";
	}
	$data .= "</moby:Collection>\n";
      }
    }
    $data .= "</moby:mobyData>\n";
  }
  ###################
  #  this was added on January 19th, 2005 and may not work!
  ###################
  ###################
  my $version = $self->smessageVersion();
  $data = "<?xml version='1.0' encoding='UTF-8'?>
	<moby:MOBY xmlns:moby='http://www.biomoby.org/moby-s' moby:smessageVersion='$version'>
	      <moby:mobyContent>
	          $data
	      </moby:mobyContent>
	</moby:MOBY>";
  $data =~ s"&"&amp;"g;  # encode content in case it has CDATA
  $data =~ s"\<"&lt;"g;
  $data =~ s"\]\]\>"\]\]&gt;"g;
  
  ####################
  ####################
  ### BEFORE IT WAS JUST THIS
  
  #$data = "<![CDATA[<?xml version='1.0' encoding='UTF-8'?>
  #<moby:MOBY xmlns:moby='http://www.biomoby.org/moby-s'>
  #      <moby:mobyContent>
  #          $data
  #      </moby:mobyContent>
  #</moby:MOBY>]]>";
  my $METHOD = $self->serviceName;
  &_LOG( %args, $METHOD );
  my $response;
  eval { ( $response ) = $self->_soapService->$METHOD( $data ) };
  if ($@) { die "Service execution failed: $@"}
  else {return $response;} # the service execution failed then pass back ""
}

=head2 serviceName

 Usage     :	$name = $Service->serviceName()
 Function  :    get the name of the service
 Returns   :	string
 Args      :	none

=cut

=head2 _getServiceName

 Usage     :	$name = $Service->_getServiceName()
 Function  :	Internal method to retrieve the name of the service from the SOAP object
 Returns   :	string
 Args      :	none

=cut

sub _getServiceName {
	my ( $service ) = @_;
	no strict;
	my ( $method ) = @{ join '::', ref $service, 'EXPORT_OK' };
	return $method;
}

sub AUTOLOAD {
	no strict "refs";
	my ( $self, $newval ) = @_;
	$AUTOLOAD =~ /.*::(\w+)/;
	my $attr = $1;
	if ( $self->_accessible( $attr, 'write' ) ) {
		*{$AUTOLOAD} = sub {
			if ( defined $_[1] ) { $_[0]->{$attr} = $_[1] }
			return $_[0]->{$attr};
		};    ### end of created subroutine
###  this is called first time only
		if ( defined $newval ) {
			$self->{$attr} = $newval;
		}
		return $self->{$attr};
	} elsif ( $self->_accessible( $attr, 'read' ) ) {
		*{$AUTOLOAD} = sub {
			return $_[0]->{$attr};
		};    ### end of created subroutine
		return $self->{$attr};
	}

	# Must have been a mistake then...
	croak "No such method: $AUTOLOAD";
}
sub DESTROY { }

sub SOAP::Transport::HTTP::Client::get_basic_credentials {
	my ( $username, $password );
	print "ENTER USERNAME: ";
	$username = <STDIN>;
	chomp $username;
	print "ENTER PASSWORD: ";
	$password = <STDIN>;
	chomp $password;
	return $username => $password;
}

sub _LOG {
	return unless $debug;
	open LOG, ">>/tmp/ServiceCallLogOut.txt" or die "can't open logfile $!\n";
	print LOG join "\n", @_;
	print LOG "\n---\n";
	close LOG;
}

#
#
# --------------------------------------------------------------------------------------------------------
#
##
##
1;
