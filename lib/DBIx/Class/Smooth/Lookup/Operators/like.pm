use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::like;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__like($self, $column_name, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('like', $value);

    return { left_hand_prefix => 'BINARY', sql_operator => 'LIKE', value => "%$value%" };
}

1;
