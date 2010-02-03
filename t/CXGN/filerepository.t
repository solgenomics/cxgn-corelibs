#!/usr/bin/env perl
use strict;
use warnings;
use English;

use File::Temp;
use Test::More tests => 34;
use Test::Exception;

use Path::Class;

use Data::Dumper;

use CXGN::Genomic::Clone;


BEGIN {
    my $repos_class = 'CXGN::FileRepository';
    use_ok( $repos_class )
        or BAIL_OUT('could not include the module being tested');
}


{ package TestRepos;
  use Moose;
  extends 'CXGN::FileRepository';

  # some other junk that we need to make sure the the fileclass finder
  # does not find
  package TestRepos::FileClass;
  my $some_junk = 0;
  sub junk {}
  sub new { Carp::confess __PACKAGE__.' should be skipped!' }
  package TestRepos::FileClass::BadBase;
  sub new { Carp::confess __PACKAGE__.' should be skipped!' }

  package TestRepos::FileClass::TestClass;
  use Moose;

  # just returns a separate VersionedFile for each condition value
  sub search_vfs {
      my ($self, %conditions) = @_;

      return $self->get_vf(%conditions);
  }

  sub get_vf {
      my ($self, %conditions) = @_;
      my @keys = sort keys %conditions;
      die unless @keys > 1;

      return $self->vf( @conditions{@keys} );
  }

  with 'CXGN::FileRepository::FileClass';

  package TestRepos::FileClass::FooFoo;
  use Moose;

  # always finds foofoofoo! regardless of condition
  sub search_vfs {
      shift->get_vf(@_);
  }

  sub get_vf {
      shift->vf( 'foofoofoo!' );
  }

  with 'CXGN::FileRepository::FileClass';

  package TestReposWithNoFileClasses;
  use Moose;
  extends 'CXGN::FileRepository';

}


my $test_dir =  File::Temp->newdir;

my $repos_dir_1 = "$test_dir/test1";

throws_ok {
    TestRepos->new( basedir => $repos_dir_1 );
} qr/does not exist/, 'nonexistent basedir with no create dies';


my $repos = TestRepos->new( basedir => $repos_dir_1, create => 1 );
ok( -d $repos_dir_1, 'repos dir was made with create' );
is( $repos->create, 1, 'create flag is set');
isa_ok( $repos->publisher, 'CXGN::Publish', 'has a publisher object');

my @classes = $repos->file_classes;
is( scalar( @classes ), 2, 'file_classes returned something' )
    or diag @classes;
ok( $classes[0]->does('CXGN::FileRepository::FileClass'), 'it does the FileClass role' );

my $repos_dir_2 = Path::Class::Dir->new($test_dir)->subdir('test2');
$repos = TestRepos->new( basedir => $repos_dir_2, create => 1 );
isa_ok( $repos->publisher, 'CXGN::Publish', 'has a publisher object');
ok( -d $repos_dir_2, 'create also works with Path::Class::Dir object passed' );


{
    my @results = $repos->search_vfs( foo => 'test1.txt', bar => 'test2.txt' );
    is(scalar(@results),2,'should get 2 results back from vfs search')
        or diag 'actual results: '.Dumper \@results;
    for (@results) {
        ok( $_->file_class->does('CXGN::FileRepository::FileClass'),'vf has a file_class');
        isa_ok( $_->repository, 'TestRepos','vf has the first repos');
        is( $_->current_file, undef, 'should not have current file');
    }
    is(scalar(grep {$_->unversioned_path =~ /foofoofoo!$/} @results), 1, 'got 1 foofoo');
}

{
    my @results = $repos->search_vfs( class => 'TestClass', foo => 'test1.txt', bar => 'test2.txt' );
    is(scalar(@results),1,'should get 1 result back from vfs search');
    for (@results) {
        ok( $_->file_class->does('CXGN::FileRepository::FileClass'),'vf has a file_class');
        isa_ok( $_->repository, 'TestRepos','vf has the first repos');
        is( $_->current_file, undef, 'should not have current file');
    }

}

{
    my $result = $repos->get_vf( class => 'TestClass', foo => 'test1', bar => 'test2' );
    isa_ok( $result, 'CXGN::FileRepository::VersionedFile' );

    ok( $result->file_class->does('CXGN::FileRepository::FileClass'),'vf has a file_class');
    isa_ok( $result->repository, 'TestRepos','vf has a repos');
    is( $result->current_file, undef, 'should not have current file');

    dies_ok {
        $repos->get_vf(qw| foo bar baz boo |);
    } 'get_vf dies without fileclass arg';

    $repos->publish( $result->publish_new_version( File::Temp->new ) );


    $result = $repos->get_vf( class => 'TestClass', foo => 'test1', bar => 'test2' );
    isa_ok( $result->current_file, 'Path::Class::File', 'should have current file');
    ok( -f $result->current_file->stringify, 'and file exists' );

    my $file = $repos->get_file( class => 'TestClass', foo => 'test1', bar => 'test2' );
    isa_ok( $file, 'Path::Class::File' );
    ok( -f "$file", 'file exists');

    my @vfs = $repos->search_vfs( foo => 'test1', bar => 'test2' );
    is( scalar(@vfs), 2, 'got correct vf count from search_vfs' );
    is( scalar(grep $_->current_file, @vfs), 1, 'one of which has a current version' );

    my @files = $repos->search_files( foo => 'test1', bar => 'test2' );
    is( scalar(@files), 1, 'got correct file count from search_files' );
    ok( -f "$files[0]", 'file from search_files exists' );
}
