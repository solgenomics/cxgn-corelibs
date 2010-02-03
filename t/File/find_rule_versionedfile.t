#!/usr/bin/env perl
use strict;
use warnings;
use English;

use Test::More tests => 6;
use File::Temp qw/:seekable/;
use File::Spec::Functions;

use CXGN::Publish;

use Data::Dumper;

use Test::Exception;

BEGIN {
  use_ok(  'File::Find::Rule::VersionedFile'  )
    or BAIL_OUT('could not include the module being tested');
}


my $tempdir = File::Temp->newdir;

## construct a test repos
my $publisher = CXGN::Publish->new;
$publisher->make_dirs(1);
my $tempfile = File::Temp->new;
$tempfile->print('foofoooo');
$tempfile->sync;

my @publish_ops;
foreach my $dir1 (qw| ABC DEF | ) {
    foreach my $dir2 (qw| GHI JKL |) {
        foreach my $name ( 'foghat', 'tobykeith' ) { #< because you know i love toby keith
            foreach my $ext ('txt','doc') {
                push @publish_ops, [ cp => "$tempfile", catfile($tempdir,$dir1,$dir2,"$name.$ext")],
            }
        }
    }
}
$publisher->publish( @publish_ops );

$tempfile->print('fiddlefaddlefoodle');
$tempfile->sync;

$publisher->publish( @publish_ops[0..4] );
#system find => $tempdir;

### now test the find rules on the test repo

dies_ok {
    File::Find::Rule->file->unversioned_name(qr/tobykeith\.doc/);
} 'dies with no publish object';

sub ffr { File::Find::Rule->file->unversioned_name( $publisher, qr/tobykeith\.doc/) };
my @set1 = normalize( ffr()->in( $tempdir ) );
is_deeply(\@set1,
          [
           'ABC/GHI/old/tobykeith.v1.doc.<timestamp>',
           'ABC/GHI/tobykeith.v2.doc',
           'ABC/JKL/tobykeith.v1.doc',
           'DEF/GHI/tobykeith.v1.doc',
           'DEF/JKL/tobykeith.v1.doc'
          ],
          'got correct results for set 1',
         )
    or diag Dumper \@set1;

my @set2 = normalize( ffr()->version_is_obsolete($publisher,1)->in( $tempdir ) );
is_deeply(\@set2,
          [
           'ABC/GHI/old/tobykeith.v1.doc.<timestamp>',
          ],
          'got correct results for set 2',
         )
    or diag Dumper \@set2;

my @set3 = normalize( ffr()->version_is_obsolete($publisher,0)->in( $tempdir ) );
is_deeply(\@set3,
          [
           'ABC/GHI/tobykeith.v2.doc',
           'ABC/JKL/tobykeith.v1.doc',
           'DEF/GHI/tobykeith.v1.doc',
           'DEF/JKL/tobykeith.v1.doc'
          ],
          'got correct results for set 3',
         )
    or diag Dumper \@set3;

my @set4 = normalize( ffr()->unversioned_dir($publisher,qr/GHI$/)->in( $tempdir ) );
is_deeply(\@set4,
          [
           'ABC/GHI/old/tobykeith.v1.doc.<timestamp>',
           'ABC/GHI/tobykeith.v2.doc',
           'DEF/GHI/tobykeith.v1.doc',
          ],
          'got correct results for set 4',
         )
    or diag Dumper \@set4;


# normalizes a list of versioned filename so we can test them reliably
sub normalize {
    for( @_ ) { #remove the tempdir from the filenames
        s/$tempdir\/?//;
        s/\.\d+$/.<timestamp>/;
    }

    return sort @_;
}
