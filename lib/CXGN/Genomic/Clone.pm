package CXGN::Genomic::Clone;
use strict;
use English;
use Carp;
use File::Glob ':glob';

use Memoize;

use Bio::PrimarySeq;
use Bio::Restriction::Analysis;

use CXGN::CDBI::SGNPeople::BacStatus;
use CXGN::DB::Connection;
use CXGN::Genomic::CloneIdentifiers qw/assemble_clone_ident parse_clone_ident/;
use CXGN::Metadata;

use CXGN::People::BACStatusLog;

use CXGN::Tools::Text qw/parse_pg_arraystr/;
use CXGN::Tools::List qw/max flatten collate/;
use CXGN::Tools::Identifiers qw/ link_identifier /;

=head1 NAME

    CXGN::Genomic::Clone - genomic.clone object abstraction,
                           based on L<Class::DBI>

=head1 DESCRIPTION

An object representing a clone in the Genomic schema, corresponding
to a row in the genomic.clone table.  This object is mostly a
one-stop-shop for anything you might need to know about a BAC.

=head1 SYNOPSIS

  my $clone = CXGN::Genomic::Clone->retrieve_from_clone_name('LE_HBa0003A12')
    or die "No clone found with name LE_HBa0003A12.\n";

  #now print out the clone's full sequence in FASTA format,
  #assuming it has one
  print '>',$clone->clone_name,"\n",$clone->seq,"\n";

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.clone');

=head1 DATA FIELDS

  These can all be accessed as: $object->fieldname()

  Primary Keys:
      clone_id

  Columns:
      clone_id
      library_id
      clone_type_id
      platenum
      wellrow
      wellcol
      bad_clone
      estimated_length

=cut

our @column_names =
    qw/
      clone_id
      library_id
      clone_type_id
      platenum
      wellrow
      wellcol
      bad_clone
      estimated_length
      /;

__PACKAGE__->columns( Primary => 'clone_id' );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->SUPER::sequence( __PACKAGE__->base_schema('genomic').'.clone_clone_id_seq' );

=head1 CLASS METHODS

=head2 retrieve

  Usage: my $clone = CXGN::Genomic::Clone->retrieve(342);
  Desc : retrieve a clone object using the clone_id
  Ret  : the new object, or undef if not found
  Args : the numeric clone_id of the clone you're looking for
  Side Effects: looks up the clone in the database

=cut

#retrieve() is defined by Class::DBI

=head2 retrieve_from_clone_name

  Usage: my $clone = retrieve_from_clone_name($name);
  Desc : retrieve a clone object from its name
  Ret  : a clone object, or undef if no clone objects matched
  Args : any clone name recognized by CXGN::Genomic::CloneIdentifiers
  Side Effects: none
  Example: see CXGN::Genomic::Clone::clone_id_from_clone_name.

=cut

sub retrieve_from_clone_name {
    my ($class,$name) = @_;
    return unless $name;
    my $parsed_name = parse_clone_ident( $name )
      or return;
    my $class_dbi_object = $class->retrieve_from_parsed_name($parsed_name)
      or return;
    return $class_dbi_object;
}

=head2 retrieve_from_parsed_name

  Usage: my $clone = retrieve_from_parsed_name($parsed_name);
  Desc : retrieve a clone using the information in a hash ref of the
         kind returned by
         CXGN::Genomic::CloneIdentifiers::parse_clone_ident()
  Ret  : a clone object, or undef if no clone objects matched
  Args : a hash ref
  Side Effects: none
  Example:

  Uses search_by_libname_and_coords internally.

=cut

sub retrieve_from_parsed_name {
  my $class = shift;
  my $parsed = shift;

  ref $parsed eq 'HASH'
    or croak 'retrieve_from_parsed_name() takes a hashref argument';

  my @matching_clones =
    $class->search_by_libname_and_coords(@{$parsed}{qw/lib plate row col/});

  @matching_clones == 1 or return undef;

  return $matching_clones[0];
}

=head2 retrieve_from_genbank_accession

  Usage: my $clone = CXGN::Genomic::Clone->retrieve_from_genbank_accession('AC123456.1');
  Desc : look up a clone by its genbank accession
  Args : genbank accession string
  Ret  : a clone object, or undef if not found
  Side Effects: may establish a new database connection

=cut

sub retrieve_from_genbank_accession {
  my ($package,$acc) = @_;
  $acc or croak "must provide an accession";

  my ($clone_id) = do {
    if($acc =~ /\.\d+$/) {
      #versioned accession
      $package->db_Main->selectrow_array(<<EOQ,undef,$acc);
select clone_id
from dbxref dbx
join feature_dbxref fdx using(dbxref_id)
join clone_feature using(feature_id)
where dbx.accession = ?
EOQ
    } else {
      #unversioned accession
      $package->db_Main->selectrow_array(<<EOQ,undef,$acc.'\.\d+');
select clone_id
from dbxref dbx
join feature_dbxref fdx using(dbxref_id)
join clone_feature using(feature_id)
where dbx.accession ~ ?
EOQ
    }
  };

  return unless $clone_id;

  return $package->retrieve($clone_id);
}


