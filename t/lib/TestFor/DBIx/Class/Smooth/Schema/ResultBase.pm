use 5.20.0;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::ResultBase;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use base 'DBIx::Class::Smooth::Result::Base';
use experimental qw/postderef signatures/;

__PACKAGE__->load_components(qw/
    Helper::Row::RelationshipDWIM
    Smooth::Helper::Row::Creation
/);

sub db {
    return shift->result_source->schema;
}

1;
