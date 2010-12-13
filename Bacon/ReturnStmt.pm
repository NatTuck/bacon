package Bacon::ReturnStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'rw', isa => 'Maybe[Bacon::Expr]');

sub kids {
    my ($self) = @_;
    return ($self->expr,);
}

sub find_retvar {
    my ($self) = @_;

    unless ($self->expr->isa("Bacon::Identifier")) {
        my $where = $self->source;
        die "Item returned must be a single variable name at $where\n";
    }

    return ($self->expr,);
}

sub to_opencl {
    my ($self, $depth) = @_;
    if (!defined $self->expr) {
        return indent($depth) . "return;\n";
    }
    else {
        return indent($depth) . "return "
            . $self->expr->to_opencl(0) . ";\n";
    }
}

__PACKAGE__->meta->make_immutable;
1;
