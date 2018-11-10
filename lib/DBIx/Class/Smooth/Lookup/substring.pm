use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::substring;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__substring($self, $column_name, $value, $params, @rest) {
    if(ref $value) {
        die 'like expects a string';
    }
    if(scalar $params->@* < 1 || scalar $params->@* > 2) {
        die sprintf 'substring expects one or two params, got <%s>', join (', ' => $params->@*);
    }
    my @secure_params = grep { /^\-?\d+$/ } $params->@*;
    if(scalar @secure_params != scalar $params->@*) {
        die sprintf 'substring got faulty params: <%s>', join (', ' => $params->@*);
    }

    my $param_string = join ', ' => @secure_params;

    return { left_hand_function => { start => 'SUBSTRING(', end => ", $param_string)" } , value => $value };
}

1;
