use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::gte;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0105';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__gte($self, $column_name, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('gte', $value);

    return { sql_operator => '>=', operator => '>=', value => $value };
}

1;
