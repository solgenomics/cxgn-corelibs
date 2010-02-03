package CXGN::Genomic::CloneIdentifiers;
use strict;
no strict 'refs'; #using symbolic refs
use warnings;
use English;
use Carp::Clan qr/^CXGN::(Genomic|TomatoGenome)/;

use Data::Dumper;

use Bio::DB::GenBank;
use Memoize;

use CXGN::DB::Connection;
use CXGN::Genomic::Config;
use CXGN::Tools::List qw/str_in flatten collate/;

=head1 NAME

CXGN::Genomic::CloneIdentifiers - functions for parsing and generating
clone identifiers.  Supersedes L<CXGN::Genomic::CloneNameParser>.

=head1 SYNOPSIS


=head1 CONFIGURATION

Set the $Config_Class variable in this package to set which
CXGN::Config - based class is used to configure the database connection.

Example:

  $CXGN::Genomic::CloneIdentifiers::Config_Class = 'SGN::Config';


=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use base qw/Exporter/;

BEGIN {
  our @EXPORT_OK = qw(
		      guess_clone_ident_type
		      parse_clone_ident
		      assemble_clone_ident
		      clean_clone_ident
		      clone_ident_glob
		      clone_ident_regex
		     );
}
our @EXPORT_OK;


=head2 guess_clone_ident_type

  Usage: my $type = CXGN::Genomic::Clone->guess_clone_ident_type('C02HBa0011A02')
         #$type is now 'agi_bac_with_chrom'
  Desc : guess the type of clone name this is
  Ret  : one of qw(
                    old_cornell        #e.g. 'P002A02'
                    intl_clone         #e.g. LE_HBa-2A2
                    agi_bac            #e.g. 'LE_HBa0002A02'
                    agi_bac_with_chrom #e.g. 'C02HBa0002A02'
                    bac_end            #e.g. 'LE_HBa0002A02_SP6_123456',
                    versioned_bac_seq  #e.g. 'C02HBa0002A02.1'
                                       #  or 'C02HBa0120B21.2-14'
                    genbank            #a genbank accession for a bac seq
                                       #e.g. 'CT990624'
                    versioned_genbank  #a versioned genbank accession
                                       #e.g. 'CT990624.4'
                    sanger_bac         #e.g. bTH2A2
                  ),
         or undef if cannot guess it
  Args : name to guess
  Side Effects: none.  does NOT look things up in the database
  Example:

=cut

use constant NAME_TYPES => qw(
			      old_cornell
			      intl_clone
			      agi_bac
			      agi_bac_with_chrom
			      bac_end
			      versioned_bac_seq
                              versioned_bac_seq_no_chrom
			      genbank
			      versioned_genbank
			      sanger_bac
			     );

sub guess_clone_ident_type {
  my ($name) = @_;
  foreach my $type (NAME_TYPES) {
    if(my $p = "_parse_clone_ident_$type"->($name)){
      return $type;
    }
  }
  return;
}

=head2 parse_clone_ident

  Usage: my $parsed = CXGN::Genomic::Clone->
                        parse_clone_ident('C02HBa0011A02','agi_bac_with_chrom');
  Desc : parse a clone or clone sequence name into its component parts
  Ret  : a hashref of parsed information, or undef if the parse failed.
         hashref is formatted as:
         {
          lib       => shortname of the corresponding Library Object
  	  plate     => plate number,
  	  row       => row (usually a letter A-Z),
  	  col       => column number,
  	  clonetype => shortname of the corresponding CloneType object,
  	  match     => the substring in the input that contained the parsed name,

          and may also contain some of the optional keys:

          chromat_id=> id number of the CXGN::Genomic::Chromat object, if it is
                       a clone read (e.g. a bac end)
	  primer    => primer used, if the name is from a bac end (clone read)
	  version   => version number in the identifier, if any,
          chr       => chromosome number or 'unmapped' for the fake unmapped chromosome,
          fragment  => fragment number,
          end       => either 'left' or 'right', if this is a clone end
         }
  Args : name to parse, optional type of the name, if known
  Side Effects: none

=cut

sub parse_clone_ident {
  my ($name,@types) = @_;

  #can't parse a nonexistent name
  return unless $name;

  #if no type provided, try to guess, return nothing if can't guess
  unless(@types) {
    my $guess = guess_clone_ident_type($name)
      or return;
    $types[0] = $guess;
  }

  #validate the types we've been given or guessed
  foreach my $type (@types) {
    str_in($type,NAME_TYPES)
      or croak "invalid clone_ident type '$type' passed to parse_clone_ident";
  }

  #now call the proper sub-parser
  foreach my $type (@types) {
    if(my $p = "_parse_clone_ident_$type"->($name)) {
      return $p;
    }
  }
  return;
}

