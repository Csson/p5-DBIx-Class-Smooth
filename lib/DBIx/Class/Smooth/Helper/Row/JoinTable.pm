use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::Row::JoinTable;

# ABSTRACT: Short intro
# AUTHORITY
our $VERSION = '0.0109';

use parent 'DBIx::Class::Row';
use String::CamelCase;
use Module::Loader;
use Syntax::Keyword::Try;
use Carp qw/croak/;
use Ref::Util qw/is_hashref/;
use DBIx::Class::Candy::Exports;
use DBIx::Class::Smooth::Helper::Util qw/result_source_to_class result_source_to_relation_name clean_source_name/;

use experimental qw/postderef signatures/;

export_methods [qw/
    join_table
/];

state $module_loader = Module::Loader->new;

sub join_table($self, $left, $right) {

    # In My::Result::Match
    # join_table 'Team', { source => 'Team', prefix => 'opponent' }
    # later: $schema->Match->filter(team_id => 1, opponent_team_id => 3);

    # or:
    # join_table 'Team', { source => 'Team', basename => 'opponent' }
    # $schema->Match->filter(team_id => 1, opponent_id => 3);
    my $extract_props = sub($props) {
        if (!is_hashref($props)) {
            return ($props, '', '');
        }
        my $source = $props->{'source'};
        my $basename = $props->{'basename'} || undef;
        my $prefix = $props->{'prefix'} || '';
        my $suffix = $props->{'suffix'} || '';

        return ($source, $basename, $prefix, $suffix);
    };
    my($left_source, $left_basename, $left_prefix, $left_suffix) = $extract_props->($left);
    my($right_source, $right_basename, $right_prefix, $right_suffix) = $extract_props->($right);

    my $left_class = result_source_to_class($self, $left_source);
    my $right_class = result_source_to_class($self, $right_source);
    my $via_class = $self;

    my $to_via_relation_name = result_source_to_relation_name($via_class, 1);
    my $via_to_right_relation_name;
    my $left_to_right_relation_name;
    if ($right_basename) {
        $via_to_right_relation_name = $right_basename;
        $left_to_right_relation_name = $right_basename.(substr ($right_basename, -1, 1) ne 's' ? 's' : '');
    }
    else {
        $via_to_right_relation_name = result_source_to_relation_name($right_source, 0, { prefix => $right_prefix, suffix => $right_suffix });
        $left_to_right_relation_name = result_source_to_relation_name($right_source, 1, { prefix => $right_prefix, suffix => $right_suffix });
    }

    my $via_to_left_relation_name;
    my $right_to_left_relation_name;

    if ($left_basename) {
        $via_to_left_relation_name = $left_basename;
        $right_to_left_relation_name = $left_basename.(substr ($left_basename, -1, 1) ne 's' ? 's' : '');
    }
    else {
        $via_to_left_relation_name = result_source_to_relation_name($left_source, 0, { prefix => $left_prefix, suffix => $left_suffix });
        $right_to_left_relation_name = result_source_to_relation_name($left_source, 1, { prefix => $left_prefix, suffix => $left_suffix });
    }

    # my $left_column_name_in_via = $left_prefix . $via_to_left_relation_name . $left_suffix . '_id';
    # my $right_column_name_in_via = $right_prefix . $via_to_right_relation_name . $right_suffix . '_id';

    $via_class->primary_belongs($left_source, $via_to_left_relation_name, { _smooth_foreign_key => 1 });
    $via_class->primary_belongs($right_source, $via_to_right_relation_name, { _smooth_foreign_key => 1 });

    $module_loader->load($left_class);
    $module_loader->load($right_class);

    $left_class->many_to_many($left_to_right_relation_name, $to_via_relation_name, $via_to_right_relation_name);
    $right_class->many_to_many($right_to_left_relation_name, $to_via_relation_name, $via_to_left_relation_name);
}

1;
