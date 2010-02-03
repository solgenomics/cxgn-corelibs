package CXGN::Annotation::GAMEXML::Generate;

=head1 NAME

CXGN::Annotation::GAMEXML::Generate - legacy code for generating game xml

=head1 FUNCTIONS

=cut

use strict;
use XML::DOM;


=head2 GenerateXML

  Usage:
  Desc :
  Ret  :
  Args :
  Side Effects:
  Example:

=cut

# generate a GAME XML (v1.2) file
sub GenerateXML {
  my $seq_id = shift @_;
  my $seq_string = shift @_;
  my @genes = @{shift @_};
  my @exons = @{shift @_};
  my @agsexons = @{shift @_};

  my $doc = new XML::DOM::Document;

  # create a <game> element
  my $root_node = $doc->createElement("game");
  $root_node->setAttribute("version", "1.2");
  $doc->appendChild($root_node);

  # create a <seq> element
  my $seq_node = &create_seq_node($doc, $seq_id, $seq_string);
  $root_node->appendChild($seq_node);

  # create a <computational_analysis> element
  $root_node->appendChild(&create_computational_analysis_node($doc, \@genes));

  # create <annotation> elements
  my $pgl = 1;
  my @one_pgl;
  foreach my $agsexon (@agsexons) {
    if ($pgl != $agsexon->pglnum()) {
      $root_node->appendChild(&create_annotation_node($doc, $pgl, \@one_pgl));
      @one_pgl = ();
      $pgl = $agsexon->pglnum();
    }
    push(@one_pgl,$agsexon);
  }
  $root_node->appendChild(&create_annotation_node($doc, $pgl, \@one_pgl));

  my $out = $doc->toString();
  $doc->dispose();

  return $out;
}

# create a <game><seq> element
sub create_seq_node {
  my $doc = $_[0];
  my $id = $_[1];
  my $sequence = $_[2];

  my $length = length($sequence);

  my $seq_node = $doc->createElement("seq");

  $seq_node->setAttribute("id", $id);
  $seq_node->setAttribute("length", $length);
  $seq_node->setAttribute("version", 0);
  $seq_node->setAttribute("focus", "true");

  $seq_node->appendChild(&create_ElementWithValue($doc, "name", $id));
  $seq_node->appendChild(&create_ElementWithValue($doc, "residues", $sequence));

  return $seq_node;
}

# create a <computational_analysis> element
# create a <computational_analysis><program> element
sub create_computational_analysis_node {
  my $doc = shift @_;
  my @genes = @{shift @_};

  my $comp_anal_node = $doc->createElement("computational_analysis");

  $comp_anal_node->appendChild(&create_ElementWithValue($doc, "program", "GeneSeqer EST Alignment"));

  foreach my $gene (@genes) {
    $comp_anal_node->appendChild(&create_result_set_node($doc, $gene, \@{$gene->exons()}));
  }

  return $comp_anal_node;
}

# create a <game><computational_analysis><result_set> element
sub create_result_set_node {
  my $doc = shift @_;
  my $gene = shift @_;
  my @exons = @{shift @_};

  my $res_set_node = $doc->createElement("result_set");
  $res_set_node->setAttribute("id", $gene->number());
  $res_set_node->appendChild(&create_ElementWithValue($doc, "name", $gene->esttitle));

  my $title = $gene->esttitle();
  my $sid = 1;
  # create <result_span> node for each exon within the current gene
  foreach my $exon (@exons) {
    $res_set_node->appendChild(&create_result_span_node($doc, $gene, $exon, $sid, $title));
    $sid++;
  }

  return $res_set_node;
}

# create a <game><computational_analysis><result_set><result_span> element
# create a <game><computational_analysis><result_set><result_span><output> element
# create a <game><computational_analysis><result_set><result_span><type> element
sub create_result_span_node {
  my $doc = shift @_;
  my $gene = shift @_;
  my $exon = shift @_;
  my $sid = shift @_;
  my $title = shift @_;

  my $res_span_node = $doc->createElement("result_span");

  my $id = $exon->gene() . "." . $sid;
  my $exon_type = "structure";

  $res_span_node->appendChild(&create_ElementWithValue($doc, "type", "exon"));

  $res_span_node->appendChild(&create_ElementWithValue($doc, "score", $exon->score()));

  $sid--;
  my ($q_align, $s_align) = &AlignFix::align($gene->q_align(), $gene->s_align(), $sid);
  $res_span_node->appendChild(&create_seq_relationship_node($doc, $exon, $title, $q_align, "query"));
  $res_span_node->appendChild(&create_seq_relationship_node($doc, $exon, $title, $s_align, "sbjct"));

  $res_span_node->setAttribute("id", $id);

  return $res_span_node;
}

# create a <annotation> element
# create a <annotation><type> element
sub create_annotation_node {
  my $doc = shift @_;
  my $pgl = shift @_;
  my @agsexons = @{shift @_};

  my $annotation_node = $doc->createElement("annotation");
  $annotation_node->setAttribute("id", "PGL $pgl");
  $annotation_node->appendChild(&create_ElementWithValue($doc, "name", "PGL $pgl"));
  $annotation_node->appendChild(&create_ElementWithValue($doc, "type", "gene"));

  my $ags = 1;
  my @one_ags;
  foreach my $agsexon (@agsexons) {
    if ($ags != $agsexon->agsnum()) {
      $annotation_node->appendChild(&create_feature_set_node($doc, $pgl, $ags, \@one_ags));
      @one_ags = ();
      $ags = $agsexon->agsnum();
    }
    push(@one_ags,$agsexon);
  }
  $annotation_node->appendChild(&create_feature_set_node($doc, $pgl, $ags, \@one_ags));

  return $annotation_node;
}

