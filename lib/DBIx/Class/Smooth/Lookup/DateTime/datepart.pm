use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::datepart;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Smooth::ResultSet::Base';
use experimental qw/signatures postderef/;

sub smooth__lookup__datepart($self, $column_name, $value, $params, @rest) {
    if(scalar $params->@* != 1) {
        die sprintf 'substring expects exactly one params, got <%s>', join (', ' => $params->@*);
    }

    my @secure_params = grep { /^[a-z_]+$/i } $params->@*;
    if(scalar @secure_params != scalar $params->@*) {
        die sprintf 'datepart got faulty params: <%s>', join (', ' => $params->@*);
    }
    my $complete = $self->dt_SQL_pluck({ -ident => $column_name }, $params->[0]);

    return { left_hand_function => { complete => $complete->$*->[0] }, value => $value };
}

1;
