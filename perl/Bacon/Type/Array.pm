package Bacon::Type::Array;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type;
extends 'Bacon::Type';

has dims    => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['size'] });
has scope   => (is => 'ro', isa => 'Str', required => 1);
has subtype => (is => 'ro', isa => 'Bacon::Type::Simple', required => 1);

use Carp;
use Data::Dumper;

sub new1 {
    my ($class, $subtype, $scope) = @_;
    $scope ||= 'global';
    return $class->new(subtype => $subtype, scope => $scope);
}

sub index {
    my ($self, $var, $env, @vals) = @_;
    my $type_n = scalar @{$self->dims};
    my $user_n = scalar @vals;
    confess "Wrong number of indices (got $user_n of $type_n on ${\$var->name})" 
        unless ($type_n == $user_n);
    return $self->index_expr($var, $env, @vals);
}

sub index_expr {
    my ($self, undef, $env, $idx) = @_;
    return $idx->to_ocl($env);
}

sub index_to_ocl {
    my ($self, $var, $env, @dims) = @_;
    return $var->name . ".data"
        . '['
        . $self->index($var, $env, @dims)
        . ']';
}

sub data_var {
    my ($self, $var) = @_;
    my $name = $var->name;
    return Bacon::Variable->new(
        name => $name . "__data", 
        type => Bacon::Type::Pointer->new1($self->subtype, $self->scope));
}

sub expand {
    my ($self, $var) = @_;
    my $name = $var->name;
    my @items = ();

    push @items, $self->data_var($var);

    for my $dim (@{$self->dims}) {
        push @items, Bacon::Variable->new(
            name => $name . "__" . $dim, 
            type => Bacon::Type::Simple->new1("uint"));
    }
    return @items;
}

sub to_ocl {
    my ($self) = @_;
    return '_Bacon__' . $self->type . '__' . $self->scope . '__' . $self->subtype->type;
}

sub to_cpp {
    my ($self) = @_;
    return "Bacon::" . $self->type . '<' . $self->subtype->to_cpp . '>';
}

sub is_returnable {
    my ($self) = @_;
    return $self->scope eq 'global';
}

__PACKAGE__->meta->make_immutable;
1;