=head2 search_by_libname_and_coords

  Usage: my @clones = search_by_libname_and_coords($lib_shortname,
                                                   $platenum,
                                                   $row, $col)
  Desc : find the clone(s) with the given library shortname, plate number, row,
         and column
  Ret  : array of matching clones.  This array should probably always contain
         just one object.
  Args : library shortname, plate number, row letter, column number
  Side Effects: none
  Example:

=cut

my $genomic = 'genomic';
__PACKAGE__->set_sql(by_libname_and_coords => <<EOSQL);
SELECT __ESSENTIAL__
FROM __TABLE__
JOIN $genomic.library as lib
  USING(library_id)
WHERE       lib.shortname = ?
  AND __TABLE__.platenum  = ?
  AND __TABLE__.wellrow   = ?
  AND __TABLE__.wellcol   = ?
EOSQL

=head1 OBJECT METHODS

These methods are used to access information about a specific clone
object.

=cut


__PACKAGE__->has_a( library_id    => 'CXGN::Genomic::Library'     );
__PACKAGE__->has_a( clone_type_id => 'CXGN::Genomic::CloneType'   );

__PACKAGE__->has_many( chromat_objects => 'CXGN::Genomic::Chromat');

=head2 chromat_objects

  Usage: my @chromats = $clone->chromat_objects
  Desc : get the chromatogram objects associated with this clone
  Args : none
  Ret  : a possibly empty list of chromatogram objects associated with this clone

=head2 clone_name_mysql

  Args:	SQL constructs for ( library name, plate number, well row, well column)
  Ret :	returns mysql expression for constructing an arizona clone name
        out of the given other mysql constructs
  Example:
        clone_name_mysql(qw/ library.shortname clone.platno clone.wellrow clone.wellcol /)
        #returns a string containing a mysql expression like
        "concat(library.shortname,lpad(clone.plateno,4,'0'),clone.wellrow,lpad(clone.wellcol,2,'0'))"

  can be used either as a class method or an object method

=cut

sub clone_name_mysql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  my ($libname,$platenum,$wellrow,$wellcol) = @_;

  #the CAST to type char is important for doing case-insensitive comparisons for searches and such
  return "CAST(CONCAT($libname,lpad($platenum,4,'0'),$wellrow,lpad($wellcol,2,'0')) as CHAR)";
}

=head2 clone_name_postgresql

  Args:	SQL constructs for ( library name, plate number, well row, well column)
  Ret :	returns postgresql expression for constructing an arizona clone name
        out of the given other mysql constructs
  Example:
        clone_name_postgresql(qw/ library.shortname clone.platno clone.wellrow
                                   clone.wellcol
                              /);
        #returns a string containing a postgresql expression like
        (library.shortname || lpad(clone.plateno,4,'0') || clone.wellrow
         || lpad(clone.wellcol,2,'0'));

  can be used either as a class method, an object method, or a regular subroutine

=cut

sub clone_name_postgresql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  my ($libname,$platenum,$wellrow,$wellcol) = @_;

  return "($libname || lpad(${platenum}::varchar(4),4,'0') || $wellrow || lpad(${wellcol}::varchar(4),2,'0'))";
}

=head2 clone_name_sql

Currently an alias for clone_name_postgresql

=cut

sub clone_name_sql {
  clone_name_postgresql(@_);
}

=head2 arizona_clone_name_mysql

Currently an alias for clone_name_mysql

=cut

sub arizona_clone_name_mysql {
  clone_name_mysql(@_);
}

=head2 arizona_clone_name_sql

Currently an alias for clone_name_sql

=cut

sub arizona_clone_name_sql {
  clone_name_sql(@_);
}

=head2 cornell_clone_name_mysql

  Args:	SQL expressions for plate number, well row, well column
  Ret :	mysql expression for constructing the old "cornell" clone name
  Example:
     cornell_clone_name_mysql(qw/clone.plateno clone.wellrow clone.wellcol/)
     #returns something like
     "concat('P',lpad(clone.plateno,3,'0'),clone.wellrow,lpad(clone.wellcol,2,'0'))"

  can be used either as a class method or an object method

=cut

sub cornell_clone_name_mysql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  my ($platenum,$wellrow,$wellcol) = @_;

  return "CAST(CONCAT('P',lpad($platenum,3,'0'),$wellrow,lpad($wellcol,2,'0')) as CHAR)";
}

=head2 cornell_clone_name_postgresql

  Args:	SQL expressions for plate number, well row, well column
  Ret :	mysql expression for constructing the old "cornell" clone name
  Example:
     cornell_clone_name_postgresql(qw/clone.plateno clone.wellrow clone.wellcol/)
     #returns something like
     "('P' || lpad(clone.plateno,3,'0') || clone.wellrow || lpad(clone.wellcol,2,'0'))"

  can be used either as a class method or an object method or a regular subroutine

=cut

