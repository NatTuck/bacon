package Bacon::LabeledStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str');
has stmt => (is => 'ro', isa => 'Bacon::Stmt');

sub new2 {
    my ($class, $label, $stmt) = @_;
    return $class->new_from_token($label, stmt => $stmt);
}

sub gen_code {
    my ($self, $depth) = @_;
    return indent($depth) . $self->name . ":\n"
        .  $self->gen_code($depth + 1);
}

__PACKAGE__->meta->make_immutable;
1;
