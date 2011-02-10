package Bacon::Stmt::VarDecl;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
use Bacon::Variable;
extends 'Bacon::Stmt', 'Bacon::Variable';

has dims => (is => 'ro', isa => 'Maybe[ArrayRef[Bacon::Expr]]');
has init => (is => 'ro', isa => 'Maybe[Bacon::Expr]');

use Data::Dumper;

use Bacon::Utils;
use Bacon::Expr::BinaryOp qw(mkop);

sub kids {
    my ($self) = @_;
    my @kids = ();
    push @kids, @{$self->dims} if (defined $self->dims);
    push @kids, $self->init if (defined $self->init);
    return @kids;
}

sub new_dimen {
    my ($self, $name, $val_expr) = @_;
    return ref($self)->new(
        file => $self->file, line => $self->line,
        name => $name, type => 'uint', init => $val_expr
    );
}

sub to_funarg {
    my ($self) = @_;
    return Bacon::FunArg->new(
        file => $self->file, line => $self->line,
        name => $self->name, type => $self->type,
    );
}

sub to_cpp_decl {
    my ($self, $fun) = @_;
    my @dims = map { $_->to_cpp($fun) } @{$self->dims};
    my $code = '';
    $code .= $self->type->to_cpp . ' ';
    $code .= $self->name . ' ';
    $code .= '(';
    $code .= join(', ', @dims);
    $code .= ');';
    return $code;
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;

    my $code = indent($depth) . $self->type->to_ocl . " " . $self->name;

    if (defined $self->init) {
        $code .= " = " . $self->init->to_ocl($fun);
    }
    elsif (defined $self->dims) {
        $code .= '[' . join(', ', map { $_->to_ocl($fun) } @{$self->dims}) . ']';
    }

    $code .= ";\n";
    return $code;
}

sub decl_to_opencl {
    my ($self, $fun, $depth) = @_;
    return "";

    my $code = indent($depth);
    $code .= $self->type . ' ' . $self->name;

    if (defined $self->dims) {
        assert_type($fun, 'Bacon::Kernel');

        my @dims = map { $_->to_ocl($fun) } @{$self->dims};
        $code .= '[' . join(', ', @dims) . ']';
    }

    if (defined $self->init && $self->init->isa('Bacon::Expr::Literal')) {
        $code .= ' = ' . $self->init->to_ocl($fun); 
    }

    $code .= ";\n";
    return $code;
}

sub cpp_dims {
    my ($self, $fun) = @_;
}

__PACKAGE__->meta->make_immutable;
1;
