package File::Find::Rule::VersionedFile;
use strict;
use Carp;
use Memoize;
use Text::Glob 'glob_to_regex';
use List::MoreUtils qw/ any /;
use CXGN::Tools::List qw/ flatten /;

# take useful things from File::Find::Rule
use base 'File::Find::Rule';

sub File::Find::Rule::unversioned_name () {
    my $self = shift()->_force_object;
    return _regexp_rule_on( $self, 'basename_unversioned', @_ );
}

sub File::Find::Rule::unversioned_dir () {
    my $self = shift()->_force_object;
    return _regexp_rule_on( $self, 'dir_unversioned', @_ );
}

sub File::Find::Rule::version_is_obsolete () {
    my $self = shift()->_force_object;
    my $publisher = _validate_publisher(shift);
    my $status = shift;
    defined $status
        or croak "must pass obsolete status";
    return $self->exec( sub {
        my $pa = _cached_parse_versioned_filepath( $publisher, $_ );
        return 0 unless $pa->{version};
        my $ot = $pa->{obsolete_timestamp};
        return $status ? !!$ot : !$ot;
    } )
}

memoize('_cached_parse_versioned_filepath');
sub _cached_parse_versioned_filepath {
    shift->parse_versioned_filepath( shift );
}

sub _regexp_rule_on {
    my $self = shift;
    my $attr_name = shift;
    my $publisher = _validate_publisher(shift);

    my @names = map { ref $_ eq "Regexp" ? $_ : glob_to_regex $_ } flatten( @_ );

    return $self->exec( sub {
        my $pa = _cached_parse_versioned_filepath( $publisher, $_[2] );
        return 0 unless $pa->{version};
        #print "compare $attr_name for $_, $pa->{$attr_name} =~ ".join ',',@names;
        #print "\n";
        my $result = any {$pa->{$attr_name} =~ $_} @names;
        #$result ||= 0;
        #print "result: $result\n";
        return $result;
    } )
}
sub _validate_publisher {
    my $publisher = shift;
    $publisher && $publisher->can('publish')
        or croak "must provide a CXGN::Publish object or equivalent as first argument";
    return $publisher;
}



1;

__END__

=head1 NAME

File::Find::Rule::VersionedFile - File::Find::Rule functions for use
on files versioned with CXGN::Publish

=head1 SYNOPSIS

use File::Find::Rule::VersionedFile;

  File::Find::Rule
     ->file
     ->unversioned_name( $publisher, qr/\w+\.bar/ )
     ->unversioned_dir ( $publisher, qr/baz$/ )
     ->version_is_obsolete ( $publisher, 1 )

  # above would find all non-obsolete files matching baz/\w+.bar

=head1 FUNCTIONS

When this module is used, adds the following functions to
File::Find::Rule.

=head2 unversioned_name

Like FFR's name() function, but matches against the file's name *not
including* the version number.  Takes L<CXGN::Publish> as the first
arg, then names to match against

=head2 unversioned_dir

Matches against the file's unversioned dirname (without old/ if
present).

=head2 version_is_obsolete

Given either 1 or 0, checks that the file is either obsolete (1) or
not obsolete (0).

