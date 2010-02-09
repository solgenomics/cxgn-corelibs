#!/usr/bin/perl
use strict;
use warnings;
use English;

use Test::More tests => 39;
use Test::Exception;

BEGIN { use_ok( 'CXGN::Tools::List',
		qw(
		   max
		   min
		   all
		   flatten
		   collate
		   str_in
		   distinct
		   balanced_split
		   evens
		   odds
		   index_where
		   list_join
		   group
	          )
	       );
}

is(max(-1,0,2,3,4),4,'max');
is(min(0,-1,2,3,4),-1,'min');
is(max(),undef,'max of empty list is undef');
is(min(),undef,'min of empty list is undef');
is(max(undef),undef,'max of undef is undef');
is(min(undef),undef,'min of undef is undef');

is(all(0,1,1),0,'all 1');
is(all('bleh',undef,'bloo'),0,'all 1');

#test flatten
my @testarr =( ['a','b'],'c',['d',['e','f']],{g => 'h',i=>{j => 'k'}} );
is_deeply( [ flatten @testarr ],
	   [qw/ a b c d e f g h i j k/],
	   'flatten works',
	 );

#test collate
@testarr = (qw/a b c d e f g/);
my @testarr2 = 1..10;

is_deeply( {collate(\@testarr,\@testarr2)},
	   {a=>1,b=>2,c=>3,d=>4,e=>5,f=>6,g=>7},
	   'collate works',
	 );

is_deeply( {collate(\@testarr2,\@testarr)},
	   {reverse a=>1,b=>2,c=>3,d=>4,e=>5,f=>6,g=>7},
	   'collate works',
	 );


is(str_in('foo',qw/foo bar baz/),1,'str_in works');
is(str_in('fog',qw/foo bar baz/),0,'str_in works');

is_deeply([distinct(qw/foo bar foo baz/)],
	  [qw/foo bar baz/],
	  'distinct works',
	 );
is_deeply([distinct(qw/foo bar baz baz/)],
	  [qw/foo bar baz/],
	  'distinct works',
	 );

#test balanced_split
is_deeply(balanced_split(2,[1..10]),
	  [[1..5],[6..10]],
	  'test balanced_split 1');
is_deeply(balanced_split(2,[1,2]),
	  [[1],[2]],
	  'test balanced_split 2');
is_deeply(balanced_split(2,[1]),
	  [[1]],
	  'test balanced_split 3');
is_deeply(balanced_split(3,[1]),
	  [[1]],
	  'test balanced_split 4');
is_deeply(balanced_split(1,[1]),
	  [[1]],
	  'test balanced_split 5');
is_deeply(balanced_split(3,[1..11]),
	  [[1..4],[5..8],[9..11]],
	  'test balanced_split 6');
is_deeply(balanced_split(3,[1..10]),
	  [[1..4],[5..7],[8..10]],
	  'test balanced_split 7');
throws_ok {
  balanced_split(0,[1..10]);
} qr/positive integer/, 'balanced_split with invalid requested pieces dies 1';

throws_ok {
  balanced_split(-10,[1..10]);
} qr/positive integer/, 'balanced_split with invalid requested pieces dies 2';

throws_ok {
  balanced_split(3,1);
} qr/arrayref/, 'balanced_split with invalid list dies';


#test evens and odds
is_deeply([ evens 'foo','bar','baz','bloo','blorg' ],
	  ['foo','baz','blorg'],
	  'evens 1'
	 );
is_deeply([ evens ],
	  [],
	  'evens 2'
	 );
is_deeply([ evens 'foo' ],
	  ['foo'],
	  'evens 3'
	 );

is_deeply([ odds 'foo','bar','baz','bloo','blorg' ],
	  ['bar','bloo'],
	  'odds 1'
	 );
is_deeply([ odds ],
	  [],
	  'odds 2'
	 );
is_deeply([ odds 'foo' ],
	  [],
	  'odds 3'
	 );

#test index_where

is( ( index_where {$_ eq 'monkeys'} qw/monkeys bonobos/),
    0,
    'index_where 1',
  );

is( ( index_where {$_ eq 'monkeys'} qw/foo/),
    -1,
    'index_where 2',
  );

is( ( index_where {$_ eq 'monkeys'} qw//),
    -1,
    'index_where 3',
  );

is( ( index_where {$_ eq 'monkeys'} qw/foo bar baz quux monkeys/),
    4,
    'index_where 4',
  );


#test list_join

is_deeply( [list_join(['a','b'],1..4)],
	   [1,'a','b',2,'a','b',3,'a','b',4]
	 );

is_deeply( [list_join([['c','d']],1..4)],
	   [1,['c','d'],2,['c','d'],3,['c','d'],4]
	 );


#test group
#use Data::Dumper;
#print Dumper ( group { $_ % 4 } 1..10 );
is_deeply( ( group { $_ % 4 } 1..10 ),
	   { 1 => [1,5,9],
	     0 => [4,8],
	     3 => [3,7],
	     2 => [2,6,10],
	   },
	   'group'
         );

