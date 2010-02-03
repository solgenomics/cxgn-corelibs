package CXGN::Class::MethodMaker;
use strict;
no strict 'refs';

=head1 NAME

 CXGN::Class::MethodMaker

=head1 DESCRIPTION 

 A simplified (thinner) version of Class::MethodMaker, with less features.
 The upshot is that we can write in our own functions for method-making 
 that only make sense for CXGN stuff, like reading VHost Configs, interacting 
 with the CXGN database, writing log files, and so forth

=head1 SUPPORTED FEATURES

 Only supports "scalar" lists and single-value "new".
 For scalars, supports the following options: -type, -forward, -default
 See the file ./t/methodmaker.t which tests all possible options

=cut

sub import {
	my $class = shift;
	my @arg = @_;
	@arg = @{$arg[0]} if @arg==1 and ref($arg[0]) eq "ARRAY";
	my %kvs = @arg;

	my $pkg = caller;
	
	my @scalars = ();

	#As you can see, only 'scalar' is supported, for now,
	#and there only some options: type, default, and forward
	
	while(my($k,$v) = each %kvs){
		if($k =~ /^scalar$/i){
			if(ref($v)){
				next unless ref($v) eq "ARRAY";
				push(@scalars, @$v);
			}
			else {
				push(@scalars, $v);
			}
		}
	}

	for(my $i = 0; $i < @scalars; $i++){
		my $scalar = $scalars[$i];
		my $options = {};
		if (ref $scalar eq "HASH"){
			$options = $scalar;
			$i++;
			$scalar = $scalars[$i];
		}
		elsif($scalar =~ /^-/){
			$options = {"$scalar" => 1};
			$i++;
			$scalar = $scalars[$i];
		}
		$class->add_scalar_method($pkg, $scalar, $options);
	}

}

sub add_scalar_method {
	my $class = shift;
	my ($package, $name, $options) = @_;
	my $required_isa = $options->{'-type'};
	my @forward = ();
	my $default = $options->{'-default'};
	my $is_static = $options->{'-static'};

	if(my $fwd = $options->{'-forward'}){
		if(ref($fwd) eq "ARRAY"){
			push(@forward, @$fwd);
		}
		elsif(!ref($fwd)) {
			push(@forward, $fwd);
		}
	}
	
	foreach my $func (@forward){
		*{$package."::".$func} = sub {
			my $self = shift;
			my $obj = $self->$name();
			$obj->$func(@_);
		}
	}

	*{$package . "::" . $name} = sub { 
		my $self = shift;
		my $class = $self;
		$class = ref($self) if ref($self);
		my $arg = shift;
		if(defined($arg)){
			if($required_isa){
				unless(UNIVERSAL::isa($arg, $required_isa)){
					my $type = ref($arg);
					die "Supplied argument (type:$type) to $name() must be a subclass of of $required_isa\n";
				}	
			}
			if($is_static){
				${$class."::$name"} = $arg;
				${$class."::$name"."_CXGN_MM_SET"} = 1;
			}
			else {
				$self->{$name} = $arg;
				$self->{$name . '_CXGN_MM_SET'} = 1;
			}
		}
		if(!exists($self->{$name . "_CXGN_MM_SET"})){
			if($is_static && !${$class."::$name"."_CXGN_MM_SET"}){
				${$class."::$name"} = $default;		
			}
			else {
				$self->{$name} = $default;
			}
		}
		if($is_static){
			return ${$class."::$name"};
		}
		else {
			return $self->{$name};
		}
	};

	*{$package . "::" . $name . "_isset"} = sub {
		my $self = shift;
		my $thing = undef;
		my $class = $self;
		$class = ref($self) if ref($self);
		($is_static)?
			($thing = ${$class."::$name"."_CXGN_MM_SET"})
			:($thing = $self->{$name.'_CXGN_MM_SET'});
		(defined($thing))?(return 1):(return 0);
	};
	
	*{$package . "::" . $name . "_reset"} = sub {
		my $self = shift;
		my $class = $self;
		$class = ref($self) if ref($self);
		if($is_static){
			${$class."::$name"} = undef;
			${$class."::$name"."_CXGN_MM_SET"} = 0;	
		}
		else {
			delete($self->{$name});
			delete($self->{$name.'_CXGN_MM_SET'});
		}
	};
}



1;
