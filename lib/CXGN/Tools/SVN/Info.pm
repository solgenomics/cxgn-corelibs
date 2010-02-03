#!/usr/bin/perl

=head1 CXGN::Tools::SVN::Info

 Grab svn status info on a particular file,
 defaults to current script file

=head1 USAGE

 my $info = CXGN::Tools::SVN::Info->new($file_or_dir_path);
 $info->read(); #optional, sets read time explicitly, running svn info and svn stat
 print "Revision: " . $info->revision();
 print "Last Update: " . $info->last_update();
 print "Status: " . $info->status(); #M,A,D,C,!,?, or ''

=head1 AUTHOR

 Chris Carpita is to blame for the usage of this module 

=cut


package CXGN::Tools::SVN::Info;
use CXGN::VHost;
our $PERLLIB= "/data/local/website/perllib";

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $fp = shift;
	$fp ||= $0;

	eval {
		my $vhost = CXGN::VHost->new();
		$self->{vhost} = $vhost;
		$self->{perllib} = $vhost->get_conf("perllib_path");
	};
	$self->{perllib} ||= $PERLLIB;
	if(!-f $fp){
		#try to find module?
		$fp =~ s/::/\//g;
		$fp .= '.pm';
		$fp = $self->{perllib} . '/' . $fp;	
	}
	if(!$fp){
		die "File/Dir path must be passed to constructor, or \$0 must be set\n";
	}
	unless(-f $fp || -d $fp){
		die "$fp is neither a valid file nor directory path\n";
	}

	$self->{fp} = $fp;
	return $self;
}

sub check_read {
	my $self = shift;
	$self->read() unless exists($self->{info}) && exists($self->{stat});
}

sub read {
	my $self = shift;
	my $fp = $self->{fp};
	my @info_out = `svn info $fp`;
	my @stat_out = `svn stat $fp`;
	my @diff_out = ();
	@diff_out = `svn diff $fp` if (-f $fp); #not for directories, that might be too much! and syntax has to change

	$self->{info} = {};
	$self->{stat} = ''; #status of $fp
	$self->{stats} = []; #only will be pushed if $fp is a directory

	foreach(@info_out){
		my @comps = split /:\s*/;
		if(@comps > 2){
			my $first = shift @comps;
			my $second = join "", @comps;
			@comps = ($first,$second);
		}
		my ($key, $value) = @comps;
		$key = lc($key);
		$key =~ s/^\s+//;
		$key =~ s/\s+$//;
		$key =~ s/ /_/g;
		if($value){
			chomp($value);
			$value =~ s/^\s+//; 
			$value =~ s/\s+$//;
		}
		$self->{info}->{$key} = $value;
	}
	foreach(@stat_out){
		my ($stat, $file) = split /\s+/;
		if($self->{fp} eq $file){
			$self->{stat} = $stat;
		}
		else {
			push(@{$self->{stats}}, {status=>$stat,file=>$file});
		}
	}
	if(@diff_out > 0){
		$self->{diff} = join "", @diff_out;
	}
}

sub revision {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{revision};
}

sub info {
	my $self = shift;
	$self->check_read();
	return $self->{info};
}

sub checksum {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{checksum};
}

sub last_author {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{last_changed_author};
}

sub last_revision {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{last_changed_rev};
}

sub last_modified {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{last_changed_date};
}

sub url {
	my $self = shift;
	$self->check_read();
	return $self->{info}->{url};
}

sub branch {
	my $self = shift;
	my $url = $self->url();
	my ($branch) = $url =~ /cxgn\/branches\/(\w+)\//;
	return $branch;
}

sub status {
	my $self = shift;
	$self->check_read();
	return $self->{stat};
}

sub status_list {
	my $self = shift;
	$self->check_read();
	return @{$self->{stats}};
}

sub diff {
	my $self = shift;
	$self->check_read();
	return $self->{diff};
}

1;

