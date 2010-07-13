package CXGN::Tools::InterProGFF3;
use Moose;
use Moose::Util::TypeConstraints;
use Bio::OntologyIO::InterProParser;
use feature 'say';
use Data::Dumper;
use autodie;
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
    # if no file param is given, read from STDIN
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
        $self->gff3( $self->gff3 . $self->make_gff3_line($domain) );
    }
}

sub make_gff3_line {
    my ($self,$domain) = @_;
    my $fmt = "%s\t" x 8 . "%s\n";
    return sprintf $fmt, $domain->identifier,
                    $self->source, $self->term_type,
                    0, 0, qw/. . ./, $self->make_id_string($domain);
}

sub make_id_string {
    my ($self,$domain) = @_;
    my $fmt = 'ID=%s;Name=%s;Alias=%s;Parent=%s;Note=%s;Dbxref=%s;Type=%s';
    return sprintf $fmt, $domain->identifier, $domain->name,
            $domain->short_name, 'PARENTS', $domain->definition,
            ($domain->get_dbxrefs||'XREF'), 'TYPE';
}

sub get_domains {
    my ($self) = @_;
    # this can be improved
    return grep { $_->identifier =~ m/^IPR/ } $self->ontology->get_all_terms;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
