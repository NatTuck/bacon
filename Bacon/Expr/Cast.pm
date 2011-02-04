package Bacon::Expr::Cast;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

has type => (is => 'ro', isa => 'Str', required => 1);
has arg0 => (is => 'ro', isa => 'Bacon::Expr', required => 1);

sub new2 {
    my ($class, $type, $arg0) = @_;
    return $class->new(
        file => $arg0->file, line => $arg0->line,
        type => $type, arg0 => $arg0);
}

sub kids {
    my ($self) = @_;
    return ($self->arg0,);
}

sub to_ocl {
    my ($self, $fun, $depth) = @_;
    return "((" . $self->type . ")"
        . $self->arg0->to_ocl($fun) 
        . ")";
}

sub to_cpp {
    my ($self, $fun, $depth) = @_;
    return "((" . $self->type . ")"
        . $self->arg0->to_cpp($fun) 
        . ")";
}

__PACKAGE__->meta->make_immutable;
1;
