
#!/usr/bin/perl

=head1 NAME

CXGN::Marker::Tools

=head1 SYNOPSIS

use CXGN::Marker::Tools qw(
                           # stuff
                           );

# do stuff

=head1 DESCRIPTION

Non-object-oriented functions for doing things with markers.

=head1 FUNCTIONS

=cut

package CXGN::Marker::Tools;

use strict;
use warnings;

use CXGN::DB::Connection;
use Exporter;
use DBI;

our @ISA;
push( @ISA, 'Exporter');
our @EXPORT_OK = qw(
clean_marker_name 
fix_marker_name
guess_marker_type
subscript
get_type_id
get_conf_id
get_experiment_type_id
get_ids_for_marker_name
get_random_marker
marker_name_to_ids
random_marker_id
);



=over 12

=item clean_marker_name()

Converts a common variation of a name for a marker into a name as it
would appear in our database. Used when someone searches for a marker
name, or when a loading script is loading new names from a
spreadsheet.

When called in list context, it returns the cleaned marker name and
any trimmed subscript. When called in scalar context, it just returns
the cleaned marker name.

   my $foo = "TG123a"

   my $marker = clean_marker_name($foo); 
   # returns "TG123"

   my ($marker, $subscript) = clean_marker_name($foo); 
   # returns "TG123" and "a"

This function GUESSES what you want. It is very smart, and usually
correct. But we all make mistakes! Do not blindly trust this function.
It is clever and tricksy and will start giving you wrong answers the 
day you let your guard down.

The cleaning routines do some or all of the following (probably not an
exhaustive list): Removes a subscript (returning it if desired, see
above); zero-pads cos markers (T25 -> T0025); removes zero-padding on
other types of markers; adds hyphens to EST markers (cLEX11k1 ->
cLEX-11-k1).

=cut

sub clean_marker_name {

  my $name = shift;
  my $subscript= '';

  if ($name =~ /Solyc\d\dg\d{6}/) { 
      if (wantarray) { 
	  return ($name, $subscript);
      }
      else { 
	  return $name;
      }
  }

  # just in case
  chomp $name;
  $name =~ s/\s+//g;
  $name =~ s/_CAPS$//i;
  
  # Rob's marker-massaging routines
  # (1) ... to remove any subscript
  if ($name =~ /^(\S+\d)_?([A-Ca-c])$/) { # require at least one digit
    $name = $1;
    $subscript = $2;
  }
  # (2) ... to format the ID's of COS markers (and others) correctly.
  if ($name =~ /^T(\d+)(\W?.*)$/i) { 
    $name = "T" . sprintf("%04d", $1). $2;
  } elsif ($name =~ /^([A-z]+)0+(\d+\S*)$/) {
    # Trim extraneous leading 0's so that eg. CT0051 => CT51
    $name = $1 . $2;
  }
  # (3) ... to format ID's of mapped EST's correctly.
  if ($name =~ /^(d?c[[:alpha:]]{3})-?(\d+)-?(\w\d+)$/) {
    $name = "$1-$2-$3";
  }
  
  $name =~ s/\s+//g; # remove any whitespace

  # (Sunseeds uses one convention to name AFLPs, KeyGene uses another.
  # we decided to stick with the KeyGene convention.)
  $name =~ s/SS_([A-Z]\d+)([A-Z]\d+)_?([A-Z])_?([\d.]+)/SS_$1\/$2-$3-$4/;
  
  if(wantarray){

    return ($name, $subscript);

  } else {

    return $name;

  }
}

=item subscript()

  my $subscript = subscript("TG123A");
  # $subscript is now "A"

  my $subscript = subscript("TG124");
  # $subscript is undef

Returns the subscript found on a marker. For more better smarterness, 
use clean_marker_name() instead.

=cut


sub subscript {

  my ($marker) = @_;

  if ($marker =~ /(.*\d)([abc])$/i){

    return $2;

  } else {

    return;

  }

}

