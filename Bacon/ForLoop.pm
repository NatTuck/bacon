package Bacon::ForLoop;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has init => (is => 'rw', isa => 'Bacon::Stmt');
has cond => (is => 'rw', isa => 'Bacon::Expr');
has incr => (is => 'rw', isa => 'Bacon::Expr');
has body => (is => 'rw', isa => 'Bacon::Stmt');

sub gen_code {
    my ($self, $depth) = @_;
    if (defined $self->expr) {
        return indent($depth) . "return;\n";
    }
    else {
        return indent($depth) . "return "
            . $self->expr->gen_code(0) . ";\n";
    }
}

__PACKAGE__->meta->make_immutable;
1;
