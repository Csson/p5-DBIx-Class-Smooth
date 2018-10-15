use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::Row::Creation;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0104';

use parent 'DBIx::Class::Row';
use String::CamelCase;
use Module::Loader;
use Syntax::Keyword::Try;
use Carp qw/croak/;
use DBIx::Class::Candy::Exports;

use experimental qw/postderef signatures/;

export_methods [qw/
    col
    primary
    foreign
    belongs
    unique
    primary_belongs
    ManyToMany
/];

state $module_loader = Module::Loader->new;

sub ManyToMany($self, $final_destination_source, %attrs) {
    if(!exists $attrs{'via'}) {
        croak "Bad call to ManyToMany in $self, missing 'via'";
    }
    my $final_destination_class = $self->result_source_to_class($final_destination_source);
    my $via_source = $attrs{'via'};
    my $via_class = $self->result_source_to_class($via_source);

    my $to_via_relation_name = $self->result_source_to_relation_name($via_source, 1);
    my $via_to_self_relation_name = $self->result_source_to_relation_name($self =~ s{^.*::Schema::Result::}{}r, 0);
    my $via_to_final_relation_name = $self->result_source_to_relation_name($final_destination_source, 0);
    my $self_to_final_relation_name = $self->result_source_to_relation_name($final_destination_source, 1);
    my $final_to_self_relation_name = $self->result_source_to_relation_name($self, 1);

    my $self_column_name_in_via = $via_to_self_relation_name . '_id';
    my $final_column_name_in_via = $via_to_final_relation_name . '_id';

    $module_loader->load($via_class);
    $module_loader->load($final_destination_class);

    $self->has_many($to_via_relation_name, $via_class, { "foreign.$self_column_name_in_via" => "self.id" });
    $via_class->belongs_to($via_to_self_relation_name, $self, { "foreign.id" => "self.$self_column_name_in_via" });

    $via_class->belongs_to($via_to_final_relation_name, $final_destination_class, { "foreign.id" => "self.$final_column_name_in_via" });
    $final_destination_class->has_many($to_via_relation_name, $via_class, { "foreign.$final_column_name_in_via" => "self.id" });

    $self->many_to_many($self_to_final_relation_name, $to_via_relation_name, $via_to_final_relation_name);
    $final_destination_class->many_to_many($final_to_self_relation_name, $to_via_relation_name, $via_to_self_relation_name);
}

sub col($self, $name, $definition) {
    $self->add_columns($name => $definition);
}


sub primary($self, $name, $definition) {
    $self->add_columns($name => $definition);
    $self->set_primary_key($self->primary_columns, $name);
}
sub primary_belongs($self, @remaining) {
    my $column_name = $self->belongs(@remaining);
    $self->set_primary_key($self->primary_columns, $column_name);

}
sub foreign($self, $column_name, $definition) {
    $definition->{'is_foreign_key'} = 1;
    $self->add_column($column_name => $definition);
}

# assumes that the primary key is called 'id'
sub belongs($self, $other_source, $relation_name_or_definition, $definition_or_undef = {}) {
    my $belongs_to_class = $self->result_source_to_class($other_source);
    my $relation_name = $self->result_source_to_relation_name($other_source);
    my $definition = {};

    # two-param call
    if(ref $relation_name_or_definition eq 'HASH') {
        $definition = $relation_name_or_definition;
    }
    # three-param call
    elsif(ref $definition_or_undef eq 'HASH') {
        $definition = $definition_or_undef;
        $relation_name = $relation_name_or_definition;
    }
    else {
        croak "Bad call to belongs in $self: 'belongs $other_source ...'";
    }
    my $column_name = $relation_name . '_id';


    # Its a ForeignKey field!
    if(exists $definition->{'_smooth_foreign_key'}) {
        delete $definition->{'_smooth_foreign_key'};
        $module_loader->load($belongs_to_class);

        my $primary_key_col = undef;

        try {
            $primary_key_col = $belongs_to_class->column_info('id');
        }
        catch {
            croak "$belongs_to_class has no column 'id'";
        }
        $definition->{'data_type'} = $primary_key_col->{'data_type'};
        $definition->{'is_foreign_key'} = 1;

        for my $attr (qw/size is_numeric/) {
            if(exists $primary_key_col->{ $attr }) {
                $definition->{ $attr } = $primary_key_col->{ $attr };
            }
        }
    }

    if(!exists $definition->{'data_type'}) {
        croak qq{ResultSource '$self' column '$column_name' => definition is missing 'data_type'};
    }
    my $sql = exists $definition->{'sql'} ? delete $definition->{'sql'} : {};
    my $related_name = exists $definition->{'related_name'} ? delete $definition->{'related_name'}
                     :                                        $self->result_source_to_relation_name($self, 1)
                     ;
    my $related_sql = exists $definition->{'related_sql'} ? delete $definition->{'related_sql'} : {};

    $self->foreign($column_name => $definition);
    $self->belongs_to($relation_name, $belongs_to_class, { "foreign.id" => "self.$column_name" }, $sql);

    if(defined $related_name) {
        $module_loader->load($belongs_to_class);
        $belongs_to_class->has_many($related_name, $self, { "foreign.$column_name" => "self.id" }, $related_sql);
    }

    return $column_name;

}

sub unique {
    my $self = shift;
    my $column_name = shift;
    my $args = shift;

    $self->add_columns($column_name => $args);
    $self->add_unique_constraint([ $column_name ]);
}

sub result_source_to_relation_name {
    my $self = shift;
    my $result_source_name = shift;
    my $plural = shift || 0;
    my $relation_name = $self->clean_source_name($result_source_name);

    $relation_name =~ s{::}{_}g;
    my @parts = split /\|/, $relation_name, 2;
    $relation_name = $parts[-1];
    $relation_name = String::CamelCase::decamelize($relation_name);

    return $relation_name.($plural && substr ($relation_name, -1, 1) ne 's' ? 's' : '');
}
sub result_source_to_class {
    my $self = shift;
    my $other_result_source = shift;
    $other_result_source =~ s{\|}{};

    # Make it possible to use fully qualified result sources, with a leading hât ("^Fully::Qualified::Result::Source").
    return substr($other_result_source, 1) if substr($other_result_source, 0, 1) eq '^';
    return $self->base_namespace($self).$self->clean_source_name($other_result_source);
}
sub base_namespace {
    my $self = shift;
    my $class = shift;
    $class =~ m{^(.*?::Result::)};
    return $1;
}
sub clean_source_name {
    my $self = shift;
    my $source_name = shift;
    $source_name =~ s{^.*?::Result::}{};

    return $source_name;
}

1;
