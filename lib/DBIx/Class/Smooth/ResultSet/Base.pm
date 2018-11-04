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
    PAIR:
    for (my $i = 0; $i < scalar $args->@*; $i += 2) {
        my $key = $args->[$i];
        my $value = $args->[$i + 1];

        if(any { $key eq $_ } (qw/-and -or -not_bool/)) {
            if(ref $value ne 'ARRAY') {
                die 'BAD ARRAY';
            }
            $self->_prepare_for_filter($value);
        }
        else {
            my @parts = split /__/ => $key;
            say $key;
            say @parts;
            next PAIR if scalar @parts == 1;
            say 'HERE 2';

            my $possible_method_name = "lookup__$parts[-1]";
            if($self->can($possible_method_name)) {
                if(ref $value eq 'HASH') {
                    die 'UNEXPECTED HASH';
                }
                ($key, $value) = $self->$possible_method_name($key, $value);
                $args->[$i] = $key;
                $args->[$i + 1] = $value;
            }

        }
    }
    say 'after:';
    warn Dumper $args;
    return $args;
}

sub filter($self, @args) {
    # only compatible with array and Q

    if(scalar @args == 1 && $args[0]->$_isa('DBIx::Class::Smooth::Q')) {
        @args = $args[0]->value;
    }

    @args = $self->_prepare_for_filter($args[0]);
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
