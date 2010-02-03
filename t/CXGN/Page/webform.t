#!/usr/bin/perl
use strict;
use warnings;
use English;

use Test::More tests => 14;

BEGIN {
  use_ok(  'CXGN::Page::WebForm'  );
}

package TestForm1;
use base qw/CXGN::Page::WebForm/;
__PACKAGE__->template(<<EOHTML);
<input name="NAME_holycrap" value="VALUE_holycrap" />
EOHTML

package TestForm2;
use base 'TestForm1';
our $template = <<EOHTML;
<input name="3NAME_nothin" value="5VALUE_nothin" />
EOHTML
__PACKAGE__->template($template);

package main;

my $form = TestForm1->new;
isa_ok($form,'CXGN::Page::WebForm');

like($form->to_html,qr|^<input name="\w+_holycrap" value="" />\n$|,'to_html looks ok');

$form->set_data( holycrap => 'omfgroflolol');
like($form->to_html,qr|^<input name="\w+_holycrap" value="omfgroflolol" />\n$|,'to_html looks ok after setting data');

my $form2 = TestForm2->new(nothin => 'foofoofoo');
isa_ok($form2,'TestForm1');
isa_ok($form2,'CXGN::Page::WebForm');

unlike($form2,qr/foofoofoo/,'did not erroneously interpolate');
is($form2->to_html,$TestForm2::template,'did not interpolate anything, in fact');

eval {
  TestForm2->template('<form action="somewhere" method="GET"><input name="NAME_monkeys" /></form>');
};
ok($EVAL_ERROR,'cannot set templates with <form> in them')
  and diag "Error message was: $EVAL_ERROR";

#test from_request
my $request = { $form->uniqify_name('monkey') => 'barbarbarbarian',
		'a'.$form->uniqify_name('something') => 'this is not yours!',
	      };
$form->from_request( $request );
ok( $form->data('monkey') eq 'barbarbarbarian', 'from_request works 1');
ok(! defined($form->data('something')), 'from_request works 2');


#test same_data_as
ok( ! $form->same_data_as($form2), 'same_data_as 1' );
ok( $form->same_data_as($form), 'same_data_as 2' );

$form->set_data(foofoo => 'quux');

my $form3 = TestForm1->new(monkey => 'barbarbarbarian', foofoo => 'quux');
ok( $form->same_data_as($form3), 'same_data_as 3' );


