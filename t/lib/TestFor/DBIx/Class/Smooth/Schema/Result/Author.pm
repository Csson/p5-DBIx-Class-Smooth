use 5.20.0;
use strict;
use warnings;

package TestFor::DBIx::Class::Smooth::Schema::Result::Author;

our $VERSION = '0.0001';

use TestFor::DBIx::Class::Smooth::Schema::Result;
use DBIx::Class::Smooth::Fields -all;

primary id => IntegerField(auto_increment => 1);
    col first_name => VarcharField(indexed => 'authorname');
    col last_name => VarcharField(indexed => 'authorname');
belongs Country => ForeignKey();

1;