=item marker_name_to_ids()

  my @possibilities = marker_name_to_ids($dbh, "JFD85943");

Given a marker name, returns a list of markers (by id) that you might
be thinking of. If a marker was incorrectly loaded with several IDs,
this will give you all of them. If several markers share the same
name, this will also give you all of those. This function can't really
tell the difference between those two situations. You'll have to
figure it out yourself.

The marker name is searched both dirty and clean (see clean_marker_name()).

The name is searched case-insensitively, so 'tm2' turns up results for
"TM2" and also "Tm2".

=cut

#this function attempts to return all ids of marker table entries which SHOULD be referring to the SAME MARKER.
#since this is based on name only, it will falsely return multiple marker table entries IF TWO DIFFERENT MARKERS HAVE THE SAME NAME (ie TM2 and Tm2).
sub marker_name_to_ids {
    my($dbh,$marker_name)=@_;
    unless(CXGN::DB::Connection::is_valid_dbh($dbh)){die"Invalid DBH";}
    my @ids;
    my $caps_name;
    my $clean_name=&clean_marker_name($marker_name);
    my $dirty_caps_name=$marker_name."_CAPS";
    my $clean_caps_name=$clean_name."_CAPS";
    my $query = "select distinct marker_id from marker_alias where alias ilike ? or alias ilike ? or alias ilike ? or alias ilike ?";
    my $q=$dbh->prepare($query);
    $q->execute($marker_name,$clean_name,$dirty_caps_name,$caps_name);
    while(my($id)=$q->fetchrow_array()) { push(@ids,$id) }
    return @ids;
}

=item insert_marker

=cut

sub insert_marker {
    my ($dbh,$marker_name) = @_;
    my $clean_name = &clean_marker_name($marker_name);
    my $marker_id = &insert($dbh,"marker","marker_id",["dummy_field"],('f'));
    &insert($dbh,"marker_alias","alias_id",["alias","marker_id","preferred"],($clean_name,$marker_id,'t'));
    return $marker_id;
}


=item get_accession_id

=cut

sub get_accession_id {
    my ($dbh,$accession) = @_;
 
    my $query = "select accession.accession_id from accession_names join accession "
	. "using (accession_name_id) where accession_name = ?";

    my $q = $dbh->prepare($query);
    $q->execute($accession);

    my ($accession_id) = $q->fetchrow_array();
    if (!$accession_id) { die "no accession_id found for accession $accession\n" }
    return $accession_id;
}

=item insert

=cut

sub insert {
    my ($dbh, $table, $id, $field_names, @field_values) = @_;
    my $placeholders = "?," x $#field_values;
    $placeholders .= "?";
    $field_names = join(",",@$field_names);

    my $sth = $dbh->prepare("insert into $table ($field_names) values ($placeholders)");
    $sth->execute(@field_values);
    
    my $query = "select max ($id) from $table";
    my $q = $dbh->prepare($query);
    $q->execute;
    ($id) = $q->fetchrow_array();
 
    # why doesn't this work????
    #    my $id = $dbh->last_insert_id(undef,undef,$table,undef);
    
    return $id;
}

=item get_sequence_id

Return the sequence_id for a given sequence

=cut

sub get_sequence_id {
    my ($dbh, $sequence) = @_;

    my $query = "select sequence_id from sequence where sequence = ?";
    my $q=$dbh->prepare($query);
    $q->execute($sequence);

    my ($sequence_id) = $q->fetchrow_array();

    if (!$sequence_id) { warn "no sequence_id found for sequence [$sequence]\n";  }
    return $sequence_id;
}

=item is_valid_marker_id

Just checks for existence of a marker with this ID in the database.

    if(CXGN::Marker::Tools::is_valid_marker_id($dbh,$marker_id))
    {
        #do stuff with your newly validated marker id
    }

=cut

sub is_valid_marker_id
{
    my($dbh,$marker_id)=@_;
    my $q=$dbh->prepare('select marker_id from marker where marker_id=?');
    $q->execute($marker_id);
    my($id)=$q->fetchrow_array();
    return $id;
}

