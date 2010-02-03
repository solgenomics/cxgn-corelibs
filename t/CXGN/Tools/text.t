#!/usr/bin/env perl
use strict;

BEGIN {
  our @ts_tests = ( [ 'monkey in the middle',
		      'monkey&in&the&middle' ],
		    [ 'gi|b4ogus123|blah: is bogus',
		      'gi\\|b4ogus123\\|blah\\:&is&bogus'],
		    [ 'gi|b4ogus123|blah is bogus & (I hate it)!',
		      'gi\\|b4ogus123\\|blah&is&bogus&\\\\&&\\(I&hate&it\\)\\\\!'],
		  );
  our @trim_tests = ( [" \thoog",'hoog'],
		      ["  monkey in the middle   ",'monkey in the middle'],
		      ["block  \t",'block'],
		    );

  our @pgarray_tests = (
			['{1,2,3,4}',[1,2,3,4]],
			['{"1,2","3,4"}',['1,2','3,4']],
			['',[]],
		       );
}
our @ts_tests;
use Test::More tests => scalar(@ts_tests) + 2*scalar(@ts_tests) + scalar(our @pgarray_tests) + 5;

use CXGN::Tools::Text qw/to_tsquery_string from_tsquery_string trim parse_pg_arraystr commify_number truncate_string/;

#test trim
foreach my $test (our @trim_tests) {
  is(trim($test->[0]),$test->[1],'test trim');
}


foreach my $test (@ts_tests) {
  my ($from,$to) = @$test;
  is(to_tsquery_string($from),$to,"to_tsquery '$from'->'$to'");
}

foreach my $test (@ts_tests) {
  my ($from,$to) = @$test;
  is(from_tsquery_string($to),$from,"from_tsquery '$to'->'$from'");
}

foreach my $test (our @pgarray_tests) {
  my ($from,$to) = @$test;
  is_deeply(parse_pg_arraystr($from),$to,"parse_pg_arraystr('$from')");
}


#test truncate_string
my @trunctests = ( [ 'is omitted, returns everything to the end of the string.  If LENGTH is negative,', undef, undef, 'is omitted, returns everything to the end of the s...' ],
		   [ 'my lovely lady lumps', undef, undef, 'my lovely lady lumps' ],
		   [ 'my lovely lady lumps', 5, 'XX', 'my loXX' ],
		 );

foreach my $t (@trunctests) {
  is( truncate_string( @{$t}[0..2] ), $t->[3]);
}

#test commify_number
is( commify_number(0) , '0', 'commify 0');
is( commify_number(1_234_124), '1,234,124', 'commify 1,234,124');