=head2 assemble_clone_ident

  Usage: my $name = CXGN::Genomic::Clone->
                      assemble_clone_ident(agi_bac_with_chrom =>
                      	                   { lib   => 'LE_HBa',
                      	                     plate => 2,
                      	                     row   => 'A',
                      	                     col   => 13,
                      	                     clonetype => 'bac',
                      	                     chr   => 2,
                      	                   });
         #$name is now 'C02HBa0002A13'
  Desc : the reverse of parse_clone_ident.  takes a hashref of the kind
         returned by parse_clone_ident and assembles a clone name of the
         requested type from it.  valid hash keys that are not used
         to assemble the requested name type are ignored.
  Ret  : a string containing the clone name, or undef if it could
         not be assembled from the given information
  Args : hashref of info to assemble, optional requested ident type,
         defaults to 'agi_bac'.
  Side Effects: none.  does NOT die on error.

=cut

sub assemble_clone_ident {
  my ($type,$parsed) = @_;

  #validate arguments
  ref $parsed eq 'HASH' or croak "second argument to assemble_clone_ident must be a hash ref";
  croak "second argument to assemble_clone_ident must be a valid clone_ident type must specify a type\n"
    unless $type;
  str_in($type,NAME_TYPES)
    or croak "invalid clone_ident type '$type' passed to assemble_clone_ident";

  return "_assemble_clone_ident_$type"->($parsed);
}

=head2 clean_clone_ident

  Usage: my $clean = clean_clone_ident('identifier','typename','typename',...);
  Desc : clean up a clone identifier
  Ret  : a clean identifier, or undef if it can't be cleaned
  Args : identifier, (optional) list of identifier types to allow
  Side Effects: none

=cut

sub clean_clone_ident {
  my ($ident,@ns) = @_;
  unless(@ns) {
    @ns = (guess_clone_ident_type($ident));
  }

  my $parsed = parse_clone_ident($ident,@ns)
    or return;

  return assemble_clone_ident($ns[0] => $parsed)
}


=head2 clone_ident_glob

  Usage: my $globstr = clone_ident_glob($type);
  Desc : get a BSD-style glob pattern that will match
         clone identifiers of the given type, and nothing else
  Args : clone ident type name
  Ret  : a BSD glob string, or dies if there isn't one for that type
  Side Effects: dies if there isn't one for that type

=cut

sub clone_ident_glob {
  my ($type) = @_;
  str_in($type,NAME_TYPES)
    or croak "invalid clone_ident type '$type' passed to clone_ident_glob";

  my $chrnum = '{'.join(',',map{sprintf '%02d',$_}(0..12)).'}'; #< bsd glob for nums 00-12

  my %shortnames = _lookup_shortnames();
  my $shortnames = join ',',values %shortnames;

  my %globs = (  agi_bac_with_chrom => 
		 'C'.$chrnum.'{HBa,SLe,SLm,SLf}'.'[0-9][0-9][0-9][0-9][A-P][0-9][0-9]',
                 agi_bac =>
		 "{$shortnames}{[0-9][0-9][0-9],[0-9][0-9][0-9][0-9]}[A-P][0-9][0-9]",
	      );
  my $possible_fragment_num = "{,-[0-9],-[0-9][0-9]}";
  $globs{versioned_bac_seq_no_chrom}
      = $globs{agi_bac}.".{[0-9],[0-9][0-9],[0-9][0-9][0-9]}$possible_fragment_num";
  $globs{versioned_bac_seq}
      = $globs{agi_bac_with_chrom}.".{[0-9],[0-9][0-9],[0-9][0-9][0-9]}$possible_fragment_num";

  return $globs{$type} || croak "no glob defined for type '$type'";
}


=head2 clone_ident_regex

  Usage: my $quoted_regex = clone_ident_regex($type);
  Desc : get a qr// regex that will match clone identifiers
         of the given type, and nothing else.  note, however,
         that these qrs do not have ^/$ anchors at the ends.
  Args : clone ident type name
  Ret  : regex STRING, or dies if there isn't one for that type
         Note that the user must interpolate this string into a
         regex to use it for matching.
  Side Effects: dies if there isn't one for that type

=cut

