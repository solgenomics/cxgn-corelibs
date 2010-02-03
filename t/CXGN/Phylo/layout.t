
# Lukas, May 12, 2009.

use strict;

use Test::More tests => 12 ;

BEGIN { 
    use_ok("CXGN::Phylo::Layout");
    use_ok("CXGN::Phylo::Parser");
};

my $lo = CXGN::Phylo::Layout->new();

$lo->set_image_width(200);
$lo->set_image_height(100);
$lo->set_top_margin(10);
$lo->set_bottom_margin(10);
$lo->set_left_margin(10);
$lo->set_right_margin(10);

my $t = CXGN::Phylo::Parse_newick->new("((A, B), (C, D))")->parse();

$lo->set_tree($t);

$lo->layout();

my $r = $t->get_root();

my %nodes = ();

my %exp = ( A => { h => 190, v=> 10 }, B=> {h => 190, v=>36}, C=>{h=>190, v=>63}, D=>{h=>190, v=>90} );

foreach my $name qw | A B C D | { 
    $nodes{$name} = $t->get_node_by_name($name);
    #print STDERR $nodes{$name}->get_horizontal_coord().", ".$nodes{$name}->get_vertical_coord()."\n";
    is($nodes{$name}->get_horizontal_coord(), $exp{$name}->{h}, "horizontal coord test for $name");
    is($nodes{$name}->get_vertical_coord(), $exp{$name}->{v}, "vertical coord test for $name");
}

is($t->get_root()->get_horizontal_coord(), 10, "root horizontal coord test");
is($t->get_root()->get_vertical_coord(), 49, "root vertical coord test");


    

