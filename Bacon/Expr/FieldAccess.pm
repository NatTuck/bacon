package Bacon::Expr::FieldAccess;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name  => (is => 'ro', isa => 'Str', required => 1);
has field => (is => 'ro', isa => 'Str', required => 1);

sub new2 {
    my ($class, $name, $field) = @_;
    return $class->new_attrs(name => $name, field => $field);
}

sub static_eval {
    my ($self, $fun) = @_;
    my $sym = $self->name . "." . $self->field;
    my $val = $fun->get_const($sym);
    return $val if (defined $val);
    die "No static value for $sym";
}

sub to_ocl {
    my ($self, $fun) = @_;
    my $var = $fun->lookup_variable($self->name)
        or confess "Unknown variable: " . $self->name;
    return $self->name . "." . $self->field;
}

sub to_cpp {
    my ($self, $fun) = @_;
    confess "Undefined function" unless defined $fun;
    my $var = $fun->lookup_variable($self->name)
        or confess "Unknown variable: " . $self->name;

    return $self->name . '.' . $self->field . '()';
}

__PACKAGE__->meta->make_immutable;
1;
