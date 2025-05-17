use 5.40.0;
use strict;
use warnings;


package DBIx::Class::Smooth::Components::Accessor;
# ABSTRACT: Specify columns
# AUTHORITY
our $VERSION = '0.0109';

use DBIx::Class::Candy::Exports;
DBIx::Class::Candy::Exports->import;
export_methods [qw/access unique_together/];

sub access($self, $column, @rest) {
    $self->mk_group_accessors(column => $column);
}

sub unique_together($self, @columns) {
    my $name = 'unique_constraint_' . join '_' => @columns;
    $self->add_unique_constraint($name => \@columns);
}

__END__
sub access {
    my $self = shift;
    my $inheritor = shift;
    my $set_table = shift;

    sub {
        my $i = $inheritor;
        sub {
            my $accessor = shift;
            $set_table->();
            $i->mk_group_accessors(column => $accessor);
        }
    }

}