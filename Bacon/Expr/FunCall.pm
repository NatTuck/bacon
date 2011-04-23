package Bacon::Expr::FunCall;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

sub new_args {
    my ($class, $op, @args) = @_;
    return $class->new_from_token0(name => $op, args => [@args]);
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_ocl {
    my ($self, $env) = @_;
    my $name = $self->name;

    my @args = @{$self->args};
    my @ac   = map { $_->to_ocl($env) } @args;
    return $name
        . '(' 
        . join(', ', @ac) 
        . ')';
}

sub to_cpp {
    my ($self, $fun) = @_;

    my @args = @{$self->args};
    my @ac   = map { $_->to_cpp($fun) } @args;
    return $self->name 
        . '(' 
        . join(', ', @ac) 
        . ')';
}

__PACKAGE__->meta->make_immutable;
1;
