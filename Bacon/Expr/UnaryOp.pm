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
has post => (is => 'ro', isa => 'Bool', default => 0);

sub mutates_variable {
    my ($self, $var) = @_;
    my @mutating_ops = qw(++ --);

    unless ($self->arg0->isa('Bacon::Expr::Identifier') && 
            $self->arg0->name eq $var) {
        return 0;
    }

    for my $op (@mutating_ops) {
        return 1 if ($op eq $self->name);
    }

    return 0;
}

sub normalize_increment {
    my ($self, $env, $var) = @_;

    unless ($self->arg0->isa('Bacon::Expr::Identifier') && 
            $self->arg0->name eq $var) {
        return undef;
    }

    if ($self->name eq '++') {
        return +1;
    }

    if ($self->name eq '--') {
        return -1;
    }

    return undef;
}

sub kids {
    my ($self) = @_;
    return ($self->arg0,);
}

sub to_ocl {
    my ($self, $env) = @_;
    if ($self->post) {
        return "(" 
            . $self->arg0->to_ocl($env) 
            . $self->name 
            . ")";
    }
    else {
        return "(" 
            . $self->name 
            . $self->arg0->to_ocl($env) 
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
