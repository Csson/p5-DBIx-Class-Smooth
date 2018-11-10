use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use TestFor::DBIx::Class::Smooth::Schema;
use experimental qw/postderef/;

my $schema = TestFor::DBIx::Class::Smooth::Schema->connect();

isa_ok $schema, 'DBIx::Class::Schema';


my $tests = [
    {
        test => q{ $schema->Book->except_titles('Silmarillion') },
        result => [title => { -not_in => ['Silmarillion']}],
    }
];

for my $test (@{ $tests }) {
    next if !length $test->{'test'};
    my $got = eval($test->{'test'})->value;
    is_deeply $got, $test->{'result'}, $test->{'test'} or diag explain $got;
}


done_testing;
