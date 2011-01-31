package Bacon::Stmt::IfElse;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond  => (is => 'ro', isa => 'Bacon::Expr');
has case0 => (is => 'ro', isa => 'Bacon::Stmt');
has case1 => (is => 'ro', isa => 'Maybe[Bacon::Stmt]');

sub new3 {
    my ($class, $token, $expr, $block) = @_;
    return $class->new4($token, $expr, $block, undef);
}

sub new4 {
    my ($class, $token, $expr, $case0, $case1) = @_;
    return $class->new_from_token0(
        undef, $token,
        cond  => $expr,
        case0 => $case0,
        case1 => $case1
    );
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth) 
        . "if (" 
        . $self->cond->to_ocl($fun) 
        . ")\n"
        . $self->case0->to_opencl($fun, $depth);

    if (defined $self->case1) {
        $code .= "\nelse\n";
        $code .= $self->case1->to_opencl($fun, $depth);
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
