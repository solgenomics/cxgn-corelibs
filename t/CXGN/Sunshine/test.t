
use strict;

use CXGN::Sunshine::Browser;
use CXGN::Sunshine::Node;

my $b = CXGN::Sunshine::Browser->new();
$b->build_graph("1");
my $ref_node = $b->get_node("1");
$b->set_reference_node($ref_node);
$b->set_level_depth(3);
$b->layout();
$b->render();

#print STDERR $b->render_string();
print STDERR $b->get_image_map("clickmap");
