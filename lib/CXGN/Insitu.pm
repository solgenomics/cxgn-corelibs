use strict;
use CXGN::DB::Connection;
use CXGN::DB::SQLWrappers;

package CXGN::Insitu;
use base('CXGN::DB::Connection');

use Data::Dumper;

# for debugging, greater is for more output
our $debug = 1;

#####################################################################
#####################################################################
# generic functions
#####################################################################
#####################################################################

#####################################################################
# constructor
sub new {
	my $class=shift;
	my $self=$class->SUPER::new({dbtype=>"mysql",dbhost=>"localhost",dbschema=>"insitu",dbuser=>"insitu",dbpass=>"insitu_editor"});
	return $self;
}

# get last insert id from database
sub last_insert_id {
	my $self=shift;
	my $sth = $self->prepare("select last_insert_id() as id");
	$sth->execute;
	my $id = $sth->fetchrow_hashref->{'id'};
	return $id;
}

#####################################################################
#####################################################################
# functions to retrieve data
#####################################################################
#####################################################################

sub return_organisms {
	my ($self, $user) = @_;
	my %organisms;
	my ($id, $name, $common, $description);
	my $stm = "select organism_id, name, common_name, description from organism order by name;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute;
	my $rc = $sth->bind_columns(\$id, \$name, \$common, \$description);
	my $count = 1;
	while ($sth->fetch) {
		$organisms{$count}{id} = $id;
		$organisms{$count}{name} = $name;
		$organisms{$count}{common_name} = $common;
		$organisms{$count}{description} = $description;
		$count++;
	}
	$sth->finish;
	return %organisms;
}

#####################################################################
# will return the name of the tag with the requested id
sub return_tag {
	my ($self, $id) = @_;
	my $name;
	my $stm = "select name from tag where tag_id=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($id);
	my $rc = $sth->bind_columns(\$name);
	$sth->fetch;
	$sth->finish;
	return $name;
}

#####################################################################
# will return a hash with all tags (optionally owned by $user)
sub return_tags {
	my ($self, $user) = @_;
	my %tags;
	my ($tag_id, $name, $description, $user);
	my $stm = "select tag_id, name, description, user_id from tag order by name asc;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute;
	my $rc = $sth->bind_columns(\$tag_id, \$name, \$description, \$user);
	while ($sth->fetch) {
		$tags{$name} = [$tag_id, $name, $description, $user];
	}
	$sth->finish;
	return %tags;
}

#####################################################################
# will return all tags, implied tags, etc for the requested item
sub return_relevant_tags {
	my ($self, $type, $id) = @_;
	my ($tag_link_table, $linked_key);
	if ($type eq 'ex') {
		$tag_link_table = "ex_tag";
		$linked_key = "experiment_id";
	}
	elsif ($type eq 'image') {
		$tag_link_table = "image_tag";
		$linked_key = "image_id";
	}
	else {
		die "Unkown table type: $type!\n"
	}
	my %tags = ();
	my @tag_implications = ();
	my ($tag_id, $tag_name, $tag_description, $implied_tag);
	my @implied_tags = ();
	# get general tag info
	my $stm = "select t.tag_id, t.name, t.description from $tag_link_table as l join tag as t on l.tag_id=t.tag_id where l.${linked_key}=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($id);
	my $rc = $sth->bind_columns(\$tag_id, \$tag_name, \$tag_description);
	while ($sth->fetch) {
		push @tag_implications, $tag_id;
		$tags{$tag_name} = [$tag_id, $tag_name, $tag_description];
	}
	# get implied tag info
	@implied_tags = $self->get_implied_tags(\@tag_implications);
	%tags = $self->follow_implied_tags(\%tags, \@implied_tags);
	return %tags;
}

#####################################################################
# given an array of tag ids, return an array of all implied tags
sub get_implied_tags {
	my ($self, $tags) = @_;
	my @implied_tags = ();
	foreach my $tag_id (@$tags) {
		my $implied_tag;
		($debug > 1) and warn "implied tags for tag ${tag_id}:\n";
		my $stm = "select implied_id from tag_implication where tag_id=?;";
		my $sth = $self->prepare($stm);
		my $rv = $sth->execute($tag_id);
		my $rc = $sth->bind_columns(\$implied_tag);
		while ($sth->fetch) {
			($debug > 1) and warn "\t$implied_tag\n";
			push @implied_tags, $implied_tag;
		}
	}
	return @implied_tags;
}

