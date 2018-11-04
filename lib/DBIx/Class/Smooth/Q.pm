use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Q;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0101';

use Carp qw/croak/;
use Mo;
use Sub::Exporter::Progressive -setup => {
    groups => {
        default => [qw/Q/],
    },
};

use overload '&' => "do_and", '|' => 'do_or';
use Data::Dump::Streamer;
use experimental qw/signatures postderef/;

has value => ();

sub Q(@args) {
    return Q->new(value => \@args);
}

sub do_and($self, $other, $swap) {
    say '- AND -';
    say Dump $self->value;
    say Dump $other->value;
    say ' // AND';
    my $new = DBIx::Class::Sweeten::Q->new(value => [-and => [$self->value->@*, $other->value->@* ]]);
    return $new;
}

sub do_or($self, $other, $swap) {
    say '- OR -' . $swap;
    say 'self value ref : ' . ref $self->value;
    say 'other value ref: ' . ref $other->value;
    say Dump $self->value;
    say '      - ';
    say Dump $other->value;
    say '===';
    my $new_value = [-or => { $self->value->@*, $other->value->@* }];
    say Dump $new_value;

    my $new = DBIx::Class::Sweeten::Q->new(value => $new_value);
    say 'ref: ' . ref $new;
    say Dump $new->value;
    say ' // OR';
    return $new;
}

1;