=item legacy_id_to_id

Converts legacy marker ID to current marker ID

    my $current_id=CXGN::Marker::Tools::legacy_id_to_id($dbh,$legacy_id);

=cut

sub legacy_id_to_id
{
    my($dbh,$legacy_id)=@_;
    my $q=$dbh->prepare('select new_marker_id from temp_marker_correspondence where old_marker_id=?');
    $q->execute($legacy_id);
    my($id)=$q->fetchrow_array();
    return $id;
}

=item random_marker_id()

Just what it sounds like. 
  
  my $id = random_marker_id($dbh);

=cut

sub random_marker_id {

  my ($dbh) = @_;
  
  my ($ret) = $dbh->selectrow_array("SELECT marker_id FROM marker ORDER BY RANDOM() LIMIT 1");

  return $ret;

}


=item get_marker_confidence_id()

Queries marker_confidence for the id of the confidence you describe.

  my $conf = get_marker_confidence_id($dbh,"I(LOD2)");

=cut

sub get_marker_confidence_id {
    my($dbh,$conf_name)=@_;
    if($conf_name eq 'CF') { $conf_name='CF(LOD3)' }
    my $select = "select confidence_id from marker_confidence where confidence_name ilike ?";
    my $q=$dbh->prepare($select);
    $q->execute($conf_name);
    my($conf_id)=$q->fetchrow_array();
    return $conf_id;
}


=item get_enzyme_id()

Name your favorite enzyme, and this function will give you back a number!

  my $enz_id = get_enzyme_id($dbh, "EcoRI");

=cut


sub get_enzyme_id {
    my ($dbh, $enzyme_name) = @_;
    my $select = "select enzyme_id from enzymes where enzyme_name ilike ?";
    my $q=$dbh->prepare($select);
    $q->execute($enzyme_name);
    my($enzyme_id)=$q->fetchrow_array();
    return $enzyme_id;
}


=item get_collection_id()

Get the ID of the given marker collection.

  my $coll_id = get_collection_id($dbh, "COSII");

=cut

sub get_collection_id {
    my($dbh,$collection_name)=@_;
    my $select = "select mc_id from marker_collection where mc_name ilike ?";
    my $q=$dbh->prepare($select);
    $q->execute($collection_name);
    my($collection_id)=$q->fetchrow_array();
    return $collection_id;
}    


=item get_lg_id()

Get the ID of the given linkage group name.

    my $id=get_lg_id($dbh,'4a');

=cut

sub get_lg_id
{
    my($dbh,$lg_name,$map_version_id)=@_;
    my $select = "select lg_id from linkage_group where lg_name=? and map_version_id=?";
    my $q=$dbh->prepare($select);
    $q->execute($lg_name,$map_version_id);
    my($lg_id)=$q->fetchrow_array();
    return $lg_id;
}


=item collection_name_to_description()

Give it a marker collection name and get a description of that collection back.

    my $desc=collection_name_to_description($dbh,'COSII');

=cut

sub collection_name_to_description
{
    my($dbh,$collection_name)=@_;
    my $q=$dbh->prepare('select mc_description from marker_collection where mc_name ilike ?');
    $q->execute($collection_name);
    my($desc)=$q->fetchrow_array();
    return $desc;    
}

=item get_derived_from_source_id()

You have a marker source in mind, but you want to know what the
database calls it.

  my $source_id = get_derived_from_source_id($dbh, "EST Friblets");


=cut


sub get_derived_from_source_id
{
    my($dbh,$source_name)=@_;
    my $select = "select derived_from_source_id from derived_from_source where source_name ilike ?";
    my $q=$dbh->prepare($select);
    $q->execute($source_name);
    my($source_id)=$q->fetchrow_array();
    return $source_id;
} 

=item dirty_marker_names($dbh)

