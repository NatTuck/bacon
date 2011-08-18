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
    return $class->new(cond => $cond, case0 => $case0, case1 => $case1);
}

sub kids {
    my ($self) = @_;
    return ($self->cond, $self->case0, $self->case1);
}

sub static_eval {
    my ($self, $env) = @_;
    my $cond = $self->cond->static_eval($env);

    if ($cond) {
        return $self->case0->static_eval($env);
    }
    else {
        return $self->case1->static_eval($env);
    }
}

sub to_ocl {
    my ($self, $env) = @_;
    return "("
        . $self->cond->to_ocl($env)
        . " ? "
        . $self->case0->to_ocl($env)
        . " : "
        . $self->case1->to_ocl($env)
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
