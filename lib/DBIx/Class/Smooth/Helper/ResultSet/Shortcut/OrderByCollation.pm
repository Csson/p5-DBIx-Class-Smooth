use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::OrderByCollation;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

# This only expects calls like ->order_by_collation('utf8mb4_swedish_ci', 'name', '!other_name')
sub order_by_collation($self, $collation, @column_names) {

    if(!defined $collation) {
        return $self->order_by(@column_names);
    }

    my $sql_order_by_args = join ', ' => map { $self->smooth__helper__orderbycollation__prepare_for_sql($collation, $_) } @column_names;

    return $self->search(undef, { order_by => \$sql_order_by_args });
}

# This is based on DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic::order_by
sub smooth__helper__orderbycollation__prepare_for_sql($self, $collation, $column_name) {
    my $direction = 'ASC';
    if(substr($column_name, 0, 1) eq '!') {
        $column_name = substr $column_name, 1;
        $direction = 'DESC';
    }

    if(index($column_name, '.') == -1) {
        $column_name = join '.' => ($self->current_source_alias, $column_name);
    }

    return "$column_name COLLATE $collation $direction";
}

1;
