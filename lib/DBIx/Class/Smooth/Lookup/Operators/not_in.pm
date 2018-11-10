use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::not_in;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__not_in($self, $column, $value, @rest) {
    if(ref $value ne 'ARRAY') {
        die 'not_in expects an array';
    }

    return { sql_operator => 'NOT IN', operator => '-not_in', value => $value };
}

1;
