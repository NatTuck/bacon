package Bacon::Stmt::Block;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Data::Dumper;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has body => (is => 'rw', isa => 'ArrayRef[Bacon::Stmt]',
    default => sub { [] });

sub kids {
    my ($self) = @_;
    return (@{$self->body});
}

# Return a list of variable declarations in this block.

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth - 1) . "{\n";
    $code .= $self->contents_to_opencl($fun, $depth);
    $code .= indent($depth - 1) . "}\n";
    return $code;
}

sub contents_to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = '';

    for my $smt (@{$self->body}) {
        $code .= $smt->to_opencl($fun, $depth);
    }

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
