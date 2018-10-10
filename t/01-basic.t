use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use DBIx::Class::Smooth;
ok 1, 'Loaded';

done_testing;
