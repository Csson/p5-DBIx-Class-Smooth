use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::PlusSelectAs;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub plus_select_as($self, %args) {
    my @selects = ();
    my @as = ();

    for my $key (keys %args) {
        push @selects => $args{ $key };
        push @as => $key;
    }

    return $self->search(undef, {
        '+select' => \@selects,
        '+as' => \@as,
    });
}

1;
