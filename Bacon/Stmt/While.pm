package Bacon::Stmt::While;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond => (is => 'ro', isa => 'Bacon::Expr');
has body => (is => 'ro', isa => 'Bacon::Stmt');

sub cost {
    my ($self, $fun) = @_;
    return +'inf';
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    die "Implement while->to_opencl\n";
}

__PACKAGE__->meta->make_immutable;
1;
