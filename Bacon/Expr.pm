package Bacon::Expr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::AstNode;
extends 'Bacon::AstNode';

use Data::Dumper;
use Carp;

sub static_eval {
    my ($self, $fun) = @_;
    my $obj_text = Dumper($self);
    confess "Cannot static_eval object:\n$obj_text\n";
}

sub to_ocl {
    my ($self, $fun) = @_;
    my $etype = ref $self ? ref $self : $self;
    my $fname = $fun->name;
    confess "Cannot generate OpenCL for $etype in $fname";
}

sub to_cpp {
    my ($self, $fun) = @_;
    my $etype = ref $self ? ref $self : $self;
    my $fname = $fun->name;
    confess "Cannot generate C++ for $etype in $fname";
}

__PACKAGE__->meta->make_immutable;
1;
