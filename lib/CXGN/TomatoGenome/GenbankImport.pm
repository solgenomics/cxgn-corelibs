package CXGN::TomatoGenome::GenbankImport;
use strict;
use warnings;

use English;
use Carp;

=head1 NAME

CXGN::TomatoGenome::GenbankImport

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Bio::DB::GenBank;

use CXGN::Genomic::CloneIdentifiers; #< do not import anything,
                                     #namespace::autoclean is not
                                     #available yet for deployment
use Data::Dumper;

use Params::Validate ();
use List::MoreUtils qw/ any /;

use base qw/Class::Data::Inheritable/;

__PACKAGE__->mk_classdata('verbose');

my $d = CXGN::Debug->new;

sub vsay {
    my $class = shift;
    print @_,"\n" if $class->verbose || $d->get_debug;
}

=head1 CLASS METHODS

=cut

=head2 import_from_genbank

  Status  : public
  Usage   : CXGN::TomatoGenome::GenbankImport
              ->import_from_genbank_text_query( $chado,
                                                'RHPOTKEY or POTGEN' );
  Returns : nothing meaningful
  Args    : hash-style list as:
            chado => Bio::Chado::Schema object,
            query => genbank query text (e.g. 'RHPOTKEY or POTGEN or RH89-039-16'),
            project_name => either project name string (e.g. 'acgt-roe') or a
                            subroutine ref that figures out the project name when
                            passed a Bio::Seq::RichSeq object
            project_country => (optional) string (e.g. 'US') or coderef, as above,
                               defaults to builtin project country inference routine,
            clone_obj => string or subroutine ref to find the proper Clone object
                         from a given Bio::Seq::RichSeq from GenBank,
            verbose => 0 or 1, default off.  if true, prints information to stdout
                       about what is being loaded.

  Side Eff: dies on error, and does not actually commit the loading
            transaction if CXGN_DEBUG is set true.

  Takes a L<Bio::Chado::Schema> object, and a text genbank query
  string, and loads the resulting records it finds into the given
  Chado database.

=cut

