package Bacon::Type::Array2D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Base;
extends 'Bacon::Type::Base';

has '+dims' => (default => sub { ['rows', 'cols'] });

sub index_expr {
    my ($self, $fun, $row, $col) = @_;

    my $cols = Bacon::Expr::FieldAccess->new2(
        $self->name, 'cols');

    my $expr = mkop('+', $col, mkop('*', $row, $cols));

    return $expr->to_opencl($fun, 0);
}

__PACKAGE__->meta->make_immutable;
1;
