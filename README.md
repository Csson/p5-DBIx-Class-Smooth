# NAME

DBIx::Class::Smooth - Sugar for DBIx::Class

<div>
    <p>
    <img src="https://img.shields.io/badge/perl-5.20+-brightgreen.svg" alt="Requires Perl 5.20+" />
    <a href="https://github.com/Csson/p5-DBIx-Class-Smooth/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-DBIx-Class-Smooth/makefile-test" alt="Build status at Github" /></a>
    </p>
</div>

# VERSION

Version 0.0109, released 2025-01-18.

# SYNOPSIS

    #* The schema
    package Your::Schema;

    use parent 'DBIx::Class::Smooth::Schema';

    __PACKAGE__->load_namespaces;


    #* The project-specific DBIx::Class::Candy subclass
    package Your::Schema::Result;

    use parent 'DBIx::Class::Smooth::Result';
    sub base {
        return $_[1] || 'Your::Schema::ResultBase';
    }
    sub default_result_namespace {
        return 'Your::Schema::Result';
    }


    #* The project-specific base class for your result sources
    package Your::Schema::ResultBase;

    use parent 'DBIx::Class::Smooth::ResultBase';
    __PACKAGE__->load_components(qw/.../);


    #* A couple of result source definitions
    package Your::Schema::Result::Publisher;

    use Your::Schema::Result -components => [qw/.../];
    use DBIx::Class::Smooth::Fields -all;

    primary id => IntegerField(auto_increment => true);
        col name => VarcharField(size => 100);


    package Your::Schema::Result::Book;

    use Your::Schema::Result -components => [qw/.../];
    use DBIx::Class::Smooth::Fields -all;

    primary id => IntegerField(auto_increment => true);
    belongs Publisher => ForeignKey();
        col isbn => VarcharField(size => 13);
        col title => VarcharField(size => 150);
        col published_date => DateField();
        col language => EnumField(indexed => 1, -list => [qw/english french german spanish/]);


    #* The project-specific DBIx::Class::Candy::ResultSet subclass
    package Your::Schema::ResultSet;

    use parent 'DBIx::Class::Smooth::ResultSet';

    sub base { $_[1] || 'Your::Schema::ResultSetBase' }


    #* The project-specific base class for your resultsets
    package Your::Schema::ResultSetBase;

    use parent 'DBIx::Class::Smooth::ResultSetBase';

    __PACKAGE__->load_components(qw/
        Helper::ResultSet::DateMethods1
        Smooth::Lookup::DateTime
    /);


    #* In the Book resultset
    package Your::Schema::ResultSet::Book;

    use Your::Schema::ResultSet -components => [qw/.../];
    use DBIx::Class::Smooth::Q;

    sub get_books_by_year($self, $year) {
        return $self->filter(published_date__year => $year);
    }
    sub get_books_by_either_isbn_or_title($self, $isbn, $title) {
        return $self->filter(Q(isbn => $isbn) | Q(title => $title));
    }


    #* Elsewhere, using the Book resultset
    my $books = $schema->Book->get_books_by_year(2018);

# STATUS

This is experimental, and an early release at that. I'm using this in a couple of non-critical personal projects, so it hasn't seen heavy use. It would not be surprising if there are bad bugs. Also, it's only been tested on MySQL/MariaDB.

Documentation is expected to improve with time.

# DESCRIPTION

DBIx::Class::Smooth is a sugar layer for [DBIx::Class](https://metacpan.org/pod/DBIx%3A%3AClass), partially built on top of [DBIx::Class::Candy](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ACandy) and [DBIx::Class::Helpers](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3AHelpers).

# MORE DOCUMENTATION

for :list
\* [DBIx::Class::Smooth::Schema](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASmooth%3A%3ASchema)
\* [DBIx::Class::Smooth::Fields](https://metacpan.org/pod/DBIx%3A%3AClass%3A%3ASmooth%3A%3AFields)

# SOURCE

[https://github.com/Csson/p5-DBIx-Class-Smooth](https://github.com/Csson/p5-DBIx-Class-Smooth)

# HOMEPAGE

[https://metacpan.org/release/DBIx-Class-Smooth](https://metacpan.org/release/DBIx-Class-Smooth)

# AUTHOR

Erik Carlsson <info@code301.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
