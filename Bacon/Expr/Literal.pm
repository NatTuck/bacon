package Bacon::Expr::Literal;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::BigNum;

use Exporter; 
use Bacon::Expr;
extends 'Bacon::Expr', 'Exporter';

our @EXPORT_OK = qw(mklit);

use Bacon::Utils;

has value => (is => 'ro', isa => 'BigNum', required => 1);

sub mklit {
    my ($value) = @_;
    return __PACKAGE__->new(value => embiggen($value), source => 'generated:0');
}

sub to_ocl {
    my ($self, undef) = @_;
    if ($self->value->isa('Math::BigFloat')) {
        return $self->value;
    }
    else {
        return $self->value;
    }
}

sub to_cpp {
    my ($self, undef) = @_;
    return $self->value;
}

sub static_eval {
    my ($self, undef) = @_;
    return $self->value;
}

__PACKAGE__->meta->make_immutable;
1;
