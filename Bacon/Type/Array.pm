package Bacon::Type::Array;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has dims    => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { ['size'] });
has subtype => (is => 'ro', isa => 'Str', default => "int");

use Carp;

sub new1 {
    my ($class, $subtype) = @_;
    return $class->new(subtype => $subtype);
}

sub index {
    my ($self, $var, $fun, @vals) = @_;
    my $type_n = scalar @{$self->dims};
    my $user_n = scalar @vals;
    confess "Wrong number of indices (got $user_n of $type_n on ${\$var->name})" 
        unless ($type_n == $user_n);
    return $self->index_expr($var, $fun, @vals);
}

sub index_expr {
    my ($self, undef, $fun, $idx) = @_;
    return $idx->to_ocl($fun);
}

sub index_to_ocl {
    my ($self, $var, $fun, @dims) = @_;
    return $var->name . ".data"
        . '['
        . $self->index($var, $fun, @dims)
        . ']';
}

sub expand {
    my ($self, $var) = @_;
    my $name = $var->name;
    my @items = ();

    push @items, Bacon::Variable->new2($name . "__data", $self->subtype . "*");

    for my $dim (@{$self->dims}) {
        push @items, Bacon::Variable->new2($name . "__" . $dim, "uint");
    }
    return @items;
}

__PACKAGE__->meta->make_immutable;
1;