sub cornell_clone_name_postgresql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  my ($platenum,$wellrow,$wellcol) = @_;

  return "('P' || lpad($platenum,3,'0') || $wellrow || lpad($wellcol,2,'0'))";
}

=head2 cornell_clone_name_sql

  Alias for cornell_clone_name_mysql()

=cut

sub cornell_clone_name_sql {
  cornell_clone_name_postgresql(@_);
}

=head2 clone_name

  Desc: get this clone's external identifier name
  Args: none
  Ret : string containing this clones complete external identifier,
        like 'LE_HBa0022A04'

=cut

sub clone_name {
  my $this = shift;

  my $lib = $this->library_object;
  return assemble_clone_ident(agi_bac =>
			      { lib   => $lib->shortname,
				plate => $this->platenum,
				row   => $this->wellrow,
				col   => $this->wellcol,
			      },
			     );
}

=head2 chromosome_num

  Usage: my $chrnum = $clone->chromosome_num;
  Ret  : the chromosome number (1..12) this bac
         is thought to be on, or 'unmapped' if
         it could not be mapped, or undef
         if unknown
  Args : none

=cut


sub _metadata {
  our $metadata ||= CXGN::Metadata->new(); #make a metadata object if we need one
}
sub _bac_status_log {
  our $bac_status_log ||= CXGN::People::BACStatusLog->new( CXGN::DB::Connection->new() ); # bac ... status ... object
}
sub chromosome_num {
  my $self = shift;
  my $bac_project_id = _metadata()->get_project_associated_with_bac($self->clone_id)
    or return;

  #get the name of the project
  my ($name) = $self->db_Main->selectrow_array('select name from sgn_people.sp_project where sp_project_id = ?',undef,$bac_project_id);
  my ($chr_num) = $name =~ /(\d+)/;
  if($chr_num) {
    $chr_num >= 1 && $chr_num <= 12
      or die "Invalid chromosome number '$bac_project_id' for clone ID ".$self->clone_id;
    return $chr_num;
  } elsif( $name =~ /\bunmapped\b/i ) {
    return 'unmapped';
  } else {
    die "can't parse project name '$name' for clone ID ".$self->clone_id;
  }

  return $chr_num;
}


=head2 il_mapping_project_id

  Usage: my $pid = $clone->il_mapping_project_id
  Desc : get/set the project id this bac is assigned to for IL mapping
  Args : (optional) new project id to set,
         person_id of the person that is setting it
  Ret  : current project id, or undef if none
  Side Effects: database queries
  Example:
     #set a new il project
     $clone->il_mapping_project_id(2,290);
     #unset this clone's il project
     $clone->il_mapping_project_id(undef,290);

=cut

sub il_mapping_project_id {
  my ($self,$id,$person) = @_;
  $id = [$id] if $person;
  my $v = $self->_log_get_set($id,$person,'sgn_people.sp_project_il_mapping_clone_log',['sp_project_id']);
  return $v->[0];
}


=head2 il_mapping_data

  Usage: my $pid = $clone->il_mapping_data
  Desc : get/set the phenome.genotype_region.genotype_region_id of the IL
         bin where this BAC has been mapped
  Args : (optional) hashref of new data to set, with
                    each element optional, as 
                    { chr => chromosome number,
                      bin_id => genotype_region_id number of IL bin this BAC mapped to,
                      notes => free-text notes about the mapping experiment,
                    }
         (optional) person_id of the person that is setting it
  Ret  : hashref in same format as the hashref in optional arg
  Side Effects: database queries
  Example:
     #set a new il bin
     $clone->il_mapping_bin_id({bin_id =>2},290);
     #unset this clone's il bin ID
     $clone->il_mapping_bin_id({bin_id => undef},290);

=cut

sub il_mapping_data {
  my ($self,$data,$person) = @_;

  #mappings back and forth between keys in the argument hash and
  #database columns
  my @fieldlist = qw/ genotype_region_id  chromosome  notes /;
  my @keyslist  = qw/ bin_id              chr         notes /;

  my $v;
  if( $data ) {
    my %newdata;
    unless( @fieldlist == keys %$data ) { #< load the current values from the DB unless we're setting all of them
      %newdata = collate(\@keyslist, $self->_log_get_set(undef,undef,'sgn_people.clone_il_mapping_bin_log',\@fieldlist));
    }
    $newdata{$_} = $data->{$_} foreach keys %$data;
    $v = $self->_log_get_set([@newdata{@keyslist}],$person,'sgn_people.clone_il_mapping_bin_log',\@fieldlist);
  } else {
    $v = $self->_log_get_set(undef,undef,'sgn_people.clone_il_mapping_bin_log',\@fieldlist);
  }

  return {collate(\@keyslist,$v)};
}

=head2 il_mapping_bin_name

  Usage: my $bin_name = $clone->il_mapping_bin_name
  Desc : same as above, but gets the string IL bin name
  Args : none
  Ret  : string bin name, or undef if not set
  Side Effects: none

=cut