sub clone_ident_regex {
  my ($type) = @_;
  str_in($type,NAME_TYPES)
    or croak "invalid clone_ident type '$type' passed to clone_ident_glob";

  my $chrnum = join '|',map{sprintf '%02d',$_}(0..12); #< regex for nums 00-12

  my %shortnames = _lookup_shortnames();
  my $shortnames = join '|',values %shortnames;

  my %re = (  agi_bac_with_chrom => 
              'C('.$chrnum.')(HBa|SLe|SLm|SLf)(\d{4})([A-P])(\d{2})',

              agi_bac =>
              '('.$shortnames.')(\d{3,4})([A-P])(\d{2})',

           );
  $re{versioned_bac_seq_no_chrom}
      = $re{agi_bac}.'\.\d+';

  $re{versioned_bac_seq}
      = $re{agi_bac_with_chrom}.'\.\d+';

  return $re{$type} || croak "no regex defined for type '$type'";
}


###### INDIVIDUAL CLONE NAME PARSERS AND ASSEMBLERS  ######
# a sub-parser should return nothing if the name it's given is not of
# its type

our $sep = '[^a-zA-Z\d\/]?';

sub _parse_clone_ident_old_cornell {
  my ($name) = @_;

  return unless $name =~ /^[Pa]
			   $sep
			   (\d{1,5})      #plate number
			   $sep
			   ([a-z]{1,2})   #row
			   (\d{1,3})      #column
			 $/ix;

  return unless ($1 && $2 && $3);

  my %clone_types = _lookup_clone_types();
  my $lib = _recognize_lib('hba');
  my $clone_type = $clone_types{$lib}
    or return;
  return { lib       => $lib,
	   plate     => $1+0,
	   row       => uc($2),
	   col       => $3+0,
	   clonetype => $clone_type,
	   match     => $MATCH,
	 };

}

sub _parse_clone_ident_intl_clone {
  my ($name) = @_;

  return
    unless $name =~ /^([a-z]{2}
		     _
		     [a-z]{2,}
                     ) #library name
		     -
		     (\d{1,3})      #plate number
		     ([a-z])   #row
		     (\d{1,2})      #column
		    $/ix;

  return unless ($1 && $2 && $3 && $4);

  my $lib = $1;
  $lib = _recognize_lib($lib) || $lib;

  my %clone_types = _lookup_clone_types();
  my $clone_type = $clone_types{$lib}
    or return;

  return { lib       => $lib,
	   plate     => $2+0,
	   row       => uc($3),
	   col       => $4+0,
	   clonetype => $clone_type,
	   match     => $MATCH,
	 };

}
sub _parse_clone_ident_agi_bac {
  my ($name) = @_;
    return
      unless $name =~ /^([A-Za-z]{0,2}
			 $sep
			 [A-Za-z]{2,}
                        ) #library name
			$sep
		       (\d{1,5})      #plate number
			$sep
			([A-Za-z]{1,2})   #row
			(\d{1,3})      #column
		       $/ox;

  #warn "matched agi_bac\n";

  return unless ($2 && $3 && $4);

  my $lib = $1;
  $lib = _recognize_lib($lib) || $lib;

  my %clone_types = _lookup_clone_types();
  my $clone_type = $clone_types{$lib}
    or return;

  return { lib       => $lib,
	   plate     => $2+0,
	   row       => uc($3),
	   col       => $4+0,
	   clonetype => $clone_type,
	   match     => $MATCH,
	 };
}
sub _parse_clone_ident_agi_bac_with_chrom {
  my ($name) = @_;

  return unless $name =~ /^(?:SGN|C)
			  (\d{1,2})           #chromo num
			  $sep                #maybe a separator
			  ([a-z]{1,})         #part of library shortname
			  $sep                #maybe a separator
			  (\d{1,5})           #plate number
			  $sep                #maybe a separator
			  ([a-z])             #row character
			  $sep                #maybe a separator
			  (\d{1,3})           #column number
			  $/ix;
  my $match = $MATCH;

  my $lib = $2; #clean up the library name if needed
  $lib = _recognize_lib($lib) || $lib;

  my %clone_types = _lookup_clone_types();

  my $clone_type = $clone_types{$lib}
    or return;

  my $h = {
	  chr       => $1+0 || 'unmapped',
	  lib       => $lib,
	  plate     => $3+0,
	  row       => uc($4),
	  col       => $5+0,
	  clonetype => $clone_type,
	  match     => $match,
	 };
  return $h;

}