# create a <game><annotation><feature_set> element
sub create_feature_set_node {
  my $doc = shift @_;
  my $pgl = shift @_;
  my $ags = shift @_;
  my @agsexons = @{shift @_};

  my $feat_set_node = $doc->createElement("feature_set");
  $feat_set_node->setAttribute("id", "PGL-$pgl AGS-$ags");
  $feat_set_node->appendChild(&create_ElementWithValue($doc, "name", "PGL-$pgl AGS-$ags"));
  $feat_set_node->appendChild(&create_ElementWithValue($doc, "type", "gene"));
  $feat_set_node->appendChild(&create_ElementWithValue($doc, "author", "GeneSeqer"));

  my $sid = 1;
  foreach my $agsexon (@agsexons) {
    $feat_set_node->appendChild(&create_feature_span_node($doc, $agsexon));
    $sid++;
  }

  return $feat_set_node;
}

# create a <game><annotation><feature_set><feature_span> element
sub create_feature_span_node {
  my $doc = shift @_;
  my $agsexon = shift @_;

  my $feat_span_node = $doc->createElement("feature_span");

  my $id = "PGL-" . $agsexon->pglnum() . " AGS-" . $agsexon->agsnum() . "." . $agsexon->num();
  $feat_span_node->setAttribute("id", $id);
  $feat_span_node->appendChild(&create_ElementWithValue($doc, "name", $id));
  $feat_span_node->appendChild(&create_ElementWithValue($doc, "type", "exon"));

  $feat_span_node->appendChild(&create_fset_seqrel_node($doc, $agsexon));

  return $feat_span_node;
}

# create a <game><annotation><feature_set><feature_span><seq_rel.> element
sub create_fset_seqrel_node {
  my $doc = shift @_;
  my $agsexon = shift @_;
  my ($seq, $seq_rel_node, $start, $end);

  # get the id of the main sequence (from the main <seq> element)
  $seq = $doc->getFirstChild()->getFirstChild()->getAttribute("id");

  $seq_rel_node = $doc->createElement("seq_relationship");
  $seq_rel_node->setAttribute("seq", $seq);

  $start = $agsexon->start();
  $end = $agsexon->end();

  my $span_node = $doc->createElement("span");
  $seq_rel_node->appendChild($span_node);

  $span_node->appendChild(&create_ElementWithValue($doc, "start", $start));
  $span_node->appendChild(&create_ElementWithValue($doc, "end", $end));

  return $seq_rel_node;
}


# create <$node><type>$type</type><value>$value</value></$node>
sub create_type_value_node {
  my $doc = $_[0];
  my $node = $_[1];
  my $type = $_[2];
  my $value = $_[3];

  my $node_node = $doc->createElement($node);

  my $type_node = &create_ElementWithValue($doc, "type", $type);
  my $value_node = &create_ElementWithValue($doc, "value", $value);

  $node_node->appendChild($type_node);
  $node_node->appendChild($value_node);

  return $node_node;
}

# create <$element_name>$value</$element_name>
sub create_ElementWithValue {
  my $doc = $_[0];
  my $element_name = $_[1];
  my $value = $_[2];

  my $element_n = $doc->createElement($element_name);
  my $value_n = $doc->createTextNode($value);

  $element_n->appendChild($value_n);

  return $element_n;
}


# create a <seq_relationship> element
sub BEGIN {
sub create_seq_relationship_node {
  my $doc = shift @_;
  my $exon = shift @_;
  my $title = shift @_;
  my $alignment = shift @_;
  my $type = shift @_;
  my ($seq, $seq_rel_node, $start, $end, $node);

  if ($type eq "query") {
    # get the id of the main sequence (from the main <seq> element)
    $seq = $doc->getFirstChild()->getFirstChild()->getAttribute("id");

    $seq_rel_node = $doc->createElement("seq_relationship");
    $seq_rel_node->setAttribute("seq", $seq);
    $seq_rel_node->setAttribute("type", "query");

    $start = $exon->start();
    $end = $exon->end();
  }

  if ($type eq "sbjct") {
    $seq_rel_node = $doc->createElement("seq_relationship");
    $seq_rel_node->setAttribute("seq", $title);
    $seq_rel_node->setAttribute("type", "subject");

    $start = $exon->cdna_start();
    $end = $exon->cdna_end();
  }

  my $span_node = $doc->createElement("span");
  $seq_rel_node->appendChild($span_node);

  $span_node->appendChild(&create_ElementWithValue($doc, "start", $start));
  $span_node->appendChild(&create_ElementWithValue($doc, "end", $end));

  $seq_rel_node->appendChild(&create_ElementWithValue($doc, "alignment", $alignment));

  return $seq_rel_node;
}
}

return 1;

package AlignFix;

use strict;

# break up the alignments generated by GeneSeqer
# get the EST alignment for the requested exon
sub align() {
  my $q_align = shift @_;
  my $s_align = shift @_;
  my $exon = shift @_;
  
  my $length = length($q_align);
  my @q_array = split(//, $q_align);
  my @s_array = split(//, $s_align);
  
  my $exoncount = 0;
  my ($dot, $q_out, $s_out);
  
  for (my $n = 0; $n < $length; $n++) {
    if ($exoncount > $exon) {
      last;
    }
    if ($s_array[$n] eq ".") {
      $dot = 1;
    }
    else {
      if ($dot) {
        $exoncount++;
        $dot = 0;
      }
      if ($exon == $exoncount) {
        $q_out .= $q_array[$n];
        $s_out .= $s_array[$n];
      }
    }
  }
  return ($q_out, $s_out);
}

return 1;


=head1 AUTHORS

Jay Gadgil (intern 2003), adapted for inclusing in perl libs by
Robert Buels

=cut
