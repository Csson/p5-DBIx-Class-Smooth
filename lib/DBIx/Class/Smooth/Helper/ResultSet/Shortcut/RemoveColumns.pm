use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::RemoveColumns;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0107';

use parent 'DBIx::Class::Helper::ResultSet::RemoveColumns';
use Carp qw/carp/;
use List::SomeUtils qw/any/;
use experimental qw/signatures postderef/;

sub remove_columns($self, @args) {
    if(!scalar @args) {
        return $self;
    }
    # If first arg is a reference, just pass it along to DBIx::Class::Helpers remove_columns
    if(ref $args[0]) {
        carp "remove_columns received a reference, this is unexpected so only the first argument is passed on to DBIx::Class::Helper's remove_columns";
        return $self->search(undef, { remove_columns => $args[0] });
    }
    return $self->search(undef, { remove_columns => \@args });
}

sub _resolved_attrs($self, @rest) {
    my $attrs = $self->{'attrs'};

    if($attrs->{'remove_columns'} && scalar $attrs->{'remove_columns'}->@*) {
        my %columns_to_remove = map { $_ => 1 } $attrs->{'remove_columns'}->@*;
        if($attrs->{'columns'}) {
            $attrs->{'columns'} = [grep { !$columns_to_remove{ $_ } } $attrs->{'columns'}->@*];
        }
        else {
            $attrs->{'columns'} = [grep { !$columns_to_remove{ $_ } } $self->result_source->columns];
        }

        if($attrs->{'+columns'} && scalar $attrs->{'+columns'}->@*) {
            for my $i (0..scalar $attrs->{'+columns'}->@* - 1) {
                # each position can either be a string (column name) or a hashref (where the key is the column name)
                my $this_colname = ref $attrs->{'+columns'}[$i]
                                 ? (keys $attrs->{'+columns'}[$i]->%*)[0]
                                 : $attrs->{'+columns'}[$i]
                                 ;

                if(any { $this_colname eq $_ } keys %columns_to_remove) {
                    splice $attrs->{'+columns'}->@*, $i, 1;
                }
            }
        }
        # This loops over 'select' (and 'as') and '+select' (and '+as') and removes the column(s) as wanted
        for my $prefix ('', '+') {
            my $select_key = $prefix . 'select';
            my $as_key = $prefix . 'as';
            if($attrs->{ $select_key }) {
                for my $i (0..scalar $attrs->{ $select_key }->@* - 1) {
                    my $this_colname = $attrs->{ $select_key }[$i];

                    if(any { $this_colname eq $_ } keys %columns_to_remove) {
                        splice $attrs->{ $select_key }->@*, $i, 1;
                        if(exists $attrs->{ $as_key } && scalar $attrs->{ $as_key }->@* >= $i + 1) {
                            splice $attrs->{ $as_key }->@*, $i, 1;
                        }
                    }
                }
            }
        }
    }

    return $self->next::method;
}

1;