# BEGIN_SKIP_FOR_PORTABLE_VALIDATION

sub _parse_clone_ident_bac_end {
  my ($name) = @_;

  my ($clone,$primer,$chromat_id,$version) = do {
    my @f = split /[^a-z\d\/]/i,$name;
    if(@f > 3) {
      (shift(@f).'_'.shift(@f),@f)
    } else {
      @f
    }
  };
  return unless $clone && $primer && defined $chromat_id;

  my $p = _parse_clone_ident_agi_bac($clone)
    or return;

  #primers, indexed by lc
  my %known_primers = _lookup_primers();
  my %primer_directions = _primer_directions();

  return if $chromat_id =~ /\D/;
  return if defined($version) && $version =~ /\D/;

  #clean the primer a bit 
  my $p_dir = $primer_directions{ lc $p->{lib} }{lc $primer};
  $primer = $known_primers{lc $primer}
    or return;

  $p->{clone_name} = _assemble_clone_ident_agi_bac( $p );
  $p->{primer} = $primer;
  $p->{chromat_id} = $chromat_id;
  $p->{match} = $name;
  $p->{version} = $version || 1;
  $p->{end} = $p_dir;
  return $p;
}

# END_SKIP_FOR_PORTABLE_VALIDATION

sub _parse_clone_ident_versioned_bac_seq {
  my ($ident) = @_;

  my ($cloneident,$version,$fragment) = $ident =~ /^(.+)\.(\d+)(?:-(\d+))?$/;
  $cloneident && $version
    or return;
  my $parsedclone = _parse_clone_ident_agi_bac_with_chrom($cloneident)
    or return;

  return if $version =~ /\D/ or $fragment && $fragment =~ /\D/;

  $parsedclone->{clone_name} = $cloneident;
  $parsedclone->{version} = $version + 0 if $version;
  $parsedclone->{fragment} = $fragment + 0 if $fragment;
  $parsedclone->{match} = $ident;

  return $parsedclone;
}
sub _parse_clone_ident_versioned_bac_seq_no_chrom {
  my ($ident) = @_;

  my ($cloneident,$version,$fragment) = $ident =~ /^(.+)\.(\d+)(?:-(\d+))?$/;
  $cloneident && $version
    or return;
  my $parsedclone = _parse_clone_ident_agi_bac($cloneident)
    or return;

  return if $version =~ /\D/ or $fragment && $fragment =~ /\D/;

  $parsedclone->{clone_name} = $cloneident;
  $parsedclone->{version} = $version + 0 if $version;
  $parsedclone->{fragment} = $fragment + 0 if $fragment;
  $parsedclone->{match} = $ident;

  return $parsedclone;
}
sub _parse_clone_ident_sanger_bac {
  my ($name) = @_;
  return
    unless $name =~ /^bT
		     ([a-z]{1,2})
		     $sep
		     (\d{1,5})      #plate number
		     $sep
		     ([a-z]{1,2})   #row
		     (\d{1,3})      #column
		     $/ix;

  return unless ($2 && $3 && $4);

  my $lib = $1;
  $lib = _recognize_lib($lib) || $lib;

  my %clone_types = _lookup_clone_types();
  my $clone_type = $clone_types{$lib}
    or return;

  return { lib       => $lib,
	   plate     => $2+0,
	   row       => uc($3),
	   col       => $4+0,
	   clonetype => $clone_type,
	   match     => $MATCH,
	 };
}


sub _recognize_lib {
  my ($libname) = @_;

  #warn "recognize $libname\n";

  my $organism;
  ($organism,$libname) = $libname =~ /^(sl|le)?$sep([a-z\d]{1,10})$/i;
  #warn "split into $organism, $libname\n";

  my %known_libs = _lookup_shortnames();
  return $known_libs{lc $libname} if $known_libs{lc $libname};


  #lowercase strings, change any erroneous numbers to the
  #letters that they would look like
  sub lc_and_no_nums {
    my $s = shift;
    my $s2 = lc($s);
    $s2 =~ tr/01/oi/;
    $s2;
  }

  # hash of known library abbreviations as abbrev => shortname
  my %known_lib_abbrevs = flatten _lookup_abbreviations();

  my $result = $known_lib_abbrevs{lc_and_no_nums($libname)};
  #warn "recognized as $result\n";
  return $result;
}

