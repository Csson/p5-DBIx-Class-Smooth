use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::not_in;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0105';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__not_in($self, $column, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_arrayref('not_in', $value);

    return { sql_operator => 'NOT IN', operator => '-not_in', value => $value };
}

1;