#####################################################################
# given a pre-existing hash, and an array of implied tags, recurses
# through the implications, adding all implied tags to the existing hash
sub follow_implied_tags {
	my ($self, $tags, $implied_tags, $seen_tags) = @_;
	if (!$seen_tags) {
		my %empty_hash = ();
		$seen_tags = \%empty_hash;
	}
	# add all tags currently being viewed to a hash to avoid redundancy
	foreach my $done_id (keys %$tags) {
		my $tag_id = $tags->{$done_id}[0];
		$seen_tags->{$tag_id}++;
	}
	# get information for previously implied tags
	my @implied_tag_ids = $self->get_implied_tags($implied_tags);
	foreach my $id (@$implied_tags) {
		if (!$seen_tags->{$id}) {
			my ($tag_id, $tag_name, $tag_description, $implied_tag);
			# get general tag info
			my $stm = "select tag_id, name, description from tag where tag_id=?;";
			my $sth = $self->prepare($stm);
			my $rv = $sth->execute($id);
			my $rc = $sth->bind_columns(\$tag_id, \$tag_name, \$tag_description);
			$sth->fetch;
			$sth->finish;
			$tags->{$tag_name} = [$tag_id, $tag_name, $tag_description];
		}
		$seen_tags->{$id}++;
	}
	# only push new implied tags if they havn't been seen before
	my @new_implications = ();
	foreach my $implied_tag (@implied_tag_ids) {
		if ($implied_tag && !$seen_tags->{$implied_tag}) {
			push @new_implications, $implied_tag;
		}
	}
	# recurse through new implications, provided there are any
	my %new_tags = ();
	if (@new_implications>0) {
		%new_tags = $self->follow_implied_tags($tags, \@new_implications, $seen_tags);
	}
	else {
		%new_tags = %{$tags};
	}
	return %new_tags;
}

#####################################################################
# follow implied tags in the reverse direction
# given a search array and a seen hash, recurse through the search
# array, ignoring anything in the seen hash. return seen hash 
sub follow_reverse_implications {
	my ($self, $search, $seen) = @_;
	if (!$seen) {
		my %empty_hash = ();
		$seen = \%empty_hash;
	}
	my @new_impliers = ();
	
	foreach my $tag (@$search) {
		if (!$seen->{$tag}) {
			$seen->{$tag}++;
			my $implying_tag;
			my $stm = "select tag_id from tag_implication where implied_id=?;";
			my $sth = $self->prepare($stm);
			my $rv = $sth->execute($tag);
			my $rc = $sth->bind_columns(\$implying_tag);
			while ($sth->fetch) {
				push @new_impliers, $implying_tag;
			}
		}
	}

	my %return_hash = ();
	if (@new_impliers<1) {
		%return_hash = %{$seen};
	}
	else {
		%return_hash = $self->follow_reverse_implications(\@new_impliers, $seen);
	}
	
	return %return_hash;
}

#####################################################################
# will return a hash with all data for each image in the specified
# experiment
#
# DEPRECATED
#
sub return_images {
	my ($self, $experiment_id) = @_;
	my %images = ();
	my ($image_id, $name, $desription, $filename, $file_ext);
	# get information about each image
	my $stm = "select image_id, name, description, filename, file_ext from image where experiment_id=? order by image_id asc;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($experiment_id);
	my $rc = $sth->bind_columns(\$image_id, \$name, \$desription, \$filename, \$file_ext);
	# store non-tag info about each image
	while ($sth->fetch) {
		$images{$image_id} = [$name, $desription, $filename, $file_ext];
	}
	# get tags for each image
	foreach my $image (keys %images) {
		$images{$image}[5] = $self->return_relevant_tags("image", $image);
	}
	return %images;
}

