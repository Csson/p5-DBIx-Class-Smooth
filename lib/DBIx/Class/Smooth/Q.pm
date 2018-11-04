use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Q;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use Carp qw/croak/;
use Safe::Isa qw/$_isa/;
use Mo;
use Sub::Exporter::Progressive -setup => {
    exports =>  [qw/Q/],
    groups => {
        default => [qw/Q/],
    },
};

use overload
    '&' => 'do_and',
    '|' => 'do_or',
    '~' => 'do_not';

use experimental qw/signatures postderef/;

has value => ();

sub Q(@args) {
    if(scalar @args == 1 && $args[0]->$_isa('DBIx::Class::Smooth::Q')) {
        return $args[0];
    }
    return DBIx::Class::Smooth::Q->new(value => [-and => \@args]);
}

sub do_and($self, $other, $swap) {
    say '---';
    say 'and self:  ' . join ', ' => $self->value->[1]->@*;
    say 'and other: ' . join ', ' => $other->value->[1]->@*;
    return DBIx::Class::Smooth::Q->new(value => [-and => [$self->value->@*, $other->value->@* ]]);
}

sub do_or($self, $other, $swap) {
    say '---';
    say ' or self:  ' . join ', ' => $self->value->[1]->@*;
    say ' or other: ' . join ', ' => $other->value->[1]->@*;
    if($self->value->[0] eq '-and' && $other->value->[0] eq '-and') {
        return DBIx::Class::Smooth::Q->new(value => [-or => [$self->value->[1]->@*, $other->value->[1]->@*]]);
    }
    return DBIx::Class::Smooth::Q->new(value => [-or => [$self->value->@*, $other->value->@* ]]);
}

sub do_not($self, $undef, $swap) {
    return DBIx::Class::Smooth::Q->new(value => [-not_bool => [$self->value->@*]]);
}

1;
