use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Flatten::DateTime;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0103';

use parent qw/
    DBIx::Class::Helper::ResultSet::DateMethods1
/;
use experimental qw/signatures postderef/;

sub smooth__flatten__DateTime($self, $dt) {
    # ->utc() is from ::RS::DateMethods1
    my $datetime_string = $self->utc($dt);
    return $datetime_string;
}

1;