#####################################################################
# will return a hash with all data for the reqested image
# 
# DEPRECATED
#
sub return_image {
	my ($self, $image_id) = @_;
	my %image = ();
	my ($experiment_id, $name, $description, $filename, $file_ext);
	# get general info
	my $stm = "select experiment_id, name, description, filename, file_ext from image where image_id=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($image_id);
	my $rc = $sth->bind_columns(\$experiment_id, \$name, \$description, \$filename, \$file_ext);
	$sth->fetch;
	$sth->finish;
	# get hash of tags for this image, including implied tags
	my %tags = $self->return_relevant_tags("image", $image_id);
	$image{experiment_id} = $experiment_id;
	$image{name} = $name;
	$image{description} = $description;
	$image{filename} = $filename;
	$image{file_ext} = $file_ext;
	$image{tags} = \%tags;
	return %image;
}

#####################################################################
# will return a hash with some data for all experiments
#
# DEPRECATED
#
sub return_experiments {
	my $self = shift;
	my %experiments = ();
	my ($experiment_id, $name, $date, $organism_id, $tissue, $stage, $primer_id, $primer, $description, $user_id);
	# get general info
	my $stm = "select experiment_id, name, date, organism_id, tissue, stage, primer_id, description, user_id from experiment;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute;
	my $rc = $sth->bind_columns(\$experiment_id, \$name, \$date, \$organism_id, \$tissue, \$stage, \$primer_id, \$description, \$user_id);
	# store non-tag info about each experiment
	while ($sth->fetch) {
		$experiments{$experiment_id}{name} = $name;
		$experiments{$experiment_id}{date} = $date;
		$experiments{$experiment_id}{organism_id} = $organism_id;
		$experiments{$experiment_id}{tissue} = $tissue;
		$experiments{$experiment_id}{stage} = $stage;
		$experiments{$experiment_id}{primer_id} = $primer_id;
		$experiments{$experiment_id}{description} = $description;
		$experiments{$experiment_id}{user_id} = $user_id;
	}
	return %experiments;
}

#####################################################################
# will return a hash with all data for the reqested experiment
#
# DEPRECATED
#
sub return_experiment {
	my ($self, $experiment_id) = @_;
	my %experiment = ();
	my ($name, $date, $stage, $organism_id, %organism, $tissue, $primer_id, $primer, $description, $user_id);
	# get general info
	my $stm = "select name, date, organism_id, tissue, stage, primer_id, description, user_id from experiment where experiment_id=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($experiment_id);
	my $rc = $sth->bind_columns(\$name, \$date, \$organism_id, \$tissue, \$stage, \$primer_id, \$description, \$user_id);
	$sth->fetch;
	$sth->finish;
	# get organism name
	%organism = $self->return_organism($organism_id);
	# get primer name
	$primer = $self->return_primer_name($primer_id);
	# get hash of tags for this experiment, including implied tags
	my %tags = $self->return_relevant_tags("ex", $experiment_id);
	$experiment{name} = $name;
	$experiment{date} = $date;
	$experiment{organism_id} = $organism_id;
	$experiment{organism_name} = $organism{name};
	$experiment{organism_common} = $organism{common_name};
	$experiment{tissue} = $tissue;
	$experiment{stage} = $stage;
	$experiment{primer_id} = $primer_id;
	$experiment{primer} = $primer;
	$experiment{description} = $description;
	$experiment{user_id} = $user_id;
	$experiment{tags} = \%tags;
	return %experiment;
}

