package CXGN::Tools::Parse::SignalP;
use strict;

=head1 CXGN::Tools::Parse::SignalP

 Parses output from SignalP V 3.0 in short format

=head1 Author

 C. Carpita <csc32@cornell.edu>

=head1 Methods

=cut

=head2 new()

 Args: (opt) raw output data
 Ret: Parser object
 Side: Calls parse() automatically if argument provided

=cut

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $data = shift;
	if($data){
		$self->{data} = $data;
		$self->parse();
	}
	return $self;
}

sub parse_file {
	my $self = shift;
	my $filename = shift;
	die "No file: $filename" unless (-f $filename);
	open(FH, $filename);
	$self->{data} .= $_ while <FH>;
	close FH;
	$self->parse();
}

sub parse {
	my $self = shift;
	my $data = $self->{data};
	$self->{entries} = [];
	$self->{entry_by_id} = {};
	while(<$data>){
		next if /^\s*#/;
		my %h = ();
		($h{id}, $h{nn_cmax}, $h{nn_cpos}, $h{nn_cdec}, 
		 $h{nn_ymax}, $h{nn_ypos}, $h{nn_ydec},
		 $h{nn_smax}, $h{nn_spos}, $h{nn_sdec},
		 $h{nn_smean}, $h{nn_smeandec}, $h{nn_score}, $h{nn_decision},
		 $h{hmm_decision}, $h{hmm_cmax}, $h{hmm_cpos}, $h{hmm_cdec},
		 $h{hmm_sprob}, $h{hmm_sdec}
		 )
		 =
		 /^(\S+)\s+(\S+)\s+(\d+)\s+([NY])\s+(\S+)\s+(\d+)\s+([NY])\s+(\S+)\s+(\d+)\s+([NY])\s+(\S+)\s+([NY])\s+(\S+)\s+([NY])\s+\S+\s+([A-Z]+)\s+(\S+)\s+(\d+)\s+([NY])\s+(\S+)\s+([NY])/;
		push(@{$self->{entries}}, \%h);
		$self->{entry_by_id}->{$h{id}} = \%h;
	}
}	

sub getEntryById {
	my $self = shift;
	my $id = shift;
	return $self->{entry_by_id}->{$id};
}

sub getEntryArray {
	my $self = shift;
	return @{$self->{entries}};
}

1;
