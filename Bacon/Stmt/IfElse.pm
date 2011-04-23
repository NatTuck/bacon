package Bacon::Stmt::IfElse;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond  => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has case0 => (is => 'ro', isa => 'Bacon::Stmt', required => 1);
has case1 => (is => 'ro', isa => 'Maybe[Bacon::Stmt]', required => 1);

sub new3 {
    my ($class, $token, $expr, $block) = @_;
    return $class->new4($token, $expr, $block, undef);
}

sub new4 {
    my ($class, $token, $expr, $case0, $case1) = @_;
    return $class->new(
        token => $token,
        cond  => $expr,
        case0 => $case0,
        case1 => $case1);
}

sub kids {
    my ($self) = @_;
    return ($self->cond, $self->case0, $self->case1);
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    my $code = indent($depth) 
        . "if (" 
        . $self->cond->to_ocl($env) 
        . ")\n"
        . $self->case0->to_opencl($env, $depth + 1);

    if (defined $self->case1) {
        $code .= indent($depth) . "else\n";
        $code .= $self->case1->to_opencl($env, $depth + 1);
    }

    return $code;
}



__PACKAGE__->meta->make_immutable;
1;
