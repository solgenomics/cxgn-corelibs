package CXGN::Genomic::Chromat;

=head1 NAME

    CXGN::Genomic::Chromat - genomic.chromat object,
                             based on L<Class::DBI>

=head1 DESCRIPTION

genomic.chromat catalogs the chromatograms we have for the
genomic survey sequences (GSSs) we have in the Genomic database

=head1 SYNOPSIS

none yet

=head1 METHODS

=cut

use strict;
use English;
use Carp;

use base qw/ /;
=head1 DATA FIELDS

  Primary Keys:
      chromat_id

  Columns:
      chromat_id
      clone_id
      primer
      filename
      subpath
      date
      censor_id
      read_class_id

  Sequence:
      (genomic base schema).chromat_chromat_id_seq

=cut

use base 'CXGN::CDBI::Class::DBI';
__PACKAGE__->table('genomic' . '.chromat');

our @primary_key_names =
    qw/
      chromat_id
      /;

our @column_names =
    qw/
      chromat_id
      clone_id
      primer
      filename
      subpath
      date
      censor_id
      read_class_id
      /;

__PACKAGE__->columns( Primary => @primary_key_names, );
__PACKAGE__->columns( All     => @column_names,      );
__PACKAGE__->sequence( __PACKAGE__->base_schema('genomic').'.chromat_chromat_id_seq' );

our $tablename = __PACKAGE__->table;
our @persistentfields = map {[$_]} __PACKAGE__->columns;
our $persistent_field_count = @persistentfields;
our $dbname = 'genomic';

=head2 clone_id

  Desc: L<Class::DBI> has_a relation to L<CXGN::Genomic::Clone>
  Args: (option) new clone object
  Ret : current clone object associated with this chromat
  Side Effects: none until you save this object
  Example:

=cut

__PACKAGE__->has_a( clone_id => 'CXGN::Genomic::Clone' );

=head2 clone_object

Get/set the L<CXGN::Genomic::Clone> associated with this Chromat.
Currently an alias for clone_id(), which is a L<Class::DBI> has_a
relation.

=cut

sub clone_object {
  shift->clone_id(@_);
}

=head2 read_link_html

  Desc:
  Args: relative pathname of the page to link to,
        (optional) name of variable for passing this
                   chromat's ID in the GET request
  Ret : html string containing an link to this
        chromat's clone read info page.
  Side Effects:
  Example:

  print $chromat->read_link_html('/map/physical/clone_read_info.pl',
                                 'chrid',
                                );

=cut

sub read_link_html {
  my $this = shift;
  my $linkpage = shift;
  my $chrid_name = shift || 'chrid';
  #don't print out the read already on this page here
  my $link = '<a href="'.$linkpage
    ."?$chrid_name=".$this->chromat_id
      .'">'.$this->clone_read_external_identifier
	.'</a>';
  my $gss = $this->latest_gss_object;
  my ($tag,$css) = $gss ? $gss->oneline_summary : ();
  $tag = "<b>(</b><span style=\"$css\">$tag</span><b>)</b>";
  return "$link&nbsp;&nbsp;$tag\n";
}


=head2 clone_read_external_identifier

  Desc:
  Args: none
  Ret : string containing this chromat's
        external identifier (a SGN-CloneRead)
  Side Effects: none
  Example:
    $chromat->clone_read_external_identifier
    #returns something like
    'LE_HBa00023A12_SP6_12345'

=cut

sub clone_read_external_identifier {
    my $this = shift;
    my $clone = $this->clone_object;

    croak "Cannot assemble external identifier - no Clone object associated with this chromat!"
	unless $clone;

    return $clone->arizona_clone_name.'_'.$this->primer.'_'.$this->chromat_id;
}

=head2 clone_read_external_identifier_sql

  Desc: get SQL that will make a properly-formed clone read external identifier,
        which you can use in your own queries
  Args: strings containing SQL expressions that will give:
        (library shortname, clone plate number, clone well row, clone well column,
         sequencing primer, chromat ID number)
  Ret : string containing SQL that will assemble a proper external identifier
        from those components
  Side Effects: none
  Example:

    my $identifier_sql = CXGN::Genomic::Chromat->
                         clone_read_external_identifier_sql(qw/ l.shortname
                                                                c.platenum
								c.wellrow
								c.wellcol
								chr.primer
								chr.chromat_id
							      /);
    my $query = <<EOSQL;
  SELECT $identifier_sql
  FROM genomic.chromat as chr
  JOIN genomic.clone as c
    USING(clone_id)
  JOIN genomic.library as l
    USING(library_id)
  LIMIT 10
  EOSQL

  Note: this can be called as a package method (CXGN...GSS->external...), OR
        an object method ($gss->external...)
        OR directly from this package like CXGN...GSS::external...

=cut

sub clone_read_external_identifier_sql {
  my $thing = shift;
  unless(UNIVERSAL::isa($thing,__PACKAGE__)) {
    unshift @_,$thing;
  } #can be called in any way you want

  my @clone = @_[0..3];
  my ($primer,$id) = @_[4,5];
  my $clone_ident = CXGN::Genomic::Clone::clone_name_sql(@clone);

  return "($clone_ident || '_' || $primer || '_' || $id)";
}

=head2 gss_objects

  Desc: L<Class::DBI> has_many relation to L<CXGN::Genomic::GSS>
  Args: none
  Ret : array of L<CXGN::Genomic::GSS> objects that correspond to this Chromat,
        ordered by their 'version' field
  Side Effects: none
  Example:

   my @gss = $chromat->gss_objects;

=cut

__PACKAGE__->has_many( gss_objects => 'CXGN::Genomic::GSS',
		       {order_by => 'version'},
		     );

=head2 latest_gss_object

  Desc:
  Args: none
  Ret : the most recent (sorted by version) L<CXGN::Genomic::GSS>
        object associated with this chromatogram,
        or undef if there are none
  Side Effects:
  Example:

  #this will always be true:
  ! defined($chromat->latest_gss_object) ||
    $chromat->latest_gss_object->isa('CXGN::Genomic::GSS')

=cut

sub latest_gss_object {
    my $this = shift;

    my @gss = $this->gss_objects();
    my $matches = @gss;

    return undef unless $matches >  0;

    return $gss[-1]; #return last gss
}

=head2 read_class_id

  Desc: L<Class::DBI> has_a relation to L<CXGN::Genomic::ReadClass>
  Args: (option) new readclass object
  Ret : current readclass object associated with this chromat
  Side Effects: none until you save this object
  Example:

=cut

__PACKAGE__->has_a(read_class_id => 'CXGN::Genomic::ReadClass');

=head2 read_class_object

  Alias for read_class_id() above.

  Desc:
  Args: none
  Ret : this chromatogram's associated L<CXGN::Genomic::ReadClass> object
  Side Effects:
  Example:

=cut

sub read_class_object {
  shift->read_class_id(@_);
}

=head1 AUTHOR

Robert Buels

=cut

###
1;# do not remove
###