sub il_mapping_bin_name {
  my ($self) = @_;

  my $id = $self->il_mapping_data->{bin_id}
    or return;

  my ($name) = $self->db_Main->selectrow_array(<<EOQ,undef,$id);
select name from phenome.genotype_region where genotype_region_id=?
EOQ
  return $name;
}


=head2 verification_flags

  Usage: my %v = $clone->verification_flags
  Desc : get/set the verification flags for this bac, which is a set
         of booleans that tell whether this BAC has been double-checked
         in certain ways
  Args : (optional) hash-style list or hashref of flags to set, in the same format as
         returned by this method, with one additional item: person => a
  Ret  : hashref as:
         {  int_read => true if this bac has been verified with a new internal read,
            bac_end  => true if this bac has been verified with bac end reseq,
         }
         TODO: clarify the above
  Side Effects: if arguments are passed, updates things in the database
  Example:

=cut

sub verification_flags {
#  use Data::Dumper;
#  warn "verification_flags got ".Dumper(\@_);

  my $self = shift;
  my $args = @_ > 1 ? {@_} : shift;



  my %currvals;
  @currvals{'int_read','bac_end'} =
    @{$self->_log_get_set(undef,undef,'sgn_people.clone_verification_log',['ver_int_read','ver_bac_end'])};

  if( $args ) {
    my $person = $args->{person} or croak "must provide a 'person' id or object to verification_flags()";
    $person = $person->get_sp_person_id if ref $person;
    $person+0 eq $person or croak "provided person ID must be numeric";

    foreach my $argname (qw/int_read bac_end/) {
      if( exists $args->{$argname} ) {
	$currvals{$argname} = $args->{$argname};
      }
    }

    @currvals{'int_read','bac_end'} =
      @{$self->_log_get_set( [map {$_ ? 'true' : 'false'} @currvals{'int_read','bac_end'}],
			     $person,
			     'sgn_people.clone_verification_log',
			     ['ver_int_read','ver_bac_end']
			   )
      };
  }

#  warn "verification flags returning ".Dumper(\%currvals);

  return \%currvals;
}


sub _log_get_set {
  my ($self,$vals,$person,$table,$fields) = @_;

  #use Data::Dumper;
  #warn "log_get_set\nfields=".Dumper($fields)."\nvals=".Dumper($vals);

  $vals && ref $vals && @$vals && ! defined $person
    and croak 'must provide both a value set and a person id';

  my $fields_str   = join ',', @$fields;
  my $bindvals_str = join ',', map '?', @$fields;

  if($vals && @$vals && defined $person) {
    #set others obsolete
    $self->db_Main->do(<<EOQ,undef,$self->clone_id);
update $table
set is_current = false
where clone_id = ?
EOQ
    if(@$vals) {
      #insert a new one
      $self->db_Main->do(<<EOQ,undef,@$vals,$person,$self->clone_id);
insert into $table
($fields_str,sp_person_id,clone_id)
values ($bindvals_str,?,?)
EOQ
    }
  }

  #now select and return the current value
  my @retvals = $self->db_Main->selectrow_array(<<EOQ,undef,$self->clone_id);
select $fields_str
from $table
where is_current = true
  and clone_id = ?
EOQ
  return \@retvals;
}


=head2 reg_info_hashref

  Usage: my $reginfo = $clone->reg_info_hashref
  Desc : get all of this clone's registry information (sequencing
         project, IL mapping, verification, etc) in a convenient
         hashref
  Args : none
  Ret  : hashref as:
         { il_proj    => { val => an sp_project_id, disp => 'country name' },
           il_chr     => { val => a chromosome number, disp => same number or 'unmapped'},
           il_bin     => { val => a genotype_region_id, disp => 'region name' },
           il_notes   => { val => free text, disp => text truncated to 15 cols, with fulltext mouseover, disp_full => full text, no mouseover },
           seq_proj   => { val => an sp_project_id, disp => chromosome num or 'unmapped' },
           seq_status => { val => 'complete/in_progress/none', disp => same, but substituting '-' for 'none'},
           gb_status  => { val => 'none/htgs1/htgs2/htgs3/htgs4', disp => same},
           NOTE gb_status is DEPRECATED in favor of $clone->seqprops->{htgs_phase}
           ver_int_read => { val => true or false, disp => 'yes' or '-' },
           ver_bac_end => { val => true or false, disp => 'yes' or '-' },
         }

=cut

