package Bacon::FunArg;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

extends 'Bacon::AstNode';
with 'Bacon::Variable';

use Bacon::Utils;

sub declared_variables {
    my ($self) = @_;
    return ($self->var,);
}

sub new_dimen {
    my ($self, $name) = @_;
    return ref($self)->new(
        file => $self->file, line => $self->line,
        name => $name, type => 'uint'
    );
}

sub expand_array2d {
    my ($self, $type) = @_;
    my $name = $self->name;

    my $data = ref($self)->new(
        file => $self->file, line => $self->line,
        name => $name . "__data", type => "$type*"
    );
    my $rows = $self->new_dimen($name . '__rows');
    my $cols = $self->new_dimen($name . '__cols');

    return ($data, $rows, $cols);
}

sub to_opencl {
    my ($self, undef, $depth) = @_;
    die "Unexpanded fun arg" if $self->type =~ /\<.*\>/;
    my $code = $self->type . " " . $self->name;
    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
