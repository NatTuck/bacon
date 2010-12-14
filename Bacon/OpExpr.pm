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
use Bacon::RawText;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]');
has post => (is => 'rw', isa => 'Bool', default => 0);

sub mkop {
    my ($op, @args) = @_;
    return Bacon::OpExpr->new(
        file => $args[0]->file, line => $args[0]->line,
        name => $op, args => \@args
    );
}

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
    my $dims = scalar @args;

    return $self->gen_aref1($depth) if $dims == 1;
    return $self->gen_aref2($depth) if $dims == 2;
    return $self->gen_aref3($depth) if $dims == 3;
    
    confess "Array indexing must be 1, 2, or 3D";
    my @ac = map { $_->to_opencl(0) } @args;
    return indent($depth) . $what->to_opencl(0) 
        . '[' . join(', ', @ac) . ']';
}

sub gen_aref1 {
    my ($self, $depth) = @_;
    my ($what, $expr) = @{$self->args};
    my $code = indent($depth);
    $code .= $what->to_opencl(0);
    $code .= '[' . $expr->to_opencl(0) . ']';
    return $code;
}

sub gen_aref2 {
    my ($self, $depth) = @_;
    my ($what, $row, $col) = @{$self->args};
    assert_type($what, "Bacon::Identifier");

    my $name = $what->name;
    my $cols = mkraw($name . "__cols");

    my $expr = mkop('+', $col, mkop('*', $row, $cols));

    my $code = indent($depth) . $name;
    $code .= '[' . $expr->to_opencl(0) . ']';
    return $code;
}

sub gen_aref3 {
    my ($self, $depth) = @_;
    my ($what, $dep, $row, $col) = @{$self->args};
    assert_type($what, "Bacon::Identifier");

    my $name = $what->name;
    my $rows = mkraw($name . "__rows");
    my $cols = mkraw($name . "__cols");
    
    my $dep_off = mkop('*', $dep, mkop('*', $rows, $cols));
    my $row_off = mkop('*', $row, $cols);
    my $expr0 = mkop('+', $dep_off, $row_off);
    my $expr  = mkop('+', $col, $expr0);

    my $code = indent($depth) . $name;
    $code .= '[' . $expr->to_opencl(0) . ']';
    return $code;
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

__PACKAGE__->meta->make_immutable;
1;