sub reg_info_hashref {
  my ($self) = @_;


  our @all_projects;
  @all_projects = @{CXGN::People::Project->new($self->db_Main)->all_projects()} unless @all_projects;

  #given a project ID, get its corresponding project country
  sub proj_country {
    #  my $c;
    my @projmap = map $_->[1], our @all_projects;
    my $id = shift();
    return unless defined $id;
    return $projmap[$id-1];
  }

  my ($seq_status,$gb_status) = _bac_status_log()->get_status($self->clone_id);

  my $il_proj_id  = $self->il_mapping_project_id;

  my $il_data  = $self->il_mapping_data;
  my $il_bin   = $il_data->{bin_id};
  my $il_chr   = $il_data->{chr};
  my $il_notes = $il_data->{notes};
  my $seq_proj_id = _metadata()->get_project_associated_with_bac($self->clone_id);
  my $chrname;

  #figure out the chromosome number of the seq_proj_id
  if($seq_proj_id) {
    ($chrname) = $self->db_Main->selectrow_array('select name from sgn_people.sp_project where sp_project_id = ?', undef, $seq_proj_id);
    $chrname =~ s/\D//g; #< remove all non-digits
    #if empty, must be unmapped
    $chrname ||= 'unmapped';
  }

  my $vflags = $self->verification_flags;

  my %clone_data =
    ( seq_proj     => { val => $seq_proj_id,              disp => $chrname || '-'                           },
      seq_status   => { val => $seq_status,               disp => $seq_status eq 'none' ? '-' : $seq_status },
      gb_status    => { val => $gb_status,                disp => $gb_status  eq 'none' ? '-' : $gb_status  },
      il_chr       => { val => $il_chr,                   disp => $il_chr || '-'                            },
      il_notes     => { val => $il_notes,                 disp => $il_notes || '-'                          },
      il_proj      => { val => $il_proj_id,               disp => proj_country($il_proj_id)  || '-'         },
      il_bin       => { val => $il_bin,                   disp => $self->il_mapping_bin_name || '-'         },
      ver_int_read => { val => $vflags->{int_read},       disp => $vflags->{int_read} ? 'yes' : '-'         },
      ver_bac_end  => { val => $vflags->{bac_end},        disp => $vflags->{bac_end}  ? 'yes' : '-'         },
    );

  $clone_data{$_}{disp} =~ s/_/ /g foreach qw/seq_status gb_status/;

#  use Data::Dumper;
#  warn Dumper(\%clone_data);

  return \%clone_data;
}



=head2 clone_name_with_chromosome

  Usage: my $name = $clone->clone_name_with_chromosome;
  Ret  : the clone name with chromosome number,
         as in 'C06HBa0002C17', or nothing
         if the chromosome number is not known
  Args : none

=cut

sub clone_name_with_chromosome {
  my ($self) = @_;
  my $chrnum = $self->chromosome_num
    or return;

  return assemble_clone_ident(agi_bac_with_chrom =>
			      { lib   => $self->library_object->shortname,
				plate => $self->platenum,
				chr   => $chrnum,
				row   => $self->wellrow,
				col   => $self->wellcol,
			      });
}

=head2 clone_name_with_chromosome_sql

  Usage: my $name_sql = CXGN::Genomic::Clone->
            clone_name_with_chromosome_sql(qw( at.project_id
                                               l.shortname
                                               c.platenum
                                               c.wellrow
                                               c.wellcol
                                              )
                                          )
  Desc : get an SQL expression that will assemble a valid clone name with chromosome
  Ret  : SQL expression that assembles a properly formed clone name with chromosome
         number from the given field names or constant values
  Args : expressions for:  chromosome num, library shortname,
           clone plate number, clone well row, clone well column
  Side Effects: none
  Example:
      CXGN::Genomic::Clone->clone_name_with_chromosome_sql('one','two','three','four','five')
      #might return something like
      # 'C'
      # || lpad(one,2,'0')
      # || (case when two = 'LE_HBa' then 'HBa'
      #          when two = 'SL_MboI' then 'SLm'
      #          when two = 'SL_EcoRI' then 'SLe'
      #     end
      #    )
      # || lpad(three,4,'0')
      # || four
      # || lpad(five,2,'0')

=cut

sub clone_name_with_chromosome_sql {
  my ($self,$chromosome_num,$shortname,$platenum,$wellrow,$wellcol) = @_;
  return <<EOSQL;
'C'
|| lpad($chromosome_num,2,'0')
|| (case when $shortname = 'LE_HBa'   then 'HBa'
         when $shortname = 'SL_MboI'  then 'SLm'
         when $shortname = 'SL_EcoRI' then 'SLe'
    end
   )
|| lpad($platenum,4,'0')
|| $wellrow
|| lpad($wellcol,2,'0')
EOSQL
}

=head2 intl_clone_name

  Usage: my $name = $clone->intl_clone_name
  Desc : get this clone's name in the NCBI/EMBL/Sanger/DDBJ style,
         which is like LE_HBa-1A1
  Args : none
  Ret  : string clone name

=cut

sub intl_clone_name {
  my ($self) = @_;

  return assemble_clone_ident(intl_clone =>
			      { lib   => $self->library_object->shortname,
				plate => $self->platenum,
				row   => $self->wellrow,
				col   => $self->wellcol,
			      });
}


=head2 arizona_clone_name

  Return this clones name in Arizona Genomic Institute format, currently
  just an alias for clone_name() above.

=cut

sub arizona_clone_name {
  shift->clone_name(@_);
}


=head2 cornell_clone_name

  Desc: get the old-style cornell clone name of this clone
  Args: none
  Ret : string containing this clone's olde Cornell Clone Name
        P0022A04
  Side Effects: might look things up in the database

