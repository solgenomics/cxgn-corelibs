package CXGN::Tools::InterProGFF3;
use Moose;
use Moose::Util::TypeConstraints;
use Bio::OntologyIO::InterProParser;
use feature 'say';
use Data::Dumper;
use autodie;
use URI::Escape;
with 'MooseX::Runnable';
with 'MooseX::Getopt';

=head1 NAME

CXGN::Tools::InterProGFF3 - Convert InterPro XML to GFF3

=head1 SYNOPSIS

This tool converts InterPro XML to GFF3 so that InterPro domains
can be loaded as features into Chado.

=head1 DESCRIPTION

=head1 MAINTAINER

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

has gff3_preamble => (
    is  => 'ro',
    isa => 'Str',
    default => "##gff-version 3
##feature ontology http://song.cvs.sourceforge.net/*checkout*/song/ontology/sofa.obo?revision=1.220\n",
);

has filename => (
    is => 'ro',
    isa => 'Str',
);

has output => (
    is => 'ro',
    isa => 'Str',
);

has parser => (
    is  => 'rw',
    isa => 'Bio::OntologyIO::InterProParser',
);

has ontology => (
    is => 'rw',
);

has source => (
    is      => 'rw',
    isa     => 'Str',
    default => 'InterPro Version X',
);

has term_type => (
    is      => 'ro',
    isa     => 'Str',
    default => 'SO:0000417',
);

has gff3 => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_;
    return $class->SUPER::BUILDARGS( %args );
}

sub run {
    my ($self,%args) = @_;
    $self->parser( Bio::OntologyIO->new(
                                -format => 'interpro',
                                -file   => $self->filename,
                                ontology_engine => 'simple'
                          ));
    $self->ontology( $self->parser->next_ontology );
    $self->gff3( $self->gff3_preamble );
    $self->convert;
    if ($self->output) {
        open my $fh, '>', $self->output;
        print $fh $self->gff3;
        close $fh;
    } else {
        print $self->gff3;
    }
    #exit code
    return 0;
}

sub convert {
    my ($self) = @_;
    my @domains = $self->get_domains;
    for my $domain (@domains) {
        # this relies on the fact that the "type" is the first relationship
        # returned, which is wrong. the parent relationship needs to be found as well
        die Dumper [ $self->ontology ];
        my (@relations) = $self->ontology->get_relationships($domain);
        warn Dumper [ $domain->identifier,
            [ map { $_->subject_term->identifier } @relations ],
            [ map { $_->predicate_term->name } @relations ],
            [ map { $_->object_term->identifier } @relations ],
        ];

        my $type       = $relations[0]->object_term->name;


        my (@parents) = # grep { $_->predicate_term->name eq 'CONTAINS_A' }
            $self->ontology->get_relationships($domain);

        $self->gff3( $self->gff3 . $self->make_gff3_line($domain, $type) );
    }
}

sub make_gff3_line {
    my ($self,$domain, $type) = @_;
    my $fmt = "%s\t" x 8 . "%s\n";
    return sprintf $fmt, $domain->identifier,
                    $self->source, $self->term_type,
                    0, 0, qw/. . ./, $self->make_attribute_string($domain, $type);
}

sub make_attribute_string {
    my ($self,$domain, $type) = @_;
    my $fmt = 'ID=%s;Name=%s;Alias=%s;ipr_parent=%s;Note=%s;Dbxref=%s;interpro_type=%s;protein_count=%s';
    return sprintf $fmt, map { uri_escape($_,';=%&,') } (
            $domain->identifier, $domain->name,
            $domain->short_name, 'PARENTS', $domain->definition,
            ($domain->get_dbxrefs || ''), $type, $domain->protein_count);
}

sub get_domains {
    my ($self) = @_;
    # this can be improved
    return grep { $_->identifier =~ m/^IPR/ } $self->ontology->get_all_terms;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
