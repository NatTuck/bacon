package Bacon::Stmt::Switch;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has body => (is => 'ro', isa => 'Bacon::Stmt', required => 1);

sub new3 {
    my ($class, $tok, $expr, $body) = @_;
    return $class->new(token => $tok, expr => $expr, body => $body);
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    die "TODO: Implement 'Bacon::SwitchStmt->to_opencl";
}

__PACKAGE__->meta->make_immutable;
1;