=cut

sub cornell_clone_name {
    my $this = shift;
    my $lib = $this->library_object;
    return assemble_clone_ident( old_cornell =>
				 { lib   => $lib->shortname,
				   plate => $this->platenum,
				   row   => $this->wellrow,
				   col   => $this->wellcol,
				 },
			       );
}

=head2 library_object

Alias for library_id, which under L<Class::DBI> returns this clones
associated L<CXGN::Genomic::Library> object

=cut

sub library_object {
  shift->library_id(@_);
}

=head2 subclone_library_objects

  Desc: get the library object(s) of any subclone libraries made
        from this clone
  Args: none
  Ret : L<CXGN::Genomic::Library> object for the library of
        subclones of this clone, if any
  Side Effects:
  Example:

  CURRENTLY NOT IMPLEMENTED

=cut

sub subclone_library_objects {
    croak 'subclone_library_object not yet implemented';
}

=head2 clone_type_object

  Desc: get/set the clone_type object associated with this clone
  Args:
  Ret : the current clone_type object associated with this clone (a CXGN::Genomic::CloneType)
  Side Effects:
  Example:

=cut

sub clone_type_object {
    my $this = shift;
    $this->clone_type_id(@_);
}

=head2 sequencing_status

  Desc:	get the sequencing status string of this clone
  Args:	none
  Ret :	the sequencing status of this clone, or 'none' if there is none
  Side Effects:	
  Example:

=cut

sub sequencing_status {
  my $this = shift;
  my @statuses =
    CXGN::CDBI::SGNPeople::BacStatus->search(bac_id => $this->clone_id);
  return ref($statuses[0]) ? $statuses[0]->status : 'none';
}

=head2 seq

  Usage: my $seq = $clone->seq
  Desc : get this clone's full sequence
  Ret  : in list context, the list of sequence strings, or undef if none found,
         in scalar context, the last sequence string in the list
  Args : none
  Side Effects: looks things up in the database

=cut

memoize('seq');
sub seq {
  my $self = shift;
  croak 'only pass 1 arg to seq()' if @_;

  my @seqnames = $self->latest_sequence_name
    or return;

  my @seqs = map {
    #get the sequences out of the chado db
    ($self->db_Main->selectrow_array(<<EOQ,undef,$_))
SELECT residues FROM feature WHERE name = ?
EOQ
  } @seqnames;
  return @seqs if wantarray;
  return $seqs[-1];
}

=head2 seqlen

  Usage: my $len = $clone->seqlen
  Desc : get the length of this clone's full sequence, or the sum of the lengths
         of its sequences if it's unfinished
  Ret  : integer, or undef if no sequences found
  Args : none
  Side Effects: looks things up in the database

=cut

memoize('seqlen');
sub seqlen {
  my $self = shift;
  my $raw = shift;

  die "fetching raw sequence not yet implemented" if $raw;

  my $seqname = $self->latest_sequence_name
    or return;

  #FIXME: munging sequence names without using CXGN::Genomic::CloneIdentifiers
  $seqname =~ s/-\d+$//;

  my $cids = $self->_cvterm_type_ids;

  #get the sequences out of the chado db
  my ($sum) = $self->db_Main->selectrow_array(<<EOQ,undef,$self->clone_id,"$seqname%");
SELECT sum(seqlen)
FROM feature f
JOIN clone_feature USING(feature_id)
WHERE clone_id = ?
  AND name like ?
  AND f.type_id=$cids->{BAC_clone}
EOQ

  return $sum;
}

sub _clone_full_sequence_cids {
  my @v = values %{shift->_cvterm_type_ids()};
  return wantarray ? @v : join ',', @v;
}

#return hash of cvterm_ids/type_ids for some types of features
#we care about.  e.g. {BAC_clone => type_id, fosmid_clone => type_id, ... }
sub _cvterm_type_ids {
  my ($self) = @_;

  return our $_cvterm_type_ids ||= do {
    my %a = flatten $self->db_Main->selectall_arrayref(<<EOQ);
select ct.name,ct.cvterm_id
from cvterm ct
join cv using(cv_id)
where lower(cv.name) = 'sequence'
  and ct.name like '\%_clone'
EOQ
    \%a
  };
}

=head2 seqprops

  Usage: my $p = $clone->seqprops;
  Desc : get the properties set on this clone's sequence feature,
         or the longest sequence feature if multiple
  Args : (optional) sequence version you want the props for, defaults
                    to latest sequence version
  Ret  : hashref as {  propname => value, ... },
         or empty hashref

  WARNING: specifying a version does not work for sequences in fragments,
  that is, with ...-1, ...-2, ...-3 fragment numbers

=cut

