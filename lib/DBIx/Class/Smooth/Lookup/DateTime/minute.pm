use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::minute;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::Lookup::DateTime::datepart';
use experimental qw/signatures postderef/;

sub smooth__lookup__minute($self, $column_name, $value, @rest) {
    return $self->smooth__lookup__datepart($column_name, $value, ['minute']);
}

1;
