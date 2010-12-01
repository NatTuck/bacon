package Bacon::Function;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::AstNode;
extends 'Bacon::AstNode';

has name => (is => 'rw', isa => 'Str');
has args => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]');
has retv => (is => 'rw', isa => 'Bacon::Variable');
has vars => (is => 'rw', isa => 'ArrayRef[Bacon::Variable]');
has body => (is => 'rw', isa => 'ArrayRef[Bacon::Stmt]');
has kern => (is => 'rw', isa => 'Bool');
has dims => (is => 'rw', isa => 'ArrayRef[Int]');

sub new_parts {
    my ($class, $specs, $decl, $body) = @_;
    my $self = $decl->update_with($specs);
    $self->vars($body->vars) if defined $body->vars;
    $self->body($body->code) if defined $body->code;
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