sub import_from_genbank {
    my $class = shift;
    my %a = Params::Validate::validate(
                @_,
                {
                 chado => {
                           can => [qw[resultset storage txn_do txn_rollback]],
                          },
                 query => {
                           type => Params::Validate::SCALAR,
                          },
                 project_country => {
                                     default => \&_infer_project_country_from_gb_richseq,
                                     type    => Params::Validate::CODEREF | Params::Validate::SCALAR,
                                    },
                 project_name => {
                                  type => Params::Validate::CODEREF | Params::Validate::SCALAR,
                                 },
                 clone_object => {
                                  default => \&_infer_clone_obj_from_gb_richseq,
                                  type => Params::Validate::CODEREF | Params::Validate::SCALAR,
                                 },
                 verbose => 0,
                },
             );

    $class->verbose( $a{verbose} || $d->get_debug);

    my $chado = delete $a{chado};

    my %handlers;
    foreach my $k ( 'project_name',
                    'project_country',
                    'clone_object'
                  ) {
        my $a = $a{$k};
        if( ref($a) eq 'CODE' ) {
            $handlers{$k} = $a;
        } else {
            $handlers{$k} = sub { $a }
        }
    }

    # set up two genbank handles, one that gets records with no seqs, and
    # one that gets just fasta seqs
    my $gb_recs  = Bio::DB::GenBank->new(-retrievaltype => 'tempfile' ,
                                         #-format => 'Fasta',
                                         #don't download any of the sequences
                                         -seq_start => 1, -seq_stop  => 1,
                                        );
    my $gb_fasta = Bio::DB::GenBank->new( -retrievaltype => 'tempfile',
                                          -format => 'Fasta',
                                        );

    $class->vsay("querying GenBank for clone records matching '$a{query}'...");

    my $bac_recs = $gb_recs->get_Stream_by_query( Bio::DB::Query::GenBank->new
                                                  ( -db => 'nucleotide',
                                                    #-query  => 'AC236750',
                                                    -query => $a{query},
                                                  )
                                                );
    my $count = 0;
    while ( my $seq = $bac_recs->next_seq ) {
        sleep 2; #< wait a couple of seconds between genbank queries

        # find the record for the BAC associated with this seq
        my $clone = $handlers{clone_object}->( $seq );
        unless( $clone ) {
            warn "cannot find clone record for ".$seq->accession_number.", skipping.\n";
            die Dumper $seq;
            next;
        }
        ref($clone) && $clone->can('genbank_accession')
            or die "invalid clone '$clone'";

        my $project_name    = $handlers{project_name}->( $seq );
        my $project_country = $handlers{project_country}->( $seq );
        my $htgs_phase      = _infer_htgs_phase_from_gb_richseq( $seq );

        my $upstream_accession = $seq->accession_number;
        my $upstream_version = $seq->version;

        # find most recent accession for this BAC
        if ( my $current_accession = $clone->genbank_accession ) {

            # compare to this one.  if up to date, next.
            my ($our_version) = $current_accession =~ /\.(\d+)$/
                or die "error parsing genbank accession $current_accession";

            if ( $upstream_version > $our_version ) {
                $class->vsay( $clone->clone_name.": current stored version $current_accession, loading new genbank seq version $upstream_accession.$upstream_version" );
            } else {
                $class->vsay( $clone->clone_name.": current stored version $current_accession is >= upstream version $upstream_accession.$upstream_version, skipping" );
                next;
            }
        } else {
            $class->vsay( $clone->clone_name.": no current sequence, loading upstream $upstream_accession.$upstream_version" );
        }

        # fetch the full genbank seq for this one
        my $gb_seq = $gb_fasta->get_Seq_by_gi( $seq->primary_id )
            or die 'could not fetch GI '.$seq->primary_id.":\n".Data::Dumper::Dumper $seq;

        unless( $gb_seq->length > 5_000 && $gb_seq->seq !~ /[<>]/ ) {
            warn "failed to fetch seq for ".$seq->display_id." (gi ".$seq->primary_id."), skipping.\n";
            next;
        }

        # figure out the new sol-style sequence version for this bac
        my $parsed_ident = CXGN::Genomic::CloneIdentifiers::parse_clone_ident($clone->clone_name)
            or die "could not parse clone identifier ".$clone->clone_name;
        my $new_sol_seq_name = CXGN::Genomic::CloneIdentifiers::assemble_clone_ident
            ( versioned_bac_seq_no_chrom =>
              {
               %$parsed_ident,
               version => ($clone->latest_sequence_version || 0) + 1,
              }
            );

        # load it into the DB with the proper accession
        # and update the clone_feature table
        $chado->txn_do( sub {
            my $bac_cvterm = $chado
                ->resultset('Cv::Cv')
                ->search({'me.name' => 'sequence'})
                ->search_related(cvterms => {'cvterms.name' => 'BAC_clone'})
                ->first;

            my $gbacc = $seq->accession_number.'.'.$seq->version;
            my $gi = $seq->primary_id;

            # make a feature for it in the feature table
            my $organism = _infer_organism( $chado, $seq );
            my $new_feature =
                $organism->create_related('features',
                                          { name => $new_sol_seq_name,
                                            uniquename => $new_sol_seq_name,
                                            type_id  => $bac_cvterm->cvterm_id,
                                            residues => $gb_seq->seq,
                                            seqlen => $gb_seq->length,
                                          },
                                         );
            $new_feature->create_featureprops({ htgs_phase => $htgs_phase,
                                                finished_seq => ($htgs_phase == 3 ? 1 : 0),
                                                sequenced_by    => $project_name,
                                                project_country => $project_country,
                                                description => (join ' ',
                                                                "genbank_gi:$gi",
                                                                "genbank_accession:$gbacc",
                                                                "sequenced_by:$project_name",
                                                                "project_country:$project_country",
                                                                "htgs_phase:$htgs_phase",
                                                               ),
                                              },
                                              {
                                               autocreate => 1 },
                                             );


            # add a dbxref for its genbank accession
            my $gbacc_dbx = $chado->resultset('General::Db')
                                  ->find_or_create({ name => 'DB:GenBank_Accession'})
                                  ->find_or_create_related('dbxrefs',
                                                           { accession => $gbacc,
                                                             version   => $seq->version,
                                                           }
                                                          );
            $new_feature->add_to_secondary_dbxrefs( $gbacc_dbx );

            # add a dbxref for its genbank GI
            my $gi_dbx = $chado->resultset('General::Db')
                               ->find_or_create({ name => 'DB:GenBank_GI'})
                               ->find_or_create_related('dbxrefs',
                                                        { accession => $gi,
                                                        }
                                                       );
            $new_feature->add_to_secondary_dbxrefs( $gi_dbx );


            # manually update the clone_feature table
            $chado->storage->dbh_do(sub {
                my ($s,$dbh) = @_;
                $dbh->do('delete from clone_feature where clone_id = ?',
                         undef,
                         $clone->clone_id,
                        );
                $dbh->do('insert into clone_feature (feature_id,clone_id) values (?,?)',
                         undef,
                         $new_feature->feature_id,
                         $clone->clone_id,
                        );
            });

            # don't actually do anything to the db if debug is on
            $chado->storage->txn_rollback if $d->get_debug;
        });


        #print Dumper $seq;
        #die unless $clone_name;
        #     print join "\t", $seq->id, $clone_name || 'UNKNOWN', $seq->accession_number, $seq->version;
        #     print "\n";
        $count++;

        # for each seq, we need to update:
        #  - mapping between gb accession and bac name
        #  - bac sequence

    }
    $class->vsay( "loaded $count seqs\n" );

}