####################################################################
# will return a hash containing all experiments
# concerning the specified organism
#
# DEPRECATED
#
sub get_organism_items {
	my ($self, $org) = @_;

	if ($debug>1) {
		warn "get_organism_items searching for experiments involving organism $org\n";
	}
	
	my ($stm, $sth, $rv, $rc);
	my %experiments;
	
	# get information from experiments that match
	my ($ex_id, $ex_name, $ex_date, $ex_org, $ex_tissue, $ex_stage, $ex_primer_id, $ex_primer, $ex_description, $ex_user_id);
	$stm = "select distinct experiment_id, name, date, organism_id, tissue, stage, primer_id, description, user_id from experiment where organism_id=?;";
	$sth = $self->prepare($stm);
	$rv = $sth->execute($org);
	$rc = $sth->bind_columns(\$ex_id, \$ex_name, \$ex_date, \$ex_org, \$ex_tissue, \$ex_stage, \$ex_primer_id, \$ex_description, \$ex_user_id);
	while ($sth->fetch) {
		my %organism = $self->return_organism($ex_org);
		$experiments{$ex_id}{name} = $ex_name;
		$experiments{$ex_id}{date} = $ex_date;
		$experiments{$ex_id}{organism_id} = $ex_org;
		$experiments{$ex_id}{organism_name} = $organism{name};
		$experiments{$ex_id}{organism_common} = $organism{common_name};
		$experiments{$ex_id}{tissue} = $ex_tissue;
		$experiments{$ex_id}{stage} = $ex_stage;
		$experiments{$ex_id}{primer_id} = $ex_primer_id;
		$experiments{$ex_id}{primer} = $self->return_primer_name($ex_primer_id);
		$experiments{$ex_id}{description} = $ex_description;
		$experiments{$ex_id}{user_id} = $ex_user_id;
		my %tags = $self->return_relevant_tags("ex", $ex_id);
		$experiments{$ex_id}{tags} = \%tags;
	}

	return %experiments;
}

####################################################################
# will return a hash containing all experiments
# submitted by the specified user
#
# DEPRECATED
#
sub get_user_items {
	my ($self, $user) = @_;

	if ($debug>1) {
		warn "get_user_items searching for experiments submitted by $user\n";
	}

	my ($stm, $sth, $rv, $rc);
	my %experiments;

	# get information from experiments that match
	my ($ex_id, $ex_name, $ex_date, $ex_org, $ex_tissue, $ex_stage, $ex_primer_id, $ex_primer, $ex_description, $ex_user_id);
	$stm = "select distinct experiment_id, name, date, organism_id, tissue, stage, primer_id, description, user_id from experiment where user_id=?;";
	$sth = $self->prepare($stm);
	$rv = $sth->execute($user);
	$rc = $sth->bind_columns(\$ex_id, \$ex_name, \$ex_date, \$ex_org, \$ex_tissue, \$ex_stage, \$ex_primer_id, \$ex_description, \$ex_user_id);
	while ($sth->fetch) {
		my %organism = $self->return_organism($ex_org);
		$experiments{$ex_id}{name} = $ex_name;
		$experiments{$ex_id}{date} = $ex_date;
		$experiments{$ex_id}{organism_id} = $ex_org;
		$experiments{$ex_id}{organism_name} = $organism{name};
		$experiments{$ex_id}{organism_common} = $organism{common_name};
		$experiments{$ex_id}{tissue} = $ex_tissue;
		$experiments{$ex_id}{stage} = $ex_stage;
		$experiments{$ex_id}{primer_id} = $ex_primer_id;
		$experiments{$ex_id}{primer} = $self->return_primer_name($ex_primer_id);
		$experiments{$ex_id}{description} = $ex_description;
		$experiments{$ex_id}{user_id} = $ex_user_id;
		my %tags = $self->return_relevant_tags("ex", $ex_id);
		$experiments{$ex_id}{tags} = \%tags;
	}

	return %experiments;
}

####################################################################
# will return a hash containing all experiments
# concerning the specified probe
#
# DEPRECATED
#
sub get_primer_items {
	my ($self, $probe) = @_;
	
	if ($debug>1) {
		warn "get_probe_items searching for experiments involving probe $probe\n";
	}

	my ($stm, $sth, $rv, $rc);
	my %experiments;

	# get information from experiments that match
	my ($ex_id, $ex_name, $ex_date, $ex_org, $ex_tissue, $ex_stage, $ex_primer_id, $ex_primer, $ex_description, $ex_user_id);
	$stm = "select distinct experiment_id, name, date, organism_id, tissue, stage, primer_id, description, user_id from experiment where primer_id=?;";
	$sth = $self->prepare($stm);
	$rv = $sth->execute($probe);
	$rc = $sth->bind_columns(\$ex_id, \$ex_name, \$ex_date, \$ex_org, \$ex_tissue, \$ex_stage, \$ex_primer_id, \$ex_description, \$ex_user_id);
	while ($sth->fetch) {
		my %organism = $self->return_organism($ex_org);
		$experiments{$ex_id}{name} = $ex_name;
		$experiments{$ex_id}{date} = $ex_date;
		$experiments{$ex_id}{organism_id} = $ex_org;
		$experiments{$ex_id}{organism_name} = $organism{name};
		$experiments{$ex_id}{organism_common} = $organism{common_name};
		$experiments{$ex_id}{tissue} = $ex_tissue;
		$experiments{$ex_id}{stage} = $ex_stage;
		$experiments{$ex_id}{primer_id} = $ex_primer_id;
		$experiments{$ex_id}{primer} = $self->return_primer_name($ex_primer_id);
		$experiments{$ex_id}{description} = $ex_description;
		$experiments{$ex_id}{user_id} = $ex_user_id;
		my %tags = $self->return_relevant_tags("ex", $ex_id);
		$experiments{$ex_id}{tags} = \%tags;
	}

	return %experiments;
	
}
	

