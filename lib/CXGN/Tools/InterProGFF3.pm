package CXGN::Tools::InterProGFF3;
use Moose;
use Moose::Util::TypeConstraints;
use Bio::OntologyIO::InterProParser;

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

has filehandle => (
    is => 'ro',
    isa => 'FileHandle',
);

has interpro_parser => (
    is  => 'ro',
    isa => 'Bio::OntologyIO::InterProParser',
    default => sub {
        Bio::OntologyIO::InterProParser->new(
            -ontology_engine => 'simple',
        ),
    },
);

sub BUILDARGS {
    my $class = shift;
    my %args = @_;
    # if no file param is given, read from STDIN

    return $class->SUPER::BUILDARGS( %args );
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
