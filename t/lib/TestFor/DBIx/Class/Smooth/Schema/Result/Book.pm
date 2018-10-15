use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::Book;

# ABSTRACT: ...
# AUTHORITY
our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth -all;
use experimental qw/postderef signatures/;

primary id => IntegerField(auto_increment => 1);
    col title => VarcharField(size => 150);
ManyToMany 'Author', via => 'BookAuthor';

1;