####################################################################
# will return a hash containing an experiment array and an image
# array of all items with the submitted tag(s)
#
# DEPRECATED
#
sub get_tagged_items {
	my ($self, $in_tags) = @_;
	
	# the count that an item has to have to be a match
	my $match_count = @$in_tags;

	# hashes where matches will live
	my %return_matches = ();
	my %matches = ();
	my %experiments = ();
	my %images = ();
	my %sub_tags = (); # tags that were also found in these matches
	
	# this is hirsute, because we need to query for each tag separately,
	# and then combine the results.  we need to do this because there needs
	# to be 'OR's for implied tags, and 'AND's for searches for multiple tags
	foreach my $tag (@$in_tags) {
		($debug > 1) and warn "Searching for experiments/images that match tag $tag...\n";
		
		# first find out whether any of the tags we are querying for are
		# implied by other tags- if so, these may not match with the standard
		# query, but they should stil be hits
		my @dummy_array = [$tag];
		my %implying_tags = $self->follow_reverse_implications(@dummy_array);
		
		# create a where clause for this tag and the tags that imply it
		my $where = "where tag_id=?";
		foreach (sort keys %implying_tags) {
			$where .= " or tag_id=$_";
		}

		my ($stm, $sth, $rv, $rc);
		
		# get information from experiments that match
		my ($ex_id, $ex_name, $ex_date, $ex_org, $ex_tissue, $ex_stage, $ex_primer_id, $ex_primer, $ex_description);
		$stm = "select distinct t.experiment_id, e.name, e.date, e.organism_id, e.tissue, e.stage, e.primer_id, e.description from ex_tag as t left join experiment as e on t.experiment_id=e.experiment_id $where;";
		$sth = $self->prepare($stm);
		$rv = $sth->execute($tag);
		$rc = $sth->bind_columns(\$ex_id, \$ex_name, \$ex_date, \$ex_org, \$ex_tissue, \$ex_stage, \$ex_primer_id, \$ex_description);
		while ($sth->fetch) {
			$matches{experiments}{$ex_id}++;
			my %organism = $self->return_organism($ex_org);
			$experiments{$ex_id}{name} = $ex_name;
			$experiments{$ex_id}{date} = $ex_date;
			$experiments{$ex_id}{organism_id} = $ex_org;
			$experiments{$ex_id}{organism_name} = $organism{name};
			$experiments{$ex_id}{organism_common} = $organism{common};
			$experiments{$ex_id}{tissue} = $ex_tissue;
			$experiments{$ex_id}{stage} = $ex_stage;
			$experiments{$ex_id}{primer_id} = $ex_primer_id;
			$experiments{$ex_id}{primer} = $self->return_primer_name($ex_primer_id);
			$experiments{$ex_id}{description} = $ex_description;
			my %ex_tags = $self->return_relevant_tags("ex", $ex_id);
			$experiments{$ex_id}{tags} = \%ex_tags;
			# add tags for this item to sub_tags
			foreach my $sub_tag (keys %ex_tags) {
				$sub_tags{experiments}{$ex_id}{$sub_tag} = $ex_tags{$sub_tag};
			}
		}

		 # get information from images that match
		 my ($image_id, $image_experiment, $image_name, $image_description, $image_filename, $image_file_ext);
		 $stm = "select distinct t.image_id, i.experiment_id, i.name, i.description, i.filename, i.file_ext from image_tag as t left join image as i on t.image_id=i.image_id $where;";
		 $sth = $self->prepare($stm);
		 $rv = $sth->execute($tag);
		 $rc = $sth->bind_columns(\$image_id, \$image_experiment, \$image_name, \$image_description, \$image_filename, \$image_file_ext);
		 while ($sth->fetch) {
			$matches{images}{$image_id}++;
			$images{$image_id}{experiment} = $image_experiment;
			$images{$image_id}{name} = $image_name;
			$images{$image_id}{description} = $image_description;
			$images{$image_id}{filename} = $image_filename;
			$images{$image_id}{file_ext} = $image_file_ext;
			my %img_tags = $self->return_relevant_tags("image", $image_id);
			$images{$image_id}{tags} = \%img_tags;
			# add tags for this item to sub_tags
			foreach my $sub_tag (keys %img_tags) {
				$sub_tags{images}{$image_id}{$sub_tag} = $img_tags{$sub_tag};
			}
		 }
		
	}

	if ($debug>1) {
		warn "\n\nget_tagged_items required match count: $match_count\n";
		warn "\n\nget_tagged_items matches: \n";
		warn Dumper \%matches;
		warn "\n\nget_tagged_items experiments: \n";
		warn Dumper \%experiments;
		warn "\n\nget_tagged_items images: \n";
		warn Dumper \%images;
		warn "\n\nget_tagged_items sub_tags: \n";
		warn Dumper \%sub_tags;
		warn "\n\n";
	}

	# given the match_count and matches, only return items that have
	# these numbers equal
	foreach my $match_ex (keys %{$matches{experiments}}) {
		if ($matches{experiments}{$match_ex} == $match_count) {
			$debug and warn "experiment $match_ex is a match against all tags!\n";
			$return_matches{experiments}{$match_ex} = $experiments{$match_ex};
			$return_matches{matches}{experiments}++;
			foreach my $sub_tag (keys %{$sub_tags{experiments}{$match_ex}}) {
				$return_matches{sub_tags}{$sub_tag} = $sub_tags{experiments}{$match_ex}{$sub_tag};
			}
		}
		else {
			$debug and warn "experiment $match_ex doesn't match\n";
		}
	}
	foreach my $match_img (keys %{$matches{images}}) {
		if ($matches{images}{$match_img} == $match_count) {
			$debug and warn "image $match_img is a match against all tags!\n";
			$return_matches{images}{$match_img} = $images{$match_img};
			$return_matches{matches}{images}++;
			foreach my $sub_tag (keys %{$sub_tags{images}{$match_img}}) {
				$return_matches{sub_tags}{$sub_tag} = $sub_tags{images}{$match_img}{$sub_tag};
			}
		}
		else {
			$debug and warn "image $match_img doesn't match\n";
		}
	}

	if ($debug>1) {
		warn "\n\nget_tagged_items return_matches: \n";
		warn Dumper \%return_matches;
		warn "\n\n";
	}
	
	# return resultint hash
	return %return_matches;
	
}

