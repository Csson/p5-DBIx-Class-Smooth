use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Like;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub lookup__like($self, $key, $value) {
    if(ref $value) {
        die 'like expects a string';
    }
    $key =~ s{__like$}{};
    return ($key, { -like => $value });
}

1;
