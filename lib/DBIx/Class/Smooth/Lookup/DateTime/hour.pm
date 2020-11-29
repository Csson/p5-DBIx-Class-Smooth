use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::hour;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Smooth::Lookup::DateTime::datepart';
use experimental qw/signatures postderef/;

sub smooth__lookup__hour($self, $column_name, $value, @rest) {
    return $self->smooth__lookup__datepart($column_name, $value, ['hour']);
}

1;
