use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::like;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__like($self, $column_name, $value, @rest) {
    if(ref $value) {
        die 'like expects a string';
    }
    return { left_hand_prefix => 'BINARY', sql_operator => 'LIKE', value => $value };
}

1;
