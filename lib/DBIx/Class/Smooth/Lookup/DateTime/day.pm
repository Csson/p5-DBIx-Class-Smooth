use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::day;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0104';

use parent 'DBIx::Class::Smooth::Lookup::DateTime::datepart';
use experimental qw/signatures postderef/;

sub smooth__lookup__day($self, $column_name, $value, @rest) {
    return $self->smooth__lookup__datepart($column_name, $value, ['day_of_month']);
}

1;
