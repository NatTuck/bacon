package Bacon::Expr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::AstNode;
extends 'Bacon::AstNode';

use Data::Dumper;
use Try::Tiny;
use Carp;

sub static_eval {
    my ($self, $env) = @_;
    my $obj_text = Dumper($self);
    confess "Cannot static_eval object:\n$obj_text\n";
}

sub is_const {
    my ($self, $env) = @_;
    return $self->try_static_eval($env) && 1;
}

sub try_static_eval {
    my ($self, $env) = @_;
    my $val;
    try {
        $val = $self->static_eval($env);
    }
    catch {
        $val = undef;
    };
    return $val;
}

sub normalize_increment {
    my ($self, $env, $var) = @_;
    return undef;
}

sub to_ocl {
    my ($self, $env) = @_;
    my $etype = ref $self ? ref $self : $self;
    confess "Cannot generate OpenCL for $etype";
}

sub to_cpp {
    my ($self, $fun) = @_;
    my $etype = ref $self ? ref $self : $self;
    my $fname = $fun->name;
    confess "Cannot generate C++ for $etype in $fname";
}

__PACKAGE__->meta->make_immutable;
1;
