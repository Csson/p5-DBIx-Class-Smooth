use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Q;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0104';

use Carp qw/croak/;
use Safe::Isa qw/$_isa/;
use List::SomeUtils qw/any/;
use Moo;
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

has value => (
    is => 'rw',
);

sub Q(@args) {
    if(scalar @args == 1 && $args[0]->$_isa('DBIx::Class::Smooth::Q')) {
        return $args[0];
    }
    return DBIx::Class::Smooth::Q->new(value => [-and => \@args]);
}

sub _prepare_do_and($self, $other) {
    my %self_values_as_flathash = ($self->value->[1]->@*);
    my @self_valuekeys = keys %self_values_as_flathash;

    if(any { $_ eq '-and' } @self_valuekeys) {
        ATTEMPT:
        while(1) {
            VALUE:
            for (my $i = 0; $i < scalar $self->value->[1]->@*; $i += 2) {
                my $key = $self->value->[1][$i];
                if($key eq '-and') {
                    push $other->value->[1]->@* => $self->value->[1][$i+1]->@*;
                    splice $self->value->[1]->@*, $i, 2;
                    next ATTEMPT;
                }
            }
            last ATTEMPT;
        }
    }

    return $self, $other;
}

sub do_and($self, $other, $swap) {
    ($self, $other) = $self->_prepare_do_and($other);
    my $self_value = $self->value;
    my $other_value = $other->value;

    if($self_value->[0] eq '-and') {
        $self_value = $self_value->[1];
    }
    if($other_value->[0] eq '-and') {
        $other_value = $other_value->[1];
    }

    my $value = [-and => [$self_value->@*, $other_value->@* ]];

    return DBIx::Class::Smooth::Q->new(value => $value);
}

sub do_or($self, $other, $swap) {
    my $self_value = $self->value;
    my $other_value = $other->value;

    if($self_value->[0] eq '-or' && $self_value->[1][0] eq '-or') {
        splice $self_value->[1]->@*, 0, 2, $self_value->[1][1]->@*;
    }
    if($other_value->[0] eq '-or' && $other_value->[1][0] eq '-or') {
        splice $other_value->[1]->@*, 0, 2, $other_value->[1][1]->@*;
    }

    if($self_value->[0] eq '-and' && scalar $self_value->[1]->@* == 2) {
        $self_value = $self_value->[1];
    }
    if($other_value->[0] eq '-and' && scalar $other_value->[1]->@* == 2) {
        $other_value = $other_value->[1];
    }
    my $value = [-or => [$self_value->@*, $other_value->@* ]];

    return DBIx::Class::Smooth::Q->new(value => $value);
}

sub do_not($self, $undef, $swap) {
    return DBIx::Class::Smooth::Q->new(value => [-not_bool => [$self->value->@*]]);
}

1;
