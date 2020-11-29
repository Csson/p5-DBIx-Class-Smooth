use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultSet;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Candy::ResultSet';

sub base {
    (my $base = caller(2)) =~ s{^(.*?)::Schema::ResultSet::.*}{$1};

    return $_[1] || "${base}::Schema::ResultSet";
}
sub perl_version { 20 }

sub experimental { [] }

1;