#GENBANK
sub _parse_clone_ident_genbank {
  my ($accession) = @_;
  return unless $accession =~ /^[a-z]{2}\d+$/i;
  return _gb_fetch('get_Seq_by_acc',$accession);
}
sub _parse_clone_ident_versioned_genbank {
  my ($accession) = @_;
  return unless $accession =~ /^[a-z]{2}\d+\.\d+$/i;
  return _gb_fetch('get_Seq_by_version',$accession);
}
sub _gb_fetch {
  my ($func,$accession) = @_;

  my $gb = Bio::DB::GenBank->new;
  my $seq = eval{$gb->$func($accession)}; #this dies if the acc doesn't exist
  warn $@ if $@;
  return unless $seq;

  #find the word in the description line that is our clone identifier
  foreach my $word (split /\s+/,$seq->desc) {
    if( my $p = _parse_clone_ident_agi_bac_with_chrom($word)
	|| _parse_clone_ident_agi_bac($word)
      ) {
      $p->{match} = $accession;
      return $p;
    }
  }
  return;
}
#/GENBANK

# BEGIN_SKIP_FOR_PORTABLE_VALIDATION

memoize '_dbh';
sub _dbh { CXGN::DB::Connection->new }

memoize('_lookup_shortnames', NORMALIZER => sub {time>>4}); #<memoize with a 16-second expiration time
sub _lookup_shortnames {
  return flatten  _dbh->selectall_arrayref(<<EOSQL);
select lower(shortname),shortname from genomic.library
EOSQL
}

memoize('_lookup_abbreviations', NORMALIZER => sub {time>>4}); #<memoize with a 16-second expiration time
sub _lookup_abbreviations {
  return flatten _dbh->selectall_arrayref(<<EOSQL);
select lower(ls.abbreviation),l.shortname
  from genomic.library_shortname_abbreviation ls
  join genomic.library l using(library_id)
EOSQL
}


# return list like 'SL_MboI' => 'bac', 'SL_FOS' => 'fosmid', ...
memoize('_lookup_clone_types', NORMALIZER => sub {time>>4}); #<memoize with a 16-second expiration time
sub _lookup_clone_types {
  return flatten _dbh->selectall_arrayref(<<EOSQL);
select l.shortname, lower(ct.name)
  from genomic.library l
  join genomic.clone_type ct
    using(clone_type_id)
EOSQL
}

#returns list like 'sp6' => 'SP6', 'pibr' => 'pIBR', ...
memoize('_lookup_primers', NORMALIZER => sub {time>>4}); #<memoize with a 16-second expiration time
sub _lookup_primers {
  return flatten _dbh->selectall_arrayref(<<EOSQL);
 select lower(name),name
   from genomic.sequencing_primer p
EOSQL
}

#returns list like 'sp6' => 'right', 'pibr' => 'right', ...
memoize('_primer_directions', NORMALIZER => sub {time>>4}); #<memoize with a 16-second expiration time
sub _primer_directions {
  my %pd;
  my $res = _dbh->selectall_arrayref(<<EOSQL);
 select l.shortname,p.name,'right'
   from genomic.library l
   join genomic.sequencing_primer p on ( l.right_primer_id = p.sequencing_primer_id )
union
 select l.shortname,p.name,'left'
   from genomic.library l
   join genomic.sequencing_primer p on ( l.left_primer_id = p.sequencing_primer_id )
EOSQL

  foreach my $r (@$res) {
    #warn "$r->[0] - $r->[1] = $r->[2]\n";
    $pd{lc $r->[0]}{lc $r->[1]} = $r->[2];
  }

  return %pd;
}

# END_SKIP_FOR_PORTABLE_VALIDATION

