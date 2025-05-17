use 5.40.0;
        
package DBIx::Class::Smooth::Exception::Factory;

use strict;
use warnings;

# ABSTRACT: Sugar for DBIx::Class
# AUTHORITY
our $VERSION = '0.0109';

use Moo;
use Contextual::Return;
use Data::Dumper;
use syntax 'junction';

has schema => (is => 'ro');
has exceptions => (

    # Work in progress
    is => 'lazy',
    default => sub($self) {
        my @sources = $self->schema->sources;
        my $lookup = {
            DoesNotExist => { map { $_ => $self->generate_does_not_exist($_) } @sources },
            MultipleObjectsReturned => { },
        };
        say(Data::Dumper->Dump([$lookup]));
        return $lookup;
    },
);

sub generate_does_not_exist($self, $result_class) {
    return $self->_generate_exception($result_class, 'DoesNotExist', "%s not found");
}
sub generate_multiple_objects_returned($self, $result_class) {
    return $self->_generate_exception($result_class, 'MultipleObjectsReturned', "%s returned multiple objects");
}

sub _generate_exception($self, $result_class, $type, $message_template) {
    my @allowed_types = (qw/
        DoesNotExist
        MultipleObjectsReturned
    /);
    die "Bad type: $type" if none(@allowed_types) eq $type;

    (my $wanted_model_name = $result_class) =~ s{.*Result::}{};

    my $base = $self->create_base_exception($type);
    my $orchestrator = $self->create_orchestrator($type);

    my $exception_hash = {};

    for my $source (sort $self->schema->sources) {
        (my $model_name = $source) =~ s{::}{_}g;

        my $hash;
        my $model_method;
        my $bool;

        if ($source eq $wanted_model_name) {
            $hash = {
                message => sprintf $message_template, $model_name,
            };
            $bool = 1;
            $exception_hash = $hash;
        }
        else {
            $hash = {
                message => '',
            };
            $bool = 0;
        }
        $model_method = sub ($self) {
            return
                SCALAR { $hash->{'message'} }
                BOOL { $bool }
                HASHREF { $hash }
            ;
        };
        my $model_exception = $self->create_model_exception($model_name, $hash);
        $self->inject_method($model_exception, $model_name, $model_method);
        $self->inject_method($orchestrator, $model_name, $model_method);
    }
    my $base_method = sub ($self) {
        return
            SCALAR { $orchestrator }
            BOOL { 1 }
            HASHREF { $exception_hash }
        ;
    };
    $self->inject_method($base, $type, $base_method);
    return $base;

}

sub create_base_exception($self, $classname, $hash = {}) {
    return bless $hash => 'DBIx::Class::Smooth::Exception::Generated::Base::' . $classname;
}

sub create_orchestrator($self, $classname, $hash = {}) {
    return bless $hash => 'DBIx::Class::Smooth::Exception::Orchestrator::' . $classname;
}
sub create_model_exception($self, $classname, $hash) {
    return bless $hash => 'DBIx::Class::Smooth::Exception::Generated::DoesNotExist::' . $classname;
}

sub inject_method($self, $object, $method_name, $sub) {
    no strict 'refs';
    no warnings 'redefine';
    my $classname = ref $object;
    {
        *{ $classname . '::' . $method_name} = $sub;
    }
}

1;