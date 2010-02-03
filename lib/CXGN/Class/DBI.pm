package CXGN::Class::DBI;
use CXGN::Class::Exporter qw/import looks_like_dbh/;
use base qw/CXGN::Class::Exporter/;
use strict;
no strict 'refs';

=head1 NAME

 CXGN::Class::DBI

=head1 DESCRIPTION

 Exporter/Parent class for modules that are database-centric and want to receive
 the delicious methods herein.  There are standard functions for creating
 a global database connection and preparing statements

=head1 USAGE

 package Foo;
 use base qw/CXGN::Class::DBI/;
 our $EXCHANGE_DBH = 1;
 Foo->set_sql("all_people", "SELECT sp_person_id FROM sgn_people.sp_person");
 1;

 #Script:
 BEGIN{
 	our $DBH = CXGN::DB::Connection->new();
 }
 use Foo; #imports $DBH automagically, or can create its own
 my $handle = Foo->new();
 my $sth = $handle->get_sql("all_people"); 
 #Can also just do 'my $sth = Foo->get_sql("all_people")'
 $sth->execute();
 exit 0;


=head1 FAQ

 Q: I still want to build the SQL in the dynamic scope so that I can alter 
 	SORT BY ... (ASC/DESC) and things that placeholders can't do.

 A: There's a way you can do variable SQL using CXGN::Class::DBI, using argument-entries.

	The argument-entry form is pretty intuitive.  In your SQL definition, use the literal 
	strings '$_[0]', '$_[1]', '$_[2]', etc. to dynamically build the sql using arguments
	to get_sql().  The prepared statement will still be saved using a serialized list
	of the provided arguments, so you don't really lose the performance benefit of this
	module.

 	The following demonstrates the difference between traditional placeholders and argument-entries:

 	package Foo;
	use base qw/CXGN::Class::DBI/;
	Foo->set_sql(
		"sort_people", 
		"	SELECT sp_person_id 
			FROM sgn_people.sp_person 
			WHERE sp_person_id > ? 
			ORDER BY sp_person_id \$_[0]

		"); # $_[0] is backslashed to avoid interpolation.
	1;

	package main;
	use Foo;
	my $foo = new Foo;
	$foo->get_sql("sort_people", "ASC");
	$foo->execute(5);
	$foo->fetchrow_array; # returns (6)
	exit 0;


	You should definitely keep using real placeholders for tasks of which they are capable, since
	a unique set of arguments to arg-entries needs to create a unique prepared statement.

 
 Q: I would rather attach a database handle to an instance, different objects of the same type
    to connect to different databases within one process.  Can I use CXGN::Class::DBI for this?

 A: Yes! When get_sql() is called on an instance, this code will search for a database
    handle named $instance->{dbh}.  In this case, it will call prepare_cached() on that database
	handle instead of using the global handle.

    package Foo;
	use base qw/CXGN::Class::DBI/;
	Foo->set_sql("something", "select ... and so on");
	1;

	package main;
	use Foo;
	use CXGN::DB::Connection;
	my $foo = new Foo;
	$foo->{dbh} = CXGN::DB::Connection->new();
	my $sth = $foo->get_sql("something", 
		{
		#If no_cache is true, then a new prepared statement is made, instead of prepare_cached()
			no_cache => 0, 

		#If global is true, then the global DBH and package prepared statements are used.
		#Otherwise, it will use $instance->{dbh}->prepare_cached()  ( or prepare() )
			global => 0
		}
	 );
	my $sth2 = $foo->get_sql("something", {no_cache=>1});
	# $sth2 will not be the same handle as $sth because of no_cache.  Useful for "Caveat Emptor"

    my $sth3 = $foo->get_sql("something", {global => 1});
	# $sth3 would be same handle returned if $foo->{dbh} was never set
	

=cut

our $EXCHANGE_DBH = 1;
our $VERBOSE = 0;
our $DBH;

our $DB_PARAM;
our $DB_CLASS;

our %SQL_DEFINITIONS;
our %SQL_PREPARED_STATEMENTS;
our @REQUIRED_SEARCH_PATHS;
our $SEARCH_PATHS_ADDED = 0;

=head1 DBH

 A function that checks, returns, or sets the package database handle.

 Usage:
 package My::Package;
 
 #The following line sets a new package DBH
 __package__->DBH(CXGN::DB::InsertDBH->new($credentials)); # ->, not ::, very important!
 
 #The following line gets the DBH, and ping checks it first.  If it is stale, it will
 #make a new dbh automatically and delete all prepared statements:
 my $dbh = DBH(); 

 # Wait! If DBH() Creates a new handle automatically, how does it determine default 
 # connection parameters?
 
 package My::Package;
 $My::Package::DB_CLASS = 'CXGN::DB::InsertDBH';  #default connection class;
 $My::Package::DB_PARAM = { dbname=>"cxgn", {AutoCommit=>0}}; #default parameters

 If these package vars aren't set, then DBH() will use CXGN::DB::Connection without
 arguments by default.  
 
 DBH() does another cool thing, which is a deliberate feature, not a bug Lukas!
 The first time you use it as a setter, it will set DB_CLASS and DB_PARAM if they
 are undefined for the package, using parameters for the database handle that it 
 was given.  This would only work for CXGN::DB::Connection based dbh's, not
 DBI->connect().  


=cut

sub DBH {
	my $class = shift;
	my $dbh = shift;
	
	if(looks_like_dbh($dbh)){
		${$class."::DBH"} = $dbh;
		%{$class."::SQL_PREPARED_STATEMENTS"} = (); 
		if(!${$class."::DB_PARAM"}){
			foreach(qw/dbhost dbname dbpass dbargs dbuser dbschema/){
				${$class."::DB_PARAM"}->{$_} = $dbh->{"_$_"};
			}
		}
		${$class."::DB_CLASS"} = ref($dbh) unless ${$class."::DB_CLASS"};	
	}
	elsif($dbh){
		warn "Passed something into DBH() that doesn't look like a database handle\n";
	}

	my $DBH = ${$class."::DBH"};
	unless(looks_like_dbh($DBH)){
		$DBH = CXGN::Class::DBI::make_DBH($class);
	}
	unless($DBH->ping()){
		print STDERR "DBH ping failed, recreating DBH and clearing prepared statements in the class $class\n";
		$DBH = CXGN::Class::DBI::make_DBH($class);
	}
	${$class."::DBH"} = $DBH;
	return $DBH;
}

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $dbh = shift;
	unless (looks_like_dbh($dbh)){
		warn __PACKAGE__ . " standard constructor takes database handle as the first argument\n";
		return $self;
	}
	$self->{dbh} = $dbh;
	return $self;
}

