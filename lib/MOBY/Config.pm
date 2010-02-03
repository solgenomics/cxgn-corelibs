package MOBY::Config;

BEGIN {}
use strict;
use Carp;
use MOBY::dbConfig;
use vars qw($AUTOLOAD);
use Text::Shellwords;
use vars '$VERSION', '@ISA', '@EXPORT', '$CONFIG';
@ISA    = qw(Exporter);
@EXPORT = ('$CONFIG');
{

	#Encapsulated class data
	#___________________________________________________________
	#ATTRIBUTES
	my %_attr_data =    #         DEFAULT    	ACCESSIBILITY
	  (
		mobycentral      => [ undef, 'read/write' ],
		mobyobject       => [ undef, 'read/write' ],
		mobynamespace    => [ undef, 'read/write' ],
		mobyservice      => [ undef, 'read/write' ],
		mobyrelationship => [ undef, 'read/write' ],
		valid_secondary_datatypes => [["String", "Integer", "DateTime", "Float"],  'read'],
		primitive_datatypes => [["String", "Integer", "DateTime", "Float", "Boolean"], 'read'],

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
}

# the expected sections (listed above) will have their dbConfig objects available
# as methods.  The unexpected sections will have their dbConfig objects available
# by $dbConfig = $CONFIG->{section_title}
sub new {
	my ( $caller, %args ) = @_;

	#print STDERR "creating MOBY::Config\n";
	my $caller_is_obj = ref($caller);
	my $class         = $caller_is_obj || $caller;
	my $self          = bless {}, $class;
	foreach my $attrname ( $self->_standard_keys ) {
		if ( exists $args{$attrname} && defined $args{$attrname} ) {
			$self->{$attrname} = $args{$attrname};
		} elsif ($caller_is_obj) {
			$self->{$attrname} = $caller->{$attrname};
		} else {
			$self->{$attrname} = $self->_default_for($attrname);
		}
	}
	my $file = $ENV{MOBY_CENTRAL_CONFIG};
	( -e $file ) || die "MOBY Configuration file $file doesn't exist $!\n";
	chomp $file;
	if ( ( -e $file ) && ( !( -d $file ) ) ) {
	    open IN, $file
		or die
		"can't open MOBY Configuration file $file for unknown reasons: $!\n";
	}
	my @sections = split /(\[\s*\S+\s*\][^\[]*)/s, join "", <IN>;

	#print STDERR "split into @sections\n";
	foreach my $section (@sections) {

		#print STDERR "calling MOBY::dbConfig\n";
		my $dbConfig =
		  MOBY::dbConfig->new( section => $section )
		  ; # this is an object full of strings, no actual connections.  It represents the information in the config file
		next unless $dbConfig;
		my $dbname = $dbConfig->section_title;
		next unless $dbname;

#print STDERR "setting the COnfig dbConfig for the title $dbname with object $dbConfig\n\n";
		$self->{$dbname} = $dbConfig;
	}
	$CONFIG = $self;
	return $self;
}

sub getDataAdaptor {
	my ( $self, %args ) = @_;
	my $source = $args{datasource} || $args{source} || "mobycentral";
	if ( $self->{"${source}Adaptor"} ) { return $self->{"${source}Adaptor"} }
	;    # read from cache
	my $username = $self->$source->{username};# $self->$source returns a MOBY::dbConfig object
	my $password = $self->$source->{password};
	my $port     = $self->$source->{port};
	my $dbname   = $self->$source->{dbname};
	my $url      = $self->$source->{url};
	my $adaptor  = $self->$source->{adaptor};
	eval "require $adaptor";
	return undef if $@;
	my $ADAPTOR = $adaptor->new(    # by default, this is queryapi::mysql
					 username => $username,
					 password => $password,
					 port     => $port,
					 dbname   => $dbname,
					 url      => $url,
	);
	if ($ADAPTOR) {
		$self->{"${source}Adaptor"} = $ADAPTOR;    # cache it
		return $ADAPTOR;
	} else {
		return undef;
	}
}
sub DESTROY { }

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
1;
