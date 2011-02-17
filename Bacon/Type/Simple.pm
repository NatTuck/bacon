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

# Indexing a simple type means the user is
# interacting with a local / private array.

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
