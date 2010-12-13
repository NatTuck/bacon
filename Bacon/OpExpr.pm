package Bacon::OpExpr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
use Exporter;
extends 'Bacon::Expr', 'Exporter';

our @EXPORT_OK = qw(mkop);

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]');
has post => (is => 'rw', isa => 'Bool', default => 0);

sub new_args {
    my ($class, $op, @args) = @_;
    my $self = $class->new_from_token(name => $op, args => [@args]);
    return $self;
}

sub set_post {
    my ($self) = @_;
    $self->post(1);
    return $self;
}

sub kids {
    my ($self) = @_;
    return @{$self->args};
}

sub to_opencl {
    my ($self, $depth) = @_;
    my $argc = scalar @{$self->args};

    return $self->gen_funcall($depth) if $self->name eq '(';
    return $self->gen_arrayref($depth) if $self->name eq '[';
    return $self->gen_fieldref($depth) if $self->name eq '.';
    return $self->to_opencl1($depth) if $argc == 1;
    return $self->to_opencl2($depth) if $argc == 2;
    return $self->to_opencl3($depth) if $argc == 3;
    die "Unknown op: " . $self->name . ", $argc args.";
}

sub gen_funcall {
    my ($self, $depth) = @_;
    my ($what, @args) = @{$self->args};
    my @ac = map { $_->to_opencl(0) } @args;
    return indent($depth) . $what->to_opencl(0)
        . '(' . join(', ', @ac) . ')';
}

sub gen_arrayref {
    my ($self, $depth) = @_;
    my ($what, @args) = @{$self->args};
    my @ac = map { $_->to_opencl(0) } @args;
    return indent($depth) . $what->to_opencl(0) 
        . '[' . join(', ', @ac) . ']';
}

sub gen_fieldref {
    my ($self, $depth) = @_;
    my $argc = scalar @{$self->args};
    die "Wrong number of args in field reference" unless $argc == 2;

    my $aa = $self->args->[0];
    my $bb = $self->args->[1];

    if ($aa->isa("Bacon::Identifier") && $bb->isa("Bacon::Identifier")) {
        return $aa->name . "__" . $bb->name;
    }
    else {
        return $self->to_opencl2($depth) if $argc == 2;
    }
}

sub to_opencl1 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    if ($self->post) {
        return indent($depth) . "(" . $args[0]->to_opencl(0) 
            . $self->name . ")";
    }
    else {
        return indent($depth) . "(" . $self->name 
            . $args[0]->to_opencl(0) . ")";
    }
}

sub to_opencl2 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    return indent($depth) . "(" . $args[0]->to_opencl(0)
        . $self->name . $args[1]->to_opencl(0) . ")";
}

sub to_opencl3 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    return indent($depth) . "(" . $args[0]->to_opencl(0)
        . $self->name . $args[1]->to_opencl(0) . ")";
}

sub mkop {
    my ($op, @args) = @_;
    return Bacon::OpExpr->new(
        file => $args[0]->file, line => $args[0]->line,
        name => $op, args => \@args
    );
}

__PACKAGE__->meta->make_immutable;
1;
