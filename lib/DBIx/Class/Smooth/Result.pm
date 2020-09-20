use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Result;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0106';

use parent 'DBIx::Class::Candy';
use String::CamelCase;

use experimental qw/signatures/;

sub base {
    (my $base = caller(2)) =~ s{::Schema::Result::.*$}{};

    return $_[1] || "${base}::Schema::Result";
}
sub autotable    { 1 }
sub perl_version { 20 }
sub experimental { [ ] }

sub gen_table($self, $resultclass, $version) {
    $resultclass =~ s{^.*::Schema::Result::}{};
    $resultclass =~ s{::}{__}g;
    $resultclass = String::CamelCase::decamelize($resultclass);

    return $resultclass;
}

1;
