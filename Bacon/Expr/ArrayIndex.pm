package Bacon::Expr::ArrayIndex;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has dims => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]', required => 1);

use Bacon::Expr::FieldAccess;
use Bacon::Expr::BinaryOp qw(mkop);

sub new_dims {
    my ($class, $name, @dims) = @_;
    return $class->new_attrs(name => $name, dims => [@dims]);
}

sub kids {
    my ($self) = @_;
    return @{$self->dims};
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $dims = scalar @{$self->dims};

    return $self->gen_aref1($fun, $depth) if $dims == 1;
    return $self->gen_aref2($fun, $depth) if $dims == 2;
    return $self->gen_aref3($fun, $depth) if $dims == 3;
    
    confess "Array indexing must be 1, 2, or 3D";
}

sub gen_aref1 {
    my ($self, $fun, $depth) = @_;
    my ($expr) = @{$self->dims};
    return indent($depth)
        . $self->name
        . '['
        . $expr->to_opencl($fun, 0)
        . ']';
}

sub gen_aref2 {
    my ($self, $fun, $depth) = @_;
    my ($row, $col) = @{$self->dims};

    my $cols = Bacon::Expr::FieldAccess->new2(
        $self->name, 'cols');

    my $expr = mkop('+', $col, mkop('*', $row, $cols));

    return indent($depth) 
        . $self->name . "__data"
        . '[' 
        . $expr->to_opencl($fun, 0) 
        . ']';
}

sub gen_aref3 {
    my ($self, $fun, $depth) = @_;
    my ($dep, $row, $col) = @{$self->dims};
    
    my $rows = Bacon::Expr::FieldAccess->new2(
        $self->name, 'rows');
    my $cols = Bacon::Expr::FieldAccess->new2(
        $self->name, 'cols');

    my $dep_off = mkop('*', $dep, mkop('*', $rows, $cols));
    my $row_off = mkop('*', $row, $cols);
    my $expr0 = mkop('+', $dep_off, $row_off);
    my $expr  = mkop('+', $col, $expr0);

    return indent($depth) 
        . $self->name . "__data"
        . '[' 
        . $expr->to_opencl($fun, 0) 
        . ']';
}

__PACKAGE__->meta->make_immutable;
1;
