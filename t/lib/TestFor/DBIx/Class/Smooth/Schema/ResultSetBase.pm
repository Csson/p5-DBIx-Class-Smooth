use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultSetBase;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use base 'DBIx::Class::Smooth::ResultSet::Base';

__PACKAGE__->load_components(qw/
    Helper::ResultSet
    Helper::ResultSet::OneRow
    Helper::ResultSet::Bare
    Helper::ResultSet::DateMethods1
/);

sub db {
    return shift->result_source->schema;
}

1;
