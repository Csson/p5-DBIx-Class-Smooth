use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use base 'DBIx::Class::Smooth::Result';
use boolean;

sub base { $_[1] || 'TestFor::DBIx::Class::Smooth::Schema::ResultBase' }

sub default_result_namespace { 'TestFor::DBIx::Class::Smooth::Schema::Result' }

sub perl_version { 20 }

sub experimental {
    [qw/
        postderef
        signatures
    /];
}

1;
