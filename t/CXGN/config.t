#!/usr/bin/env perl
use strict;
use warnings;
use English;

use File::Temp;
use Path::Class;

use Test::More tests => 51;
use Test::Exception;

use Memoize;

BEGIN {
  use_ok(  'CXGN::Config'  )
    or BAIL_OUT('could not include the module being tested');
}

my $tempdir = File::Temp->newdir;

{ # test a bare config superclass
    local $CXGN::Config::defaults = {
                                     test1 => 'foo',
                                     test2 => 'bar',
                                    };

    # unset the search path to prevent loading any config files, just defaults
    local @CXGN::Config::search_path = ( );

    my $cfg = CXGN::Config->load;
    ok( defined($cfg), 'got back a config' );
    is_deeply($cfg, $CXGN::Config::defaults, 'got just default values');
}

{

    local $CXGN::Config::defaults = {
                                     test1 => 'foo',
                                     test2 => 'bar',
                                    };

    # set the search path to prevent loading any config files except the test ones (if any)
    local @CXGN::Config::search_path = ( $tempdir );

    { my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults};
      test_cfg( class => 'Foo::Config::Bar', load => $d, defaults => $d );
    }

    { my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults, %$MyConfig::test_defaults };
      test_cfg( class => 'MyConfig', load => $d, defaults => $d );
    }


    my $global_file   = file( $tempdir, 'Global.conf' );
    my $bar_file      = file( $tempdir, 'Foo.conf'  );
    my $myconfig_file = file( $tempdir, 'MyConfig.conf' );
    $myconfig_file->touch;

    { my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults, %$MyConfig::test_defaults };
      test_cfg( class => 'MyConfig', load => $d, defaults => $d );
    }

    my $myconfig_vals = {  test1 => 'needle', test2 => 'haystack' };
    $myconfig_file->openw->print(map "$_  $myconfig_vals->{$_}\n", keys %$myconfig_vals);

    {
      my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults, %$MyConfig::test_defaults};
      my $l = { %$d, %$myconfig_vals };
      test_cfg( class => 'MyConfig', load => $l, defaults => $d );
    }

    $bar_file->openw->print("fog boo baz beep\n");

    { my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults};
      my $l = {%$d, fog => 'boo baz beep'};
      test_cfg( class => 'Foo::Config::Bar', load => $l, defaults => $d );
    }

    my $global_vals = { global1 => 13244, global8 => 'asdlkajg' };
    $global_file->openw->print(map "$_  $global_vals->{$_}\n", keys %$global_vals);

    {
      my $d = {%$CXGN::Config::defaults, %$Foo::Config::Bar::test_defaults, %$MyConfig::test_defaults};
      my $l = { %$d, %$global_vals, %$myconfig_vals };
      test_cfg( class => 'MyConfig', load => $l, defaults => $d );
    }

}


########### SUBS

sub test_cfg {
    my %a = @_;

    Memoize::flush_cache('CXGN::Config::load_locked'); #< clear Memoize-cached data

    is_deeply($a{class}->load, $a{load}, "$a{class}: got the right defaults from load");
    is_deeply($a{class}->load_locked, $a{load}, "$a{class}: got the right defaults from load_locked");
    is_deeply($a{class}->defaults, $a{defaults}, "$a{class}: got the right defaults from the defaults() method");
    my $merge = {foofoofoofoo => 'booze'};
    is_deeply($a{class}->defaults($merge), {%{$a{defaults}}, %$merge}, "$a{class}: defaults() method merges config");

    my $add_vals = { fonebone => 'tonka truck' };
    is_deeply($a{class}->load(add_vals => $add_vals), {%{$a{load}},%$add_vals}, "$a{class}: got the right defaults from load with add_vals");

    my $locked = $a{class}->load_locked( add_vals => { writeme => 'boo' });
    throws_ok {
        my $v = $locked->{doesnotexist};
    } qr/disallowed/i, 'throws an error accessing nonexistent key in hash from load_locked';
    throws_ok {
        $locked->{writeme} = 'bar';
    } qr/modification/i, 'throws an error writing to locked hash';
    is( $locked->{writeme}, 'boo' );
}


BEGIN { # some test config subclasses
    package Foo::Config::Bar;
    use base 'CXGN::Config';

    our $test_defaults = { bee => 'bo', 'bar' => __PACKAGE__};
    sub defaults {
        shift->SUPER::defaults( $test_defaults, @_ );
    }

    package MyConfig;
    use base 'Foo::Config::Bar';

    our $test_defaults = { noggin => 'nudge', bunk => ['booz','noggin',{ fooish => 'bar'},] };
    sub defaults {
        shift->SUPER::defaults( $test_defaults, @_ );
    }
}