# ASSEMBLING CLONE NAMES
sub _validate_parsed {
  my ($p) = @_;

  my %shortnames = _lookup_shortnames();

  $shortnames{lc $p->{lib}} eq $p->{lib}
    or croak "library '$p->{lib}' not recognized, identifier was parsed as: ".Dumper($p);

  $p->{row} =~ /^[A-P]$/
    or croak "invalid row '$p->{row}', identifier was parsed as: ".Dumper($p);

  $p->{col} >= 1 && $p->{col} <= 24
    or croak "invalid column '$p->{col}', identifier was parsed as: ".Dumper($p);

  $p->{plate} >= 1
    or croak "invalid plate '$p->{plate}', identifier was parsed as: ".Dumper($p);

}
sub _assemble_clone_ident_old_cornell {
  my ($parsed) = @_;
  _validate_parsed($parsed);
  if($parsed->{lib} eq 'LE_HBa') {
    return 'P'.sprintf('%03d',$parsed->{plate}).$parsed->{row}.sprintf('%02d',$parsed->{col});
  } else {
    return _assemble_clone_ident_agi_bac($parsed);
  }
}
sub _assemble_clone_ident_agi_bac {
  my ($parsed) = @_;
  _validate_parsed($parsed);
  my $lclib = lc($parsed->{lib});
  my $plate_format = $lclib eq 'rhpotkey' || $lclib eq 'rh' ? '%03d' : '%04d';
  return $parsed->{lib}
    .sprintf($plate_format,$parsed->{plate})
    .$parsed->{row}
    .sprintf('%02d',$parsed->{col});
}
sub _assemble_clone_ident_intl_clone {
  my ($parsed) = @_;
  _validate_parsed($parsed);
  return
    $parsed->{lib}
    .'-'
    .($parsed->{plate}+0)
    .$parsed->{row}
    .($parsed->{col}+0)
}
sub _assemble_clone_ident_sanger_bac {
  my ($parsed) = @_;
  _validate_parsed($parsed);
  my %lib_map = ( SL_MboI => 'M',
		  SL_FOS => 'F',
		  LE_HBa => 'H',
		);
  return 'bT'
    .($lib_map{$parsed->{lib}} || confess "don't know sanger abbreviation for library $parsed->{lib}")
    .sprintf('%d',$parsed->{plate})
    .$parsed->{row}
    .sprintf('%d',$parsed->{col});
}
sub _assemble_clone_ident_agi_bac_with_chrom {
  my ($parsed) = @_;

  _validate_parsed($parsed);

  $parsed->{chr} eq 'unmapped' || ($parsed->{chr} >= 0 && $parsed->{chr} <= 12)
    or croak "invalid chromosome '$parsed->{chr}'";
  $parsed->{chr} = 0 if $parsed->{chr} eq 'unmapped';

  my $lib = $parsed->{lib};
  $lib =~ s/^LE_|^SL_//;
  $lib = substr($lib,0,3);
  my %libname_map = ( Mbo => 'SLm', Eco => 'SLe', FOS => 'SLf' );
  return
    sprintf('C%02d',$parsed->{chr})
    .($libname_map{$lib} || $lib)
    .sprintf('%04d',$parsed->{plate})
    .$parsed->{row}
    .sprintf('%02d',$parsed->{col});

}
sub _assemble_clone_ident_bac_end {
  my ($parsed) = @_;
  defined $parsed->{chromat_id} or croak 'cannot assemble bac end, no chromat id';
  $parsed->{primer} or croak 'cannot assemble bac end, no primer';
  return assemble_clone_ident('agi_bac',$parsed).'_'.$parsed->{primer}.'_'.$parsed->{chromat_id};

}
sub _assemble_clone_ident_versioned_bac_seq {
  my ($parsed) = @_;

  #this will validate it too
  my $bacname = _assemble_clone_ident_agi_bac_with_chrom($parsed);

  $parsed->{version} >= 1
    or croak "invalid version '$parsed->{version}'";

  !defined($parsed->{fragment}) || $parsed->{fragment} >= 1
    or croak "invalid fragment '$parsed->{fragment}'";

  return
    $bacname
    .".$parsed->{version}"
    .($parsed->{fragment} ? "-$parsed->{fragment}" : '');
}
sub _assemble_clone_ident_versioned_bac_seq_no_chrom {
  my ($parsed) = @_;

  #this will validate it too
  my $bacname = _assemble_clone_ident_agi_bac($parsed);

  $parsed->{version} >= 1
    or croak "invalid version '$parsed->{version}'";

  !defined($parsed->{fragment}) || $parsed->{fragment} >= 1
    or croak "invalid fragment '$parsed->{fragment}'";

  return
    $bacname
    .".$parsed->{version}"
    .($parsed->{fragment} ? "-$parsed->{fragment}" : '');
}
sub _assemble_clone_ident_genbank {
  my ($parsed) = @_;
  confess '_assemble_clone_ident_genbank not implemented';
}
sub _assemble_clone_ident_versioned_genbank {
  my ($parsed) = @_;
  confess '_assemble_clone_ident_versioned_genbank not implemented';
}
#/ASSEMBLING CLONE NAMES

###### /INDIVIDUAL CLONE NAME PARSERS AND ASSEMBLERS ######

=head1 AUTHOR(S)

Robert Buels

=cut

###
1;#do not remove
###
