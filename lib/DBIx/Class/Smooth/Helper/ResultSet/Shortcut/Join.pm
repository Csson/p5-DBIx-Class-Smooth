use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::Join;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub join($self, @args) {

    if(!scalar @args) {
        return $self;
    }

    for my $arg (@args) {
        if ($arg =~ m/\./) {
            my ($first, $second) = split m/\./ => $arg;
            $arg = { $first => $second };
        }
        $self = $self->search(undef, { join => $arg });
    }

    return $self;
}

1;
