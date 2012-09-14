package Bacon::Type::Pointer;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type;
extends 'Bacon::Type';

has subtype => (is => 'ro', isa => 'Bacon::Type::Simple', required => 1);
has scope   => (is => 'ro', isa => 'Maybe[Str]');

use Carp;

sub new1 {
    my ($class, $subtype, $scope) = @_;
    unless ($subtype->isa("Bacon::Type")) {
        $subtype = Bacon::Type::Simple->new1($subtype);
    }
    return $class->new(subtype => $subtype, scope => $scope);
}

sub index {
    my ($self, $var, $env, $idx, @extra) = @_;
    croak "Wrong number of indices" unless (scalar @extra == 0);
    return $self->index_expr($var, $env, $idx);
}

sub index_expr {
    my ($self, undef, $env, $idx) = @_;
    return $idx->to_ocl($env);
}

sub index_to_ocl {
    my ($self, $var, $env, @dims) = @_;
    return $var->name . '[' . $self->index($var, $env, @dims) . ']';
}

sub to_ocl {
    my ($self) = @_;
    my $type = "";
    $type .= $self->scope . ' ' if $self->scope;
    $type .= $self->subtype->to_ocl . "*";
    return $type;
}

sub to_cpp {
    my ($self) = @_;
    die "Can't pass non-global pointer from C++" unless $self->scope eq 'global';
    return $self->subtype->to_cpp . "*";
}

sub is_returnable {
    my ($self) = @_;
    return $self->scope eq 'global';
}

__PACKAGE__->meta->make_immutable;
1;
