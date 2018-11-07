use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::year;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__year($self, $column_name, $value) {
    return { left_hand_function => { name => 'YEAR' }, value => $value };
=pod
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
=cut
}

1;
