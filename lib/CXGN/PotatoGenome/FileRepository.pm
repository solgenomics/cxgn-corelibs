package CXGN::PotatoGenome::FileRepository;
use Moose;

use English;
use Carp;

=head1 NAME

CXGN::PotatoGenome::FileRepository - versioned file respository for
the potato genome

=head1 SYNOPSIS

=head1 DESCRIPTION

Subclass of CXGN::FileRepository implementing the
storage scheme for the Potato Genome file repository

=head1 BASE CLASS(ES)

L<CXGN::FileRepository>

=cut

extends 'CXGN::FileRepository';

has '+publisher',
    ( default => sub {
          my $p = CXGN::Publish->new;
          $p->make_dirs(1);
          $p->suffix([  qr/(?<=\.\d{5})\..+$/,
                        qr/(?<=\.\d{4})\..+$/,
                        qr/(?<=\.\d{3})\..+$/,
                        qr/(?<=\.\d{2})\..+$/,
                        qr/(?<=\.\d)\..+$/,
                        qr/\..*[a-z].*$/i,
                     ]
                    );
          return $p
      },
    );

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 FILE CLASSES

=head2 SingleCloneSequence

Conditions:

  format        - if given, must be 'fasta'

  sequence_name - e.g. RH123A12.1

  OR

    clone   - clone object or clone name (e.g. RH123A12)
    OPTIONALLY WITH
    version - 1

=cut


package CXGN::PotatoGenome::FileRepository::FileClass::Base;
use Moose;
use List::MoreUtils qw/ any /;
use Carp::Clan qr/FileRepository/;

sub check_format {
    my ($self,$s,@accepted_formats) = @_;
    if( defined $s->{format} ) {
        #formalize it
        $s->{format} = lc $s->{format};

        #< check the format if any allowed ones were passed
        if( @accepted_formats ) {
            croak "invalid format '$s->{format}'"
                unless any {$s->{format} eq $_} @accepted_formats;
        }

        return 1;
    } else {
        $s->{format} = '[a-z\d]+';
        return 0;
    }
}

package CXGN::PotatoGenome::FileRepository::FileClass::SingleCloneSequence;
use Moose;
use Carp::Clan qw(^CXGN::(\w+::)*FileRepository);
use CXGN::Genomic::CloneIdentifiers qw/ clone_ident_regex assemble_clone_ident parse_clone_ident /;

use File::Find::Rule::VersionedFile ();

extends 'CXGN::PotatoGenome::FileRepository::FileClass::Base';

sub get_vf {
    my ($uniq, @results) = shift->_search(@_);
    croak "search conditions do not uniquely specify a file" unless $uniq;
    return $results[0];
}

sub search_vfs {
    my (undef, @results) = shift->_search(@_);
    return @results;
}

sub _search {
    my ($self, %s) = @_;


    my $pub = $self->repository->publisher;

    # progressively build up a File::Find::Rule to find the files
    # we want.  start with files
    my $rule = File::Find::Rule->file
                               ->maxdepth(2)
                               ->mindepth(2)
                               ->version_is_obsolete( $pub, 0);

    # narrow by format, start keeping track of whether our conditions narrow to a unique file
    my $unique = $self->check_format(\%s,'fasta');
    my $format = delete $s{format};

    my $project = delete $s{project};
    unless( $project ) {
        $project = '[A-Z]{2}';
        $unique = 0;
    }

    $rule->unversioned_dir( $pub, qr/\b$project$/ ); #< dir must match project name

    #### figure out the sequence name

    #if we have one passed, use that
    my $sn = delete $s{sequence_name};
    if( $sn ) {
        %s and croak "sequence_name condition overrides all other conditions.";
    }
    else {
        # if we have clone and version, use those
        if( $s{clone} ) {
            my $clone_name = ref $s{clone} ? $s{clone}->clone_name : $s{clone};
            my $p = parse_clone_ident($clone_name)
                or die "could not parse clone ident '$clone_name'";

            $sn = assemble_clone_ident( 'agi_bac' => $p )
                or die "could not assemble seq name from '$clone_name', '$s{version}";

            $sn .= '\.'.($s{version} || '\d+');
        }
        elsif( $s{version} ) {
            croak "search by only seq version not yet supported";
        }
        # if we have nothing, just * for the seq name
        else {
            $sn = clone_ident_regex('versioned_bac_seq_no_chrom');
            $unique = 0;
        }
    }

    # now we know what our unversioned name will look like
    $rule->unversioned_name($pub, qr/^$sn\.$format$/);

    return ($unique, $unique ? $self->vf( $project, "$sn.$format") : $self->vfs_by_rule( $rule ));
}

with 'CXGN::FileRepository::FileClass';

__PACKAGE__->meta->make_immutable;
no Moose;

=head2 AllCloneSequences

Conditions:

  format - currently only 'fasta.gz' is available

=cut

package CXGN::PotatoGenome::FileRepository::FileClass::AllCloneSequences;
use Moose;
use File::Spec;
use Carp;

use File::Find::Rule::VersionedFile ();

extends 'CXGN::PotatoGenome::FileRepository::FileClass::Base';

# just returns a separate VersionedFile for each condition value
sub search_vfs {
    my ($self,%c) = @_;

    my $unique = $self->check_format(\%c,'fasta.gz');
    my $fmt = $c{format};
    my $rule = File::Find::Rule->file
                               ->maxdepth(1)
                               ->unversioned_name( $self->repository->publisher,
                                                   "all_clone_sequences.$fmt",
                                                 );
    return $unique ? $self->vf( "all_clone_sequence.$fmt" ) : $self->vfs_by_rule( $rule );
}

sub get_vf {
    shift->search_vfs(@_);
}


with 'CXGN::FileRepository::FileClass';


__PACKAGE__->meta->make_immutable;
no Moose;


=head2 AccessionMapping

Conditions:

  format - currently only 'txt' is available

=cut

package CXGN::PotatoGenome::FileRepository::FileClass::AccessionMapping;
use Moose;
use File::Spec;
use Carp;

use File::Find::Rule::VersionedFile ();

extends 'CXGN::PotatoGenome::FileRepository::FileClass::Base';

# just returns a separate VersionedFile for each condition value
sub search_vfs {
    my ($self,%c) = @_;

    my $unique = $self->check_format(\%c,'txt');
    my $fmt = $c{format};
    my $rule = File::Find::Rule->file
                               ->maxdepth(1)
                               ->unversioned_name( $self->repository->publisher,
                                                   "genbank_accessions.$fmt",
                                                 );
    return $unique ? $self->vf( "genbank_accessions.$fmt" ) : $self->vfs_by_rule( $rule );
}

sub get_vf {
    shift->search_vfs(@_);
}

with 'CXGN::FileRepository::FileClass';

__PACKAGE__->meta->make_immutable;
no Moose;


=head1 MAINTAINER

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 AUTHOR

Robert Buels, E<lt>rmb32@cornell.eduE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;
###
