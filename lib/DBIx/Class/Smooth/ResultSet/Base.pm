use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::ResultSet::Base;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0101';

use base 'DBIx::Class::ResultSet';

use experimental qw/signatures/;

sub db($self) {
    return $self->result_source->schema;
}

sub filter($self, %args) {
    return $self->search(\%args);
}

sub filterattr($self, %args) {
    return $self->search({}, \%args);
}

1;
