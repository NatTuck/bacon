package Bacon::Stmt::WithLabel;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has stmt => (is => 'ro', isa => 'Bacon::Stmt', required => 1);
has case => (is => 'ro', isa => 'Bool', default => 0);

sub new2 {
    my ($class, $label, $stmt) = @_;
    return $class->new(name => $label, stmt => $stmt);
}

sub new_case {
    my ($class, $label, $stmt) = @_;
    return $class->new(name => $label, stmt => $stmt, case => 1);
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    if ($self->case) {
        return indent($depth) . 'case ' . $self->name . ":\n"
             . $self->to_opencl($env, $depth + 1);
    }
    else {
        return indent($depth) . $self->name . ":\n"
             . $self->to_opencl($env, $depth + 1);
    }
}

__PACKAGE__->meta->make_immutable;
1;