#####################################################################
# given organism id, return scientific name, common name, and desc.
#
# DEPRECATED
#
sub return_organism {
	my ($self, $organism_id) = @_;
	my (%org, $organism, $common_name, $description);
	my $stm = "select name, common_name, description from organism where organism_id=?";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($organism_id);
	my $rc = $sth->bind_columns(\$organism, \$common_name, \$description);
	$sth->fetch;
	$sth->finish;
	$org{id} = $organism_id;
	$org{name} = $organism;
	$org{common_name} = $common_name;
	$org{description} = $description;
	return %org;
}


#####################################################################
# given primer id, return name
#
# DEPRECATED
#
sub return_primer_name {
	my ($self, $primer_id) = @_;
	my ($primer);
	my $stm = "select name from primer where primer_id=?";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($primer_id);
	my $rc = $sth->bind_columns(\$primer);
	$sth->fetch;
	$sth->finish;
	return $primer;
}

#####################################################################
# given primer id, return all primer info
#
# DEPRECATED
#
sub return_primer {
	my ($self, $primer_id) = @_;
	my (%primer, $name, $p1, $p1seq, $p2, $p2seq, $seq, $clone, $link_desc, $link);
	my $stm = "select name, primer1, primer1_seq, primer2, primer2_seq, sequence, clone, link_desc, link from primer where primer_id=?";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($primer_id);
	my $rc = $sth->bind_columns(\$name, \$p1, \$p1seq, \$p2, \$p2seq, \$seq, \$clone, \$link_desc, \$link);
	$sth->fetch;
	$sth->finish;
	$primer{id} = $primer_id;
	$primer{name} = $name;
	$primer{primer1} = $p1;
	$primer{primer1_seq} = $p1seq;
	$primer{primer2} = $p2;
	$primer{primer2_seq} = $p2seq;
	$primer{sequence} = $seq;
	$primer{clone} = $clone;
	$primer{link_desc} = $link_desc;
	$primer{link} = $link;
	return %primer;
}

