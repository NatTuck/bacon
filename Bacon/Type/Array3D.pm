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
    my ($self, $var, $fun, $dep, $row, $col) = @_;

    my $rows = Bacon::Expr::FieldAccess->new2(
        $var->name, 'rows');
    my $cols = Bacon::Expr::FieldAccess->new2(
        $var->name, 'cols');

    my $dep_off = mkop('*', $rows, $cols);

    return '(' . $dep_off->to_ocl($fun) . " * " . $dep->to_ocl($fun) . ') + ' 
         . '(' . $cols->to_ocl($fun) . " * " . $row->to_ocl($fun) . ') + '
         . $col->to_ocl($fun);
}

__PACKAGE__->meta->make_immutable;
1;
