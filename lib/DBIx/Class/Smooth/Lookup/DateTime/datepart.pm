use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::datepart;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0107';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/carp confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__datepart($self, $column_name, $value, $params, @rest) {
    my $datepart = $params->[0];
    $self->smooth__lookup_util__ensure_param_count($datepart, $params, { at_least => 1, at_most => 1, regex => qr/^[a-z_]+$/i });


    local $SIG{'__WARN__'} = sub ($message) {
        if($message =~ m{uninitialized value within %part_map}) {
            confess "<datepart> was passed <$datepart> as the datepart, but your database don't support that";
        }
        else {
            warn $message;
        }
    };

    my $complete = $self->dt_SQL_pluck({ -ident => $column_name }, $datepart);

    my $function_call_string = $complete->$*->[0];

    return { left_hand_function => { complete => $function_call_string }, value => $value };
}

1;
