package Bacon::Type::Array3D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Array;
extends 'Bacon::Type::Array';

has '+dims' => (default => sub { ['rows', 'cols', 'deep'] });

use Bacon::Expr::BinaryOp qw(mkop);

sub index_expr {
    my ($self, $var, $fun, $dep, $row, $col) = @_;

    my $rows = Bacon::Expr::FieldAccess->new2(
        $var->name, 'rows');
    my $cols = Bacon::Expr::FieldAccess->new2(
        $var->name, 'cols');

    my $dep_off = mkop('*', $dep, mkop('*', $rows, $cols));
    my $row_off = mkop('*', $row, $cols);
    my $expr0 = mkop('+', $dep_off, $row_off);
    my $expr  = mkop('+', $col, $expr0);

    return $expr->to_ocl($fun);
}

__PACKAGE__->meta->make_immutable;
1;