sub make_DBH {
	my $class = shift;
	my $arg = shift;
	
	my $DB_PARAM = ${$class."::DB_PARAM"};
	my $DB_CLASS = ${$class."::DB_CLASS"};
	$DB_PARAM = {} unless ref($DB_PARAM) eq "HASH";
	$DB_CLASS ||= "CXGN::DB::Connection";

	$arg = {} unless ref($arg) eq "HASH";
	while(my($k,$v) = each %$arg){
		$DB_PARAM->{$k} = $v;
	}

	print STDERR "# $class is making a DBH\n" if $CXGN::Class::Exporter::VERBOSE;
	
	eval "require $DB_CLASS";
	my $prior = $DB_CLASS->verbose(); 
	$DB_CLASS->verbose($class->verbose());
	my $DBH = $DB_CLASS->new($DB_PARAM);
	$DB_CLASS->verbose($prior);
	
	%{$class."::SQL_PREPARED_STATEMENTS"} = ();

	${$class."::DBH"} = $DBH;
	return $DBH;
}

sub get_definition {
	my $class = shift;
	my ($name) = @_;
	return ${$class."::SQL_DEFINITIONS"}{$name};
}

sub get_sql {
	
	#Let's make sure we get the class, no matter how this is called:
	my $this = shift;
	my $class = $this;
	$class = ref($this) if ref($this);

	my $SQL_PREPARED_STATEMENTS = \%{$class."::SQL_PREPARED_STATEMENTS"};
	my %SQL_DEFINITIONS = %{$class."::SQL_DEFINITIONS"};
	my $SEARCH_PATHS_ADDED = ${$class."::SEARCH_PATHS_ADDED"};
	my @REQUIRED_SEARCH_PATHS = @{$class."::REQUIRED_SEARCH_PATHS"};

	my ($name, @arg) = @_;
	die "No SQL statement with the name '$name' found in $class\n" unless exists $SQL_DEFINITIONS{$name};

	#DBH() does a ping check.  If the DBH is no good, it will re-create one automatically and attach
	#it to the class in which this is used, and also clear any stale prepared statements on the class.
	
	$DBH = $class->DBH(); 

	my $serialized_arg = join (":",  grep {!ref} @arg );

	my $lookup = $name;
	$lookup .= ":$serialized_arg" if $serialized_arg; #allows many prepared statements for each defined SQL query based on argument states


	unless($SEARCH_PATHS_ADDED || !@REQUIRED_SEARCH_PATHS){
		if($DBH->can("add_search_paths")){
			$DBH->add_search_paths(@REQUIRED_SEARCH_PATHS);
		}
		else {
			CXGN::Class::DBI::_add_search_paths($class, @REQUIRED_SEARCH_PATHS);
		}
	}

	my $sql = $SQL_DEFINITIONS{$name};

	#This is where the argument-entry magic happens:
	
	my $opt = undef;
	for(my $i = 0; $i < @arg; $i++){
		my $arg = $arg[$i];
		if(ref($arg)){
			die "Only one option-reference can be passed\n" if ref($opt);
			$opt = $arg;
			next;
		}
		unless ($sql =~ /\$_\[$i\]/){
			die "No argument-entry \$_[$i] exists (too many arguments to get_sql(), perhaps?) for SQL: " . $SQL_DEFINITIONS{$name} . "\n";
		}
		$sql =~ s/\$_\[$i\]/$arg/;
		if($sql =~ /\$_\[$i\]/) {
			die "Multiple arg entries exist for \$_[$i] in SQL: " . $SQL_DEFINITIONS{$name} . "\n";
		}
	}
	if($sql =~ /\W\$_\[\d+\]\W/){
		die "An arg entry was not filled (not enough arguments to get_sql(), perhaps?) in the SQL:\n" . $SQL_DEFINITIONS{$name} . "\nFilled SQL:\n$sql";
	}

	#Used cached prepared statements for instances with a database handle
	if(!$opt->{global} && ref($this) && looks_like_dbh($this->{dbh})) {
		return $this->{dbh}->prepare_cached($sql) unless $opt->{no_cache};
		return $this->{dbh}->prepare($sql);
	}

	#Use global prepared statements for package get_sql() calls, or instance calls
	#wherin the instance does not have a database handle named {dbh}
	my $prepared = $SQL_PREPARED_STATEMENTS->{$lookup};
	
	return $prepared 
		if ( !$opt->{no_cache} 
				&& $prepared 
				&& ref($prepared) 
				&& $prepared->can('execute')
			);

	my $sth = $DBH->prepare($sql);

	$SQL_PREPARED_STATEMENTS->{$lookup} = $sth;
	return $sth;
}

