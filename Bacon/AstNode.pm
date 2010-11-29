package Bacon::AstNode;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

has file => (is => 'ro', isa => 'Str', required => 1);
has line => (is => 'ro', isa => 'Int', required => 1);

sub source {
    my ($self) = @_;
    return $self->file . ":" . $self->line;
}

sub gen_code {
    return "((** Invalid AST Node **))\n";
}

__PACKAGE__->meta->make_immutable;
1;
