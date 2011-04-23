package Bacon::Type::Array3D;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type::Array;
extends 'Bacon::Type::Array';

has '+dims' => (default => sub { ['deep', 'rows', 'cols'] });

use Bacon::Expr::BinaryOp qw(mkop);

sub index_expr {
    my ($self, $var, $env, $dep, $row, $col) = @_;

    my $rows = Bacon::Expr::FieldAccess->new2(
        $var->name, 'rows');
    my $cols = Bacon::Expr::FieldAccess->new2(
        $var->name, 'cols');

    my $dep_off = mkop('*', $rows, $cols);

    return '(' . $dep_off->to_ocl($env) . " * " . $dep->to_ocl($env) . ') + ' 
         . '(' . $cols->to_ocl($env) . " * " . $row->to_ocl($env) . ') + '
         . $col->to_ocl($env);
}

__PACKAGE__->meta->make_immutable;
1;
