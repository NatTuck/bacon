package Bacon::Expr::Identifier;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Utils;

use Bacon::Expr;
extends 'Bacon::Expr';

has name => (is => 'rw', isa => 'Str');

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_token(name => $name);
}

sub to_ocl {
    my ($self, undef) = @_;
    my $name = $self->name;
    # Rename "magic" variables.
    $name =~ s/^\$/_bacon__S/;
    return $name;
}

sub to_cpp {
    my ($self, undef) = @_;
    my $name = $self->name;
    confess "Can't use magic variables in C++" if ($name =~ /^\$/);
    return $name;
}

__PACKAGE__->meta->make_immutable;
1;
