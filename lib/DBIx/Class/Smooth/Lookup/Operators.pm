use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0108';

use parent qw/
    DBIx::Class::Smooth::Lookup::Operators::gt
    DBIx::Class::Smooth::Lookup::Operators::gte
    DBIx::Class::Smooth::Lookup::Operators::lt
    DBIx::Class::Smooth::Lookup::Operators::lte
    DBIx::Class::Smooth::Lookup::Operators::in
    DBIx::Class::Smooth::Lookup::Operators::like
    DBIx::Class::Smooth::Lookup::Operators::not_in
/;

1;