All marker names (aliases) must be cleaned before insertion using clean_marker_name.
Putting some kind of constraint in the database for this would be kind of hard, so we are doing it here, outside the db, instead.
Send in a dbh, and you will get an empty list in return if all is well. 
If you get a list of dirty names back, your script should probably die, and they should be all be fixed in the databse using clean_marker_name.

    my @dirty_names=dirty_marker_names($dbh);

=cut

sub dirty_marker_names
{
    my($dbh)=@_;
    my @dirty_names=();
    my $clean_alias_q=$dbh->prepare('select alias from marker_alias');
    $clean_alias_q->execute();
    while(my($alias)=$clean_alias_q->fetchrow_array())
    {
        my $clean_name=CXGN::Marker::Tools::clean_marker_name($alias);
        unless($clean_name eq $alias)
        {
            push(@dirty_names,$alias);
        }
        my $doubly_clean_name=CXGN::Marker::Tools::clean_marker_name($clean_name);
        unless($doubly_clean_name eq $clean_name)
        {
            die"Aack! Marker name '$clean_name' can be cleaned again to '$doubly_clean_name'! The world is about to end, unless you can fix clean_marker_name to handle this!\n";
        }    
    }
    return @dirty_names;
}

=item cosii_to_arab_name()

  my $arab_name = cosii_to_arab_name($cosii_name)

=item arab_name_to_cosii_name()

  my $cosii_name = arab_name_to_cosii_name($arab_name)

=cut

sub cosii_to_arab_name
{
    my($name)=@_;
    substr($name,0,3)='';#remove first 3 characters
    return $name;
}
sub arab_name_to_cosii_name
{
    my($name)=@_;
    $name="C2_".$name;
    chop($name);#remove digit
    chop($name);#remove period
    return $name;
}

=item tair_gene_search_link()

This creates an HTML link to a gene on TAIR. 

  my $link = tair_gene_search_link($gene_name);

=cut

sub tair_gene_search_link
{
    my($gene_name)=@_;
    return"<a href=\"http://arabidopsis.org/servlets/TairObject?type=locus&name=$gene_name\">$gene_name on TAIR</a>";
}

=item cosii_name_to_seq_file_search_string()

Extracts a sequence filename substring which can be used to search for COSII files in the file system using 'find'.

    my $find_string = cosii_name_to_seq_file_search_string($cosii_name);

=cut

sub cosii_name_to_seq_file_search_string
{
    my($cosii_name)=@_;
    if($cosii_name=~/(\dg\d\d\d\d\d)/)
    {
        return $1;
    }
}

=item lg_name_and_position()

Extracts lg_name and position from a string like '01' or '01.000' or '01.525*'.

    my($lg_name,$position)=CXGN::Marker::Tools::lg_name_and_position($string);

=cut

sub lg_name_and_position
{
    my($map_pos)=@_;
    my($chromosome,$position);
    if($map_pos=~/^(\d+)\.(\d+)\*?$/)
    {
        $chromosome=$1;
        $position=$2;
    }
    elsif($map_pos=~/^(\d+)\.?(0+)?\*?$/)
    {
        $chromosome=$1;
        $position=0;
    }
    else
    {
        die"Could not get lg_name and position from string '$map_pos'";
    }
    $position=".$position";
    $position*=1000;#whatever. that's how they are stored.
    if($chromosome=~/^0+(\d+)/)#remove preceding zeroes
    {
        $chromosome=$1;
    }
    return($chromosome,$position);
}

=back

=head1 AUTHORS

Beth and John

=head1 BUGS

     2. (Zool.) A general name applied to various insects
        belonging to the Hemiptera; as, the squash bug; the chinch
        bug, etc.
        [1913 Webster]

=head1 LICENSE

This module is covered under the same license as the rest of CXGN. 
Questions? Contact sgn-feedback@sgn.cornell.edu

=head1 SEE ALSO

CXGN::Marker, CXGN::Marker::Modifiable, CXGN::Marker::Location, CXGN::Marker::PCR::Experiment, CXGN::Marker::RFLP::Experiment, markerinfo.pl, markersearch.pl.

=cut





















# every good module returns true
1;
