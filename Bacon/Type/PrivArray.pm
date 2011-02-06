package Bacon::Type::PrivArray;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has subtype => (is => 'ro', isa => 'Str', default => "int");

use Carp;

sub new1 {
    my ($class, $subtype) = @_;
    return $class->new(subtype => $subtype);
}

sub index {
    my ($self, $var, $fun, $idx, @extra) = @_;
    croak "Wrong number of indices" unless (scalar @extra == 0);
    return $self->index_expr($var, $fun, $idx);
}

sub index_expr {
    my ($self, undef, $fun, $idx) = @_;
    return $idx->to_ocl($fun);
}

sub index_to_ocl {
    my ($self, $var, $fun, @dims) = @_;
    return $var->name . '[' . $self->index($var, $fun, @dims) . ']';
}

sub expand {
    my ($self, $var) = @_;
    croak "Can't expand PrivArray " . $var->name;
}

__PACKAGE__->meta->make_immutable;
1;
