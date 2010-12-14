package Bacon::Expr::UnaryOp;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has arg0 => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has post => (is => 'rw', isa => 'Bool', default => 0);

sub new2 {
    my ($class, $op, $arg) = @_;
    return $class->new_from_token(name => $op, arg0 => $arg);
}

sub set_post {
    my ($self) = @_;
    $self->post(1);
    return $self;
}

sub kids {
    my ($self) = @_;
    return ($self->arg0,);
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    if ($self->post) {
        return indent($depth) 
            . "(" 
            . $self->arg0->to_opencl($fun, 0) 
            . $self->name 
            . ")";
    }
    else {
        return indent($depth) 
            . "(" 
            . $self->name 
            . $self->arg0->to_opencl($fun, 0) 
            . ")";
    }
}

__PACKAGE__->meta->make_immutable;
1;
