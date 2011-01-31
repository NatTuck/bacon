package Bacon::Stmt::VarDecl;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

extends 'Bacon::Stmt', 'Bacon::Variable';

has dims => (is => 'ro', isa => 'Maybe[ArrayRef[Bacon::Expr]]');
has init => (is => 'ro', isa => 'Maybe[Bacon::Expr]');

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

sub expand_array2d {
    my ($self, $type) = @_;
    my $name = $self->name;

    die "Wrong number of dims for array2d"
        unless scalar @{$self->dims} == 2;

    my $rows_expr = $self->dims->[0];
    my $cols_expr = $self->dims->[1];

    my $size_expr = mkop('+', 
        mkop('*', $rows_expr, $cols_expr),
        $cols_expr
    );

    my $data = ref($self)->new(
        file => $self->file, line => $self->line,
        name => $name . "__data", type => "$type",
        dims => [ $size_expr ]
    );
    my $rows = $self->new_dimen($name . '__rows', $rows_expr);
    my $cols = $self->new_dimen($name . '__cols', $cols_expr);

    return ($data, $rows, $cols);
}

sub to_funarg {
    my ($self) = @_;
    return Bacon::FunArg->new(
        file => $self->file, line => $self->line,
        name => $self->name, type => $self->type,
    );
}

sub to_opencl {
    my ($self, $fun, $depth) = @_;
    if (defined $self->init) {
        my $code = indent($depth);
        $code .= $self->name . " = " . $self->init->to_ocl($fun);    
        return $code . ";\n";
    }
    else {
        return "";
    }
}

sub decl_to_opencl {
    my ($self, $fun, $depth) = @_;
    my $code = indent($depth);
    $code .= $self->type . ' ' . $self->name;

    if (defined $self->dims) {
        assert_type($fun, 'Bacon::Kernel');

        my @dims = map { $_->to_ocl($fun) } @{$self->dims};
        $code .= '[' . join(', ', @dims) . ']';
    }

    if (defined $self->init) {
        $code .= ' = ' . $self->init->to_ocl($fun); 
    }

    $code .= ";\n";
    return $code;
}

sub cpp_dims {
    my ($self, $fun) = @_;
    my @dims = map { $_->to_cpp($fun) } @{$self->dims};
    return join(', ', @dims);
}

__PACKAGE__->meta->make_immutable;
1;