sub set_sql {
	my $class = shift;
	$class = ref($class) if ref($class);	
	my ($name, $sql) = @_;

	no warnings 'once';
	${$class."::SQL_DEFINITIONS"}{$name} = $sql;
	*{$class.'::sql_'.$name} = sub {
		$class->get_sql($name, @_);	
	}
	
}	

sub required_search_paths {
	my $class = shift;
	my @sps = @_;
	@{$class."::REQUIRED_SEARCH_PATHS"} = @sps if @sps;
	return @{$class."::REQUIRED_SEARCH_PATHS"};	
}

sub _add_search_paths {
	my $class = shift;
	my $DBH = $class->DBH();		
	my $current = $DBH->prepare("SHOW search_path");
	$current->execute();
	my ($list) = $current->fetchrow_array;
	my @list = split(",", $list);
	$_ =~ s/\s//g foreach @list;
	push(@list, @_);
	my %search_paths = ();
	$search_paths{$_} = 1 foreach(@list);
	
	my @newlist = ();
	while(my ($sp, $val) = each %search_paths){
		$sp =~ s/\s//g;
		push(@newlist, $sp);
	}
	my $new_string = join ",", @newlist;

	my $query = "SET search_path=$new_string";
	$DBH->do($query);
}

sub verbose {
	our ($VERBOSE);
	my $class = shift;
	my ($arg) = @_;
	$VERBOSE = $arg if defined $arg;
	return $VERBOSE;
}

1;
