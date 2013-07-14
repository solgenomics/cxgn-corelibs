package SGN::Schema::BlastDb;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Carp;
use File::Spec;
use File::Basename;
use File::Copy;
use File::Path;
use POSIX;

use List::MoreUtils qw/ uniq /;

use Memoize;

use CXGN::BlastDB::Config;
use CXGN::Tools::List qw/any min all max/;
use CXGN::Tools::Run;

use Bio::BLAST::Database;


=head1 NAME

SGN::Schema::BlastDb

=head1 DESCRIPTION

This table holds metadata about the BLAST databases that we keep in stock.

=cut

__PACKAGE__->table("blast_db");

=head1 ACCESSORS

=head2 blast_db_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'blast_db_blast_db_id_seq'

=head2 file_base

  data_type: 'varchar'
  is_nullable: 0
  size: 120

the basename of the blast db files, relative to the root of the databases repository.  A blast DB is usually composed of 3 files, all with a given basename, and with the extensions .[pn]in, .[pn]sq, and .[pn]hr.

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 80

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 80

=head2 source_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 lookup_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 update_freq

  data_type: 'varchar'
  default_value: 'monthly'
  is_nullable: 0
  size: 80

=head2 info_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 index_seqs

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

corresponds to formatdb -o option.  Set true if formatdb should be given a '-o T'.  This is used only if you later want to fetch specific sequences out of this blast db.

=head2 blast_db_group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

blast_db_group this belongs to, for displaying on web

=head2 web_interface_visible

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

whether this blast DB is available for BLASTing via web interfaces

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "blast_db_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "blast_db_blast_db_id_seq",
  },
  "file_base",
  { data_type => "varchar", is_nullable => 0, size => 120 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 80 },
  "source_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "lookup_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "update_freq",
  {
    data_type => "varchar",
    default_value => "monthly",
    is_nullable => 0,
    size => 80,
  },
  "info_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "index_seqs",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "blast_db_group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "web_interface_visible",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("blast_db_id");
__PACKAGE__->add_unique_constraint("blast_db_file_base_key", ["file_base"]);

=head1 RELATIONS

=head2 blast_db_group

Type: belongs_to

Related object: L<SGN::Schema::BlastDbGroup>

=cut

