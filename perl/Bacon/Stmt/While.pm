package Bacon::Stmt::While;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
use Bacon::Template;
extends 'Bacon::Stmt', 'Bacon::Template';

use Bacon::Utils;

has cond => (is => 'ro', isa => 'Bacon::Expr');
has body => (is => 'ro', isa => 'Bacon::Stmt');

sub cost {
    my ($self, $fun) = @_;
    return +'inf';
}

sub to_opencl {
    my ($self, $env, $depth) = @_;

    return $self->fill_section(
        opencl_code => $depth,
        cond => $self->cond->to_ocl($env),
        body => $self->body->contents_to_opencl($env, $depth));
}

__PACKAGE__->meta->make_immutable;
1;

__DATA__
<<"END_OF_DATA";

__[ opencl_code ]__

while (<% $cond %>) {
    <% $body %>
}

__[ EOF ]__
END_OF_DATA
