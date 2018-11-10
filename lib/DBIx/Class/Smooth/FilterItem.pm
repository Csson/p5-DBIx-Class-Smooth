use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::FilterItem;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use Carp qw/croak confess/;
use Safe::Isa qw/$_isa/;
use List::SomeUtils qw/any none/;
use Data::Dumper::Concise;
use Mo;

use experimental qw/signatures postderef/;

# parts and resultset (and nothing else) are constructor args
has parts => [];
has resultset => undef;

has left_hand_functions => [];
has left_hand_prefix => undef;
has value => undef;
has quote_value => 1;
has operator => undef;
has sql_operator => undef;
has column_name => undef;

sub get_value($self) {
    return $self->value;
}
sub set_value($self, $new_value) {
    return $self->value($new_value);
}
sub parts_get($self, $index) {
    return $self->parts->[$index];
}
sub parts_get_all($self) {
    return $self->parts->@*;
}
sub parts_shift($self, $repeats = 1) {
    if($repeats == 1) {
        return shift $self->parts->@*;
    }
    elsif($repeats > 1) {
        return splice $self->parts->@*, 0, $repeats;
    }
}
sub set_column_name($self, $name) {
    $self->column_name($name);
}
sub set_sql_operator($self, $operator) {
    if(defined $self->operator) {
        die "Trying to set sql_operator ($operator), but operator (@{[ $self->operator ]}) already set";
    }
    elsif(defined $self->sql_operator) {
        die "Trying to set sql_operator ($operator), but it is already set to (@{[ $self->sql_operator ]})";
    }
    $self->sql_operator($operator);
}
sub set_operator($self, $operator) {
    if(defined $self->operator) {
    #    die "Trying to set operator ($operator), but it is already set to (@{[ $self->operator ]})";
    }
    elsif(defined $self->sql_operator) {
    #    die "Trying to set operator ($operator), but sql_operator (@{[ $self->operator ]}) already set";
    }
    $self->operator($operator);
}
sub set_left_hand_prefix($self, $prefix) {
    if(defined $self->left_hand_prefix) {
        die "Trying to set left hand prefix ($prefix), but it is already set to (@{[ $self->left_hand_prefix ]})";
    }
    $self->left_hand_prefix($prefix);
}

