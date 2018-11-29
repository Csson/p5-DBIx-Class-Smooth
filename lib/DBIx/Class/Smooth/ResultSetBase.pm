use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultSetBase;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::ResultSet';
use List::SomeUtils qw/any/;
use Safe::Isa qw/$_isa/;
use Carp qw/croak confess/;
use DBIx::Class::Smooth::Q;
use DBIx::Class::Smooth::FilterItem;
use experimental qw/signatures postderef/;

sub _smooth__prepare_for_filter($self, @args) {
    my @qobjs = grep { $_->$_isa('DBIx::Class::Smooth::Q') } @args;
    if(scalar @qobjs) {
        if(scalar @args > 1) {
            die "Don't mix Q() and normal args";
        }
        else {
            @args = $args[0]->value->@*;
        }
    }

    my $i = undef;
    my $prepared_args = [];

    ARG:
    for my $fori (0..scalar @args - 1) {
        # We do it this way since not all search args are key => value pairs (such as \[] searches)
        # meaning that sometimes we need to $i += 1 and sometimes $i += 2
        $i = $fori if !defined $i;

        my $possible_key = $args[$i];
        my $possible_value = $i + 1 <= scalar @args - 1 ? $args[$i + 1] : undef;

        # Dig deeper into the search structure
        if($possible_value && any { $possible_key eq $_ } (qw/-and -or -not_bool/)) {
            if(ref $possible_value eq 'ARRAY') {
                push $prepared_args->@* => ($possible_key => $self->_smooth__prepare_for_filter($possible_value->@*));
                $i += 2;
            }
        }
        else {
            # There is no $possible_value for \[] searches, the value is already in the arrayrefref
            if(ref $possible_key eq 'REF') {
                push $prepared_args->@* => $possible_key;
                $i++;
            }
            elsif(defined $possible_key && defined $possible_value) {

                my @key_parts = split /__/ => $possible_key;

                my $item = DBIx::Class::Smooth::FilterItem->new(resultset => $self, parts => \@key_parts, value => $possible_value);
                ($possible_key, $possible_value) = $item->parse;

                if($possible_key) {
                    push $prepared_args->@* => ($possible_key, $possible_value);
                }
                else {
                    push $prepared_args->@* => $possible_value;
                }
                $i += 2;
            }
        }
    }
    return $prepared_args;
}

sub filter($self, @args) {
    # only compatible with array and Q
    my $args = $self->_smooth__prepare_for_filter(-and => \@args);
    return $self->search($args);
}

sub filterattr($self, %args) {
    return $self->search({}, \%args);
}

1;
