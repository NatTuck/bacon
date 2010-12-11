package Bacon::Identifier;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Utils;

use Bacon::Expr;
use Bacon::Stmt;
extends 'Bacon::Expr';

has name => (is => 'rw', isa => 'Str');

sub new_by_name {
    my ($class, $name) = @_;
    return $class->new_from_token(name => $name);
}

sub to_opencl {
    my ($self, $depth) = @_;
    return $self->name;
}

sub expand {
    my ($self) = @_;
    die $self->type;
    if ($self->type =~ /^(.*)\<(.*)\>$/) {
        my ($ptype, $type) = ($1, $2);    
        die "Found ptype: $ptype/$type";
    }
    else {
        return ($self,);
    }
}

__PACKAGE__->meta->make_immutable;
1;
