# TO MAKE A NEW MOBY SERVICE
# 1.) add your service name to @servicenames below.
# 2.) make a sub of the same name below like the other ones
# 3.) test your web service with test_service.pl in this directory
# 4.) register your service with biomoby.org by editing the register.pl
#     script in this directory
#
# And yes, MOBY is extremely haphazard and is held together with spit
# and baling wire.  I guess that's the way it is. -- rob
package CXGN::MOBY::LocalServices;

#MOBY service names are traditionally long and descriptive, in CamelCase
our @servicenames = qw/
		       GetSGNUnigeneConsensusSequence
		       Echo
		       GetSGNTrimmedCloneReadSequenceByCloneReadIdentifier
		       GetAvailableBlastDBs
		      /;
# 		       PerformBLAST
# 		      /;

use strict;
use English;

use Data::Dumper;
use File::Spec;
use File::Temp qw/tempdir/;
use File::Path;

use SOAP::Lite;
use XML::DOM;

use Bio::Tools::Run::StandAloneBlast;

use MOBY::Client::OntologyServer;
use MOBY::CommonSubs qw(:all);

use CXGN::Tools::List qw/all/;

use CXGN::DB::Connection;
use CXGN::Genomic::Search::GSS;

use CXGN::MOBY::XML::Generator;

#this LocalServices thing is basically a set of functions
#that are called by the SOAP handler
use base qw/SOAP::Server::Parameters/;

my $x = CXGN::MOBY::XML::Generator->new( pretty    => 2 );

=head2 moby_iterate

  Usage: return moby_iterate $xml, sub { blah };
  Desc : automates iterating over multiple queries in an invocation
         of a MOBY service, collecting the responses and exceptions
         for each, and formulating a valid MOBY XML response
  Ret  : a valid MOBY XML response
  Args : MOBY XML, any extra arguments the handler needs, and
         a reference to the subroutine handler
  Side Effects: runs the handler for each of the MOBY invocations
                and aggregates the responses
  Example:

=cut

sub moby_iterate(@) {
  my $data = shift;
  my $handler = pop;
  my @extras = @_;

  my @responses = ();
  my @exceptions = ();

  my $inputs = complexServiceInputParser($data);
  while(my($qid,$input) = each %$inputs) {
    my($response,$exception) = $handler->($qid,$input,@extras);
    push @responses,$qid,$response;
    push @exceptions,$exception if $exception;
  }
  return $x->moby_document(@responses,SERVICENOTES=>\@exceptions)
}

sub GetAvailableBlastDBs {
  my ($caller, $data) = @_;

  my @responses;
  my @inputs =
    eval {
      genericServiceInputParser($data);
    }; if($EVAL_ERROR) {
      warn __PACKAGE__,": could not parse input XML, which was:\n$data";
      return $x->moby_document();
    };

  #parse the inputs
  foreach my $s (@inputs) {
    my ($articleType, $qID , $input) = @$s;

    unless( $articleType == SIMPLE
	    && defined($qID)
	  ) {
      warn "improper query with attributes ($articleType,$qID)";
      push @responses,( $qID, undef );
      next;
    }

    #get a list of available databases and their descriptions
    #use only blast databases that we have files for
    my @dbs = grep {$_->files_are_complete} CXGN::BlastDB->retrieve_all;
    my @dbs_xml = map { $_->to_moby_xml($x) } @dbs;

    if(@dbs && @dbs_xml) {
      push @responses, ( $qID, $x->Collection(@dbs_xml) );
    } else {
      warn 'no BLAST databases found';
      push @responses, ( $qID, undef );
    }
  }

  return $x->moby_document( @responses );
}


