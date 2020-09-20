use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::substring;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0106';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__substring($self, $column_name, $value, $params, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('substring', $value);
    $self->smooth__lookup_util__ensure_param_count('substring', $params, { at_least => 1, at_most => 2, regex => qr/^\-?\d+$/ });

    if(scalar $params->@* < 1 || scalar $params->@* > 2) {
        confess sprintf 'substring expects one or two params, got <%s>', join (', ' => $params->@*);
    }
    my @secure_params = grep { /^\-?\d+$/ } $params->@*;
    if(scalar @secure_params != scalar $params->@*) {
        confess sprintf 'substring got faulty params: <%s>', join (', ' => $params->@*);
    }

    my $param_string = join ', ' => @secure_params;

    return { left_hand_function => { start => 'SUBSTRING(', end => ", $param_string)" } , value => $value };
}

1;
