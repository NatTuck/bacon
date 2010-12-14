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

sub to_opencl {
    my ($self, undef, $depth) = @_;
    return indent($depth) . $self->value;
}

__PACKAGE__->meta->make_immutable;
1;
