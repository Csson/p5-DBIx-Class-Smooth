use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultSet::Base;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use base 'DBIx::Class::ResultSet';
use List::SomeUtils qw/any/;
use Safe::Isa qw/$_isa/;
use DBIx::Class::Smooth::Q;
use Data::Dumper::Concise;
use experimental qw/signatures postderef/;

sub db($self) {
    return $self->result_source->schema;
}

sub qfilter($self, $q) {
    return $self->search($q->value);
}

=pod
    return $self->search([
        -and => [
            -or => [
                -and => [
                    name => 'WaterStreet',
                ],
                -and => [
                    name => 'GermanZone',
                ]
            ],
            -not_bool => [
                -and => [
                    name => { -like => '%o%' },
                ]
            ]
        ]
    ]);
=cut
sub _prepare_for_filter($self, $args) {
    say 'before:';
    warn Dumper $args;
    say '---';
    my @prepared_args = ();
    PAIR:
    for (my $i = 0; $i < scalar $args->@*; $i++) {
        say "i: $i";
        my $key = $args->[$i];
        my $value;
        if(any { $key eq $_ } (qw/-and -or -not_bool/)) {
            ++$i;
            say $key;
            say join ', ' => $args->[1]->@*;
            $value = $args->[$i + 1]->@*;
            if(ref $value ne 'ARRAY') {
                say $value;
                die 'BAD ARRAY' . ref $value;
            }
            say '..prepare';
            $self->_prepare_for_filter($value);
        }
        if(ref $key eq 'REF') {
            say 'next PAIR';
            push @prepared_args => $key;
            next PAIR;
        }

        else {
            say 'else';
            my @parts = split /__/ => $key;
            say $key;
            say 'no 1';
            say @parts;
            say 'no 2';
            push @prepared_args => 'wee' && next PAIR if scalar @parts == 1;
            say 'HERE 2';

            my $possible_method_name = "lookup__$parts[-1]";
            if($self->can($possible_method_name)) {
                say 'HERE 3';
                if(ref $value eq 'HASH') {
                    die 'UNEXPECTED HASH';
                }
                ($key, $value) = $self->$possible_method_name($key, $value);
                push @prepared_args => ($key, $value);
                #$args->[$i] = $key;
                #$args->[$i + 1] = $value;
            }
            else {
                push @prepared_args => ($key, $value);
            }

        }
    }
    say 'after:';
    warn Dumper \@prepared_args;
    say '---';
    return \@prepared_args;
}

sub dumpit($todump, $prelude) {
    return;
    say "$prelude:";
    say Dumper $todump;
    say '------------';
}

sub _prepare_for_filter2($self, @args) {
    dumpit(\@args, 'in args');
    my @qobjs = grep { $_->$_isa('DBIx::Class::Smooth::Q') } @args;
    if(scalar @qobjs) {
        if(scalar @args > 1) {
            die "Don't mix Q() and normal args";
        }
        else {
            @args = $args[0]->value->@*;
        }
    }
    dumpit(\@args, 'after q fix args');

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
                push $prepared_args->@* => ($possible_key => $self->_prepare_for_filter2($possible_value->@*));
                $i += 2;
            }
            else {
                dumpit($possible_value, 'Expected array ref, got');
            }
        }
        else {
            # $possible_value isn't the value for \[] searches
            if(ref $possible_key eq 'REF') {
                push $prepared_args->@* => $possible_key;
                $i++;
            }
            elsif(defined $possible_key && defined $possible_value) {

                my @key_parts = split /__/ => $possible_key;

                # normal, just: column => 'value'
                if(scalar @key_parts == 1) {
                    push $prepared_args->@* => ($possible_key, $possible_value);
                    $i += 2;
                }
                # TODO: Fix for more than column__method
                else {
                    my $column = shift @key_parts;

                    for my $part (reverse @key_parts) {
                        my $method = 'lookup__' . $part;

                        if($self->can($method)) {
                            ($possible_key, $possible_value) = $self->$method($possible_key, $possible_value);
                        }
                        else {
                            die "Can't do $method";
                        }
                    }

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
    }

    return $prepared_args;
}

sub filter($self, @args) {
    # only compatible with array and Q

    my $args = $self->_prepare_for_filter2(-and => \@args);
    dumpit($args, 'passed to search()');

    return $self->search($args);
    if(scalar @args == 1 && $args[0]->$_isa('DBIx::Class::Smooth::Q')) {
        @args = $args[0]->value;
    }

=pod
    for my $key (keys %args) {
        my $value = $args{ $key };

        my @parts = split /__/ => $key;
        next if scalar @parts < 2;

        my $column;

        # find column
        if(any { $_ eq $parts[0] } $self->result_source->columns) {
            $column = "me.$parts[0]";
        }

        my $method = "lookup__$parts[1]";
        if($self->can($method)) {
            delete $args{ $key };
            ($key, $value) = $self->$method($column, $value);
            $args{ $key } = $value;
        }

    }
=cut

    return $self->search(\@args);
}

sub filterattr($self, %args) {
    return $self->search({}, \%args);
}

1;
