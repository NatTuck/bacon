package Bacon::IfStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond => (is => 'ro', isa => 'Bacon::Expr');
has is_t => (is => 'ro', isa => 'Bacon::Stmt');
has is_f => (is => 'ro', isa => 'Bacon::Stmt');

sub new3 {
    my ($class, $tok, $cond, $is_t) = @_;
    return $class->new_from_token(
        undef => $tok, cond => $cond,
        is_t => $is_t, is_f => undef);
}

sub new3 {
    my ($class, $tok, $cond, $is_t, $is_f) = @_;
    return $class->new_from_token(
        undef => $tok, cond => $cond,
        is_t => $is_t, is_f => $is_f);
}

sub to_opencl {
    my ($self, $depth) = @_;
    return indent($depth) . "if (" . $self->cond->to_opencl(0) . ")\n"
         . $self->if_t->to_opencl($depth + 1) . 
         ((defined $self->if_f)
            ? ("\nelse\n" . $self->if_f->to_opencl($depth + 1))
            : ""
         );
}

__PACKAGE__->meta->make_immutable;
1;
