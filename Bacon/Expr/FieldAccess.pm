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

sub to_opencl {
    my ($self, $fun, undef) = @_;
    my $var = $fun->vtab->{$self->name};

    if ($var->type =~ /^array.*\<.*\>$/i) {
        return $self->name . "__" . $self->field;
    }
    else {
        return $self->name . "." . $self->field;
    }
}

sub to_dim {
    my ($self) = @_;
    return $self->name . "." . $self->field;
}

__PACKAGE__->meta->make_immutable;
1;
