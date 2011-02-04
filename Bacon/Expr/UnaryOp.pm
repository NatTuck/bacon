package Bacon::Expr::UnaryOp;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Data::Dumper;
use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has arg0 => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has post => (is => 'rw', isa => 'Bool', default => 0);

sub new2 {
    my ($class, $op, $arg) = @_;
    return $class->new(
        file => $arg->file, line => $arg->line,
        name => $op->text, arg0 => $arg);
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

sub to_ocl {
    my ($self, $fun, $depth) = @_;
    if ($self->post) {
        return "(" 
            . $self->arg0->to_ocl($fun) 
            . $self->name 
            . ")";
    }
    else {
        return "(" 
            . $self->name 
            . $self->arg0->to_ocl($fun, 0) 
            . ")";
    }
}

sub to_cpp {
    my ($self, $fun, $depth) = @_;
    if ($self->post) {
        return "(" 
            . $self->arg0->to_cpp($fun) 
            . $self->name 
            . ")";
    }
    else {
        return "(" 
            . $self->name 
            . $self->arg0->to_cpp($fun, 0) 
            . ")";
    }
}

__PACKAGE__->meta->make_immutable;
1;
