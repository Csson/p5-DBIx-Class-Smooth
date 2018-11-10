use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent qw/
    DBIx::Class::Smooth::Lookup::Operators::in
    DBIx::Class::Smooth::Lookup::Operators::like
    DBIx::Class::Smooth::Lookup::Operators::not_in
/;

1;
