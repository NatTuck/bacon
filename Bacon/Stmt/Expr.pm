package Bacon::Stmt::Expr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'ro', isa => 'Bacon::Expr');

sub kids {
    my ($self) = @_;
    return ($self->expr,);
}

sub new2 {
    my ($class, $tok, $expr) = @_;
    return $class->new(token => $tok, expr => $expr);
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    if (!defined $self->expr) {
        return indent($depth) . "/* pass */;\n";
    }
    else {
        return indent($depth) . $self->expr->to_ocl($env) . ";\n";
    }
}

__PACKAGE__->meta->make_immutable;
1;
