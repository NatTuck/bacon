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

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth) 
        . "if (" 
        . $self->cond->to_opencl($fun, 0) 
        . ")\n"
        . $self->case0->to_opencl($fun, $depth + 1);

    if (defined $self->case1) {
        $code .= "\nelse\n";
        $code .= $self->if_f->to_opencl($fun, $depth + 1);
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