sub GetSGNUnigeneConsensusSequence {
  my ($caller, $data) = @_;

  my $MOBY_RESPONSE = '';
  my @inputs = genericServiceInputParser($data);
  foreach my $s (@inputs) {
    my $result;
    my ($articleType, $qID , $input) = @$s;

    my $unigene_id;
    unless ($input
	    && $articleType == SIMPLE
	    && (($unigene_id) = getSimpleArticleIDs('SGN-U', [$input]))
	    && $unigene_id
	   ) {
      $MOBY_RESPONSE .= simpleResponse(undef,undef,$qID);
      next;
    }

    my $seq = &get_unigene_sequence($unigene_id);
    my $len = length($seq);
    $MOBY_RESPONSE .= simpleResponse($seq ? <<EOR : undef, $seq ? 'Unigene_Seq_from_SGN-U' : undef, $qID);
  <DNASequence namespace='' id='$unigene_id' articleName='Unigene_Consensus_Sequence'>
    <Integer namespace='' id='' articleName='Length'>$len</Integer>
    <String namespace='' id='' articleName='SequenceString'>$seq</String>
  </DNASequence>
EOR
  }
  return responseHeader('sgn.cornell.edu') . $MOBY_RESPONSE . responseFooter;
}
sub get_unigene_sequence { #used in unigene fetch above
   my $dbh = CXGN::DB::Connection->new;
   my $query = "SELECT unigene.unigene_id AS unigene_id,
                unigene_consensi.seq FROM unigene, unigene_consensi
                WHERE unigene.consensi_id = unigene_consensi.consensi_id
                AND unigene_id=?";

   my $sth = $dbh->prepare($query);
   my $seq_res;

   my $unigene_id = shift;;
   $unigene_id =~ s/\r//g;
   #$unigene_id =~ s/^>.*?(\d+)$/$1/;
   $sth -> execute($unigene_id);

   if (my $row = $sth -> fetchrow_hashref()) {
      foreach my $db_field(@{$sth->{NAME}}) {
 	 if($db_field eq "seq") {
	    $seq_res = $row->{$db_field};
	 }
      }
      return $seq_res; 
   }  else {
      return 0; 
   }
}


# given a SGN genomic clone read external identifier (e.g. LE_HBa0022A24_T7_133284), return the vector-screened and trimmed sequence of that read, unless it has been flagged as contaminated or otherwise bad in our database.  in that case, nothing is returned.
sub GetSGNTrimmedCloneReadSequenceByCloneReadIdentifier {
  my ($this, $data) = @_;

  my $search = CXGN::Genomic::Search::GSS->new;
  my $query = $search->new_query;

  my $MOBY_RESPONSE = '';
  my @inputs = genericServiceInputParser($data);
  foreach my $s (@inputs) {
    $query->clear;
    my $result;
    my ($articleType, $qID , $input) = @$s;

    my $requested_clone_read_ident;
    my $gss;
    my ($cn1,$cn2,$primer,$chromat_id,$version);
    my $seq;

    #make sure we can parse and fetch everything okay.  if anything goes wrong,
    #return no data.  Why not return some kind of useful error?  Because MOBY
    #does not yet have a way to do that.
    unless ($input
	    and $articleType == SIMPLE
	    and ($requested_clone_read_ident) = getSimpleArticleIDs('SGN-CloneRead', [$input])
	    and ($cn1,$cn2,$primer,$chromat_id,$version) = split /_/,$requested_clone_read_ident
	    and  do { $query->chromat_id("=$chromat_id");
		     $query->version("=$version") if $version;
		     $result = $search->do_search($query);
		     $result->total_results == 1
		   }
	    and $gss=$result->next_result
	    and $seq = $gss->trimmed_seq
	    and 0 == grep {$_} (values %{$gss->flags})
	   ) {
      $MOBY_RESPONSE .= simpleResponse(undef,undef,$qID);
      next;
    }

    my $len = length($seq);
    my $xml = $x->article('DNASequence',
			  'TrimmedSequence',
			  {id => $requested_clone_read_ident},
			  $x->article('Integer','Length',$len),
			  $x->article('String','SequenceString',$seq)
			 );
    $MOBY_RESPONSE .= simpleResponse($xml, 'CloneReadTrimmedSequence', $qID);
  }
  return responseHeader('sgn.cornell.edu') . $MOBY_RESPONSE . responseFooter;
}


sub Echo {
  my ($caller, $data) = @_;	# $data is where the message is

  my $MOBY_RESPONSE = '';       # start an empty response message

  my @inputs = genericServiceInputParser($data) # ([SIMPLE, $queryID, $simple],...)
    or return responseHeader("sgn.cornell.edu") . $MOBY_RESPONSE . responseFooter;

  foreach (@inputs) {
    my ($articleType, $qID, $input) = @$_; # break out the individual listref members

    unless( $articleType == SIMPLE && $input) { # we only accept Simple articles
      $MOBY_RESPONSE .= simpleResponse("", "", $qID); next;
    } else {
      my $object = extractRawContent($input); # this subroutine is exported from MOBY::CommonSubs
      $MOBY_RESPONSE .= simpleResponse($object, undef, $qID);
    }
  }

  return responseHeader("sgn.cornell.edu") . $MOBY_RESPONSE . responseFooter;
}


###
1;#do not remove
###

