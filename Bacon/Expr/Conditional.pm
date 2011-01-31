package Bacon::Expr::Conditional;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

our @EXPORT_OK = qw(mkop);

use Bacon::Utils;

has cond   => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has case0  => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has case1  => (is => 'ro', isa => 'Bacon::Expr', required => 1);

sub new3 {
    my ($class, $cond, $case0, $case1) = @_;
    return $class->new_attrs(
        name => $cond, case0 => $case0, case1 => $case1);
}

sub kids {
    my ($self) = @_;
    return ($self->cond, $self->case0, $self->case1);
}

sub to_ocl {
    my ($self, $fun) = @_;
    return "("
        . $self->cond->to_ocl($fun)
        . " ? "
        . $self->case0->to_ocl($fun)
        . " : "
        . $self->case1->to_ocl($fun)
        . ")";
}

sub to_cpp {
    my ($self, $fun) = @_;
    return "("
        . $self->cond->to_cpp($fun)
        . " ? "
        . $self->case0->to_cpp($fun)
        . " : "
        . $self->case1->to_cpp($fun)
        . ")";
}

__PACKAGE__->meta->make_immutable;
1;
