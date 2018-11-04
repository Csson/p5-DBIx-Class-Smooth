use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::NotIn;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub lookup__not_in($self, $column, $value) {
    return ($column, { -not_in => $value });
}

1;
