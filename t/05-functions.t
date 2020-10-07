use strict;
use warnings;
use 5.20.0;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DateTime;
use DBIx::Class::Smooth::Functions -all;
use experimental qw/postderef signatures/;

BEGIN {
    eval "use Test::mysqld"; if($@) {
        plan skip_all => 'Test::mysqld not installed';
    }
}

use Test::DBIx::Class
    -config_path => [qw/t etc test_fixtures/],
    -traits=>['Testmysqld'];

my $mysqld = Test::mysqld->new(auto_start => undef) or plan skip_all => $Test::mysqld::errstr;

fixtures_ok 'basic';

subtest ascii_ord => sub {
    my $ascii_for_S = 83;
    is Country->annotate(ascii => Ascii('name'))->filter(id => 1)->first->get_column('ascii'), $ascii_for_S;
    is Country->annotate(chr => Char(Ascii('name')))->filter(id => 1)->first->get_column('chr'), 'S';
};



subtest substring => sub {
    my $got = Country->annotate(name_substr => Substring('name', 2, 2));
    is $got->first->get_column('name_substr'), 'we', or diag explain $got->as_query;

    $got = Country->annotate(name_substr => Substring('name', 2));
    is $got->first->get_column('name_substr'), 'weden', or diag explain $got->as_query;

};

done_testing;
