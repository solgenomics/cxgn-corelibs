use strict;
use warnings;
use English;

use Test::More tests => 2;
use Test::Exception;
use Test::Warn;

use_ok(  'CXGN::DB::DBICFactory'  )
    or BAIL_OUT('could not include the module being tested');

# test table name collision warning.  this has to be in a separate
# test file because testing them both in the same file because test
# apparently hits perl bug 52610,
# http://rt.perl.org/rt3/Public/Bug/Display.html?id=52610

My::Schema->load_classes('CollidingTable');
warning_like {
    CXGN::DB::DBICFactory->merge_schemas( schema_classes =>
                                          [ 'Test::Schema::One',
                                            'My::Schema',
                                          ],
                                        );
} qr/both .+ tableone/, 'correct warning for table name collisions';

# schemas and classes for testing
BEGIN {
    package My::Schema::ToBeComposed;
    use strict;
    use warnings;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/Core/);
    __PACKAGE__->table('tobecomposed');
    __PACKAGE__->add_columns(qw/id somethingelse/);
    __PACKAGE__->set_primary_key('id');

    package My::Schema;
    use base 'DBIx::Class::Schema';

    __PACKAGE__->load_classes('ToBeComposed');

    package Test::Schema::One::TableOne;
    use strict;
    use warnings;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/Core/);
    __PACKAGE__->table('tableone');
    __PACKAGE__->add_columns(qw/id somethingelse/);
    __PACKAGE__->set_primary_key('id');

    package Test::Schema::One;
    use base 'DBIx::Class::Schema';

    __PACKAGE__->load_classes('TableOne');


    package My::Schema::CollidingTable;
    use strict;
    use warnings;
    use base 'DBIx::Class';

    __PACKAGE__->load_components(qw/Core/);
    __PACKAGE__->table('tableone');
    __PACKAGE__->add_columns(qw/id somethingelse/);
    __PACKAGE__->set_primary_key('id');

}


