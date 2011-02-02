package Bacon::Stmt::For;
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

sub kids {
    my ($self) = @_;
    return ($self->init, $self->cond, $self->incr, $self->body);
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth) . "for (";

    if (defined $self->init) {
        $code .= $self->init->to_opencl($fun, 0);
        chomp($code);
        $code =~ s/;$//;
        $code .= "; ";
    }
    else {
        $code .= "; ";
    }

    if (defined $self->cond) {
        $code .= $self->cond->to_ocl($fun);
    }
    $code .= "; ";

    if (defined $self->incr) {
        $code .= $self->incr->to_ocl($fun);
    }
    $code .= ")\n";

    $code .= $self->body->to_opencl($fun, $depth);

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
