use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::Util;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';


use Sub::Exporter::Progressive -setup => {
    exports => [
        qw(
             result_source_to_relation_name
             result_source_to_class
             clean_source_name
        ),
    ],
};
use experimental qw/signatures/;

sub result_source_to_relation_name($result_source_name, $plural = 0, $options = {}) {
    my $relation_name = clean_source_name($result_source_name);
    my $prefix = $options->{'prefix'} || '';
    my $suffix = $options->{'suffix'} || '';

    $relation_name =~ s{::}{_}g;
    my @parts = split /\|/, $relation_name, 2;
    $relation_name = $parts[-1];
    $relation_name = String::CamelCase::decamelize($prefix . $relation_name . $suffix);

    return $relation_name.($plural && substr ($relation_name, -1, 1) ne 's' ? 's' : '');
}
sub result_source_to_class($calling_class, $other_result_source) {
    $other_result_source =~ s{\|}{};

    # Make it possible to use fully qualified result sources, with a leading hât ("^Fully::Qualified::Result::Source").
    return substr($other_result_source, 1) if substr($other_result_source, 0, 1) eq '^';
    return base_namespace($calling_class) . clean_source_name($other_result_source);
}
sub base_namespace($class) {
    $class =~ m{^(.*?::Result::)};
    return $1;
}
sub clean_source_name($source_name) {
    $source_name =~ s{^.*?::Result::}{};
    return $source_name;
}

1;
