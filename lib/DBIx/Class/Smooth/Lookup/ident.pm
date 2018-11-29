use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::ident;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__ident($self, $column, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('ident', $value);

    my($possible_relation, $possible_column) = split /\./, $value;
    $possible_relation = undef if $possible_relation eq 'me';

    if($possible_relation && $possible_column) {
        if($self->result_source->has_relationship($possible_relation)) {
            if($self->result_source->relationship_info($possible_relation)->{'class'}->has_column($possible_column)) {
                $value = "$possible_relation.$possible_column";
            }
            else {
                confess "<ident> got '$value'; column '$possible_column' does not exist in '$possible_relation";
            }
        }
        else {
            confess "<ident> got '$value', relation '$possible_relation' does not exist in the current result source";
        }
    }
    else {
        $possible_column = $possible_relation if !$possible_column;
        if($self->result_source->has_column($possible_column)) {
            $value = $self->current_source_alias . ".$possible_column";
        }
        else {
            confess "<ident> got '$value', column '$possible_column' does not exist in the current result source"
        }
    }

    return { sql_operator => '=', value => $self->result_source->storage->sql_maker->_quote($value), quote_value => 0 };
}

1;
