package Bacon::SwitchStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'ro', isa => 'Bacon::Expr');
has body => (is => 'ro', isa => 'Bacon::Stmt');

sub new3 {
    my ($class, $tok, $expr, $body) = @_;
    return $class->new_from_token(
        undef => $tok, expr => $expr, body => $body);
}

sub to_opencl {
    my ($self, $depth) = @_;
    return indent($depth) . $self->name . ":\n"
        .  $self->to_opencl($depth + 1);
}

__PACKAGE__->meta->make_immutable;
1;
