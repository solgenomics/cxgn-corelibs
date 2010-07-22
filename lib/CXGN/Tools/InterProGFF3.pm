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

has parent_list => (
    is  => 'rw',
    isa => 'HashRef',
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
                          ));
    $self->ontology( $self->parser->next_ontology );
    $self->gff3( $self->gff3_preamble );
    $self->generate_parent_list;
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

sub generate_parent_list {
    my ($self) = @_;
    my $relations = $self->ontology->{engine}->{_inverted_relationship_store} ;
    my $parent_list = {};

    while ( my ($k,$v) = each %$relations ) {
        $parent_list->{$k} = join(',',grep { $_ =~ m/^IPR/ && $v->{$_}->name eq 'IS_A' } keys %$v);
    }
    $self->parent_list( $parent_list );
}

sub convert {
    my ($self) = @_;
    my @domains = $self->get_domains;
    for my $domain (@domains) {

        my (@relations) = $self->ontology->get_relationships($domain);

        # Find all IS_A relations of this domain, excluding itself
        # This should include parent terms, but does not. See
        # generate_parent_list for how parents are found
        my @isa_relations = grep {
            $_->predicate_term->name eq 'IS_A' &&
            $_->object_term->identifier ne $domain->identifier
        } @relations;
        my $type = @isa_relations ? $isa_relations[0]->object_term->name : '';

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
    my $fmt = 'ID=%s;Name=%s;Alias=%s;Parent=%s;Note=%s;Dbxref=%s;interpro_type=%s;protein_count=%s';
    no warnings 'uninitialized';
    return sprintf $fmt, (map { uri_escape($_,';=%&,') } (
            $domain->identifier, $domain->name,
            $domain->short_name,
            $self->parent_list()->{$domain->identifier},
            $domain->definition)),
            join(',', "INTERPRO:" . $domain->identifier, (map { $_->database . ':' . $_->primary_id } $domain->get_members)),
            $type, $domain->protein_count;
}

sub get_domains {
    my ($self) = @_;
    return sort { $b <=> $a } grep { $_->identifier =~ m/^IPR/ } $self->ontology->get_all_terms;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
