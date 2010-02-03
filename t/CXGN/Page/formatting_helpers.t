#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Data::Dumper;


use_ok( 'CXGN::Page::FormattingHelpers',
	qw(
	   commify_number
	   columnar_table_html
	   conditional_like_input_html
	   truncate_string
	   multilevel_mode_selector_html
	   info_section_html
           simple_selectbox_html
	  )
      );

#test commify_number
is( commify_number(0) , '0', 'commify 0');
is( commify_number(1_234_124), '1,234,124', 'commify 1,234,124');

like( columnar_table_html( headings => ['foo', undef, undef, 'bar', undef, undef],
			   data => [['1', '2', '3', '4','5']]
			 ),
      qr/<table/,
       'columnar_table_html does not crash and makes some kind of table',
     );

#test conditional_like_input_html
my $htm = conditional_like_input_html('monkeys','starts_with','tumorvirus');
#diag $htm,"and that was a test of conditional_like_input_html";


#test truncate_string
my @trunctests = ( [ 'is omitted, returns everything to the end of the string.  If LENGTH is negative,', undef, undef, 'is omitted, returns everything to the end of the s&hellip;' ],
		   [ 'my lovely lady lumps', undef, undef, 'my lovely lady lumps' ],
		   [ 'my lovely lady lumps', 5, 'XX', 'my loXX' ],
		 );

foreach my $t (@trunctests) {
  is( truncate_string( @{$t}[0..2] ), $t->[3]);
}


my $selected_levels = [];
my $entry = { wall => { street => { text => 'nooj',
				    ding_dong => { zap => { zowee => {text => 'foo'}}}}}};
ok( CXGN::Page::FormattingHelpers::_ml_find_active('wall',$entry->{wall},'','wall_street_ding_dong_zap_zowee',$selected_levels), 'test multilevel select box helper')
  or diag Dumper($selected_levels);
ok( CXGN::Page::FormattingHelpers::_ml_find_active('',$entry,'','wall_street_ding_dong_zap_zowee',$selected_levels), 'test multilevel select box helper')
  or diag Dumper($selected_levels);
$selected_levels = [];
ok( ! CXGN::Page::FormattingHelpers::_ml_find_active('wall',$entry,'','wall_street_ding_dong_zap',$selected_levels), 'test multilevel select box helper')
  or diag Dumper($selected_levels);


my ($sel_html, @sel_levels) = multilevel_mode_selector_html(<<EOC,'foo_ish_bar');
<foo>
  text "This is a Foo"
  <bar>
    text "FooBar"
  </bar>
  <baz>
    text "FooBaz"
    <luhrman>
      text "Baz Luhrman"
    </luhrman>
  </baz>
  <ish>
    text "FooIsh"
    <bar>
      text "FooIshBar"
      tooltip "This is a fooish bar"
    </bar>
    <beast>
      text "And the Beast"
    </beast>
  </ish>
</foo>
EOC

like $sel_html, qr/script/, 'multilevel mode selector html looks like it returned something possibly maybe valid';

like info_section_html( title => 'Test Title', contents => 'these are the test contents', align => 'center' ), qr/infosectioncontent"\s+style="text-align:\s+center"/, 'info_section_html with no align arg does not return a style section on the infosectioncontentdiv';
like info_section_html( title => 'Test Title', contents => 'these are the test contents' ), qr/infosectioncontent"\s+>/, 'info_section_html with an align arg DOES return a style section on the infosectioncontent div';


my $select = simple_selectbox_html( name => 'fooey',
                                    choices =>   [  '__Group 1',
                                                    'choice1',
                                                    [2, 'choice2'],
                                                    'choice3',
                                                    '__Group 2',
                                                    'choice4',
                                                 ],
                                  );

like( $select, qr/<select\s[^>]*name="fooey"/, 'select with name fooey' );
like( $select, qr/<optgroup\s[^>]*label="Group 1"/, 'got optgroup 1' );
like( $select, qr/<optgroup\s[^>]*label="Group 2"/, 'got optgroup 2' );
like( $select, qr!<option\s+value="choice3".+choice3</option>!, 'got choice3' );
for my $tag (qw/select option optgroup/) {
    my $open = my @o = $select =~ /<$tag/g;
    my $close = my @c = $select =~ m!</$tag!g;
    is( $open, $close, "<$tag> tags in selectbox are balanced" );
}

