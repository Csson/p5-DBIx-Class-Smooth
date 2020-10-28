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
use Ref::Util qw/is_scalarref is_refref is_arrayref/;
use Sub::Exporter::Progressive -setup => {
    exports => [qw/
        Ascii
        Bin
        Char
        CharLength
        Concat
        ConcatWS
        Elt
        ExportSet
        Substring
    /]
};

use experimental qw/postderef signatures/;

sub first_is_voc($function_name, @params) {
    if (!scalar @params) {
        return { uc $function_name => undef };
    }
    my $first = shift @params;
    # If an inner call requires a rendered sql string, the outer call needs to do that as well
    if (is_refref $first && is_arrayref $$first) {
        my $inner_sql_string = $$first->[0];
        my $sql_string = $inner_sql_string . (scalar @params ? ', ' . join ', ' => @params : '');
        return \["@{[ uc $function_name ]}($sql_string)"];
    }
    # If you pass the $value_or_columnname as a string ref, then we render an sql string
    elsif (is_scalarref $first) {
        my $sql_string = "'$$first'" . (scalar @params ? ', ' . join ', ' => @params : '');
        return \["@{[ uc $function_name ]}($sql_string)"];
    }
    unshift @params => $first;
    return { uc $function_name => \@params };
}

sub all_is_voc($function_name, @params) {
    my $any_is_ref = scalar grep { is_scalarref $_ } @params;

    if ($any_is_ref) {
        my $sql_string = join ', ' => map { is_scalarref $_ ? "'$$_'" : $_ } @params;
        return \["@{[ uc $function_name ]}($sql_string)"];
    }
    else {
        return { uc $function_name => \@params };
    }
}

sub drop_last_if_undef(@params) {
    if (!defined $params[-1]) {
        pop @params;
    }
    return @params;
}

# $voc = Value or column name
sub Ascii($voc) { return first_is_voc ascii => $voc; }

sub Bin($voc) { return first_is_voc bin => $voc; }

# # Char does not support USING currently
# sub Char($voc, $opts = {}) {
#     $voc = is_refref $voc ? $$voc->[0]                     # inner is: \[..]
#          : is_scalarref $voc && $$voc =~ m/'$/ ? "$$voc"   # $voc is eg: \"x'65'"
#          : is_scalarref $voc ? "'$$voc'"                   # $voc is eg: \"65"
#          : $voc;
#     if ($opts->{'using'}) {
#         return \["CHAR($voc USING $opts->{'using'})"]
#     }
#     return first_is_voc char => $voc;

# }

sub CharLength($voc) { return first_is_voc char_length => $voc; }

sub Concat(@list) { return all_is_voc concat => @list; }

sub ConcatWS($sep, @list) { return all_is_voc concat_ws => $sep, @list; }

sub Elt($index, @list) { return all_is_voc elt => $index, @list; }

sub ExportSet($bits, $on, $off, $separator, $number_of_bits) { return all_is_voc export_set => drop_last_if_undef(drop_last_if_undef $bits, $on, $off, $separator, $number_of_bits); }

sub Substring($voc, $pos, $length = undef) { return first_is_voc substring => drop_last_if_undef($voc, $pos, $length); }

=pod

=head1 SYNOPSIS

    use DBIx::Class::Smooth::Functions -all;

    # With DBIx::Class::Smooth
    $rs->annotate(first_two_from_column => Substring('title', 1, 2));
    $rs->annotate(first_two_from_string => Substring(\'The Fellowship', 1, 2));

    # Normal DBIx::Class
    $rs->search({}, { '+select' => [{ substring => ['title', 1, 2]}], '+as' => ['first_two_from_column'] });
    $rs->search({}, { '+select' => [ \['substring("The Fellowship", 1, 2)'] ], '+as' => ['first_two_from_string'] });

    # and then, regardless
    $rs->first->get_column('first_two_from_column');

=head1 DESCRIPTION

DBIx::Class::Smooth::Functions contains SQL function helpers. They work together with C<annotate> (which is added by L<DBIx::Class::Smooth::ResultSet>) to make adding calculated columns easier. See synopsis for a general example.

1;

__END__

=head2 Arguments

Pass a string to refer to a column name.
Pass a reference to a string to pass a string to the database function.

=head1 STRING FUNCTIONS

C<$column_or_value> can be either a quoted string (to refer to a column name) or a reference to a string (to pass a hard coded string to the SQL function).
C<@columns_or_values> is a list of C<$column_or_value>.


=for :list

* Ascii($column_or_value)
* Bin($column_or_value)
* CharLength($column_or_value)
* Concat(@columns_or_values)
* ConcatWS($separator, @columns_or_values) # $separator can be column or value as well
* Elt($index, @columns_or_values) #
* ExportSet($bits, $on, $off[, $separator[, $number_of_bits]]) # all parameters can be columns or values
* Substring($column_or_value, $position[, $length])


1;
