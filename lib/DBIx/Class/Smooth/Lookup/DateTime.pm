use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0108';

use parent qw/
    DBIx::Class::Smooth::Lookup::DateTime::year
    DBIx::Class::Smooth::Lookup::DateTime::month
    DBIx::Class::Smooth::Lookup::DateTime::day
    DBIx::Class::Smooth::Lookup::DateTime::hour
    DBIx::Class::Smooth::Lookup::DateTime::minute
    DBIx::Class::Smooth::Lookup::DateTime::second
    DBIx::Class::Smooth::Lookup::DateTime::datepart
/;

1;
