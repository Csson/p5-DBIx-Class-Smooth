use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::lte;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__lte($self, $column_name, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('lte', $value);

    return { sql_operator => '<=', operator => '<=', value => $value };
}

1;
