use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::in;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__in($self, $column, $value, @rest) {
    if(ref $value ne 'ARRAY') {
        die '<in> expects an array';
    }

    return { sql_operator => 'IN', operator => '-in', value => $value };
}

1;