#####################################################################
# return primer info for all primers
#
# DEPRECATED
#
sub return_primers {
	my $self = shift;
	my (%primer, $id, $name, $p1, $p1seq, $p2, $p2seq, $seq, $clone, $link_desc, $link);
	my $stm = "select primer_id, name, primer1, primer1_seq, primer2, primer2_seq, sequence, clone, link_desc, link from primer";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute();
	my $rc = $sth->bind_columns(\$id, \$name, \$p1, \$p1seq, \$p2, \$p2seq, \$seq, \$clone, \$link_desc, \$link);
	while ($sth->fetch) {
		$primer{$name}{id} = $id;
		$primer{$name}{name} = $name;
		$primer{$name}{primer1} = $p1;
		$primer{$name}{primer1_seq} = $p1seq;
		$primer{$name}{primer2} = $p2;
		$primer{$name}{primer2_seq} = $p2seq;
		$primer{$name}{sequence} = $seq;
		$primer{$name}{clone} = $clone;
		$primer{$name}{link_desc} = $link_desc;
		$primer{$name}{link} = $link;
	}
	return %primer;
}

#####################################################################
#####################################################################
# functions to update existing data
#####################################################################
#####################################################################

#####################################################################
# will update data for the specified image
#
# DEPRECATED
#
sub update_image_data {
	my ($self, $id, $name, $description, $tags) =@_;
	if ($debug > 1) {
		warn "update_image_data got:\n";
		warn "\tid: $id\n";
		warn "\tname: $name\n";
		warn "\tdescription: $description\n";
		warn "\ttags:\n";
		warn Dumper $tags;
		warn "\n";
	}
	# update image table
	my $stm = "update image set name=?, description=? where image_id=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($name, $description, $id);
	$sth->finish;
	# update tags
	foreach my $tag (@$tags) {
		if ($tag && ($tag =~ m/[0-9]+/)) {
			$stm = "insert into image_tag (image_id, tag_id) values (?, ?)";
			$sth = $self->prepare($stm);
			$rv = $sth->execute($id, $tag);
			$sth->finish;
		}
	}
}

#####################################################################           
# will update data for the specified tag
#
# DEPRECATED
#
sub update_tag_data {
	my ($self, $id, $name, $description, $implied_tags) =@_;
	if ($debug > 1) {
		warn "update_tag_data got:\n";
		warn "\tid: $id\n";
		warn "\tname: $name\n";
		warn "\tdescription: $description\n";
		warn "\timplied_tags:\n";
		warn Dumper $implied_tags;
		warn "\n";
	}

	# update tage table
	my $stm = "update tag set name=?, description=? where tag_id=?;";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($name, $description, $id);
	$sth->finish;

	# update tags
	# first delete all old implications
	$stm = "delete from tag_implication where tag_id=?;";
	$sth = $self->prepare($stm);
	$rv = $sth->execute($id);
	$sth->finish;
	# now insert new implications
	foreach my $tag (@$implied_tags) {
		if ($tag && ($tag =~ m/[0-9]+/)) {
			$stm = "insert into tag_implication (tag_id, implied_id) values (?, ?)";
			$sth = $self->prepare($stm);
			$rv = $sth->execute($id, $tag);
			$sth->finish;
		}
	}
	
}

