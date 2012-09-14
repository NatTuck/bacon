package Bacon::Type::Simple;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Type;
extends 'Bacon::Type';

has type => (is => 'ro', isa => 'Str', required => 1);

use Carp;

sub new1 {
    my ($class, $type) = @_;
    return $class->new(type => $type);
}

sub scope {
    my ($self) = @_;
    return "+none=;";
}

sub dims {
    my ($self) = @_;
    confess "Shouldn't be querying dims on a simple variable";
}

# Indexing a simple type means the user is
# interacting with a local / private array.

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

sub is_void {
    my ($self) = @_;
    return $self->type eq 'void';
}

sub to_ocl {
    my ($self) = @_;
    my $type = '';
    if ($self->qualifier) {
        $type .= $self->qualifier . ' ' ;
    }
    $type .= $self->type;
    return $type;
}

sub to_cpp {
    my ($self) = @_;
    return 'void' if $self->type eq 'void';
    return 'cl_' . $self->type;
}

__PACKAGE__->meta->make_immutable;
1;
