package Bacon::Type::Array2D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Array;
extends 'Bacon::Type::Array';

has '+dims' => (default => sub { ['rows', 'cols'] });

use Bacon::Expr::BinaryOp qw(mkop);

sub index_expr {
    my ($self, $var, $fun, $row, $col) = @_;

    my $cols = Bacon::Expr::FieldAccess->new2(
        $var->name, 'cols');

    my $expr = mkop('+', $col, mkop('*', $row, $cols));

    return $expr->to_ocl($fun);
}

__PACKAGE__->meta->make_immutable;
1;
