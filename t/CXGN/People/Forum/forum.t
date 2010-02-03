
use strict;

use Test::More qw | no_plan |;

use CXGN::DB::Connection;
use CXGN::People::Forum::Topic;
use CXGN::People::Forum::Post;

CXGN::DB::Connection->verbose(0);
my $dbh = CXGN::DB::Connection->new();

eval { 

    my $topic = CXGN::People::Forum::Topic->new($dbh);
    $topic->set_topic_name("A test topic");
    $topic->set_topic_description("A test description");
    $topic->set_person_id(222);
    my $new_topic_id = $topic->store();

    my $post = CXGN::People::Forum::Post->new($dbh);
    $post->set_post_text("This is a post.");
    $post->set_forum_topic_id($new_topic_id);
    $post->set_person_id(222);
    $post->store();

    my $another_post = CXGN::People::Forum::Post->new($dbh);
    $another_post->set_post_text("This is another post");
    $another_post->set_forum_topic_id($new_topic_id);
    $another_post->set_person_id(222);
    $another_post->store();

    my $test_topic = CXGN::People::Forum::Topic->new($dbh, $new_topic_id);
    is($test_topic->get_topic_name(), "A test topic", "topic name test");
    is($test_topic->get_topic_description(), "A test description", "topic description test");
    is($test_topic->get_post_count(), 2, "topic post count test");
    
    my @posts = $test_topic->get_all_posts();
    is($posts[0]->get_post_text(), "This is a post.", "post text test 1");
    is($posts[0]->get_person_id(), 222, "poster id 1 test");
    is($posts[1]->get_post_text(), "This is another post", "post text test 2");
    is($posts[1]->get_person_id(), 222, "poster id 2 test");

    $posts[0]->delete();
    
    is($test_topic->get_post_count(), 1, "post delete test");
    

};

if ($@) { 
    print "An error occurred: $@\n";
}
$dbh->rollback();
