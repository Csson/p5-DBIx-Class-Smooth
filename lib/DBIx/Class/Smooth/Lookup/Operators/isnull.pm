use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::isnull;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__isnull($self, $column, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('isnull', $value);

    # NOT WORKING
    if (!!$value) {
        return { operator => '=', value => undef };
    }
    else {
        return { operator => '!=', value => undef };
    }
}

1;
