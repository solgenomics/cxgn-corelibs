=head1 NAME

CXGN::Secretary::Family;

=head1 SYNOPSIS

A module for handling and filtering an Arabidopsis T. family

=head1 USAGE

 my $family = CXGN::Secretary::Family->new($dbh);
	OR
 CXGN::Secretary::Family->setDBH($dbh);
 my $family1 = CXGN::Secretary::Family->new();
 my $family2 = CXGN::Secretary::Family->new();

 $family->addAgis(@Agis); #ara gene identifiers
 $family->fetch();
 
 my $gene_object = $family->{$agi}; #can use after fetch
 print $family->FASTA("protein"); #or "cds", "cdna", "genomic"
 print $family->signalPositiveRatio;
 ## you can add other aggregate stat functions as you please...

=head1 AUTHOR

Christopher Carpita <csc32@cornell.edu>

=cut

package CXGN::Secretary::Family;

use strict;
use CXGN::DB::Connection;
use CXGN::Secretary::Gene; 

our $DBH;

sub import {
	my $class = shift;
	if(@_){
		$class->setDBH(@_);
	}
}

sub new {
	my $class = shift;
	my $dbh = shift;
	my $self = bless {}, $class;
	my @agis = @_;
	$self->{agis} = \@agis;
	if($dbh){	
		$self->{dbh} = $dbh;
		$self->setDBH($dbh);
	}
	return $self;
}

sub setDBH {
	my $class = shift;
	$DBH = shift;
	CXGN::Secretary::Gene->setDBH($DBH);
}

sub addAgis {
	my $self = shift;
	push(@{$self->{agis}}, @_);
}

sub fetch {
	my $self = shift;
	foreach(@{$self->{agis}}){
		my $gene = CXGN::Secretary::Gene->new($_, "");
		$gene->fetch_all();
		$self->{$_} = $gene;
	}
}

sub familySize {
	my $self = shift;
	return scalar(@{$self->{agis}});
}

sub signalPositiveRatio {
	my $self = shift;
	my $poscount = 0;
	foreach(@{$self->{agis}}){
		$poscount++ if $self->{$_}->isSignalPositive;			
	}
	return ($poscount / ($self->familySize));
}

sub signalPositiveNumber {
	my $self = shift;
	my $count = 0;
	foreach my $gene (@{$self->{agis}}) {
		$count++ if $self->{$gene}->isSignalPositive;
	}
	return $count;
}

sub FASTA {
	my ($self, $type) = @_;
	my $text = "";
	foreach(@{$self->{agis}}){
		my $gene = $self->{$_};
		$text .= ">$_\n" . $gene->{$type} . "\n";
	}	
	return $text;	
}

###
1;###
###
