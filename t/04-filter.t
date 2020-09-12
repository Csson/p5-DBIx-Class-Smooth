use strict;
use warnings;
use 5.20.0;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DateTime;
use Module::Load;
use TestFor::DBIx::Class::Smooth::Schema;
use experimental qw/postderef/;

my $schema;

if($ENV{'DBIC_SMOOTH_SCHEMA'}) {
    load $ENV{'DBIC_SMOOTH_SCHEMA'};
    $schema = $ENV{'DBIC_SMOOTH_SCHEMA'}->connect();
}
else {
    $schema = TestFor::DBIx::Class::Smooth::Schema->connect();
}

isa_ok $schema, 'DBIx::Class::Schema';

my $tests = [
    {
        name => 'not in',
        test => $schema->Book->except_titles('Silmarillion'),
        result => ['me.title' => { -not_in => ['Silmarillion']}],
    },
    {
        name => 'column in relation',
        test => $schema->Author->_smooth__prepare_for_filter(country__name => 'Sweden'),
        result => ['country.name' => 'Sweden'],
    },
    {
        name => "column in relation's relation",
        test => $schema->Book->_smooth__prepare_for_filter(book_authors__author__country__name => 'Sweden'),
        result => ['country.name' => 'Sweden'],
    },
    {
        name => 'substring',
        test => $schema->Book->_smooth__prepare_for_filter('book_authors__author__country__name__substring(2, 4)' => 'wede'),
        result => [ \[ 'SUBSTRING(country.name, 2, 4) =  ? ', 'wede' ] ],
    },
    {
        name => 'substring substring',
        test => $schema->Book->_smooth__prepare_for_filter('book_authors__author__country__name__substring(2, 4)__substring(1, 2)' => 'we'),
        result => [ \[ 'SUBSTRING(SUBSTRING(country.name, 2, 4), 1, 2) =  ? ', 'wede' ] ],
    },
    {
        name => 'lt',
        test => $schema->Book->_smooth__prepare_for_filter(book_authors__author__country__created_date_time__lt => '2020-01-01'),
        result => [ 'country.created_date_time' => { '<' => '2020-01-01' } ],
    },
    {
        name => 'ident',
        test => $schema->Book->_smooth__prepare_for_filter(book_authors__author__country__name__ident => 'me.title'),
        result => [ 'country.name' => { -ident => 'me.title' } ],
    },
];


for my $test (@{ $tests }) {
    my $got = $test->{'test'};
    is_deeply $got, $test->{'result'}, $test->{'name'} or diag explain $got;
}

done_testing;