sub seqprops {
  my ($self,$version) = @_;
  $version
    and $version < 1 || $version =~ /\./
    and croak "version must be a positive integer greater than 0 (you gave $version)";

  my $seqname = $version ? $self->clone_name_with_chromosome.".$version" : $self->latest_sequence_name
      or return {};

  my $cids = $self->_clone_full_sequence_cids;
  my $props = $self->db_Main->selectall_arrayref(<<EOQ,undef,$seqname,$self->clone_id);
select ct.name as n,
       fp.value as v
from clone_feature cf
join feature f using (feature_id)
join featureprop fp using(feature_id)
join cvterm ct on (ct.cvterm_id = fp.type_id)
where f.name = ?
  and cf.clone_id = ?
  and f.type_id in($cids)
EOQ

  return {} unless $props && @$props;

  return {flatten($props)};
}


=head2 latest_sequence_name

  Usage: my $name = $clone->latest_sequence_name
  Desc : look in the chado feature table for features
         with this clone's name, return the name of the one with
         the highest sequence version number
  Ret  : in scalar context, return the sequence in the DB with the
                            highest version and longest length
         in list context,   return the list of sequences in the DB with
                            the highest version, sorted in descending order
                            by sequence length.  note that for finished
                            BACs, there will only be one element.
  Args : none

=cut

sub latest_sequence_name {
  my ($self) = @_;

  my $clone_seq_types = $self->_clone_full_sequence_cids;
  my $seqs = $self->db_Main->selectall_hashref(<<EOQ,'name',undef,$self->clone_id);
SELECT name,timelastmodified
FROM clone_feature
JOIN feature f using(feature_id)
WHERE clone_id = ?
--  and f.type_id in($clone_seq_types)
EOQ

  #if error, or not in db, return nothing
  $seqs && %$seqs or return;

  #parse all the names
  $seqs->{$_}{parsed} = parse_clone_ident($_) foreach keys %$seqs;

  #sort names by version and descending sequence length
  my @names = sort {
    if( my $pa = $seqs->{$a}{parsed}
	and
	my $pb = $seqs->{$b}{parsed}
      ) {
	$pb->{version} <=> $pa->{version}
	  || $seqs->{$b}{timelastmodified} <=> $seqs->{$a}{timelastmodified}
      } else {
	0
      }
  } keys %$seqs;

  #if in array context, return all of the names of the most recent version for this bac
  if(wantarray) {
    #find the maximum version
    my $max_version = $seqs->{$names[0]}{parsed}{version};
    return grep { $seqs->{$_}{parsed}{version} == $max_version } @names;
  }
  #if in scalar context, just return the latest name
  else {
    return $names[0];
  }
}

=head2 latest_sequence_version

  Usage: my $ver = $c->latest_sequence_version
  Desc : return just the version number of the latest
         sequence for this clone
  Args : none
  Ret  : the highest sequence version present in the DB,
         or undef if none found
  Side Effects: none

=cut

sub latest_sequence_version {
  my ($self) = @_;
  my @seqs = $self->latest_sequence_name
    or return;
  my $p = parse_clone_ident(shift @seqs,'versioned_bac_seq');
  return $p->{version};
}


=head2 genbank_accession

  Usage: my $acc = $clone->genbank_accession( $chado )
  Desc : get the versioned genbank accession associated with the most
         recent SGN sequence of this clone
  Args : Bio::Chado::Schema (or other DBIx::Class::Schema) to use for lookup
  Ret  : the genbank accession,
         or undef if not found (in scalar context),
         or an empty list (in list context)
  Side Effects: looks things up in the db

=cut

memoize('genbank_accession');
sub genbank_accession {
  my ($self,$chado) = @_;
  $chado or croak "must provide a Chado schema handle as argument to genbank_accession";

  my $seqname = $self->latest_sequence_name
    or return;

  my $acc = $self->chado_feature_rs($chado)
		 ->search_related('feature_dbxrefs')
		 ->search_related('dbxref',
				  { db_id => { IN => $chado->resultset('General::Db')
					                   ->search({ name => 'DB:GenBank_Accession'},
								    { limit => 1 },
								   )
                                                           ->get_column('db_id')
							   ->as_query
					     },
				  },
				 )
		 ->get_column('accession')
		 ->first;

  return unless $acc;
  return $acc;
}


=head2 chado_feature_rs

  Usage: my $feat = $clone->chado_feature_rs->first;
  Desc : get the Bio::Chado::Schema::Sequence::Feature resultset
         object representing the L<Bio::Chado::Schema::Sequence::Feature>
         objects corresponding to this clone
  Args : Bio::Chado::Schema (or other DBIx::Class::Schema) to use for lookup
  Ret  : DBIx::Class::ResultSet object for the corresponding clone features,
         or nothing if not present
  Side Effects: none

=cut

sub chado_feature_rs {
  my ( $self, $chado ) = @_;

  my $rs = $chado->resultset('Sequence::Feature');

  # if we have no sequence name, return a resultset with a query that
  # will never return any rows
  my $seqname = $self->latest_sequence_name
      or return $rs->search(\"1 = 0");

  # otherwise, actually construct the proper query
  return $rs->search({ 'me.feature_id' =>
			 \["IN( select feature_id from genomic.clone_feature where clone_id = ?)",
		           [ dummy => $self->clone_id ],
		          ]
		     });
}