sub left_hand_function_add($self, $data) {
    if(!$self->left_hand_functions) {
        $self->left_hand_functions([]);
    }
    push $self->left_hand_functions->@* => $data;
}
sub left_hand_functions_get_all($self) {
    if(!$self->left_hand_functions) {
        return ();
    }
    return $self->left_hand_functions->@*;
}
sub set_quote_value($self, $value) {
    $self->quote_value($value);
}
sub get_quote_value($self) {
    return $self->quote_value;
}
sub parse($self) {
    # Ordinary column name, like 'me.first_name' or 'that_relation.whatever', then we keep that as the column name
    if($self->parts_get(0) =~ m/\./) {
        $self->set_column_name($self->parts_shift);
    }
    # Otherwise we make it into an ordinary column name
    elsif($self->resultset->result_source->has_column($self->parts_get(0))) {
        $self->set_column_name(sprintf '%s.%s', $self->resultset->current_source_alias, $self->parts_shift);
    }
    else {
        my $possible_relation = $self->parts_get(0);
        my $possible_column = $self->parts_get(1);

        my $has_relationship = $self->resultset->result_source->has_relationship($possible_relation);

        if($has_relationship && defined $possible_column && $self->resultset->result_source->relationship_info($possible_relation)->{'class'}->has_column($possible_column)) {
            if($self->get_value->$_isa('DBIx::Class::Row')) {
                confess "Don't pass a row object to a column";
            }
            $self->set_column_name(sprintf '%s.%s', $self->parts_shift(2));
        }
        elsif($has_relationship && $self->get_value->$_isa('DBIx::Class::Row')) {
            $self->set_column_name(sprintf '%s.id', $possible_relation);
            $self->set_value($self->get_value->id);
            $self->parts_shift;
        }
        else {
            die "Has no relation <$possible_relation> or that has no column <$possible_column>";
        }
    }

    for my $part ($self->parts_get_all) {
        my @params = ();
        if($part =~ m{^ (\w+) \( ([^)]+) \) $}x) {
            $part = $1;
            @params = split /\s*,\s*/ => $2;
        }
        my $method = "smooth__lookup__$part";

        my $lookup_result;
        if($self->resultset->can($method)) {
            $lookup_result = $self->resultset->$method($self->column_name, $self->get_value, \@params);
        }
        else {
            confess "Can't do <$method>, find suitable Lookup and add it to load_components";
        }

        if(!exists $lookup_result->{'value'}) {
            confess "Lookup for <$part> is expected to return { value => ... }, can't proceed";
        }
        $self->set_value(delete $lookup_result->{'value'});
        if(exists $lookup_result->{'left_hand_function'}) {
            $self->left_hand_function_add(delete $lookup_result->{'left_hand_function'});
        }
        if(exists $lookup_result->{'left_hand_prefix'}) {
            $self->set_left_hand_prefix(delete $lookup_result->{'left_hand_prefix'});
        }
        if(exists $lookup_result->{'sql_operator'}) {
            $self->set_sql_operator(delete $lookup_result->{'sql_operator'});
        }
        if(exists $lookup_result->{'operator'}) {
            $self->set_operator(delete $lookup_result->{'operator'});
        }
        if(exists $lookup_result->{'quote_value'}) {
            $self->set_quote_value(delete $lookup_result->{'quote_value'});
        }
        else {
            $self->set_quote_value(1);
        }
        if(scalar keys $lookup_result->%*) {
            die sprintf "Unexpected keys returned from lookup for <$part>: %s", join(', ' => sort keys $lookup_result->%*);
        }
    }

    # Happy case
    if((!defined $self->left_hand_functions || !scalar $self->left_hand_functions->@*) && !defined $self->left_hand_prefix && $self->get_quote_value) {
        my $column_name = $self->column_name;

        if($self->operator && $self->operator ne '=') {
            return ($self->column_name, { $self->operator => $self->value });
        }
        else {
            return ($self->column_name, $self->get_value);
        }
    }
    else {
        my @left_hand = ();
        if($self->left_hand_prefix) {
            push @left_hand => $self->left_hand_prefix;
        }
        my $function_call_string = $self->column_name;
        for my $lhf ($self->left_hand_functions_get_all) {
            if(exists $lhf->{'complete'}) {
                $function_call_string = delete $lhf->{'complete'};
            }
            elsif(exists $lhf->{'name'}) {
                $function_call_string = sprintf '%s(%s)', delete ($lhf->{'name'}), $function_call_string;
            }
            elsif(exists $lhf->{'start'} && exists $lhf->{'end'}) {
                $function_call_string = sprintf '%s%s%s', delete ($lhf->{'start'}), $function_call_string, delete ($lhf->{'end'});
            }
        }
        push @left_hand => $function_call_string;
=pod
        # for now, just one function and no additional params
        if($self->left_hand_functions && scalar $self->left_hand_functions->@* == 1) {
            $left_hand .= sprintf '%s(%s) ', $self->left_hand_functions->[0]{'name'}, $self->column_name;
        }
        elsif(!$self->left_hand_functions) {
            $left_hand .= sprintf ' %s ', $self->column_name;
        }
=cut
        push @left_hand => $self->sql_operator ? $self->sql_operator : $self->operator;

        if($self->get_quote_value) {
            # Either ? or (?, ?, ...., ?)
            my $placeholders = ref $self->get_value eq 'ARRAY' ? '(' . join(', ', split (//, ('?' x scalar $self->get_value->@*))) . ')' : ' ? ';
            push @left_hand => $placeholders;
            my $left_hand = join ' ' => @left_hand;
            return (undef, \[$left_hand, $self->get_value->@*]);
        }
        else {
            push @left_hand => $self->get_value;
            my $left_hand = join ' ' => @left_hand;
            return (undef, \[$left_hand]);
        }


        

        #if((!defined $self->left_hand_functions || !scalar $self->left_hand_functions->@*) && defined $self->sql_operator) {
        #    return (undef, \["@{[ $self->column_name ]} @{[ $self->sql_operator ]} ?", $self->get_value]);
        #}
    }

=pod

    $possible_key = join '__', ($column_name, @key_parts);

    for my $part (reverse @key_parts) {
        my $method = 'lookup__' . $part;

        if($self->can($method)) {
            ($possible_key, $self->get_value) = $self->$method($possible_key, $self->get_value);
        }
        else {
            die "Can't do $method";
        }
    }
=cut
}

1;
