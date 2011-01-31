package Bacon::Expr::Literal;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has value => (is => 'ro', isa => 'Str', required => 1);

sub new1 {
    my ($class, $token) = @_;
    return $class->new_from_token0(value => $token);
}

sub to_ocl {
    my ($self, undef) = @_;
    return $self->value;
}

sub to_cpp {
    my ($self, undef) = @_;
    return $self->value;
}

__PACKAGE__->meta->make_immutable;
1;
