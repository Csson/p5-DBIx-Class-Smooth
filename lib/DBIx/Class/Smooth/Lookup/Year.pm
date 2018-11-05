use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Year;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub lookup__year($self, $key, $value) {
    my $changed_key = $key =~ s{__year$}{}r;
    if(ref $value) {
        if(ref $value eq 'HASH' && scalar keys $value->%* == 1) {
            if(exists $value->{'-like'}) {
                return (undef, \["YEAR($changed_key) LIKE ?", $value->{'-like'}]);
            }
        }
    }
    else {
        return (undef, \["YEAR($changed_key) = ?", $value]);
    }
}

1;