sub _infer_project_country_from_gb_richseq {
    my $seq = shift;
    my @project_signatures = @_;

    unless( @project_signatures ) {
        @project_signatures =
            (
             [ IE => qr/Ireland/i ],
             [ CN => qr/China/, qr/Qu,D/, qr/Du,Y/, qr/He,J/, qr/Zhang,Z/,qr/Huang,S/],
             [ IN => qr/India/],
             [ NL => qr/Netherlands/],
             [ NZ => qr/New Zealand/],
             [ PE => qr/Peru/], 
             [ PL => qr/Poland/],
             [ RU => qr/Russia/],
             [ US => qr/United States of America|\bUSA\b/, qr/Oklahoma/, qr/Giovannoni/, qr/\bRoe,B/ ],
             [ AR => qr/Argentina/],
            );
    }

    #match one of the project signatures from the above array
    foreach my $p (@project_signatures) {
        my ( $project_name, @signatures ) = @$p;
        foreach my $sig (@signatures) {
            if( ref $sig eq 'CODE' ) {
                return $project_name if $sig->($seq);
            }
            elsif( ref $sig eq 'Regexp' ) {
                my ($ref) = $seq->annotation->get_Annotations('reference');
                my $text = join "\n",
                    map "$_: ".($ref->$_ || '<none>'),
                    qw| title authors location consortium |;
                return $project_name if $text =~ $sig;
            }
            else {
                die "no handler for '".ref($sig)."' signatures";
            }
        }

    }

    require Data::Dumper;
    die "could not infer project name for sequence:\n".Data::Dumper::Dumper($seq);
}

sub _infer_htgs_phase_from_gb_richseq {
    my $seq = shift;

    my @keywords = map $_->value, $seq->annotation->get_Annotations('keyword','keywords');
    return 1 if any { $_ eq 'HTGS_PHASE1' } @keywords;
    return 2 if any { $_ eq 'HTGS_PHASE2' } @keywords;

    # if no HTGS_PHASE1 or 2, assume phase 3
    return 3;
}

sub _infer_clone_obj_from_gb_richseq {
    my $seq = shift;
    my $clone_name = _infer_clone_name_from_gb_richseq($seq)
        or return;

    require CXGN::Genomic::Clone;
    return CXGN::Genomic::Clone->retrieve_from_clone_name( $clone_name );
}

sub _infer_clone_name_from_gb_richseq {
    my $seq = shift;

    my @tests =
        (
         sub { shift->desc =~ /clone\s+([\w\-]+)/ && $1 },
         sub { my $a = shift->annotation(); my ($c) = $a->get_Annotations('clone'); $c && $c->value },
        );

    foreach my $t (@tests) {
        my $name = $t->($seq);
        return $name if $name && CXGN::Genomic::CloneIdentifiers::parse_clone_ident($name);
    }

    return;
}

# finds the NCBI taxon ID in the sequence coming from genbank and
# looks it up in the Chado DB
sub _infer_organism {
    my ( $chado, $seq ) = @_;

    my $ncbi_taxon = $seq->species->ncbi_taxid
        or confess "cannot infer organism, no NCBI taxon ID provided for: ".Dumper($seq);

    my $taxon_dbx =
        $chado->resultset('General::Db')
              ->find_or_create({ name => 'DB:NCBI_taxonomy'})
              ->find_related('dbxrefs',
                             { accession => $ncbi_taxon }
                            )

         or confess "cannot find ncbi taxon ID '$ncbi_taxon' in Chado DB";

    my $og_rs = $taxon_dbx->organisms_mm;
    my $og_count = $og_rs->count;
    $og_count > 1
        and confess "more than one chado organism matches taxon ID '$ncbi_taxon', dbxref_id '".$taxon_dbx->dbxref_id."'";
    $og_count > 0
        or confess <<EOM;
No chado organism matches taxon ID '$ncbi_taxon', cannot infer
organism.  Make sure you have the rows necessary to link organism ->
organism_dbxrefs -> dbxref -> db( name=DB:NCBI_taxonomy )
EOM

    return $og_rs->first;
}

=head1 MAINTAINER

Robert Buels

=head1 AUTHOR

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

####
1;
###
