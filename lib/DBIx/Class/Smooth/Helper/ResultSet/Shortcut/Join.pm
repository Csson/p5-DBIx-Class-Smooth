use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::Join;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0103';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub join($self, @args) {

    if(!scalar @args) {
        return $self;
    }
    elsif(scalar @args >= 2) {
        die 'Too many args';
    }
    return $self->search(undef, { join => $args[0]});
}

1;
