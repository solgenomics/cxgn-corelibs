package CXGN::MOBY::XML::Generator;
use strict;

=head1 NAME

CXGN::MOBY::XML::Generator - subclass of L<XML::Generator> with a couple of
  enhancements for generating MOBY XML

=head1 DESCRIPTION

This is just an XML::Generator class with one extra method and with its
namespace hardcoded to the MOBY namespace.

=head1 SYNOPSIS

  #somewhere in a MOBY service handler....

  my $x = CXGN::MOBY::XML::Generator->new;

  my $xml =
    $x->NCBI_Blast_Database( $x->article('String', 'title',    $_->db_title),
			     $x->article('String', 'idNumber', $_->blast_db_id),
			     $x->article('String', 'proteinOrNucleotide',
					 $_->blast_program eq 'blastx' ? 'protein'  :
					 'nucleotide',
					),
			     $x->article('String','fileBasename',$_->file_basename),
			     $x->article('Integer','numSequences',$_->sequences_count),
			     $x->article('Integer','unixTimestamp',$_->file_modtime),
			     $x->article('String','comment',
					 'source url: '
					 .$_->source_url
					 .' lookup identifiers at: '
					 .$_->lookup_url
					 .'&lt;identifier&gt;'
					),
			   )
   );


$MOBY_RESPONSE = simpleResponse($xml, 'Available_DBs', $qID);
  return responseHeader . $MOBY_RESPONSE . responseFooter;

=head1 BASE CLASS

L<XML::Generator>

=head1 ADDITIONAL METHODS

=cut

BEGIN {
    require XML::Generator;
    if( $XML::Generator::VERSION >= 1.01 ) {
	import XML::Generator;
    } else {
	import XML::Generator ':noimport';
    }
}
use base qw/XML::Generator/;

our $moby_ns_uri = 'http://www.biomoby.org/moby-s';

#same as super new, except put it in the MOBY namespace
sub new {
  my $class = shift;
  my @args = @_;
  return $class->SUPER::new(namespace   => [moby => $moby_ns_uri],
			    conformance => 'strict',
			    escape      => 'always,apos',
#			    qualifiedAttributes => 1,
			    @args,
			   );
}

#keep XML::Generator's import() from doing all kinds of crap
#to the namespace of users of THIS module
sub import {
}

=head2 object

  Usage: my $xml = $mobygen->object('Integer',{id=>1234,namespace='bogus'},492387543393);
  Desc : make XML for a MOBY object (or subclass thereof)
  Ret  : string of xml
  Args : object type, { attributes hash }, (optional) object contents
  Side Effects: none

  Ensures that your object has moby::id and moby::namespace attributes.

=cut

sub object {
  my $this = shift;
  my $type = shift;

  my @args = @_;

  if(ref $args[0] eq 'HASH') {
    $args[0]->{id} ||= '';
    $args[0]->{namespace} ||= '';
  } else {
    unshift @args,{ namespace=>'',id=>''};
  }

  return $this->$type(@args);
}

=head2 article

  Desc: shortcut method to make an XML tag with the
        'articleName' attribute set, which is required of all
        MOBY objects, or at least it is at the time of this
        writing
  Args: (type name, article name, article value)
  Ret : generated XML for the MOBY object, with the specified
        article name
  Side Effects: none
  Example:

    my $article_xml = $x->article('String','database_name','NCBI Non-redundant stuff');
    my $article_xml2 = $x->article('Object','db_id', { namespace=> 'NCBI_gi',
                                                       id => 'gi|30749851|pdb|1O9J|A',
                                                     }
                                  );

   print $article_xml;
   #prints
   <moby:String articleName="database_name">NCBI Non-redundant stuff</moby:String>

   print $article_xml2;
   #prints
   <moby:Object articleName="db_id" namespace="NCBI_gi" id="gi|30749851|pdb|1O9J|A" />

=cut

sub article {
  no strict 'refs';
  my ($this,$name,$artname,$attributes,@contents) = @_;

  if(ref $attributes eq 'HASH') { #we do have attributes
    $attributes->{articleName} = $artname;
  } else { #we don't actually have attributes
    unshift @contents,$attributes;
    $attributes = {articleName => $artname};
  }

  return $this->object($name,$attributes, @contents);
}

