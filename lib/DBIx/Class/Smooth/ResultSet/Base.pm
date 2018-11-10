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
use DBIx::Class::Smooth::FilterItem;
use Carp qw/croak confess/;
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
sub _prepare_for_filter__this_is_probably_not_working_well($self, $args) {
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

sub _prepare_for_filter__this_works_well($self, @args) {
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
            #    if(scalar @key_parts == 1) {
            #        push $prepared_args->@* => ($possible_key, $possible_value);
            #        $i += 2;
            #    }
                # TODO: Fix for more than column__method
            #    else {
                    my $column_name;

                    # Ordinary column name, like 'me.first_name' or 'that_relation.whatever', then we keep that as the column name
                    if($key_parts[0] =~ m/\./) {
                        $column_name = shift @key_parts;
                    }
                    # Otherwise we make it into an ordinary column name
                    elsif($self->result_source->has_column($key_parts[0])) {
                        $column_name = sprintf 'me.%s', shift @key_parts;
                    }
                    else {
                        my $possible_relation = $key_parts[0];
                        my $possible_column = $key_parts[1];

                        my $has_relationship = $self->result_source->has_relationship($possible_relation);

                        if($has_relationship && defined $possible_column && $self->result_source->relationship_info($possible_relation)->{'class'}->has_column($possible_column)) {
                            if($possible_value->$_isa('DBIx::Class::Row')) {
                                confess "Don't pass a row object to a column";
                            }
                            $column_name = sprintf '%s.%s', splice @key_parts, 0, 2;
                        }
                        elsif($has_relationship && $possible_value->$_isa('DBIx::Class::Row')) {
                            $column_name = sprintf '%s.id', $possible_relation;
                            $possible_value = $possible_value->id;
                            shift @key_parts;
                        }
                        else {
                            die "Has no relation <$possible_relation> or that has no column <$possible_column>";
                        }
                    }
                    $possible_key = join '__', ($column_name, @key_parts);

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
        #        }
            }
        }
    }

    return $prepared_args;
}

sub _prepare_for_filter($self, @args) {
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
                push $prepared_args->@* => ($possible_key => $self->_prepare_for_filter($possible_value->@*));
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
    my $args = $self->_prepare_for_filter(-and => \@args);
    dumpit($args, 'passed to search()');
    say Dumper $args;
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
