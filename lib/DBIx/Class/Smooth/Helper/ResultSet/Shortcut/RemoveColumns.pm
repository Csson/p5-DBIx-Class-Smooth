use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::RemoveColumns;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use parent 'DBIx::Class::Helper::ResultSet::Shortcut::RemoveColumns';
use Carp qw/capr/;
use experimental qw/signatures postderef/;

sub remove_columns($self, @args) {
    if(!scalar @args) {
        return $self;
    }
    # If first arg is a reference, just pass it along to DBIx::Class::Helpers remove_columns
    if(ref $args[0]) {
        carp "remove_columns received a reference, this is unexpected so only the first argument is passed on to DBIx::Class::Helper's remove_columns";
        return $self->search(undef, { remove_columns => $args[0] });
    }
    return $self->search(undef, { remove_columns => \@args });
}

1;