#####################################################################
#####################################################################
# functions to insert data
#####################################################################
#####################################################################

#####################################################################
# will insert a new organism into the database
#
# DEPRECATED
#
sub insert_organism {
	my ($self, $name, $description, $user) = @_;
	my $stm = "insert into organism (name, common_name, description) values (?, ?, ?)";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($name, $description, $user);
}

#####################################################################
# will insert a new category into the database
#
# DEPRECATED
#
sub insert_tag {
	my ($self, $name, $description, $user) = @_;
	my $stm = "insert into tag (name, description, user_id) values (?, ?, ?)";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($name, $description, $user);
}

#####################################################################
# will insert information regarding an experiment into the database
#
# DEPRECATED
#
sub insert_experiment {
	my ($self, $name, $date, $organism_id, $tissue, $stage, $primer, $primer_link_desc, $primer_link, $primer_clone, $primer_sequence, $primer_p1, $primer_p1_seq, $primer_p2, $primer_p2_seq, $description, $tags, $user) = @_;
	if ($debug > 1) {
		warn "insert_experiment got:\n";
		warn "\tname: $name\n";
		warn "\tdate: $date\n";
		warn "\torganism: $organism_id\n";
		warn "\ttissue: $tissue\n";
		warn "\tstage: $stage\n";
		warn "\tprimer: $primer\n";
		warn "\tprimer_link_desc: $primer_link_desc\n";
		warn "\tprimer_link: $primer_link\n";
		warn "\tprimer_clone: $primer_clone\n";
		warn "\tprimer_sequence:\n$primer_sequence\n";
		warn "\tprimer_p1: $primer_p1\n";
		warn "\tprimer_p1_seq:\n$primer_p1_seq\n";
		warn "\tprimer_p2: $primer_p2\n";
		warn "\tprimer_p2_seq:\n$primer_p2_seq\n";
		warn "\tdescription:\n$description\n";
		warn "\ttags:\n" . Dumper $tags;
		warn "\tuser: $user\n";
	}
	
	# look up the primer in the primer table, if it already exists use that key
	# otherwise, create a new row for it and use that key
	my $primer_id;
	my $stm = "select primer_id from primer where name=?";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($primer);
	my $rc = $sth->bind_columns (\$primer_id);
	$sth->fetch;
	$sth->finish;
	if (!$primer_id) {
		$stm = "insert into primer (name, link_desc, link, clone, sequence, primer1, primer1_seq, primer2, primer2_seq, user_id) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
		$sth = $self->prepare($stm);
		$rv = $sth->execute($primer, $primer_link_desc, $primer_link, $primer_clone, $primer_sequence, $primer_p1, $primer_p1_seq, $primer_p2, $primer_p2_seq, $user);
		$sth->finish;
		$primer_id = $self->last_insert_id;
	}
		
	# insert row into experiment table, get key for that row
	$stm = "insert into experiment (name, date, organism_id, tissue, stage, primer_id, description, user_id) values (?, ?, ?, ?, ?, ?, ?, ?)";
	$sth = $self->prepare($stm);
	$rv = $sth->execute($name, $date, $organism_id, $tissue, $stage, $primer_id, $description, $user);
	$sth->finish;
	my $experiment_id = $self->last_insert_id;
	
	# link this experiment with selected tags
	foreach my $tag (@$tags) {
		$stm = "insert into ex_tag (experiment_id, tag_id) values (?, ?)";
		$sth = $self->prepare($stm);
		$rv = $sth->execute($experiment_id, $tag);
		$sth->finish;
	}

	# return key of this experiment
	return $experiment_id;
	
}

#####################################################################
# will insert information regarding an image into the database
#
# DEPRECATED
#
sub insert_image {
	my ($self, $experiment_id, $filename, $file_ext) = @_;
	my $stm = "insert into image (experiment_id, filename, file_ext) values (?, ?, ?)";
	my $sth = $self->prepare($stm);
	my $rv = $sth->execute($experiment_id, $filename, $file_ext);
	$sth->finish;
	my $image_id = $self->last_insert_id;
	return $image_id;
}

#####################################################################
#####################################################################
# Do not delete this line:
1;
