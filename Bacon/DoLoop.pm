package Bacon::DoLoop;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond => (is => 'rw', isa => 'Bacon::Expr');
has body => (is => 'rw', isa => 'Bacon::Stmt');

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    die "TODO: DoLoop->to_opencl";
}

__PACKAGE__->meta->make_immutable;
1;
