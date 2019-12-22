use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Util;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0103';

use parent qw/
    DBIx::Class::Smooth::ResultSetBase
/;
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup_util__ensure_value_is_arrayref($self, $lookup_name, $value) {
    if(ref $value ne 'ARRAY') {
        confess sprintf '<%s> expects an array, got <%s>', $lookup_name, $value;
    }
}

sub smooth__lookup_util__ensure_value_is_scalar($self, $lookup_name, $value) {
    if(ref $value) {
        confess sprintf '<%s> expects a scalar, got a <%s>', $lookup_name, ref($value);
    }
}

sub smooth__lookup_util__ensure_param_count($self, $lookup_name, $params, $ensure_options) {
    my $at_least = delete $ensure_options->{'at_least'} || 0;
    my $at_most = delete $ensure_options->{'at_most'} || 10000;
    my $regex = delete $ensure_options->{'regex'} || undef;

    if(keys $ensure_options->%*) {
        confess sprintf "Unexpected keys <%s>", join(', ', sort keys $ensure_options->%*);
    }

    if(scalar $params->@* < $at_least || scalar $params->@* > $at_most) {
        confess sprintf "<%s> expects between $at_least and $at_most params, got %d: <%s>", $lookup_name, scalar ($params->@*), join (', ' => $params->@*);
    }

    if($regex) {
        my @correct_params = grep { /$regex/ } $params->@*;
        if(scalar @correct_params != scalar $params->@*) {
            confess sprintf '<%s> got faulty params, check documentation: <%s>', $lookup_name, join (', ' => $params->@*);
        }
    }
}

1;
