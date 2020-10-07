use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Functions;

# ABSTRACT: Specify columns
# AUTHORITY
our $VERSION = '0.0106';

use Carp qw/croak/;
use List::Util qw/uniq/;
use List::SomeUtils qw/any/;
use boolean;
use Sub::Exporter::Progressive -setup => {
    exports => [qw/
        Ascii
        Char
        Substring
    /]
};

use experimental qw/postderef signatures/;

sub standard($function_name, @params) {
    return { lc $function_name => !scalar @params ? undef : scalar @params == 1 ? $params[0] : \@params };
}
sub drop_last_if_undef($function_name, @params) {
    if (!defined $params[-1]) {
        pop @params;
    }
    return standard $function_name => @params;
}

sub Ascii($string) { return standard ascii => $string; }
sub Char($string) { return standard char => $string; }
sub Substring($string, $pos, $length = undef) { return drop_trailing_undef substring => [$string, $pos, $length]; }

=pod

=head1 SYNOPSIS

    use DBIx::Class::Smooth::Fields -all;

    # ....

    # $rs is a resultset

    # With DBIx::Class::Smooth
    $rs->annotate(first_two_from_title => Substring('title', 0, 2));

    # Normal DBIx::Class
    $rs->search({}, { '+select' => [{ substring => ['title', 0, 2]}], '+as' => ['first_two_from_title'] });

    # and then, regardless
    $rs->first->get_column('first_two_from_title');

=head1 DESCRIPTION

DBIx::Class::Smooth::Functions contains "SQL" functions. They work together with C<annotate> (which is added by L<DBIx::Class::Smooth::ResultSet>) to make adding calculated columns easier. See synopsis for a general example.

=head1 FUNCTIONS

=head2 Substring($column_name, $position, [$length])

Returns:

    # if $length is defined
    { substring => [$column_name, $position, $length] }

    # otherwise
    { substring => [$column_name, $position] }


1;