__PACKAGE__->belongs_to(
  "blast_db_group",
  "SGN::Schema::BlastDbGroup",
  { blast_db_group_id => "blast_db_group_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 unigenes_build

Type: has_many

Related object: L<SGN::Schema::UnigeneBuild>

=cut

__PACKAGE__->has_many(
  "unigenes_build",
  "SGN::Schema::UnigeneBuild",
  { "foreign.blast_db_id" => "self.blast_db_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


 __PACKAGE__->has_many(
     "blast_db_blast_db_groups",
     "SGN::Schema::BlastDbBlastDbGroup",
     { "foreign.blast_db_id"=> "self.blast_db_id" },
     { cascade_copy => 0, cascade_delete => 0},
     );

 __PACKAGE__->many_to_many(
     "blast_db_groups", "blast_db_blast_db_groups" => "blast_db_group"
     );

# Created by DBIx::Class::Schema::Loader v0.07002 @ 2012-03-03 12:32:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CtJt3leN5YsnLZmy0I1YFw


# You can replace this text with custom content, and it will be preserved on regeneration
1;

=head1 FILE RELATED METHODS

=head2 file_modtime

  Desc: get the earliest unix modification time of the database files
  Args: none
  Ret : unix modification time of the database files, or nothing if does not exist
  Side Effects:
  Example:

=cut

sub file_modtime {
  my $self = shift;
  
  if (! ($self->_fileset) ) {
      print STDERR "NO FILESET AVAILABLE... CRASHING!\n";
      return undef;
  }
  return $self->_fileset->file_modtime;
}

=head2 format_time

  Usage: my $time = $db->format_time;
  Desc : get the format time of these db files
  Ret  : the value time() would have returned when
         this database was last formatted, or undef
         if that could not be determined (like if the
         files aren't there)
  Args : none
  Side Effects: runs 'fastacmd' to extract the formatting
                time from the database files

  NOTE:  This function assumes that the computer that
         last formatted this database had the same time zone
         set as the computer we are running on.

=cut

sub format_time {
  my ($self) = @_;
  return unless $self->_fileset;
  return $self->_fileset->format_time;
}



=head2 full_file_basename

    Deprecated. Use $c->{blast_db_path} and the file_base function
  Desc:
  Args: none
  Ret : full path to the blast database file basename,
  Side Effects: none
  Example:

     my $basename = $db->full_file_basename;
     #returns '/data/shared/blast/databases/genbank/nr'

=cut

 sub full_file_basename {
   my $self = shift;

   return scalar File::Spec->catfile( $self->dbpath,
 				     $self->file_base,
 				   );

 }

=head2 list_files

  Usage: my @files = $db->list_files;
  Desc : get the list of files that belong to this blast database
  Ret  : list of full paths to all files belonging to this blast database,
  Args : none
  Side Effects: looks in the filesystem

=cut

sub list_files {
  my $self = shift;
  return unless $self->_fileset;
  $self->_fileset->list_files();
}

=head2 files_are_complete

  Usage: print "complete!" if $db->files_are_complete;
  Desc : tell whether this blast db has a complete set of files on disk
  Ret  : true if the set of files on disk looks complete,
         false if not
  Args : none
  Side Effects: lists files on disk

=cut

sub files_are_complete {
  my ($self) = @_;
  return unless $self->_fileset;
  return $self->_fileset->files_are_complete;
}

=head2 is_split

  Usage: print "that thing is split, yo" if $db->is_split;
  Desc : determine whether this database is in multiple parts
  Ret  : true if this database has been split into multiple
         files by formatdb (e.g. nr.00.pin, nr.01.pin, etc.)
  Args : none
  Side Effects: looks in filesystem

=cut

sub is_split {
  my ($self) = @_;
  return unless $self->_fileset;
  return $self->_fileset->is_split;
}

=head2 is_indexed

  Usage: $bdb->is_indexed
  Desc : checks whether this blast db is indexed on disk to support
         individual sequence retrieval.  note that this is different
         from index_seqs(), which is the flag of whether this db
         _should_ be indexed.
  Args : none
  Ret  : false if not on disk or not indexed, true if indexed

=cut

sub is_indexed {
  my ( $self ) = @_;
  return unless $self->_fileset;
  return $self->_fileset->files_are_complete && $self->_fileset->indexed_seqs;
}


=head2 sequences_count

  Desc: get the number of sequences in this blast database
  Args: none
  Ret : number of distinct sequences in this blast database, or undef
        if it could not be determined due to some error or other
  Side Effects: runs 'fastacmd' to get stats on the blast database file

=cut

sub sequences_count {
  my $self = shift;
  return unless $self->_fileset;
  return $self->_fileset->sequences_count;
}

=head2 is_contaminant_for

  This method doesn't work yet.

  Usage: my $is_contam = $bdb->is_contaminant_for($lib);
  Desc : return whether this BlastDB contains sequences
         from something that would be considered a contaminant
         in the given CXGN::Genomic::Library
  Ret  : 1 or 0
  Args : a CXGN::Genomic::Library object

=cut

#__PACKAGE__->has_many( _lib_annots => 'CXGN::Genomic::LibraryAnnotationDB' );
sub is_contaminant_for {
  my ($this,$lib) = @_;

  #return true if any arguments are true
  return any( map { $_->is_contaminant && $_->library_id == $lib } $this->_lib_annots);
}

=head2 needs_update

  Usage: print "you should update ".$db->title if $db->needs_update;
  Desc : check whether this blast DB needs to be updated
  Ret  : true if this database's files need an update or are missing,
         false otherwise
  Args : none
  Side Effects: runs format_time(), which runs `fastacmd`

=cut

sub needs_update {
  my ($self) = @_;

  #it of course needs an update if it is not complete
  return 1 unless $self->files_are_complete;

  my $modtime = $self->format_time();

  #if no modtime, files must not even be there
  return 1 unless $modtime;

  #manually updated DBs never _need_ updates if their
  #files are there
  return 0 if $self->update_freq eq 'manual';

  #also need update if it is set to be indexed but is not indexed
  return 1 if $self->index_seqs && ! $self->is_indexed;

  #figure out the maximum number of seconds we'll tolerate
  #the files being out of date
  my $max_time_offset = 60 * 60 * 24 * do { #figure out number of days
    if(    $self->update_freq eq 'daily'   ) {   1   }
    elsif( $self->update_freq eq 'weekly'  ) {   7   }
    elsif( $self->update_freq eq 'monthly' ) {   31  }
    else {
      confess "invalid update_freq ".$self->update_freq;
    }
  };

  #subtract from modtime and make a decision
  return time-$modtime > $max_time_offset ? 1 : 0;
}


=head2 check_format_permissions

  Usage: $bdb->check_format_from_file() or die "cannot format!\n";
  Desc : check directory existence and file permissions to see if a
         format_from_file() is likely to succeed.  This is useful,
         for example, when you have a script that downloads some
         remote database and you'd like to check first whether
         we even have permissions to format before you take the
         time to download something.
  Args : none
  Ret  : nothing if everything looks good,
         otherwise a string error message summarizing the reason
         for failure
  Side Effects: reads from filesystem, may stat some files

=cut

sub check_format_permissions {
  my ($self,$ffbn) = @_;
  croak "ffbn arg is no longer supported, maybe you should just use a new Bio::BLAST::Database object" if $ffbn;
  return unless $self->_fileset('write');
  return $self->_fileset('write')->check_format_permissions;
}

=head2 format_from_file

  Usage: $db->format_from_file('mysequences.seq');
  Desc : format this blast database from the given source file,
         into its proper place on disk, overwriting the files already
         present
  Ret  : nothing meaningful
  Args : filename containing sequences,
  Side Effects: runs 'formatdb' to format the given sequences,
                dies on failure

=cut

sub format_from_file {
  my ($self,$seqfile,$ffbn) = @_;
  $ffbn and croak "ffbn arg no longer supported.  maybe you should make a new Bio::BLAST::Database object";

  $self->_fileset('write')
      ->format_from_file( seqfile => $seqfile, indexed_seqs => $self->index_seqs, title => $self->title );
}

=head2 to_fasta

  Usage: my $fasta_fh = $bdb->to_fasta;
  Desc : get the contents of this blast database in FASTA format
  Ret  : an IO::Pipe filehandle, or nothing if it could not be opened
  Args : none
  Side Effects: runs 'fastacmd' in a forked process, cleaning up its output,
                and passing it to you

=cut

sub to_fasta {
  my ($self) = @_;
  return unless $self->_fileset;
  return $self->_fileset->to_fasta;
}

=head2 get_sequence

  Usage: my $seq = $bdb->get_sequence('LE_HBa0001A02');
  Desc : get a particular sequence from this db
  Args : sequence name to retrieve
  Ret  : Bio::PrimarySeqI object, or nothing if not found or
         if db does not exist
  Side Effects: dies on error, like if this db is not indexed

=cut

sub get_sequence {
    my ($self, $seqname) = @_;
    return unless $self->_fileset;
    return $self->_fileset->get_sequence($seqname);
}

=head2 dbpath

  Usage: CXGN::BlastDB->dbpath('/data/cluster/blast/databases');
  Desc : class method to get/set the location where all blast database
         files are expected to be found.  Defaults to the value of the
         CXGN configuration variable 'blast_db_path'.
  Ret  : the current base path
  Args : (optional) new base path
  Side Effects: gets/sets a piece of CLASS-WIDE data

=cut
__PACKAGE__->mk_classdata( dbpath => CXGN::BlastDB::Config->load->{'blast_db_path'} );

#mk_classdata is from Class::Data::Inheritable.  good little module,
#you should look at it
#__PACKAGE__->mk_classdata( dbpath => CXGN::BlastDB::Config->load->{'blast_db_path'} );

=head2 identifier_url

  Usage: my $url = $db->identifier_url('some ident from this bdb');
  Desc : get a URL to look up more information on this identifier.
         first tries to make a URL using the lookup_url column in the
         sgn.blast_db table, then tries to use identifier_url() from
         L<CXGN::Tools::Identifiers>
  Args : the identifier to lookup, assumed
         to be from this blast db
  Ret : a URL, or undef if none could be found
  Side Effects: Example:

=cut

sub identifier_url {
  my ($self,$ident) = @_;
  $ident or croak 'must pass an identifier to link';

  return $self->lookup_url
    ? sprintf($self->lookup_url,$ident)
      : do { require CXGN::Tools::Identifiers; CXGN::Tools::Identifiers::identifier_url($ident) };
}



sub files_exist { 
    my $self = shift;
    if ($self->_fileset) { 
	return 1;
    }
    else { 
	return 0;
    }
}


# accessor that holds our encapsulated Bio::BLAST::Database
#memoize '_fileset',
#  NORMALIZER => sub { #< need to take the full_file_basename (really the dbpath) into account for the memoization
#    my $s = shift; join ',',$s,@_,$s->full_file_basename
#  };

=head2 files_exist()

 Usage:        $db->files_exist()
 Desc:         returns true if files actually exist in the filesystem
 Ret:          boolean
 Args:         none
 Side Effects: 
 Example:

=cut



sub _fileset {
  my ($self,$write) = @_;
  my $ffbn = $self->full_file_basename;
  my $db =  Bio::BLAST::Database->open( full_file_basename => $ffbn,
				       type => $self->type,
                                       ($write ? ( write => 1,
						   create_dirs => 1,
                                                 )
                                        :        (),
                                       )
                                     );

  if (!defined($db)) { 
      return undef;
  }
  return $db;
}