# # on-the-spot DBIC CloneFeature object.  this needs to be somewhere
# # other than just here, but for now here it is
# BEGIN {
#     package Bio::Chado::Schema::CXGN::Genomic::Clone::CloneFeature;
#     use base 'DBIx::Class';
#     __PACKAGE__->load_components("Core");
#     __PACKAGE__->table("clone_feature");
#     __PACKAGE__->add_columns(
#                              "clone_feature_id",
#                              {
#                               data_type => "integer",
#                               default_value => "nextval('clone_feature_clone_feature_id_seq'::regclass)",
#                               is_auto_increment => 1,
#                               is_nullable => 0,
#                               size => 4,
#                              },
#                              "feature_id",
#                              {
#                               data_type => "integer",
#                               default_value => undef,
#                               is_foreign_key => 1,
#                               is_nullable => 1,
#                               size => 4,
#                              },
#                              "clone_id",
#                              {
#                               data_type => "integer",
#                               default_value => undef,
#                               is_foreign_key => 1,
#                               is_nullable => 0,
#                               size => 4,
#                              },
#                             );
#     __PACKAGE__->set_primary_key("clone_feature_id");
#     __PACKAGE__->add_unique_constraint("clone_feature_clone_id_key", ["clone_id",'feature_id']);
#     __PACKAGE__->belongs_to(
#                             'feature',
#                             'Bio::Chado::Schema::Sequence::Feature',
#                             {
#                              'foreign.feature_id' => 'self.feature_id' },
#                            );

# }


=head2 in_vitro_restriction_fragment_sizes

  Usage: my @fragsets = $clone->in_vitro_restriction_fragment_sizes;
  Desc : get a list of fragment sizes for this clone, sorted in ascending order of size
  Ret  : nothing if no fragment sizes are in the db,
         otherwise returns list of one or more restriction fragment sets, each of which
         is an arrayref of the form:
           [234,'MboI',2314,2345,3425,...]
         where the first number is the fpc_fingerprint_id from
         the fpc_fingerprint table
  Args : none
  Side Effects: looks things up in the DB

=cut


sub in_vitro_restriction_fragment_sizes {
  my ($self) = @_;

  my $sgn = 'sgn';
  my $fingerprints = $self->db_Main->selectall_arrayref(<<EOQ,undef,$self->clone_id)
select  fpc_fingerprint_id
        , enzyme_name
        , array( select
                        fragment_size
                 from fpc_band b
                 where b.fpc_fingerprint_id = fp.fpc_fingerprint_id
                   and fragment_size is not null
                 order by fragment_size asc
                )
from sgn.enzymes
join fpc_fingerprint fp using(enzyme_id)
where clone_id = ?
and exists( select 1
            from fpc_band b
            where b.fpc_fingerprint_id=fp.fpc_fingerprint_id
              and fragment_size is not null
          )
EOQ
    or return;

  #use Data::Dumper;
  #die Dumper $fingerprints;

  #parse the postgres array strings, replacing the returned rows with
  #the format we're supposed to return
  foreach my $fp (@$fingerprints) {
    unless( ref $fp->[2]  eq 'ARRAY' ) {
      my $ar = parse_pg_arraystr($fp->[2]);
      unshift @$ar,$fp->[0],$fp->[1];
      $fp=$ar;
    } else {
      $fp = [flatten $fp];
    }
  }

  return @$fingerprints;
}

=head2 in_silico_restriction_fragment_sizes

  Usage: my $frags = $clone->in_silico_restriction_fragment_sizes;
  Desc : get an arrayref of in-silico digestion fragment sizes when
         this clone's sequence is digested with the given restriction
         enzyme
  Ret  : an arrayref of fragment sizes, or nothing if clone is unfinished
  Args : name of restriction enzyme to use for the in-silico digest
  Side Effects: none

=cut

sub in_silico_restriction_fragment_sizes {
  my ($self,$enzyme) = @_;
  $enzyme or croak "must provide a restriction enzyme name to in_silico_restriction_fragment_sizes()";

  my ($seq,$unfinished) = $self->seq;
  return if !$seq || $unfinished;

  #ligate the seq back into its vector, so it will be more comparable
  #with in vitro restriction data
#   my ($vecseq,$lig1,$lig2) = $self->db_Main->selectrow_array(<<EOSQL,undef,$self->library_object->vector);
# select seq, vector_ligation_1, vector_ligation_2
# from sgn.cloning_vector v
# where name = ?
# EOSQL

  $seq = Bio::PrimarySeq->new( -seq => $seq,
			       -primary_id => $self->clone_name,
			     );

  my $ra = Bio::Restriction::Analysis->new( -seq => $seq );
  my @frags = $ra->fragments($enzyme)
    or croak "could not cut with enzyme '$enzyme'";
  return [sort {$a <=> $b} map {length $_} @frags];
}


=head1 AUTHOR

Robert Buels

=cut

####
1; # do not remove
####