=head2 parameter

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

sub parameter {
  my $this = shift;
  $this->article('Parameter',shift,$this->Value(@_));
}

sub moby_data {
  my ($this,$qid,$attributes,@contents) = @_;

  if(ref $attributes eq 'HASH') { #we do have attributes
    $attributes->{queryID} = $qid;
  } else { #we don't actually have attributes
    unshift @contents,$attributes;
    $attributes = {queryID => $qid};
  }

  if(@contents) {
    return $this->mobyData($attributes, @contents);
  } else {
    return $this->mobyData($attributes);
  }
}


=head2 Collection

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

#override Collection to wrap everything in a Simple
sub Collection {
  my $this = shift;
  my @contents = @_;

  my @attributes = (); #take any special attributes off of the passed params
  push @attributes, (shift @contents)
    while ref($contents[0]) eq 'HASH' || ref($contents[0] eq 'ARRAY');

  #now wrap all of the contents in <Simple></Simple>
  @contents = map { $this->Simple( $_ ) } @contents;

  #return the finished Collection
  return $this->SUPER::Collection( @attributes, @contents );
}

=head2 moby_document

  Usage:
  Desc :
  Ret  :
  Args : hash-style list of ( qid => response, ..., SERVICENOTES => notes)
  Side Effects: none

=cut

sub moby_document {
  my $this = shift;
  my @queries;
  my @notes = ();
  while (my($qid,$contents) = splice (@_,0,2)) {
    if($qid eq 'SERVICENOTES') {
      if(ref $contents) {
	if(@$contents) {
	  @notes = $this->serviceNotes(@$contents);
	}
      } elsif($contents) {
	@notes = $this->serviceNotes($contents);
      }
    }
    elsif( ref $contents eq 'ARRAY' ) {
      push @queries, $this->moby_data($qid,@$contents);
    } else {
      push @queries, $this->moby_data($qid,$contents);
    }
  }
  return $this->_moby_container(@notes, @queries);
}
sub _moby_container {
  my $this = shift;
  my @contents = @_;
  return $this->xmldecl( version => '1.0', encoding => 'UTF-8' ).
    $this->MOBY($this->mobyContent( {authority => 'sgn.cornell.edu'}, @contents ) );
}

=head2 provision_information

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

sub provision_information {
  my ($this,%args) = @_;

  my @return;
  if( $args{software} ) {
    push @return,
      $this->serviceSoftware({software_name    => $args{software}{name},
			      software_version => $args{software}{version},
			      software_comment => $args{software}{comment},
			     });
  }

  if( $args{database} ) {
    push @return,
      $this->serviceDatabase({database_name    => $args{database}{name},
			      database_version => $args{database}{version},
			      database_comment => $args{database}{comment},
			     });
  }

  if( $args{comment} ) {
    push @return,
      $this->serviceComment( $args{comment} );
  }

  return @return;
}

=head2 cross_reference

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

sub cross_reference { #just an alias
  shift->CrossReference(@_);
}

=head2 exception

  Usage:
  Desc :
  Ret  :
  Args : queryID, article ref ID, severity, error code, error message
  Side Effects:
  Example:

=cut

sub exception {
  my ($this,$qid,$elem,$severity,$code,$message) = @_;
  return $this->mobyException({ refElement=> $elem,
			        refQueryID=> $qid,
				severity  => $severity,
			      },
			      $this->exceptionCode($code),
			      $this->exceptionMessage($message),
			     );
}

=head2 warning

  Usage:
  Desc :
  Ret  :
  Args : queryID, article ref ID, error code, error message
  Side Effects:
  Example:

=cut

sub warning {
  my ($this,$qid,$elem,$code,$message) = @_;
  return $this->exception($qid,$elem,'warning',$code,$message);
}

=head2 error

  Usage:
  Desc :
  Ret  :
  Args : queryID, article ref ID, error code, error message
  Side Effects:
  Example:

=cut

sub error {
  my ($this,$qid,$elem,$code,$message) = @_;
  return $this->exception($qid,$elem,'error',$code,$message);
}




###
1;#do not remove
###
